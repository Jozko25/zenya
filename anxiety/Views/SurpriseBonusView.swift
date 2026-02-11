//
//  SurpriseBonusView.swift
//  anxiety
//
//  Surprise bonus point celebration view
//

import SwiftUI

struct SurpriseBonusView: View {
    let bonusPoints: Int
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var starScale: CGFloat = 0.1
    @State private var coinRotation: Double = 0
    @State private var glitterOpacity: Double = 0
    @State private var bounce = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var bonusMessage: String {
        switch bonusPoints {
        case 10...24:
            return "A gentle reward ✨"
        case 25...49:
            return "Wonderful progress! 🌸"
        case 50...99:
            return "Amazing dedication! 🌟"
        case 100...199:
            return "Outstanding achievement! 🌺"
        default:
            return "Exceptional mindfulness! 🦋"
        }
    }
    
    private var bonusColor: Color {
        switch bonusPoints {
        case 10...24:
            return OnboardingColors.wellnessGreen
        case 25...49:
            return OnboardingColors.wellnessLavender
        case 50...99:
            return OnboardingColors.wellnessBlue
        case 100...199:
            return OnboardingColors.softPurple
        default:
            return AdaptiveColors.Action.breathing
        }
    }
    
    var body: some View {
        ZStack {
            // Gentle background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Soft celebration particles (only for higher bonuses)
            if showContent && bonusPoints >= 50 {
                GentleCelebrationView()
                    .opacity(glitterOpacity)
                    .allowsHitTesting(false)
            }
            
            // Main bonus card
            bonusCard
                .scaleEffect(showContent ? (bounce ? 1.05 : 1.0) : 0.1)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                .animation(.easeInOut(duration: 0.15), value: bounce)
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private var bonusCard: some View {
        VStack(spacing: 20) {
            // Gentle celebration icon
            ZStack {
                // Soft background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                bonusColor.opacity(0.3),
                                bonusColor.opacity(0.15),
                                bonusColor.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(starScale * 1.2)

                // Therapeutic icon based on bonus level
                Image(systemName: getTherapeuticIcon())
                    .font(.quicksand(size: 36, weight: .semibold))
                    .foregroundColor(bonusColor)
                    .scaleEffect(starScale)
                    .shadow(color: bonusColor.opacity(0.3), radius: 8)

                // Gentle floating elements
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: getFloatingIcon(for: index))
                        .font(.quicksand(size: 8))
                        .foregroundColor(bonusColor.opacity(0.6))
                        .offset(gentleFloatingPosition(for: index))
                        .rotationEffect(.degrees(coinRotation * 0.5)) // Slower, gentler rotation
                        .opacity(glitterOpacity * 0.8)
                }
            }
            
            // Gentle bonus text
            VStack(spacing: 12) {
                Text("Mindful Bonus")
                    .font(.quicksand(size: 22, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)

                Text(bonusMessage)
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .multilineTextAlignment(.center)

                // Calm points display
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.quicksand(size: 18, weight: .medium))
                            .foregroundColor(bonusColor)

                        Text("\(bonusPoints)")
                            .font(.quicksand(size: 24, weight: .semibold))
                            .foregroundColor(bonusColor)

                        Text("points")
                            .font(.quicksand(size: 16, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }

                    Text("added to your journey")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.tertiary)
                }
                .padding(.vertical, 8)
            }
            
            // Fun fact or encouragement
            Text(getEncouragementText())
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            
            // Gentle dismiss button
            Button("Continue") {
                dismissWithAnimation()
            }
            .font(.quicksand(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [bonusColor, bonusColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: bonusColor.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AdaptiveColors.Surface.card)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    bonusColor.opacity(0.05),
                                    bonusColor.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(bonusColor.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 32)
    }
    
    private func getTherapeuticIcon() -> String {
        switch bonusPoints {
        case 10...24:
            return "leaf.fill"
        case 25...49:
            return "heart.fill"
        case 50...99:
            return "sun.max.fill"
        case 100...199:
            return "sparkles"
        default:
            return "lotus"
        }
    }

    private func getFloatingIcon(for index: Int) -> String {
        let icons = ["sparkle", "circle.fill", "heart.fill", "leaf.fill", "sun.max.fill"]
        return icons[index % icons.count]
    }

    private func gentleFloatingPosition(for index: Int) -> CGSize {
        let angle = Double(index) * 72.0 * .pi / 180.0 + (coinRotation * 0.3 * .pi / 180.0)
        let radius: CGFloat = 35
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }
    
    private func getEncouragementText() -> String {
        let messages = [
            "Your mindful practice continues to grow ✨",
            "Each moment of reflection brings clarity",
            "Progress blooms from consistent care",
            "Your journey deserves this gentle recognition",
            "Mindfulness creates space for joy"
        ]
        return messages.randomElement() ?? messages[0]
    }
    
    private func startCelebration() {
        // Gentle haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            showContent = true
        }

        // Gentle delayed animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.9)) {
                starScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Gentle, slow rotation
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                coinRotation = 360
            }
            // Soft particle animation only for higher bonuses
            if bonusPoints >= 50 {
                withAnimation(.easeInOut(duration: 1.2)) {
                    glitterOpacity = 0.6
                }
            }

            // Subtle breathing effect for larger bonuses
            if bonusPoints >= 100 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }

        // Gentle bounce effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.15)) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    bounce = false
                }
            }
        }

        // Auto-dismiss after 4 seconds (longer for reading)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            dismissWithAnimation()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
            glitterOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Gentle Celebration Animation View

struct GentleCelebrationView: View {
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                GentleCelebrationPiece(index: index)
            }
        }
    }
}

struct GentleCelebrationPiece: View {
    let index: Int
    @State private var location = CGPoint(x: 0, y: -50)
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    private let therapeuticColors = [
        OnboardingColors.wellnessLavender,
        OnboardingColors.softTeal,
        OnboardingColors.softPink,
        OnboardingColors.wellnessGreen.opacity(0.8),
        OnboardingColors.wellnessBlue.opacity(0.8)
    ]

    private let mindfulIcons = ["sparkle", "heart.fill", "leaf.fill", "circle.fill", "sun.max.fill"]

    var body: some View {
        Image(systemName: mindfulIcons[index % mindfulIcons.count])
            .font(.system(size: 6))
            .foregroundColor(therapeuticColors[index % therapeuticColors.count])
            .opacity(opacity)
            .scaleEffect(scale)
            .position(location)
            .onAppear {
                startGentleAnimation()
            }
    }

    private func startGentleAnimation() {
        let startX = Double.random(in: 80...UIScreen.main.bounds.width - 80)
        let endX = startX + Double.random(in: -30...30)
        let endY = UIScreen.main.bounds.height * 0.8

        location = CGPoint(x: startX, y: -10)

        let delay = Double.random(in: 0...1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                .easeOut(duration: Double.random(in: 3.0...5.0))
            ) {
                location = CGPoint(x: endX, y: endY)
                opacity = 0
                scale = Double.random(in: 0.8...1.2)
            }
        }
    }
}

// MARK: - Surprise Bonus Manager

@MainActor
class SurpriseBonusManager: ObservableObject {
    @Published var currentBonusPoints: Int?
    @Published var showBonus = false
    
    func triggerBonus(points: Int) {
        currentBonusPoints = points
        showBonus = true
    }
    
    func dismissBonus() {
        showBonus = false
        currentBonusPoints = nil
    }
}


#Preview {
    SurpriseBonusView(bonusPoints: 200, onDismiss: {})
}