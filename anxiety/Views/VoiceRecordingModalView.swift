//
//  VoiceRecordingModalView.swift
//  anxiety
//
//  Voice Recording Modal with Modern Design
//

import SwiftUI
import AVFoundation

struct VoiceRecordingModalView: View {
    @StateObject private var whisperService = WhisperService()
    @Binding var isPresented: Bool
    @Binding var recordedText: String
    let promptCategory: Color

    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    @State private var processingAnimation = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var modalAppeared = false
    @State private var dragOffset: CGFloat = 0

    private var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Background with blur effect - smooth fade
            Color.black.opacity(modalAppeared ? 0.5 * (1 - Double(dragOffset / 400)) : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.2), value: modalAppeared)
                .onTapGesture {
                    if !whisperService.isRecording && !whisperService.isProcessing {
                        dismissModal()
                    }
                }

            // Main modal content
            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 24)

                // Title with icon
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(promptCategory.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "waveform")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(promptCategory)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice Note")
                            .font(.quicksand(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        Text(whisperService.isProcessing ? "Transcribing..." :
                             whisperService.isRecording ? "Listening..." :
                             "Hold to record")
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        dismissModal()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Recording Interface
                ZStack {
                    // Animated background rings - softer, more elegant
                    if whisperService.isRecording {
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.red.opacity(0.25 - Double(index) * 0.08),
                                            Color.red.opacity(0.15 - Double(index) * 0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                                .frame(width: 130 + CGFloat(index * 35), height: 130 + CGFloat(index * 35))
                                .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                                .opacity(pulseAnimation ? 0.6 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.8)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.25),
                                    value: pulseAnimation
                                )
                        }
                    }

                    // Main recording button
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        (whisperService.isRecording ? Color.red : promptCategory).opacity(0.3),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 160, height: 160)

                        // Main circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: whisperService.isRecording ?
                                    [Color(hex: "FF4757"), Color(hex: "FF6B7A")] :
                                    whisperService.isProcessing ?
                                    [promptCategory.opacity(0.7), promptCategory.opacity(0.5)] :
                                    [promptCategory, promptCategory.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: whisperService.isRecording ? Color.red.opacity(0.5) : promptCategory.opacity(0.5),
                                   radius: 20, x: 0, y: 10)
                            .scaleEffect(animationScale)

                        // Inner content
                        if whisperService.isProcessing {
                            // Modern loading animation
                            ProcessingLoaderView()
                        } else if whisperService.isRecording {
                            // Recording indicator
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)

                                Text(formattedDuration)
                                    .font(.quicksand(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(whisperService.isRecording ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: whisperService.isRecording)

                    // Audio waveform visualization (when recording)
                    if whisperService.isRecording {
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in
                                Capsule()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 4, height: CGFloat.random(in: 20...50))
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.1),
                                        value: pulseAnimation
                                    )
                            }
                        }
                        .offset(y: 90)
                    }
                }
                .frame(height: 200)
                .onLongPressGesture(minimumDuration: 0.01, maximumDistance: .infinity, pressing: { isPressing in
                    handleRecordingGesture(isPressing: isPressing)
                }, perform: {})
                .disabled(whisperService.isProcessing)

                // Instructions or status
                VStack(spacing: 16) {
                    if whisperService.isProcessing {
                        VStack(spacing: 12) {
                            Text("AI Processing")
                                .font(.quicksand(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Converting your speech to text...")
                                .font(.quicksand(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            // Progress indicator bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [promptCategory, promptCategory.opacity(0.6)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: processingAnimation ? geometry.size.width : 0, height: 6)
                                        .animation(
                                            Animation.linear(duration: 2.0)
                                                .repeatForever(autoreverses: false),
                                            value: processingAnimation
                                        )
                                }
                            }
                            .frame(height: 6)
                            .padding(.horizontal, 60)
                        }
                    } else if !recordedText.isEmpty {
                        VStack(spacing: 12) {
                            Label("Transcribed Text", systemImage: "checkmark.circle.fill")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(Color.green)

                            ScrollView {
                                Text(recordedText)
                                    .font(.quicksand(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            .frame(maxHeight: 100)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 20) {
                            HStack(spacing: 40) {
                                VStack(spacing: 8) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(promptCategory)
                                    Text("Hold")
                                        .font(.quicksand(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.4))

                                VStack(spacing: 8) {
                                    Image(systemName: "waveform")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.red)
                                    Text("Speak")
                                        .font(.quicksand(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.4))

                                VStack(spacing: 8) {
                                    Image(systemName: "text.alignleft")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.green)
                                    Text("Text")
                                        .font(.quicksand(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            Text("Your thoughts will be transcribed automatically")
                                .font(.quicksand(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .frame(height: 120)
                .padding(.top, 20)

                // Error message if any
                if let errorMessage = whisperService.errorMessage {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.orange)

                            Text(errorMessage)
                                .font(.quicksand(size: 14, weight: .medium))
                                .foregroundColor(Color.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if errorMessage.contains("Settings") {
                            Button(action: {
                                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsURL)
                                }
                            }) {
                                Text("Open Settings")
                                    .font(.quicksand(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.orange)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 20)

                // Action buttons
                if !recordedText.isEmpty && !whisperService.isRecording && !whisperService.isProcessing {
                    HStack(spacing: 16) {
                        Button(action: {
                            recordedText = ""
                            whisperService.recognizedText = ""
                        }) {
                            Text("Clear")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.2))
                                )
                        }

                        Button(action: {
                            dismissModal()
                        }) {
                            Text("Done")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [promptCategory, promptCategory.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(UIColor.systemBackground).opacity(0.95),
                                Color(UIColor.secondarySystemBackground).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .background(
                        VisualEffectBlur(blurStyle: .systemMaterialDark)
                            .cornerRadius(30)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 60)
            .offset(y: modalAppeared ? dragOffset : UIScreen.main.bounds.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 && !whisperService.isRecording && !whisperService.isProcessing {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                            dismissModal()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            pulseAnimation = true
            whisperService.refreshMicrophonePermissionStatus()
            // Smooth spring animation on appear
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                modalAppeared = true
            }
        }
        .onChange(of: whisperService.recognizedText) { newText in
            if !newText.isEmpty {
                recordedText = newText
            }
        }
        .onChange(of: whisperService.isProcessing) { isProcessing in
            processingAnimation = isProcessing
        }
    }

    private func handleRecordingGesture(isPressing: Bool) {
        if isPressing {
            if !whisperService.isRecording && !whisperService.isProcessing {
                startRecording()
            }
        } else {
            if whisperService.isRecording {
                stopRecording()
            }
        }
    }

    private func startRecording() {
        whisperService.startRecording()
        recordingDuration = 0

        // Start timer to update duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animationScale = 1.2
        }
    }

    private func stopRecording() {
        whisperService.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animationScale = 1.0
        }
    }

    private func dismissModal() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            modalAppeared = false
            dragOffset = 0
        }
        // Delay the actual dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// Processing Loader Animation View
struct ProcessingLoaderView: View {
    @State private var rotation: Double = 0
    @State private var dotScale: [CGFloat] = [1, 1, 1, 1]

    var body: some View {
        ZStack {
            // Rotating dots
            ForEach(0..<4) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale[index])
                    .offset(x: 25)
                    .rotationEffect(.degrees(Double(index) * 90 + rotation))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: dotScale[index]
                    )
            }

            // Center icon
            Image(systemName: "waveform.circle")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(dotScale[0])
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: dotScale[0]
                )
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            for i in 0..<4 {
                withAnimation(Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)) {
                    dotScale[i] = 1.3
                }
            }
        }
    }
}

// Visual Effect Blur for glass morphism
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

#Preview {
    VoiceRecordingPreviewWrapper()
}

struct VoiceRecordingPreviewWrapper: View {
    @State private var isPresented = true
    @State private var recordedText = ""
    
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VoiceRecordingModalView(
                isPresented: $isPresented,
                recordedText: $recordedText,
                promptCategory: AdaptiveColors.Action.breathing
            )
        }
    }
}