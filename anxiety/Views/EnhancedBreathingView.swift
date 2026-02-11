//
//  EnhancedBreathingView.swift
//  anxiety
//
//  Enhanced Breathing Exercise Interface with Scientific Techniques
//

import SwiftUI
import AVFoundation

// MARK: - Breathing Pattern Helper
struct BreathingPattern {
    let inhale: Double
    let hold1: Double
    let exhale: Double
    let hold2: Double
    
    var totalDuration: Double {
        return inhale + hold1 + exhale + hold2
    }
}

// MARK: - Extension for existing BreathingTechnique
extension BreathingTechnique {
    var enhancedPattern: BreathingPattern {
        return BreathingPattern(
            inhale: Double(inhaleTime), 
            hold1: Double(holdTime), 
            exhale: Double(exhaleTime), 
            hold2: 0
        )
    }
}

// MARK: - Main Enhanced Breathing View
struct EnhancedBreathingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Session state
    @State private var selectedTechnique: BreathingTechnique = BreathingTechnique.techniques[0]
    @State private var isSessionActive = false
    @State private var isPaused = false
    @State private var currentPhase: BreathingPhase = .ready
    @State private var cycleCount = 0
    @State private var targetCycles = 7
    
    // Visual states
    @State private var circleScale: CGFloat = 0.4
    @State private var circleOpacity: Double = 0.8
    @State private var innerCircleRotation: Double = 0
    @State private var outerRingScale: CGFloat = 1.0
    @State private var particlesVisible = false
    
    // Timer
    @State private var timer: Timer?
    @State private var phaseTimer: Timer?
    @State private var elapsedTime: Double = 0
    @State private var phaseProgress: Double = 0
    
    // Settings
    @State private var hapticEnabled = true
    @State private var soundEnabled = false
    @State private var showingSettings = false
    @State private var showingTechniqueSelector = false
    
    // Anxiety tracking
    @State private var anxietyBefore: Int? = nil
    @State private var anxietyAfter: Int? = nil
    @State private var showingAnxietyCheck = true
    @State private var showingCompletionView = false
    
    enum BreathingPhase {
        case ready, inhale, hold1, exhale, hold2, completed
        
        var instruction: String {
            switch self {
            case .ready: return "Ready to begin"
            case .inhale: return "Breathe In"
            case .hold1: return "Hold"
            case .exhale: return "Breathe Out"
            case .hold2: return "Hold"
            case .completed: return "Well done!"
            }
        }
        
        var icon: String {
            switch self {
            case .ready: return "play.circle.fill"
            case .inhale: return "arrow.up.circle.fill"
            case .hold1, .hold2: return "pause.circle.fill"
            case .exhale: return "arrow.down.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Therapeutic background matching app design
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()
                
                if showingAnxietyCheck && !isSessionActive {
                    anxietyCheckView
                } else if showingCompletionView {
                    completionView
                } else {
                    mainBreathingInterface
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                }
            }
        }
        .onDisappear {
            stopSession()
        }
    }
    
    // MARK: - Anxiety Check View
    private var anxietyCheckView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF5C7A").opacity(0.15))
                            .frame(width: 100, height: 100)

                        Image(systemName: "wind")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(Color(hex: "FF5C7A"))
                    }

                    VStack(spacing: 10) {
                        Text("Ready to Breathe?")
                            .font(.instrumentSerif(size: 30))
                            .foregroundColor(AdaptiveColors.Text.primary)

                        Text("Take a moment to check in with yourself")
                            .font(.quicksand(size: 16, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                }
                .padding(.top, 20)

                // Anxiety Level Selector
                VStack(spacing: 16) {
                    Text("How anxious do you feel?")
                        .font(.quicksand(size: 17, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)

                    // Simple anxiety slider with numbers
                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { level in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    anxietyBefore = level
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
                                }
                            }) {
                                Text("\(level)")
                                    .font(.quicksand(size: 15, weight: anxietyBefore == level ? .bold : .medium))
                                    .foregroundColor(anxietyBefore == level ? .white : AdaptiveColors.Text.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(anxietyBefore == level ? Color(hex: "FF5C7A") : AdaptiveColors.Surface.cardElevated)
                                    )
                            }
                        }
                    }

                    HStack {
                        Text("Calm")
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                        Spacer()
                        Text("Very anxious")
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AdaptiveColors.Surface.card)
                )

                // Technique Selector
                Button(action: { showingTechniqueSelector.toggle() }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FF5C7A").opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "leaf.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "FF5C7A"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(selectedTechnique.name)
                                .font(.quicksand(size: 16, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)

                            Text(selectedTechnique.description)
                                .font(.quicksand(size: 13, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.Surface.card)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Spacer(minLength: 20)

                // Action Buttons - 3D style
                VStack(spacing: 14) {
                    Button(action: startSession) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Begin Session")
                                .font(.quicksand(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            ZStack {
                                // Shadow layer for 3D effect
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(anxietyBefore == nil ? Color.gray.opacity(0.3) : Color(hex: "C83555"))
                                    .offset(y: 3)

                                // Main gradient
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        anxietyBefore == nil ?
                                        LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(
                                            colors: [
                                                Color(hex: "FF7A95"),
                                                Color(hex: "FF5C7A"),
                                                Color(hex: "D94467")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                // Highlight
                                if anxietyBefore != nil {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            }
                        )
                        .shadow(color: anxietyBefore == nil ? Color.clear : Color(hex: "FF5C7A").opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .disabled(anxietyBefore == nil)

                    Button("Skip check-in") {
                        showingAnxietyCheck = false
                    }
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingTechniqueSelector) {
            TechniqueSelectionView(selectedTechnique: $selectedTechnique)
        }
    }
    
    
    // MARK: - Main Breathing Interface
    private var mainBreathingInterface: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
            
            Spacer()
            
            // Breathing visualization
            breathingVisualization
            
            // Phase instruction
            phaseInstructionView
            
            Spacer()
            
            // Controls
            controlsSection
            
            // Progress indicator
            progressIndicator
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .frame(width: 40, height: 40)
                    .background(AdaptiveColors.Surface.cardElevated)
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedTechnique.name)
                    .font(.quicksand(size: 15, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)

                Text("\(cycleCount) / \(targetCycles) cycles")
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }

            Spacer()

            Button(action: { showingSettings.toggle() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .frame(width: 40, height: 40)
                    .background(AdaptiveColors.Surface.cardElevated)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Breathing Visualization
    private var breathingVisualization: some View {
        let breathColor = Color(hex: "FF5C7A")

        return ZStack {
            // Outer pulsing rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        breathColor.opacity(0.2 - Double(index) * 0.05),
                        lineWidth: 2
                    )
                    .scaleEffect(outerRingScale + CGFloat(index) * 0.2)
                    .opacity(isSessionActive ? 1.0 : 0.3)
            }

            // Main breathing circle
            ZStack {
                // Gradient background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "FF8FA3").opacity(0.9),
                                breathColor.opacity(0.6),
                                Color(hex: "D94467").opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)

                // Inner rotating element
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "FF7A95"),
                                breathColor.opacity(0.3),
                                Color(hex: "FF7A95")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(innerCircleRotation))
                    .scaleEffect(circleScale)

                // Center icon
                Image(systemName: currentPhase.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(circleScale * 0.8)

                // Progress ring
                Circle()
                    .trim(from: 0, to: phaseProgress)
                    .stroke(
                        breathColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: phaseProgress)
            }
        }
        .frame(width: 300, height: 300)
    }
    
    // MARK: - Phase Instruction
    private var phaseInstructionView: some View {
        VStack(spacing: 8) {
            Text(currentPhase.instruction)
                .font(.instrumentSerif(size: 32))
                .foregroundColor(AdaptiveColors.Text.primary)
                .animation(.easeInOut, value: currentPhase)

            if isSessionActive && currentPhase != .ready {
                Text(getPhaseCountdown())
                    .font(.instrumentSerif(size: 48))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        HStack(spacing: 24) {
            if !isSessionActive {
                // Start button - 3D style
                Button(action: startSession) {
                    ZStack {
                        // Shadow layer
                        Circle()
                            .fill(Color(hex: "C83555"))
                            .frame(width: 76, height: 76)
                            .offset(y: 3)

                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF7A95"),
                                        Color(hex: "FF5C7A"),
                                        Color(hex: "D94467")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)

                        Image(systemName: "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(hex: "FF5C7A").opacity(0.4), radius: 12, x: 0, y: 6)
                }
            } else {
                // Pause/Resume button
                Button(action: togglePause) {
                    ZStack {
                        Circle()
                            .fill(AdaptiveColors.Surface.cardElevated)
                            .frame(width: 56, height: 56)

                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                    }
                }

                // Stop button
                Button(action: stopSession) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "FF2E50").opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "stop.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(hex: "FF2E50"))
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 12) {
            // Cycle dots
            HStack(spacing: 8) {
                ForEach(0..<targetCycles, id: \.self) { index in
                    Circle()
                        .fill(index < cycleCount ? Color(hex: "FF5C7A") : AdaptiveColors.Text.tertiary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            // Time elapsed
            Text("Session time: \(formatTime(elapsedTime))")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.tertiary)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            // Success animation
            ZStack {
                Circle()
                    .fill(Color(hex: "FF5C7A").opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.2)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: showingCompletionView
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(Color(hex: "FF5C7A"))
            }

            VStack(spacing: 10) {
                Text("Session Complete!")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(AdaptiveColors.Text.primary)

                Text("You completed \(cycleCount) breathing cycles")
                    .font(.quicksand(size: 15, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }

            // Post-session anxiety check
            if anxietyBefore != nil {
                VStack(spacing: 16) {
                    Text("How do you feel now?")
                        .font(.quicksand(size: 17, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)

                    HStack(spacing: 8) {
                        ForEach(1...10, id: \.self) { level in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    anxietyAfter = level
                                    let impact = UIImpactFeedbackGenerator(style: .soft)
                                    impact.impactOccurred()
                                }
                            }) {
                                Text("\(level)")
                                    .font(.quicksand(size: 14, weight: anxietyAfter == level ? .bold : .medium))
                                    .foregroundColor(anxietyAfter == level ? .white : AdaptiveColors.Text.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(anxietyAfter == level ? Color(hex: "FF5C7A") : AdaptiveColors.Surface.cardElevated)
                                    )
                            }
                        }
                    }

                    if let before = anxietyBefore, let after = anxietyAfter {
                        let improvement = before - after
                        if improvement > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(Color(hex: "FF5C7A"))
                                Text("Anxiety reduced by \(improvement) points!")
                                    .font(.quicksand(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "FF5C7A"))
                            }
                            .padding(12)
                            .background(Color(hex: "FF5C7A").opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AdaptiveColors.Surface.card)
                )
            }

            Spacer()

            // Finish button - 3D style
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Finish")
                    .font(.quicksand(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "C83555"))
                                .offset(y: 3)

                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FF7A95"),
                                            Color(hex: "FF5C7A"),
                                            Color(hex: "D94467")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
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
                    .shadow(color: Color(hex: "FF5C7A").opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Functions
    private func startSession() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isSessionActive = true
            showingAnxietyCheck = false
            currentPhase = .inhale
            cycleCount = 0
            elapsedTime = 0
            particlesVisible = true
        }
        
        startBreathingCycle()
        
        // Haptic feedback
        if hapticEnabled {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func startBreathingCycle() {
        let pattern = selectedTechnique.enhancedPattern
        
        // Start with inhale
        animateInhale(duration: pattern.inhale)
        
        // Schedule phases
        var delay: Double = 0
        
        delay += pattern.inhale
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isSessionActive {
                currentPhase = .hold1
                animateHold()
                if hapticEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
        
        delay += pattern.hold1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isSessionActive {
                currentPhase = .exhale
                animateExhale(duration: pattern.exhale)
                if hapticEnabled {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
            }
        }
        
        delay += pattern.exhale
        if pattern.hold2 > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isSessionActive {
                    currentPhase = .hold2
                    animateHold()
                    if hapticEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
            delay += pattern.hold2
        }
        
        // Complete cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isSessionActive {
                cycleCount += 1
                
                if cycleCount >= targetCycles {
                    completeSession()
                } else {
                    currentPhase = .inhale
                    startBreathingCycle()
                }
            }
        }
        
        // Update timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isSessionActive && !isPaused {
                elapsedTime += 0.1
            }
        }
    }
    
    private func animateInhale(duration: Double) {
        withAnimation(.easeInOut(duration: duration)) {
            circleScale = 1.0
            circleOpacity = 1.0
            outerRingScale = 1.3
            innerCircleRotation += 180
        }
    }
    
    private func animateExhale(duration: Double) {
        withAnimation(.easeInOut(duration: duration)) {
            circleScale = 0.4
            circleOpacity = 0.6
            outerRingScale = 0.8
            innerCircleRotation -= 180
        }
    }
    
    private func animateHold() {
        withAnimation(.easeInOut(duration: 0.5)) {
            circleOpacity = 0.8
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
        
        if hapticEnabled {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func stopSession() {
        isSessionActive = false
        isPaused = false
        currentPhase = .ready
        timer?.invalidate()
        phaseTimer?.invalidate()
        particlesVisible = false
        
        withAnimation {
            circleScale = 0.4
            circleOpacity = 0.8
            outerRingScale = 1.0
            innerCircleRotation = 0
        }
    }
    
    private func completeSession() {
        currentPhase = .completed
        isSessionActive = false
        timer?.invalidate()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingCompletionView = true
        }
        
        // Celebration haptic
        if hapticEnabled {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func getPhaseCountdown() -> String {
        // This would need actual countdown logic
        return ""
    }
}

// MARK: - Supporting Views

struct TechniqueSelectionView: View {
    @Binding var selectedTechnique: BreathingTechnique
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                AdaptiveColors.Background.primary
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(BreathingTechnique.techniques, id: \.id) { technique in
                            Button(action: {
                                selectedTechnique = technique
                                let impact = UIImpactFeedbackGenerator(style: .soft)
                                impact.impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedTechnique == technique ? Color(hex: "FF5C7A") : Color(hex: "FF5C7A").opacity(0.15))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "wind")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(selectedTechnique == technique ? .white : Color(hex: "FF5C7A"))
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(technique.name)
                                            .font(.quicksand(size: 16, weight: .bold))
                                            .foregroundColor(AdaptiveColors.Text.primary)

                                        Text(technique.description)
                                            .font(.quicksand(size: 13, weight: .medium))
                                            .foregroundColor(AdaptiveColors.Text.secondary)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    if selectedTechnique == technique {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(Color(hex: "FF5C7A"))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AdaptiveColors.Surface.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedTechnique == technique ? Color(hex: "FF5C7A").opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Techniques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5C7A"))
                }
            }
        }
    }
}


#Preview {
    EnhancedBreathingView()
        .preferredColorScheme(.dark)
}