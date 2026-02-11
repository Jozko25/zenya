//
//  WhisperService.swift
//  anxiety
//
//  OpenAI Whisper speech-to-text service for journal dictation
//

import Foundation
import AVFoundation

@MainActor
class WhisperService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var isAvailable = true
    @Published var errorMessage: String?

    // Computed property for backward compatibility
    var error: String? {
        return errorMessage
    }

    // Check if transcription is available (recording is always available if microphone is accessible)
    var isTranscriptionAvailable: Bool {
        return !openAIAPIKey.isEmpty
    }
    
    private var recordingStartTime: Date?
    
    private var audioRecorder: AVAudioRecorder?
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioURL: URL?
    
    // OpenAI API configuration
    private let openAIAPIKey: String
    private let whisperEndpoint = "https://api.openai.com/v1/audio/transcriptions"
    
    override init() {
        // Load API key from APIKeys.plist
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["OpenAI_API_Key"] as? String,
           !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY_HERE" {
            self.openAIAPIKey = apiKey
        } else {
            self.openAIAPIKey = ""
        }

        // Call parent initializer first
        super.init()

        // Now we can call methods that use self
        if openAIAPIKey.isEmpty {
            debugPrint("ℹ️ OpenAI API key not configured - voice recording available, transcription disabled")
            debugPrint("ℹ️ To enable transcription: copy APIKeys.plist.template to APIKeys.plist and add your OpenAI API key")
            // Don't set isAvailable = false here, as we want to allow recording even without API key
            // The user will get feedback about transcription availability after recording
        } else {
            debugPrint("✅ OpenAI API key configured - full voice transcription available")
        }

        // Don't setup audio session here to avoid interrupting music
        // Audio session will be configured only when recording actually starts
        // Don't request microphone permission immediately to prevent crash
        // Will be requested when user first tries to use voice recording
    }
    
    // Method to refresh microphone permission status (call when app becomes active)
    func refreshMicrophonePermissionStatus() {
        let permission = AVAudioSession.sharedInstance().recordPermission
        debugPrint("🔄 Refreshing microphone permission status: \(permission.rawValue)")
        
        switch permission {
        case .granted:
            isAvailable = true
            errorMessage = nil
            debugPrint("✅ Microphone access confirmed")
        case .denied:
            isAvailable = false
            errorMessage = "Microphone access is required for voice recording. Please enable it in Settings > Privacy & Security > Microphone > Zenya"
            debugPrint("❌ Microphone access denied")
        case .undetermined:
            isAvailable = false
            debugPrint("❓ Microphone permission not determined yet")
        @unknown default:
            isAvailable = false
            errorMessage = "Unable to determine microphone access status"
            debugPrint("⚠️ Unknown microphone permission state")
        }
    }
    
    private func requestMicrophonePermission() {
        // This method is now replaced by checkMicrophonePermissionAndStartRecording
        // Keep for backward compatibility if needed elsewhere
        refreshMicrophonePermissionStatus()
    }
    
    func startRecording() {
        // Always check microphone permission before recording
        checkMicrophonePermissionAndStartRecording()
    }
    
    private func checkMicrophonePermissionAndStartRecording() {
        let permission = AVAudioSession.sharedInstance().recordPermission
        debugPrint("🎤 Current microphone permission: \(permission.rawValue)")
        
        switch permission {
        case .undetermined:
            debugPrint("📱 Requesting microphone permission...")
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        debugPrint("✅ Microphone permission granted")
                        self?.performStartRecording()
                    } else {
                        debugPrint("❌ Microphone permission denied")
                        self?.errorMessage = "Microphone access is required for voice recording. Please enable it in Settings > Privacy & Security > Microphone > Zenya"
                        self?.isAvailable = false
                    }
                }
            }
            return
            
        case .denied:
            debugPrint("❌ Microphone permission previously denied")
            errorMessage = "Microphone access is required for voice recording. Please go to Settings > Privacy & Security > Microphone > Zenya and enable microphone access."
            isAvailable = false
            return
            
        case .granted:
            debugPrint("✅ Microphone permission is granted, proceeding with recording")
            performStartRecording()
            
        @unknown default:
            debugPrint("⚠️ Unknown microphone permission state")
            errorMessage = "Unable to determine microphone access. Please check your device settings."
            isAvailable = false
            return
        }
    }
    
    private func performStartRecording() {
        guard isAvailable else {
            errorMessage = "Microphone not available"
            return
        }

        // Clear any previous errors
        errorMessage = nil

        // Quick response - set recording state immediately
        isRecording = true
        recordingStartTime = Date()

        // Do the heavy work asynchronously
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.setupRecordingAsync()
        }
    }

    private func setupRecordingAsync() {
        // Configure audio session on background thread
        DispatchQueue.main.async { [weak self] in
            self?.configureAudioSessionAndStartRecording()
        }
    }

    private func configureAudioSessionAndStartRecording() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)

            debugPrint("🎙️ Audio session configured and activated for recording: Sample rate \(audioSession.sampleRate)Hz")
            continueRecordingSetup()
        } catch {
            debugPrint("Failed to configure audio session: \(error)")
            // Try to deactivate in case it was partially activated
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to configure audio session for recording"
                self?.isRecording = false
                self?.recordingStartTime = nil
            }
        }
    }

    private func continueRecordingSetup() {
        
        // Create temporary file for recording - use WAV format for better compatibility
        let tempDir = FileManager.default.temporaryDirectory
        audioURL = tempDir.appendingPathComponent("journal_recording_\(Date().timeIntervalSince1970).wav")
        
        // Delete any existing file at this location
        if let audioURL = audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            try? FileManager.default.removeItem(at: audioURL)
        }
        
        // Use uncompressed WAV format for maximum compatibility with Whisper
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            guard let audioURL = audioURL else { return }
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                DispatchQueue.main.async { [weak self] in
                    self?.isRecording = true
                    self?.recordingStartTime = Date()
                    self?.errorMessage = nil
                }
                debugPrint("🎤 Started recording audio for Whisper transcription at: \(audioURL.path)")
            } else {
                // Deactivate audio session on failure
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to start recording"
                    self?.isRecording = false
                }
                debugPrint("❌ Failed to start recording")
            }
        } catch {
            // Deactivate audio session on error
            try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            debugPrint("Failed to start recording: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                self?.isRecording = false
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }

        let recordingDuration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        debugPrint("🎤 Recording duration: \(recordingDuration) seconds")

        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        recordingStartTime = nil

        // Deactivate audio session to allow music playback to resume
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            debugPrint("✅ Audio session deactivated, music can resume")
        } catch {
            debugPrint("⚠️ Failed to deactivate audio session: \(error)")
        }

        // Check minimum duration
        if recordingDuration < 1.0 {
            errorMessage = "Recording too short. Please hold the button for at least 1 second while speaking clearly."
            debugPrint("⚠️ Recording too short: \(recordingDuration) seconds")
            return
        }
        
        // Process with Whisper after a small delay to ensure file is written
        if let audioURL = audioURL {
            // Check file size and duration before sending
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay to ensure file is fully written

                // Validate file exists and has content
                guard FileManager.default.fileExists(atPath: audioURL.path) else {
                    await MainActor.run {
                        errorMessage = "Audio file not found. Please try again."
                    }
                    return
                }

                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path),
                   let fileSize = fileAttributes[.size] as? Int64 {
                    debugPrint("📊 Audio file size: \(fileSize) bytes for \(recordingDuration) second recording")

                    // More lenient file size check - should be at least 1KB per second
                    let expectedMinSize = max(1000, Int64(recordingDuration * 1000))
                    if fileSize < expectedMinSize {
                        await MainActor.run {
                            errorMessage = "Recording appears incomplete. Please speak clearly and ensure microphone access."
                        }
                        debugPrint("⚠️ File size \(fileSize) too small for \(recordingDuration) second recording")
                        return
                    }

                    // For testing: If we have a successful recording but no API key, show success message
                    if openAIAPIKey.isEmpty {
                        await MainActor.run {
                            recognizedText = "🎤 Recording successful! Duration: \(String(format: "%.1f", recordingDuration))s\n\nTo enable voice-to-text transcription, add your OpenAI API key to the configuration file."
                        }
                        return
                    }
                }

                await MainActor.run {
                    transcribeWithWhisper(audioURL: audioURL)
                }
            }
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
            // Track voice usage for achievements
            trackVoiceUsage()
        }
    }
    
    private func trackVoiceUsage() {
        let currentCount = UserDefaults.standard.integer(forKey: "journal_voice_usage_count") + 1
        UserDefaults.standard.set(currentCount, forKey: "journal_voice_usage_count")
    }
    
    private func transcribeWithWhisper(audioURL: URL) {
        guard !openAIAPIKey.isEmpty else {
            errorMessage = "OpenAI API key not configured. Please add your API key to APIKeys.plist to enable voice transcription."
            isProcessing = false
            return
        }

        isProcessing = true
        
        Task {
            do {
                let transcription = try await sendToWhisperAPI(audioURL: audioURL)
                await MainActor.run {
                    recognizedText = transcription
                    isProcessing = false
                    debugPrint("✅ Whisper transcription: \(transcription)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Transcription failed: \(error.localizedDescription)"
                    isProcessing = false
                    debugPrint("❌ Whisper transcription failed: \(error)")
                }
            }
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: audioURL)
        }
    }
    
    private func sendToWhisperAPI(audioURL: URL) async throws -> String {
        guard let url = URL(string: whisperEndpoint) else {
            throw NSError(domain: "WhisperService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        let audioData = try Data(contentsOf: audioURL)
        debugPrint("🔊 Sending audio file: \(audioURL.lastPathComponent), size: \(audioData.count) bytes")
        
        // Verify we have actual audio data
        guard audioData.count > 44 else { // WAV header is at least 44 bytes
            throw NSError(domain: "WhisperService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Audio file appears corrupted or empty"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter for better accuracy (assuming English)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add temperature parameter for more conservative transcription
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("0.2\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("verbose_json\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "WhisperService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "WhisperService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorString)"])
        }
        
        struct WhisperResponse: Codable {
            let text: String
            let language: String?
            let duration: Double?
            let segments: [WhisperSegment]?
        }
        
        struct WhisperSegment: Codable {
            let text: String
            let start: Double
            let end: Double
        }
        
        let whisperResponse = try JSONDecoder().decode(WhisperResponse.self, from: data)
        
        // Log additional info for debugging
        if let language = whisperResponse.language {
            debugPrint("🌐 Detected language: \(language)")
        }
        if let duration = whisperResponse.duration {
            debugPrint("⏱️ Audio duration: \(duration) seconds")
        }
        
        return whisperResponse.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension WhisperService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            Task { @MainActor in
                errorMessage = "Recording failed"
                isRecording = false
            }
        }
    }
}