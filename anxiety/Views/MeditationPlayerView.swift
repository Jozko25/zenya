    //
//  MeditationPlayerView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI
import AVFoundation

struct MeditationPlayerView: View {
    let meditationInfo: MeditationItem // The UI model
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var activationService = ActivationService.shared
    @StateObject private var audioManager = RealAudioPlayer()
    
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var totalTime: Double = 0
    @State private var waveformProgress: Double = 0
    @State private var currentSession: SupabaseMeditationSession? // Supabase entity
    @State private var showingRatingPrompt = false
    @State private var sessionRating: Int = 5
    @State private var moodImprovement: Int = 3
    @State private var playbackSpeed: Float = 1.0
    @State private var showingSpeedPicker = false
    @State private var totalSessions = 0
    @State private var showingPaywall = false
    
    private let meditationId: String
    
    init(meditation: MeditationItem) {
        self.meditationInfo = meditation
        self.meditationId = meditation.id.uuidString
        self._totalTime = State(initialValue: MeditationPlayerView.parseDuration(meditation.duration))
    }
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            let backgroundColors: [Color] = [
                meditationInfo.color.opacity(0.1),
                meditationInfo.color.opacity(0.05),
                AdaptiveColors.Background.primary,
                meditationInfo.color.opacity(0.03)
            ]

            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Always visible back button - positioned absolutely
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Back")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 25))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? 5 : 50)

                    Spacer()
                }
            }

            if showingRatingPrompt {
                ratingPromptView
            } else {
                VStack(spacing: 20) {
                    Spacer(minLength: 80)

                    // Session artwork and visualization
                    sessionArtworkSection

                    Spacer(minLength: 20)

                    // Waveform visualization
                    waveformVisualization

                    // Progress and controls
                    playerControlsSection

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupSession()
            loadSessionCount()
        }
        .onDisappear {
            // Stop audio when navigating away from meditation player
            if isPlaying {
                audioManager.stop()
                isPlaying = false
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PremiumUpsellView(context: .meditation)
        }
        .actionSheet(isPresented: $showingSpeedPicker) {
            let speedButtons: [ActionSheet.Button] = [
                .default(Text("0.5x")) { setPlaybackSpeed(0.5) },
                .default(Text("0.75x")) { setPlaybackSpeed(0.75) },
                .default(Text("1x")) { setPlaybackSpeed(1.0) },
                .default(Text("1.25x")) { setPlaybackSpeed(1.25) },
                .default(Text("1.5x")) { setPlaybackSpeed(1.5) },
                .cancel()
            ]
            
            return ActionSheet(
                title: Text("Playback Speed"),
                buttons: speedButtons
            )
        }
    }
    
    
    private var sessionArtworkSection: some View {
        VStack(spacing: 24) {
            // Main artwork circle with pulsing animation
            ZStack {
                // Outer glow circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            meditationInfo.color.opacity(0.3 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(width: 280 + CGFloat(index * 40), height: 280 + CGFloat(index * 40))
                        .scaleEffect(isPlaying ? 1.1 : 1.0)
                        .opacity(isPlaying ? 0.6 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 3.0 + Double(index)).repeatForever(autoreverses: true),
                            value: isPlaying
                        )
                }
                
                // Main gradient circle
                let gradientColors: [Color] = [
                    meditationInfo.color.opacity(0.6),
                    meditationInfo.color.opacity(0.3),
                    meditationInfo.color.opacity(0.1),
                    Color.clear
                ]
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: gradientColors,
                            center: .center,
                            startRadius: 50,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(isPlaying ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: isPlaying)
                
                // Perfectly centered icon and time
                VStack(spacing: 8) {
                    Image(systemName: meditationInfo.icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(meditationInfo.color)
                        .frame(width: 60, height: 60)

                    Text(formatTime(currentTime))
                        .font(.quicksand(size: 32, weight: .light))
                        .foregroundColor(AdaptiveColors.Text.primary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var waveformVisualization: some View {
        VStack(spacing: 16) {
            // Audio waveform bars
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<60) { index in
                    let isActive = index < Int(waveformProgress * 60)
                    let gradientColors: [Color] = isActive ? [
                        meditationInfo.color,
                        meditationInfo.color.opacity(0.7)
                    ] : [
                        AdaptiveColors.Text.tertiary.opacity(0.3),
                        AdaptiveColors.Text.tertiary.opacity(0.2)
                    ]
                    
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3, height: CGFloat.random(in: 8...32))
                        .animation(Animation.easeInOut(duration: 0.3), value: waveformProgress)
                }
            }
            .frame(height: 40)
            
            // Progress time indicators
            HStack {
                Text(formatTime(currentTime))
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .monospacedDigit()

                Spacer()

                if totalTime == -1 {
                    Text("∞")
                        .font(.quicksand(size: 16, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                } else {
                    Text("-\(formatTime(totalTime - currentTime))")
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                        .monospacedDigit()
                }
            }
        }
    }
    
    private var playerControlsSection: some View {
        VStack(spacing: 24) {
            // Only play/pause button
            Button(action: { togglePlayback() }) {
                ZStack {
                    Circle()
                        .fill(meditationInfo.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: meditationInfo.color.opacity(0.3), radius: 12, x: 0, y: 6)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: isPlaying ? 0 : 2) // Slight offset for play icon
                }
                .scaleEffect(isPlaying ? 1.1 : 1.0)
                .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isPlaying)
            }
        }
    }
    
    private var sessionInfoSection: some View {
        TherapeuticCard(elevation: .elevated) {
            VStack(spacing: 16) {
                HStack {
                    Text("Session Details")
                        .font(.quicksand(size: 18, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(meditationInfo.difficulty.color)
                            .frame(width: 8, height: 8)
                        
                        Text(meditationInfo.difficulty.rawValue)
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
                
                Text(meditationInfo.subtitle)
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Session stats
                HStack(spacing: 24) {
                    SessionStat(icon: "clock", value: meditationInfo.duration, label: "Duration")
                    SessionStat(icon: "heart.fill", value: "4.9", label: "Rating")
                    SessionStat(icon: "person.2.fill", value: "12K", label: "Listens")
                }
            }
            .padding(20)
        }
    }
    
    private var ratingPromptView: some View {
        ZStack {
            VStack(spacing: 32) {
                completionHeaderView

                VStack(spacing: 24) {
                    starRatingView

                    moodImprovementView
                }
                .padding(24)
                .background(AdaptiveColors.Surface.cardElevated)
                .cornerRadius(16)
                .padding(.horizontal, 20)

                Spacer()

                ratingActionsView
            }
            .padding(.vertical, 40)

            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        audioManager.stop()
                        showingRatingPrompt = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()
            }
        }
    }
    
    private func setupSession() {
        // Setup audio for the specific meditation first
        setupAudioForMeditation()

        // Start meditation session for Supabase if user is available
        guard let currentUser = DatabaseService.shared.currentUser else {
            secureLog("⚠️ No current user - skipping session creation")
            return
        }

        let newSession = SupabaseMeditationSession(
            id: UUID(),
            userId: currentUser.id,
            createdAt: Date(),
            type: meditationInfo.category.rawValue,
            title: meditationInfo.title,
            duration: 0, // Will be updated when completed
            completed: false,
            completionRate: 0.0,
            effectiveness: nil
        )

        currentSession = newSession
        secureLog("✅ Meditation session created for user: \(currentUser.id)")
    }
    
    private func setupAudioForMeditation() {
        secureLog("🎵 Setting up audio for: \(meditationInfo.title)", level: .info)
        
        audioManager.setupAudio(duration: totalTime, soundType: meditationInfo.title)
        audioManager.onTimeUpdate = { time in
            DispatchQueue.main.async {
                self.currentTime = time

                if self.totalTime == -1 {
                    let cycleTime = 30.0
                    self.waveformProgress = (time.truncatingRemainder(dividingBy: cycleTime)) / cycleTime
                } else {
                    let progress = time / self.totalTime
                    self.waveformProgress = progress
                }
            }
        }
        audioManager.onPlaybackFinished = {
            DispatchQueue.main.async {
                if self.totalTime != -1 {
                    self.sessionCompleted()
                }
            }
        }
    }
    
    private func togglePlayback() {
        secureLog("🎵 Toggle playback - currently playing: \(isPlaying)", level: .info)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isPlaying.toggle()
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
        
        if isPlaying {
            secureLog("▶️ Starting playback", level: .success)
            audioManager.play()
        } else {
            secureLog("⏸️ Pausing playback", level: .info)
            audioManager.pause()
        }
    }
    
    private func seekBackward(_ seconds: Double) {
        audioManager.seek(to: max(0, currentTime - seconds))
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func seekForward(_ seconds: Double) {
        audioManager.seek(to: min(totalTime, currentTime + seconds))
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioManager.setPlaybackSpeed(speed)
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    private func sessionCompleted() {
        // Stop audio playback immediately
        audioManager.stop()
        isPlaying = false
        showingRatingPrompt = true

        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
    
    private func completeSession() {
        if var session = currentSession {
            let actualDuration = Int(currentTime)
            session.duration = actualDuration
            session.completed = true
            session.completionRate = currentTime / totalTime
            currentSession = session

            // Save session to Supabase
            Task {
                do {
                    try await DatabaseService.shared.saveMeditationSession(session)
                } catch {
                    secureLog("⚠️ Failed to save meditation session: \(error)", level: .warning)
                }
            }
        }
        
        totalSessions += 1
        UserDefaults.standard.set(totalSessions, forKey: "meditation_session_count")
        
        // Trigger paywall for free users after 2 sessions
        if totalSessions == 2 && !activationService.isActivated {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingPaywall = true
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func loadSessionCount() {
        totalSessions = UserDefaults.standard.integer(forKey: "meditation_session_count")
    }
    
    private static func parseDuration(_ durationString: String) -> Double {
        // Handle infinite duration for ambient sounds
        if durationString == "∞" {
            return -1 // Special value for infinite duration
        }

        let components = durationString.replacingOccurrences(of: " min", with: "").components(separatedBy: " ")
        if let minutes = Int(components[0]) {
            return Double(minutes * 60)
        }
        return 1260 // Default 21 minutes
    }
    
    private func formatTime(_ seconds: Double) -> String {
        // Check for invalid values first
        guard seconds.isFinite && !seconds.isNaN else {
            return "00:00"
        }

        let clampedSeconds = max(0, seconds) // Prevent negative values
        let minutes = Int(clampedSeconds) / 60
        let remainingSeconds = Int(clampedSeconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Rating Prompt Sub-Views
    
    private var completionHeaderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.quicksand(size: 64))
                .foregroundColor(AdaptiveColors.Action.progress)
            
            Text("Session Complete!")
                .font(.quicksand(size: 28, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            Text("How was your meditation experience?")
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var starRatingView: some View {
        VStack(spacing: 16) {
            Text("Rate your experience")
                .font(.quicksand(size: 18, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    let isFilled = star <= sessionRating
                    let starIcon = isFilled ? "star.fill" : "star"
                    let starColor = isFilled ? AdaptiveColors.Action.progress : AdaptiveColors.Text.tertiary
                    
                    Button(action: { sessionRating = star }) {
                        Image(systemName: starIcon)
                            .font(.quicksand(size: 24))
                            .foregroundColor(starColor)
                    }
                }
            }
        }
    }
    
    private var moodImprovementView: some View {
        VStack(spacing: 16) {
            Text("How much did this improve your mood?")
                .font(.quicksand(size: 18, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    Button("\(level)") {
                        moodImprovement = level
                        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                        impactFeedback.impactOccurred()
                    }
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(moodImprovement == level ? .white : AdaptiveColors.Text.primary)
                    .frame(width: 40, height: 40)
                    .background(moodImprovement == level ? AdaptiveColors.Action.progress : AdaptiveColors.Surface.cardElevated)
                    .cornerRadius(8)
                }
            }
            
            HStack {
                Text("Not much")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
                Spacer()
                Text("Significantly")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var ratingActionsView: some View {
        VStack(spacing: 16) {
            Button(action: completeSession) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.quicksand(size: 18, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Finish Session")
                            .font(.quicksand(size: 16, weight: .semibold))
                        Text("Save your progress")
                            .font(.quicksand(size: 13, weight: .medium))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AdaptiveColors.Action.progress)
                .cornerRadius(12)
            }
            
            Button("Skip Rating") {
                completeSession()
            }
            .font(.quicksand(size: 16, weight: .medium))
            .foregroundColor(AdaptiveColors.Text.secondary)
        }
        .padding(.horizontal, 20)
    }
}

struct SessionStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.quicksand(size: 12))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                Text(value)
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)
            }
            
            Text(label)
                .font(.quicksand(size: 11, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.tertiary)
        }
    }
}

// MARK: - Audio Manager for Meditation Playback (Industry Standard)
class MeditationAudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    var onTimeUpdate: ((Double) -> Void)?
    var onPlaybackFinished: (() -> Void)?

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timer: Timer?
    private var soundType: String = ""
    private var audioBuffer: AVAudioPCMBuffer?

    override init() {
        super.init()
        setupAudioEngine()
        setupAudioInterruptionHandling()
    }


    private func setupAudioInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            // Interruption began - pause playback
            secureLog("🔇 Audio interruption began")
            pause()
        } else if type == .ended {
            // Interruption ended - resume if it was playing
            secureLog("🔊 Audio interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && !isPlaying {
                    // Resume playback if appropriate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.play()
                    }
                }
            }
        }
    }

    private func setupAudioEngine() {
        // Clean shutdown of existing engine
        if let existingEngine = audioEngine {
            existingEngine.stop()
            existingEngine.reset()
        }
        audioEngine = nil
        playerNode = nil

        do {
            // Configure audio session with proper category for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)

            secureLog("✅ Audio session configured for device compatibility")

            // Create fresh audio engine and player
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()

            // Attach player to engine first
            engine.attach(player)

            // Create proper format that matches our buffer generation
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

            // Connect player directly to main mixer (not output node directly)
            engine.connect(player, to: engine.mainMixerNode, format: format)

            // Connect main mixer to output
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)

            // Prepare engine before starting
            engine.prepare()
            try engine.start()

            // Only assign if successful
            audioEngine = engine
            playerNode = player

            secureLog("✅ Audio engine configured successfully with format: \(format)")

        } catch {
            secureLog("❌ Audio engine setup failed: \(error)")

            // Final fallback - minimal setup
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.soloAmbient)
                try audioSession.setActive(true)

                let engine = AVAudioEngine()
                let player = AVAudioPlayerNode()

                engine.attach(player)
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)! // Mono fallback
                engine.connect(player, to: engine.mainMixerNode, format: format)

                engine.prepare()
                try engine.start()

                audioEngine = engine
                playerNode = player

                secureLog("✅ Fallback mono audio engine configured")
            } catch {
                secureLog("❌ All audio setup attempts failed: \(error)")
                audioEngine = nil
                playerNode = nil
            }
        }
    }

    private func tryBasicAudioSetup() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            secureLog("✅ Basic audio session configured")
        } catch {
            secureLog("❌ Even basic audio setup failed: \(error)")
        }
    }

    func setupAudio(duration: Double, soundType: String = "") {
        secureLog("🔧 Setting up audio for: \(soundType) (duration: \(duration))", level: .info)

        self.duration = duration
        self.currentTime = 0
        self.soundType = soundType

        stop()

        if duration == -1 {
            generateAmbientBuffer(type: soundType)
            secureLog("✅ Audio buffer generated for \(soundType)", level: .success)
        }
    }

    private func generateAmbientBuffer(type: String) {
        secureLog("🎛️ Generating ambient buffer for: \(type)", level: .info)

        let sampleRate: Double = 44100
        let channelCount: UInt32 = 2
        let bufferSize = Int(sampleRate * 2.0)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(bufferSize)) else {
            secureLog("❌ Failed to create audio buffer", level: .error)
            return
        }

        buffer.frameLength = AVAudioFrameCount(bufferSize)

        let numChannels = Int(channelCount)
        secureLog("📊 Using \(numChannels) channel(s) at \(sampleRate) Hz", level: .debug)

        for channel in 0..<numChannels {
            let samples = buffer.floatChannelData![channel]

            switch type.lowercased() {
            case "white noise":
                generateWhiteNoiseSamples(samples, count: bufferSize)
            case "brown noise":
                generateBrownNoiseSamples(samples, count: bufferSize)
            case "forest rain":
                generateRainSamples(samples, count: bufferSize)
            case "ocean waves":
                generateOceanSamples(samples, count: bufferSize, sampleRate: sampleRate)
            case "thunderstorm":
                generateThunderstormSamples(samples, count: bufferSize, sampleRate: sampleRate)
            case "crackling fire":
                generateFireSamples(samples, count: bufferSize)
            case "pink noise":
                generatePinkNoiseSamples(samples, count: bufferSize)
            case "mountain stream":
                generateStreamSamples(samples, count: bufferSize, sampleRate: sampleRate)
            default:
                generateWhiteNoiseSamples(samples, count: bufferSize)
            }
        }

        audioBuffer = buffer
        secureLog("✅ Audio buffer generated: \(buffer.frameLength) frames, \(channelCount) channels", level: .success)
    }

    // MARK: - Sample Generation Functions
    private func generateWhiteNoiseSamples(_ samples: UnsafeMutablePointer<Float>, count: Int) {
        for i in 0..<count {
            samples[i] = Float.random(in: -0.3...0.3)
        }
    }

    private func generateBrownNoiseSamples(_ samples: UnsafeMutablePointer<Float>, count: Int) {
        var lastSample: Float = 0
        for i in 0..<count {
            let white = Float.random(in: -1...1)
            lastSample = (lastSample + (0.02 * white)) / 1.02
            samples[i] = lastSample * 0.2
        }
    }

    private func generateRainSamples(_ samples: UnsafeMutablePointer<Float>, count: Int) {
        var filterState1: Float = 0
        var filterState2: Float = 0
        
        for i in 0..<count {
            let whiteNoise = Float.random(in: -1...1)
            
            // High-pass filter for rain hiss (removes low frequencies)
            filterState1 = 0.95 * filterState1 + whiteNoise
            let highPass = whiteNoise - filterState1
            
            // Band-pass for rain drops (emphasize mid-high frequencies)
            filterState2 = 0.85 * filterState2 + highPass * 0.5
            let rainHiss = filterState2
            
            // Occasional heavy droplets with decay
            let dropChance = Int.random(in: 0...150)
            let droplet: Float
            if dropChance == 0 {
                droplet = Float.random(in: 0.3...0.6)
            } else if dropChance < 5 {
                droplet = Float.random(in: 0.1...0.3)
            } else {
                droplet = 0
            }
            
            // Distant thunder rumble (very subtle)
            let thunder = Float(sin(Double(i) * 0.00008)) * 0.03
            
            // Background rain on leaves (softer hiss)
            let leaves = Float.random(in: -0.08...0.08)
            
            // Combine all elements
            let rain = (rainHiss * 0.4) + droplet + thunder + leaves
            samples[i] = rain * 0.25
        }
    }

    private func generateOceanSamples(_ samples: UnsafeMutablePointer<Float>, count: Int, sampleRate: Double) {
        for i in 0..<count {
            let time = Double(i) / sampleRate
            
            // Multiple wave frequencies for realistic ocean
            let wave1 = Float(sin(time * 0.3) * 0.2)
            let wave2 = Float(sin(time * 0.47) * 0.15)
            let wave3 = Float(sin(time * 0.71) * 0.1)
            
            // Wave crash (occasional swell)
            let swellCycle = sin(time * 0.08)
            let swell = swellCycle > 0.8 ? Float(swellCycle - 0.8) * 0.3 : 0
            
            // Foam and bubbles (filtered white noise)
            let foam = Float.random(in: -0.08...0.08) * Float(abs(sin(time * 2)))
            
            samples[i] = wave1 + wave2 + wave3 + swell + foam
        }
    }

    private func generateThunderstormSamples(_ samples: UnsafeMutablePointer<Float>, count: Int, sampleRate: Double) {
        for i in 0..<count {
            let time = Double(i) / sampleRate
            
            // Deep rumbling thunder (low frequency)
            let rumble1 = Float(sin(time * 0.2) * 0.2)
            let rumble2 = Float(sin(time * 0.35) * 0.15)
            
            // Thunder crack (random, occasional)
            let thunderChance = Int(time * 10) % 200
            let thunder: Float
            if thunderChance == 0 {
                thunder = Float.random(in: 0.4...0.8)
            } else if thunderChance < 3 {
                thunder = Float.random(in: 0.2...0.4) * Float(3 - thunderChance) / 3.0
            } else {
                thunder = 0
            }
            
            // Heavy rain (filtered noise)
            let heavyRain = Float.random(in: -0.1...0.1)
            
            // Wind (low rumble)
            let wind = Float(sin(time * 1.5) * 0.08)
            
            samples[i] = rumble1 + rumble2 + thunder + heavyRain + wind
        }
    }

    private func generateFireSamples(_ samples: UnsafeMutablePointer<Float>, count: Int) {
        for i in 0..<count {
            // Continuous low crackle
            let baseCrackle = Float.random(in: -0.15...0.15)
            
            // Sharp pops (wood cracking)
            let popChance = Int.random(in: 0...800)
            let pop: Float
            if popChance == 0 {
                pop = Float.random(in: 0.3...0.6)
            } else if popChance < 3 {
                pop = Float.random(in: 0.15...0.3)
            } else {
                pop = 0
            }
            
            // Sizzle (high frequency crackle)
            let sizzle = Float.random(in: -0.05...0.05) * Float.random(in: 0...1)
            
            // Deep flame roar (low rumble)
            let roar = Float(sin(Double(i) * 0.003)) * 0.08
            
            samples[i] = (baseCrackle + pop + sizzle + roar) * 0.35
        }
    }

    private func generatePinkNoiseSamples(_ samples: UnsafeMutablePointer<Float>, count: Int) {
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0

        for i in 0..<count {
            let white = Float.random(in: -1...1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            let pink = (b0 + b1 + b2 + b3 + white * 0.5362) * 0.08
            samples[i] = pink
        }
    }

    private func generateStreamSamples(_ samples: UnsafeMutablePointer<Float>, count: Int, sampleRate: Double) {
        for i in 0..<count {
            let time = Double(i) / sampleRate
            
            // Water flow (multiple frequencies)
            let flow1 = Float(sin(time * 3.0) * 0.15)
            let flow2 = Float(sin(time * 7.2) * 0.1)
            let flow3 = Float(sin(time * 11.5) * 0.06)
            
            // Babbling (higher frequency variation)
            let babble = Float.random(in: -0.08...0.08) * Float(abs(sin(time * 15)))
            
            // Splashes (occasional)
            let splashChance = Int.random(in: 0...300)
            let splash = (splashChance == 0) ? Float.random(in: 0.1...0.25) : 0
            
            // Rocks and ripples (filtered noise)
            let ripple = Float.random(in: -0.04...0.04)
            
            samples[i] = flow1 + flow2 + flow3 + babble + splash + ripple
        }
    }

    // MARK: - Playback Control
    func play() {
        secureLog("▶️ play() called - soundType: \(soundType)", level: .info)
        
        if audioEngine == nil || playerNode == nil {
            secureLog("🔄 Audio engine not ready, setting up...", level: .warning)
            setupAudioEngine()
        }

        guard let buffer = audioBuffer else {
            secureLog("❌ No audio buffer available! Did you call setupAudio()?", level: .error)
            return
        }
        
        guard let engine = audioEngine,
              let player = playerNode else {
            secureLog("❌ Audio engine or player node still nil after setup", level: .error)
            return
        }

        secureLog("🎵 Starting playback for \(soundType) - buffer has \(buffer.frameLength) frames", level: .info)

        do {
            if !engine.isRunning {
                try engine.start()
                secureLog("🔄 Started audio engine", level: .success)
            }

            player.stop()

            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)

            player.volume = 1.0
            secureLog("🔊 Set volume to \(player.volume)", level: .debug)

            player.play()
            isPlaying = true
            startTimer()

            secureLog("✅ Playback started successfully!", level: .success)

        } catch {
            secureLog("❌ Failed to start playback: \(error)", level: .error)
            setupAudioEngine()
        }
    }

    func pause() {
        guard let player = playerNode else {
            secureLog("❌ Player node not available for pause")
            return
        }
        player.pause()
        isPlaying = false
        timer?.invalidate()
        secureLog("⏸️ Playback paused")
    }

    func stop() {
        guard let player = playerNode else {
            secureLog("❌ Player node not available for stop")
            isPlaying = false
            timer?.invalidate()
            currentTime = 0
            return
        }
        player.stop()
        isPlaying = false
        timer?.invalidate()
        currentTime = 0
        secureLog("⏹️ Playback stopped")
    }

    func seek(to time: Double) {
        // For looping audio, seeking is not typical, but we can reset current time tracking
        currentTime = time
        onTimeUpdate?(currentTime)
    }

    func setPlaybackSpeed(_ speed: Float) {
        // AVAudioPlayerNode doesn't support rate directly, but we could use AVAudioUnitTimePitch
        // For now, just acknowledge the request
        secureLog("⚙️ Playback speed change requested: \(speed)x (not implemented for engine)")
    }


    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard self.isPlaying else { return }

            self.currentTime += 0.1
            self.onTimeUpdate?(self.currentTime)

            // For infinite duration, no need to check completion
        }
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.reset()
        }
    }
}

#Preview {
    MeditationPlayerView(meditation: MeditationItem(
        title: "Stress Relaxation",
        subtitle: "Release tension and find peace",
        duration: "21 min",
        category: .anxiety,
        difficulty: .beginner,
        isPremium: false,
        color: AdaptiveColors.Action.breathing,
        icon: "wind",
        imageName: "wind"
    ))
}
