//
//  LevelUpCelebrationView.swift
//  anxiety
//
//  Level up celebration with unified card style
//

import SwiftUI

struct LevelUpCelebrationView: View {
    let levelUpInfo: LevelUpInfo
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var badgeScale: CGFloat = 0.5
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            // Background overlay with blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Main Level Up card
            levelUpCard
                .scaleEffect(showContent ? (bounce ? 1.05 : 1.0) : 0.1)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showContent)
                .animation(.easeInOut(duration: 0.2), value: bounce)
        }
        .onAppear {
            startCelebration()
        }
    }
    
    private var levelUpCard: some View {
        VStack(spacing: 24) {
            
            // Level Badge (Centered)
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                levelUpInfo.newLevel.color.opacity(0.6),
                                levelUpInfo.newLevel.color.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 15)
                
                // Main badge circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                levelUpInfo.newLevel.color,
                                levelUpInfo.newLevel.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: levelUpInfo.newLevel.color.opacity(0.5), radius: 20, x: 0, y: 10)
                    .scaleEffect(badgeScale)
                
                // Badge emoji/content
                VStack(spacing: 4) {
                    Text(levelUpInfo.newLevel.badge)
                        .font(.quicksand(size: 36))
                    
                    Text("LV \(levelUpInfo.newLevel.level)")
                        .font(.quicksand(size: 14, weight: .black))
                        .foregroundColor(.white)
                }
                .scaleEffect(badgeScale)
                
                // Rotating crown for higher levels
                if levelUpInfo.newLevel.level >= 5 {
                    Image(systemName: "crown.fill")
                        .font(.quicksand(size: 24))
                        .foregroundColor(Color(hex: "FFD700"))
                        .offset(y: -70)
                        .rotationEffect(.degrees(showContent ? 360 : 0))
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: showContent)
                }
            }
            .padding(.top, 10)
            
            // Level Info
            VStack(spacing: 12) {
                Text("LEVEL UP!")
                    .font(.quicksand(size: 14, weight: .black))
                    .foregroundColor(levelUpInfo.newLevel.color)
                    .tracking(1.0)
                
                Text(levelUpInfo.newLevel.title)
                    .font(.quicksand(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(levelUpInfo.newLevel.description)
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(4)
                
                // Rewards Unlocked
                if !levelUpInfo.newLevel.rewards.isEmpty {
                    VStack(spacing: 8) {
                        Text("New Rewards Unlocked")
                            .font(.quicksand(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "FFD700"))
                            .padding(.bottom, 2)
                        
                        ForEach(levelUpInfo.newLevel.rewards, id: \.self) { reward in
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.quicksand(size: 10))
                                    .foregroundColor(Color(hex: "FFD700"))
                                
                                Text(reward)
                                    .font(.quicksand(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.top, 8)
                }
            }
            
            // Continue Button
            Button(action: {
                dismissWithAnimation()
            }) {
                Text("Continue Your Journey")
                    .font(.quicksand(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        levelUpInfo.newLevel.color,
                                        levelUpInfo.newLevel.color.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: levelUpInfo.newLevel.color.opacity(0.5), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
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
                                    levelUpInfo.newLevel.color.opacity(0.5),
                                    levelUpInfo.newLevel.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: levelUpInfo.newLevel.color.opacity(0.3), radius: 30, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.5), radius: 40, x: 0, y: 20)
        )
        .padding(.horizontal, 32)
    }
    
    private func startCelebration() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Sequence of animations
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            showContent = true
            badgeScale = 1.0
        }
        
        // Bounce effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.15)) {
                bounce = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    bounce = false
                }
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.25)) {
            showContent = false
            badgeScale = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

// MARK: - Level Up Manager remains unchanged
// MARK: - Level Up Manager

@MainActor
class LevelUpCelebrationManager: ObservableObject {
    @Published var currentLevelUpInfo: LevelUpInfo?
    @Published var showCelebration = false
    
    func celebrateLevelUp(_ levelUpInfo: LevelUpInfo) {
        currentLevelUpInfo = levelUpInfo
        showCelebration = true
    }
    
    func dismissCelebration() {
        showCelebration = false
        currentLevelUpInfo = nil
    }
}
