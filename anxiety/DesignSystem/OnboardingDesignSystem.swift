//
//  OnboardingDesignSystem.swift
//  anxiety
//
//  Unified design system matching onboarding aesthetics
//

import SwiftUI

// MARK: - Onboarding Color Palette
struct OnboardingColors {
    
    // Helper function for dynamic colors
    private static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // MARK: - Base Wellness Colors (Adaptive) - Pink Palette
    static let lightLavender = dynamicColor(
        light: Color(hex: "FFE5F0"),  // Light pink
        dark: Color(hex: "2D2838")  // Very dark purple-gray for dark mode
    )

    static let mintCream = dynamicColor(
        light: Color(hex: "FFF0F5"),  // Lavender blush
        dark: Color(hex: "2D2838")  // Match dark purple-gray theme
    )

    static let softPink = dynamicColor(
        light: Color(hex: "FFD6E8"),  // Soft pink
        dark: Color(hex: "2D2838")  // Match dark purple-gray theme
    )

    static let palePurple = dynamicColor(
        light: Color(hex: "FFF0F7"),  // Very pale pink
        dark: Color(hex: "2D2838")  // Match dark purple-gray theme
    )

    // MARK: - Secondary Wellness Colors (Adaptive) - Pink Palette
    static let softPurple = dynamicColor(
        light: Color(hex: "FFB3D9"),  // Medium pink
        dark: Color(hex: "363042")  // Slightly lighter dark purple
    )

    static let softTeal = dynamicColor(
        light: Color(hex: "FFE0ED"),  // Pale pink
        dark: Color(hex: "2D2838")  // Match dark purple-gray theme
    )

    static let wellnessLavender = dynamicColor(
        light: Color(hex: "FF99CC"),  // Rose pink accent
        dark: Color(hex: "C97FA5")  // Muted rose for dark mode
    )
    
    // MARK: - Dark Mode Variants - Pink Palette
    static let darkLavender = Color(hex: "FF99CC").opacity(0.3)
    static let darkTeal = Color(hex: "FFB3D9").opacity(0.25)
    static let darkRose = Color(hex: "FFD6E8").opacity(0.2)
    static let darkPurple = Color(hex: "FFA3C7").opacity(0.2)
    
    // MARK: - Functional Colors (Adaptive)
    static let wellnessGreen = dynamicColor(
        light: Color(hex: "10B981"),
        dark: Color(hex: "34D399")  // Brighter green for dark mode
    )
    
    static let wellnessBlue = dynamicColor(
        light: Color(hex: "3B82F6"),
        dark: Color(hex: "60A5FA")  // Brighter blue for dark mode
    )
    
    static let wellnessOrange = dynamicColor(
        light: Color(hex: "F59E0B"),
        dark: Color(hex: "FBBF24")  // Brighter orange for dark mode
    )
    
    static let wellnessRed = dynamicColor(
        light: Color(hex: "EF4444"),
        dark: Color(hex: "F87171")  // Brighter red for dark mode
    )
    
    static let wellnessGray = dynamicColor(
        light: Color(hex: "6B7280"),
        dark: Color(hex: "9CA3AF")  // Lighter gray for dark mode
    )
}

// MARK: - Adaptive Colors Reference
// Use these values directly in views:
// Light mode primary text: Color(hex: "1A1A1A")
// Dark mode primary text: Color.white
// Light mode secondary text: Color(hex: "4A4A4A") 
// Dark mode secondary text: Color(hex: "E0E0E0")
// Light mode text shadow: Color.white.opacity(0.8)
// Dark mode text shadow: Color.black.opacity(0.6)

// MARK: - Wellness Background Component
struct WellnessBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var breathingScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    let intensity: BackgroundIntensity
    
    enum BackgroundIntensity {
        case subtle, medium, full
        
        var opacityMultiplier: Double {
            switch self {
            case .subtle: return 0.3
            case .medium: return 0.6
            case .full: return 1.0
            }
        }
    }
    
    init(intensity: BackgroundIntensity = .medium) {
        self.intensity = intensity
    }
    
    var body: some View {
        ZStack {
            // Base wellness gradient
            LinearGradient(
                colors: colorScheme == .dark ? [
                    OnboardingColors.darkLavender,
                    OnboardingColors.darkTeal,
                    OnboardingColors.darkRose
                ] : [
                    OnboardingColors.lightLavender,
                    OnboardingColors.mintCream,
                    OnboardingColors.softPink,
                    OnboardingColors.palePurple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(intensity.opacityMultiplier)
            
            // Breathing overlay
            RadialGradient(
                colors: colorScheme == .dark ? [
                    OnboardingColors.darkPurple,
                    Color.clear
                ] : [
                    OnboardingColors.softPurple.opacity(0.4 * intensity.opacityMultiplier),
                    OnboardingColors.softTeal.opacity(0.3 * intensity.opacityMultiplier),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 600
            )
            .scaleEffect(breathingScale)
            
            // Botanical elements for subtle backgrounds
            if intensity != .full {
                ForEach(0..<2, id: \.self) { index in
                    Image(systemName: "leaf.fill")
                        .font(.quicksand(size: CGFloat(60 + index * 30)))
                        .foregroundColor(OnboardingColors.softTeal.opacity(0.04))
                        .rotationEffect(.degrees(rotationAngle + Double(index * 45)))
                        .offset(
                            x: CGFloat(-100 + index * 200),
                            y: CGFloat(-150 + index * 100)
                        )
                        .blur(radius: 3)
                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                breathingScale = 1.1
            }
            
            withAnimation(
                .linear(duration: 120)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Wellness Card Component
struct WellnessCard<Content: View>: View {
    let content: Content
    let elevation: CardElevation
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    enum CardElevation {
        case none, subtle, medium, elevated
        
        var shadowRadius: CGFloat {
            switch self {
            case .none: return 0
            case .subtle: return 2
            case .medium: return 6
            case .elevated: return 12
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .none: return 0
            case .subtle: return 0.05
            case .medium: return 0.1
            case .elevated: return 0.15
            }
        }
    }
    
    init(
        elevation: CardElevation = .medium,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        OnboardingColors.softTeal.opacity(0.3),
                                        OnboardingColors.softTeal.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: Color.black.opacity(elevation.shadowOpacity * 1.2),
                radius: elevation.shadowRadius * 1.5,
                x: 0,
                y: elevation.shadowRadius * 0.75
            )
            .shadow(
                color: Color.black.opacity(elevation.shadowOpacity * 0.5),
                radius: elevation.shadowRadius * 0.5,
                x: 0,
                y: elevation.shadowRadius * 0.25
            )
    }
}

// MARK: - Wellness Typography
struct WellnessText: View {
    let text: String
    let style: TextStyle
    
    enum TextStyle {
        case largeTitle
        case title
        case headline
        case subheadline
        case body
        case caption
        case button
        
        var font: Font {
            switch self {
            case .largeTitle:
                return .quicksand(size: 32, weight: .bold)
            case .title:
                return .quicksand(size: 24, weight: .bold)
            case .headline:
                return .quicksand(size: 20, weight: .semibold)
            case .subheadline:
                return .quicksand(size: 16, weight: .medium)
            case .body:
                return .quicksand(size: 16, weight: .regular)
            case .caption:
                return .quicksand(size: 13, weight: .medium)
            case .button:
                return .quicksand(size: 16, weight: .semibold)
            }
        }
        
        var color: Color {
            switch self {
            case .largeTitle, .title, .headline:
                return AdaptiveColors.Text.primary
            case .subheadline, .body:
                return AdaptiveColors.Text.secondary
            case .caption:
                return AdaptiveColors.Text.tertiary
            case .button:
                return .white
            }
        }
    }
    
    init(_ text: String, style: TextStyle) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundColor(style.color)
    }
}

// MARK: - Wellness Action Button
struct WellnessActionButton: View {
    let title: String
    let subtitle: String?
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, tertiary, wellness
        
        var backgroundColor: LinearGradient {
            switch self {
            case .primary:
                return LinearGradient(
                    colors: [OnboardingColors.wellnessLavender, OnboardingColors.softPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .secondary:
                return LinearGradient(
                    colors: [OnboardingColors.softTeal, OnboardingColors.mintCream],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .tertiary:
                return LinearGradient(
                    colors: [Color.clear, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .wellness:
                return LinearGradient(
                    colors: [OnboardingColors.lightLavender, OnboardingColors.palePurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary:
                return .white
            case .wellness:
                return .black // Black text for better contrast on light purple background
            case .tertiary:
                return OnboardingColors.wellnessLavender
            }
        }
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.quicksand(size: 20, weight: .medium))
                    .foregroundColor(style.foregroundColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.quicksand(size: 18, weight: .semibold))
                        .foregroundColor(style.foregroundColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(style.foregroundColor.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(style.foregroundColor.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(style.backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style == .tertiary ? OnboardingColors.wellnessLavender.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Wellness Section Header
struct WellnessSectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    WellnessText(title, style: .title)
                    
                    if let subtitle = subtitle {
                        WellnessText(subtitle, style: .subheadline)
                    }
                }
                
                Spacer()
                
                if let action = action, let actionTitle = actionTitle {
                    Button(actionTitle) {
                        action()
                    }
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(OnboardingColors.wellnessLavender)
                }
            }
        }
    }
}

