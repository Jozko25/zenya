//
//  LiquidGlassSystem.swift
//  anxiety
//
//  Liquid Glass UI System - Modern glassmorphism design
//

import SwiftUI

// MARK: - Glass Intensity Levels

enum GlassIntensity {
    case subtle
    case medium
    case strong
    case ultra
    
    var blurRadius: CGFloat {
        switch self {
        case .subtle: return 10
        case .medium: return 20
        case .strong: return 30
        case .ultra: return 40
        }
    }
    
    var opacity: Double {
        switch self {
        case .subtle: return 0.5
        case .medium: return 0.3
        case .strong: return 0.2
        case .ultra: return 0.1
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .subtle: return 0.3
        case .medium: return 0.4
        case .strong: return 0.5
        case .ultra: return 0.6
        }
    }
}

// MARK: - Liquid Glass Modifier

struct LiquidGlassModifier: ViewModifier {
    let intensity: GlassIntensity
    let tintColor: Color
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    init(
        intensity: GlassIntensity = .medium,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 20,
        borderWidth: CGFloat = 1
    ) {
        self.intensity = intensity
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    tintColor.opacity(intensity.opacity)
                    
                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                        .opacity(0.9)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity.borderOpacity),
                                Color.white.opacity(intensity.borderOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            )
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .shadow(color: tintColor.opacity(0.15), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Glass Card Component

struct LiquidGlassCard<Content: View>: View {
    let intensity: GlassIntensity
    let tintColor: Color
    let cornerRadius: CGFloat
    let content: Content
    
    init(
        intensity: GlassIntensity = .medium,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.intensity = intensity
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .modifier(LiquidGlassModifier(
                intensity: intensity,
                tintColor: tintColor,
                cornerRadius: cornerRadius
            ))
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    let colors: [Color]
    let duration: Double
    
    init(colors: [Color] = [
        AdaptiveColors.Action.breathing,
        AdaptiveColors.Action.mood,
        AdaptiveColors.Action.progress,
        AdaptiveColors.Action.coaching
    ], duration: Double = 8.0) {
        self.colors = colors
        self.duration = duration
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Floating Glass Button

struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let tintColor: Color
    let intensity: GlassIntensity
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        tintColor: Color = AdaptiveColors.Action.breathing,
        intensity: GlassIntensity = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.tintColor = tintColor
        self.intensity = intensity
    }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.quicksand(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.quicksand(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    tintColor.opacity(0.6)
                    VisualEffectBlur(blurStyle: .systemThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(16)
            .shadow(color: tintColor.opacity(0.25), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Glass Tab Bar

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                LiquidGlassTabItem(
                    icon: tabs[index].icon,
                    title: tabs[index].title,
                    isSelected: selectedTab == index
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            ZStack {
                Color.white.opacity(0.1)
                VisualEffectBlur(blurStyle: .systemThinMaterial)
            }
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct LiquidGlassTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon : icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AdaptiveColors.Action.breathing : .white.opacity(0.6))
                
                Text(title)
                    .font(.quicksand(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AdaptiveColors.Action.breathing : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    AnyView(
                        Capsule()
                            .fill(AdaptiveColors.Action.breathing.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(AdaptiveColors.Action.breathing.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 8)
                    ) :
                    AnyView(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Glass Progress Bar

struct LiquidGlassProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, color: Color = AdaptiveColors.Action.progress, height: CGFloat = 12) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                color,
                                color.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                    .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 2)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Glass Pill Badge

struct LiquidGlassPill: View {
    let text: String
    let icon: String?
    let color: Color
    
    init(text: String, icon: String? = nil, color: Color = AdaptiveColors.Action.breathing) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            Text(text)
                .font(.quicksand(size: 13, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                color.opacity(0.5)
                VisualEffectBlur(blurStyle: .systemThinMaterial)
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlass(
        intensity: GlassIntensity = .medium,
        tintColor: Color = .white,
        cornerRadius: CGFloat = 20
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            intensity: intensity,
            tintColor: tintColor,
            cornerRadius: cornerRadius
        ))
    }
}
