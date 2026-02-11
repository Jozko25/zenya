//
//  ConsolidatedRewardsView.swift
//  anxiety
//
//  Achievement celebration inspired by Apple Design Award winners
//  Reference: Any Distance app, Headspace, modern iOS patterns
//

import SwiftUI

// MARK: - Reward Item Type

enum RewardItem: Identifiable {
    case achievement(JournalAchievement)
    case bonus(Int)
    case levelUp(LevelUpInfo)

    var id: String {
        switch self {
        case .achievement(let a): return "achievement-\(a.id)"
        case .bonus(let points): return "bonus-\(points)-\(UUID().uuidString)"
        case .levelUp(let info): return "levelUp-\(info.newLevel.level)"
        }
    }

    var points: Int {
        switch self {
        case .achievement(let a): return a.points
        case .bonus(let p): return p
        case .levelUp(_): return 0
        }
    }
}

// MARK: - Consolidated Rewards View

struct ConsolidatedRewardsView: View {
    let rewards: [RewardItem]
    let onDismiss: () -> Void

    @State private var isPresented = false
    @State private var headerScale: CGFloat = 0.8
    @State private var headerOpacity: Double = 0
    @State private var listOffset: CGFloat = 30
    @State private var listOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    @Environment(\.colorScheme) var colorScheme

    private let accent = Color(hex: "FF5C7A")
    private let accentLight = Color(hex: "FF8FA3")
    private let accentDark = Color(hex: "A34865")

    var totalPoints: Int {
        rewards.reduce(0) { $0 + $1.points }
    }

    var body: some View {
        ZStack {
            // Background
            Color.black
                .opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
                .animation(.easeOut(duration: 0.3), value: isPresented)

            // Card
            cardContent
                .opacity(isPresented ? 1 : 0)
                .scaleEffect(isPresented ? 1 : 0.95)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isPresented)
        }
        .onAppear {
            presentWithSequence()
        }
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header with medal/icon
            headerView
                .scaleEffect(headerScale)
                .opacity(headerOpacity)

            // Rewards list
            rewardsList
                .offset(y: listOffset)
                .opacity(listOpacity)
                .padding(.top, 24)

            // Total & Button
            footerView
                .offset(y: buttonOffset)
                .opacity(buttonOpacity)
                .padding(.top, 20)
                .padding(.bottom, 28)
        }
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(colorScheme == .dark ? Color(hex: "18181A") : Color.white)
                .overlay(
                    // Subtle top highlight
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 40, y: 20)
        )
        .padding(.horizontal, 20)
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            // Achievement medal/badge
            ZStack {
                // Soft glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // Medal circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentLight, accent, accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .blur(radius: 1)
                    )
                    .shadow(color: accent.opacity(0.4), radius: 20, y: 10)

                // Icon
                Image(systemName: rewards.count > 1 ? "star.fill" : iconForFirstReward)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Title
            Text(rewards.count == 1 ? titleForFirstReward : "Rewards Unlocked")
                .font(.quicksand(size: 22, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                .multilineTextAlignment(.center)

            // Subtitle for single achievement
            if rewards.count == 1, let subtitle = subtitleForFirstReward {
                Text(subtitle)
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var rewardsList: some View {
        VStack(spacing: 8) {
            if rewards.count > 1 {
                ForEach(rewards) { reward in
                    rewardRow(for: reward)
                }
            }
        }
    }

    private func rewardRow(for reward: RewardItem) -> some View {
        HStack(spacing: 14) {
            // Icon circle
            Circle()
                .fill(accent.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: iconName(for: reward))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                )

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: reward))
                    .font(.quicksand(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))

                if let sub = shortSubtitle(for: reward) {
                    Text(sub)
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : Color(hex: "999999"))
                }
            }

            Spacer()

            // Points
            if reward.points > 0 {
                Text("+\(reward.points)")
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color(hex: "FFF7F8"))
        )
    }

    private var footerView: some View {
        VStack(spacing: 16) {
            // Total points
            if totalPoints > 0 {
                HStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(accent)

                    Text("\(totalPoints) points earned")
                        .font(.quicksand(size: 15, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : Color(hex: "666666"))
                }
            }

            // Claim button
            Button(action: dismiss) {
                Text("Continue")
                    .font(.quicksand(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accent, accentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: accent.opacity(0.35), radius: 16, y: 8)
                    )
            }
        }
    }

    // MARK: - Helpers

    private var iconForFirstReward: String {
        guard let first = rewards.first else { return "star.fill" }
        return iconName(for: first)
    }

    private var titleForFirstReward: String {
        guard let first = rewards.first else { return "Achievement Unlocked" }
        return title(for: first)
    }

    private var subtitleForFirstReward: String? {
        guard let first = rewards.first else { return nil }
        switch first {
        case .achievement(let a): return a.description
        case .bonus(let p): return "+\(p) bonus points"
        case .levelUp(let info): return "You've reached \(info.newLevel.title)"
        }
    }

    private func iconName(for reward: RewardItem) -> String {
        switch reward {
        case .achievement(let a): return a.icon
        case .bonus(_): return "sparkles"
        case .levelUp(_): return "arrow.up.circle.fill"
        }
    }

    private func title(for reward: RewardItem) -> String {
        switch reward {
        case .achievement(let a): return a.title
        case .bonus(_): return "Bonus Points"
        case .levelUp(let info): return "Level \(info.newLevel.level)"
        }
    }

    private func shortSubtitle(for reward: RewardItem) -> String? {
        switch reward {
        case .achievement(let a): return a.description
        case .bonus(_): return nil
        case .levelUp(let info): return info.newLevel.title
        }
    }

    // MARK: - Animation

    private func presentWithSequence() {
        // Initial haptic
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        // Show card
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            isPresented = true
        }

        // Staggered content reveal
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
            headerScale = 1.0
            headerOpacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.25)) {
            listOffset = 0
            listOpacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.35)) {
            buttonOffset = 0
            buttonOpacity = 1.0
        }

        // Success haptic after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func dismiss() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
            headerOpacity = 0
            listOpacity = 0
            buttonOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Manager

@MainActor
class ConsolidatedRewardsManager: ObservableObject {
    @Published var pendingRewards: [RewardItem] = []
    @Published var showRewards = false

    private var processingDelay: Task<Void, Never>?

    func addReward(_ reward: RewardItem) {
        pendingRewards.append(reward)

        processingDelay?.cancel()
        processingDelay = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            if !pendingRewards.isEmpty {
                showRewards = true
            }
        }
    }

    func dismiss() {
        showRewards = false
        pendingRewards.removeAll()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ConsolidatedRewardsView(
            rewards: [
                .achievement(JournalAchievement.achievements[0]),
                .achievement(JournalAchievement.achievements[1]),
                .bonus(50)
            ],
            onDismiss: {}
        )
    }
}
