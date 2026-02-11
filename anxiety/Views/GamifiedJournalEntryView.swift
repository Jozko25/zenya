//
//  GamifiedJournalEntryView.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Journal Entry Theme Palette (Modern Minimal Design)

private enum JournalEntryPalette {
    // Primary accent - warm coral/pink
    static let accent = Color(hex: "FF6B6B")

    // Secondary accent for gradients
    static let accentSecondary = Color(hex: "FF8E8E")

    // Subtle surface tint
    static let surfaceTint = Color(hex: "FF6B6B").opacity(0.05)

    // Semantic colors following Apple HIG
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "000000") : Color(hex: "F2F2F7")
    }

    static func elevatedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "0A0A0A") : Color.white
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "141414") : Color(hex: "FAFAFA")
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color(hex: "3C3C43").opacity(0.6)
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.25) : Color(hex: "3C3C43").opacity(0.3)
    }

    static func separator(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "3C3C43").opacity(0.12)
    }

    static func fill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "787880").opacity(0.08)
    }

    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color(hex: "F5F5F7")
    }
}

struct GamifiedJournalEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var gameStatsManager = JournalGameStatsManager.shared
    @StateObject private var whisperService = WhisperService()

    @State private var content: String = ""
    @State private var isLoading = false
    @State private var inputMode: InputMode = .recording
    @State private var isBlockedFromSubmitting = false
    @State private var nextSubmissionTime: Date?
    @State private var countdownTimer: Timer?

    #if DEBUG
    @State private var isDebugOverrideEnabled = false
    #endif

    @State private var wordCount: Int = 0
    @State private var wordCountUpdateTask: Task<Void, Never>?
    @FocusState private var isTextEditorFocused: Bool
    @State private var showingMicrophonePermissionAlert = false
    @State private var showVoiceRecording = false
    @State private var isRecording = false
    @State private var recordingTimer: Timer?
    @State private var recordingDuration: TimeInterval = 0
    @State private var audioLevel: CGFloat = 0.0

    // Navigation for cooldown actions
    @State private var showBreathingExercise = false
    @State private var showEvaluations = false

    enum InputMode {
        case typing, recording
    }

    enum TimeSlot {
        case morning, afternoon
    }

    let existingEntry: SupabaseJournalEntry?

    init(existingEntry existingJournalEntry: SupabaseJournalEntry? = nil) {
        self.existingEntry = existingJournalEntry
    }



    var blockedMessage: String {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let isMorning = currentHour >= 6 && currentHour < 17

        if isMorning {
            return "Your morning reflection is complete. Take this time to breathe, move, or simply be present. Your evening check-in opens at 5 PM."
        } else {
            return "Your evening reflection is complete. Rest well tonight. Tomorrow's morning reflection opens at 6 AM."
        }
    }

    var encouragementMessage: String {
        let messages = [
            "Every reflection brings you closer to understanding yourself.",
            "You're building a powerful habit of self-awareness.",
            "Taking time to reflect is an act of self-love.",
            "Your thoughts matter. Thank you for showing up today.",
            "Consistency is key. You're doing great."
        ]
        // Use day of year to get consistent but varied message
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return messages[dayOfYear % messages.count]
    }

    var body: some View {
        ZStack {
            // Clean background - content sits on top
            JournalEntryPalette.elevatedBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with glass save button
                if !isBlockedFromSubmitting {
                    gamifiedHeader
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                if isBlockedFromSubmitting {
                    blockedSubmissionView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            entryForm
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .onAppear {
            loadExistingEntry()
            checkSubmissionRestrictions()
            updateWordCount()
        }
        .onChange(of: whisperService.recognizedText) { _, newText in
            // Append transcribed text to existing content
            if !newText.isEmpty {
                if content.isEmpty {
                    content = newText
                } else {
                    content = content + " " + newText
                }
                whisperService.recognizedText = ""
                updateWordCount()
            }
        }
        .onChange(of: whisperService.isRecording) { _, newIsRecording in
            // Sync local recording state with service state
            if newIsRecording != isRecording {
                isRecording = newIsRecording
            }
        }
        .onChange(of: content) { _, _ in
            debouncedUpdateWordCount()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            wordCountUpdateTask?.cancel()
            recordingTimer?.invalidate()
            waveformTimer?.invalidate()
            if isRecording {
                whisperService.stopRecording()
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingMicrophonePermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to record your thoughts using voice.")
        }
        .sheet(isPresented: $showBreathingExercise) {
            EmergencyBreathingView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showEvaluations) {
            EvaluationsModalView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    private var gamifiedHeader: some View {
        HStack(alignment: .center) {
            // Drag indicator - refined
            Capsule()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.3))
                .frame(width: 36, height: 4)

            Spacer()

            if !isBlockedFromSubmitting {
                saveButton
            }
        }
        .padding(.horizontal, 20)
    }

    private var saveButton: some View {
        let isButtonDisabled = isBlockedFromSubmitting || isLoading || !isContentValid(content)

        return Button(action: {
            if !isButtonDisabled {
                saveEntry()
            }
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isButtonDisabled ? JournalEntryPalette.tertiaryText(for: colorScheme) : .white)
                }
            }
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(isButtonDisabled ? JournalEntryPalette.fill(for: colorScheme) : JournalEntryPalette.accent)
                    .shadow(
                        color: isButtonDisabled ? .clear : JournalEntryPalette.accent.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(isButtonDisabled)
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isButtonDisabled)
    }

    private var countdownDisplay: some View {
        VStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))

            Text(timeRemainingString())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
        }
        .frame(width: 32, height: 32)
        .background(JournalEntryPalette.fill(for: colorScheme))
        .cornerRadius(16)
    }

    private var timeToRestNotification: some View {
        HStack(spacing: 14) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(JournalEntryPalette.accent)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(JournalEntryPalette.accent.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Time to Rest")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

                Text("Take time to process before your next reflection.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JournalEntryPalette.fill(for: colorScheme))
        )
    }

    private var blockedSubmissionView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon with soft halo
            ZStack {
                Circle()
                    .fill(JournalEntryPalette.accent.opacity(0.14))
                    .frame(width: 120, height: 120)
                    .blur(radius: 18)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                JournalEntryPalette.accent.opacity(0.9),
                                JournalEntryPalette.accent.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 82, height: 82)
                    .shadow(color: JournalEntryPalette.accent.opacity(0.35), radius: 14, x: 0, y: 6)

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 28)

            // Typography - Apple style
            VStack(spacing: 8) {
                Text("All Done")
                    .font(.instrumentSerif(size: 30))
                    .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

                Text("Reflection complete")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
            }
            .padding(.bottom, 32)

            // Encouragement message
            Text(encouragementMessage)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 38)
                .padding(.bottom, 34)

            // Countdown (if active)
            if nextSubmissionTime != nil {
                VStack(spacing: 12) {
                    Text("Next available in")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(timeRemainingString())
                        .font(.instrumentSerif(size: 48))
                        .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))
                        .monospacedDigit()

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(JournalEntryPalette.fill(for: colorScheme))
                                .frame(height: 4)

                            Capsule()
                                .fill(JournalEntryPalette.accent)
                                .frame(width: geometry.size.width * cooldownProgress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .frame(maxWidth: 200)
                }
                .padding(.bottom, 40)
            }

            Spacer()

            // Action Buttons - Apple style
            VStack(spacing: 12) {
                // Primary: Practice Breathing
                Button(action: { showBreathingExercise = true }) {
                    Label("Practice Breathing", systemImage: "wind")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(JournalEntryPalette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Secondary: View Progress
                Button(action: { showEvaluations = true }) {
                    Label("View Progress", systemImage: "chart.xyaxis.line")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(JournalEntryPalette.fill(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Dismiss
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(JournalEntryPalette.accent)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var cooldownProgress: Double {
        guard let nextTime = nextSubmissionTime else { return 0 }
        let totalCooldown: TimeInterval = 4 * 60 * 60 // 4 hours in seconds
        let remaining = nextTime.timeIntervalSince(Date())
        let elapsed = totalCooldown - remaining
        return min(max(elapsed / totalCooldown, 0), 1)
    }

    private var entryForm: some View {
        VStack(spacing: 20) {
            headerSection
            contentInputArea
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Time-based greeting with refined typography
            VStack(alignment: .leading, spacing: 10) {
                Text(timeBasedPrompt)
                    .font(.instrumentSerif(size: 34))
                    .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

                Text(motivationalSubtitle)
                    .font(.quicksand(size: 16, weight: .regular))
                    .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
            }

            // Stats pills - modern minimal design
            HStack(spacing: 12) {
                // Word count pill
                HStack(spacing: 6) {
                    Text("A")
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(wordCount > 0 ? JournalEntryPalette.accent : JournalEntryPalette.tertiaryText(for: colorScheme))

                    Text("\(wordCount)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(wordCount > 0 ? JournalEntryPalette.primaryText(for: colorScheme) : JournalEntryPalette.tertiaryText(for: colorScheme))
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(wordCount > 0 ? JournalEntryPalette.accent.opacity(0.1) : JournalEntryPalette.fill(for: colorScheme))
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: wordCount)

                // Streak pill (if active)
                if gameStatsManager.gameStats.currentStreak > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "FF9500"))

                        Text("\(gameStatsManager.gameStats.currentStreak)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FF9500").opacity(0.1))
                    )
                }

                Spacer()
            }
        }
    }

    private var timeBasedIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            return "sun.horizon.fill"
        } else if hour >= 12 && hour < 17 {
            return "sun.max.fill"
        } else if hour >= 17 && hour < 21 {
            return "sunset.fill"
        } else {
            return "moon.stars.fill"
        }
    }

    private var timeBasedPrompt: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            return "Good morning"
        } else if hour >= 12 && hour < 17 {
            return "Afternoon check-in"
        } else if hour >= 17 && hour < 21 {
            return "Evening reflection"
        } else {
            return "Night thoughts"
        }
    }

    private var motivationalSubtitle: String {
        let subtitles = [
            "What's alive in you right now?",
            "Take a moment to reflect",
            "Your thoughts matter",
            "How are you really feeling?",
            "Let it out, no judgment here"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return subtitles[dayOfYear % subtitles.count]
    }



    private var contentInputArea: some View {
        VStack(spacing: 24) {
            // Modern text input with subtle border
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(JournalEntryPalette.inputBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isTextEditorFocused
                                    ? JournalEntryPalette.accent.opacity(0.3)
                                    : JournalEntryPalette.separator(for: colorScheme),
                                lineWidth: 1
                            )
                    )

                TextEditor(text: $content)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(minHeight: 160)

                // Placeholder
                if content.isEmpty && !isRecording {
                    Text("What's on your mind?")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(JournalEntryPalette.tertiaryText(for: colorScheme))
                        .padding(.horizontal, 21)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
            .focused($isTextEditorFocused)
            .opacity(isRecording || whisperService.isProcessing ? 0.4 : 1.0)
            .disabled(isRecording || whisperService.isProcessing)
            .animation(.easeOut(duration: 0.2), value: isTextEditorFocused)

            // Voice recording section - seamless inline design
            voiceRecordingSection

            // Validation message
            if !content.isEmpty && !isContentValid(content) {
                validationMessageView
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRecording)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: whisperService.isProcessing)
    }

    // MARK: - Voice Recording Section
    private var voiceRecordingSection: some View {
        Group {
            if isRecording {
                // Active recording state - immersive design
                activeRecordingView
            } else if whisperService.isProcessing {
                // Processing state
                processingView
            } else {
                // Idle state - tap to record
                voiceRecordingButton
            }
        }
    }

    private var activeRecordingView: some View {
        VStack(spacing: 28) {
            // Live waveform visualizer
            recordingVisualizer
                .frame(height: 48)
                .padding(.horizontal, 16)

            // Recording time display
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(JournalEntryPalette.accent)
                        .frame(width: 8, height: 8)
                        .opacity(pulsingRecordingDot ? 1 : 0.4)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsingRecordingDot)

                    Text(formatRecordingTime(recordingDuration))
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Text("Recording...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
            }

            // Stop button - clean design
            Button(action: stopRecording) {
                HStack(spacing: 10) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12, weight: .bold))

                    Text("Stop")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(JournalEntryPalette.accent)
                        .shadow(color: JournalEntryPalette.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(
            ZStack {
                // Base dark layer
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color(hex: "F8F8FA"))

                // Liquid glass overlay
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.5))

                // Subtle gradient
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.8),
                                colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.08), radius: 20, x: 0, y: 10)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.96).combined(with: .opacity),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        ))
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            // Animated processing indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(JournalEntryPalette.accent)
                        .frame(width: 10, height: 10)
                        .scaleEffect(processingDotScale(for: index))
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: whisperService.isProcessing
                        )
                }
            }
            .padding(.top, 8)

            Text("Transcribing...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(JournalEntryPalette.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(JournalEntryPalette.separator(for: colorScheme), lineWidth: 1)
                )
        )
        .transition(.opacity)
    }

    private func processingDotScale(for index: Int) -> CGFloat {
        whisperService.isProcessing ? 1.3 : 0.7
    }

    private var voiceRecordingButton: some View {
        Button(action: {
            isTextEditorFocused = false
            startRecording()
        }) {
            HStack(spacing: 16) {
                // Microphone icon with animated ring
                ZStack {
                    // Subtle outer glow
                    Circle()
                        .fill(JournalEntryPalette.accent.opacity(0.08))
                        .frame(width: 56, height: 56)

                    // Gradient ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    JournalEntryPalette.accent.opacity(0.6),
                                    JournalEntryPalette.accent.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(JournalEntryPalette.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Record voice note")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

                    Text("Tap to start recording")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
                }

                Spacer()

                // Waveform indicator
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(JournalEntryPalette.tertiaryText(for: colorScheme))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(JournalEntryPalette.cardBackground(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(JournalEntryPalette.separator(for: colorScheme), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .transition(.opacity)
    }

    @State private var pulsingRecordingDot = false
    @State private var waveformHeights: [CGFloat] = Array(repeating: 4, count: 24)
    @State private var waveformTimer: Timer?

    private var recordingVisualizer: some View {
        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        LinearGradient(
                            colors: [
                                JournalEntryPalette.accent,
                                JournalEntryPalette.accentSecondary
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: waveformHeights[i])
                    .animation(
                        .spring(response: 0.15, dampingFraction: 0.6),
                        value: waveformHeights[i]
                    )
            }
        }
        .onAppear {
            if isRecording {
                startWaveformAnimation()
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startWaveformAnimation()
            } else {
                stopWaveformAnimation()
            }
        }
    }

    private func startWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            updateWaveformHeights()
        }
    }

    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            waveformHeights = Array(repeating: 4, count: 24)
        }
    }

    private func updateWaveformHeights() {
        // Create smooth wave-like animation with center emphasis
        var newHeights: [CGFloat] = []
        for i in 0..<24 {
            let centerDistance = abs(CGFloat(i) - 11.5) / 11.5
            let maxHeight: CGFloat = 48 * (1.0 - centerDistance * 0.5)
            let minHeight: CGFloat = 6
            let randomHeight = CGFloat.random(in: minHeight...maxHeight)
            newHeights.append(randomHeight)
        }
        waveformHeights = newHeights
    }

    private var validationMessageView: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "FF9500"))

            Text(validationErrorMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme).opacity(0.8))
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "FF9500").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "FF9500").opacity(0.2), lineWidth: 1)
                )
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    

    







    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red)

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.red.opacity(0.1))
        )
    }



    // MARK: - Functions

    private func debouncedUpdateWordCount() {
        wordCountUpdateTask?.cancel()

        wordCountUpdateTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if !Task.isCancelled {
                await MainActor.run {
                    updateWordCount()
                }
            }
        }
    }

    private func updateWordCount() {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            wordCount = 0
            return
        }
        
        var count = 0
        var inWord = false
        
        for char in trimmed {
            if char.isWhitespace || char.isNewline {
                if inWord {
                    count += 1
                    inWord = false
                }
            } else {
                inWord = true
            }
        }
        
        if inWord {
            count += 1
        }
    }
    
    private func startRecording() {
        let permission = AVAudioSession.sharedInstance().recordPermission

        if permission == .denied {
            showingMicrophonePermissionAlert = true
            return
        }

        // Dismiss keyboard first
        isTextEditorFocused = false

        // Immediate haptic feedback for responsiveness
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()

        // Update UI state immediately for instant feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isRecording = true
            recordingDuration = 0
            pulsingRecordingDot = true
        }

        // Start recording timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }

        // Start waveform animation
        startWaveformAnimation()

        // Start actual recording asynchronously to avoid blocking UI
        Task {
            whisperService.startRecording()
        }
    }
    
    private func stopRecording() {
        // Immediate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Stop timers
        recordingTimer?.invalidate()
        recordingTimer = nil

        // Stop waveform animation
        stopWaveformAnimation()

        // Update UI state with smooth animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isRecording = false
            pulsingRecordingDot = false
        }

        // Stop recording (this triggers processing)
        whisperService.stopRecording()
    }
    
    private func formatRecordingTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func loadExistingEntry() {
        if let entry = existingEntry {
            content = entry.content
        }
    }

    // MARK: - Content Validation
    
    private func isContentValid(_ text: String, logFailures: Bool = false) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Minimum length check (at least 15 characters)
        guard trimmed.count >= 15 else {
            if logFailures {
                debugPrint("❌ Content too short: \(trimmed.count) characters")
            }
            return false
        }
        
        // Minimum word count (at least 3 words)
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard words.count >= 3 else {
            if logFailures {
                debugPrint("❌ Too few words: \(words.count) words")
            }
            return false
        }
        
        // Check if content is just repetitive characters or nonsense
        if isRepetitiveText(trimmed) {
            if logFailures {
                debugPrint("❌ Content is repetitive or nonsense")
            }
            return false
        }
        
        // Check if content is just punctuation or special characters
        let alphanumericCount = trimmed.filter { $0.isLetter || $0.isNumber }.count
        guard Double(alphanumericCount) / Double(trimmed.count) > 0.5 else {
            if logFailures {
                debugPrint("❌ Content is mostly punctuation/special characters")
            }
            return false
        }
        
        return true
    }
    
    private func isRepetitiveText(_ text: String) -> Bool {
        // Check for repetitive single characters (e.g., "aaaaa", ".....", "11111")
        let uniqueChars = Set(text.lowercased())
        if uniqueChars.count <= 2 && text.count > 10 {
            return true
        }
        
        // Check for repetitive words (e.g., "test test test test")
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count >= 3 {
            let uniqueWords = Set(words)
            let repetitionRatio = Double(words.count) / Double(uniqueWords.count)
            if repetitionRatio > 3.0 {
                return true
            }
        }
        
        return false
    }
    
    private var validationErrorMessage: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        if trimmed.isEmpty {
            return "Your entry is empty. Take a moment to reflect on your feelings."
        } else if trimmed.count < 15 {
            return "Your entry is too brief. Share a bit more about what's on your mind."
        } else if words.count < 3 {
            return "Try writing at least a few words to express your thoughts."
        } else if isRepetitiveText(trimmed) {
            return "Your entry seems incomplete. Take your time to reflect meaningfully."
        } else {
            let alphanumericCount = trimmed.filter { $0.isLetter || $0.isNumber }.count
            if Double(alphanumericCount) / Double(trimmed.count) <= 0.5 {
                return "Please write a genuine reflection using words, not just symbols."
            }
        }
        
        return "Please write a thoughtful reflection."
    }
    
    private func saveEntry() {
        guard let currentUser = databaseService.currentUser else { return }
        
        // Validate content before saving
        guard isContentValid(content, logFailures: true) else {
            // Show validation error to user
            debugPrint("❌ Validation failed: \(validationErrorMessage)")
            // You can show an alert here if you want
            return
        }
        
        isLoading = true

        Task {
            let entry = SupabaseJournalEntry(
                id: existingEntry?.id ?? UUID(),
                userId: currentUser.id,
                createdAt: existingEntry?.createdAt ?? Date(),
                updatedAt: Date(),
                title: nil, // No title field - client only fills out content
                content: content,
                mood: nil,
                gratitudeItems: nil, // No gratitude items
                tags: nil, // No tags
                isPrivate: false
            )

            // Process gamification and record submission BEFORE trying to save to database
            // This way it works even if database is offline
            if existingEntry == nil {
                await MainActor.run {
                    gameStatsManager.processNewJournalEntry(entry)

                    // Record the submission time for cooldown tracking
                    ReflectionNotificationManager.shared.recordJournalSubmission(userId: currentUser.id)

                    // Update smart notifications (don't notify if user just reflected)
                    Task {
                        await ReflectionNotificationManager.shared.checkAndScheduleSmartReminders()
                    }

                    // Check if now on cooldown after submission
                    checkSubmissionRestrictions()

                    // Show a brief success message if now on cooldown
                    if isBlockedFromSubmitting {
                        debugPrint("🎉 Entry saved! Now on cooldown until next submission time.")
                    }
                }
            }

            // Try to save to database (may fail if offline, but submission is already tracked)
            do {
                try await databaseService.saveJournalEntry(entry)
                debugPrint("✅ Successfully saved entry to database")
            } catch {
                debugPrint("⚠️ Database save failed, but entry is tracked locally: \(error)")
                // Continue anyway - the submission is already tracked locally
            }

            await MainActor.run {
                // Stop the countdown timer when saving completes
                countdownTimer?.invalidate()
                countdownTimer = nil
                
                // Post notification to refresh home view
                NotificationCenter.default.post(name: Notification.Name("JournalEntrySubmitted"), object: nil)

                // Only dismiss if not showing countdown
                presentationMode.wrappedValue.dismiss()
            }
            
            // Trigger analysis check after successful journal submission
            // Use Task (not detached) so it continues even after view dismisses
            Task {
                debugPrint("🚀 Starting analysis task...")
                await JournalAnalysisService.shared.checkAndAnalyzeIfNeeded(for: currentUser.id.uuidString)
                debugPrint("🏁 Analysis task completed")
            }
            
            // Trigger LLM pattern extraction to update mood predictions
            // This runs in background and extracts patterns like occupation type, significant dates
            Task {
                debugPrint("🧠 Starting pattern extraction...")
                let recentEntries = try? await databaseService.getJournalEntries(userId: currentUser.id, limit: 10)
                if let entries = recentEntries, entries.count >= 3 {
                    await PatternExtractionService.shared.extractPatterns(from: entries, userId: currentUser.id)
                    debugPrint("✅ Pattern extraction completed")
                }
            }
        }
    }

    // MARK: - Helper Methods for Submission Restrictions

    private func hasUserSubmittedToday(userId: UUID, timeSlot: TimeSlot) -> Bool {
        // Use the same key format consistently
        let periodName = timeSlot == .morning ? "Morning" : "Evening"
        let key = "hasSubmittedIn\(periodName)"
        let resetTimeKey = "submissionResetTime\(periodName)"

        // Check if user has submitted and if the cooldown is still active
        if UserDefaults.standard.bool(forKey: key) {
            // Check if the reset time has passed
            if let storedResetTime = UserDefaults.standard.object(forKey: resetTimeKey) as? Date {
                if Date() >= storedResetTime {
                    // Reset time has passed, clear the flags
                    UserDefaults.standard.removeObject(forKey: key)
                    UserDefaults.standard.removeObject(forKey: resetTimeKey)
                    return false
                } else {
                    // Still in cooldown period
                    return true
                }
            } else {
                // No reset time stored but flag is set, assume it's still valid
                return true
            }
        }
        return false
    }

    private func markSubmissionForToday(userId: UUID, timeSlot: TimeSlot) {
        // Use the same key format as GamifiedJournalView expects
        let periodName = timeSlot == .morning ? "Morning" : "Evening"
        let key = "hasSubmittedIn\(periodName)"

        UserDefaults.standard.set(true, forKey: key)

        // Also set the timestamp for when this period expires
        let nextResetTime = ReflectionNotificationManager.shared.getNextResetTime()
        UserDefaults.standard.set(nextResetTime, forKey: "submissionResetTime\(periodName)")
    }

    private func checkSubmissionRestrictions() {
        guard let currentUser = databaseService.currentUser else {
            debugPrint("🚫 No current user for submission check")
            return
        }

        Task {
            let reflectionManager = ReflectionNotificationManager.shared

            // Check if user is on cooldown based on their last submission
            #if DEBUG
            if await reflectionManager.isUserOnCooldown(userId: currentUser.id) && !isDebugOverrideEnabled {
                let nextTime = await reflectionManager.getNextSubmissionTime(userId: currentUser.id)
                let remainingTime = await reflectionManager.getRemainingCooldownTime(userId: currentUser.id)

                debugPrint("⏰ User is on cooldown for \(Int(remainingTime/60)) minutes")
                debugPrint("⏰ Next submission allowed at: \(nextTime?.description ?? "unknown")")

                await MainActor.run {
                    isBlockedFromSubmitting = true
                    nextSubmissionTime = nextTime
                    startCountdownTimer()
                }
            } else {
                debugPrint("✅ Submission allowed - no active cooldown")
                await MainActor.run {
                    isBlockedFromSubmitting = false
                    nextSubmissionTime = nil
                }
            }
            #else
            if await reflectionManager.isUserOnCooldown(userId: currentUser.id) {
                let nextTime = await reflectionManager.getNextSubmissionTime(userId: currentUser.id)
                let remainingTime = await reflectionManager.getRemainingCooldownTime(userId: currentUser.id)

                debugPrint("⏰ User is on cooldown for \(Int(remainingTime/60)) minutes")
                debugPrint("⏰ Next submission allowed at: \(nextTime?.description ?? "unknown")")

                await MainActor.run {
                    isBlockedFromSubmitting = true
                    nextSubmissionTime = nextTime
                    startCountdownTimer()
                }
            } else {
                debugPrint("✅ Submission allowed - no active cooldown")
                await MainActor.run {
                    isBlockedFromSubmitting = false
                    nextSubmissionTime = nil
                }
            }
            #endif
        }
    }

    private func startCountdownTimer() {
        debugPrint("🎬 Starting countdown timer")
        countdownTimer?.invalidate() // Cancel any existing timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let nextTime = self.nextSubmissionTime else {
                debugPrint("❌ No next time set, invalidating timer")
                self.countdownTimer?.invalidate()
                return
            }

            let timeLeft = nextTime.timeIntervalSince(Date())
            // Removed debug print to reduce console spam

            if Date() >= nextTime {
                debugPrint("✅ Time's up! Unblocking submissions")
                // Time's up, reset the blocked state
                self.isBlockedFromSubmitting = false
                self.nextSubmissionTime = nil
                self.countdownTimer?.invalidate()
            }
        }
    }

    private func timeRemainingString() -> String {
        guard let nextTime = nextSubmissionTime else { return "" }

        let timeInterval = nextTime.timeIntervalSince(Date())
        if timeInterval <= 0 { return "Available now!" }

        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        } else {
            return String(format: "%d min", minutes > 0 ? minutes : 1)
        }
    }

    private func checkMicrophonePermissionAndRecord() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // Permission granted, start recording
                Task {
                    whisperService.startRecording()
                }
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                // Permission denied, show alert
                DispatchQueue.main.async {
                    self.showingMicrophonePermissionAlert = true
                }
            }
        }
    }
}

struct PointsBreakdownRow: View {
    let label: String
    let points: Int
    let isEarned: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(isEarned ? .white : Color.white.opacity(0.5))

            Spacer()

            HStack(spacing: 2) {
                Text("+\(points)")
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(isEarned ? Color(hex: "FFD700") : Color.white.opacity(0.5))

                Image(systemName: "star.fill")
                    .font(.quicksand(size: 8))
                    .foregroundColor(isEarned ? Color(hex: "FFD700") : Color.white.opacity(0.5))
            }
        }
        .opacity(isEarned ? 1.0 : 0.5)
    }
}

// MARK: - Preview Helpers
struct GamifiedJournalEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            GamifiedJournalEntryView()
                .previewDisplayName("Normal State")
            
            // Cooldown state simulation
            GamifiedJournalEntryViewWithCooldown()
                .previewDisplayName("Cooldown State")
        }
    }
}

struct GamifiedJournalEntryViewWithCooldown: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isBlockedFromSubmitting = true
    @State private var nextSubmissionTime: Date? = Calendar.current.date(byAdding: .hour, value: 2, to: Date())
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "xmark")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("New Entry")
                                .font(.quicksand(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Express yourself")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "checkmark")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Time to rest notification
                            timeToRestNotification
                            
                            // Blocked submission view
                            blockedSubmissionView
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
    
    private var timeToRestNotification: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF5C7A").opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.quicksand(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5C7A"))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Time to Rest & Reflect")
                    .font(.quicksand(size: 17, weight: .bold))
                    .foregroundColor(JournalEntryPalette.primaryText(for: colorScheme))

                Text("You've shared your thoughts. Take time to process before your next reflection.")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(JournalEntryPalette.secondaryText(for: colorScheme))
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(JournalEntryPalette.fill(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(JournalEntryPalette.separator(for: colorScheme), lineWidth: 1)
                )
        )
    }

    private var blockedSubmissionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FF5C7A").opacity(0.3),
                                    Color(hex: "FF5C7A").opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF5C7A"),
                                    Color(hex: "FF8FA3")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color(hex: "FF5C7A").opacity(0.5), radius: 20, x: 0, y: 8)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.quicksand(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Reflection Complete")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(.white)
            }

            Text("You've already reflected this morning. Your next opportunity is this evening starting at 5 PM.")
                .font(.quicksand(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 20)

            if let nextTime = nextSubmissionTime {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.quicksand(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "FF5C7A"))

                        Text("Next opportunity in")
                            .font(.quicksand(size: 14, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }

                    Text("03:30")
                        .font(.instrumentSerif(size: 36))
                        .foregroundColor(Color(hex: "FF5C7A"))
                        .monospacedDigit()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(JournalEntryPalette.fill(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color(hex: "FF5C7A").opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(JournalEntryPalette.fill(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(JournalEntryPalette.separator(for: colorScheme), lineWidth: 1)
                )
        )
    }
}

// MARK: - Premium Button Style
// ScaleButtonStyle is defined in DesignSystem/WebDSComponents.swift
