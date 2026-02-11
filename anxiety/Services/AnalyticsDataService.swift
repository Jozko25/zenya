//
//  AnalyticsDataService.swift
//  anxiety
//
//  Service for collecting and analyzing user activity data for analytics
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AnalyticsDataService: ObservableObject {
    static let shared = AnalyticsDataService()
    
    private let databaseService = DatabaseService.shared
    private let gameStatsManager = JournalGameStatsManager.shared
    
    // MARK: - Published Properties
    @Published var weeklyMoodTrend: [MoodDataPoint] = []
    @Published var monthlyMoodTrend: [MoodDataPoint] = []
    @Published var activityHeatmap: [DailyActivity] = []
    @Published var journeyMilestones: [JourneyMilestone] = []
    @Published var personalInsights: [PersonalInsight] = []
    
    private init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await loadMoodTrends()
        await loadActivityHeatmap()
        await loadJourneyMilestones()
        await generatePersonalInsights()
    }
    
    func refreshAnalyticsData() async {
        await loadInitialData()
    }
    
    // MARK: - Mood Trends

    private func loadMoodTrends() async {
        guard let userId = databaseService.currentUser?.id else {
            await generateMockMoodTrends()
            return
        }

        let calendar = Calendar.current

        // Get journal entries
        var entries: [SupabaseJournalEntry] = []
        do {
            entries = try await databaseService.getJournalEntries(userId: userId, limit: 90)
        } catch {
            debugPrint("⚠️ Could not load journal entries for mood trends: \(error)")
        }

        // Also get evaluations for mood scores
        let analysisService = JournalAnalysisService.shared
        await analysisService.loadEvaluations()
        let evaluations = await MainActor.run { analysisService.analyses }

        // Create a map of date -> mood from evaluations
        var evalMoodByDate: [Date: Double] = [:]
        for eval in evaluations {
            let dayStart = calendar.startOfDay(for: eval.date)
            evalMoodByDate[dayStart] = Double(eval.maturityScore) // Use maturity score as mood proxy
        }

        // Generate weekly trend
        var weeklyData: [MoodDataPoint] = []
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let dayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }

            // Try entries first, then evaluations
            var avgMood: Double? = nil
            let entryMoods = dayEntries.compactMap { $0.mood }
            if !entryMoods.isEmpty {
                avgMood = Double(entryMoods.reduce(0, +)) / Double(entryMoods.count)
            } else if let evalMood = evalMoodByDate[dayStart] {
                avgMood = evalMood
            }

            weeklyData.append(MoodDataPoint(date: date, mood: avgMood))
        }

        // Generate monthly trend
        var monthlyData: [MoodDataPoint] = []
        for dayOffset in (0..<30).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let dayEntries = entries.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }

            var avgMood: Double? = nil
            let entryMoods = dayEntries.compactMap { $0.mood }
            if !entryMoods.isEmpty {
                avgMood = Double(entryMoods.reduce(0, +)) / Double(entryMoods.count)
            } else if let evalMood = evalMoodByDate[dayStart] {
                avgMood = evalMood
            }

            monthlyData.append(MoodDataPoint(date: date, mood: avgMood))
        }

        weeklyMoodTrend = weeklyData
        monthlyMoodTrend = monthlyData
    }
    
    private func generateMockMoodTrends() async {
        let calendar = Calendar.current
        
        // Generate realistic mock data with some patterns
        var weeklyData: [MoodDataPoint] = []
        var monthlyData: [MoodDataPoint] = []
        
        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let mood = generateRealisticMood(for: date, baseLevel: 6.0)
            weeklyData.append(MoodDataPoint(date: date, mood: mood))
        }
        
        for dayOffset in (0..<30).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let mood = generateRealisticMood(for: date, baseLevel: 6.2)
            monthlyData.append(MoodDataPoint(date: date, mood: mood))
        }
        
        weeklyMoodTrend = weeklyData
        monthlyMoodTrend = monthlyData
    }
    
    private func generateRealisticMood(for date: Date, baseLevel: Double) -> Double? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: Date())
        
        // Add some randomness
        let random = Double.random(in: -1.5...1.5)
        
        // Weekend boost
        let weekendBoost = (weekday == 1 || weekday == 7) ? 0.5 : 0.0
        
        // Time of day influence (for current day only)
        let timeBoost = calendar.isDateInToday(date) ? getTimeBasedMoodBoost(hour: hour) : 0.0
        
        let mood = baseLevel + random + weekendBoost + timeBoost
        return max(1.0, min(10.0, mood))
    }
    
    private func getTimeBasedMoodBoost(hour: Int) -> Double {
        switch hour {
        case 6..<10: return 0.3  // Morning optimism
        case 10..<14: return 0.5 // Mid-day peak
        case 14..<18: return 0.2 // Afternoon dip
        case 18..<22: return 0.4 // Evening recovery
        default: return -0.2     // Late night/early morning
        }
    }
    
    // MARK: - Activity Heatmap

    private func loadActivityHeatmap() async {
        guard let userId = databaseService.currentUser?.id else {
            activityHeatmap = []
            return
        }

        let calendar = Calendar.current
        var activities: [DailyActivity] = []

        // Get journal entries
        var entries: [SupabaseJournalEntry] = []
        do {
            entries = try await databaseService.getJournalEntries(userId: userId, limit: 200)
        } catch {
            debugPrint("⚠️ Could not load journal entries for heatmap: \(error)")
        }

        // Also get evaluations (these represent actual reflection activity)
        let analysisService = JournalAnalysisService.shared
        await analysisService.loadEvaluations()
        let evaluations = await MainActor.run { analysisService.analyses }

        // Create a set of dates with evaluations
        let evalDates = Set(evaluations.map { calendar.startOfDay(for: $0.date) })

        // Generate activity data for the past 5 weeks (35 days)
        for dayOffset in (0..<35).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            // Get actual entries for this day
            let dayEntries = entries.filter {
                $0.createdAt >= dayStart && $0.createdAt < dayEnd
            }

            // Check if there's an evaluation for this day
            let hasEvaluation = evalDates.contains(dayStart)

            // Count activity: entries OR evaluations
            let entryCount = max(dayEntries.count, hasEvaluation ? 1 : 0)
            let level = min(3, entryCount) // Cap at 3 for display

            activities.append(DailyActivity(
                date: date,
                level: level,
                entryCount: entryCount,
                hasBreathingSession: false,
                hasMoodCheck: dayEntries.contains { $0.mood != nil } || hasEvaluation
            ))
        }

        activityHeatmap = activities
    }
    
    // MARK: - Journey Milestones
    
    private func loadJourneyMilestones() async {
        var milestones: [JourneyMilestone] = []
        
        let stats = gameStatsManager.gameStats
        let calendar = Calendar.current
        
        // First Entry Milestone
        if stats.totalEntries > 0 {
            milestones.append(JourneyMilestone(
                id: "first_entry",
                title: "First Reflection",
                description: "You started your wellness journey with your first journal entry",
                date: calendar.date(byAdding: .day, value: -stats.totalEntries, to: Date()) ?? Date(),
                type: .firstEntry,
                isCompleted: true,
                points: 20
            ))
        }
        
        // Streak Milestones
        if stats.currentStreak >= 3 {
            milestones.append(JourneyMilestone(
                id: "streak_3",
                title: "Building Habits",
                description: "You maintained a 3-day reflection streak",
                date: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                type: .streak,
                isCompleted: true,
                points: 50
            ))
        }
        
        if stats.currentStreak >= 7 {
            milestones.append(JourneyMilestone(
                id: "streak_7",
                title: "One Week Strong",
                description: "You completed your first week of consistent journaling",
                date: calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                type: .streak,
                isCompleted: true,
                points: 100
            ))
        }
        
        // Level Up Milestones
        if stats.level >= 2 {
            milestones.append(JourneyMilestone(
                id: "level_2",
                title: "Level Up!",
                description: "You reached Level 2 in your wellness journey",
                date: calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
                type: .levelUp,
                isCompleted: true,
                points: stats.totalPoints / 2
            ))
        }
        
        // Total Entries Milestones
        if stats.totalEntries >= 5 {
            milestones.append(JourneyMilestone(
                id: "entries_5",
                title: "Getting Started",
                description: "You completed 5 reflection sessions",
                date: calendar.date(byAdding: .day, value: -stats.totalEntries + 5, to: Date()) ?? Date(),
                type: .entries,
                isCompleted: true,
                points: 100
            ))
        }
        
        if stats.totalEntries >= 10 {
            milestones.append(JourneyMilestone(
                id: "entries_10",
                title: "Building Momentum",
                description: "You reached 10 journal entries - keep going!",
                date: calendar.date(byAdding: .day, value: -stats.totalEntries + 10, to: Date()) ?? Date(),
                type: .entries,
                isCompleted: true,
                points: 200
            ))
        }
        
        // Sort by date (most recent first)
        milestones.sort { $0.date > $1.date }
        
        journeyMilestones = milestones
    }
    
    // MARK: - Personal Insights
    
    private func generatePersonalInsights() async {
        var insights: [PersonalInsight] = []
        
        let stats = gameStatsManager.gameStats
        let calendar = Calendar.current
        
        // Streak insights
        if stats.currentStreak >= 7 {
            insights.append(PersonalInsight(
                id: "streak_champion",
                title: "Consistency Champion",
                description: "You've maintained a \(stats.currentStreak)-day streak! This consistency is building strong mental wellness habits.",
                type: .achievement,
                priority: .high,
                actionSuggestion: "Keep maintaining this excellent streak",
                date: Date()
            ))
        } else if stats.currentStreak >= 3 {
            insights.append(PersonalInsight(
                id: "building_habits",
                title: "Habit Building",
                description: "You're building great momentum with a \(stats.currentStreak)-day streak.",
                type: .progress,
                priority: .medium,
                actionSuggestion: "Try to reach a 7-day streak next",
                date: Date()
            ))
        } else if stats.totalEntries > 0 {
            insights.append(PersonalInsight(
                id: "start_streak",
                title: "Build Your Streak",
                description: "Start a daily reflection streak to maximize your wellness journey.",
                type: .suggestion,
                priority: .medium,
                actionSuggestion: "Write a journal entry today",
                date: Date()
            ))
        }
        
        // Level insights
        let currentLevel = JournalLevel.levelForPoints(stats.totalPoints)
        if let nextLevel = JournalLevel.journalLevels.first(where: { $0.level > currentLevel.level }) {
            let pointsNeeded = nextLevel.requiredPoints - stats.totalPoints
            if pointsNeeded <= 50 {
                insights.append(PersonalInsight(
                    id: "close_to_level_up",
                    title: "Close to Level Up!",
                    description: "You're only \(pointsNeeded) points away from reaching \(nextLevel.title).",
                    type: .progress,
                    priority: .high,
                    actionSuggestion: "Write a detailed journal entry to level up",
                    date: Date()
                ))
            }
        }
        
        // Time-based insights
        let hour = calendar.component(.hour, from: Date())
        if hour >= 18 && hour <= 22 {
            insights.append(PersonalInsight(
                id: "evening_reflection",
                title: "Evening Reflection Time",
                description: "Evening is a great time for reflection and processing the day's experiences.",
                type: .suggestion,
                priority: .low,
                actionSuggestion: "Take 5 minutes to reflect on your day",
                date: Date()
            ))
        }
        
        // Beginner insights
        if stats.totalEntries == 0 {
            insights.append(PersonalInsight(
                id: "welcome",
                title: "Welcome to Your Journey",
                description: "Starting your mental wellness journey is a brave and important step.",
                type: .welcome,
                priority: .high,
                actionSuggestion: "Write your first journal entry",
                date: Date()
            ))
        }
        
        personalInsights = insights
    }
    
    // MARK: - Analytics Calculations
    
    func getWeeklyMoodAverage() -> Double {
        let validMoods = weeklyMoodTrend.compactMap { $0.mood }
        return validMoods.isEmpty ? 0 : validMoods.reduce(0, +) / Double(validMoods.count)
    }
    
    func getMoodTrend() -> TrendDirection {
        let recentMoods = weeklyMoodTrend.suffix(3).compactMap { $0.mood }
        let earlierMoods = weeklyMoodTrend.prefix(3).compactMap { $0.mood }
        
        guard !recentMoods.isEmpty && !earlierMoods.isEmpty else { return .neutral }
        
        let recentAvg = recentMoods.reduce(0, +) / Double(recentMoods.count)
        let earlierAvg = earlierMoods.reduce(0, +) / Double(earlierMoods.count)
        
        if recentAvg > earlierAvg + 0.5 { return .up }
        if recentAvg < earlierAvg - 0.5 { return .down }
        return .neutral
    }
    
    func getActivityTrend() -> TrendDirection {
        let recentActivity = activityHeatmap.suffix(7).map { $0.level }.reduce(0, +)
        let earlierActivity = activityHeatmap.dropLast(7).suffix(7).map { $0.level }.reduce(0, +)
        
        if recentActivity > earlierActivity { return .up }
        if recentActivity < earlierActivity { return .down }
        return .neutral
    }
    
    func getTotalActiveDays() -> Int {
        return activityHeatmap.filter { $0.level > 0 }.count
    }
}

// MARK: - Supporting Models

struct MoodDataPoint {
    let date: Date
    let mood: Double?
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    let level: Int // 0-3 scale
    let entryCount: Int
    let hasBreathingSession: Bool
    let hasMoodCheck: Bool
}

struct JourneyMilestone: Identifiable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let type: MilestoneType
    let isCompleted: Bool
    let points: Int
}

enum MilestoneType {
    case firstEntry
    case streak
    case levelUp
    case entries
    case mood
    case breathing
}

struct PersonalInsight: Identifiable {
    let id: String
    let title: String
    let description: String
    let type: InsightType
    let priority: InsightPriority
    let actionSuggestion: String
    let date: Date
}

enum InsightType {
    case achievement
    case progress
    case suggestion
    case warning
    case welcome
}

enum InsightPriority {
    case high
    case medium
    case low
}

enum TrendDirection {
    case up
    case down
    case neutral
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right.circle.fill"
        case .down: return "arrow.down.right.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return AdaptiveColors.Action.progress
        case .down: return AdaptiveColors.Action.sos
        case .neutral: return AdaptiveColors.Text.secondary
        }
    }
}