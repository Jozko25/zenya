//
//  GamifiedJournalModels.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import Foundation
import SwiftUI

// MARK: - Gamification Models

struct JournalGameStats {
    var totalEntries: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalPoints: Int = 0
    var pointsEarnedToday: Int = 0
    var level: Int = 1
    var unlockedAchievements: Set<String> = []
    var weeklyGoal: Int = 3
    var monthlyGoal: Int = 12
    var lastEntryDate: Date? = nil
}

struct JournalAchievement {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let points: Int
    let requirement: AchievementRequirement
    
    enum AchievementRequirement {
        case firstEntry
        case streak(days: Int)
        case totalEntries(count: Int)
        case moodImprovement(points: Int)
        case gratitudePractice(days: Int)
        case reflectionDepth(words: Int)
        case consistency(weeks: Int)
        case timeOfDay(before: Int?, after: Int?, count: Int)
        case weekendConsistency(weeks: Int)
        case voiceUsage(count: Int)
        case moodTracking(count: Int)
        case positiveMood(count: Int)
    }
    
    static let achievements: [JournalAchievement] = [
        // Entry Milestones
        JournalAchievement(
            id: "first_steps",
            title: "First Steps",
            description: "Write your first journal entry",
            icon: "star.circle.fill",
            color: AdaptiveColors.Action.breathing,
            points: 50,
            requirement: .firstEntry
        ),
        JournalAchievement(
            id: "getting_started",
            title: "Getting Started",
            description: "Write 3 journal entries",
            icon: "book.pages.fill",
            color: AdaptiveColors.Action.mood,
            points: 75,
            requirement: .totalEntries(count: 3)
        ),
        JournalAchievement(
            id: "weekly_explorer",
            title: "Weekly Explorer",
            description: "Write 7 journal entries",
            icon: "calendar.badge.checkmark",
            color: AdaptiveColors.Action.progress,
            points: 100,
            requirement: .totalEntries(count: 7)
        ),
        JournalAchievement(
            id: "dedicated_writer",
            title: "Dedicated Writer", 
            description: "Write 15 journal entries",
            icon: "doc.text.fill",
            color: AdaptiveColors.Action.coaching,
            points: 200,
            requirement: .totalEntries(count: 15)
        ),
        JournalAchievement(
            id: "monthly_warrior",
            title: "Monthly Warrior",
            description: "Complete 30 journal entries",
            icon: "crown.fill",
            color: Color(hex: "FFD700"),
            points: 500,
            requirement: .totalEntries(count: 30)
        ),
        
        // Streak Achievements
        JournalAchievement(
            id: "streak_starter",
            title: "Streak Starter",
            description: "Maintain a 3-day journaling streak",
            icon: "flame.fill",
            color: AdaptiveColors.Action.sos,
            points: 100,
            requirement: .streak(days: 3)
        ),
        JournalAchievement(
            id: "streak_master",
            title: "Streak Master",
            description: "Maintain a 7-day journaling streak",
            icon: "flame.fill",
            color: AdaptiveColors.Action.sos,
            points: 200,
            requirement: .streak(days: 7)
        ),
        JournalAchievement(
            id: "streak_champion",
            title: "Streak Champion",
            description: "Maintain a 14-day journaling streak",
            icon: "flame.fill",
            color: Color(hex: "FF4500"),
            points: 350,
            requirement: .streak(days: 14)
        ),
        JournalAchievement(
            id: "streak_legend",
            title: "Streak Legend",
            description: "Maintain a 30-day journaling streak",
            icon: "flame.fill",
            color: Color(hex: "FF0000"),
            points: 750,
            requirement: .streak(days: 30)
        ),
        
        // Time-based Achievements
        JournalAchievement(
            id: "morning_person",
            title: "Morning Person",
            description: "Write 5 entries before 10 AM",
            icon: "sun.max.fill",
            color: Color(hex: "FFA500"),
            points: 150,
            requirement: .timeOfDay(before: 10, after: nil, count: 5)
        ),
        JournalAchievement(
            id: "night_owl",
            title: "Night Owl", 
            description: "Write 5 entries after 8 PM",
            icon: "moon.stars.fill",
            color: Color(hex: "4A90E2"),
            points: 150,
            requirement: .timeOfDay(before: nil, after: 20, count: 5)
        ),
        JournalAchievement(
            id: "weekend_warrior",
            title: "Weekend Warrior",
            description: "Journal for 4 weekends in a row",
            icon: "calendar.badge.plus",
            color: AdaptiveColors.Action.progress,
            points: 200,
            requirement: .weekendConsistency(weeks: 4)
        ),
        
        // Content Quality Achievements
        JournalAchievement(
            id: "thoughtful_writer",
            title: "Thoughtful Writer",
            description: "Write an entry with over 100 words",
            icon: "text.alignleft",
            color: AdaptiveColors.Action.coaching,
            points: 75,
            requirement: .reflectionDepth(words: 100)
        ),
        JournalAchievement(
            id: "deep_thinker",
            title: "Deep Thinker",
            description: "Write a journal entry with over 300 words",
            icon: "brain.head.profile.fill",
            color: AdaptiveColors.Action.coaching,
            points: 150,
            requirement: .reflectionDepth(words: 300)
        ),
        JournalAchievement(
            id: "philosopher",
            title: "Philosopher",
            description: "Write a journal entry with over 500 words",
            icon: "quote.bubble.fill",
            color: Color(hex: "8A2BE2"),
            points: 250,
            requirement: .reflectionDepth(words: 500)
        ),
        
        // Voice & Technology
        JournalAchievement(
            id: "voice_explorer",
            title: "Voice Explorer",
            description: "Use voice dictation for the first time",
            icon: "waveform.circle.fill",
            color: AdaptiveColors.Action.mood,
            points: 100,
            requirement: .voiceUsage(count: 1)
        ),
        JournalAchievement(
            id: "voice_master",
            title: "Voice Master",
            description: "Use voice dictation 10 times",
            icon: "mic.fill",
            color: AdaptiveColors.Action.mood,
            points: 200,
            requirement: .voiceUsage(count: 10)
        ),
        
        // Mood & Wellness
        JournalAchievement(
            id: "mood_tracker",
            title: "Mood Tracker",
            description: "Log your mood 5 times",
            icon: "chart.line.uptrend.xyaxis.circle.fill",
            color: AdaptiveColors.Action.progress,
            points: 100,
            requirement: .moodTracking(count: 5)
        ),
        JournalAchievement(
            id: "positive_vibes",
            title: "Positive Vibes",
            description: "Log 10 positive moods (7+ rating)",
            icon: "sun.max.circle.fill",
            color: Color(hex: "32CD32"),
            points: 200,
            requirement: .positiveMood(count: 10)
        ),
        JournalAchievement(
            id: "mood_lifter",
            title: "Mood Lifter",
            description: "Show positive mood improvement over 2 weeks",
            icon: "arrow.up.heart.fill",
            color: AdaptiveColors.Action.breathing,
            points: 300,
            requirement: .moodImprovement(points: 10)
        ),
        
        // Gratitude & Mindfulness
        JournalAchievement(
            id: "gratitude_beginner",
            title: "Gratitude Beginner",
            description: "Practice gratitude 3 times",
            icon: "heart.text.square.fill",
            color: AdaptiveColors.Action.progress,
            points: 100,
            requirement: .gratitudePractice(days: 3)
        ),
        JournalAchievement(
            id: "gratitude_guru",
            title: "Gratitude Guru",
            description: "Practice gratitude for 7 consecutive days",
            icon: "heart.fill",
            color: AdaptiveColors.Action.progress,
            points: 200,
            requirement: .gratitudePractice(days: 7)
        ),
        JournalAchievement(
            id: "gratitude_master",
            title: "Gratitude Master",
            description: "Practice gratitude for 14 consecutive days",
            icon: "hands.sparkles.fill",
            color: Color(hex: "FF69B4"),
            points: 350,
            requirement: .gratitudePractice(days: 14)
        ),
        
        // Consistency & Dedication
        JournalAchievement(
            id: "weekly_consistent",
            title: "Weekly Consistent",
            description: "Journal regularly for 1 week",
            icon: "checkmark.circle.fill",
            color: AdaptiveColors.Action.breathing,
            points: 150,
            requirement: .consistency(weeks: 1)
        ),
        JournalAchievement(
            id: "consistency_champion",
            title: "Consistency Champion",
            description: "Journal regularly for 4 consecutive weeks",
            icon: "trophy.fill",
            color: Color(hex: "FF6B35"),
            points: 400,
            requirement: .consistency(weeks: 4)
        ),
        JournalAchievement(
            id: "dedication_master",
            title: "Dedication Master",
            description: "Journal regularly for 8 consecutive weeks",
            icon: "star.fill",
            color: Color(hex: "FFD700"),
            points: 750,
            requirement: .consistency(weeks: 8)
        )
    ]
}

// MARK: - Mental Health Evolution Tracking

struct MentalHealthDataPoint {
    let date: Date
    let moodScore: Double // 1-10 scale
    let anxietyLevel: Double // 1-10 scale (inverted - lower is better)
    let stressLevel: Double // 1-10 scale (inverted - lower is better)
    let gratitudeCount: Int
    let wordCount: Int
    let reflectionQuality: Double // Calculated metric
}

struct MentalHealthTrend {
    let period: TimePeriod
    let moodTrend: TrendDirection
    let anxietyTrend: TrendDirection
    let stressTrend: TrendDirection
    let overallWellness: Double // Composite score
    
    enum TimePeriod {
        case week, month, threeMonths, year
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .threeMonths: return "3 Months"
            case .year: return "This Year"
            }
        }
    }
    
    enum TrendDirection {
        case improving, stable, declining
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.circle.fill"
            case .stable: return "minus.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return AdaptiveColors.Action.progress
            case .stable: return AdaptiveColors.Action.mood
            case .declining: return AdaptiveColors.Action.sos.opacity(0.7)
            }
        }
    }
}

// MARK: - Journal Entry Enhancement

struct GamifiedJournalEntry {
    let baseEntry: SupabaseJournalEntry
    let pointsEarned: Int
    let achievementsUnlocked: [String]
    let moodImprovement: Double?
    let streakContribution: Bool
    let qualityScore: Double // Based on length, gratitude, mood reflection
    
    var displayPoints: String {
        return "+\(pointsEarned) pts"
    }
}

// MARK: - Progress Proximity System

struct ProgressProximityStatus {
    let items: [ProximityItem]
    
    var hasItems: Bool {
        return !items.isEmpty
    }
    
    var mostUrgent: ProximityItem? {
        return items.first
    }
}

struct ProximityItem: Identifiable {
    let id: String
    let type: ProximityType
    let title: String
    let description: String
    let progressPercentage: Double
    let pointsNeeded: Int
    let icon: String
    let color: Color
    
    var urgencyLevel: UrgencyLevel {
        if progressPercentage >= 0.9 || pointsNeeded <= 1 {
            return .veryClose
        } else if progressPercentage >= 0.7 || pointsNeeded <= 3 {
            return .close
        } else {
            return .moderate
        }
    }
}

enum ProximityType {
    case achievement
    case levelUp
    case streak
}

enum UrgencyLevel {
    case veryClose
    case close
    case moderate
    
    var message: String {
        switch self {
        case .veryClose:
            return "So close!"
        case .close:
            return "Almost there!"
        case .moderate:
            return "Within reach!"
        }
    }
    
    var color: Color {
        switch self {
        case .veryClose:
            return Color.red
        case .close:
            return Color.orange
        case .moderate:
            return Color.blue
        }
    }
}

// MARK: - Level System

struct JournalLevel {
    let level: Int
    let title: String
    let description: String
    let requiredPoints: Int
    let badge: String
    let color: Color
    let rewards: [String]
    
    static func levelForPoints(_ points: Int) -> JournalLevel {
        return journalLevels.last { $0.requiredPoints <= points } ?? journalLevels.first!
    }
    
    static let journalLevels: [JournalLevel] = [
        JournalLevel(level: 1, title: "Mindful Beginner", description: "Starting your wellness journey", requiredPoints: 0, badge: "🌱", color: AdaptiveColors.Action.breathing, rewards: ["Basic journal templates"]),
        JournalLevel(level: 2, title: "Reflective Soul", description: "Building awareness", requiredPoints: 200, badge: "🪞", color: AdaptiveColors.Action.mood, rewards: ["Mood insights", "Weekly summaries"]),
        JournalLevel(level: 3, title: "Grateful Heart", description: "Embracing gratitude", requiredPoints: 500, badge: "💝", color: AdaptiveColors.Action.progress, rewards: ["Gratitude streaks", "Achievement badges"]),
        JournalLevel(level: 4, title: "Wisdom Seeker", description: "Deep self-reflection", requiredPoints: 1000, badge: "🧠", color: AdaptiveColors.Action.coaching, rewards: ["Advanced analytics", "Trend insights"]),
        JournalLevel(level: 5, title: "Zen Master", description: "Mastering mindfulness", requiredPoints: 2000, badge: "🏆", color: Color(hex: "FFD700"), rewards: ["Custom themes", "Export options"]),
        JournalLevel(level: 6, title: "Wellness Guru", description: "Inspiring others", requiredPoints: 4000, badge: "👑", color: Color(hex: "FF6B35"), rewards: ["Premium templates", "Share achievements"])
    ]
}

// MARK: - Level Up System

struct LevelUpInfo {
    let previousLevel: Int
    let newLevel: JournalLevel
    let pointsEarned: Int
    
    var levelIncrease: Int {
        return newLevel.level - previousLevel
    }
}