//
//  TherapeuticUIComponents.swift
//  anxiety
//
//  Shared UI components for therapeutic design system
//

import SwiftUI

enum CardElevation {
    case flat
    case elevated
    case medium
    case floating
    
    var shadowRadius: CGFloat {
        switch self {
        case .flat: return 0
        case .elevated: return 8
        case .medium: return 12
        case .floating: return 20
        }
    }
    
    var shadowOpacity: Double {
        switch self {
        case .flat: return 0
        case .elevated: return 0.1
        case .medium: return 0.15
        case .floating: return 0.2
        }
    }
}

struct TherapeuticCard<Content: View>: View {
    let elevation: CardElevation
    let content: Content
    let useLiquidGlass: Bool
    
    init(elevation: CardElevation = .elevated, useLiquidGlass: Bool = true, @ViewBuilder content: () -> Content) {
        self.elevation = elevation
        self.useLiquidGlass = useLiquidGlass
        self.content = content()
    }
    
    var body: some View {
        if useLiquidGlass {
            content
                .liquidGlass(
                    intensity: glassIntensity,
                    tintColor: .white,
                    cornerRadius: 20
                )
        } else {
            content
                .background(AdaptiveColors.Background.secondary)
                .cornerRadius(16)
                .shadow(
                    color: Color.black.opacity(elevation.shadowOpacity),
                    radius: elevation.shadowRadius,
                    x: 0,
                    y: elevation == .floating ? 8 : 4
                )
        }
    }
    
    private var glassIntensity: GlassIntensity {
        switch elevation {
        case .flat: return .subtle
        case .elevated: return .medium
        case .medium: return .medium
        case .floating: return .strong
        }
    }
}

struct TherapeuticProgressIndicator: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 8
    let useLiquidGlass: Bool
    
    init(progress: Double, color: Color, height: CGFloat = 8, useLiquidGlass: Bool = true) {
        self.progress = progress
        self.color = color
        self.height = height
        self.useLiquidGlass = useLiquidGlass
    }
    
    var body: some View {
        if useLiquidGlass {
            LiquidGlassProgressBar(progress: progress, color: color, height: height)
        } else {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)))
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: - App-Wide 3D Button Styles

/// Shared color palette for buttons across the app
struct AppButtonColors {
    static let primaryGradient = [
        Color(hex: "FF7A95"),
        Color(hex: "FF5C7A"),
        Color(hex: "D94467")
    ]
    static let primaryShadow = Color(hex: "8B2040")
    static let accentPrimary = Color(hex: "FF5C7A")
    static let accentSecondary = Color(hex: "FF8FA3")
    static let cardBackground = Color(hex: "1A1A1C")
}

/// Primary 3D button style used throughout the app
struct Primary3DButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        configuration.label
            .font(.quicksand(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // 3D Base shadow layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEnabled ? AppButtonColors.primaryShadow : Color.gray.opacity(0.3))
                        .offset(y: isPressed ? 1 : 4)

                    // Main button surface
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isEnabled ?
                            LinearGradient(
                                colors: AppButtonColors.primaryGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: isPressed ? 2 : 0)

                    // Top highlight for 3D effect
                    if isEnabled {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .offset(y: isPressed ? 2 : 0)
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isEnabled ? 0.2 : 0.1), lineWidth: 1)
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(
                color: isEnabled ?
                    AppButtonColors.accentPrimary.opacity(isPressed ? 0.2 : 0.4) :
                    Color.clear,
                radius: isPressed ? 4 : 12,
                x: 0,
                y: isPressed ? 2 : 6
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

/// Secondary 3D button style (for non-selected states)
struct Secondary3DButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        configuration.label
            .font(.quicksand(size: 17, weight: .semibold))
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // 3D Base shadow layer
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppButtonColors.primaryShadow)
                            .offset(y: isPressed ? 1 : 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.4))
                            .offset(y: isPressed ? 1 : 3)
                    }

                    // Main button surface
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: AppButtonColors.primaryGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [
                                    AppButtonColors.cardBackground,
                                    AppButtonColors.cardBackground.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: isPressed ? 2 : 0)

                    // Top highlight for 3D effect
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .offset(y: isPressed ? 2 : 0)
                    }

                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(
                color: isSelected ?
                    AppButtonColors.accentPrimary.opacity(isPressed ? 0.2 : 0.4) :
                    Color.black.opacity(0.2),
                radius: isPressed ? 4 : 12,
                x: 0,
                y: isPressed ? 2 : 6
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Circular 3D button (for back buttons, icons, etc.)
struct Circular3DButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        configuration.label
            .frame(width: size, height: size)
            .background(
                ZStack {
                    // 3D Base shadow
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .offset(y: isPressed ? 1 : 3)

                    // Main surface
                    Circle()
                        .fill(AppButtonColors.cardBackground)
                        .offset(y: isPressed ? 2 : 0)

                    // Border
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(color: Color.black.opacity(0.2), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Smooth Sheet Presentation Modifiers

/// Custom animation for smooth bottom sheet presentations
/// Use this to ensure consistent, buttery-smooth modal animations across the app
extension Animation {
    /// Optimized spring animation for sheet presentations - smooth and responsive
    static var smoothSheet: Animation {
        .spring(response: 0.35, dampingFraction: 0.86, blendDuration: 0)
    }

    /// Slightly faster spring for dismissals
    static var smoothSheetDismiss: Animation {
        .spring(response: 0.3, dampingFraction: 0.82, blendDuration: 0)
    }
}

/// View modifier that applies smooth sheet presentation configuration
struct SmoothSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(.ultraThinMaterial)
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
}

/// View modifier for full-height smooth sheets
struct SmoothFullSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
            .presentationCornerRadius(28)
    }
}

extension View {
    /// Apply smooth sheet styling with optimal animation settings
    func smoothSheet() -> some View {
        modifier(SmoothSheetModifier())
    }

    /// Apply smooth full-height sheet styling
    func smoothFullSheet() -> some View {
        modifier(SmoothFullSheetModifier())
    }
}

// MARK: - Smooth Bottom Modal Presentation

/// A custom bottom modal that slides up with smooth spring animation
/// Use this for custom modals that aren't using the native .sheet modifier
struct SmoothBottomModal<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content

    @State private var dragOffset: CGFloat = 0
    @State private var contentAppeared = false

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background overlay
                if contentAppeared {
                    Color.black
                        .opacity(0.4 * Double(1 - dragOffset / 300))
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissModal()
                        }
                        .transition(.opacity)
                }

                // Modal content
                if contentAppeared {
                    content
                        .frame(maxWidth: .infinity)
                        .offset(y: max(0, dragOffset))
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 100 || value.predictedEndTranslation.height > 200 {
                                        dismissModal()
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onChange(of: isPresented) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    contentAppeared = true
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    contentAppeared = false
                    dragOffset = 0
                }
            }
        }
        .onAppear {
            if isPresented {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    contentAppeared = true
                }
            }
        }
    }

    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            contentAppeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            dragOffset = 0
        }
    }
}
