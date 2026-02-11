import Foundation
import AVFoundation

class RealAudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    
    var onTimeUpdate: ((Double) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var soundType: String = ""
    
    override init() {
        super.init()
        setupAudioSession()
        setupAudioInterruptionHandling()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            secureLog("✅ Audio session configured for playback", level: .success)
        } catch {
            secureLog("❌ Audio session setup failed: \(error)", level: .error)
        }
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
            secureLog("🔇 Audio interruption began", level: .warning)
            pause()
        } else if type == .ended {
            secureLog("🔊 Audio interruption ended", level: .info)
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.play()
                    }
                }
            }
        }
    }
    
    func setupAudio(duration: Double, soundType: String = "") {
        secureLog("🔧 Setting up real audio for: \(soundType)", level: .info)
        
        self.soundType = soundType
        self.currentTime = 0
        
        stop()
        
        let fileName = mapSoundToFile(soundType)
        secureLog("📁 Looking for file: \(fileName.name).\(fileName.ext)", level: .debug)
        loadAudioFile(fileName: fileName)
    }
    
    private func mapSoundToFile(_ soundType: String) -> (name: String, ext: String) {
        switch soundType.lowercased() {
        case "forest rain":
            return ("rain", "wav")
        case "ocean waves":
            return ("waves", "wav")
        case "thunderstorm":
            return ("thunderstorm", "mp3")
        case "crackling fire":
            return ("fire", "wav")
        default:
            secureLog("⚠️ Unknown sound type: \(soundType), defaulting to rain", level: .warning)
            return ("rain", "wav")
        }
    }
    
    private func loadAudioFile(fileName: (name: String, ext: String)) {
        var url: URL?
        
        // Try different subdirectory paths
        let paths = [
            "Sounds",
            "Resources/Sounds",
            nil
        ]
        
        for path in paths {
            if let foundURL = Bundle.main.url(forResource: fileName.name, withExtension: fileName.ext, subdirectory: path) {
                url = foundURL
                secureLog("✅ Found audio file at path: \(path ?? "root")", level: .success)
                break
            }
        }
        
        guard let audioURL = url else {
            secureLog("❌ Audio file not found: \(fileName.name).\(fileName.ext) in any path", level: .error)
            secureLog("   Searched: Sounds/, Resources/Sounds/, root", level: .error)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            
            secureLog("✅ Audio file loaded: \(fileName.name).\(fileName.ext)", level: .success)
        } catch {
            secureLog("❌ Failed to load audio file: \(error)", level: .error)
        }
    }
    
    func play() {
        guard let player = audioPlayer else {
            secureLog("❌ No audio player available", level: .error)
            return
        }
        
        player.play()
        isPlaying = true
        startTimer()
        
        secureLog("▶️ Playback started for \(soundType)", level: .success)
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
        
        secureLog("⏸️ Playback paused", level: .info)
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        timer?.invalidate()
        currentTime = 0
        
        secureLog("⏹️ Playback stopped", level: .info)
    }
    
    func seek(to time: Double) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
        onTimeUpdate?(currentTime)
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        audioPlayer?.rate = speed
        audioPlayer?.enableRate = true
        secureLog("⚙️ Playback speed set to \(speed)x", level: .debug)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            if let player = self.audioPlayer {
                self.currentTime = player.currentTime
                self.onTimeUpdate?(self.currentTime)
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        audioPlayer?.stop()
    }
}
