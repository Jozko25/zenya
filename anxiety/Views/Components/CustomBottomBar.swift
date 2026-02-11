//
//  CustomBottomBar.swift
//  anxiety
//
//  Created by Ján Harmady on 03/12/2025.
//

import SwiftUI

struct CustomBottomBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme

    private let tabs = [
        (icon: "circle.grid.2x2", selectedIcon: "circle.grid.2x2.fill", label: "Home", hint: "View dashboard and quick actions"),
        (icon: "heart", selectedIcon: "heart.fill", label: "Heart", hint: "Track your mood and journal"),
        (icon: "bubble.left.and.bubble.right", selectedIcon: "bubble.left.and.bubble.right.fill", label: "Chat", hint: "Talk with AI coach"),
        (icon: "waveform.path.ecg", selectedIcon: "waveform.path.ecg", label: "Breathe", hint: "Start breathing exercise")
    ]

    private var accentColor: Color {
        Color(hex: "FF5C7A")
    }

    private var selectedColor: Color {
        colorScheme == .dark ? .white : accentColor
    }

    private var unselectedColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.4) : Color(hex: "8E8E93")
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    let generator = UIImpactFeedbackGenerator(style: .soft)
                    generator.impactOccurred()
                }) {
                    Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(selectedTab == index ? selectedColor : unselectedColor)
                        .frame(maxWidth: .infinity)
                        .symbolEffect(.bounce.down, value: selectedTab == index)
                }
                .accessibilityLabel(tabs[index].label)
                .accessibilityHint(tabs[index].hint)
                .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .frame(height: 64)
        .background(
            ZStack {
                // Solid dark base
                Capsule()
                    .fill(colorScheme == .dark ? Color(hex: "0D0D0D") : Color(hex: "F8F8FA"))

                // Grainy texture overlay
                Capsule()
                    .fill(Color.clear)
                    .overlay(
                        BottomBarGrainTexture(intensity: colorScheme == .dark ? 0.25 : 0.1)
                            .clipShape(Capsule())
                    )

                // Subtle inner gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Border
                Capsule()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E8E8EA"),
                        lineWidth: 0.5
                    )
            }
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.5) : accentColor.opacity(0.12),
                radius: 20,
                x: 0,
                y: 10
            )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 2)
    }
}

// MARK: - Grain Texture for Bottom Bar

struct BottomBarGrainTexture: View {
    let intensity: Double

    var body: some View {
        Image(uiImage: generateNoiseImage())
            .resizable()
            .opacity(intensity)
            .blendMode(.overlay)
    }

    private func generateNoiseImage() -> UIImage {
        let size = CGSize(width: 150, height: 50)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(UIColor.clear.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            for _ in 0..<1500 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let gray = CGFloat.random(in: 0.3...0.7)
                let alpha = CGFloat.random(in: 0.08...0.2)

                context.setFillColor(UIColor(white: gray, alpha: alpha).cgColor)
                context.fillEllipse(in: CGRect(x: x, y: y, width: 1.2, height: 1.2))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            CustomBottomBar(selectedTab: .constant(0))
        }
    }
}
