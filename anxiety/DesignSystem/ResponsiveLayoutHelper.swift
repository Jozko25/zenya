//
//  ResponsiveLayoutHelper.swift
//  anxiety
//
//  Helper utilities for responsive layouts across all device sizes
//

import SwiftUI

// MARK: - Device Size Detection

enum DeviceType {
    case phone      // iPhone
    case tablet     // iPad

    static func current(width: CGFloat) -> DeviceType {
        return width >= 768 ? .tablet : .phone
    }
}

// MARK: - Responsive Layout Extension

extension View {
    /// Makes the view responsive by providing device dimensions
    func responsiveFrame(alignment: Alignment = .center) -> some View {
        GeometryReader { geometry in
            self
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: alignment
                )
                .environment(\.deviceWidth, geometry.size.width)
                .environment(\.deviceHeight, geometry.size.height)
        }
    }

    /// Adds responsive padding based on device size
    func responsivePadding(_ edges: Edge.Set = .all) -> some View {
        GeometryReader { geometry in
            self.padding(edges, CGFloat.DS.padding(for: geometry.size.width))
        }
    }
}

// MARK: - Environment Keys for Device Dimensions

private struct DeviceWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 390 // iPhone 14 Pro width
}

private struct DeviceHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 844 // iPhone 14 Pro height
}

extension EnvironmentValues {
    var deviceWidth: CGFloat {
        get { self[DeviceWidthKey.self] }
        set { self[DeviceWidthKey.self] = newValue }
    }

    var deviceHeight: CGFloat {
        get { self[DeviceHeightKey.self] }
        set { self[DeviceHeightKey.self] = newValue }
    }
}

// MARK: - Responsive Container

struct ResponsiveContainer<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat?

    init(maxWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let deviceType = DeviceType.current(width: geometry.size.width)
            let computedMaxWidth: CGFloat = {
                if let maxWidth = maxWidth {
                    return maxWidth
                }
                // Use full width on tablets, constrained on phones
                return deviceType == .tablet ? .infinity : min(geometry.size.width, 480)
            }()

            content
                .frame(maxWidth: computedMaxWidth)
                .frame(maxWidth: .infinity) // Center the container
                .environment(\.deviceWidth, geometry.size.width)
                .environment(\.deviceHeight, geometry.size.height)
        }
    }
}

// MARK: - Adaptive Typography

extension Font {
    /// Returns a scaled font based on device size
    static func adaptive(_ style: Font.DS.Style, for width: CGFloat) -> Font {
        let scaleFactor: CGFloat = width >= 768 ? 1.2 : 1.0 // 20% larger on tablets

        switch style {
        case .hero:
            return .system(size: 32 * scaleFactor, weight: .bold)
        case .h1:
            return .system(size: 24 * scaleFactor, weight: .bold)
        case .h2:
            return .system(size: 18 * scaleFactor, weight: .semibold)
        case .body:
            return .system(size: 16 * scaleFactor, weight: .regular)
        case .small:
            return .system(size: 14 * scaleFactor, weight: .medium)
        }
    }
}

extension Font.DS {
    enum Style {
        case hero, h1, h2, body, small
    }
}
