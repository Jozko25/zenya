//
//  AchievementCelebrationView.swift
//  anxiety
//
//  Achievement celebration popup with confetti animations
//

import SwiftUI

struct AchievementCelebrationView: View {
    let achievement: JournalAchievement
    let onDismiss: () -> Void
    
    @State private var showContent = false

    @State private var bounce = false
    @State private var sparkleOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            // Background overlay with blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Main achievement card
            achievementCard
                .scaleEffect(showContent ? (bounce ? 1.1 : 1.0) : 0.1)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
                .animation(.easeInOut(duration: 0.2), value: bounce)
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private var achievementCard: some View {
        VStack(spacing: 24) {
            // Achievement icon with enhanced glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FF5C7A").opacity(0.4),
                                Color(hex: "FF5C7A").opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 20)

                // Main circle
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

                Image(systemName: achievement.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)

                // Sparkle effects around the icon
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))
                        .offset(sparklePosition(for: index))
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: showContent
                        )
                }
            }
            .padding(.top, 8)
            
            // Achievement details
            VStack(spacing: 12) {
                Text("🎉 Achievement Unlocked!")
                    .font(.quicksand(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "FF5C7A"))
                    .kerning(0.5)

                Text(achievement.title)
                    .font(.quicksand(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(achievement.description)
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)

                // Points reward
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "FFD700"))

                    Text("+\(achievement.points) points")
                        .font(.quicksand(size: 19, weight: .bold))
                        .foregroundColor(Color(hex: "FFD700"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFD700").opacity(0.15),
                                    Color(hex: "FFD700").opacity(0.08)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.top, 4)
            }
            
            // Dismiss button
            Button(action: {
                dismissWithAnimation()
            }) {
                Text("Continue")
                    .font(.quicksand(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF5C7A"),
                                        Color(hex: "FF8FA3")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                    .shadow(color: Color(hex: "FF5C7A").opacity(0.5), radius: 15, x: 0, y: 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: "1A1A1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF5C7A").opacity(0.3),
                                    Color(hex: "FF8FA3").opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color(hex: "FF5C7A").opacity(0.3), radius: 30, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.5), radius: 40, x: 0, y: 20)
        )
        .padding(.horizontal, 32)
    }
    
    private func sparklePosition(for index: Int) -> CGSize {
        let angle = Double(index) * 45.0 * .pi / 180.0
        let radius: CGFloat = 65 + (showContent ? 10 : 0)
        return CGSize(
            width: Foundation.cos(angle) * radius,
            height: Foundation.sin(angle) * radius
        )
    }
    
    private func startCelebration() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            showContent = true
        }
        
        // Start confetti removed
        
        // Bounce effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.1)) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    bounce = false
                }
            }
        }
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            dismissWithAnimation()
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}



// MARK: - Achievement Celebration Manager

@MainActor
class AchievementCelebrationManager: ObservableObject {
    @Published var currentAchievement: JournalAchievement?
    @Published var showCelebration = false
    
    init() {
        // Listen for achievement notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAchievementUnlocked),
            name: NSNotification.Name("AchievementUnlocked"),
            object: nil
        )
    }
    
    @objc private func handleAchievementUnlocked(_ notification: Notification) {
        guard let achievement = notification.object as? JournalAchievement else { return }
        
        Task { @MainActor in
            celebrate(achievement)
        }
    }
    
    func celebrate(_ achievement: JournalAchievement) {
        currentAchievement = achievement
        showCelebration = true
    }
    
    func dismissCelebration() {
        showCelebration = false
        currentAchievement = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    AchievementCelebrationView(
        achievement: JournalAchievement.achievements.first!,
        onDismiss: {}
    )
}