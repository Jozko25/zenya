//
//  EmergencyBreathingView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

// MARK: - Theme Palette
private enum BreathingPalette {
    static let accent = Color(hex: "FF6B6B")
    static let accentSecondary = Color(hex: "FF8E8E")

    static let inhaleColor = Color(hex: "7DD3FC") // Soft sky blue
    static let holdColor = Color(hex: "A78BFA")   // Soft purple
    static let exhaleColor = Color(hex: "FDA4AF") // Soft rose
    static let pauseColor = Color(hex: "6EE7B7")  // Soft mint

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color(hex: "F7F8FB")
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white
    }

    static func cardBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(hex: "1B1D24")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color(hex: "4F5560")
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color(hex: "9AA0AE")
    }

    static func ringTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    static func glassTop(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white
    }

    static func glassBottom(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color(hex: "EDF1F7")
    }

    static func inactiveDot(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
    }
}

// Confetti element for celebration animation
struct BreathingConfettiElement: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var color: Color
    var size: CGFloat
    var rotation: Double
    var rotationSpeed: Double
    var shape: ConfettiShape

    enum ConfettiShape: CaseIterable {
        case circle, square, triangle, heart
    }

    static func create(in bounds: CGRect) -> BreathingConfettiElement {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.78, blue: 0.35),   // iOS green
            Color(red: 0.0, green: 0.48, blue: 1.0),    // iOS blue
            Color(red: 1.0, green: 0.23, blue: 0.19),   // iOS red
            Color(red: 1.0, green: 0.58, blue: 0.0),    // iOS orange
            Color(red: 0.35, green: 0.34, blue: 0.84),  // iOS indigo
            Color(red: 0.75, green: 0.35, blue: 0.95),  // iOS purple
        ]

        return BreathingConfettiElement(
            position: CGPoint(x: Double.random(in: 0...bounds.width), y: -30),
            velocity: CGPoint(
                x: Double.random(in: -80...80),
                y: Double.random(in: 150...300)
            ),
            color: colors.randomElement() ?? Color(red: 0.2, green: 0.78, blue: 0.35),
            size: Double.random(in: 6...12),
            rotation: 0,
            rotationSpeed: Double.random(in: -360...360),
            shape: ConfettiShape.allCases.randomElement() ?? .circle
        )
    }
}

// Custom button style to prevent modal movement
struct StableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.none, value: configuration.isPressed)
    }
}

struct EmergencyBreathingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var breathingCount = 0
    @State private var isActive = false
    @State private var circleScale: CGFloat = 1.0
    @State private var breathingTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var currentCountdown: Double = 0
    @State private var totalProgress: Double = 0 // Continuous progress across all phases
    @State private var showingSOSSupport = false
    @State private var showingCompletion = false
    @State private var confettiElements: [BreathingConfettiElement] = []
    
    let totalCycles = 4 // 4-7-8 technique: 4 cycles
    
    enum BreathingPhase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        case pause = "Pause"
        
        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .hold: return 7.0
            case .exhale: return 8.0
            case .pause: return 1.0
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe in slowly through your nose"
            case .hold: return "Hold your breath gently"
            case .exhale: return "Exhale slowly through your mouth"
            case .pause: return "Rest for a moment"
            }
        }
        
        var color: Color {
            switch self {
            case .inhale: return BreathingPalette.inhaleColor
            case .hold: return BreathingPalette.holdColor
            case .exhale: return BreathingPalette.exhaleColor
            case .pause: return BreathingPalette.pauseColor
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                BreathingPalette.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    headerSection
                        .padding(.top, 8)

                    breathingVisualization

                    controlsSection
                        .frame(height: 120) // Fixed height to prevent layout changes

                    progressSection

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.top, 15)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        stopBreathing()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(BreathingPalette.primaryText(for: colorScheme))
                }
            }
            .overlay(
                // Just confetti animation - no modal
                Group {
                    if showingCompletion {
                        // Confetti animation with different shapes
                        ForEach(confettiElements) { element in
                            Group {
                                switch element.shape {
                                case .circle:
                                    Circle()
                                        .fill(element.color)
                                case .square:
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(element.color)
                                case .triangle:
                                    Triangle()
                                        .fill(element.color)
                                case .heart:
                                    HeartShape()
                                        .fill(element.color)
                                }
                            }
                            .frame(width: element.size, height: element.size)
                            .rotationEffect(.degrees(element.rotation))
                            .position(element.position)
                            .opacity(0.9)
                        }
                    }
                }
                .allowsHitTesting(false) // Allow touches to pass through confetti
            )
        }
        .sheet(isPresented: $showingSOSSupport) {
            SOSSupportView()
        }
        .onDisappear {
            stopBreathing()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Emergency Calm")
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(BreathingPalette.primaryText(for: colorScheme))
                .tracking(-0.5)

            Text("4-7-8 breathing for immediate relief")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(BreathingPalette.secondaryText(for: colorScheme))
        }
    }
    
    private var breathingVisualization: some View {
        VStack(spacing: 40) {
            ZStack {
                // Outer ambient glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                breathingPhase.color.opacity(0.15),
                                breathingPhase.color.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 80,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .scaleEffect(circleScale * 0.9)
                    .animation(.easeInOut(duration: breathingPhase.duration), value: circleScale)

                // Progress track
                Circle()
                    .stroke(BreathingPalette.ringTrack(for: colorScheme), lineWidth: 3)
                    .frame(width: 240, height: 240)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0.0, to: totalProgress)
                    .stroke(
                        LinearGradient(
                            colors: [breathingPhase.color, breathingPhase.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: totalProgress)

                // Main breathing circle
                ZStack {
                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    breathingPhase.color.opacity(0.25),
                                    breathingPhase.color.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: breathingPhase.duration), value: circleScale)

                    // Glass circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    BreathingPalette.glassTop(for: colorScheme),
                                    BreathingPalette.glassBottom(for: colorScheme)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            breathingPhase.color.opacity(0.5),
                                            breathingPhase.color.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: breathingPhase.duration), value: circleScale)

                    // Center content
                    VStack(spacing: 6) {
                        Text(breathingPhase.rawValue)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(breathingPhase.color)

                        Text(String(format: "%.0f", isActive ? max(0, ceil(currentCountdown)) : breathingPhase.duration))
                            .font(.system(size: 56, weight: .ultraLight, design: .rounded))
                            .foregroundColor(BreathingPalette.primaryText(for: colorScheme))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .scaleEffect(1.0 / max(circleScale, 0.85))
                    .animation(.easeOut(duration: 0.2), value: circleScale)
                }
            }
            .frame(width: 320, height: 320)

            // Instruction text
            VStack(spacing: 8) {
                Text(breathingPhase.instruction)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(BreathingPalette.primaryText(for: colorScheme))
                    .multilineTextAlignment(.center)

                if isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(breathingPhase.color)
                            .frame(width: 6, height: 6)
                            .opacity(circleScale > 1.2 ? 1 : 0.4)

                        Text("Follow the rhythm")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(BreathingPalette.secondaryText(for: colorScheme))

                        Circle()
                            .fill(breathingPhase.color)
                            .frame(width: 6, height: 6)
                            .opacity(circleScale > 1.2 ? 1 : 0.4)
                    }
                    .animation(.easeInOut(duration: 0.5), value: circleScale)
                    .transition(.opacity)
                }
            }
            .frame(minHeight: 60)
            .animation(.easeInOut(duration: 0.3), value: isActive)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 14) {
            // Primary action button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()

                if isActive {
                    stopBreathing()
                } else {
                    startBreathing()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text(isActive ? "Pause" : "Start Breathing")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(breathingPhase.color)
                        .shadow(
                            color: breathingPhase.color.opacity(0.35),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Emergency support button
            emergencyButton

            // Reset button (only when active)
            if isActive {
                Button(action: resetBreathing) {
                    Text("Reset")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(BreathingPalette.secondaryText(for: colorScheme))
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: isActive)
    }
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Cycle indicator with dots
            HStack(spacing: 8) {
                ForEach(0..<totalCycles, id: \.self) { index in
                    Circle()
                        .fill(index < breathingCount ? breathingPhase.color : BreathingPalette.inactiveDot(for: colorScheme))
                        .frame(width: 10, height: 10)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: breathingCount)
                }
            }

            // Cycle text
            Text("Cycle \(breathingCount) of \(totalCycles)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(BreathingPalette.secondaryText(for: colorScheme))
        }
        .padding(.top, 8)
    }
    
    private func startBreathing() {
        isActive = true
        breathingPhase = .inhale
        totalProgress = 0.0
        animateBreathingCycle()
    }
    
    private func stopBreathing() {
        isActive = false
        breathingTimer?.invalidate()
        breathingTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        withAnimation(.easeOut(duration: 0.5)) {
            circleScale = 1.0
        }
    }
    
    private func resetBreathing() {
        stopBreathing()
        breathingCount = 0
        breathingPhase = .inhale
        circleScale = 1.0
        totalProgress = 0.0
    }
    
    private func animateBreathingCycle() {
        guard isActive else { return }
        
        let phaseDuration = breathingPhase.duration
        
        // Start countdown for this phase
        currentCountdown = phaseDuration
        startCountdownTimer()
        
        // Animate circle based on phase with smooth linear animation
        withAnimation(.linear(duration: phaseDuration)) {
            switch breathingPhase {
            case .inhale:
                circleScale = 1.4  // Slightly larger for better visual effect
            case .hold:
                circleScale = 1.4  // Keep expanded during hold
            case .exhale:
                circleScale = 0.7  // Smaller contraction
            case .pause:
                circleScale = 1.0  // Return to normal
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
        
        // Schedule next phase
        breathingTimer?.invalidate()
        breathingTimer = Timer.scheduledTimer(withTimeInterval: phaseDuration, repeats: false) { _ in
            guard isActive else { return }
            
            // Stop countdown timer for this phase
            countdownTimer?.invalidate()
            countdownTimer = nil
            
            switch breathingPhase {
            case .inhale:
                breathingPhase = .hold
            case .hold:
                breathingPhase = .exhale
            case .exhale:
                breathingPhase = .pause
            case .pause:
                breathingPhase = .inhale
                breathingCount += 1

                // Reset progress for new cycle (smooth transition back to start)
                withAnimation(.easeInOut(duration: 0.3)) {
                    totalProgress = 0.0
                }

                // Check if completed
                if breathingCount >= totalCycles {
                    completeExercise()
                    return
                }
            }
            
            animateBreathingCycle()
        }
    }
    
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            guard isActive else { return }

            if currentCountdown > 0 {
                currentCountdown -= 0.02
                // Ensure we don't go below 0
                if currentCountdown < 0 {
                    currentCountdown = 0
                }

                // Calculate progress within current cycle (0.0 to 1.0 for each complete cycle)
                let phaseProgress = 1.0 - (currentCountdown / breathingPhase.duration)
                let totalCycleDuration = BreathingPhase.inhale.duration + BreathingPhase.hold.duration +
                                       BreathingPhase.exhale.duration + BreathingPhase.pause.duration

                // Current cycle progress (completes full circle each cycle)
                let cycleProgress = getCurrentPhaseOffset() + phaseProgress * (breathingPhase.duration / totalCycleDuration)
                totalProgress = min(cycleProgress, 1.0)
            }
        }
    }

    private func getCurrentPhaseOffset() -> Double {
        let totalCycleDuration = BreathingPhase.inhale.duration + BreathingPhase.hold.duration +
                               BreathingPhase.exhale.duration + BreathingPhase.pause.duration

        switch breathingPhase {
        case .inhale:
            return 0.0
        case .hold:
            return BreathingPhase.inhale.duration / totalCycleDuration
        case .exhale:
            return (BreathingPhase.inhale.duration + BreathingPhase.hold.duration) / totalCycleDuration
        case .pause:
            return (BreathingPhase.inhale.duration + BreathingPhase.hold.duration + BreathingPhase.exhale.duration) / totalCycleDuration
        }
    }

    private func completeExercise() {
        isActive = false
        breathingTimer?.invalidate()
        countdownTimer?.invalidate()
        triggerCelebration()

        // Haptic feedback for completion
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }

    private func triggerCelebration() {
        showingCompletion = true

        // Create confetti elements - fewer but more refined
        let bounds = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        confettiElements = (0..<30).map { _ in BreathingConfettiElement.create(in: bounds) }

        // Animate confetti
        animateConfetti()

        // Auto-hide celebration after 4 seconds (let confetti fully fall)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showingCompletion = false
        }
    }

    private func animateConfetti() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in // 60fps for smoother animation
            guard showingCompletion else {
                timer.invalidate()
                return
            }

            for i in confettiElements.indices {
                // Smoother position updates
                confettiElements[i].position.x += confettiElements[i].velocity.x * 0.016
                confettiElements[i].position.y += confettiElements[i].velocity.y * 0.016

                // Smoother rotation
                confettiElements[i].rotation += confettiElements[i].rotationSpeed * 0.016

                // Smoother physics
                confettiElements[i].velocity.y += 280 * 0.016 // slightly reduced gravity for more graceful fall
                confettiElements[i].velocity.x *= 0.995 // less air resistance for smoother horizontal movement

                // Add subtle horizontal sway
                confettiElements[i].velocity.x += sin(confettiElements[i].position.y * 0.01) * 5 * 0.016

                // Remove elements that fall off screen
                if confettiElements[i].position.y > UIScreen.main.bounds.height + 100 {
                    confettiElements.remove(at: i)
                    break
                }
            }
        }
    }
    
    private var emergencyButton: some View {
        Button(action: { showingSOSSupport = true }) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text("Emergency Support")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(hex: "FF4D6A"))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "FF4D6A").opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "FF4D6A").opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


// MARK: - Custom Confetti Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.addCurve(to: CGPoint(x: width * 0.1, y: height * 0.15),
                     control1: CGPoint(x: width * 0.5, y: height * 0.05),
                     control2: CGPoint(x: width * 0.25, y: height * 0.05))
        path.addCurve(to: CGPoint(x: width * 0.5, y: height * 0.9),
                     control1: CGPoint(x: width * 0.1, y: height * 0.35),
                     control2: CGPoint(x: width * 0.3, y: height * 0.6))
        path.addCurve(to: CGPoint(x: width * 0.9, y: height * 0.15),
                     control1: CGPoint(x: width * 0.7, y: height * 0.6),
                     control2: CGPoint(x: width * 0.9, y: height * 0.35))
        path.addCurve(to: CGPoint(x: width * 0.5, y: height * 0.25),
                     control1: CGPoint(x: width * 0.75, y: height * 0.05),
                     control2: CGPoint(x: width * 0.5, y: height * 0.05))
        return path
    }
}

#Preview {
    EmergencyBreathingView()
}
