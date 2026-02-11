//
//  ContentView.swift
//  anxiety
//
//  Created by Ján Harmady on 27/08/2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var rewardsManager = ConsolidatedRewardsManager()
    @StateObject private var notificationManager = ReflectionNotificationManager.shared
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var activationService = ActivationService.shared
    @State private var selectedTab = 0
    @State private var showReflectionModal = false
    @State private var showEvaluationsModal = false

    // Onboarding state
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding = false
    @AppStorage("has_active_subscription") private var hasActiveSubscription = false
    @State private var showOnboarding = false
    @State private var showPaywall = true

    // Splash screen state
    @State private var showSplash = true
    @State private var splashOpacity: Double = 1.0
    @State private var splashScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.85
    @State private var pulseAnimation = false
    @State private var orbRotation: Double = 0.0
    @State private var textReveal: Double = 0.0
    @State private var taglineReveal: Double = 0.0
    @State private var glowIntensity: Double = 0.0
    @State private var breatheScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Show onboarding flow for first-time users
                ConversionOnboardingView(isPresented: $showOnboarding)
                    .transition(.opacity)
                    .onDisappear {
                        // Onboarding completed - refresh activation state
                        activationService.checkActivationStatus()
                    }
            } else if !activationService.isActivated && !hasActiveSubscription {
                // User completed onboarding but hasn't subscribed - show paywall
                LiquidGlassPaywallView(isPresented: $showPaywall)
                    .transition(.opacity)
                    .onChange(of: showPaywall) { _, newValue in
                        if !newValue {
                            // Paywall dismissed - check if user subscribed
                            activationService.checkActivationStatus()
                        }
                    }
            } else {
                ZStack {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            // Main Content Area
                            Group {
                                switch selectedTab {
                                case 0:
                                    EnhancedHomeView(selectedTab: $selectedTab)
                                        .id("home")
                                case 1:
                                    GamifiedJournalView()
                                        .id("journal")
                                case 2:
                                    ChatbotView()
                                        .id("chatbot")
                                case 3:
                                    EnhancedAnalyticsView()
                                        .id("analytics")
                                default:
                                    EnhancedHomeView(selectedTab: $selectedTab)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .environment(\.deviceWidth, geometry.size.width)
                            .environment(\.deviceHeight, geometry.size.height)

                            // Custom Bottom Bar - fixed position at bottom
                            VStack {
                                Spacer()
                                CustomBottomBar(selectedTab: $selectedTab)
                            }
                            .ignoresSafeArea(.keyboard)
                        }
                    }
                    .onAppear {
                        // Set up reflection notifications
                        notificationManager.setupNotificationCategories()
                        notificationManager.requestNotificationPermission()

                        // Only check for questions if we've never checked before (first app launch)
                        let hasCheckedQuestions = UserDefaults.standard.bool(forKey: "has_checked_initial_questions")
                        if !hasCheckedQuestions {
                            Task {
                                let needsQuestions = await AIQuestionGenerationService.shared.needsInitialQuestions()
                                if needsQuestions {
                                    // Generate questions in background without blocking UI
                                }
                                // Mark that we've checked for initial questions
                                UserDefaults.standard.set(true, forKey: "has_checked_initial_questions")
                            }
                        }

                        // Animate splash screen out
                        if showSplash {
                            // Start gentle breathing animation
                            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                                breatheScale = 1.08
                                glowIntensity = 1.0
                            }
                            
                            // Slow orb rotation
                            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                                orbRotation = 360
                            }
                            
                            // First, animate logo in with spring
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                                logoOpacity = 1.0
                                logoScale = 1.0
                            }
                            
                            // Then reveal text with staggered timing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    textReveal = 1.0
                                }
                            }
                            
                            // Tagline appears after
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    taglineReveal = 1.0
                                }
                            }
                            
                            // Shimmer effect
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeInOut(duration: 1.2)) {
                                    shimmerOffset = 200
                                }
                            }

                            // After delay, fade out splash elegantly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    splashOpacity = 0.0
                                    splashScale = 1.02
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    showSplash = false
                                }
                            }
                        }
                    }
                    .overlay(
                        Group {
                            if rewardsManager.showRewards && !rewardsManager.pendingRewards.isEmpty {
                                ConsolidatedRewardsView(
                                    rewards: rewardsManager.pendingRewards,
                                    onDismiss: {
                                        rewardsManager.dismiss()
                                    }
                                )
                                .zIndex(1000)
                            }
                        }
                    )

                    // Beautiful splash screen
                    if showSplash {
                        splashScreen
                            .opacity(splashOpacity)
                            .scaleEffect(splashScale)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserDidLogout"))) { _ in
            // Reset app state
            withAnimation(.smooth(duration: 0.6, extraBounce: 0.0)) {
                selectedTab = 0
            }
            
            // Reload game stats to ensure proper data after logout
            let gameStatsManager = JournalGameStatsManager.shared
            gameStatsManager.reloadGameStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAchievementCelebration"))) { notification in
            if let achievement = notification.object as? JournalAchievement {
                rewardsManager.addReward(.achievement(achievement))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SurpriseBonusEarned"))) { notification in
            if let bonusPoints = notification.object as? Int {
                rewardsManager.addReward(.bonus(bonusPoints))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LevelUpAchieved"))) { notification in
            if let levelUpInfo = notification.object as? LevelUpInfo {
                rewardsManager.addReward(.levelUp(levelUpInfo))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenReflectionModal"))) { _ in
            // Show reflection modal when notification is tapped
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 1 // Switch to Feel tab
                showReflectionModal = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenEvaluations"))) { _ in
            // Show evaluations modal when analysis notification is tapped
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = 0 // Switch to Soul tab
                showEvaluationsModal = true
            }
        }
        .sheet(isPresented: $showReflectionModal) {
            GamifiedJournalEntryView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showEvaluationsModal) {
            EvaluationsModalView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Beautiful Splash Screen
    private var splashScreen: some View {
        let isDark = colorScheme == .dark
        let accentPink = Color(hex: "FF4F9A")
        let accentPinkLight = Color(hex: "FF7FBF")
        let accentPinkDeep = Color(hex: "FF2E84")

        return ZStack {
            // Clean background matching app theme
            Group {
                if isDark {
                    Color.black
                } else {
                    Color.white
                }
            }
            .ignoresSafeArea()

            // Subtle ambient glow - top left
            RadialGradient(
                colors: [
                    accentPink.opacity(isDark ? 0.15 : 0.08),
                    accentPink.opacity(isDark ? 0.05 : 0.02),
                    Color.clear
                ],
                center: .init(x: 0.15, y: 0.2),
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            .scaleEffect(breatheScale)

            // Subtle ambient glow - bottom right
            RadialGradient(
                colors: [
                    accentPinkLight.opacity(isDark ? 0.12 : 0.06),
                    accentPinkLight.opacity(isDark ? 0.03 : 0.01),
                    Color.clear
                ],
                center: .init(x: 0.85, y: 0.85),
                startRadius: 20,
                endRadius: 250
            )
            .ignoresSafeArea()
            .scaleEffect(breatheScale * 0.95)

            // Floating orb element
            ZStack {
                // Outer soft glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentPink.opacity(glowIntensity * (isDark ? 0.35 : 0.2)),
                                accentPink.opacity(glowIntensity * (isDark ? 0.1 : 0.05)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 140
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(breatheScale)
                    .blur(radius: 50)

                // Inner core glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentPinkLight.opacity(glowIntensity * (isDark ? 0.5 : 0.25)),
                                accentPink.opacity(glowIntensity * (isDark ? 0.2 : 0.1)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(breatheScale * 1.05)
                    .blur(radius: 25)

                // Ethereal ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentPink.opacity(isDark ? 0.4 : 0.25),
                                accentPinkLight.opacity(isDark ? 0.2 : 0.1),
                                Color.clear,
                                accentPinkDeep.opacity(isDark ? 0.3 : 0.15),
                                accentPink.opacity(isDark ? 0.4 : 0.25)
                            ],
                            center: .center
                        ),
                        lineWidth: isDark ? 1.5 : 1
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(orbRotation))
                    .opacity(glowIntensity * 0.7)
            }
            .offset(y: -50)

            // Main content
            VStack(spacing: 24) {
                Spacer()

                // Logo
                ZStack {
                    // Soft glow behind
                    Circle()
                        .fill(accentPink.opacity(glowIntensity * (isDark ? 0.4 : 0.2)))
                        .frame(width: 110, height: 110)
                        .blur(radius: 35)

                    // Main circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentPinkLight,
                                    accentPink,
                                    accentPinkDeep
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: accentPink.opacity(isDark ? 0.5 : 0.3), radius: 20, x: 0, y: 8)

                    // Icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale * breatheScale * 0.97)
                .opacity(logoOpacity)

                // Text content
                VStack(spacing: 8) {
                    // App name with shimmer
                    ZStack {
                        Text("Zenya")
                            .font(.quicksand(size: 36, weight: .bold))
                            .foregroundColor(isDark ? .white : Color(hex: "1A1A1A"))

                        // Shimmer overlay
                        Text("Zenya")
                            .font(.quicksand(size: 36, weight: .bold))
                            .foregroundColor(.clear)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        (isDark ? Color.white : accentPink).opacity(0.5),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .offset(x: shimmerOffset)
                            )
                            .mask(
                                Text("Zenya")
                                    .font(.quicksand(size: 36, weight: .bold))
                            )
                    }
                    .opacity(textReveal)
                    .offset(y: (1 - textReveal) * 10)

                    // Tagline
                    Text("Your calm companion")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(isDark ? Color.white.opacity(0.5) : Color(hex: "666666"))
                        .opacity(taglineReveal)
                        .offset(y: (1 - taglineReveal) * 6)
                }

                Spacer()
                Spacer()
            }
        }
    }
}


#Preview {
    ContentView()
}
