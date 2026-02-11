//
//  AdaptiveColorSystem.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

// MARK: - Adaptive Color System for Anxiety Relief App
struct AdaptiveColors {
    
    // MARK: - Background Colors
    struct Background {
        static let primary = Color.backgroundPrimary
        static let secondary = Color.backgroundSecondary
        static let tertiary = Color.backgroundSecondary
        static let elevated = Color.surfaceCardElevated
        
        // True black for OLED battery savings in deep meditation states
        static let meditation = Color.meditationBackground
    }
    
    // MARK: - Text Colors with Enhanced Contrast
    struct Text {
        static let primary = Color.textPrimary
        static let secondary = Color.textSecondary
        static let tertiary = Color.textTertiary
        static let accent = Color.actionBreathing
        
        // High contrast for SOS/Emergency features
        static let emergency = Color.textEmergency
    }
    
    // MARK: - Therapeutic Action Colors
    struct Action {
        static let breathing = Color.actionBreathing
        static let mood = Color.actionMood
        static let sos = Color.actionSOS
        static let coaching = Color.actionCoaching
        static let progress = Color.progressPositive
    }
    
    // MARK: - Wellness Progress Colors
    struct Progress {
        static let positive = Color.progressPositive
        static let neutral = Color.progressNeutral
        static let attention = Color.progressAttention
    }
    
    // MARK: - Card and Surface Colors
    struct Surface {
        static let card = Color.surfaceCard
        static let cardElevated = Color.surfaceCardElevated
        static let secondary = Color.backgroundSecondary
        static let tertiary = Color.backgroundSecondary.opacity(0.5)
        static let selection = Color.actionBreathing.opacity(0.1)
        static let disabled = Color.progressNeutral.opacity(0.3)
    }
    
    // MARK: - Breathing Animation Colors (Softer in Dark Mode)
    struct Breathing {
        static let primary = Color.actionBreathing
        static let secondary = Color.actionCoaching
        static let accent = Color.progressPositive
        static let calm = Color.actionMood
    }
    
    // MARK: - Mode-Specific Helpers
    static func dynamicColor(
        light: Color,
        dark: Color
    ) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // Therapeutic color temperature adjustments
    static func warmDark(_ baseColor: Color, warmth: Double = 0.1) -> Color {
        return baseColor.opacity(1.0 - warmth)
    }
}

// MARK: - Accessibility Extensions
extension AdaptiveColors {
    
    // High contrast versions for accessibility
    struct HighContrast {
        static let background = dynamicColor(
            light: Color.white,
            dark: Color.black
        )
        
        static let text = dynamicColor(
            light: Color.black,
            dark: Color.white
        )
        
        static let accent = dynamicColor(
            light: Color.blue,
            dark: Color.cyan
        )
    }
    
    // Emergency/SOS colors that work in all conditions
    struct Emergency {
        static let background = Color.red
        static let text = Color.white
        static let border = Color.white
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Programmatic Color Definitions
extension Color {
    // Background colors - true black
    static let backgroundPrimary = dynamicColor(
        light: Color(hex: "F7F8FB"),
        dark: Color(hex: "000000")
    )

    static let backgroundSecondary = dynamicColor(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "000000")
    )

    static let meditationBackground = dynamicColor(
        light: Color(hex: "EEF1F7"),
        dark: Color(hex: "000000")
    )
    
    // Text colors tuned for the noir/pink palette
    static let textPrimary = dynamicColor(
        light: Color(hex: "1C1D24"),
        dark: Color(hex: "F5F5F7")
    )
    static let textSecondary = dynamicColor(
        light: Color(hex: "4F5560"),
        dark: Color(hex: "B6B7C4")
    )
    static let textTertiary = dynamicColor(
        light: Color(hex: "8A8D98"),
        dark: Color(hex: "8B8C95")
    )
    static let textEmergency = dynamicColor(
        light: Color.red,
        dark: Color(red: 0.9, green: 0.3, blue: 0.4)
    )
    
    // Action colors remapped to soft pink spectrum
    static let actionBreathing = dynamicColor(
        light: Color(hex: "FF4F9A"),
        dark: Color(hex: "FF4F9A")
    )

    static let actionMood = dynamicColor(
        light: Color(hex: "FF7FBF"),
        dark: Color(hex: "FF7FBF")
    )

    static let actionSOS = dynamicColor(
        light: Color(hex: "FF5C7A"),
        dark: Color(hex: "FF5C7A")
    )

    static let actionCoaching = dynamicColor(
        light: Color(hex: "FF2E84"),
        dark: Color(hex: "FF2E84")
    )
    
    // Progress colors - desaturated for dark mode
    static let progressPositive = dynamicColor(
        light: Color(hex: "FF4F9A"),
        dark: Color(hex: "FF4F9A")
    )

    static let progressNeutral = dynamicColor(
        light: Color(hex: "C7CBD6"),
        dark: Color(hex: "5A5B66")
    )

    static let progressAttention = dynamicColor(
        light: Color(hex: "FF9AC4"),
        dark: Color(hex: "FF9AC4")
    )
    
    // Surface colors with elevation system (lightness communicates depth in dark mode)
    static let surfaceCard = dynamicColor(
        light: Color(hex: "FFFFFF"),
        dark: Color(hex: "121214")
    )

    static let surfaceCardElevated = dynamicColor(
        light: Color(hex: "F1F3F8"),
        dark: Color(hex: "1A1A1D")
    )
    
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
}

// MARK: - Mode Transition Animation
struct ModeTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .animation(
                .easeInOut(duration: 0.4),
                value: UUID() // Triggers on color scheme changes
            )
    }
}

extension View {
    func smoothModeTransitions() -> some View {
        self.modifier(ModeTransitionModifier())
    }
}

// MARK: - Therapeutic Typography
struct TherapeuticTypography {
    
    // Enhanced readability with increased line height using Quicksand
    static let bodyEnhanced = Font.quicksand(
        size: 16,
        weight: .regular
    )
    
    static let captionEnhanced = Font.quicksand(
        size: 13,
        weight: .medium
    )
    
    static let headlineCalm = Font.quicksand(
        size: 20,
        weight: .semibold
    )
    
    static let titleGentle = Font.quicksand(
        size: 24,
        weight: .bold
    )
}

// MARK: - Therapeutic Text Modifiers
extension Text {
    func therapeuticBody() -> some View {
        self
            .font(TherapeuticTypography.bodyEnhanced)
            .lineSpacing(8) // 1.5x line height
            .tracking(0.2) // Subtle letter spacing for dark mode
    }
    
    func therapeuticCaption() -> some View {
        self
            .font(TherapeuticTypography.captionEnhanced)
            .lineSpacing(4)
            .tracking(0.1)
    }
    
    func calmHeadline() -> some View {
        self
            .font(TherapeuticTypography.headlineCalm)
            .lineSpacing(6)
    }
    
    func gentleTitle() -> some View {
        self
            .font(TherapeuticTypography.titleGentle)
            .lineSpacing(8)
    }
}

#if DEBUG
struct AdaptiveColorSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Background preview
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.Background.primary)
                .frame(height: 100)
                .overlay(
                    Text("Primary Background")
                        .foregroundColor(AdaptiveColors.Text.primary)
                        .therapeuticBody()
                )
            
            // Action colors preview
            HStack(spacing: 12) {
                Circle()
                    .fill(AdaptiveColors.Action.breathing)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.mood)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.sos)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.coaching)
                    .frame(width: 44, height: 44)
            }
            
            // Typography preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Gentle Title")
                    .gentleTitle()
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text("This is therapeutic body text with enhanced readability")
                    .therapeuticBody()
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                Text("Caption text for subtle information")
                    .therapeuticCaption()
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }
        }
        .padding()
        .background(AdaptiveColors.Background.secondary)
        .smoothModeTransitions()
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        VStack(spacing: 20) {
            // Same content for dark mode
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.Background.primary)
                .frame(height: 100)
                .overlay(
                    Text("Primary Background")
                        .foregroundColor(AdaptiveColors.Text.primary)
                        .therapeuticBody()
                )
            
            HStack(spacing: 12) {
                Circle()
                    .fill(AdaptiveColors.Action.breathing)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.mood)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.sos)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .fill(AdaptiveColors.Action.coaching)
                    .frame(width: 44, height: 44)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Gentle Title")
                    .gentleTitle()
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text("This is therapeutic body text with enhanced readability")
                    .therapeuticBody()
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                Text("Caption text for subtle information")
                    .therapeuticCaption()
                    .foregroundColor(AdaptiveColors.Text.tertiary)
            }
        }
        .padding()
        .background(AdaptiveColors.Background.secondary)
        .smoothModeTransitions()
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
}
#endif
