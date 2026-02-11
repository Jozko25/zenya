//
//  ActivationCodeView.swift
//  anxiety
//
//  Activation code entry - matches web design system
//

import SwiftUI

struct ActivationCodeView: View {
    let prefillCode: String? // Optional prefill code from iOS bridge
    
    @StateObject private var activationService = ActivationService.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var code = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var detectedClipboardCode: String?
    @State private var isSubmitting = false
    @State private var animateIn = false
    @State private var showRecoverWeb = false
    @State private var showPurchaseWeb = false
    @State private var webURL: URL?
    @FocusState private var isCodeFieldFocused: Bool
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var floatingOffset: CGFloat = 0
    
    // Default initializer for when no prefill code
    init(prefillCode: String? = nil) {
        self.prefillCode = prefillCode
    }
    
    private let theme = SoulPalette.neon
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Refined background
                LinearGradient(
                    colors: [theme.backgroundTop, theme.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle animated background
                refinedBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        Spacer().frame(height: geometry.safeAreaInsets.top + 32)
                        
                        headerSection
                        
                        codeInputCard
                        
                        if let clipboardCode = detectedClipboardCode, clipboardCode != code, !isSubmitting {
                            clipboardSuggestion(clipboardCode)
                        }
                        
                        if !isSubmitting {
                            helpSection
                        }
                        
                        Spacer().frame(height: geometry.safeAreaInsets.bottom + 32)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                }
                
                // Loading overlay
                if isSubmitting {
                    loadingOverlay
                }
            }
        }
        .ignoresSafeArea()
        .webViewSheet(url: webURL, isPresented: $showRecoverWeb)
        .webViewSheet(url: webURL, isPresented: $showPurchaseWeb)
        .alert("Activation Failed", isPresented: $showError) {
            Button("Try Again", role: .cancel) { }
        } message: {
            Text(activationService.error?.errorDescription ?? "Unknown error")
        }
        .onChange(of: showSuccess) { success in
            if success {
                dismiss()
            }
        }
        .task {
            debugPrint("🌉 ActivationCodeView: .task started, prefillCode = \(prefillCode ?? "nil")")
            
            // Handle prefill code from iOS bridge
            if let prefillCode = prefillCode {
                // Remove "ZENYA-" prefix if present and dashes
                let cleanCode = prefillCode
                    .replacingOccurrences(of: "ZENYA-", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                
                debugPrint("🌉 iOS Bridge: Prefilling code from '\(prefillCode)' to '\(cleanCode)'")
                
                // Set the code
                code = cleanCode
                debugPrint("🌉 iOS Bridge: Code state updated to: \(code)")
                
                // Auto-submit after delay - let user see the beautiful animation
                Task { @MainActor in
                    debugPrint("🌉 iOS Bridge: Waiting 2.0s before auto-submit (let user see the code fill)...")
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0 seconds - enough to see the animation
                    debugPrint("🌉 iOS Bridge: Auto-submit check - code: \(code), cleanCode: \(cleanCode), isSubmitting: \(isSubmitting)")
                    if code == cleanCode && !isSubmitting {
                        debugPrint("🌉 iOS Bridge: ✅ Auto-submitting prefilled code")
                        activateCode()
                    } else {
                        debugPrint("🌉 iOS Bridge: ❌ Auto-submit skipped (code changed or already submitting)")
                    }
                }
            } else {
                debugPrint("🌉 ActivationCodeView: No prefill code, checking clipboard instead")
                checkClipboard()
            }
            
            startAnimations()
        }
    }
    
    private var refinedBackground: some View {
        ZStack {
            // Subtle radial gradient
            RadialGradient(
                colors: [
                    theme.accent.opacity(0.08),
                    theme.accentSecondary.opacity(0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .scaleEffect(breathingScale)
            .blur(radius: 60)
            
            // Minimal floating accent
            Circle()
                .fill(theme.accent.opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: -80, y: 150 + floatingOffset * 0.3)
            
            Circle()
                .fill(theme.accentSecondary.opacity(0.04))
                .frame(width: 150, height: 150)
                .blur(radius: 35)
                .offset(x: 100, y: -100 - floatingOffset * 0.2)
        }
    }
    
    private func startAnimations() {
        withAnimation(
            .easeOut(duration: 0.5)
            .delay(0.1)
        ) {
            animateIn = true
        }
        
        withAnimation(
            .easeInOut(duration: 6.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.08
        }
        
        withAnimation(
            .easeInOut(duration: 8.0)
            .repeatForever(autoreverses: true)
        ) {
            floatingOffset = 20
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Find your peace")
                .font(.quicksand(size: 36, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)
                .multilineTextAlignment(.center)
            
            Text("Enter your activation code to continue")
                .font(.quicksand(size: 16, weight: .regular))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(animateIn ? 1.0 : 0.95)
        .opacity(animateIn ? 1.0 : 0.0)
    }
    
    // MARK: - Code Input Card
    
    private var codeInputCard: some View {
        VStack(spacing: 32) {
            // Code segments display
            VStack(spacing: 20) {
                codeSegmentView(segment: firstSegment, isActive: code.count < 4)
                
                codeSegmentView(segment: secondSegment, isActive: code.count >= 4)
            }
            
            // Hidden text field for input
            TextField("", text: $code)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .textCase(.uppercase)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .keyboardType(.asciiCapable)
                .focused($isCodeFieldFocused)
                .opacity(0)
                .frame(height: 1)
                .onChange(of: code) { newValue in
                    let filtered = newValue.filter { $0.isLetter || $0.isNumber }
                    
                    if filtered.count > 8 {
                        code = String(filtered.prefix(8))
                    } else {
                        if filtered != code {
                            code = filtered
                        }
                        
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        // Auto-submit when code is complete
                        if code.count == 8 {
                            debugPrint("✅ Code complete: \(code), auto-submitting...")
                            isCodeFieldFocused = false
                            
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                if !isSubmitting {
                                    activateCode()
                                }
                            }
                        }
                    }
                }
            
            // Status bar
            HStack {
                if code.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 12, weight: .medium))
                        Text("Start typing to enter code")
                            .font(.quicksand(size: 13, weight: .medium))
                    }
                    .foregroundColor(AdaptiveColors.Text.tertiary)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: code.count == 8 ? "checkmark.circle.fill" : "circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(code.count == 8 ? theme.accent : AdaptiveColors.Text.tertiary)
                        
                        Text("\(code.count)/8")
                            .font(.quicksand(size: 13, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                code = ""
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }) {
                            Text("Clear")
                                .font(.quicksand(size: 13, weight: .semibold))
                                .foregroundColor(AdaptiveColors.Text.tertiary)
                        }
                    }
                }
            }
            .frame(height: 24)
        }
        .padding(32)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.surfaceAlt.opacity(0.6))
                
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.03 : 0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                theme.accent.opacity(0.25),
                                theme.accentSecondary.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: theme.accent.opacity(0.1), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .onTapGesture {
            isCodeFieldFocused = true
        }
        .scaleEffect(animateIn ? 1.0 : 0.96)
        .opacity(animateIn ? 1.0 : 0.0)
    }
    
    private func codeSegmentView(segment: String, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                singleCodeSegment(
                    segment: segment,
                    index: index,
                    isActive: isActive
                )
            }
        }
    }
    
    private func singleCodeSegment(segment: String, index: Int, isActive: Bool) -> some View {
        let hasCharacter = index < segment.count
        let isCurrentActive = isActive && index == segment.count
        
        return ZStack {
            segmentBackgroundView(hasCharacter: hasCharacter)
            
            segmentBorderView(hasCharacter: hasCharacter, isCurrentActive: isCurrentActive)
            
            segmentContentView(segment: segment, index: index, hasCharacter: hasCharacter, isCurrentActive: isCurrentActive)
        }
        .shadow(
            color: segmentShadowColor(hasCharacter: hasCharacter, isCurrentActive: isCurrentActive),
            radius: isCurrentActive ? 12 : 6,
            x: 0,
            y: isCurrentActive ? 6 : 3
        )
        .scaleEffect(isCurrentActive ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: segment.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
    
    @ViewBuilder
    private func segmentBackgroundView(hasCharacter: Bool) -> some View {
        if hasCharacter {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.15),
                            theme.accentSecondary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 72)
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(AdaptiveColors.Surface.secondary.opacity(0.8))
                .frame(width: 56, height: 72)
        }
    }
    
    private func segmentBorderView(hasCharacter: Bool, isCurrentActive: Bool) -> some View {
        let borderGradient: LinearGradient
        let lineWidth: CGFloat
        
        if isCurrentActive {
            borderGradient = LinearGradient(
                colors: [
                    theme.accent.opacity(0.6),
                    theme.accentSecondary.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            lineWidth = 2
        } else if hasCharacter {
            borderGradient = LinearGradient(
                colors: [
                    theme.accent.opacity(0.3),
                    theme.accentSecondary.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            lineWidth = 1.5
        } else {
            borderGradient = LinearGradient(
                colors: [
                    AdaptiveColors.Surface.tertiary.opacity(0.4),
                    AdaptiveColors.Surface.tertiary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            lineWidth = 1.5
        }
        
        return RoundedRectangle(cornerRadius: 18)
            .stroke(borderGradient, lineWidth: lineWidth)
            .frame(width: 56, height: 72)
    }
    
    @ViewBuilder
    private func segmentContentView(segment: String, index: Int, hasCharacter: Bool, isCurrentActive: Bool) -> some View {
        if hasCharacter {
            Text(String(segment[segment.index(segment.startIndex, offsetBy: index)]))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(AdaptiveColors.Text.primary)
                .transition(.scale.combined(with: .opacity))
        } else if isCurrentActive {
            Rectangle()
                .fill(theme.accent)
                .frame(width: 2.5, height: 32)
                .cornerRadius(1.25)
                .opacity(0.8)
        }
    }
    
    private func segmentShadowColor(hasCharacter: Bool, isCurrentActive: Bool) -> Color {
        if isCurrentActive {
            return theme.accent.opacity(0.3)
        } else if hasCharacter {
            return theme.accent.opacity(0.1)
        } else {
            return .clear
        }
    }
    
    private var firstSegment: String {
        String(code.prefix(4))
    }
    
    private var secondSegment: String {
        code.count > 4 ? String(code.suffix(from: code.index(code.startIndex, offsetBy: 4))) : ""
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black
                .opacity(isSubmitting ? 1 : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: isSubmitting)
            
            VStack(spacing: 40) {
                LottieView(
                    animationName: "businessman-rocket",
                    loopMode: .loop,
                    contentMode: .scaleAspectFit
                )
                .frame(width: 280, height: 280)
                .opacity(isSubmitting ? 1 : 0)
                .scaleEffect(isSubmitting ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isSubmitting)
                
                Text("Preparing your personalized wellness experience")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .opacity(isSubmitting ? 1 : 0)
                    .offset(y: isSubmitting ? 0 : 15)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: isSubmitting)
                
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(theme.accent.opacity(0.8))
                            .frame(width: 10, height: 10)
                            .scaleEffect(isSubmitting ? 1.2 : 0.6)
                            .opacity(isSubmitting ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 0.7)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: isSubmitting
                            )
                    }
                }
                .opacity(isSubmitting ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.5), value: isSubmitting)
            }
            .opacity(isSubmitting ? 1 : 0)
            .scaleEffect(isSubmitting ? 1.0 : 0.85)
        }
    }
    
    // MARK: - Clipboard Suggestion
    
    private func clipboardSuggestion(_ clipboardCode: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                code = clipboardCode
            }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }) {
            HStack(spacing: 16) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(theme.accent.opacity(0.12))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Code found in clipboard")
                        .font(.quicksand(size: 15, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                    
                    Text("ZENYA-\(clipboardCode.prefix(4))-\(clipboardCode.suffix(4))")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accent)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surfaceAlt.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(animateIn ? 1.0 : 0.96)
        .opacity(animateIn ? 1.0 : 0.0)
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(spacing: 16) {
            Text("Need help?")
                .font(.quicksand(size: 14, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.tertiary)
            
            HStack(spacing: 12) {
                Button(action: {
                    webURL = URL(string: "https://zenya-web.vercel.app/recover")
                    showRecoverWeb = true
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Lost code?")
                            .font(.quicksand(size: 15, weight: .semibold))
                    }
                    .foregroundColor(theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.accent.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.accent.opacity(0.25), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    webURL = URL(string: "https://zenya-web.vercel.app")
                    showPurchaseWeb = true
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Get code")
                            .font(.quicksand(size: 15, weight: .semibold))
                    }
                    .foregroundColor(OnboardingColors.wellnessGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(OnboardingColors.wellnessGreen.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(OnboardingColors.wellnessGreen.opacity(0.25), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .scaleEffect(animateIn ? 1.0 : 0.96)
        .opacity(animateIn ? 1.0 : 0.0)
    }
    
    // MARK: - Helpers
    
    private var isCodeValid: Bool {
        code.count == 8
    }
    
    private func checkClipboard() {
        guard let clipboardText = UIPasteboard.general.string else { return }
        
        let cleanText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if cleanText.range(of: "^ZENYA[A-Z0-9]{8}$", options: .regularExpression) != nil {
            let extractedCode = String(cleanText.dropFirst(5))
            detectedClipboardCode = extractedCode
            debugPrint("📋 Detected activation code in clipboard: \(extractedCode)")
        }
    }
    
    private func activateCode() {
        isSubmitting = true
        let fullCode = "ZENYA-\(code.prefix(4))-\(code.suffix(4))"
        
        Task {
            do {
                try await activationService.redeemCode(fullCode)
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    showError = true
                    debugPrint("❌ Activation failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ActivationCodeView()
}
