//
//  DSComponents.swift
//  anxiety
//
//  Reusable design system components
//

import SwiftUI

// MARK: - Primary Button

struct DSPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: .DS.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(.DS.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: .DS.buttonHeightMax)
            .background(
                isEnabled && !isLoading
                    ? LinearGradient.DS.primary
                    : LinearGradient(colors: [Color.DS.textTertiary], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(.DS.radiusCard)
        }
        .buttonStyle(ScaleButtonStyle())
        .dsShadow(.medium)
        .disabled(!isEnabled || isLoading)
    }
}

// MARK: - Option Button (Selectable)

struct DSOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        }) {
            HStack {
                Text(title)
                    .font(.DS.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.DS.text(.primary, for: colorScheme))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.DS.lavender)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.DS.lg)
            .background(
                isSelected
                    ? Color.DS.lavender.opacity(0.05)
                    : Color.DS.bg(.primary, for: colorScheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .DS.radiusButton)
                    .strokeBorder(
                        isSelected ? Color.DS.lavender : Color.DS.textTertiary.opacity(0.3),
                        lineWidth: 2
                    )
            )
            .cornerRadius(.DS.radiusButton)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.DS.standard, value: isSelected)
    }
}

// MARK: - Continue Button (Floating)

struct DSContinueButton: View {
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Text("Continue")
                    .font(.DS.small)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, .DS.xl)
            .padding(.vertical, .DS.md)
            .background(
                isEnabled
                    ? Color.DS.lavender
                    : Color.DS.textTertiary
            )
            .cornerRadius(.DS.radiusFull)
        }
        .buttonStyle(ScaleButtonStyle())
        .dsShadow(.large)
        .disabled(!isEnabled)
    }
}

// MARK: - Progress Bar

struct DSProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: .DS.radiusFull)
                    .fill(Color.DS.textTertiary.opacity(0.2))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: .DS.radiusFull)
                    .fill(LinearGradient.DS.primary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.DS.smooth, value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Card View

struct DSCard<Content: View>: View {
    let content: Content
    var isSelected: Bool = false
    var padding: CGFloat = .DS.xl
    
    @Environment(\.colorScheme) var colorScheme
    
    init(isSelected: Bool = false, padding: CGFloat = .DS.xl, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isSelected = isSelected
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                isSelected
                    ? Color.DS.lavender.opacity(0.05)
                    : Color.DS.bg(.primary, for: colorScheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .DS.radiusCard)
                    .strokeBorder(
                        isSelected ? Color.DS.lavender : Color.DS.textTertiary.opacity(0.2),
                        lineWidth: 2
                    )
            )
            .cornerRadius(.DS.radiusCard)
            .dsShadow(isSelected ? .medium : .subtle)
            .animation(.DS.standard, value: isSelected)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.DS.quick, value: configuration.isPressed)
    }
}

// MARK: - Page Transition

struct DSPageTransition: ViewModifier {
    let isVisible: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.DS.smooth, value: isVisible)
    }
}

extension View {
    func dsPageTransition(isVisible: Bool) -> some View {
        modifier(DSPageTransition(isVisible: isVisible))
    }
}

// MARK: - Success Badge

struct DSSuccessBadge: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
            
            Text(text)
                .font(.DS.small)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, .DS.lg)
        .padding(.vertical, .DS.sm)
        .background(Color.DS.wellnessGreen)
        .cornerRadius(.DS.radiusFull)
    }
}

// MARK: - Copy Button

struct DSCopyButton: View {
    let text: String
    @State private var copied = false
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = text
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copied = false
            }
        }) {
            HStack(spacing: .DS.md) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 16, weight: .semibold))
                
                Text(copied ? "Copied!" : "Copy Code")
                    .font(.DS.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.DS.lavender)
            .frame(maxWidth: .infinity)
            .frame(height: .DS.buttonHeightMin)
            .background(Color.DS.lavender.opacity(0.1))
            .cornerRadius(.DS.radiusButton)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.DS.standard, value: copied)
    }
}
