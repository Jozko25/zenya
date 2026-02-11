import SwiftUI

struct SoulPalette {
    let backgroundTop: Color
    let backgroundBottom: Color
    let accent: Color
    let accentSecondary: Color
    let accentMuted: Color
    let surface: Color
    let surfaceAlt: Color
    let outline: Color
    let glow: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    static let neon = SoulPalette(
        backgroundTop: Color(hex: "0A0612"),
        backgroundBottom: Color(hex: "1A0F1F"),
        accent: Color(hex: "FF4F9A"),
        accentSecondary: Color(hex: "FF7FBF"),
        accentMuted: Color(hex: "FF2E84"),
        surface: Color(hex: "1C1520"),
        surfaceAlt: Color(hex: "251A2A"),
        outline: Color(hex: "3A2F42"),
        glow: Color(hex: "FF478F"),
        textPrimary: Color(hex: "F8F6FA"),
        textSecondary: Color(hex: "D1C9DB"),
        textTertiary: Color(hex: "9B8FA8")
    )

    static let light = SoulPalette(
        backgroundTop: Color(hex: "FFF0F7"),
        backgroundBottom: Color(hex: "FFE3EC"),
        accent: Color(hex: "FF5C7A"),
        accentSecondary: Color(hex: "FF8FA3"),
        accentMuted: Color(hex: "A34865"),
        surface: Color.white,
        surfaceAlt: Color(hex: "FFF8FA"),
        outline: Color(hex: "FF5C7A").opacity(0.15),
        glow: Color(hex: "FF5C7A"),
        textPrimary: Color(hex: "1A1A1A"),
        textSecondary: Color(hex: "666666"),
        textTertiary: Color(hex: "999999")
    )

    static func forColorScheme(_ colorScheme: ColorScheme) -> SoulPalette {
        colorScheme == .dark ? .neon : .light
    }
}
