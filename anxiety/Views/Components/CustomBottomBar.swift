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

                // Very subtle glass overlay
                Capsule()
                    .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.15 : 0.4))

                // Subtle inner gradient
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.7),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Border
                Capsule()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "E8E8EA"),
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            CustomBottomBar(selectedTab: .constant(0))
        }
    }
}
