//
//  PurchaseSuccessView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct PurchaseSuccessView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAnimation = false
    @State private var showingConfetti = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Success gradient background
                LinearGradient(
                    colors: [
                        AdaptiveColors.Action.progress.opacity(0.08),
                        AdaptiveColors.Action.breathing.opacity(0.05),
                        AdaptiveColors.Background.primary
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        successAnimationSection
                        
                        successMessageSection
                        
                        nextStepsSection
                        
                        quickActionsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                }
                
                // Confetti animation overlay
                if showingConfetti {
                    PurchaseConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AdaptiveColors.Text.primary)
                    .font(.quicksand(size: 16, weight: .semibold))
                }
            }
        }
        .onAppear {
            startSuccessAnimation()
        }
    }
    
    private var successAnimationSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Pulsing background circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            AdaptiveColors.Action.progress.opacity(0.2 - Double(index) * 0.05),
                            lineWidth: 2
                        )
                        .frame(
                            width: 120 + CGFloat(index * 30),
                            height: 120 + CGFloat(index * 30)
                        )
                        .scaleEffect(showingAnimation ? 1.0 : 0.5)
                        .opacity(showingAnimation ? 0.3 : 0.0)
                        .animation(
                            .easeOut(duration: 1.0)
                                .delay(Double(index) * 0.2),
                            value: showingAnimation
                        )
                }
                
                // Main success circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Action.progress,
                                AdaptiveColors.Action.progress.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(showingAnimation ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showingAnimation)
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.quicksand(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showingAnimation ? 1.0 : 0.3)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.7)
                            .delay(0.3),
                        value: showingAnimation
                    )
            }
            
            Text("🎉")
                .font(.quicksand(size: 32))
                .scaleEffect(showingAnimation ? 1.0 : 0.3)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.7)
                        .delay(0.6),
                    value: showingAnimation
                )
        }
    }
    
    private var successMessageSection: some View {
        VStack(spacing: 16) {
            Text("Welcome to Premium!")
                .font(.quicksand(size: 28, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)
                .multilineTextAlignment(.center)
                .opacity(showingAnimation ? 1.0 : 0.0)
                .animation(
                    .easeOut(duration: 0.8)
                        .delay(0.9),
                    value: showingAnimation
                )
            
            Text("Your 7-day free trial has started. You now have unlimited access to all premium features to support your mental wellness journey.")
                .font(.quicksand(size: 16, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .opacity(showingAnimation ? 1.0 : 0.0)
                .animation(
                    .easeOut(duration: 0.8)
                        .delay(1.1),
                    value: showingAnimation
                )
        }
    }
    
    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What's Next?")
                .font(.quicksand(size: 20, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
                .opacity(showingAnimation ? 1.0 : 0.0)
                .animation(
                    .easeOut(duration: 0.6)
                        .delay(1.3),
                    value: showingAnimation
                )
            
            VStack(spacing: 12) {
                NextStepCard(
                    icon: "brain.head.profile",
                    title: "Complete Your Wellness Profile",
                    subtitle: "Get personalized recommendations",
                    color: AdaptiveColors.Action.breathing,
                    delay: 1.5
                )
                
                NextStepCard(
                    icon: "leaf.fill",
                    title: "Try Your First Premium Meditation",
                    subtitle: "Access exclusive guided sessions",
                    color: AdaptiveColors.Action.mood,
                    delay: 1.7
                )
                
                NextStepCard(
                    icon: "chart.xyaxis.line",
                    title: "Enable Progress Tracking",
                    subtitle: "Visualize your wellness journey",
                    color: AdaptiveColors.Action.progress,
                    delay: 1.9
                )
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            // Primary action
            Button(action: {
                // Start first meditation
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.quicksand(size: 18, weight: .medium))
                    
                    Text("Start Your First Premium Session")
                        .font(.quicksand(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            AdaptiveColors.Action.breathing,
                            AdaptiveColors.Action.coaching
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(showingAnimation ? 1.0 : 0.0)
            .animation(
                .easeOut(duration: 0.6)
                    .delay(2.1),
                value: showingAnimation
            )
            
            // Secondary action
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Continue Exploring")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            .opacity(showingAnimation ? 1.0 : 0.0)
            .animation(
                .easeOut(duration: 0.6)
                    .delay(2.3),
                value: showingAnimation
            )
        }
    }
    
    private func startSuccessAnimation() {
        // Initial success animation
        withAnimation {
            showingAnimation = true
        }
        
        // Trigger confetti after main animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingConfetti = true
            
            // Haptic success feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
        
        // Remove confetti after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showingConfetti = false
        }
    }
}

// MARK: - Supporting Components

struct NextStepCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        TherapeuticCard(elevation: .elevated) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.quicksand(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.quicksand(size: 16, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                    
                    Text(subtitle)
                        .font(.quicksand(size: 14, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }
            .padding(16)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(x: isVisible ? 0 : 50)
        .animation(
            .easeOut(duration: 0.6)
                .delay(delay),
            value: isVisible
        )
        .onAppear {
            isVisible = true
        }
    }
}

struct PurchaseConfettiView: View {
    @State private var confettiElements: [ConfettiElement] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiElements, id: \.id) { element in
                    Rectangle()
                        .fill(element.color)
                        .frame(width: element.size, height: element.size)
                        .rotationEffect(element.rotation)
                        .position(element.position)
                        .animation(
                            .easeOut(duration: element.duration)
                                .delay(element.delay),
                            value: element.position
                        )
                }
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [
            AdaptiveColors.Action.progress,
            AdaptiveColors.Action.breathing,
            AdaptiveColors.Action.coaching,
            AdaptiveColors.Action.mood
        ]
        
        confettiElements = (0..<50).map { index in
            ConfettiElement(
                id: index,
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -50
                ),
                color: colors.randomElement() ?? colors[0],
                size: CGFloat.random(in: 4...8),
                rotation: Angle.degrees(Double.random(in: 0...360)),
                duration: Double.random(in: 1.5...2.5),
                delay: Double.random(in: 0...0.5)
            )
        }
        
        // Animate confetti falling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for index in confettiElements.indices {
                confettiElements[index].position = CGPoint(
                    x: confettiElements[index].position.x + CGFloat.random(in: -50...50),
                    y: UIScreen.main.bounds.height + 100
                )
            }
        }
    }
}

struct ConfettiElement {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    let rotation: Angle
    let duration: Double
    let delay: Double
}

#Preview {
    PurchaseSuccessView()
}