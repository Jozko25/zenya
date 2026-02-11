//
//  ConversionOnboardingView.swift
//  anxiety
//
//  Created by Ján Harmady on 27/08/2025.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Shared Palette (Matching Main App)
private struct ConversionOnboardingTheme {
    // Colors matching EnhancedHomeView
    static let accentPrimary = Color(hex: "FF5C7A")
    static let accentSecondary = Color(hex: "FF8FA3")
    static let accentTertiary = Color(hex: "A34865")
    static let accentGlow = Color(hex: "FF5C7A").opacity(0.35)

    // Button gradient colors (matching main app blob/button)
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

    static func textureOverlay(for colorScheme: ColorScheme) -> [Color] {
        if colorScheme == .dark {
            return [
                Color.white.opacity(0.01),
                Color.clear
            ]
        }
        return [
            Color.white.opacity(0.2),
            Color.clear,
            Color.white.opacity(0.1),
            Color.clear
        ]
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

    static func cardBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "F2B3D1").opacity(0.5)
    }
}

// MARK: - Background Matching Main App
struct CalmingAnimatedBackground: View {
    @State private var breathingScale: CGFloat = 1.0
    @Environment(\.colorScheme) var colorScheme

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
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                breathingScale = 1.1
            }
        }
    }
}

// MARK: - Helper Components
struct HeaderSection: View {
    let currentStep: Int
    let totalSteps: Int
    let geometry: GeometryProxy
    let onBack: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Back button and step indicator
            HStack(alignment: .center) {
                if currentStep > 0 {
                    BackButton(onBack: onBack)
                } else {
                    Spacer().frame(width: 44)
                }

                Spacer()

                // Step indicator text
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))

                Spacer()

                Spacer().frame(width: 44)
            }
            .padding(.horizontal, 20)

            // Streamlined progress bar
            ProgressBarSection(
                currentStep: currentStep,
                totalSteps: totalSteps,
                geometry: geometry
            )
        }
    }
}

struct BackButton: View {
    let onBack: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.quicksand(size: 16, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        // 3D Base shadow
                        Circle()
                            .fill(
                                colorScheme == .dark ?
                                    Color.black.opacity(0.4) :
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.15)
                            )
                            .offset(y: isPressed ? 1 : 3)

                        // Main surface
                        Circle()
                            .fill(
                                colorScheme == .dark ?
                                    Color(hex: "1A1A1C") :
                                    Color.white.opacity(0.9)
                            )
                            .offset(y: isPressed ? 2 : 0)

                        // Border
                        Circle()
                            .stroke(
                                colorScheme == .dark ?
                                    Color.white.opacity(0.12) :
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                                lineWidth: 1
                            )
                            .offset(y: isPressed ? 2 : 0)
                    }
                )
                .shadow(
                    color: colorScheme == .dark ?
                        Color.black.opacity(0.2) :
                        ConversionOnboardingTheme.accentPrimary.opacity(0.15),
                    radius: isPressed ? 2 : 6,
                    x: 0,
                    y: isPressed ? 1 : 3
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct ProgressBarSection: View {
    let currentStep: Int
    let totalSteps: Int
    let geometry: GeometryProxy
    @Environment(\.colorScheme) var colorScheme

    private var progress: CGFloat {
        CGFloat(currentStep + 1) / CGFloat(totalSteps)
    }

    var body: some View {
        // Clean, minimal progress bar matching main app style
        ZStack(alignment: .leading) {
            // Background track
            Capsule()
                .fill(
                    colorScheme == .dark ?
                        Color(hex: "1A1A1C") :
                        Color.white.opacity(0.6)
                )
                .frame(height: 6)

            // Progress fill with gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: ConversionOnboardingTheme.buttonGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 6)
                .frame(width: max(0, (geometry.size.width - 48) * progress))
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.5), radius: 6, x: 0, y: 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)

            // Progress indicator dot
            Circle()
                .fill(ConversionOnboardingTheme.accentPrimary)
                .frame(width: 14, height: 14)
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.4), radius: 4, x: 0, y: 2)
                .offset(x: max(0, (geometry.size.width - 62) * progress))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
        }
        .padding(.horizontal, 24)
    }
}

struct ContentSection<Content: View>: View {
    let currentStep: Int
    let geometry: GeometryProxy
    let content: Content

    init(currentStep: Int, geometry: GeometryProxy, @ViewBuilder content: () -> Content) {
        self.currentStep = currentStep
        self.geometry = geometry
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: currentStep)
            Spacer(minLength: 0)
        }
        .frame(width: geometry.size.width)
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Enhanced Analysis View
struct AnalysisView: View {
    let animateIllustration: Bool
    let analysisSteps: [String]
    let onComplete: () -> Void
    let userProfile: AnxietyUserData
    
    @State private var currentAnalysisStep = 0
    @State private var showCompletion = false
    @State private var completionScale: CGFloat = 0.5
    @State private var completionOpacity: Double = 0
    @State private var particleAnimations: [Bool] = Array(repeating: false, count: 8)
    @State private var breathingScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    @State private var currentMessage = ""
    @Environment(\.colorScheme) var colorScheme
    
    let personalizedMessages = [
        "Processing your anxiety frequency patterns...",
        "Mapping your unique trigger responses...",
        "Analyzing your current wellness toolkit...", 
        "Understanding your support connections...",
        "Identifying your stress cycles...",
        "Crafting techniques just for you...",
        "Designing your personalized program...",
        "Completing your wellness blueprint..."
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            if !showCompletion {
                analysisContent
            } else {
                completionContent
            }
        }
        .onAppear {
            startAnalysisSequence()
        }
    }

    private var analysisStepIcons: [String] {
        ["brain.head.profile", "waveform.path.ecg", "heart.text.square", "person.fill.checkmark", "leaf.fill", "sparkles", "chart.line.uptrend.xyaxis", "checkmark.seal.fill"]
    }

    private var currentAnalysisIcon: String {
        let index = min(currentAnalysisStep, analysisStepIcons.count - 1)
        return analysisStepIcons[index]
    }

    private var analysisContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 24) {
                // Orb + particles lifted out into its own scene for more visual interest
                animationVisualizationView
                    .frame(width: 220, height: 220)

                textContentView

                analysisProgressStrip

                if !analysisPeekSteps.isEmpty {
                    analysisPeekCard
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
    }
    
    private var animationVisualizationView: some View {
        ZStack {
            // Outer glow ring
            outerGlowRingView
            
            // Floating particles around the main circle
            floatingParticlesView
            
            // Main central orb with enhanced design
            centralOrbView
            
            // Subtle sparkle effects
            sparkleEffectsView
        }
    }
    
    private var textContentView: some View {
        VStack(spacing: 12) {
            Text("Creating your plan")
                .font(.quicksand(size: 28, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                .padding(.horizontal, 20)
            
            Text(currentMessage)
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .lineLimit(2)
                .opacity(0.9)
                .animation(.easeInOut(duration: 0.5), value: currentMessage)
            
            // Progress indicator dots
            progressDotsView
                .padding(.top, 4)
        }
    }
    
    private var progressGridView: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(analysisSteps.enumerated()), id: \.offset) { index, step in
                    CompactAnalysisStepCard(
                        step: step,
                        isCompleted: index < currentAnalysisStep,
                        isActive: index == currentAnalysisStep,
                        index: index
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Bottom padding
            Spacer().frame(height: 40)
        }
    }

    private var analysisProgressStrip: some View {
        let progress = Double(currentAnalysisStep + 1) / Double(max(analysisSteps.count, 1))

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                Text("Blueprint progress")
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.quicksand(size: 13, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ConversionOnboardingTheme.glassStroke(for: colorScheme).opacity(0.35))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary,
                                    ConversionOnboardingTheme.accentSecondary
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 10)
                        .animation(.easeInOut(duration: 0.45), value: progress)
                }
            }
            .frame(height: 10)

            Text(currentAnalysisTitle)
                .font(.quicksand(size: 13, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                .lineLimit(2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(ConversionOnboardingTheme.cardBackground(for: colorScheme).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(ConversionOnboardingTheme.glassStroke(for: colorScheme), lineWidth: 1)
                )
        )
    }

    private var analysisPeekCard: some View {
        let steps = analysisPeekSteps

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Up next in your plan")
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                Spacer()

                Text("Live personalization")
                    .font(.quicksand(size: 11, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.accentSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ConversionOnboardingTheme.accentSecondary.opacity(0.12))
                    )
            }

            let lastIndex = steps.last?.index
            ForEach(steps, id: \.index) { step in
                analysisPeekRow(for: step)

                if step.index != lastIndex {
                    Divider()
                        .background(ConversionOnboardingTheme.glassStroke(for: colorScheme))
                        .opacity(0.25)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    colorScheme == .dark ?
                        Color.white.opacity(0.04) :
                        Color.white.opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(ConversionOnboardingTheme.glassStroke(for: colorScheme), lineWidth: 1)
                )
        )
    }

    private var analysisPeekSteps: [(index: Int, title: String)] {
        let enumeratedSteps = Array(analysisSteps.enumerated())
        guard !enumeratedSteps.isEmpty else { return [] }

        let startIndex = max(min(currentAnalysisStep - 1, enumeratedSteps.count - 3), 0)
        let endIndex = min(startIndex + 3, enumeratedSteps.count)

        return enumeratedSteps[startIndex..<endIndex].map { ($0.offset, $0.element) }
    }

    private var currentAnalysisTitle: String {
        guard analysisSteps.indices.contains(currentAnalysisStep) else {
            return "Personalizing every touchpoint"
        }
        return analysisSteps[currentAnalysisStep]
    }

    @ViewBuilder
    private func analysisPeekRow(for step: (index: Int, title: String)) -> some View {
        let isCompleted = step.index < currentAnalysisStep
        let isActive = step.index == currentAnalysisStep

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        isCompleted ?
                            ConversionOnboardingTheme.accentSecondary.opacity(0.25) :
                        isActive ?
                            ConversionOnboardingTheme.accentPrimary.opacity(0.25) :
                            ConversionOnboardingTheme.cardBackground(for: colorScheme).opacity(0.6)
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                isCompleted || isActive ?
                                    (colorScheme == .dark ? Color.white.opacity(0.5) : ConversionOnboardingTheme.accentPrimary.opacity(0.3)) :
                                    (colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)),
                                lineWidth: 1
                            )
                    )

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.quicksand(size: 14, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : ConversionOnboardingTheme.accentSecondary)
                } else if isActive {
                    Image(systemName: currentAnalysisIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : ConversionOnboardingTheme.accentPrimary)
                } else {
                    Text("\(step.index + 1)")
                        .font(.quicksand(size: 13, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isActive ? "In progress" : (isCompleted ? "Completed" : "Queued"))
                    .font(.quicksand(size: 11, weight: .semibold))
                    .foregroundColor(
                        isActive ?
                            ConversionOnboardingTheme.accentPrimary :
                            ConversionOnboardingTheme.secondaryText(for: colorScheme)
                    )

                Text(step.title)
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.accentSecondary)
            } else if isActive {
                Text("Now")
                    .font(.quicksand(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ConversionOnboardingTheme.accentPrimary,
                                        ConversionOnboardingTheme.accentSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .scaleEffect(pulseAnimation ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
            } else {
                Text("Soon")
                    .font(.quicksand(size: 11, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
            }
        }
        .padding(.vertical, 6)
    }
    
    private var completionContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating celebration particles
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(ConversionOnboardingTheme.accentPrimary.opacity(Double.random(in: 0.08...0.2)))
                        .frame(width: CGFloat.random(in: 4...10))
                        .position(
                            x: CGFloat.random(in: 30...geometry.size.width - 30),
                            y: CGFloat.random(in: 50...geometry.size.height * 0.6)
                        )
                        .blur(radius: 1)
                }

                VStack(spacing: 0) {
                    Spacer()

                    // Hero section with checkmark
                    enhancedCompletionHero
                        .padding(.bottom, 32)

                    // Title section
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(ConversionOnboardingTheme.accentPrimary)

                            Text("Your Wellness Plan")
                                .font(.quicksand(size: 28, weight: .medium))
                                .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                        }

                        Text("is Ready!")
                            .font(.quicksand(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        ConversionOnboardingTheme.accentPrimary,
                                        ConversionOnboardingTheme.accentSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .opacity(completionOpacity)
                    .padding(.bottom, 24)

                    // Benefits grid
                    enhancedBenefitsGrid
                        .opacity(completionOpacity)
                        .padding(.horizontal, 20)

                    Spacer()

                    // Bottom CTA section
                    VStack(spacing: 16) {
                        completionButtonView

                        // Trust indicators
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11))
                                Text("Secure")
                                    .font(.quicksand(size: 11, weight: .medium))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 11))
                                Text("Cancel anytime")
                                    .font(.quicksand(size: 11, weight: .medium))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                Text("100K+ users")
                                    .font(.quicksand(size: 11, weight: .medium))
                            }
                        }
                        .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                }
            }
        }
    }

    private var enhancedCompletionHero: some View {
        ZStack {
            // Pulsing outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                            ConversionOnboardingTheme.accentPrimary.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 130
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(breathingScale)

            // Inner glow ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary.opacity(0.4),
                            ConversionOnboardingTheme.accentSecondary.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .scaleEffect(completionScale)

            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary,
                            ConversionOnboardingTheme.accentSecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.5), radius: 25, x: 0, y: 10)
                .scaleEffect(completionScale)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(completionScale)
                .opacity(completionOpacity)
        }
    }

    private var enhancedBenefitsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                benefitCard(icon: "brain.head.profile", title: "AI-Personalized", subtitle: "Just for you")
                benefitCard(icon: "chart.line.uptrend.xyaxis", title: "Track Progress", subtitle: "See growth")
            }
            HStack(spacing: 12) {
                benefitCard(icon: "bell.badge", title: "Smart Reminders", subtitle: "Stay on track")
                benefitCard(icon: "heart.circle", title: "Daily Support", subtitle: "Always here")
            }
        }
    }

    private func benefitCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                Text(subtitle)
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ConversionOnboardingTheme.accentPrimary.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var completionHeroSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Radiating pulse rings
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.4 - Double(index) * 0.1),
                                    ConversionOnboardingTheme.accentSecondary.opacity(0.2 - Double(index) * 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: index == 0 ? 3 : 2
                        )
                        .frame(width: 90 + CGFloat(index * 35), height: 90 + CGFloat(index * 35))
                        .scaleEffect(breathingScale)
                        .opacity(completionOpacity * (0.5 - Double(index) * 0.12))
                        .animation(
                            .easeInOut(duration: 2.5 + Double(index) * 0.4)
                            .repeatForever(autoreverses: true),
                            value: breathingScale
                        )
                }

                // Subtle background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary.opacity(0.25),
                                ConversionOnboardingTheme.accentSecondary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                    .scaleEffect(breathingScale)

                successAnimationView
                    .frame(width: 100, height: 100)
            }
            .frame(height: 200)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                        .rotationEffect(.degrees(completionOpacity > 0.5 ? 15 : -15))
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: completionOpacity
                        )

                    Text("Your Wellness Plan")
                        .font(.quicksand(size: 26, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                        .rotationEffect(.degrees(completionOpacity > 0.5 ? -15 : 15))
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: completionOpacity
                        )
                }

                Text("is Ready!")
                    .font(.quicksand(size: 26, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary,
                                ConversionOnboardingTheme.accentSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .multilineTextAlignment(.center)
            .opacity(completionOpacity)
        }
    }
    
    private var successAnimationView: some View {
        ZStack {
            // Outer glow with pulsing effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary.opacity(0.25),
                            ConversionOnboardingTheme.accentSecondary.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(breathingScale)
                .blur(radius: 8)

            // Main circle with enhanced gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary,
                            ConversionOnboardingTheme.accentSecondary,
                            ConversionOnboardingTheme.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 90, height: 90)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.5), radius: 20, x: 0, y: 10)

            // Checkmark icon with enhanced styling
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(completionScale)
                .opacity(completionOpacity)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .allowsHitTesting(false)
    }
    
    private var successOrbView: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            ConversionOnboardingTheme.accentSecondary.opacity(0.2),
                            ConversionOnboardingTheme.accentPrimary.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 18
                )
                .frame(width: 180, height: 180)
                .blur(radius: 18)
                .opacity(0.35)
                .scaleEffect(breathingScale)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary.opacity(0.6),
                            ConversionOnboardingTheme.accentSecondary.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 130
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(breathingScale)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FF8FA3"),
                            ConversionOnboardingTheme.accentPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.4), radius: 30, x: 0, y: 10)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 2)
                )
                .scaleEffect(completionScale)
                .opacity(completionOpacity)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .opacity(0.9)
                .scaleEffect(completionScale)
            
            successIconView
                .scaleEffect(completionScale)
                .opacity(completionOpacity)
        }
    }
    
    private var successIconView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.quicksand(size: 36, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(breathingScale)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(1.0),
                    value: breathingScale
                )
            
            Image(systemName: "sparkles")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
                .opacity(completionOpacity > 0 ? 1.0 : 0.0)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(1.2),
                    value: completionOpacity
                )
        }
    }
    
    private var completionTextView: some View {
        VStack(spacing: 20) {
            completionDescriptionView
        }
    }
    
    private var completionDescriptionView: some View {
        VStack(spacing: 18) {
            Text("Your personalized program is ready")
                .font(.quicksand(size: 16, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
                .opacity(completionOpacity)
                .animation(.easeInOut(duration: 0.6).delay(0.4), value: completionOpacity)

            personalizedPlanHighlights
                .opacity(completionOpacity)
                .animation(.easeInOut(duration: 0.8).delay(0.6), value: completionOpacity)
        }
    }

    private var personalizedPlanHighlights: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row with icon
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.quicksand(size: 22, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(planThemeConfiguration.headline)
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(planThemeConfiguration.timeCommitment)
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                }
                Spacer(minLength: 0)
            }

            // Focus areas as horizontal chips with gradient backgrounds
            HStack(spacing: 6) {
                ForEach(highlightedFocuses.prefix(3), id: \.self) { focus in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ConversionOnboardingTheme.accentPrimary)
                            .frame(width: 4, height: 4)
                        Text(focus)
                            .font(.quicksand(size: 10, weight: .semibold))
                            .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ConversionOnboardingTheme.accentPrimary.opacity(0.12),
                                        ConversionOnboardingTheme.accentSecondary.opacity(0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
                Spacer(minLength: 0)
            }

            // Quick benefits row with enhanced styling
            HStack(spacing: 8) {
                PlanBenefitPill(icon: "brain.head.profile", text: "AI-Personalized")
                PlanBenefitPill(icon: "chart.line.uptrend.xyaxis", text: "Track Progress")
                PlanBenefitPill(icon: "heart.fill", text: "Daily Support")
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(hex: "1F1F23") : Color.white,
                            colorScheme == .dark ? Color(hex: "1A1A1C") : Color(hex: "F8F8F8")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                                    ConversionOnboardingTheme.accentSecondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: ConversionOnboardingTheme.accentPrimary.opacity(0.15),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
    }

    // MARK: - Personalized Plan Helpers

    private var friendlyDisplayName: String {
        let trimmed = userProfile.name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return trimmed.isEmpty ? "You" : trimmed
    }

    private var readinessBadge: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("Ready")
                    .font(.quicksand(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(ConversionOnboardingTheme.accentPrimary)
            )

            Text(planThemeConfiguration.timeCommitment)
                .font(.quicksand(size: 13, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
        }
    }

    private var focusChipGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 130), spacing: 12)
            ],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(highlightedFocuses, id: \.self) { focus in
                PlanFocusChip(text: focus)
            }
        }
    }

    private var highlightedFocuses: [String] {
        var values: [String] = []

        for goal in userProfile.primaryGoals {
            let label = goalDisplayName(for: goal)
            if !values.contains(label) {
                values.append(label)
            }
        }

        for area in userProfile.difficultyAreas {
            let label = difficultyDisplayName(for: area)
            if !values.contains(label) {
                values.append(label)
            }
        }

        if values.isEmpty {
            values = [
                "Steadier calm",
                "Restorative sleep",
                "Confident mindset",
                "Gentle focus rituals"
            ]
        }

        return Array(values.prefix(4))
    }

    private var glassDivider: some View {
        Rectangle()
            .fill(
                colorScheme == .dark ?
                    Color.white.opacity(0.06) :
                    Color.black.opacity(0.06)
            )
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    private var planTimelineView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your daily journey")
                .font(.quicksand(size: 13, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))

            ForEach(planThemeConfiguration.milestones, id: \.title) { milestone in
                PlanTimelineRow(icon: milestone.icon, title: milestone.title, detail: milestone.detail)
            }
        }
    }

    private var planThemeConfiguration: PlanThemeConfiguration {
        if userProfile.primaryGoals.contains("sleep") || userProfile.difficultyAreas.contains("sleep") {
            return PlanThemeConfiguration(
                headline: "Deeper rest & gentler nights",
                timeCommitment: "≈12 min / night",
                milestones: [
                    (icon: "moonphase.first.quarter", title: "Night reset ritual", detail: "Breath pacing + weighted-body scan to slow the nervous system"),
                    (icon: "sparkles", title: "Calming affirmations", detail: "Gentle prompts that reframe late-night spirals"),
                    (icon: "bed.double.fill", title: "Sleep closure", detail: "Journaling cues to release the day and prepare for rest")
                ]
            )
        } else if userProfile.primaryGoals.contains("performance") || userProfile.difficultyAreas.contains("performance") {
            return PlanThemeConfiguration(
                headline: "Sharper focus & confident delivery",
                timeCommitment: "≈10 min / day",
                milestones: [
                    (icon: "sunrise.fill", title: "Focus calibration", detail: "2-min box breathing + intention setting"),
                    (icon: "bolt.fill", title: "Midday power reset", detail: "Somatic micro-break to release tension & reset posture"),
                    (icon: "flag.checkered", title: "Evening reflection", detail: "Win-tracking ritual with AI reflections")
                ]
            )
        } else if userProfile.primaryGoals.contains("selfesteem") || userProfile.primaryGoals.contains("happiness") {
            return PlanThemeConfiguration(
                headline: "Grounded confidence & lighter mood",
                timeCommitment: "≈9 min / day",
                milestones: [
                    (icon: "sun.max.fill", title: "Morning priming", detail: "Compassionate check-in to anchor self-talk"),
                    (icon: "heart.fill", title: "Midday nervous system break", detail: "Guided somatic taps to soften harsh inner voice"),
                    (icon: "sparkles", title: "Nightly wins", detail: "Celebratory prompts that reinforce progress")
                ]
            )
        } else {
            return PlanThemeConfiguration(
                headline: "Steadier calm from sunrise to sleep",
                timeCommitment: "≈8 min / day",
                milestones: [
                    (icon: "sunrise.fill", title: "Grounding breath", detail: "Coherent breathing to set a calmer tone"),
                    (icon: "leaf.fill", title: "Midday reset", detail: "2-min somatic release when stress spikes"),
                    (icon: "moon.stars.fill", title: "Evening decompression", detail: "Guided release + gratitude prompts")
                ]
            )
        }
    }


    private func goalDisplayName(for key: String) -> String {
        switch key {
        case "anxiety": return "Ease anxiety"
        case "sleep": return "Restore sleep"
        case "stress": return "Lower stress"
        case "selfesteem": return "Boost confidence"
        case "performance": return "Peak performance"
        case "happiness": return "Feel lighter"
        default: return key.capitalized
        }
    }

    private func difficultyDisplayName(for key: String) -> String {
        switch key {
        case "sleep": return "Sleep rhythms"
        case "focus": return "Deep focus"
        case "relationships": return "Connected relationships"
        case "performance": return "Showing up strong"
        default: return key.capitalized
        }
    }

    private var premiumFeaturesView: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 140), spacing: 20)
            ],
            spacing: 20
        ) {
            ForEach(premiumFeatureData, id: \.title) { feature in
                PremiumCompletionFeature(
                    icon: feature.icon,
                    title: feature.title,
                    subtitle: feature.subtitle,
                    color: feature.color
                )
            }
        }
    }

    private var premiumFeatureData: [(icon: String, title: String, subtitle: String, color: Color)] {
        [
            (
                icon: "brain.head.profile",
                title: "AI-Personalized",
                subtitle: "Custom techniques for you",
                color: ConversionOnboardingTheme.accentPrimary
            ),
            (
                icon: "chart.line.uptrend.xyaxis",
                title: "Progress Tracking",
                subtitle: "See your growth daily",
                color: ConversionOnboardingTheme.accentSecondary
            ),
            (
                icon: "heart.text.square.fill",
                title: "Proven Methods",
                subtitle: "Science-backed relief",
                color: ConversionOnboardingTheme.accentTertiary
            ),
            (
                icon: "sparkles",
                title: "24/7 Support",
                subtitle: "Always here for you",
                color: Color(hex: "FFB6E3")
            )
        ]
    }
    
    private var completionButtonView: some View {
        Button(action: {
            // Haptic feedback on completion
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onComplete()
        }) {
            HStack(spacing: 14) {
                Text("Start Your Wellness Journey")
                    .font(.quicksand(size: 17, weight: .bold))

                Image(systemName: "arrow.right.circle.fill")
                    .font(.quicksand(size: 20, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary,
                                ConversionOnboardingTheme.accentSecondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .opacity(completionOpacity)
        .scaleEffect(completionScale)
    }
    
    private func startAnalysisSequence() {
        // Initialize animations with smoother entry
        withAnimation(.easeOut(duration: 0.8)) {
            currentMessage = personalizedMessages[0]
        }

        // Start breathing animation smoothly
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            breathingScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                pulseAnimation = true
            }
        }

        // Smoother progression with varied timing for natural feel
        Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { timer in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                if currentAnalysisStep < analysisSteps.count - 1 {
                    currentAnalysisStep += 1

                    // Smooth message transition
                    if currentAnalysisStep < personalizedMessages.count {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentMessage = personalizedMessages[currentAnalysisStep]
                        }
                    }
                } else {
                    timer.invalidate()
                    showCompletionAnimation()
                }
            }
        }
    }
    
    private func showCompletionAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showCompletion = true
            }
            
            // Animate completion elements with more elegant spring
            withAnimation(.interactiveSpring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.4).delay(0.1)) {
                completionScale = 1.0
                completionOpacity = 1.0
            }
            
            // Start breathing animation after completion appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    breathingScale = 1.15
                }
            }
            
            // Trigger particle animations with staggered timing
            for i in 0..<particleAnimations.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.08) {
                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7)) {
                        particleAnimations[i] = true
                    }
                }
            }
        }
    }
    
    // MARK: - Complex Animation Views (Extracted to Fix Compiler)
    
    private var floatingParticlesView: some View {
        ForEach(0..<8, id: \.self) { index in
            floatingParticleView(for: index)
        }
    }
    
    private func floatingParticleView(for index: Int) -> some View {
        let particleGradient = LinearGradient(
            colors: [
                ConversionOnboardingTheme.accentPrimary.opacity(0.7),
                ConversionOnboardingTheme.accentSecondary.opacity(0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        let angle = Double(index) * .pi / 4 + (breathingScale - 1) * 2 * .pi
        let xOffset = cos(angle) * 70
        let yOffset = sin(angle) * 70
        
        return Circle()
            .fill(particleGradient)
            .frame(width: 8, height: 8)
            .offset(x: xOffset, y: yOffset)
            .scaleEffect(pulseAnimation ? 1.2 : 0.6)
            .opacity(pulseAnimation ? 0.9 : 0.4)
            .animation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.2),
                value: pulseAnimation
            )
    }
    
    private var sparkleEffectsView: some View {
        ForEach(0..<4, id: \.self) { index in
            sparkleView(for: index)
        }
    }
    
    private func sparkleView(for index: Int) -> some View {
        let angle = Double(index) * .pi / 2 + (breathingScale - 1) * 4 * .pi
        let xOffset = cos(angle) * 100
        let yOffset = sin(angle) * 100
        let opacity = breathingScale > 1.05 ? 1.0 : 0.0
        
        return Image(systemName: "sparkle")
            .font(.quicksand(size: 12, weight: .light))
            .foregroundColor(Color.white.opacity(0.6))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .animation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.5),
                value: breathingScale
            )
    }
    
    private var progressDotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary.opacity(0.85),
                                ConversionOnboardingTheme.accentSecondary.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 6, height: 6)
                    .scaleEffect(breathingScale > 1.0 ? 1.3 : 0.7)
                    .opacity(breathingScale > 1.0 ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.3),
                        value: breathingScale
                    )
            }
        }
        .padding(.top, 4)
    }
    
    private var centralOrbView: some View {
        ZStack {
            // Soft outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary.opacity(0.3),
                            ConversionOnboardingTheme.accentSecondary.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 25,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 8)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)

            // Main gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            ConversionOnboardingTheme.accentPrimary,
                            ConversionOnboardingTheme.accentSecondary,
                            ConversionOnboardingTheme.accentPrimary.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.4), radius: 15, x: 0, y: 5)

            // Dynamic icon with smooth transition
            Image(systemName: currentAnalysisIcon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
                .transition(.scale.combined(with: .opacity))
                .id(currentAnalysisIcon)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentAnalysisIcon)
        }
        .scaleEffect(pulseAnimation ? 1.08 : 0.98)
        .animation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true),
            value: pulseAnimation
        )
    }
    
    private var outerGlowRingView: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        ConversionOnboardingTheme.accentPrimary.opacity(0.6),
                        ConversionOnboardingTheme.accentSecondary.opacity(0.35),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .frame(width: 140, height: 140)
            .scaleEffect(breathingScale)
            .rotationEffect(.degrees(breathingScale * 360))
            .animation(
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true),
                value: breathingScale
            )
    }
}

struct WellnessAnalysisStepRow: View {
    let step: String
    let isCompleted: Bool
    let isActive: Bool
    let animateIllustration: Bool
    let colorScheme: ColorScheme
    
    private var stepTextColor: Color {
        if isCompleted {
            return colorScheme == .dark ? Color(hex: "BAF8E0") : Color(hex: "166534")
        } else if isActive {
            return ConversionOnboardingTheme.accentPrimary
        } else {
            return ConversionOnboardingTheme.mutedText(for: colorScheme).opacity(0.7)
        }
    }
    
    private var statusCircleGradient: LinearGradient {
        if isCompleted {
            return LinearGradient(
                colors: [
                    Color(hex: "8AF5CF"),
                    Color(hex: "37D0A8")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isActive {
            return LinearGradient(
                colors: [
                    ConversionOnboardingTheme.accentPrimary,
                    ConversionOnboardingTheme.accentSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let colors = colorScheme == .dark ? [
                Color.white.opacity(0.08),
                Color.white.opacity(0.05)
            ] : [
                Color(hex: "F5F5F5"),
                Color(hex: "E8E8E8")
            ]
            return LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Wellness-themed status indicator
            ZStack {
                // Background circle with glass effect
                Circle()
                    .fill(statusCircleGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(
                                isCompleted || isActive ? Color.white.opacity(0.3) :
                                Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: isCompleted ? 
                            Color(hex: "8AF5CF").opacity(0.35) :
                        isActive ? 
                            ConversionOnboardingTheme.accentPrimary.opacity(0.3) : 
                            Color.clear,
                        radius: isCompleted || isActive ? 6 : 0,
                        x: 0, y: 2
                    )
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else if isActive {
                    // Pulsing center dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .scaleEffect(animateIllustration ? 1.4 : 0.8)
                        .opacity(animateIllustration ? 1.0 : 0.6)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                            value: animateIllustration
                        )
                } else {
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(step)
                .font(.quicksand(size: 16, weight: isActive ? .semibold : .medium))
                .foregroundColor(stepTextColor)
            
            Spacer()
            
            // Enhanced progress indicator
            if isActive {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ConversionOnboardingTheme.accentPrimary,
                                        ConversionOnboardingTheme.accentSecondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateIllustration ? 1.3 : 0.7)
                            .opacity(animateIllustration ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.4),
                                value: animateIllustration
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isActive ? 
                        (colorScheme == .dark ? 
                            Color.white.opacity(0.05) : 
                            Color(hex: "F3E5F5").opacity(0.3)) :
                        Color.clear
                )
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Conversion-Optimized Onboarding
struct ConversionOnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var userProfile = AnxietyUserData()
    @State private var animateIllustration = false
    @State private var impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var analysisTimer: Timer?
    @State private var isNavigating = false
    @State private var isSelectionLocked = false // Prevents double-taps during transition
    @State private var showPaywall = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible = false
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var mainBackgroundGradient: LinearGradient {
        let gradientColors = ConversionOnboardingTheme.backgroundGradient(for: colorScheme)
        return LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0: breathingIntroStep
        case 1: goalSelectionStep
        case 2: calmComparisonStep
        case 3: anxietyFrequencyStep
        case 4: ritualValueStep
        case 5: howDidYouHearStep
        case 6: noticeShiftStep
        case 7: difficultyAreasStep
        case 8: ageStep
        case 9: dailyLifeImpactStep
        case 10: communityProofStep
        case 11: copingStrategiesStep
        case 12: previousSolutionsStep
        case 13: nameAndAgeStep
        case 14: analysisStep
        default: EmptyView()
        }
    }
    
    let totalSteps = 15
    let analysisSteps = [
        "Understanding your anxiety frequency",
        "Analyzing your personal triggers", 
        "Evaluating your current coping strategies",
        "Assessing your support network",
        "Identifying your stress patterns",
        "Creating personalized techniques",
        "Building your custom recovery plan",
        "Finalizing your wellness roadmap"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if !showPaywall {
                    // Only show onboarding content when paywall is not visible
                    ZStack {
                        // Clean background matching main app
                        CalmingAnimatedBackground()
                            .ignoresSafeArea(.all)

                        VStack(spacing: 0) {
                            // Hide header only for the final analysis step so the name screen shows progress
                            if currentStep < totalSteps - 1 {
                                HeaderSection(
                                    currentStep: currentStep,
                                    totalSteps: totalSteps,
                                    geometry: geometry,
                                    onBack: {
                                        // Haptic feedback on back
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            currentStep -= 1
                                        }
                                    }
                                )
                                .padding(.top, 12)
                            }

                            // Main content with smooth transitions - properly centered
                            ContentSection(currentStep: currentStep, geometry: geometry) {
                                currentStepView
                            }
                        }
                    }
                    .transition(.opacity)
                }

                // Paywall overlay - completely replaces onboarding content
                if showPaywall {
                    LiquidGlassPaywallView(isPresented: $showPaywall)
                        .transition(.opacity)
                        .zIndex(1000)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            startAnimations()
        }
        .animation(.easeInOut(duration: 0.3), value: showPaywall)
        .onChange(of: showPaywall) { _, newValue in
            // When paywall closes and user has subscription, immediately complete onboarding
            if !newValue && UserDefaults.standard.bool(forKey: "has_active_subscription") {
                UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                isPresented = false
            }
        }
        .onChange(of: currentStep) { _, _ in
            // Haptic feedback on page change
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let bottomInset = UIApplication.shared.connectedScenes
                .compactMap { scene -> CGFloat? in
                    guard let windowScene = scene as? UIWindowScene else { return nil }
                    return windowScene.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom
                }
                .first ?? 0
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                keyboardHeight = max(0, frame.height - bottomInset)
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                keyboardHeight = 0
                isKeyboardVisible = false
            }
        }
    }
    
    // Enhanced breathing intro step with premium orb visualization
    private var breathingIntroStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Breathing orb with instruction inside
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                        lineWidth: 1.5
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateIllustration ? 1.15 : 0.9)
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                        value: animateIllustration
                    )

                // Main breathing orb with enhanced design
                ZStack {
                    // Outer glow layer
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.4),
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 120
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 20)

                    // Main orb body
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FFAABB").opacity(0.8),
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.7),
                                    ConversionOnboardingTheme.accentSecondary.opacity(0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 85
                            )
                        )
                        .frame(width: 150, height: 150)
                        .blur(radius: 12)

                    // Inner highlight
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                center: UnitPoint(x: 0.35, y: 0.35),
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 150, height: 150)
                        .blur(radius: 8)
                }
                .scaleEffect(animateIllustration ? 1.15 : 0.9)
                .animation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                    value: animateIllustration
                )

                // Breathing text inside orb
                VStack(spacing: 4) {
                    Text(animateIllustration ? "Breathe Out" : "Breathe In")
                        .font(.quicksand(size: 18, weight: .bold))
                    Text(animateIllustration ? "6 seconds" : "4 seconds")
                        .font(.quicksand(size: 13, weight: .medium))
                        .opacity(0.85)
                }
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .frame(height: 220)

            Spacer().frame(height: 32)

            // Text content
            VStack(spacing: 12) {
                Text("Let's begin with calm")
                    .font(.quicksand(size: 26, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                Text("Follow the breathing pattern to center yourself")
                    .font(.quicksand(size: 15, weight: .regular))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button("I'm ready") {
                selectWithHaptic { }
            }
            .buttonStyle(Primary3DButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateIllustration = true
                }
            }
        }
    }

    private var breathingInstructionPill: some View {
        let title = animateIllustration ? "Breathe Out" : "Breathe In"
        let detail = animateIllustration ? "Release gently for 6" : "Fill deeply for 4"

        return VStack(spacing: 4) {
            Text(title)
                .font(.quicksand(size: 18, weight: .semibold))
            Text(detail)
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.45))
                .overlay(
                    Capsule()
                        .stroke(ConversionOnboardingTheme.accentPrimary.opacity(0.4), lineWidth: 1)
                )
        )
    }
    
    // Calm-style goal selection step with fixed layout
    private var goalSelectionStep: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header section with proper spacing from progress bar
                VStack(spacing: 16) {
                    Text("What brings you here?")
                        .font(.quicksand(size: 26, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                        .padding(.horizontal, 40)
                        .padding(.top, 24)

                    Text("We'll personalize recommendations based on your goals")
                        .font(.quicksand(size: 16, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 16)

                // Goals options with scrollable content - takes all available space
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        GoalOption(
                            icon: "heart.circle.fill",
                            title: "Reduce Anxiety",
                            isSelected: userProfile.primaryGoals.contains("anxiety"),
                            action: { toggleSelectionWithHaptic("anxiety", in: \.primaryGoals) }
                        )

                        GoalOption(
                            icon: "bed.double.circle.fill",
                            title: "Better Sleep",
                            isSelected: userProfile.primaryGoals.contains("sleep"),
                            action: { toggleSelectionWithHaptic("sleep", in: \.primaryGoals) }
                        )

                        GoalOption(
                            icon: "figure.mind.and.body.circle.fill",
                            title: "Reduce Stress",
                            isSelected: userProfile.primaryGoals.contains("stress"),
                            action: { toggleSelectionWithHaptic("stress", in: \.primaryGoals) }
                        )

                        GoalOption(
                            icon: "brain.head.profile.fill",
                            title: "Build Self-Esteem",
                            isSelected: userProfile.primaryGoals.contains("selfesteem"),
                            action: { toggleSelectionWithHaptic("selfesteem", in: \.primaryGoals) }
                        )

                        GoalOption(
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            title: "Improve Performance",
                            isSelected: userProfile.primaryGoals.contains("performance"),
                            action: { toggleSelectionWithHaptic("performance", in: \.primaryGoals) }
                        )

                        GoalOption(
                            icon: "sun.max.circle.fill",
                            title: "Increase Happiness",
                            isSelected: userProfile.primaryGoals.contains("happiness"),
                            action: { toggleSelectionWithHaptic("happiness", in: \.primaryGoals) }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Space for button overlay
                }
                .frame(maxHeight: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                // Fixed button area at consistent position
                VStack(spacing: 0) {
                    Button("Continue") {
                        nextStep()
                    }
                    .buttonStyle(WellnessButtonStyle(isSelected: !userProfile.primaryGoals.isEmpty))
                    .disabled(userProfile.primaryGoals.isEmpty)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color.black.opacity(0),
                            Color.black.opacity(0.95),
                            Color.black
                        ] : [
                            Color(hex: "FFF0F7").opacity(0),
                            Color(hex: "FFF0F7").opacity(0.95),
                            Color(hex: "FFF0F7")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
    
    // Enhanced question layout - positioned higher
    private var anxietyFrequencyStep: some View {
        VStack(spacing: 36) {
            Spacer().frame(height: 40) // Position content higher
            
            VStack(spacing: 20) {
                Text("How often do you feel anxious?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                    .padding(.horizontal, 40)
                
                Text("Be honest - this helps us understand your unique experience")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button("Daily - it's almost constant") {
                    selectWithHaptic { userProfile.anxietyFrequency = "daily" }
                }
                .buttonStyle(WellnessButtonStyle(isSelected: userProfile.anxietyFrequency == "daily"))
                .disabled(isSelectionLocked)

                Button("Several times a week") {
                    selectWithHaptic { userProfile.anxietyFrequency = "weekly" }
                }
                .buttonStyle(WellnessButtonStyle(isSelected: userProfile.anxietyFrequency == "weekly"))
                .disabled(isSelectionLocked)

                Button("A few times a month") {
                    selectWithHaptic { userProfile.anxietyFrequency = "monthly" }
                }
                .buttonStyle(WellnessButtonStyle(isSelected: userProfile.anxietyFrequency == "monthly"))
                .disabled(isSelectionLocked)

                Button("Occasionally") {
                    selectWithHaptic { userProfile.anxietyFrequency = "occasionally" }
                }
                .buttonStyle(WellnessButtonStyle(isSelected: userProfile.anxietyFrequency == "occasionally"))
                .disabled(isSelectionLocked)
            }
            .padding(.horizontal, 20)
            .allowsHitTesting(!isSelectionLocked)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    // Enhanced analysis step with completion logic
    private var analysisStep: some View {
        AnalysisView(
            animateIllustration: animateIllustration,
            analysisSteps: analysisSteps,
            onComplete: {
                // Save user's name for personalized paywall
                UserDefaults.standard.set(userProfile.name.isEmpty ? "Friend" : userProfile.name, forKey: "user_name")
                // Add slight delay for smooth transition to paywall
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showPaywall = true
                    }
                }
            },
            userProfile: userProfile
        )
    }
    
    private var howDidYouHearStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("How did you hear about us?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Help us understand how you found this app")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("Social media (TikTok, Instagram, etc.)") {
                    selectWithHaptic { userProfile.hearAboutUs = "social_media" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.hearAboutUs == "social_media"))

                Button("Friend or family recommendation") {
                    selectWithHaptic { userProfile.hearAboutUs = "friend_family" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.hearAboutUs == "friend_family"))

                Button("App Store search") {
                    selectWithHaptic { userProfile.hearAboutUs = "app_store" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.hearAboutUs == "app_store"))

                Button("Online article or blog") {
                    selectWithHaptic { userProfile.hearAboutUs = "online_article" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.hearAboutUs == "online_article"))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(!isSelectionLocked)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var noticeShiftStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("When do you notice your anxiety shift?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Understanding triggers helps us personalize your experience")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("In social situations") {
                    selectWithHaptic { userProfile.anxietyShift = "social" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.anxietyShift == "social"))

                Button("When thinking about the future") {
                    selectWithHaptic { userProfile.anxietyShift = "future" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.anxietyShift == "future"))

                Button("At work or school") {
                    selectWithHaptic { userProfile.anxietyShift = "work_school" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.anxietyShift == "work_school"))

                Button("When I'm alone with my thoughts") {
                    selectWithHaptic { userProfile.anxietyShift = "alone" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.anxietyShift == "alone"))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(!isSelectionLocked)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var difficultyAreasStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Which areas feel most difficult?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Select all that apply - there's no wrong answer")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("Sleep and rest") {
                    toggleSelectionWithHaptic("sleep", in: \.difficultyAreas)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.difficultyAreas.contains("sleep")))
                
                Button("Concentration and focus") {
                    toggleSelectionWithHaptic("focus", in: \.difficultyAreas)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.difficultyAreas.contains("focus")))
                
                Button("Relationships") {
                    toggleSelectionWithHaptic("relationships", in: \.difficultyAreas)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.difficultyAreas.contains("relationships")))
                
                Button("Work or school performance") {
                    toggleSelectionWithHaptic("performance", in: \.difficultyAreas)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.difficultyAreas.contains("performance")))
                
                Button("Continue") {
                    nextStep()
                }
                .buttonStyle(SimpleButtonStyle(isSelected: !userProfile.difficultyAreas.isEmpty))
                .disabled(userProfile.difficultyAreas.isEmpty)
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var ageStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's your age range?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("This helps us provide age-appropriate content")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("18-24") {
                    selectWithHaptic { userProfile.ageRange = "18-24" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.ageRange == "18-24"))

                Button("25-34") {
                    selectWithHaptic { userProfile.ageRange = "25-34" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.ageRange == "25-34"))

                Button("35-44") {
                    selectWithHaptic { userProfile.ageRange = "35-44" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.ageRange == "35-44"))

                Button("45+") {
                    selectWithHaptic { userProfile.ageRange = "45+" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.ageRange == "45+"))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(!isSelectionLocked)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var dailyLifeImpactStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("How much does anxiety impact your daily life?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Be honest - this helps us create the right support plan")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("It controls most of my decisions") {
                    selectWithHaptic { userProfile.impactLevel = "high" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.impactLevel == "high"))

                Button("It affects some of my choices") {
                    selectWithHaptic { userProfile.impactLevel = "medium" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.impactLevel == "medium"))

                Button("It's noticeable but manageable") {
                    selectWithHaptic { userProfile.impactLevel = "low" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.impactLevel == "low"))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(!isSelectionLocked)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var copingStrategiesStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What helps you cope right now?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Select all that currently work for you")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("Deep breathing") {
                    toggleSelectionWithHaptic("breathing", in: \.copingMethods)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.copingMethods.contains("breathing")))
                
                Button("Exercise or movement") {
                    toggleSelectionWithHaptic("exercise", in: \.copingMethods)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.copingMethods.contains("exercise")))
                
                Button("Music or podcasts") {
                    toggleSelectionWithHaptic("music", in: \.copingMethods)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.copingMethods.contains("music")))
                
                Button("Nothing works well yet") {
                    toggleSelectionWithHaptic("nothing", in: \.copingMethods)
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.copingMethods.contains("nothing")))
                
                Button("Continue") {
                    nextStep()
                }
                .buttonStyle(SimpleButtonStyle(isSelected: !userProfile.copingMethods.isEmpty))
                .disabled(userProfile.copingMethods.isEmpty)
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var previousSolutionsStep: some View {
        VStack(spacing: 50) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Have you tried anxiety solutions before?")
                    .font(.quicksand(size: 26, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color(hex: "1A1A1A"))
                
                Text("Understanding your experience helps us do better")
                    .font(.quicksand(size: 17, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "4A4A4A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 14) {
                Button("Yes, but nothing worked long-term") {
                    selectWithHaptic { userProfile.previousSolutions = "tried_failed" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.previousSolutions == "tried_failed"))

                Button("Yes, some things helped a bit") {
                    selectWithHaptic { userProfile.previousSolutions = "tried_helped" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.previousSolutions == "tried_helped"))

                Button("No, this is my first time seeking help") {
                    selectWithHaptic { userProfile.previousSolutions = "first_time" }
                }
                .buttonStyle(SimpleButtonStyle(isSelected: userProfile.previousSolutions == "first_time"))
            }
            .padding(.horizontal, 24)
            .allowsHitTesting(!isSelectionLocked)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var nameAndAgeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Center content section
            VStack(spacing: 32) {
                // Animated greeting icon - only when keyboard hidden
                ZStack {
                    // Pulsing outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.3),
                                    ConversionOnboardingTheme.accentSecondary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 90, height: 90)

                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 45
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                }
                .opacity(isKeyboardVisible ? 0 : 1)
                .scaleEffect(isKeyboardVisible ? 0.8 : 1)

                // Title section
                VStack(spacing: 8) {
                    Text(isKeyboardVisible ? "Nice to meet you!" : "What should we call you?")
                        .font(.quicksand(size: isKeyboardVisible ? 22 : 26, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                    Text("Let's personalize your journey")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .opacity(isKeyboardVisible ? 0 : 1)
                }

                // Clean, minimal input field
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        Image(systemName: isNameFieldFocused ? "person.circle.fill" : "person.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(
                                isNameFieldFocused ?
                                    ConversionOnboardingTheme.accentPrimary :
                                    ConversionOnboardingTheme.secondaryText(for: colorScheme)
                            )

                        TextField("Your name", text: $userProfile.name)
                            .focused($isNameFieldFocused)
                            .font(.quicksand(size: 20, weight: .medium))
                            .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit {
                                if !userProfile.name.isEmpty {
                                    isNameFieldFocused = false
                                    nextStep()
                                }
                            }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isNameFieldFocused ?
                                            ConversionOnboardingTheme.accentPrimary :
                                            (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)),
                                        lineWidth: isNameFieldFocused ? 2 : 1
                                    )
                            )
                            .shadow(
                                color: isNameFieldFocused ? ConversionOnboardingTheme.accentPrimary.opacity(0.15) : Color.clear,
                                radius: 12,
                                x: 0,
                                y: 4
                            )
                    )

                    // Skip button
                    Button(action: {
                        selectWithHaptic { userProfile.name = "" }
                        nextStep()
                    }) {
                        Text("Skip for now")
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button - always present but with opacity
            Button("Continue") {
                isNameFieldFocused = false
                nextStep()
            }
            .buttonStyle(Primary3DButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .opacity(userProfile.name.isEmpty ? 0 : 1)
            .allowsHitTesting(!userProfile.name.isEmpty)
        }
        .padding(.bottom, isKeyboardVisible ? keyboardHeight : 0)
        .animation(.easeInOut(duration: 0.25), value: isKeyboardVisible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
        .onDisappear {
            isNameFieldFocused = false
        }
    }

    // MARK: - Value Education Steps

    private var calmComparisonStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                }

                VStack(spacing: 8) {
                    Text("When chaos hits")
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                    Text("See the difference with guided support")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                }

                // Before/After comparison cards - completely redesigned
                VStack(spacing: 16) {
                    // Before card - sad state
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 50, height: 50)

                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.red.opacity(0.7))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("Without")
                                    .font(.quicksand(size: 12, weight: .bold))
                                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.red.opacity(0.6))
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("40+")
                                    .font(.quicksand(size: 32, weight: .heavy))
                                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                                Text("min")
                                    .font(.quicksand(size: 16, weight: .semibold))
                                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                                    .offset(y: -2)
                            }

                            Text("of racing thoughts before sleep")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                                .lineSpacing(1)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white)

                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.red.opacity(0.15),
                                            Color.red.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )

                    // After card - happy state with celebration
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.2),
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.1)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 25
                                    )
                                )
                                .frame(width: 50, height: 50)

                            Image(systemName: "sparkles")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("With Zenya")
                                    .font(.quicksand(size: 12, weight: .bold))
                                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                            }

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("< 60")
                                    .font(.quicksand(size: 32, weight: .heavy))
                                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                                Text("sec")
                                    .font(.quicksand(size: 16, weight: .semibold))
                                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                                    .offset(y: -2)
                            }

                            Text("to interrupt thought spirals")
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                                .lineSpacing(1)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: colorScheme == .dark ? [
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.12),
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.08)
                                        ] : [
                                            Color.white,
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            ConversionOnboardingTheme.accentPrimary.opacity(0.5),
                                            ConversionOnboardingTheme.accentSecondary.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    )
                    .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.2), radius: 12, x: 0, y: 6)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") { nextStep() }
                .buttonStyle(Primary3DButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    private var ritualValueStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                }

                VStack(spacing: 8) {
                    Text("Your daily rhythm")
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                    Text("4 micro-moments throughout your day")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                }

                // Timeline grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    RitualCard(icon: "sunrise.fill", time: "Morning", title: "Ground", color: Color.orange)
                    RitualCard(icon: "sun.max.fill", time: "Midday", title: "Reset", color: Color.yellow)
                    RitualCard(icon: "sunset.fill", time: "Evening", title: "Unwind", color: Color.purple)
                    RitualCard(icon: "moon.stars.fill", time: "Night", title: "Rest", color: Color.blue)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") { nextStep() }
                .buttonStyle(Primary3DButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    private var communityProofStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                }

                VStack(spacing: 8) {
                    Text("Proven results")
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                    Text("Science-backed techniques that work")
                        .font(.quicksand(size: 15, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                }

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ProofStatCard(value: "4.8", label: "App Store", icon: "star.fill")
                    ProofStatCard(value: "67%", label: "Less anxious", icon: "arrow.down")
                    ProofStatCard(value: "2 min", label: "To feel calm", icon: "timer")
                }

                // Testimonial
                VStack(spacing: 8) {
                    Text("\"Finally something that actually works for my anxiety.\"")
                        .font(.quicksand(size: 14, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .italic()
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Continue") { nextStep() }
                .buttonStyle(Primary3DButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func valueEducationLayout<Content: View>(
        title: String,
        subtitle: String,
        badge: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.quicksand(size: 28, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                        Text(subtitle)
                            .font(.quicksand(size: 15, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                            .padding(.horizontal, 8)

                        Text(badge.uppercased())
                            .font(.quicksand(size: 11, weight: .bold))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .foregroundColor(.white)
                            .background(
                                Capsule()
                                    .fill(ConversionOnboardingTheme.accentPrimary)
                            )
                    }

                    content()
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                                            lineWidth: 1
                                        )
                                )
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button("Continue") {
                nextStep()
            }
            .buttonStyle(Primary3DButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var calmComparisonItems: [ValueComparisonItem] {
        [
            .init(
                icon: "bolt.heart",
                title: "Racing thoughts",
                pain: "Mind loops for 40+ minutes before sleep.",
                relief: "2-min resonance breathing interrupts spirals in under 60 seconds."
            ),
            .init(
                icon: "waveform.path.ecg",
                title: "Body tension",
                pain: "Shoulders locked + shallow breathing all day.",
                relief: "Somatic micro-breaks cue you when posture + breath collapse."
            )
        ]
    }

    private var ritualMoments: [ValueTimelineMilestone] {
        [
            .init(icon: "sunrise.fill", title: "Morning priming", detail: "Ground with a 90-second check-in + clear plan for the day."),
            .init(icon: "clock", title: "Midday reset", detail: "App senses increased stress words and suggests a guided release."),
            .init(icon: "moon.zzz", title: "Nightly decompression", detail: "Sleep stories pair with breath pacing to slow your nervous system.")
        ]
    }

    private var memberQuote: ValueTestimonial {
        ValueTestimonial(
            author: "Jess • Product manager",
            quote: "\"My therapist asked what changed—it's the 4 touchpoints reminding me to breathe before panic hits.\""
        )
    }

    private var communityMetrics: [ValueMetric] {
        [
            .init(value: "82%", caption: "feel calmer by week 2"),
            .init(value: "67%", caption: "sleep deeper within 10 nights"),
            .init(value: "24/7", caption: "AI coach at your side")
        ]
    }
    
    
    // Helper functions with navigation cooldown and haptic feedback
    private func nextStep() {
        guard !isNavigating else { return }

        // Strong haptic feedback on continue
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        isNavigating = true

        // Save user's name when moving from name input step
        if currentStep == 3 && !userProfile.name.isEmpty {
            UserDefaults.standard.set(userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "user_name")
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if currentStep < totalSteps - 1 {
                currentStep += 1
            } else {
                // Save that onboarding is complete
                UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                isPresented = false
            }
        }

        // Reset navigation cooldown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isNavigating = false
        }
    }

    private func selectWithHaptic(action: @escaping () -> Void) {
        // Prevent double-taps during transition
        guard !isSelectionLocked else { return }

        // Lock immediately to prevent any other taps
        isSelectionLocked = true

        // Impact haptic on button press
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        action()

        // Transition to next step after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            nextStep()
            // Unlock after transition completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isSelectionLocked = false
            }
        }
    }

    private func toggleSelectionWithHaptic(_ item: String, in keyPath: WritableKeyPath<AnxietyUserData, [String]>) {
        guard !isNavigating else { return }

        // Impact haptic on toggle
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if userProfile[keyPath: keyPath].contains(item) {
            userProfile[keyPath: keyPath].removeAll { $0 == item }
        } else {
            userProfile[keyPath: keyPath].append(item)
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            animateIllustration = true
        }
    }
}

// 3D Button Style with Press Animation
struct WellnessButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.colorScheme) var colorScheme

    private var textColor: Color {
        isSelected ? Color.white : ConversionOnboardingTheme.primaryText(for: colorScheme).opacity(0.9)
    }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        configuration.label
            .font(.quicksand(size: 17, weight: .semibold))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // 3D Base shadow layer (bottom)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "8B2040"))
                            .offset(y: isPressed ? 1 : 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                colorScheme == .dark ?
                                    Color.black.opacity(0.4) :
                                    ConversionOnboardingTheme.accentPrimary.opacity(0.15)
                            )
                            .offset(y: isPressed ? 1 : 3)
                    }

                    // Main button surface
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: ConversionOnboardingTheme.buttonGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.cardBackground(for: colorScheme),
                                    ConversionOnboardingTheme.cardBackground(for: colorScheme).opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: isPressed ? 2 : 0)

                    // Top highlight for 3D effect
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .offset(y: isPressed ? 2 : 0)
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ?
                            Color.white.opacity(0.2) :
                            ConversionOnboardingTheme.glassStroke(for: colorScheme),
                            lineWidth: 1
                        )
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(
                color: isSelected ?
                    ConversionOnboardingTheme.accentPrimary.opacity(isPressed ? 0.2 : 0.4) :
                    Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: isPressed ? 4 : 12,
                x: 0,
                y: isPressed ? 2 : 6
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Keep SimpleButtonStyle as alias for compatibility
typealias SimpleButtonStyle = WellnessButtonStyle

// Supporting data structure
struct AnxietyUserData {
    var primaryGoals: [String] = []
    var anxietyFrequency = ""
    var anxietyLocations: [String] = []
    var hearAboutUs = ""
    var anxietyShift = ""
    var difficultyAreas: [String] = []
    var blocksLife = ""
    var copingMethods: [String] = []
    var previousSolutions = ""
    var impactLevel = ""
    var name = ""
    var ageRange = ""
}

struct GoalOption: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.quicksand(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : ConversionOnboardingTheme.accentPrimary.opacity(0.9))
                    .frame(width: 32)

                Text(title)
                    .font(.quicksand(size: 17, weight: .medium))
                    .foregroundColor(
                        isSelected ?
                        Color.white :
                        ConversionOnboardingTheme.primaryText(for: colorScheme).opacity(0.9)
                    )

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // 3D Base shadow layer
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "8B2040"))
                            .offset(y: isPressed ? 1 : 3)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                            .offset(y: isPressed ? 1 : 2)
                    }

                    // Main button surface
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: ConversionOnboardingTheme.buttonGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    ConversionOnboardingTheme.cardBackground(for: colorScheme),
                                    ConversionOnboardingTheme.cardBackground(for: colorScheme).opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: isPressed ? 2 : 0)

                    // Top highlight for 3D effect
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .offset(y: isPressed ? 2 : 0)
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ?
                            Color.white.opacity(0.2) :
                            ConversionOnboardingTheme.glassStroke(for: colorScheme),
                            lineWidth: 1
                        )
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(
                color: isSelected ?
                    ConversionOnboardingTheme.accentPrimary.opacity(isPressed ? 0.15 : 0.3) :
                    Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05),
                radius: isPressed ? 3 : 8,
                x: 0,
                y: isPressed ? 1 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
}

struct CompletionFeature: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.quicksand(size: 18, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            
            Text(text)
                .font(.quicksand(size: 12, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.mutedText(for: colorScheme))
        }
    }
}

struct CompactAnalysisStepCard: View {
    let step: String
    let isCompleted: Bool
    let isActive: Bool
    let index: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(
                        isCompleted ? 
                        ConversionOnboardingTheme.accentSecondary.opacity(0.8) : 
                        isActive ? 
                        ConversionOnboardingTheme.accentPrimary : 
                        Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                    )
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.quicksand(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if isActive {
                    ZStack {
                        // Outer glow effect
                        Circle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 12, height: 12)
                            .scaleEffect(1.5)
                        
                        // Inner solid dot
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    }
                    .opacity(0.9)
                } else {
                    Text("\(index + 1)")
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? Color(hex: "B0B0B0") : Color(hex: "5A5A5A"))
                }
            }
            
            // Step text
            Text(step)
                .font(.quicksand(size: 12, weight: isActive ? .semibold : .regular))
                .foregroundColor(
                    isCompleted ? ConversionOnboardingTheme.secondaryText(for: colorScheme).opacity(0.8) :
                    isActive ? ConversionOnboardingTheme.accentPrimary :
                    ConversionOnboardingTheme.mutedText(for: colorScheme).opacity(0.8)
                )
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isCompleted ? 
                    ConversionOnboardingTheme.accentSecondary.opacity(0.12) :
                    isActive ?
                    ConversionOnboardingTheme.accentPrimary.opacity(0.12) :
                    ConversionOnboardingTheme.cardBackground(for: colorScheme).opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCompleted ? 
                            ConversionOnboardingTheme.accentSecondary.opacity(0.4) :
                            isActive ?
                            ConversionOnboardingTheme.accentPrimary.opacity(0.4) :
                            ConversionOnboardingTheme.glassStroke(for: colorScheme),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(isActive ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCompleted)
    }
}

private struct PlanThemeConfiguration {
    let headline: String
    let timeCommitment: String
    let milestones: [(icon: String, title: String, detail: String)]
}

struct PlanFocusChip: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ConversionOnboardingTheme.accentPrimary)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.quicksand(size: 13, weight: .medium))
                .foregroundColor(
                    colorScheme == .dark ?
                        Color.white.opacity(0.85) :
                        Color(hex: "1A1A1A")
                )
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(
                    colorScheme == .dark ?
                        Color.white.opacity(0.06) :
                        Color.black.opacity(0.04)
                )
        )
    }
}

struct PlanTimelineRow: View {
    let icon: String
    let title: String
    let detail: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark ?
                            Color.white.opacity(0.06) :
                            ConversionOnboardingTheme.accentPrimary.opacity(0.08)
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                Text(detail)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

struct ValueComparisonItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let pain: String
    let relief: String
}

struct ValueTimelineMilestone: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

struct ValueTestimonial {
    let author: String
    let quote: String
}

struct ValueMetric: Identifiable {
    let id = UUID()
    let value: String
    let caption: String
}

struct ValueComparisonCard: View {
    let item: ValueComparisonItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.quicksand(size: 15, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Without Zenya")
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme).opacity(0.7))
                    Text(item.pain)
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("With Zenya")
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary.opacity(0.8))
                    Text(item.relief)
                        .font(.quicksand(size: 13, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ValueTimelineRow: View {
    let milestone: ValueTimelineMilestone
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: milestone.icon)
                    .font(.quicksand(size: 18, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.quicksand(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(milestone.detail)
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ValueTestimonialCard: View {
    let testimonial: ValueTestimonial
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.quicksand(size: 26, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.accentSecondary)

            Text(testimonial.quote)
                .font(.quicksand(size: 15, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(testimonial.author)
                .font(.quicksand(size: 13, weight: .semibold))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    colorScheme == .dark ?
                        Color.white.opacity(0.04) :
                        Color.white.opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(ConversionOnboardingTheme.accentSecondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ValueMetricChip: View {
    let metric: ValueMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric.value)
                .font(.quicksand(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(metric.caption)
                .font(.quicksand(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }
}

struct PremiumCompletionFeature: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark ?
                            color.opacity(0.12) :
                            color.opacity(0.08)
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(
                        colorScheme == .dark ?
                            Color.white :
                            Color(hex: "1A1A1A")
                    )
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.quicksand(size: 11, weight: .medium))
                    .foregroundColor(
                        colorScheme == .dark ?
                            Color.white.opacity(0.5) :
                            Color(hex: "6A6A6A")
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    colorScheme == .dark ?
                        Color.white.opacity(0.04) :
                        Color.black.opacity(0.02)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            colorScheme == .dark ?
                                Color.white.opacity(0.06) :
                                Color.black.opacity(0.04),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Compact Components for One-Screen Steps

struct CompactComparisonRow: View {
    let item: ValueComparisonItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                HStack(spacing: 8) {
                    Text("Before:")
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme).opacity(0.7))
                    Text(item.pain)
                        .font(.quicksand(size: 11, weight: .medium))
                        .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                }

                HStack(spacing: 8) {
                    Text("After:")
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.accentPrimary.opacity(0.8))
                    Text(item.relief)
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                }
            }
        }
    }
}

struct CompactTimelineRow: View {
    let milestone: ValueTimelineMilestone
    let isLast: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: milestone.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ConversionOnboardingTheme.accentPrimary)
                    )

                if !isLast {
                    Rectangle()
                        .fill(ConversionOnboardingTheme.accentPrimary.opacity(0.2))
                        .frame(width: 2, height: 24)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
                Text(milestone.detail)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }
            .padding(.bottom, isLast ? 0 : 8)

            Spacer()
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.quicksand(size: 16, weight: .bold))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            Text(label)
                .font(.quicksand(size: 10, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        )
    }
}

struct PlanBenefitPill: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.accentPrimary)

            Text(text)
                .font(.quicksand(size: 9, weight: .medium))
                .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
        )
    }
}

struct RitualCard: View {
    let icon: String
    let time: String
    let title: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 35
                        )
                    )
                    .frame(width: 62, height: 62)
                    .blur(radius: 4)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.5),
                                        color.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(spacing: 3) {
                Text(time)
                    .font(.quicksand(size: 11, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(title)
                    .font(.quicksand(size: 17, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ] : [
                                Color.white,
                                color.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.35),
                                color.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ProofStatCard: View {
    let value: String
    let label: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Animated glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary.opacity(0.25),
                                ConversionOnboardingTheme.accentPrimary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 28
                        )
                    )
                    .frame(width: 48, height: 48)
                    .blur(radius: 3)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary.opacity(0.18),
                                ConversionOnboardingTheme.accentPrimary.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(ConversionOnboardingTheme.accentPrimary.opacity(0.3), lineWidth: 1.5)
                    )

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.accentPrimary)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.quicksand(size: 28, weight: .heavy))
                    .foregroundColor(ConversionOnboardingTheme.primaryText(for: colorScheme))

                Text(label)
                    .font(.quicksand(size: 10, weight: .bold))
                    .foregroundColor(ConversionOnboardingTheme.secondaryText(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.03)
                            ] : [
                                Color.white,
                                ConversionOnboardingTheme.accentPrimary.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ConversionOnboardingTheme.accentPrimary.opacity(0.25),
                                ConversionOnboardingTheme.accentPrimary.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: ConversionOnboardingTheme.accentPrimary.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ConversionOnboardingView(isPresented: .constant(true))
}
