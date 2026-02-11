//
//  JournalAchievementsView.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import SwiftUI

struct JournalAchievementsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var gameStatsManager = JournalGameStatsManager.shared
    
    @State private var selectedCategory: AchievementCategory = .all
    
    enum AchievementCategory: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case inProgress = "In Progress"
        case locked = "Locked"
        
        var icon: String {
            switch self {
            case .all: return "trophy.fill"
            case .unlocked: return "checkmark.circle.fill"
            case .inProgress: return "clock.fill"
            case .locked: return "lock.fill"
            }
        }
    }
    
    var filteredAchievements: [JournalAchievement] {
        let stats = gameStatsManager.gameStats
        
        return JournalAchievement.achievements.filter { achievement in
            let isUnlocked = stats.unlockedAchievements.contains(achievement.id)
            let progress = getAchievementProgress(achievement, stats: stats)
            let isInProgress = progress > 0 && progress < 1.0
            
            switch selectedCategory {
            case .all: return true
            case .unlocked: return isUnlocked
            case .inProgress: return isInProgress
            case .locked: return !isUnlocked && !isInProgress
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Category Filter
                categoryFilter
                
                // Achievements List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAchievements, id: \.id) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                progress: getAchievementProgress(achievement, stats: gameStatsManager.gameStats),
                                isUnlocked: gameStatsManager.gameStats.unlockedAchievements.contains(achievement.id)
                            )
                        }
                        
                        if filteredAchievements.isEmpty {
                            emptyStateView
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Top Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Text("Achievements")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Trophy count
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "FF5C7A"))

                    Text("\(gameStatsManager.gameStats.unlockedAchievements.count)/\(JournalAchievement.achievements.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "1A1A1C"))
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "FF5C7A").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            
            // Overall Progress
            let overallProgress = Double(gameStatsManager.gameStats.unlockedAchievements.count) / Double(JournalAchievement.achievements.count)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Overall Progress")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))

                    Spacer()

                    Text("\(Int(overallProgress * 100))% Complete")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "FF5C7A"))
                }

                // Custom Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FF8FA3"),
                                        Color(hex: "FF5C7A")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * overallProgress, 0), height: 8)
                            .shadow(color: Color(hex: "FF5C7A").opacity(0.5), radius: 4, x: 0, y: 0)
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1A1C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: getCountForCategory(category),
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 48))
                .foregroundColor(Color.white.opacity(0.2))
            
            Text("No \(selectedCategory.rawValue) Achievements")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Keep journaling to unlock new achievements!")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Methods
    
    private func getAchievementProgress(_ achievement: JournalAchievement, stats: JournalGameStats) -> Double {
        if stats.unlockedAchievements.contains(achievement.id) {
            return 1.0
        }
        
        switch achievement.requirement {
        case .firstEntry:
            return stats.totalEntries > 0 ? 1.0 : 0.0
            
        case .streak(let days):
            return min(Double(stats.currentStreak) / Double(days), 1.0)
            
        case .totalEntries(let count):
            return min(Double(stats.totalEntries) / Double(count), 1.0)
            
        case .moodImprovement:
            return 0.0
            
        case .gratitudePractice:
            return 0.0
            
        case .reflectionDepth:
            return 0.0
            
        case .consistency:
            return 0.0
            
        case .timeOfDay(_, _, _):
            // Simplified progress for time-based achievements
            return stats.totalEntries >= 5 ? 0.6 : 0.0
            
        case .weekendConsistency(_):
            // Simplified progress for weekend consistency
            return stats.currentStreak >= 4 ? 0.8 : 0.0
            
        case .voiceUsage(let count):
            let currentUsage = UserDefaults.standard.integer(forKey: "journal_voice_usage_count")
            return min(Double(currentUsage) / Double(count), 1.0)
            
        case .moodTracking(let count):
            let currentMoodCount = UserDefaults.standard.integer(forKey: "journal_mood_tracking_count")
            return min(Double(currentMoodCount) / Double(count), 1.0)
            
        case .positiveMood(let count):
            let currentMoodCount = UserDefaults.standard.integer(forKey: "journal_mood_tracking_count")
            return min(Double(currentMoodCount) / Double(count), 0.8)
        }
    }
    
    private func getCountForCategory(_ category: AchievementCategory) -> Int {
        let stats = gameStatsManager.gameStats
        
        return JournalAchievement.achievements.filter { achievement in
            let isUnlocked = stats.unlockedAchievements.contains(achievement.id)
            let progress = getAchievementProgress(achievement, stats: stats)
            let isInProgress = progress > 0 && progress < 1.0
            
            switch category {
            case .all: return true
            case .unlocked: return isUnlocked
            case .inProgress: return isInProgress
            case .locked: return !isUnlocked && !isInProgress
            }
        }.count
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: JournalAchievementsView.AchievementCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "FF5C7A") : Color(hex: "1A1A1C"))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct AchievementCard: View {
    let achievement: JournalAchievement
    let progress: Double
    let isUnlocked: Bool
    
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            HStack(spacing: 16) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked ? achievement.color.opacity(0.2) : Color.white.opacity(0.05)
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    isUnlocked ? achievement.color.opacity(0.5) : Color.white.opacity(0.05),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(
                            isUnlocked ? achievement.color : Color.white.opacity(0.3)
                        )
                    
                    if isUnlocked {
                        // Sparkle effect for unlocked achievements
                        Circle()
                            .stroke(achievement.color.opacity(0.3), lineWidth: 2)
                            .frame(width: 70, height: 70)
                            .scaleEffect(1.1)
                            .opacity(0.5)
                    }
                }
                
                // Achievement Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(achievement.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(
                                isUnlocked ? .white : Color.white.opacity(0.6)
                            )
                        
                        Spacer()
                        
                        // Points
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "FF5C7A"))

                            Text("+\(achievement.points)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "FF5C7A"))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "FF5C7A").opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Text(achievement.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Progress Bar (if not unlocked)
                    if !isUnlocked && progress > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Progress")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.4))
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "FF5C7A"))
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(Color(hex: "FF5C7A"))
                                        .frame(width: max(geometry.size.width * progress, 0), height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.top, 4)
                    }
                }
                
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FF5C7A"))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1A1A1C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            AchievementDetailView(achievement: achievement, isUnlocked: isUnlocked, progress: progress)
                .presentationCornerRadius(28)
        }
    }
}

struct AchievementDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let achievement: JournalAchievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Large Achievement Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    achievement.color.opacity(0.2),
                                    achievement.color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(achievement.color.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(achievement.color)
                    
                    if isUnlocked {
                        ForEach(0..<6, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "FF5C7A"))
                                .offset(
                                    x: CGFloat(cos(Double(index) * .pi / 3)) * 60,
                                    y: CGFloat(sin(Double(index) * .pi / 3)) * 60
                                )
                                .opacity(0.6)
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    Text(achievement.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(achievement.description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Status
                    HStack(spacing: 12) {
                        if isUnlocked {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "FF5C7A"))
                                Text("Unlocked")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "FF5C7A"))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "FF5C7A").opacity(0.1))
                            .cornerRadius(20)
                        } else if progress > 0 {
                            VStack(spacing: 8) {
                                Text("\(Int(progress * 100))% Complete")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "FF5C7A"))
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 6)
                                        
                                        Capsule()
                                            .fill(Color(hex: "FF5C7A"))
                                            .frame(width: max(geometry.size.width * progress, 0), height: 6)
                                    }
                                }
                                .frame(width: 200, height: 6)
                            }
                        } else {
                            Text("Locked")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                        }
                    }
                    
                    // Points
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "FF5C7A"))

                        Text("+\(achievement.points) Points")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "FF5C7A"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "FF5C7A").opacity(0.1))
                    .cornerRadius(16)
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
    }
}

struct AchievementUnlockedView: View {
    let achievement: JournalAchievement
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var sparkleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 24) {
                // Achievement unlocked text
                Text("Achievement Unlocked!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                // Achievement card
                VStack(spacing: 24) {
                    // Icon with sparkle effect
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [achievement.color.opacity(0.2), achievement.color.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(achievement.color.opacity(0.5), lineWidth: 1)
                            )
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(achievement.color)
                        
                        // Sparkle effects
                        ForEach(0..<6, id: \.self) { index in
                            Image(systemName: "sparkle")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FF5C7A"))
                                .offset(
                                    x: CGFloat(cos(Double(index) * .pi / 3)) * (50 + sparkleOffset),
                                    y: CGFloat(sin(Double(index) * .pi / 3)) * (50 + sparkleOffset)
                                )
                                .opacity(0.8)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Text(achievement.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        // Points earned
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "FF5C7A"))

                            Text("+\(achievement.points) Points!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "FF5C7A"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(hex: "FF5C7A").opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: onDismiss) {
                        Text("Awesome!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "FF5C7A"))
                            )
                    }
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "1A1A1C"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .scaleEffect(scale)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                sparkleOffset = 10
            }
            
            // Auto dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}

#Preview {
    JournalAchievementsView()
}