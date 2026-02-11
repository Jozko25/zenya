//
//  PersonalMoodAnalytics.swift
//  anxiety
//
//  Learns from actual user data to provide personalized mood insights
//  Replaces assumption-based predictions with data-driven analytics
//

import Foundation
import SwiftUI

// MARK: - Trend Direction

enum MoodTrendDirection: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return Color(hex: "10B981") // Green
        case .declining: return Color(hex: "F59E0B") // Amber
        case .stable: return Color(hex: "6B7280") // Gray
        }
    }

    var trendDescription: String {
        switch self {
        case .improving: return "trending up"
        case .declining: return "trending down"
        case .stable: return "holding steady"
        }
    }
}

// MARK: - Visual State for UI

enum MoodVisualState {
    case significantlyAbove  // +1.5 or more above baseline
    case aboveBaseline       // +0.5 to +1.5 above
    case nearBaseline        // -0.5 to +0.5
    case belowBaseline       // -0.5 to -1.5 below
    case significantlyBelow  // -1.5 or more below

    var ringFillPercentage: Double {
        switch self {
        case .significantlyAbove: return 0.95
        case .aboveBaseline: return 0.75
        case .nearBaseline: return 0.50
        case .belowBaseline: return 0.30
        case .significantlyBelow: return 0.15
        }
    }

    var primaryColor: Color {
        switch self {
        case .significantlyAbove: return Color(hex: "FF5C7A")
        case .aboveBaseline: return Color(hex: "FF8FA3")
        case .nearBaseline: return Color(hex: "B87FA3")
        case .belowBaseline: return Color(hex: "A34865")
        case .significantlyBelow: return Color(hex: "8A3855")
        }
    }

    static func from(comparativeScore: Double) -> MoodVisualState {
        switch comparativeScore {
        case 1.5...: return .significantlyAbove
        case 0.5..<1.5: return .aboveBaseline
        case -0.5..<0.5: return .nearBaseline
        case -1.5..<(-0.5): return .belowBaseline
        default: return .significantlyBelow
        }
    }
}

// MARK: - Mood Insight (What the user sees)

struct MoodInsight: Identifiable {
    let id = UUID()
    let date: Date

    // Core metrics
    let predictedMood: Double           // Absolute 1-10 scale
    let comparativeScore: Double        // Relative to personal baseline (-3 to +3)
    let personalBaseline: Double        // User's rolling average

    // Trend information
    let trend: MoodTrendDirection
    let trendStrength: Int              // Number of consecutive days in trend

    // Insights (learned from data)
    let primaryInsight: String          // e.g., "Tuesday is your best day"
    let secondaryInsight: String?       // e.g., "3-day positive streak"
    let emotionalContext: String?       // From evaluations

    // Confidence and display
    let confidence: Double
    let visualState: MoodVisualState
    let dataPointsUsed: Int             // How many entries informed this

    // Weekday-specific data
    let weekdayAverage: Double?         // Average mood for this weekday
    let weekdayRank: Int?               // 1 = best day, 7 = worst day

    var comparativeDescription: String {
        let absScore = abs(comparativeScore)
        let direction = comparativeScore >= 0 ? "above" : "below"

        if absScore < 0.3 {
            return "Near your typical range"
        } else if absScore < 0.8 {
            return String(format: "%.1f %@ your average", absScore, direction)
        } else {
            return String(format: "%.1f %@ your average", absScore, direction)
        }
    }

    var shortComparativeDescription: String {
        if abs(comparativeScore) < 0.3 {
            return "Typical"
        } else if comparativeScore > 0 {
            return String(format: "+%.1f", comparativeScore)
        } else {
            return String(format: "%.1f", comparativeScore)
        }
    }
}

// MARK: - Weekday Statistics

struct WeekdayStats {
    let weekday: Int                    // 1 = Sunday, 7 = Saturday
    let averageMood: Double
    let entryCount: Int
    let standardDeviation: Double
    let rank: Int                       // 1 = best, 7 = worst

    var weekdayName: String {
        let calendar = Calendar.current
        return calendar.weekdaySymbols[weekday - 1]
    }

    var shortName: String {
        let calendar = Calendar.current
        return calendar.shortWeekdaySymbols[weekday - 1]
    }
}

// MARK: - Personal Analytics Summary

struct PersonalAnalyticsSummary {
    let personalBaseline: Double
    let volatility: Double              // Standard deviation
    let weekdayStats: [WeekdayStats]
    let bestDay: WeekdayStats?
    let challengingDay: WeekdayStats?
    let currentTrend: MoodTrendDirection
    let trendStrength: Int
    let totalEntries: Int
    let recentEmotionalThemes: [String]

    var hasEnoughData: Bool {
        totalEntries >= 3
    }

    var dataQualityDescription: String {
        switch totalEntries {
        case 0..<3: return "Building your profile..."
        case 3..<7: return "Learning your patterns"
        case 7..<14: return "Good data foundation"
        case 14..<30: return "Strong pattern recognition"
        default: return "Rich personal insights"
        }
    }
}

// MARK: - Personal Mood Analytics Service

@MainActor
class PersonalMoodAnalytics: ObservableObject {
    static let shared = PersonalMoodAnalytics()

    @Published var summary: PersonalAnalyticsSummary?
    @Published var isAnalyzing = false

    private let patternStore = PersonalPatternStore.shared
    private let analysisService = JournalAnalysisService.shared

    private var cachedWeekdayStats: [Int: WeekdayStats] = [:]
    private var lastAnalysisDate: Date?

    private init() {
        // Service initialized
    }

    // MARK: - Main Analysis

    /// Analyze all entries and build personal profile
    func analyzeEntries(_ entries: [SupabaseJournalEntry]) async -> PersonalAnalyticsSummary {
        isAnalyzing = true
        defer { isAnalyzing = false }

        // Filter entries with valid mood scores
        let validEntries = entries.filter { $0.mood != nil }

        guard !validEntries.isEmpty else {
            let emptySummary = createEmptySummary()
            summary = emptySummary
            return emptySummary
        }

        // 1. Calculate personal baseline (rolling average)
        let baseline = calculateBaseline(from: validEntries)

        // 2. Calculate volatility (standard deviation)
        let volatility = calculateVolatility(from: validEntries, baseline: baseline)

        // 3. Calculate weekday statistics
        let weekdayStats = calculateWeekdayStats(from: validEntries)

        // 4. Find best and challenging days
        let bestDay = weekdayStats.min(by: { $0.rank < $1.rank })
        let challengingDay = weekdayStats.max(by: { $0.rank < $1.rank })

        // 5. Detect current trend
        let (trend, trendStrength) = detectTrend(from: validEntries)

        // 6. Get recent emotional themes from evaluations
        let recentThemes = getRecentEmotionalThemes()

        let newSummary = PersonalAnalyticsSummary(
            personalBaseline: baseline,
            volatility: volatility,
            weekdayStats: weekdayStats,
            bestDay: bestDay,
            challengingDay: challengingDay,
            currentTrend: trend,
            trendStrength: trendStrength,
            totalEntries: validEntries.count,
            recentEmotionalThemes: recentThemes
        )

        summary = newSummary
        lastAnalysisDate = Date()

        return newSummary
    }

    // MARK: - Generate Insight for Date

    /// Generate a rich insight for a specific date
    func generateInsight(
        for date: Date,
        entries: [SupabaseJournalEntry],
        existingPrediction: MoodPrediction? = nil
    ) async -> MoodInsight {
        // Ensure we have fresh analytics
        if summary == nil || shouldRefreshAnalytics() {
            _ = await analyzeEntries(entries)
        }

        guard let analytics = summary else {
            return createDefaultInsight(for: date)
        }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let weekdayName = calendar.weekdaySymbols[weekday - 1]

        // Generating insight for weekday

        // Get weekday-specific stats
        let weekdayStat = analytics.weekdayStats.first { $0.weekday == weekday }

        // Calculate predicted mood
        let predictedMood: Double
        if let existing = existingPrediction {
            predictedMood = existing.predictedMood
        } else if let stat = weekdayStat, stat.entryCount >= 2 {
            // Use actual weekday average if we have enough data
            predictedMood = stat.averageMood
        } else {
            predictedMood = analytics.personalBaseline
        }

        // Calculate comparative score
        let comparativeScore = predictedMood - analytics.personalBaseline

        // Generate primary insight
        let primaryInsight = generatePrimaryInsight(
            weekday: weekday,
            weekdayStat: weekdayStat,
            analytics: analytics,
            date: date
        )

        // Generate secondary insight
        let secondaryInsight = generateSecondaryInsight(
            trend: analytics.currentTrend,
            trendStrength: analytics.trendStrength,
            analytics: analytics
        )

        // Get emotional context from recent evaluations
        let emotionalContext = generateEmotionalContext(from: analytics.recentEmotionalThemes)

        // Calculate confidence based on data quality
        let confidence = calculateConfidence(
            weekdayStat: weekdayStat,
            totalEntries: analytics.totalEntries,
            daysInFuture: calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        )

        let visualState = MoodVisualState.from(comparativeScore: comparativeScore)

        return MoodInsight(
            date: date,
            predictedMood: predictedMood,
            comparativeScore: comparativeScore,
            personalBaseline: analytics.personalBaseline,
            trend: analytics.currentTrend,
            trendStrength: analytics.trendStrength,
            primaryInsight: primaryInsight,
            secondaryInsight: secondaryInsight,
            emotionalContext: emotionalContext,
            confidence: confidence,
            visualState: visualState,
            dataPointsUsed: analytics.totalEntries,
            weekdayAverage: weekdayStat?.averageMood,
            weekdayRank: weekdayStat?.rank
        )
    }

    // MARK: - Private Helpers

    private func calculateBaseline(from entries: [SupabaseJournalEntry]) -> Double {
        // Use last 14 days for rolling average, or all if fewer
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()

        let recentEntries = entries.filter { $0.createdAt >= twoWeeksAgo }
        let entriesToUse = recentEntries.isEmpty ? entries : recentEntries

        let moods = entriesToUse.compactMap { $0.mood }
        guard !moods.isEmpty else { return 6.0 }

        return Double(moods.reduce(0, +)) / Double(moods.count)
    }

    private func calculateVolatility(from entries: [SupabaseJournalEntry], baseline: Double) -> Double {
        let moods = entries.compactMap { $0.mood }.map { Double($0) }
        guard moods.count >= 2 else { return 0.0 }

        let squaredDiffs = moods.map { pow($0 - baseline, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(moods.count)
        return sqrt(variance)
    }

    private func calculateWeekdayStats(from entries: [SupabaseJournalEntry]) -> [WeekdayStats] {
        let calendar = Calendar.current

        // Group entries by weekday
        var weekdayMoods: [Int: [Int]] = [:]
        for entry in entries {
            guard let mood = entry.mood else { continue }
            let weekday = calendar.component(.weekday, from: entry.createdAt)
            weekdayMoods[weekday, default: []].append(mood)
        }

        // Calculate stats for each weekday
        var stats: [WeekdayStats] = []
        for weekday in 1...7 {
            let moods = weekdayMoods[weekday] ?? []

            if moods.isEmpty {
                // No data for this weekday - use neutral values
                stats.append(WeekdayStats(
                    weekday: weekday,
                    averageMood: 6.0, // Neutral
                    entryCount: 0,
                    standardDeviation: 0.0,
                    rank: 4 // Middle rank
                ))
            } else {
                let avg = Double(moods.reduce(0, +)) / Double(moods.count)
                let stdDev = moods.count >= 2 ? calculateStdDev(moods.map { Double($0) }, mean: avg) : 0.0

                stats.append(WeekdayStats(
                    weekday: weekday,
                    averageMood: avg,
                    entryCount: moods.count,
                    standardDeviation: stdDev,
                    rank: 0 // Will be set below
                ))
            }
        }

        // Assign ranks (1 = highest avg, 7 = lowest)
        let sortedByMood = stats.sorted { $0.averageMood > $1.averageMood }
        var rankedStats: [WeekdayStats] = []
        for (index, stat) in sortedByMood.enumerated() {
            rankedStats.append(WeekdayStats(
                weekday: stat.weekday,
                averageMood: stat.averageMood,
                entryCount: stat.entryCount,
                standardDeviation: stat.standardDeviation,
                rank: index + 1
            ))
        }

        // Cache for quick lookup
        for stat in rankedStats {
            cachedWeekdayStats[stat.weekday] = stat
        }

        return rankedStats
    }

    private func calculateStdDev(_ values: [Double], mean: Double) -> Double {
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        let variance = squaredDiffs.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func detectTrend(from entries: [SupabaseJournalEntry]) -> (MoodTrendDirection, Int) {
        let sortedEntries = entries
            .filter { $0.mood != nil }
            .sorted { $0.createdAt > $1.createdAt }

        guard sortedEntries.count >= 3 else {
            return (.stable, 0)
        }

        // Compare recent average to earlier average
        let recentCount = min(5, sortedEntries.count / 2)
        let recentMoods = sortedEntries.prefix(recentCount).compactMap { $0.mood }
        let earlierMoods = sortedEntries.dropFirst(recentCount).prefix(recentCount).compactMap { $0.mood }

        guard !recentMoods.isEmpty && !earlierMoods.isEmpty else {
            return (.stable, 0)
        }

        let recentAvg = Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
        let earlierAvg = Double(earlierMoods.reduce(0, +)) / Double(earlierMoods.count)

        let difference = recentAvg - earlierAvg

        // Count consecutive trend days
        var trendStrength = 0
        var lastMood: Int? = nil
        for entry in sortedEntries.prefix(7) {
            guard let mood = entry.mood else { continue }
            if let last = lastMood {
                if difference > 0.3 && mood >= last {
                    trendStrength += 1
                } else if difference < -0.3 && mood <= last {
                    trendStrength += 1
                } else {
                    break
                }
            }
            lastMood = mood
        }

        if difference > 0.5 {
            return (.improving, max(1, trendStrength))
        } else if difference < -0.5 {
            return (.declining, max(1, trendStrength))
        } else {
            return (.stable, 0)
        }
    }

    private func getRecentEmotionalThemes() -> [String] {
        let recentAnalyses = analysisService.analyses
            .sorted { $0.date > $1.date }
            .prefix(3)

        var themes: [String] = []
        for analysis in recentAnalyses {
            themes.append(contentsOf: analysis.emotionalThemes.prefix(2))
        }

        // Deduplicate and limit
        return Array(Set(themes)).prefix(5).map { $0 }
    }

    private func generatePrimaryInsight(
        weekday: Int,
        weekdayStat: WeekdayStats?,
        analytics: PersonalAnalyticsSummary,
        date: Date
    ) -> String {
        let calendar = Calendar.current
        let weekdayName = calendar.weekdaySymbols[weekday - 1]

        // Check for learned patterns in PatternStore first
        let learnedPatterns = patternStore.getPatternsAffecting(date: date)
        if let weekdayPattern = learnedPatterns.first(where: { $0.patternType == .weekdayPreference }) {
            return weekdayPattern.description
        }

        // Check for significant date patterns
        if let significantDate = learnedPatterns.first(where: { $0.patternType == .significantDate }) {
            return significantDate.description
        }

        // Use actual weekday stats if available
        if let stat = weekdayStat, stat.entryCount >= 2 {
            if stat.rank == 1 {
                return "\(weekdayName)s tend to be your best days"
            } else if stat.rank == 7 {
                return "\(weekdayName)s can be more challenging for you"
            } else if stat.averageMood > analytics.personalBaseline + 0.5 {
                return "\(weekdayName)s are typically above your average"
            } else if stat.averageMood < analytics.personalBaseline - 0.5 {
                return "\(weekdayName)s are usually below your average"
            }
        }

        // Default based on trend
        switch analytics.currentTrend {
        case .improving:
            return "You've been on an upward trend"
        case .declining:
            return "Recent days have been more challenging"
        case .stable:
            return "Your mood has been steady lately"
        }
    }

    private func generateSecondaryInsight(
        trend: MoodTrendDirection,
        trendStrength: Int,
        analytics: PersonalAnalyticsSummary
    ) -> String? {
        if trendStrength >= 3 {
            switch trend {
            case .improving:
                return "\(trendStrength)-day positive streak"
            case .declining:
                return "Consider some extra self-care"
            case .stable:
                return nil
            }
        }

        // Check for best/worst day proximity
        if let bestDay = analytics.bestDay, bestDay.entryCount >= 2 {
            let calendar = Calendar.current
            let todayWeekday = calendar.component(.weekday, from: Date())
            let daysUntilBest = (bestDay.weekday - todayWeekday + 7) % 7

            if daysUntilBest == 1 {
                return "Tomorrow is usually your best day"
            }
        }

        return nil
    }

    private func generateEmotionalContext(from themes: [String]) -> String? {
        guard !themes.isEmpty else { return nil }

        if themes.count == 1 {
            return "Recent focus: \(themes[0])"
        } else {
            return "Recent themes: \(themes.prefix(2).joined(separator: ", "))"
        }
    }

    private func calculateConfidence(
        weekdayStat: WeekdayStats?,
        totalEntries: Int,
        daysInFuture: Int
    ) -> Double {
        var confidence = 0.7 // Base confidence

        // Boost for weekday-specific data
        if let stat = weekdayStat {
            if stat.entryCount >= 4 {
                confidence += 0.15
            } else if stat.entryCount >= 2 {
                confidence += 0.08
            }
        }

        // Adjust for total entries
        if totalEntries >= 14 {
            confidence += 0.1
        } else if totalEntries < 5 {
            confidence -= 0.2
        }

        // Decay for future dates
        if daysInFuture > 0 {
            let decay = Double(daysInFuture) * 0.05
            confidence -= min(decay, 0.4)
        }

        return max(0.2, min(0.95, confidence))
    }

    private func shouldRefreshAnalytics() -> Bool {
        guard let lastDate = lastAnalysisDate else { return true }
        let hoursSinceLastAnalysis = Date().timeIntervalSince(lastDate) / 3600
        return hoursSinceLastAnalysis > 1 // Refresh if older than 1 hour
    }

    private func createEmptySummary() -> PersonalAnalyticsSummary {
        let emptyBestDay: WeekdayStats? = nil
        let emptyChallengingDay: WeekdayStats? = nil

        return PersonalAnalyticsSummary(
            personalBaseline: 6.0,
            volatility: 0.0,
            weekdayStats: [],
            bestDay: emptyBestDay,
            challengingDay: emptyChallengingDay,
            currentTrend: MoodTrendDirection.stable,
            trendStrength: 0,
            totalEntries: 0,
            recentEmotionalThemes: []
        )
    }

    private func createDefaultInsight(for date: Date) -> MoodInsight {
        let emptyContext: String? = nil
        let emptyWeekdayAvg: Double? = nil
        let emptyWeekdayRank: Int? = nil

        return MoodInsight(
            date: date,
            predictedMood: 6.0,
            comparativeScore: 0.0,
            personalBaseline: 6.0,
            trend: MoodTrendDirection.stable,
            trendStrength: 0,
            primaryInsight: "Building your personal profile...",
            secondaryInsight: "Add more reflections for personalized insights",
            emotionalContext: emptyContext,
            confidence: 0.3,
            visualState: MoodVisualState.nearBaseline,
            dataPointsUsed: 0,
            weekdayAverage: emptyWeekdayAvg,
            weekdayRank: emptyWeekdayRank
        )
    }

    // MARK: - Public Utilities

    /// Get quick comparative score for a date (for calendar grid)
    func getQuickComparative(for date: Date) -> (score: Double, state: MoodVisualState)? {
        guard let analytics = summary else { return nil }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        if let stat = cachedWeekdayStats[weekday], stat.entryCount >= 1 {
            let comparative = stat.averageMood - analytics.personalBaseline
            return (comparative, MoodVisualState.from(comparativeScore: comparative))
        }

        return (0.0, .nearBaseline)
    }

    /// Get weekday insight string for display
    func getWeekdayInsight(for weekday: Int) -> String? {
        guard let stat = cachedWeekdayStats[weekday], stat.entryCount >= 2 else {
            return nil
        }

        guard let analytics = summary else { return nil }

        let diff = stat.averageMood - analytics.personalBaseline

        if diff > 0.8 {
            return "\(stat.weekdayName): +\(String(format: "%.1f", diff)) (your best)"
        } else if diff < -0.8 {
            return "\(stat.weekdayName): \(String(format: "%.1f", diff)) (tougher day)"
        } else if abs(diff) > 0.3 {
            let direction = diff > 0 ? "above" : "below"
            return "\(stat.weekdayName): \(String(format: "%.1f", abs(diff))) \(direction) average"
        }

        return nil
    }
}
