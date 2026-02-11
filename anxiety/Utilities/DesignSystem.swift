//
//  DesignSystem.swift
//  anxiety
//
//  Comprehensive design system for wellness app
//  Based on mental health UX research & iOS HIG
//

import SwiftUI

// MARK: - Typography Scale
struct Typography {
    // Research-based: Serif for empathy, Sans-serif for clarity

    // Display (Page titles, hero text)
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
    static let displaySmall = Font.system(size: 24, weight: .bold, design: .default)

    // Headings (Section titles)
    static let headingLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let headingSmall = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Body (Content, descriptions) - MINIMUM 16px for readability
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)

    // Labels (Metadata, captions)
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // Line height multiplier (research: 1.5x for wellness)
    static let lineSpacing: CGFloat = 0.5
}

// MARK: - Spacing System (8px base unit)
struct Spacing {
    static let xxxs: CGFloat = 4   // 0.5 unit
    static let xxs: CGFloat = 8    // 1 unit
    static let xs: CGFloat = 12    // 1.5 units
    static let sm: CGFloat = 16    // 2 units
    static let md: CGFloat = 24    // 3 units
    static let lg: CGFloat = 32    // 4 units
    static let xl: CGFloat = 40    // 5 units
    static let xxl: CGFloat = 48   // 6 units
    static let xxxl: CGFloat = 64  // 8 units

    // Section spacing (research: ample white space reduces anxiety)
    static let sectionSpacing: CGFloat = 40
    static let breathingRoom: CGFloat = 50
}

// MARK: - Touch Targets (Apple HIG + Accessibility)
struct TouchTarget {
    static let minimum: CGFloat = 44       // Apple HIG minimum
    static let comfortable: CGFloat = 48   // Research-recommended
    static let primaryAction: CGFloat = 56 // Large CTA buttons

    // Spacing between targets (prevent fat-finger errors)
    static let minimumSpacing: CGFloat = 16
}

// MARK: - Corner Radius (iOS standard: 12-13px for buttons)
struct CornerRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12        // iOS standard for buttons
    static let md: CGFloat = 16        // Standard cards
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let round: CGFloat = 9999   // Fully rounded/pill buttons
}

// MARK: - Shadows (Subtle, not overwhelming)
struct Shadows {
    static let minimal = Shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let subtle = Shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
    static let medium = Shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8)
    static let elevated = Shadow(color: Color.black.opacity(0.20), radius: 20, x: 0, y: 10)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Psychology (Research-based)
struct WellnessColors {
    // Primary - Calming Blues (reduces anxiety, builds trust)
    static let calmBlue = Color(hex: "5B9BD5")
    static let deepBlue = Color(hex: "4A7BA7")
    static let lightBlue = Color(hex: "A8D5F2")

    // Secondary - Harmony Greens (balance, health)
    static let harmonyGreen = Color(hex: "7FB685")
    static let forestGreen = Color(hex: "5A9263")
    static let mintGreen = Color(hex: "A8DDB5")

    // Accent - Warm Uplift (joy, energy)
    static let warmOrange = Color(hex: "F4A261")
    static let goldenYellow = Color(hex: "F9C74F")
    static let coralPink = Color(hex: "FF8B94")

    // Pastels - Soothing (Headspace-inspired)
    static let pastelLavender = Color(hex: "C7B8EA")
    static let pastelPeach = Color(hex: "FFD6BA")
    static let pastelMint = Color(hex: "C8E6C9")
    static let pastelBlue = Color(hex: "B3D9FF")

    // Neutral - Clean Base (updated for better dark mode)
    static let pureBlack = Color(hex: "121212")  // #121212 instead of pure black
    static let charcoal = Color(hex: "1a1a1a")
    static let slate = Color(hex: "2a2a2a")

    // Text hierarchy (off-white prevents halation effect)
    static let textPrimary = Color(hex: "E0E0E0")      // Off-white
    static let textSecondary = Color(hex: "B0B0B0")    // Secondary
    static let textTertiary = Color(hex: "808080")     // Tertiary/hint
    static let textQuaternary = Color.white.opacity(0.3)
}

// MARK: - Animation Constants (Subtle, calming)
struct Animations {
    // Duration (research: brief, not distracting)
    static let instant: Double = 0.1
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.5
    static let leisurely: Double = 0.8

    // Spring animations (warm, organic feel)
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.85)
    static let playfulSpring = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let bouncySpring = Animation.spring(response: 0.6, dampingFraction: 0.7)

    // Easing
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
}

// MARK: - Opacity Levels
struct Opacity {
    static let invisible: Double = 0
    static let barely: Double = 0.03
    static let subtle: Double = 0.06
    static let light: Double = 0.10
    static let medium: Double = 0.15
    static let visible: Double = 0.25
    static let strong: Double = 0.5
    static let veryStrong: Double = 0.7
    static let opaque: Double = 1.0
}

// MARK: - Container Styles (Mental health app hierarchy)
enum ContainerStyle {
    case primary
    case secondary
    case tertiary
    case subtle
    case glass
    case elevated
    case floating
}

struct ContainerStyleConfig {
    let fillOpacity: Double
    let borderOpacity: Double
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let cornerRadius: CGFloat
    let useMaterial: Bool
    let innerGlow: Bool

    static func config(for style: ContainerStyle) -> ContainerStyleConfig {
        switch style {
        case .primary:
            return ContainerStyleConfig(
                fillOpacity: 1.0,
                borderOpacity: 0.25,
                shadowRadius: 16,
                shadowOpacity: 0.25,
                cornerRadius: CornerRadius.xl,
                useMaterial: false,
                innerGlow: true
            )
        case .secondary:
            return ContainerStyleConfig(
                fillOpacity: 0.08,
                borderOpacity: 0.15,
                shadowRadius: 14,
                shadowOpacity: 0.12,
                cornerRadius: CornerRadius.lg,
                useMaterial: true,
                innerGlow: false
            )
        case .tertiary:
            return ContainerStyleConfig(
                fillOpacity: 0.04,
                borderOpacity: 0.08,
                shadowRadius: 8,
                shadowOpacity: 0.06,
                cornerRadius: CornerRadius.md,
                useMaterial: true,
                innerGlow: false
            )
        case .subtle:
            return ContainerStyleConfig(
                fillOpacity: 0.02,
                borderOpacity: 0.05,
                shadowRadius: 4,
                shadowOpacity: 0.03,
                cornerRadius: CornerRadius.sm,
                useMaterial: false,
                innerGlow: false
            )
        case .glass:
            return ContainerStyleConfig(
                fillOpacity: 0.12,
                borderOpacity: 0.2,
                shadowRadius: 20,
                shadowOpacity: 0.15,
                cornerRadius: CornerRadius.xl,
                useMaterial: true,
                innerGlow: true
            )
        case .elevated:
            return ContainerStyleConfig(
                fillOpacity: 0.1,
                borderOpacity: 0.18,
                shadowRadius: 18,
                shadowOpacity: 0.2,
                cornerRadius: CornerRadius.lg,
                useMaterial: true,
                innerGlow: false
            )
        case .floating:
            return ContainerStyleConfig(
                fillOpacity: 0.15,
                borderOpacity: 0.25,
                shadowRadius: 24,
                shadowOpacity: 0.3,
                cornerRadius: CornerRadius.xxl,
                useMaterial: true,
                innerGlow: true
            )
        }
    }
}

// MARK: - Accessibility Helpers
extension View {
    func minimumTouchTarget() -> some View {
        self.frame(minWidth: TouchTarget.minimum, minHeight: TouchTarget.minimum)
    }

    func comfortableTouchTarget() -> some View {
        self.frame(minWidth: TouchTarget.comfortable, minHeight: TouchTarget.comfortable)
    }

    func primaryActionSize() -> some View {
        self.frame(minWidth: TouchTarget.primaryAction, minHeight: TouchTarget.primaryAction)
    }
}

// MARK: - Modern Container Modifiers
extension View {
    func modernGlassCard(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "2a2a2a"))  // Level 1 elevation
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
    }

    func elevatedCard(cornerRadius: CGFloat = 22, shadowIntensity: Double = 0.12) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "2f2f2f"))  // Level 2 elevation (appears closer)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(shadowIntensity), radius: 4, x: 0, y: 2)
    }

    func floatingCard(cornerRadius: CGFloat = 28) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(hex: "2f2f2f"))  // Level 2 elevation
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
    }
    
    func innerGlow(color: Color, radius: CGFloat = 20) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius)
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.15),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .allowsHitTesting(false)
        )
    }
    
    func springAppear(delay: Double = 0) -> some View {
        self.modifier(SpringAppearModifier(delay: delay))
    }
    
    func pressableScale() -> some View {
        self.modifier(PressableScaleModifier())
    }
}

struct SpringAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1.0 : 0.0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.4)
                    .delay(delay)
                ) {
                    appeared = true
                }
            }
    }
}

struct PressableScaleModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}


