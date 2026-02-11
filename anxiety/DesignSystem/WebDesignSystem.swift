//
//  DesignSystem.swift
//  anxiety
//
//  Unified design system matching web app
//

import SwiftUI

// MARK: - Colors

extension Color {
    struct DS {
        // Primary Colors
        static let lavender = Color(hex: "7C6FDC")
        static let softPurple = Color(hex: "A598F0")
        static let mint = Color(hex: "8FD4C1")
        static let cream = Color(hex: "FAF8FF")
        static let wellnessOrange = Color(hex: "FF9F5A")
        static let wellnessGreen = Color(hex: "6FCF97")
        
        // Text Colors
        static let textPrimary = Color(hex: "0F0F14")
        static let textSecondary = Color(hex: "5F6378")
        static let textTertiary = Color(hex: "9CA3AF")
        
        // Background Colors (Light)
        static let background = Color(hex: "FFFFFF")
        static let lightSecondary = Color(hex: "F8F9FC")
        static let lightTertiary = Color(hex: "F3F4F8")
        
        // Dark Mode Colors
        static let darkBg = Color(hex: "0F0F14")
        static let darkSecondary = Color(hex: "1A1A23")
        static let darkTertiary = Color(hex: "23232E")
        static let darkTextPrimary = Color(hex: "F8F9FC")
        static let darkTextSecondary = Color(hex: "B8BCCF")
        static let darkTextTertiary = Color(hex: "6B7280")
        
        // Adaptive Colors
        static func text(_ level: TextLevel, for colorScheme: ColorScheme) -> Color {
            switch level {
            case .primary:
                return colorScheme == .dark ? darkTextPrimary : textPrimary
            case .secondary:
                return colorScheme == .dark ? darkTextSecondary : textSecondary
            case .tertiary:
                return colorScheme == .dark ? darkTextTertiary : textTertiary
            }
        }
        
        static func bg(_ level: BGLevel, for colorScheme: ColorScheme) -> Color {
            switch level {
            case .primary:
                return colorScheme == .dark ? darkBg : background
            case .secondary:
                return colorScheme == .dark ? darkSecondary : lightSecondary
            case .tertiary:
                return colorScheme == .dark ? darkTertiary : lightTertiary
            }
        }
        
        enum TextLevel {
            case primary, secondary, tertiary
        }
        
        enum BGLevel {
            case primary, secondary, tertiary
        }
    }
}

// MARK: - Typography

extension Font {
    struct DS {
        // Hero
        static let hero = Font.system(size: 32, weight: .bold, design: .default)
        static var heroLineHeight: CGFloat { 38.4 } // 1.2
        static var heroLetterSpacing: CGFloat { -0.64 } // -0.02em
        
        // H1
        static let h1 = Font.system(size: 24, weight: .bold, design: .default)
        static var h1LineHeight: CGFloat { 31.2 } // 1.3
        static var h1LetterSpacing: CGFloat { -0.24 } // -0.01em
        
        // H2
        static let h2 = Font.system(size: 18, weight: .semibold, design: .default)
        static var h2LineHeight: CGFloat { 25.2 } // 1.4
        
        // Body
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static var bodyLineHeight: CGFloat { 25.6 } // 1.6
        
        // Small
        static let small = Font.system(size: 14, weight: .medium, design: .default)
        static var smallLineHeight: CGFloat { 21 } // 1.5
    }
}

// MARK: - Spacing

extension CGFloat {
    struct DS {
        // Adaptive container width - uses full width on tablets, max 480 on phones
        static func containerMaxWidth(for screenWidth: CGFloat) -> CGFloat {
            // iPad detection: wider than 768pt
            if screenWidth >= 768 {
                return .infinity // Use full width on tablets
            } else {
                return Swift.min(screenWidth, 480) // Max 480pt on phones
            }
        }

        // Legacy fixed width for compatibility (can be removed if not used)
        static let containerMaxWidth: CGFloat = 480

        // Adaptive padding based on device size
        static func padding(for screenWidth: CGFloat) -> CGFloat {
            if screenWidth >= 768 {
                return 32 // More padding on tablets
            } else if screenWidth >= 390 {
                return 20 // Standard padding on larger phones
            } else {
                return 16 // Less padding on smaller phones
            }
        }

        static let padding: CGFloat = 20

        // Border Radius
        static let radiusButton: CGFloat = 12
        static let radiusCard: CGFloat = 16
        static let radiusLargeCard: CGFloat = 24
        static let radiusFull: CGFloat = 999

        // Button Heights
        static let buttonHeightMin: CGFloat = 48
        static let buttonHeightMax: CGFloat = 56

        // Spacing Scale
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
}

// MARK: - Shadows

enum DSShadowStyle {
    case subtle
    case medium
    case large
}

extension View {
    func dsShadow(_ style: DSShadowStyle) -> some View {
        switch style {
        case .subtle:
            return AnyView(self.shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2))
        case .medium:
            return AnyView(self.shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4))
        case .large:
            return AnyView(self.shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 8))
        }
    }
}

// MARK: - Animations

extension Animation {
    struct DS {
        static let quick = Animation.easeOut(duration: 0.1)
        static let standard = Animation.easeOut(duration: 0.2)
        static let smooth = Animation.easeOut(duration: 0.3)
    }
}

// MARK: - Gradients

extension LinearGradient {
    struct DS {
        static let primary = LinearGradient(
            colors: [Color.DS.lavender, Color.DS.softPurple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
