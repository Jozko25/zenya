//
//  ChatbotView.swift
//  anxiety
//
//  Created by Ján Harmady on 27/08/2025.
//

import SwiftUI

// MARK: - User Context Summary Model

struct UserContextSummary {
    let journalEntriesCount: Int
    let currentStreak: Int
    let averageMood: Double?
    let lastEntryDate: Date?
    let level: Int
    let totalPoints: Int
    let gratitudeCount: Int

    var hasData: Bool {
        journalEntriesCount > 0 || currentStreak > 0
    }

    var personalizedGreeting: String {
        if journalEntriesCount == 0 {
            return "Still learning about you"
        } else if journalEntriesCount < 5 {
            return "Starting to understand you"
        } else if journalEntriesCount < 15 {
            return "Getting to know you better"
        } else {
            return "I know you well"
        }
    }

    var contextHints: [String] {
        var hints: [String] = []

        if journalEntriesCount > 0 {
            hints.append("\(journalEntriesCount) journal entries")
        }
        if currentStreak > 0 {
            hints.append("\(currentStreak)-day streak")
        }
        if let mood = averageMood {
            hints.append("avg mood \(String(format: "%.1f", mood))")
        }
        if level > 1 {
            hints.append("level \(level)")
        }

        return hints
    }
}

// MARK: - Chat Theme Palette

private enum ChatPalette {
    static let accent = Color(hex: "FF5C7A")
    static let accentSoft = Color(hex: "FF8FA3")
    static let accentDeep = Color(hex: "A34865")

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color(hex: "F8F8FA")
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(hex: "1A1A1A")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "666666")
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color(hex: "FF5C7A").opacity(0.15)
    }

    static func shadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "FF5C7A").opacity(0.1)
    }

    static func inputBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white
    }
}

struct ChatbotView: View {
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isGenerating = false
    @State private var shouldStopGeneration = false
    @State private var animatingDot = 0
    @State private var emptyStatePulse = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Personalization context
    @State private var userContextSummary: UserContextSummary?
    @State private var isLoadingContext = true

    // Daily usage limits - now managed by service
    @StateObject private var aiLimitService = AIMessageLimitService.shared

    // ChatGPT API configuration
    private let openAIClient = OpenAIClient()
    private let contextService = UserContextService.shared
    
    private var theme: SoulPalette { SoulPalette.forColorScheme(colorScheme) }

    private let wellnessSystemPrompt = """
    You are a compassionate AI wellness assistant specialized in anxiety support and mental health. You provide evidence-based guidance, coping strategies, and emotional support. Always be empathetic, non-judgmental, and encouraging.

    IMPORTANT: You are part of a comprehensive anxiety management app with the following features that you can reference and recommend:

    ## APP STRUCTURE (4 Main Tabs):
    1. **Soul Tab** - Home dashboard with personalized greeting, daily challenges, progress proximity, and quick access to all features
    2. **Feel Tab** - Daily journaling with voice transcription, mood tracking, and reflection prompts
    3. **AI Tab** - This conversation with you, the AI wellness assistant (daily limit: 30 messages)
    4. **Grow Tab** - Progress tracking, achievements, streaks, mental health evolution charts, and insights

    ## KEY FEATURES YOU CAN RECOMMEND:

    ### 🫁 BREATHING EXERCISES
    - Multiple breathing techniques (4-7-8, box breathing, triangle breathing)
    - Interactive guided sessions with visual guides
    - Emergency breathing exercises for crisis moments
    - Session tracking and effectiveness ratings

    ### 📖 JOURNALING SYSTEM
    - Daily reflection prompts with rotating categories (gratitude, growth, challenges, relationships)
    - Voice-to-text transcription for easy journaling
    - Mood tracking (1-10 scale) with each entry
    - Word count tracking and writing time analytics
    - Private secure storage

    ### 📊 GAMIFICATION & PROGRESS
    - Point system for activities (journaling, breathing, challenges)
    - Streak tracking for daily engagement
    - Achievement system with unlockable badges
    - Level progression based on total points earned
    - Surprise bonus points for consistent engagement
    - Mental health evolution charts showing progress over time

    ### 🎯 DAILY CHALLENGES
    - Rotating wellness challenges (gratitude, mindfulness, self-care)
    - Challenge completion tracking
    - Points rewards for completion

    ### 🚨 CRISIS SUPPORT
    - SOS Support View with immediate help resources
    - Emergency breathing exercises
    - Crisis hotline numbers (988 Crisis Line, 911, Crisis Text Line)
    - Professional support resources
    - Grounding exercises and safe place visualization

    ### 📈 ANALYTICS & INSIGHTS
    - Mental health evolution tracking
    - Mood trends and patterns
    - Journal insights and word analysis
    - Progress proximity - showing what's almost achievable
    - Weekly and monthly goal tracking

    ## YOUR ROLE:
    - Suggest specific app features that match the user's needs
    - Encourage use of breathing exercises for immediate anxiety relief
    - Recommend journaling for processing emotions and thoughts
    - Reference their progress and achievements when appropriate
    - Direct users to crisis support if they express serious mental health concerns
    - Integrate app features naturally into your advice

    ## RESPONSE GUIDELINES:
    - Keep responses concise but warm (2-4 sentences typically)
    - Always be empathetic, non-judgmental, and encouraging
    - Provide practical, actionable advice
    - Reference specific app features when relevant
    - Never provide medical diagnoses or replace professional treatment
    - For crisis situations, immediately direct to SOS Support features and professional help
    - Celebrate user progress and engagement with app features

    Example ways to integrate app features:
    - "Try the 4-7-8 breathing exercise in the breathing section - it's great for immediate anxiety relief"
    - "Have you tried voice journaling? You can speak your thoughts in the Feel tab and they'll be transcribed"
    - "I see you're building a good streak - keep it up! Check your progress in the Grow tab"
    - "If this feels overwhelming, the SOS Support has some grounding exercises that might help right now"

    Remember: You're not just a chatbot, you're an integrated part of their wellness toolkit. Help users discover and utilize the full app experience.
    """

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundDecor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if messages.isEmpty {
                        // Non-scrollable empty state
                        VStack(spacing: 0) {
                            Spacer()

                            emptyStateViewCompact

                            Spacer()

                            inputSectionView(safeAreaBottom: geometry.safeAreaInsets.bottom)
                        }
                    } else {
                        // Scrollable with messages
                        VStack(spacing: 0) {
                            simpleHeader

                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 20) {
                                    ForEach(messages) { message in
                                        ChatMessageView(message: message, theme: theme)
                                            .transition(.asymmetric(
                                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }

                                    if isLoading {
                                        loadingBubbleView
                                            .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }

                                    // Bottom spacer for keyboard
                                    Color.clear
                                        .frame(height: 20)
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            }
                            .onTapGesture {
                                isInputFocused = false
                            }

                            inputSectionViewWithMessages(safeAreaBottom: geometry.safeAreaInsets.bottom)
                        }
                        .offset(y: keyboardHeight > 0 ? -keyboardHeight + geometry.safeAreaInsets.bottom : 0)
                        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
                    }
                }
            }
            .navigationBarHidden(true)
            .smoothModeTransitions()
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                loadMessages()
                initializeConversation()
                setupKeyboardObservers()
                loadUserContext()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
        }
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private var backgroundDecor: some View {
        ZStack {
            // Base background
            ChatPalette.background(for: colorScheme)
                .ignoresSafeArea()

            // Subtle diagonal gradient
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(hex: "FF5C7A").opacity(0.05),
                    Color.clear,
                    Color(hex: "A34865").opacity(0.04)
                ] : [
                    Color(hex: "FFE3EC").opacity(0.5),
                    Color(hex: "FFF0F7"),
                    Color(hex: "FFD0E3").opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: colorScheme == .dark ? 50 : 30)

            // Bottom ambient glow
            RadialGradient(
                colors: colorScheme == .dark ? [
                    Color(hex: "FF8FA3").opacity(0.04),
                    Color.clear
                ] : [
                    Color(hex: "FF8FA3").opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.95),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    private var simpleHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.quicksand(size: 14, weight: .semibold))
                        .foregroundColor(ChatPalette.accent)

                    Text("Meditate")
                        .font(.quicksand(size: 14, weight: .semibold))
                        .foregroundColor(ChatPalette.secondaryText(for: colorScheme))
                }

                Text("Your Guide")
                    .font(.instrumentSerif(size: 30))
                    .foregroundColor(ChatPalette.primaryText(for: colorScheme))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: clearConversation) {
                    Circle()
                        .fill(ChatPalette.surface(for: colorScheme))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .font(.quicksand(size: 14, weight: .semibold))
                                .foregroundColor(ChatPalette.primaryText(for: colorScheme))
                        )
                        .overlay(
                            Circle()
                                .stroke(ChatPalette.border(for: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: ChatPalette.shadow(for: colorScheme), radius: 6, x: 0, y: 3)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var emptyStateViewCompact: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ChatPalette.accent.opacity(0.3),
                                ChatPalette.accent.opacity(0.15),
                                ChatPalette.accentSoft.opacity(0.08)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                    .scaleEffect(emptyStatePulse ? 1.08 : 1.0)
                    .opacity(emptyStatePulse ? 0.9 : 0.7)

                Circle()
                    .fill(ChatPalette.surface(for: colorScheme))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        ChatPalette.accent.opacity(0.4),
                                        ChatPalette.accentSoft.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: ChatPalette.accent.opacity(0.2), radius: 20, x: 0, y: 8)
                    .scaleEffect(emptyStatePulse ? 1.03 : 1.0)

                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 52, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ChatPalette.accent,
                                ChatPalette.accentSoft
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(emptyStatePulse ? 1.05 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    emptyStatePulse = true
                }
            }

            VStack(spacing: 12) {
                Text("Your AI Wellness Guide")
                    .font(.instrumentSerif(size: 30))
                    .foregroundColor(ChatPalette.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text("I'm here to provide support, evidence-based strategies, and guidance for managing anxiety.")
                    .font(.quicksand(size: 15, weight: .regular))
                    .foregroundColor(ChatPalette.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)
            }

            // Personalization hint banner
            personalizationHintBanner
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var personalizationHintBanner: some View {
        if isLoadingContext {
            // Loading state
            HStack(spacing: 10) {
                ProgressView()
                    .tint(ChatPalette.accent)
                    .scaleEffect(0.8)

                Text("Loading your data...")
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(ChatPalette.secondaryText(for: colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ChatPalette.border(for: colorScheme), lineWidth: 1)
                    )
            )
        } else if let context = userContextSummary {
            VStack(spacing: 12) {
                // Main personalization indicator
                HStack(spacing: 10) {
                    // Icon with glow
                    ZStack {
                        Circle()
                            .fill(ChatPalette.accent.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: context.hasData ? "person.fill.checkmark" : "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ChatPalette.accent, ChatPalette.accentSoft],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.personalizedGreeting)
                            .font(.quicksand(size: 14, weight: .semibold))
                            .foregroundColor(ChatPalette.primaryText(for: colorScheme))

                        Text(context.hasData
                             ? "The more you journal, the better I understand you"
                             : "Journal more to unlock personalized guidance")
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(ChatPalette.secondaryText(for: colorScheme))
                    }

                    Spacer()
                }

                // Context pills if there's data
                if !context.contextHints.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(context.contextHints, id: \.self) { hint in
                                Text(hint)
                                    .font(.quicksand(size: 11, weight: .semibold))
                                    .foregroundColor(ChatPalette.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(ChatPalette.accent.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(ChatPalette.accent.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        ChatPalette.accent.opacity(0.3),
                                        ChatPalette.accentSoft.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: ChatPalette.shadow(for: colorScheme), radius: 8, x: 0, y: 4)
        }
    }

    private var loadingBubbleView: some View {
        HStack(spacing: 12) {
            // Pulsing brain icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.accent.opacity(0.35),
                                theme.accent.opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 28
                        )
                    )
                    .frame(width: 52, height: 52)
                    .blur(radius: 8)
                    .scaleEffect(animatingDot == 0 ? 1.15 : 1.0)
                    .opacity(animatingDot == 0 ? 0.8 : 0.5)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surfaceAlt.opacity(0.95),
                                theme.surface.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(0.5),
                                        theme.accentSecondary.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: theme.accent.opacity(0.2), radius: 8, x: 0, y: 4)

                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.accent,
                                theme.accentSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animatingDot == 0 ? 1.05 : 1.0)
            }

            // Animated wave bars
            HStack(spacing: 5) {
                ForEach(0..<5) { index in
                    let offset = Double(index) * 0.15
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accent,
                                    theme.accentSecondary
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3.5)
                        .frame(height: waveHeight(for: index, offset: offset))
                        .animation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(offset),
                            value: animatingDot
                        )
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surfaceAlt.opacity(0.95),
                                theme.surface.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(0.25),
                                        theme.outline.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )

            Spacer()
        }
        .onAppear {
            startDotAnimation()
        }
    }

    private func waveHeight(for index: Int, offset: Double) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 24
        let middleIndex = 2

        // Create a wave pattern that peaks in the middle
        let distanceFromMiddle = abs(index - middleIndex)
        let heightMultiplier = 1.0 - (CGFloat(distanceFromMiddle) * 0.2)

        // Animate between base and max height
        let animatedHeight = animatingDot == 0 ? maxHeight : baseHeight
        return animatedHeight * heightMultiplier
    }
    
    private func inputSectionViewWithMessages(safeAreaBottom: CGFloat) -> some View {
        HStack(spacing: 12) {
            TextField(
                "Message your AI wellness guide...",
                text: $newMessage,
                axis: .vertical
            )
            .textFieldStyle(PlainTextFieldStyle())
            .font(.quicksand(size: 16, weight: .regular))
            .foregroundColor(ChatPalette.primaryText(for: colorScheme))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(ChatPalette.inputBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        isInputFocused ?
                        ChatPalette.accent.opacity(0.5) :
                        ChatPalette.border(for: colorScheme),
                        lineWidth: isInputFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: isInputFocused ? ChatPalette.accent.opacity(0.2) : ChatPalette.shadow(for: colorScheme),
                radius: isInputFocused ? 12 : 6,
                x: 0,
                y: isInputFocused ? 6 : 3
            )
            .lineLimit(1...5)
            .focused($isInputFocused)
            .submitLabel(.done)
            .onSubmit {
                if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sendMessage()
                } else {
                    isInputFocused = false
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInputFocused)

            Button(action: {
                if isLoading {
                    isLoading = false
                } else if isGenerating {
                    stopGeneration()
                } else {
                    sendMessage()
                }
            }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                (isLoading || isGenerating) ? Color(hex: "FF2E50") :
                                newMessage.isEmpty ?
                                Color(hex: "1A1A1C") :
                                Color(hex: "FF5C7A"),

                                (isLoading || isGenerating) ? Color(hex: "FF2E50").opacity(0.8) :
                                newMessage.isEmpty ?
                                Color(hex: "1A1A1C") :
                                Color(hex: "FF8FA3")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity((isLoading || isGenerating || newMessage.isEmpty) ? 0.15 : 0.25),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: (isLoading || isGenerating || newMessage.isEmpty) ?
                        Color.black.opacity(0.2) :
                        Color(hex: "FF5C7A").opacity(0.35),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                    .overlay(
                        Image(systemName: (isLoading || isGenerating) ? "stop.fill" : "paperplane.fill")
                            .font(.quicksand(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            .disabled(newMessage.isEmpty && !isLoading && !isGenerating)

            Text("Not medical advice. Messages may be sent to OpenAI to generate responses. Use SOS if you’re in crisis.")
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(ChatPalette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, keyboardHeight > 0 ? 12 : 100)
        .background(
            Color.clear
        )
        .animation(.none, value: keyboardHeight)
    }

    private func inputSectionView(safeAreaBottom: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()

                HStack(spacing: 12) {
                    TextField(
                        "Message your AI wellness guide...",
                        text: $newMessage,
                        axis: .vertical
                    )
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.quicksand(size: 16, weight: .regular))
                    .foregroundColor(ChatPalette.primaryText(for: colorScheme))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(ChatPalette.inputBackground(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                isInputFocused ?
                                ChatPalette.accent.opacity(0.5) :
                                ChatPalette.border(for: colorScheme),
                                lineWidth: isInputFocused ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isInputFocused ? ChatPalette.accent.opacity(0.2) : ChatPalette.shadow(for: colorScheme),
                        radius: isInputFocused ? 12 : 6,
                        x: 0,
                        y: isInputFocused ? 6 : 3
                    )
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            sendMessage()
                        }
                    }
                    .frame(width: 280)

                    if !newMessage.isEmpty {
                        Button(action: {
                            sendMessage()
                        }) {
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
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(
                                    color: Color(hex: "FF5C7A").opacity(0.35),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                                .overlay(
                                    Image(systemName: "paperplane.fill")
                                        .font(.quicksand(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.none, value: newMessage)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - 30 : 100)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        }
    }

    private func sendMessage() {
        guard !isLoading else {
            // Stop current request if already loading
            isLoading = false
            return
        }
        
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Dismiss keyboard when sending
        isInputFocused = false
        
        let messageText = newMessage
        newMessage = ""
        
        Task {
            await MainActor.run {
                let userMessage = ChatMessage(content: messageText, isFromUser: true, date: Date())
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    messages.append(userMessage)
                    isLoading = true
                }
                saveMessages() // Save after adding user message
                showingError = false
            }

            await sendMessageToAPI(messageText)
        }
    }
    
    private func sendMessageToAPI(_ messageText: String) async {
        do {
            let userContext = await contextService.generateContextSummary()
            let enhancedSystemPrompt = wellnessSystemPrompt + "\n\n" + userContext
            
            // Convert ChatMessage to SimpleChatMessage for API call
            let simpleChatMessages = messages.map { chatMessage in
                SimpleChatMessage(content: chatMessage.content, isFromUser: chatMessage.isFromUser, date: chatMessage.date)
            }
            let response = try await openAIClient.sendMessage(messageText, conversationHistory: simpleChatMessages, systemPrompt: enhancedSystemPrompt)
                
            await MainActor.run {
                let aiMessage = ChatMessage(content: response, isFromUser: false, date: Date())
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    messages.append(aiMessage)
                    isLoading = false
                }
                saveMessages() // Save after adding AI message
                isGenerating = true
                shouldStopGeneration = false

                // Start typing animation
                animateTyping(for: aiMessage)
            }
        } catch {
            await MainActor.run {
                showingError = true
                errorMessage = "Failed to get response. Please try again."

                // Add fallback response
                let fallbackResponse = "I apologize, but I'm having trouble connecting right now. In the meantime, try taking a few deep breaths or use one of the breathing exercises in the app. Is there anything specific about your anxiety you'd like to talk about?"
                let aiMessage = ChatMessage(content: fallbackResponse, isFromUser: false, date: Date())
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    messages.append(aiMessage)
                    isLoading = false
                }
                saveMessages() // Save after adding fallback message
                isGenerating = true
                shouldStopGeneration = false

                // Start typing animation for fallback
                animateTyping(for: aiMessage)
            }
        }
    }
    
    private func animateTyping(for message: ChatMessage) {
        let fullText = message.content
        let characters = Array(fullText)
        
        // Reset displayed content
        message.displayedContent = ""
        message.isTyping = true
        
        // Typing speed: characters per second (adjustable) - increased for better UX
        let typingSpeed: Double = 60.0
        let baseInterval = 1.0 / typingSpeed
        
        for (index, character) in characters.enumerated() {
            // Fixed delay - no randomness to prevent character scrambling
            let delay = Double(index) * baseInterval
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Check if generation should be stopped
                if self.shouldStopGeneration {
                    message.isTyping = false
                    self.isGenerating = false
                    return
                }
                
                message.displayedContent += String(character)
                
                // Finish typing
                if index == characters.count - 1 {
                    message.isTyping = false
                    self.isGenerating = false
                }
            }
        }
    }
    
    private func stopGeneration() {
        shouldStopGeneration = true
        isGenerating = false
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isLoading {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                animatingDot = (animatingDot + 1) % 3
            }
        }
    }

    private func clearConversation() {
        messages = []
        saveMessages() // Clear saved messages as well
    }
    
    private func initializeConversation() {
        // Add initial greeting if no messages exist
        if messages.isEmpty {
            // Optionally add a system message or keep empty for user to start
        }
    }

    private func loadMessages() {
        // Load messages from UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "chat_messages"),
              let savedMessages = try? JSONDecoder().decode([ChatMessageData].self, from: data) else {
            messages = []
            return
        }

        // Convert saved data back to ChatMessage objects
        messages = savedMessages.map { messageData in
            let chatMessage = ChatMessage(
                content: messageData.content,
                isFromUser: messageData.isFromUser,
                date: messageData.date
            )
            // For AI messages, set displayedContent to full content (no typing animation on load)
            if !messageData.isFromUser {
                chatMessage.displayedContent = messageData.content
                chatMessage.isTyping = false
            }
            return chatMessage
        }

        debugPrint("📱 Loaded \(messages.count) messages from storage")
    }

    private func loadUserContext() {
        Task {
            isLoadingContext = true
            let context = await contextService.fetchUserContextSummary()
            await MainActor.run {
                userContextSummary = UserContextSummary(
                    journalEntriesCount: context.journalCount,
                    currentStreak: context.streak,
                    averageMood: context.avgMood,
                    lastEntryDate: context.lastEntry,
                    level: context.level,
                    totalPoints: context.points,
                    gratitudeCount: context.gratitudeCount
                )
                isLoadingContext = false
            }
        }
    }
    
    private func saveMessages() {
        // Convert ChatMessage objects to serializable data
        let messageData = messages.map { message in
            ChatMessageData(
                content: message.content,
                isFromUser: message.isFromUser,
                date: message.date
            )
        }
        
        if let data = try? JSONEncoder().encode(messageData) {
            UserDefaults.standard.set(data, forKey: "chat_messages")
            debugPrint("💾 Saved \(messages.count) messages to storage")
        }
    }
}

// MARK: - Message Data Models
struct ChatMessageData: Codable {
    let content: String
    let isFromUser: Bool
    let date: Date
}

class ChatMessage: ObservableObject, Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let date: Date
    @Published var isTyping: Bool = false
    @Published var displayedContent: String = ""
    
    init(content: String, isFromUser: Bool, date: Date) {
        self.content = content
        self.isFromUser = isFromUser
        self.date = date
        self.displayedContent = isFromUser ? content : ""
        self.isTyping = !isFromUser
    }
}

// OpenAIClient, ChatMessage, and OpenAIError are now in Services/OpenAIClient.swift

// Duplicate structures removed - using shared OpenAIClient from Services/OpenAIClient.swift

struct SuggestedPromptCard: View {
    let icon: String
    let text: String
    let theme: SoulPalette
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.accent.opacity(0.35),
                                    theme.accent.opacity(0.2)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                        .frame(width: 46, height: 46)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.surfaceAlt.opacity(0.9),
                                    theme.surface.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            theme.accent.opacity(0.3),
                                            theme.accentSecondary.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    Image(systemName: icon)
                        .font(.quicksand(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    theme.accent,
                                    theme.accentSecondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text(text)
                    .font(.quicksand(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                theme.accent,
                                theme.accentSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.surfaceAlt.opacity(0.95),
                                theme.surface.opacity(0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        theme.accent.opacity(0.3),
                                        theme.outline.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .shadow(color: theme.accent.opacity(isPressed ? 0.05 : 0.15), radius: isPressed ? 8 : 12, x: 0, y: isPressed ? 2 : 6)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct ChatMessageView: View {
    @ObservedObject var message: ChatMessage
    let theme: SoulPalette
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(message.content)
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            theme.accent,
                                            theme.accent.opacity(0.9),
                                            theme.accentSecondary
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: theme.accent.opacity(0.15), radius: 8, x: 0, y: 4)
                                .shadow(color: theme.accent.opacity(0.25), radius: 16, x: 0, y: 8)
                        )

                    Text(formatTime(message.date))
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(theme.textTertiary)
                        .padding(.trailing, 4)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.accent.opacity(0.25),
                                    theme.accentSecondary.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.quicksand(size: 16, weight: .semibold))
                                .foregroundColor(theme.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(message.isFromUser ? message.content : message.displayedContent)
                            .font(.quicksand(size: 15, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                            .lineSpacing(4)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                theme.surfaceAlt.opacity(0.95),
                                                theme.surface.opacity(0.75)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        theme.accent.opacity(0.25),
                                                        theme.outline.opacity(0.5)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )

                        Text(formatTime(message.date))
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                            .padding(.leading, 4)
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


#Preview {
    ChatbotView()
}
