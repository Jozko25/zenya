//
//  LiquidGlassPaywallView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

enum LiquidGlassPricingPlan: CaseIterable {
    case monthly, yearly

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Annual"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$12.99"
        case .yearly: return "$79"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "per year"
        }
    }

    var monthlyEquivalent: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "$6.58/mo"
        }
    }

    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save 49%"
        }
    }

    var isPopular: Bool {
        return self == .yearly
    }
}

// MARK: - Paywall Palette (Matching Main App & Onboarding)
private struct PaywallPalette {
    // Colors matching EnhancedHomeView and ConversionOnboardingView
    static let accentPrimary = Color(hex: "FF5C7A")
    static let accentSecondary = Color(hex: "FF8FA3")
    static let accentHighlight = Color(hex: "A34865")

    // Button gradient colors (matching main app)
    static let buttonGradient = [
        Color(hex: "FF7A95"),
        Color(hex: "FF5C7A"),
        Color(hex: "D94467")
    ]

    // Dark background matching main app exactly
    private static let darkGradient = [
        Color.black,
        Color.black,
        Color.black
    ]

    private static let lightGradient = [
        Color(hex: "FFF0F7"),
        Color(hex: "FFE3EC"),
        Color(hex: "FFD0E3"),
        Color(hex: "FFE5F0")
    ]

    static func backgroundGradient(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? darkGradient : lightGradient
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1A")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "4A4A4A")
    }

    static func mutedText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.45) : Color(hex: "6B5B95")
    }

    static func glassFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white.opacity(0.85)
    }

    static func glassStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.4)
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white.opacity(0.9)
    }
}

// MARK: - Background Matching Main App
private struct VelvetPaywallBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var breathingScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Base background (dark or light)
            if colorScheme == .dark {
                Color.black
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "FFF0F7"),
                        Color(hex: "FFE3EC"),
                        Color(hex: "FFD0E3")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Subtle top-left glow
            RadialGradient(
                colors: [
                    Color(hex: "FF5C7A").opacity(colorScheme == .dark ? 0.08 : 0.15),
                    Color(hex: "FF5C7A").opacity(colorScheme == .dark ? 0.04 : 0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2, y: 0.1),
                startRadius: 50,
                endRadius: 400
            )
            .blur(radius: 30)

            // Subtle bottom-right accent
            RadialGradient(
                colors: [
                    Color(hex: "A34865").opacity(colorScheme == .dark ? 0.06 : 0.12),
                    Color(hex: "FF8FA3").opacity(colorScheme == .dark ? 0.03 : 0.06),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.9),
                startRadius: 80,
                endRadius: 500
            )
            .blur(radius: 40)

            // Subtle noise texture overlay
            Rectangle()
                .fill(colorScheme == .dark ? Color.white.opacity(0.01) : Color.white.opacity(0.2))
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                breathingScale = 1.1
            }
        }
    }
}

struct LiquidGlassPaywallView: View {
    @Binding var isPresented: Bool
    @State private var selectedPlan: LiquidGlassPricingPlan = .yearly
    @State private var showAnimation = false
    @State private var glowIntensity: Double = 0.8
    @State private var breathingScale: CGFloat = 1.0
    @State private var showSuccessState = false
    @State private var successCheckScale: CGFloat = 0.0
    @State private var successRingScale: CGFloat = 0.5
    @State private var successTextOpacity: Double = 0.0
    @State private var successGlowPulse: CGFloat = 1.0
    @State private var particleOffset: CGFloat = 0
    @State private var dimOverlayOpacity: Double = 0.0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VelvetPaywallBackground()

                // Main paywall content
                if !showSuccessState {
                    VStack(spacing: 0) {
                        // Top spacing - positioned lower for better balance (below dynamic island)
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 50)

                        // Clean header
                        cleanPaywallHeader

                        Spacer()
                            .frame(height: 16)

                        // What you'll get section
                        whatYouGetSection
                            .padding(.horizontal, 20)

                        Spacer()
                            .frame(minHeight: 16, maxHeight: 24)

                        // Simplified pricing - expanded
                        streamlinedPricingSection
                            .padding(.horizontal, 20)

                        Spacer()
                            .frame(minHeight: 16, maxHeight: 30)

                        // Fixed bottom section with CTA
                        VStack(spacing: 14) {
                            optimizedCtaSection
                            compactTrustSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
                    }
                    .transition(.opacity)
                }

                // Success celebration overlay
                if showSuccessState {
                    successCelebrationView
                        .transition(.opacity)
                }

                // Dim overlay for smooth transition out
                Color.black
                    .opacity(dimOverlayOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea(.all)
        .opacity(showAnimation ? 1.0 : 0.0)
        .onAppear {
            // Start animations with smooth fade-in
            withAnimation(.easeInOut(duration: 0.35)) {
                showAnimation = true
            }

            // Start breathing animation after fade-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    breathingScale = 1.1
                }
            }
        }
    }

    // MARK: - Success Celebration State Variables
    @State private var showContinueButton: Bool = false
    @State private var featuresOpacity: Double = 0

    // MARK: - Success Celebration View
    private var successCelebrationView: some View {
        GeometryReader { geometry in
            ZStack {
                // Elegant background matching app
                VelvetPaywallBackground()

                VStack(spacing: 0) {
                    Spacer()

                    // MARK: - Animated Success Icon
                    ZStack {
                        // Soft pulsing glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        PaywallPalette.accentPrimary.opacity(0.2),
                                        PaywallPalette.accentPrimary.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                            .scaleEffect(successGlowPulse)

                        // Main gradient circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF7A95"),
                                        PaywallPalette.accentPrimary,
                                        Color(hex: "D94467")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .scaleEffect(successRingScale)
                            .shadow(color: PaywallPalette.accentPrimary.opacity(0.5), radius: 30, x: 0, y: 12)

                        // Checkmark
                        Image(systemName: "checkmark")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(successCheckScale)
                    }
                    .padding(.bottom, 40)

                    // MARK: - Welcome Text
                    VStack(spacing: 12) {
                        Text("Welcome to Zenya")
                            .font(.quicksand(size: 32, weight: .bold))
                            .foregroundColor(PaywallPalette.primaryText(for: colorScheme))

                        Text("Your journey to calm begins now")
                            .font(.quicksand(size: 17, weight: .medium))
                            .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                    }
                    .multilineTextAlignment(.center)
                    .opacity(successTextOpacity)
                    .padding(.bottom, 44)

                    // MARK: - Simple Feature List
                    VStack(spacing: 16) {
                        SuccessFeatureRow(icon: "waveform.path.ecg", text: "Unlimited breathing exercises", colorScheme: colorScheme)
                        SuccessFeatureRow(icon: "moon.stars.fill", text: "Premium sleep stories", colorScheme: colorScheme)
                        SuccessFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Progress tracking & insights", colorScheme: colorScheme)
                        SuccessFeatureRow(icon: "sparkles", text: "Personalized recommendations", colorScheme: colorScheme)
                    }
                    .padding(.horizontal, 48)
                    .opacity(featuresOpacity)

                    Spacer()

                    // MARK: - Continue Button
                    VStack(spacing: 14) {
                        Button(action: {
                            #if canImport(UIKit)
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            #endif

                            withAnimation(.easeInOut(duration: 0.4)) {
                                dimOverlayOpacity = 1.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                isPresented = false
                            }
                        }) {
                            Text("Start Exploring")
                                .font(.quicksand(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FF7A95"),
                                                    PaywallPalette.accentPrimary,
                                                    Color(hex: "D94467")
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: PaywallPalette.accentPrimary.opacity(0.4), radius: 16, x: 0, y: 8)
                                )
                        }
                        .opacity(showContinueButton ? 1 : 0)
                        .scaleEffect(showContinueButton ? 1 : 0.95)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showContinueButton)

                        Text("7-day free trial • Cancel anytime")
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(PaywallPalette.secondaryText(for: colorScheme).opacity(0.6))
                            .opacity(showContinueButton ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
            }
        }
    }
    
    // MARK: - Clean Paywall Header
    private var cleanPaywallHeader: some View {
        VStack(spacing: 20) {
            // App icon/logo
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                PaywallPalette.accentPrimary.opacity(0.25),
                                PaywallPalette.accentPrimary.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                PaywallPalette.accentPrimary.opacity(0.15),
                                PaywallPalette.accentSecondary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(PaywallPalette.accentPrimary.opacity(0.3), lineWidth: 1.5)
                    )

                // Icon
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(PaywallPalette.accentPrimary)
            }
            .opacity(showAnimation ? 1 : 0)
            .scaleEffect(showAnimation ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: showAnimation)

            // Main headline
            VStack(spacing: 6) {
                Text("Feel calm in minutes")
                    .font(.quicksand(size: 28, weight: .medium))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))

                Text("Science-backed breathing & sleep tools")
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
            }
            .multilineTextAlignment(.center)
            .opacity(showAnimation ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: showAnimation)

            // Trust indicators - single line
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "FFD700"))
                    }
                }
                Text("4.8")
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                Text("•")
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme).opacity(0.5))
                Text("12K+ reviews")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
            }
            .opacity(showAnimation ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.15), value: showAnimation)
        }
    }
    
    // MARK: - What You'll Get Section
    private var whatYouGetSection: some View {
        VStack(spacing: 12) {
            featureRow(icon: "waveform.path.ecg", title: "Guided Breathing", subtitle: "90-second exercises to break anxiety loops")
            featureRow(icon: "moon.zzz", title: "Sleep Stories", subtitle: "Calming narratives for restful nights")
            featureRow(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", subtitle: "See your calm streaks grow daily")
            featureRow(icon: "bell.badge", title: "Gentle Reminders", subtitle: "Stay consistent with mindful nudges")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(PaywallPalette.glassStroke(for: colorScheme), lineWidth: 1)
                )
        )
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 15)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: showAnimation)
    }
    
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(PaywallPalette.accentPrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PaywallPalette.accentPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 15, weight: .semibold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                
                Text(subtitle)
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PaywallPalette.accentPrimary)
        }
    }
    
    private var cleanHeaderSection: some View {
        VStack(spacing: 16) {
            // Simple app icon
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(OnboardingColors.wellnessLavender.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 24, weight: .light))
                    .foregroundColor(OnboardingColors.wellnessLavender)
            }
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
            
            // Clean headline
            VStack(spacing: 8) {
                WellnessText("Find Your Zen", style: .title)
                    .multilineTextAlignment(.center)
                
                WellnessText("Start your free trial today", style: .body)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
        }
    }
    
    private var cleanSocialProofSection: some View {
        VStack(spacing: 12) {
            // Single trust line
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.quicksand(size: 14))
                    .foregroundColor(OnboardingColors.wellnessGreen)
                
                WellnessText("Trusted by 100K+ users", style: .caption)
                    .foregroundColor(OnboardingColors.wellnessLavender)
            }
            
            // Simple guarantee
            WellnessText("7-day free trial • Cancel anytime", style: .caption)
                .opacity(0.7)
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
    }
    
    private var cleanPricingSection: some View {
        VStack(spacing: 16) {
            // Simplified pricing cards
            VStack(spacing: 8) {
                ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                    CleanPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var liquidGlassBackground: some View {
        ZStack {
            // Calming gradient optimized for anxiety relief
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(hex: "7FB3D5").opacity(0.25),  // Soft blue
                    Color(hex: "A8D5E2").opacity(0.2),   // Light sky
                    Color(hex: "E6F3F7").opacity(0.15),  // Pale cyan
                    Color.black.opacity(0.5)
                ] : [
                    Color(hex: "F0F8FF"),  // Alice blue
                    Color(hex: "E6F3F7"),  // Pale cyan
                    Color(hex: "F5FFFE"),  // Mint cream
                    Color(hex: "FAFFFE")   // Snow white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Calming breathing orb
            RadialGradient(
                colors: colorScheme == .dark ? [
                    Color(hex: "7FB3D5").opacity(0.15),
                    Color(hex: "A8D5E2").opacity(0.1),
                    Color.clear
                ] : [
                    Color(hex: "B8E3F0").opacity(0.3),  // Soft sky blue
                    Color(hex: "D4EEF7").opacity(0.2),  // Pale blue
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .scaleEffect(breathingScale)
            .animation(
                .easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true),
                value: breathingScale
            )
            
            // Liquid glass texture overlay - ensure full coverage
            Rectangle()
                .fill(Material.ultraThinMaterial)
                .opacity(colorScheme == .dark ? 0.2 : 0.4)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // App Icon with glow effect
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "95B8D1").opacity(0.6),
                                        Color(hex: "B4A7D6").opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.teal.opacity(0.3), radius: 20, x: 0, y: 8)
                
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "95B8D1"),
                                Color(hex: "B4A7D6")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
            
            // Headlines
            VStack(spacing: 12) {
                Text("Your daily companion for a calmer mind")
                    .font(.quicksand(size: 28, weight: .medium))
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)

                Text("Build self-awareness through journaling, AI insights, and gentle nudges to reflect.")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
        }
        .padding(.top, 20)
    }
    
    private var compactHeaderSection: some View {
        VStack(spacing: 8) {
            // App Icon with glow - optimized size
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        OnboardingColors.wellnessLavender.opacity(0.5),
                                        OnboardingColors.softTeal.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: OnboardingColors.wellnessLavender.opacity(0.2), radius: 10, x: 0, y: 3)
                
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 32, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                OnboardingColors.wellnessLavender,
                                OnboardingColors.softTeal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
            
            // Headlines - stronger value proposition
            VStack(spacing: 8) {
                WellnessText(
                    "Your daily companion for a calmer mind",
                    style: .title
                )
                .multilineTextAlignment(.center)

                WellnessText(
                    "Build self-awareness through journaling, AI insights, and gentle nudges to reflect.",
                    style: .body
                )
                .multilineTextAlignment(.center)
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
        }
    }
    
    private var enhancedSocialProofSection: some View {
        VStack(spacing: 12) {
            // Primary trust indicator with urgency
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.quicksand(size: 18))
                    .foregroundColor(Color(hex: "4CAF50"))
                
                VStack(alignment: .leading, spacing: 3) {
                    WellnessText(
                        "Dr. Sarah Chen, Clinical Psychologist",
                        style: .subheadline
                    )
                    
                    WellnessText(
                        "\"Clinically proven to reduce anxiety in 90 seconds\"",
                        style: .caption
                    )
                    .italic()
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "4CAF50").opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Success metrics row
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    WellnessText("67%", style: .headline)
                        .foregroundColor(OnboardingColors.wellnessGreen)
                    WellnessText("Less Anxiety", style: .caption)
                }
                
                VStack(spacing: 2) {
                    WellnessText("15 Min", style: .headline)
                        .foregroundColor(OnboardingColors.wellnessBlue)
                    WellnessText("Daily Usage", style: .caption)
                }
                
                VStack(spacing: 2) {
                    WellnessText("90%", style: .headline)
                        .foregroundColor(OnboardingColors.wellnessLavender)
                    WellnessText("Sleep Better", style: .caption)
                }
                
                VStack(spacing: 2) {
                    WellnessText("24/7", style: .headline)
                        .foregroundColor(OnboardingColors.softTeal)
                    WellnessText("Available", style: .caption)
                }
            }
            .padding(.vertical, 8)
            
            // Risk-free guarantee
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.quicksand(size: 14))
                    .foregroundColor(Color(hex: "4CAF50"))
                
                Text("7-day free trial • Cancel anytime • 100% risk-free")
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(Color.secondary)
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
    }
    
    private var socialProofBanner: some View {
        VStack(spacing: 8) {
            // Trust indicators
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.quicksand(size: 16))
                    .foregroundColor(Color(hex: "7FB3D5"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dr. Sarah Chen, Clinical Psychologist")
                        .font(.quicksand(size: 12, weight: .semibold))
                        .foregroundColor(Color.primary)
                    
                    Text("\"Clinically proven to reduce anxiety in 90 seconds\"")
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(Color.secondary)
                        .italic()
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "7FB3D5").opacity(0.2), lineWidth: 0.5)
                    )
            )
            
            // Risk-free trial message
            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.quicksand(size: 12))
                    .foregroundColor(Color(hex: "7FB3D5"))
                
                Text("7-day free trial • Cancel anytime • No questions asked")
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(Color.secondary)
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
    }
    
    private var valueFeatureShowcase: some View {
        VStack(spacing: 10) {
            // Feature grid with value-focused descriptions
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ValueFeatureCard(
                        icon: "lungs.fill",
                        title: "4-7-8 Breathing",
                        subtitle: "Instant calm in 90 seconds",
                        color: Color(hex: "7FB3D5")
                    )
                    ValueFeatureCard(
                        icon: "moon.zzz.fill",
                        title: "Sleep Stories",
                        subtitle: "Fall asleep in 15 minutes",
                        color: Color(hex: "9D8DF1")
                    )
                }
                
                HStack(spacing: 10) {
                    ValueFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Track",
                        subtitle: "See your anxiety drop daily",
                        color: Color(hex: "C785E8")
                    )
                    ValueFeatureCard(
                        icon: "heart.fill",
                        title: "Mood Insights",
                        subtitle: "Understand your patterns",
                        color: Color(hex: "FF8A95")
                    )
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var compactFeaturesSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                CompactFeature(icon: "lungs.fill", title: "4-7-8 Breathing", color: .teal)
                CompactFeature(icon: "moon.zzz.fill", title: "Sleep Stories", color: .indigo)
            }
            
            HStack(spacing: 12) {
                CompactFeature(icon: "chart.line.uptrend.xyaxis", title: "Progress Track", color: .purple)
                CompactFeature(icon: "heart.fill", title: "Mood Insights", color: .pink)
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var optimizedPricingSection: some View {
        VStack(spacing: 12) {
            // Simple header with value emphasis
            HStack {
                WellnessText("Choose Your Plan", style: .headline)
                
                Spacer()
                
                WellnessText("Start Free Today", style: .caption)
                    .foregroundColor(OnboardingColors.wellnessGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(OnboardingColors.wellnessGreen.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            // Compact pricing cards with enhanced design
            VStack(spacing: 6) {
                ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                    EnhancedCompactPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 40)
        .animation(.easeOut(duration: 0.8).delay(1.0), value: showAnimation)
    }
    
    private var compactPricingSection: some View {
        VStack(spacing: 10) {
            // Simple header
            HStack {
                Text("Choose Your Plan")
                    .font(.quicksand(size: 18, weight: .semibold))
                    .foregroundColor(Color.primary)
                
                Spacer()
            }
            
            // Vertical pricing cards - more compact
            VStack(spacing: 8) {
                ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                    CompactPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 40)
        .animation(.easeOut(duration: 0.8).delay(1.0), value: showAnimation)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("What You'll Get")
                .font(.quicksand(size: 22, weight: .semibold))
                .foregroundColor(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                FeatureRow(
                    icon: "pencil.and.scribble",
                    title: "Unlimited journaling",
                    description: "Write freely, anytime",
                    color: .pink
                )

                FeatureRow(
                    icon: "brain.head.profile",
                    title: "AI companion",
                    description: "Remembers your story, grows with you",
                    color: .purple
                )

                FeatureRow(
                    icon: "waveform.path.ecg",
                    title: "Mood insights",
                    description: "Spot patterns, understand yourself better",
                    color: .teal
                )

                FeatureRow(
                    icon: "flame.fill",
                    title: "Streaks & rewards",
                    description: "Stay motivated, celebrate progress",
                    color: .orange
                )

                FeatureRow(
                    icon: "bell.badge.fill",
                    title: "Smart reminders",
                    description: "Gentle nudges when you need them",
                    color: .blue
                )

                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Secure cloud sync",
                    description: "Your entries, always safe",
                    color: .green
                )
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: showAnimation)
    }
    
    private var pricingSection: some View {
        VStack(spacing: 20) {
            Text("Choose Your Plan")
                .font(.quicksand(size: 22, weight: .semibold))
                .foregroundColor(Color.primary)
            
            // Horizontal pricing cards
            HStack(spacing: 12) {
                ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                    LiquidGlassPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 40)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var enhancedCtaSection: some View {
        Button(action: startTrial) {
            VStack(spacing: 6) {
                WellnessText("Start 7-Day Free Trial", style: .button)
                    .foregroundColor(.white)

                WellnessText("Cancel anytime. No commitment.", style: .caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Use same gradient as onboarding confirm button
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    OnboardingColors.wellnessLavender,  // B4A7D6
                                    OnboardingColors.softTeal           // 95B8D1
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle glass effect
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 30)
                        .offset(y: -15)
                }
            )
            .shadow(color: OnboardingColors.wellnessLavender.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(showAnimation ? 1.0 : 0.9)
        .opacity(showAnimation ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: showAnimation)
    }
    
    private var riskReversalSection: some View {
        VStack(spacing: 6) {
            WellnessText("Try free for 7 days, cancel anytime", style: .caption)
                .multilineTextAlignment(.center)
                .opacity(0.8)
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(1.4), value: showAnimation)
    }
    
    private var ctaSection: some View {
        Button(action: startTrial) {
            VStack(spacing: 6) {
                Text("Unlock Oasis for Free")
                    .font(.quicksand(size: 17, weight: .bold))
                    .foregroundColor(.white)
                
                Text("7 days free, then \(selectedPlan.price)/\(selectedPlan.period == "per month" ? "mo" : "yr")")
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Calming gradient for anxiety-sensitive users
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "7FB3D5"),  // Calming blue
                                    Color(hex: "9AC1DC")   // Lighter blue
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Subtle glass effect
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.25),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 30)
                        .offset(y: -15)
                }
            )
            .shadow(color: Color(hex: "7FB3D5").opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .scaleEffect(showAnimation ? 1.0 : 0.9)
        .opacity(showAnimation ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: showAnimation)
    }
    
    private var trustSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                VStack {
                    Text("4.8★")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("App Store")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
                
                VStack {
                    Text("100K+")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("Users")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
                
                VStack {
                    Text("95%")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(Color.primary)
                    Text("Success Rate")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Material.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.primary.opacity(0.1), lineWidth: 0.5)
            )
            
            Text("Cancel anytime • No commitments • Privacy protected")
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(1.2), value: showAnimation)
    }
    
    private func startAnimations() {
        withAnimation {
            showAnimation = true
            breathingScale = 1.1
        }
    }
    
    private func startTrial() {
        // Immediate haptic feedback
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif

        // Show success state with smooth animation
        withAnimation(.easeInOut(duration: 0.5)) {
            showSuccessState = true
        }

        // Animate checkmark appearing with bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                successCheckScale = 1.0
                successRingScale = 1.0
            }

            // Success haptic
            #if canImport(UIKit)
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            #endif
        }

        // Start subtle pulsing glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                successGlowPulse = 1.08
            }
        }

        // Fade in text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                successTextOpacity = 1.0
            }
        }

        // Fade in features
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeInOut(duration: 0.5)) {
                featuresOpacity = 1.0
            }
        }

        // Set subscription data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UserDefaults.standard.set(true, forKey: "has_active_subscription")
            UserDefaults.standard.set(Date(), forKey: "subscription_start_date")
            UserDefaults.standard.set(selectedPlan.title.lowercased(), forKey: "subscription_plan")
        }

        // Show continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showContinueButton = true
            }
        }
    }
    
    // MARK: - Streamlined Sections for Better Screen Fit
    
    private var streamlinedHeaderSection: some View {
        VStack(spacing: 8) {
            // Smaller app icon to avoid dynamic island
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        OnboardingColors.wellnessLavender.opacity(0.4),
                                        OnboardingColors.softTeal.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 24, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                OnboardingColors.wellnessLavender,
                                OnboardingColors.softTeal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Compact headline
            VStack(spacing: 4) {
                Text("Find Your Oasis in Minutes")
                    .font(.quicksand(size: 22, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text("Join 100K+ users who reduced anxiety by 67%")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(OnboardingColors.wellnessGreen)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: showAnimation)
    }
    
    private var compactSocialProofSection: some View {
        // Single line social proof with clinical validation
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(OnboardingColors.wellnessGreen)
            
            Text("Dr. Sarah Chen, Clinical Psychologist")
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(OnboardingColors.wellnessGreen.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: showAnimation)
    }
    
    private var essentialFeaturesSection: some View {
        // Horizontal scroll of 4 key features using inline cards
        HStack(spacing: 12) {
            CompactFeatureCard(icon: "lungs.fill", title: "4-7-8 Breathing", subtitle: "Instant calm")
            CompactFeatureCard(icon: "moon.fill", title: "Sleep Stories", subtitle: "Fall asleep fast")
            CompactFeatureCard(icon: "chart.line.uptrend.xyaxis", title: "Progress Track", subtitle: "See results")
            CompactFeatureCard(icon: "heart.fill", title: "Mood Insights", subtitle: "Understand patterns")
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: showAnimation)
    }
    
    
    private var streamlinedCtaSection: some View {
        Button(action: startTrial) {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.quicksand(size: 18, weight: .medium))
                
                Text("Start Free Trial")
                    .font(.quicksand(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [
                        OnboardingColors.wellnessLavender,
                        OnboardingColors.softTeal
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: OnboardingColors.wellnessLavender.opacity(0.3),
                radius: 8, x: 0, y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showAnimation ? 1.0 : 0.95)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showAnimation)
    }
    
    private var minimalTrustSection: some View {
        Text("7-day free trial • Cancel anytime • 100% risk-free")
            .font(.quicksand(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .opacity(showAnimation ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: showAnimation)
    }
    
    // MARK: - Conversion-Optimized Sections
    
    private var optimizedHeaderSection: some View {
        VStack(spacing: 12) {
            // App icon - positioned lower to avoid dynamic island
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        PaywallPalette.accentPrimary.opacity(0.7),
                                        PaywallPalette.accentSecondary.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: PaywallPalette.accentPrimary.opacity(0.35), radius: 12, x: 0, y: 6)

                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 22, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                PaywallPalette.accentPrimary,
                                PaywallPalette.accentSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: showAnimation)

            // Credible social proof without inflated claims
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.quicksand(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                }
                Text("4.8★ from 12,413 ratings")
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))

                Button(action: { /* Show evidence modal */ }) {
                    Text("Evidence")
                        .font(.quicksand(size: 10, weight: .medium))
                        .foregroundColor(PaywallPalette.accentHighlight)
                        .underline()
                }
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 10)
            .animation(.easeOut(duration: 0.6).delay(0.15), value: showAnimation)

            heroValueCard
                .opacity(showAnimation ? 1 : 0)
                .offset(y: showAnimation ? 0 : 15)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showAnimation)
        }
    }

    private var heroValueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 3) {
                Text("Feel calm in minutes")
                    .font(.quicksand(size: 19, weight: .bold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                Text("Science-backed techniques for daily relief")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
            }

            // Simple feature list
            VStack(spacing: 8) {
                PaywallFeatureRow(icon: "waveform.path.ecg", text: "Breathing exercises for anxiety")
                PaywallFeatureRow(icon: "moon.zzz", text: "Sleep stories & soundscapes")
                PaywallFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress daily")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : PaywallPalette.accentPrimary.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var heroValueHighlights: [(icon: String, title: String, detail: String)] {
        [
            (icon: "waveform.path.ecg", title: "Breath coaching", detail: "Coherent breathing tailored to anxiety spikes"),
            (icon: "moon.zzz", title: "Sleep OS", detail: "Wind-down stories & soundscapes for deeper rest"),
            (icon: "sparkles", title: "Micro-habits", detail: "3-min nervous system resets throughout the day"),
            (icon: "chart.bar.xaxis", title: "Progress radar", detail: "Track calm streaks & celebrate wins")
        ]
    }
    
    private var calmResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "circle.hexagonpath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PaywallPalette.accentPrimary)
                Text("First-week wins")
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                Spacer()
                Text("≈ 10 min / day")
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(PaywallPalette.accentPrimary.opacity(0.12))
                    )
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(calmResultData, id: \.title) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(item.accent.opacity(colorScheme == .dark ? 0.25 : 0.15))
                                    .frame(width: 26, height: 26)
                                Image(systemName: item.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(item.accent)
                            }

                            Text(item.title)
                                .font(.quicksand(size: 12, weight: .semibold))
                                .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                        }

                        Text(item.detail)
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                colorScheme == .dark ?
                                    Color.white.opacity(0.04) :
                                    Color.white.opacity(0.95)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(item.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }

            Text("7-day free trial • Cancel anytime • Works offline after download")
                .font(.quicksand(size: 10, weight: .medium))
                .foregroundColor(PaywallPalette.mutedText(for: colorScheme))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(PaywallPalette.cardBackground(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(PaywallPalette.glassStroke(for: colorScheme), lineWidth: 1)
                )
        )
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.25), value: showAnimation)
    }

    private var calmResultData: [(icon: String, title: String, detail: String, accent: Color)] {
        [
            (icon: "lungs.fill", title: "Breathing resets", detail: "Guided cues break panic loops in 90 seconds.", accent: PaywallPalette.accentPrimary),
            (icon: "moon.zzz", title: "Restful nights", detail: "Wind-down stories and soundscapes quiet late thoughts.", accent: PaywallPalette.accentSecondary),
            (icon: "sunrise.fill", title: "Morning anchor", detail: "Intention check-ins keep you steady before work.", accent: PaywallPalette.accentHighlight),
            (icon: "chart.line.uptrend.xyaxis", title: "Progress radar", detail: "Track calmer streaks and share wins with your coach.", accent: Color(hex: "65D6C2"))
        ]
    }

    private var beforeAfterCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.quicksand(size: 20))
                    .foregroundColor(PaywallPalette.accentPrimary.opacity(0.7))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Before: anxious & overwhelmed")
                        .font(.quicksand(size: 13, weight: .semibold))
                        .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                    Text("Racing thoughts, restless sleep, constant worry loops")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(PaywallPalette.mutedText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(alignment: .center, spacing: 8) {
                Rectangle()
                    .fill(PaywallPalette.accentPrimary.opacity(0.4))
                    .frame(height: 1)
                Image(systemName: "arrow.right")
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Rectangle()
                    .fill(PaywallPalette.accentPrimary.opacity(0.4))
                    .frame(height: 1)
            }

            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.quicksand(size: 20))
                    .foregroundColor(PaywallPalette.accentSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("After: calm & in control")
                        .font(.quicksand(size: 13, weight: .semibold))
                        .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                    Text("Guided tools for better sleep, gentle focus, and clear thinking")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PaywallPalette.cardBackground(for: colorScheme).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    PaywallPalette.accentPrimary.opacity(0.4),
                                    PaywallPalette.accentSecondary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(color: PaywallPalette.accentPrimary.opacity(0.15), radius: 15, x: 0, y: 10)
    }

    private var valuePromiseGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(valuePromiseData, id: \.title) { item in
                PaywallValuePill(icon: item.icon, title: item.title, detail: item.detail)
            }
        }
    }

    private var valuePromiseData: [(icon: String, title: String, detail: String)] {
        [
            (icon: "timer", title: "4-min breath resets", detail: "Interrupt spirals in under 60 seconds."),
            (icon: "moon.zzz", title: "Sleep rituals", detail: "Night routines to quiet late-night loops."),
            (icon: "chart.line.uptrend.xyaxis", title: "Progress tracking", detail: "Celebrate calm streaks and insights."),
            (icon: "heart.text.square", title: "Clinician guidance", detail: "Methods reviewed by therapists & coaches.")
        ]
    }
    
    private var streamlinedPricingSection: some View {
        VStack(spacing: 12) {
            ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                SimplePricingCard(
                    plan: plan,
                    isSelected: selectedPlan == plan
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedPlan = plan
                    }
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.5).delay(0.3), value: showAnimation)
    }
    
    private var optimizedCtaSection: some View {
        VStack(spacing: 12) {
            Button(action: startTrial) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Start Free Trial")
                        .font(.quicksand(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        // Shadow layer for depth
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "C83555"))
                            .offset(y: 3)

                        // Main gradient with better colors
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF7A95"),
                                        PaywallPalette.accentPrimary,
                                        Color(hex: "D94467")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Enhanced top highlight
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(color: PaywallPalette.accentPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
            }
            .scaleEffect(showAnimation ? 1.0 : 0.95)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showAnimation)

            Text("7 days free, then \(selectedPlan.price)/\(selectedPlan == .yearly ? "year" : "month"). Cancel anytime.")
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
        }
    }
    
    private var compactTrustSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button(action: { /* Restore purchases */ }) {
                    Text("Restore")
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                }

                Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))

                Link("Privacy", destination: URL(string: "https://zenya.app/privacy")!)
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: showAnimation)
    }
    
    // MARK: - Legacy Enhanced Sections (keeping for compatibility)
    
    private var enhancedHeaderSection: some View {
        VStack(spacing: 16) {
            // App icon with enhanced glow
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        OnboardingColors.wellnessLavender.opacity(0.6),
                                        OnboardingColors.softTeal.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: OnboardingColors.wellnessLavender.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "brain.head.profile")
                    .font(.quicksand(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                OnboardingColors.wellnessLavender,
                                OnboardingColors.softTeal
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(showAnimation ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showAnimation)
            
            // Strong headline with benefits
            VStack(spacing: 12) {
                Text("Find Your Calm in Minutes")
                    .font(.quicksand(size: 28, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text("Join 100K+ users who reduced anxiety by 67%")
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(OnboardingColors.wellnessGreen)
                    .multilineTextAlignment(.center)
                
                Text("Science-backed techniques that work in 90 seconds")
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showAnimation ? 1 : 0)
            .offset(y: showAnimation ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.4), value: showAnimation)
        }
    }
    
    private var comprehensiveFeaturesSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Text("What You'll Get")
                    .font(.quicksand(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Feature grid - 2x2 layout
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DetailedFeatureCard(
                        icon: "lungs.fill",
                        title: "4-7-8 Breathing",
                        subtitle: "Instant calm",
                        description: "Fall asleep fast",
                        color: OnboardingColors.wellnessLavender
                    )
                    
                    DetailedFeatureCard(
                        icon: "moon.zzz.fill",
                        title: "Sleep Stories",
                        subtitle: "Fall asleep fast",
                        description: "Soothing narratives",
                        color: OnboardingColors.wellnessBlue
                    )
                }
                
                HStack(spacing: 12) {
                    DetailedFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Track",
                        subtitle: "See results",
                        description: "Monitor daily progress",
                        color: OnboardingColors.softTeal
                    )
                    
                    DetailedFeatureCard(
                        icon: "heart.fill",
                        title: "Mood Insights",
                        subtitle: "Understand patterns",
                        description: "Personal analysis",
                        color: Color.pink
                    )
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: showAnimation)
    }
    
    private var enhancedPricingSection: some View {
        VStack(spacing: 16) {
            // Section header with value emphasis
            HStack {
                Text("Choose Your Plan")
                    .font(.quicksand(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Start Free Today")
                    .font(.quicksand(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(OnboardingColors.wellnessGreen)
                    .clipShape(Capsule())
            }
            
            // Pricing cards with enhanced design
            VStack(spacing: 8) {
                ForEach(LiquidGlassPricingPlan.allCases, id: \.self) { plan in
                    EnhancedPricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlan = plan
                        }
                    }
                }
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .offset(y: showAnimation ? 0 : 40)
        .animation(.easeOut(duration: 0.8).delay(1.0), value: showAnimation)
    }
    
    private var testimonialsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("What Users Say")
                    .font(.quicksand(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 12) {
                PaywallTestimonialCard(
                    quote: "My anxiety reduced by 70% in just 2 weeks!",
                    author: "Sarah M.",
                    rating: 5
                )
                
                PaywallTestimonialCard(
                    quote: "Finally found something that actually works.",
                    author: "Mike D.",
                    rating: 5
                )
                
                PaywallTestimonialCard(
                    quote: "The breathing exercises are life-changing.",
                    author: "Emma L.",
                    rating: 5
                )
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(1.2), value: showAnimation)
    }
    
    private var enhancedTrustSection: some View {
        VStack(spacing: 8) {
            // Main guarantee
            Text("7-day free trial • Cancel anytime • 100% risk-free")
                .font(.quicksand(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Trust indicators
            HStack(spacing: 20) {
                PaywallTrustIndicator(value: "4.8★", label: "App Store")
                PaywallTrustIndicator(value: "100K+", label: "Happy Users")
                PaywallTrustIndicator(value: "67%", label: "Less Anxiety")
            }
        }
        .opacity(showAnimation ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(1.4), value: showAnimation)
    }
}

// MARK: - New Supporting Views

struct DetailedFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.quicksand(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.quicksand(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct EnhancedPricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Popular badge
                if plan.isPopular {
                    Text("Most Popular")
                        .font(.quicksand(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .offset(x: -12, y: -6)
                        .zIndex(1)
                }
                
                HStack(spacing: 0) {
                    // Left side - Plan details
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.title)
                            .font(.quicksand(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(plan.period)
                            .font(.quicksand(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let monthlyEquivalent = plan.monthlyEquivalent {
                            Text(monthlyEquivalent)
                                .font(.quicksand(size: 12, weight: .semibold))
                                .foregroundColor(OnboardingColors.wellnessGreen)
                        }
                    }
                    
                    Spacer()
                    
                    // Right side - Price and savings
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(plan.price)
                            .font(.quicksand(size: 24, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.quicksand(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(OnboardingColors.wellnessGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? OnboardingColors.wellnessLavender : Color.clear.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? OnboardingColors.wellnessLavender.opacity(0.3) : Color.clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: isSelected ? 6 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PaywallTestimonialCard: View {
    let quote: String
    let author: String
    let rating: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<rating, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.quicksand(size: 12))
                        .foregroundColor(.yellow)
                }
            }
            
            Text("\"\(quote)\"")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .italic()
            
            Text("- \(author)")
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(OnboardingColors.wellnessLavender.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PaywallTrustIndicator: View {
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.quicksand(size: 14, weight: .bold))
                .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
            
            Text(label)
                .font(.quicksand(size: 10, weight: .medium))
                .foregroundColor(PaywallPalette.mutedText(for: colorScheme))
        }
    }
}

// MARK: - Conversion-Optimized Supporting Views

struct BenefitRow: View {
    let icon: String
    let benefit: String
    let timeframe: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(PaywallPalette.accentPrimary)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(benefit)
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
                
                Text(timeframe)
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(PaywallPalette.mutedText(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct PaywallValuePill: View {
    let icon: String
    let title: String
    let detail: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(PaywallPalette.accentPrimary)
                    .frame(width: 18, height: 18)
                Text(title)
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(PaywallPalette.primaryText(for: colorScheme))
            }

            Text(detail)
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(PaywallPalette.secondaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(PaywallPalette.cardBackground(for: colorScheme).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(PaywallPalette.accentPrimary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

struct PaywallMetricPill: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.quicksand(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(caption)
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(PaywallPalette.accentPrimary)
                .frame(width: 24)

            Text(text)
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(PaywallPalette.primaryText(for: colorScheme))

            Spacer()
        }
    }
}

struct SimplePricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let titleColor = isSelected ? Color.white : PaywallPalette.primaryText(for: colorScheme)
        let subtitleColor = isSelected ? Color.white.opacity(0.85) : PaywallPalette.mutedText(for: colorScheme)

        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.quicksand(size: 17, weight: .bold))
                            .foregroundColor(titleColor)

                        if plan.isPopular {
                            Text("Most Popular")
                                .font(.quicksand(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.25))
                                )
                        }
                    }

                    Text(plan.period)
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(subtitleColor)

                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.quicksand(size: 12, weight: .semibold))
                            .foregroundColor(isSelected ? Color.white.opacity(0.9) : PaywallPalette.accentHighlight)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(plan.price)
                        .font(.quicksand(size: 24, weight: .medium))
                        .foregroundColor(titleColor)

                    if let savings = plan.savings {
                        Text(savings)
                            .font(.quicksand(size: 10, weight: .bold))
                            .foregroundColor(isSelected ? Color.white : PaywallPalette.accentPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(
                                        isSelected ?
                                            Color.white.opacity(0.25) :
                                            PaywallPalette.accentPrimary.opacity(0.15)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: backgroundGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected ?
                                    Color.white.opacity(0.4) :
                                    PaywallPalette.glassStroke(for: colorScheme),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? PaywallPalette.accentPrimary.opacity(0.35) : Color.black.opacity(0.1),
                radius: isSelected ? 15 : 8,
                x: 0,
                y: isSelected ? 8 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var backgroundGradientColors: [Color] {
        if isSelected {
            return [
                PaywallPalette.accentPrimary,
                PaywallPalette.accentSecondary,
                PaywallPalette.accentHighlight
            ]
        } else {
            let base = PaywallPalette.glassFill(for: colorScheme)
            return [base, base]
        }
    }
}


// MARK: - Compact Feature Card for Paywall
struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                OnboardingColors.wellnessLavender.opacity(0.2),
                                OnboardingColors.softTeal.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.quicksand(size: 18, weight: .medium))
                    .foregroundColor(OnboardingColors.wellnessLavender)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.quicksand(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
    }
}

// MARK: - Compact Pricing Option Card
struct PricingOptionCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let isCompact: Bool
    let isPopular: Bool
    let action: () -> Void
    
    init(plan: LiquidGlassPricingPlan, isSelected: Bool, isCompact: Bool = false, isPopular: Bool = false, action: @escaping () -> Void) {
        self.plan = plan
        self.isSelected = isSelected
        self.isCompact = isCompact
        self.isPopular = isPopular
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(plan.title)
                            .font(.quicksand(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        if isPopular {
                            Text("Most Popular")
                                .font(.quicksand(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(OnboardingColors.wellnessOrange)
                                )
                        }
                    }
                    
                    Text(plan.period)
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(OnboardingColors.wellnessGreen)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(.quicksand(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.quicksand(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(OnboardingColors.wellnessGreen)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [
                                    OnboardingColors.wellnessLavender,
                                    OnboardingColors.softTeal
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ?
                                    Color.clear :
                                    OnboardingColors.wellnessLavender.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.quicksand(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(Color.primary)
                
                Text(description)
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(Color.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct LiquidGlassPricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Popular badge
                if plan.isPopular {
                    Text("Most Popular")
                        .font(.quicksand(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                        .offset(y: -8)
                }
                
                // Plan title
                Text(plan.title)
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(Color.primary)
                
                // Price
                VStack(spacing: 4) {
                    Text(plan.price)
                        .font(.quicksand(size: 22, weight: .bold))
                        .foregroundColor(Color.primary)
                    
                    Text(plan.period)
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(Color.secondary)
                    
                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        Text(monthlyEquivalent)
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(Color.teal)
                    }
                }
                
                // Savings badge
                if let savings = plan.savings {
                    Text(savings)
                        .font(.quicksand(size: 10, weight: .bold))
                        .foregroundColor(Color.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.teal,
                                        Color.indigo
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.primary.opacity(0.15), lineWidth: 1)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? Color.teal.opacity(0.2) : .clear,
                radius: isSelected ? 10 : 0,
                x: 0,
                y: isSelected ? 5 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CompactFeature: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: icon)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(Color.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct ValueFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Material.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.4), lineWidth: 1.5)
                    )
                
                Image(systemName: icon)
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 3) {
                Text(title)
                    .font(.quicksand(size: 12, weight: .bold))
                    .foregroundColor(Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.quicksand(size: 10, weight: .medium))
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

struct EnhancedCompactPricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Popular badge - positioned in top right
                if plan.isPopular {
                    Text("Most Popular")
                        .font(.quicksand(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .offset(x: -8, y: -6)
                        .zIndex(1)
                }
                
                HStack(spacing: 0) {
                    // Left side - Plan details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.quicksand(size: 16, weight: .bold))
                            .foregroundColor(Color.primary)
                        
                        Text(plan.period)
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(Color.secondary.opacity(0.9))
                        
                        if let monthlyEquivalent = plan.monthlyEquivalent {
                            Text(monthlyEquivalent)
                                .font(.quicksand(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "4CAF50"))
                        }
                    }
                    
                    Spacer()
                    
                    // Right side - Price and savings
                    VStack(alignment: .trailing, spacing: 6) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(plan.price)
                                .font(.quicksand(size: 22, weight: .bold))
                                .foregroundColor(Color.primary)
                            
                            // Show per month for annual/quarterly
                            if plan != .monthly {
                                Text(plan.period)
                                    .font(.quicksand(size: 10, weight: .medium))
                                    .foregroundColor(Color.secondary.opacity(0.7))
                            }
                        }
                        
                        // Savings badge
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.quicksand(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "4CAF50"), Color(hex: "45A049")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.ultraThinMaterial)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "7FB3D5"),
                                        Color(hex: "9AC1DC")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.primary.opacity(0.12), lineWidth: 1)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? Color(hex: "7FB3D5").opacity(0.3) : Color.clear,
                radius: isSelected ? 10 : 0,
                x: 0,
                y: isSelected ? 5 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CleanPricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        WellnessText(plan.title, style: .subheadline)
                        
                        if plan.isPopular {
                            WellnessText("Most Popular", style: .caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(OnboardingColors.wellnessOrange)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let monthlyEquivalent = plan.monthlyEquivalent {
                        WellnessText(monthlyEquivalent, style: .caption)
                            .foregroundColor(OnboardingColors.wellnessGreen)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    WellnessText(plan.price, style: .headline)
                    
                    if let savings = plan.savings {
                        WellnessText(savings, style: .caption)
                            .foregroundColor(OnboardingColors.wellnessGreen)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Material.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? OnboardingColors.wellnessLavender : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? OnboardingColors.wellnessLavender.opacity(0.2) : Color.clear,
                radius: isSelected ? 6 : 0,
                x: 0,
                y: isSelected ? 3 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CompactPricingCard: View {
    let plan: LiquidGlassPricingPlan
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Popular badge - positioned in top right
                if plan.isPopular {
                    Text("Most Popular")
                        .font(.quicksand(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                        .offset(x: -10, y: -8)
                        .zIndex(1)
                }
                
                HStack(spacing: 0) {
                    // Left side - Plan details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.quicksand(size: 15, weight: .semibold))
                            .foregroundColor(Color.primary)
                        
                        Text(plan.period)
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(Color.secondary)
                        
                        if let monthlyEquivalent = plan.monthlyEquivalent {
                            Text(monthlyEquivalent)
                                .font(.quicksand(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "7FB3D5"))
                        }
                    }
                    
                    Spacer()
                    
                    // Right side - Price and savings
                    VStack(alignment: .trailing, spacing: 4) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(plan.price)
                                .font(.quicksand(size: 20, weight: .bold))
                                .foregroundColor(Color.primary)
                            
                            // Show per month for annual/quarterly
                            if plan != .monthly {
                                Text(plan.period)
                                    .font(.quicksand(size: 9, weight: .medium))
                                    .foregroundColor(Color.secondary.opacity(0.8))
                            }
                        }
                        
                        // Savings badge
                        if let savings = plan.savings {
                            Text(savings)
                                .font(.quicksand(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "4CAF50"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: "4CAF50").opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Material.ultraThinMaterial)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "7FB3D5"),
                                        Color(hex: "A8D5E2")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.primary.opacity(0.15), lineWidth: 1)
                    }
                }
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .shadow(
                color: isSelected ? Color(hex: "B4A7D6").opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Success Celebration Supporting Views

struct SuccessFeatureRow: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(PaywallPalette.accentPrimary)
                .frame(width: 24)

            Text(text)
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : Color(hex: "2A2A2A"))

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(PaywallPalette.accentPrimary.opacity(0.8))
        }
    }
}

#Preview {
    LiquidGlassPaywallView(isPresented: .constant(true))
}
