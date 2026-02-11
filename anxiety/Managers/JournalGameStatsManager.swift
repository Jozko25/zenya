//
//  JournalGameStatsManager.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import Foundation
import Combine

@MainActor
class JournalGameStatsManager: ObservableObject {
    static let shared = JournalGameStatsManager()
    
    @Published     var gameStats = JournalGameStats()
    private let databaseService = DatabaseService.shared
    
    private var saveTask: Task<Void, Never>?
    
    private init() {
        loadGameStatsFromUserDefaults()
        
        Task {
            await loadGameStatsFromDatabase()
        }
    }
    
    // MARK: - Core Functionality
    
    // Synchronous loading from UserDefaults for immediate display
    private func loadGameStatsFromUserDefaults() {
        gameStats.totalEntries = UserDefaults.standard.integer(forKey: "journal_total_entries")
        gameStats.currentStreak = UserDefaults.standard.integer(forKey: "journal_current_streak")
        gameStats.longestStreak = UserDefaults.standard.integer(forKey: "journal_longest_streak")
        gameStats.totalPoints = UserDefaults.standard.integer(forKey: "journal_total_points")
        gameStats.level = UserDefaults.standard.integer(forKey: "journal_level")
        if gameStats.level == 0 { gameStats.level = 1 } // Default level

        // Load last entry date
        if let lastEntryDate = UserDefaults.standard.object(forKey: "journal_last_entry_date") as? Date {
            gameStats.lastEntryDate = lastEntryDate
        }

        // Load unlocked achievements
        if let achievementData = UserDefaults.standard.data(forKey: "journal_unlocked_achievements"),
           let achievements = try? JSONDecoder().decode(Set<String>.self, from: achievementData) {
            gameStats.unlockedAchievements = achievements
        }

        debugPrint("📊 Loaded game stats from UserDefaults - Level: \(gameStats.level), Points: \(gameStats.totalPoints)")
    }
    
    // Asynchronous loading from database (updates UserDefaults data if available)
    private func loadGameStatsFromDatabase() async {
        guard let currentUser = databaseService.currentUser else { return }
        
        do {
            let databaseStats = try await databaseService.loadGameStatsFromDatabase(currentUser.id)
            
            // Update UI on main thread
            await MainActor.run {
                // Only update if database has newer/better data
                if databaseStats.totalPoints > gameStats.totalPoints || 
                   databaseStats.level > gameStats.level {
                    gameStats = databaseStats
                    debugPrint("📊 Updated game stats from database - Level: \(gameStats.level), Points: \(gameStats.totalPoints)")
                } else {
                    // Sync local data to database if it's newer (only if we have data)
                    if gameStats.totalEntries > 0 || gameStats.totalPoints > 0 {
                        Task {
                            do {
                                try await databaseService.syncLocalGameStats(gameStats, userId: currentUser.id)
                            } catch {
                                let errorDesc = error.localizedDescription
                                // Silently ignore RLS errors on startup
                                if !errorDesc.contains("42501") && !errorDesc.contains("row-level security") {
                                    debugPrint("Failed to sync game stats to database: \(error)")
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            debugPrint("Failed to load game stats from database: \(error)")
        }
    }
    
    func loadGameStats() async {
        // Public method for manual refresh
        loadGameStatsFromUserDefaults()
        await loadGameStatsFromDatabase()
    }
    
    func reloadGameStats() {
        // Method for immediate reload (e.g., after app reset)
        loadGameStatsFromUserDefaults()
        Task {
            await loadGameStatsFromDatabase()
            await recalculateStatsFromEntries()
        }
    }

    /// Recalculates stats from actual journal entries AND evaluations to fix any discrepancies
    func recalculateStatsFromEntries() async {
        guard let userId = databaseService.currentUser?.id else { return }

        let calendar = Calendar.current
        var allDates: [Date] = []
        var totalCount = 0

        // Get journal entries
        do {
            let entries = try await databaseService.getJournalEntries(userId: userId, limit: 1000, forceRefresh: true)
            totalCount += entries.count
            allDates.append(contentsOf: entries.map { $0.createdAt })
            debugPrint("📊 Found \(entries.count) journal entries")
        } catch {
            debugPrint("⚠️ Could not load journal entries: \(error)")
        }

        // Also count evaluations (these represent analyzed reflection days)
        let analysisService = JournalAnalysisService.shared
        await analysisService.loadEvaluations()
        let evaluations = await MainActor.run { analysisService.analyses }

        if !evaluations.isEmpty {
            // Count unique evaluation days as reflections
            let evalDates = evaluations.map { $0.date }
            allDates.append(contentsOf: evalDates)

            // Use evaluation count if higher than entries (evaluations = actual reflections)
            let evalCount = evaluations.count
            if evalCount > totalCount {
                totalCount = evalCount
            }
            debugPrint("📊 Found \(evalCount) evaluations")
        }

        if totalCount == 0 && allDates.isEmpty { return }

        // Calculate streak from all activity dates
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        let sortedDates = Set(allDates.map { calendar.startOfDay(for: $0) }).sorted(by: >)

        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) ||
               calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate)!) {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }

        await MainActor.run {
            // Update with calculated values
            if totalCount > gameStats.totalEntries {
                debugPrint("📊 Updated totalEntries from \(gameStats.totalEntries) to \(totalCount)")
                gameStats.totalEntries = totalCount
            }
            if streak > gameStats.currentStreak {
                gameStats.currentStreak = streak
            }
            if streak > gameStats.longestStreak {
                gameStats.longestStreak = streak
            }
            if let lastDate = sortedDates.first {
                gameStats.lastEntryDate = lastDate
            }

            // Ensure points are reasonable (20 points per entry minimum)
            let minExpectedPoints = totalCount * 20
            if gameStats.totalPoints < minExpectedPoints {
                gameStats.totalPoints = minExpectedPoints
                debugPrint("📊 Adjusted totalPoints to minimum: \(minExpectedPoints)")
            }

            saveGameStats()

            // Check and unlock any achievements based on new stats
            checkAchievements(totalEntries: totalCount)
        }

        debugPrint("📊 Recalculated stats: \(totalCount) total reflections, \(streak) day streak")
    }
    
    func saveGameStats() {
        saveTask?.cancel()
        
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            let defaults = UserDefaults.standard
            defaults.set(gameStats.totalEntries, forKey: "journal_total_entries")
            defaults.set(gameStats.currentStreak, forKey: "journal_current_streak")
            defaults.set(gameStats.longestStreak, forKey: "journal_longest_streak")
            defaults.set(gameStats.totalPoints, forKey: "journal_total_points")
            defaults.set(gameStats.level, forKey: "journal_level")

            if let lastEntryDate = gameStats.lastEntryDate {
                defaults.set(lastEntryDate, forKey: "journal_last_entry_date")
            }
            
            if let achievementData = try? JSONEncoder().encode(gameStats.unlockedAchievements) {
                defaults.set(achievementData, forKey: "journal_unlocked_achievements")
            }
            
            if let currentUser = databaseService.currentUser {
                Task { @MainActor in
                    do {
                        try await self.databaseService.syncLocalGameStats(self.gameStats, userId: currentUser.id)
                    } catch {
                        debugPrint("Failed to sync game stats: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Journal Entry Processing
    
    func processNewJournalEntry(_ entry: SupabaseJournalEntry) {
        gameStats.totalEntries += 1
        gameStats.lastEntryDate = Date()

        // Track various entry characteristics for achievements
        trackLongEntry(entry)
        trackMoodEntry(entry)
        
        // Calculate points for this entry
        var pointsEarned = calculatePointsForEntry(entry)
        
        // Check for surprise bonus
        if let bonusPoints = checkSurpriseBonus() {
            pointsEarned += bonusPoints
            debugPrint("🎁 Surprise bonus generated: \(bonusPoints) points")
            triggerSurpriseBonusNotification(points: bonusPoints)
        }
        
        gameStats.totalPoints += pointsEarned
        debugPrint("💰 Total points for this entry: \(pointsEarned) (New Total: \(gameStats.totalPoints))")
        
        // Update streak
        updateStreak(entryDate: entry.createdAt)
        
        // Update level
        updateLevel()
        
        // Check for new achievements
        checkAchievements()
        
        saveGameStats()
    }
    
    private func calculatePointsForEntry(_ entry: SupabaseJournalEntry) -> Int {
        var points = 20 // Base points for any entry
        
        // Bonus for mood tracking
        if entry.mood != nil {
            points += 10
        }
        
        // Bonus for gratitude items
        if let gratitude = entry.gratitudeItems, !gratitude.isEmpty {
            points += gratitude.count * 5
        }
        
        // Bonus for word count
        let wordCount = entry.content.components(separatedBy: .whitespacesAndNewlines).count
        if wordCount >= 50 {
            points += 10
        }
        if wordCount >= 200 {
            points += 20
        }
        if wordCount >= 500 {
            points += 30
        }
        
        // Streak bonus
        if gameStats.currentStreak >= 3 {
            points += 10
        }
        if gameStats.currentStreak >= 7 {
            points += 20
        }
        
        return points
    }
    
    private func updateStreak(entryDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let entryDay = calendar.startOfDay(for: entryDate)
        let lastEntryDate = gameStats.lastEntryDate ?? Date.distantPast
        let lastEntryDay = calendar.startOfDay(for: lastEntryDate)

        if calendar.isDate(entryDay, inSameDayAs: today) {
            // Entry for today - only update streak if this is the first entry today
            if !calendar.isDate(lastEntryDay, inSameDayAs: today) {
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

                if calendar.isDate(lastEntryDay, inSameDayAs: yesterday) {
                    // Continue streak from yesterday
                    gameStats.currentStreak += 1
                } else {
                    // Start new streak
                    gameStats.currentStreak = 1
                }
            }
            // If lastEntryDay was also today, don't change the streak

        } else if calendar.isDate(entryDay, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
            // Entry for yesterday - only update if this is the first entry for yesterday
            if !calendar.isDate(lastEntryDay, inSameDayAs: entryDay) {
                gameStats.currentStreak += 1
            }
        } else {
            // Entry for other day - start new streak
            gameStats.currentStreak = 1
        }

        if gameStats.currentStreak > gameStats.longestStreak {
            gameStats.longestStreak = gameStats.currentStreak
        }
    }
    
    private func updateLevel() {
        let currentLevelData = JournalLevel.levelForPoints(gameStats.totalPoints)
        if currentLevelData.level > gameStats.level {
            let previousLevel = gameStats.level
            gameStats.level = currentLevelData.level
            
            // Trigger level up celebration
            triggerLevelUpCelebration(from: previousLevel, to: currentLevelData)
        }
    }
    
    private func triggerLevelUpCelebration(from previousLevel: Int, to newLevelData: JournalLevel) {
        debugPrint("🆙 Level Up! \(previousLevel) -> \(newLevelData.level)")
        // Post notification for level up celebration
        NotificationCenter.default.post(
            name: NSNotification.Name("LevelUpAchieved"),
            object: LevelUpInfo(
                previousLevel: previousLevel,
                newLevel: newLevelData,
                pointsEarned: gameStats.totalPoints
            )
        )
    }
    
    // MARK: - Achievement System
    
    func checkAchievements(totalEntries: Int? = nil) {
        let entryCount = totalEntries ?? gameStats.totalEntries
        
        for achievement in JournalAchievement.achievements {
            if !gameStats.unlockedAchievements.contains(achievement.id) {
                if checkAchievementRequirement(achievement.requirement, entryCount: entryCount) {
                    unlockAchievement(achievement)
                }
            }
        }
    }
    
    private func checkAchievementRequirement(_ requirement: JournalAchievement.AchievementRequirement, entryCount: Int) -> Bool {
        switch requirement {
        case .firstEntry:
            return entryCount >= 1
            
        case .streak(let days):
            return gameStats.currentStreak >= days
            
        case .totalEntries(let count):
            return entryCount >= count
            
        case .moodImprovement:
            return getMoodTrackingCount() >= 10
            
        case .gratitudePractice(let days):
            // Simplified - check if user has been consistent with entries
            return gameStats.currentStreak >= days
            
        case .reflectionDepth(let words):
            // Check if user has written long entries
            return hasWrittenLongEntry(minWords: words)
            
        case .consistency(let weeks):
            // Check if user has maintained activity for weeks
            return gameStats.currentStreak >= (weeks * 7)
            
        case .timeOfDay(_, _, let count):
            return entryCount >= count
            
        case .weekendConsistency(let weeks):
            // Simplified - check general consistency
            return gameStats.currentStreak >= (weeks * 2)
            
        case .voiceUsage(let count):
            // Track voice usage count
            return getVoiceUsageCount() >= count
            
        case .moodTracking(let count):
            return getMoodTrackingCount() >= count
            
        case .positiveMood(let count):
            // Simplified - check if user has been tracking mood regularly
            return getMoodTrackingCount() >= count && getAverageRecentMood() >= 7.0
        }
    }
    
    private func hasWrittenLongEntry(minWords: Int) -> Bool {
        return UserDefaults.standard.integer(forKey: "journal_long_entries_\(minWords)") > 0
    }
    
    private func getVoiceUsageCount() -> Int {
        return UserDefaults.standard.integer(forKey: "journal_voice_usage_count")
    }
    
    private func getMoodTrackingCount() -> Int {
        return UserDefaults.standard.integer(forKey: "journal_mood_tracking_count")
    }
    
    private func getAverageRecentMood() -> Double {
        return UserDefaults.standard.double(forKey: "journal_average_recent_mood")
    }
    
    private func trackLongEntry(_ entry: SupabaseJournalEntry) {
        let wordCount = entry.content.components(separatedBy: .whitespacesAndNewlines).count
        
        // Track different word count milestones
        if wordCount >= 100 {
            let count = UserDefaults.standard.integer(forKey: "journal_long_entries_100") + 1
            UserDefaults.standard.set(count, forKey: "journal_long_entries_100")
        }
        if wordCount >= 300 {
            let count = UserDefaults.standard.integer(forKey: "journal_long_entries_300") + 1
            UserDefaults.standard.set(count, forKey: "journal_long_entries_300")
        }
        if wordCount >= 500 {
            let count = UserDefaults.standard.integer(forKey: "journal_long_entries_500") + 1
            UserDefaults.standard.set(count, forKey: "journal_long_entries_500")
        }
    }
    
    private func trackMoodEntry(_ entry: SupabaseJournalEntry) {
        if entry.mood != nil {
            let count = UserDefaults.standard.integer(forKey: "journal_mood_tracking_count") + 1
            UserDefaults.standard.set(count, forKey: "journal_mood_tracking_count")
            
            // Update average recent mood (simple running average)
            if let mood = entry.mood {
                let currentAvg = UserDefaults.standard.double(forKey: "journal_average_recent_mood")
                let newAvg = currentAvg == 0 ? Double(mood) : (currentAvg + Double(mood)) / 2
                UserDefaults.standard.set(newAvg, forKey: "journal_average_recent_mood")
            }
        }
    }
    
    private func unlockAchievement(_ achievement: JournalAchievement) {
        debugPrint("🔓 Unlocking achievement: \(achievement.title) (ID: \(achievement.id))")
        gameStats.unlockedAchievements.insert(achievement.id)
        gameStats.totalPoints += achievement.points
        
        // Post notification for achievement unlocked - both old and new system
        NotificationCenter.default.post(
            name: NSNotification.Name("AchievementUnlocked"),
            object: achievement
        )
        
        // Trigger achievement celebration UI
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAchievementCelebration"),
            object: achievement
        )
        
        // Sync to database if user is authenticated
        if let currentUser = databaseService.currentUser {
            Task {
                do {
                    try await databaseService.recordAchievement(
                        userId: currentUser.id,
                        achievementId: achievement.id,
                        pointsEarned: achievement.points
                    )
                } catch {
                    debugPrint("Failed to sync achievement unlock to database: \(error)")
                }
            }
        }
        
        saveGameStats()
    }
    
    // MARK: - Statistics
    
    func getWeeklyProgress() -> [Int] {
        // Return array of entries for each day of the week
        // Placeholder implementation
        return Array(repeating: 0, count: 7)
    }
    
    func getMonthlyGoalProgress() -> Double {
        guard gameStats.monthlyGoal > 0 else { return 0.0 }
        return min(Double(gameStats.totalEntries) / Double(gameStats.monthlyGoal), 1.0)
    }
    
    func getStreakMessage() -> String {
        switch gameStats.currentStreak {
        case 0:
            return "Start your journaling streak today!"
        case 1:
            return "Great start! Keep it going tomorrow."
        case 2...6:
            return "Building momentum! \(gameStats.currentStreak) days strong."
        case 7...13:
            return "Impressive streak! \(gameStats.currentStreak) days of self-reflection."
        case 14...29:
            return "Amazing dedication! \(gameStats.currentStreak) days of growth."
        default:
            return "Incredible! \(gameStats.currentStreak) days of consistent journaling."
        }
    }
    
    // MARK: - Progress Proximity System
    
    func getProgressProximityStatus() -> ProgressProximityStatus {
        var proximityItems: [ProximityItem] = []
        
        // Check next level proximity
        if let nextLevelItem = checkNextLevelProximity() {
            proximityItems.append(nextLevelItem)
        }
        
        // Check closest achievements
        proximityItems.append(contentsOf: getCloseAchievements())
        
        // Sort by proximity (closest first)
        proximityItems.sort { $0.progressPercentage > $1.progressPercentage }
        
        return ProgressProximityStatus(items: proximityItems)
    }
    
    private func checkNextLevelProximity() -> ProximityItem? {
        let currentLevel = JournalLevel.levelForPoints(gameStats.totalPoints)
        let nextLevelIndex = JournalLevel.journalLevels.firstIndex { $0.level > currentLevel.level }
        
        guard let nextIndex = nextLevelIndex,
              nextIndex < JournalLevel.journalLevels.count else {
            return nil // Already at max level
        }
        
        let nextLevel = JournalLevel.journalLevels[nextIndex]
        let pointsNeeded = nextLevel.requiredPoints - gameStats.totalPoints
        let denominator = nextLevel.requiredPoints - currentLevel.requiredPoints
        let numerator = gameStats.totalPoints - currentLevel.requiredPoints
        let progress: Double
        if denominator > 0 && numerator >= 0 {
            let calculatedProgress = Double(numerator) / Double(denominator)
            progress = calculatedProgress.isNaN || calculatedProgress.isInfinite ? 0.0 : min(calculatedProgress, 1.0)
        } else {
            progress = 0.0
        }
        
        // Only show if within reasonable proximity (>50% or <100 points away)
        if progress > 0.5 || pointsNeeded <= 100 {
            return ProximityItem(
                id: "level_\(nextLevel.level)",
                type: .levelUp,
                title: "Level Up: \(nextLevel.title)",
                description: "\(pointsNeeded) more points to reach level \(nextLevel.level)",
                progressPercentage: progress,
                pointsNeeded: pointsNeeded,
                icon: "arrow.up.circle.fill",
                color: nextLevel.color
            )
        }
        
        return nil
    }
    
    private func getCloseAchievements() -> [ProximityItem] {
        var closeItems: [ProximityItem] = []
        
        for achievement in JournalAchievement.achievements {
            if gameStats.unlockedAchievements.contains(achievement.id) {
                continue // Skip already unlocked
            }
            
            if let proximityItem = checkAchievementProximity(achievement) {
                closeItems.append(proximityItem)
            }
        }
        
        // Return top 3 closest achievements
        return Array(closeItems.sorted { $0.progressPercentage > $1.progressPercentage }.prefix(3))
    }
    
    private func checkAchievementProximity(_ achievement: JournalAchievement) -> ProximityItem? {
        switch achievement.requirement {
        case .totalEntries(let count):
            let progress: Double
            if count > 0 {
                let calculatedProgress = Double(gameStats.totalEntries) / Double(count)
                progress = calculatedProgress.isNaN || calculatedProgress.isInfinite ? 0.0 : min(calculatedProgress, 1.0)
            } else {
                progress = 0.0
            }
            let remaining = count - gameStats.totalEntries
            if progress > 0.6 || remaining <= 5 {
                return ProximityItem(
                    id: achievement.id,
                    type: .achievement,
                    title: achievement.title,
                    description: "\(remaining) more entries needed",
                    progressPercentage: progress,
                    pointsNeeded: remaining,
                    icon: achievement.icon,
                    color: achievement.color
                )
            }
            
        case .streak(let days):
            let progress: Double
            if days > 0 {
                let calculatedProgress = Double(gameStats.currentStreak) / Double(days)
                progress = calculatedProgress.isNaN || calculatedProgress.isInfinite ? 0.0 : min(calculatedProgress, 1.0)
            } else {
                progress = 0.0
            }
            let remaining = days - gameStats.currentStreak
            if progress > 0.5 || remaining <= 3 {
                return ProximityItem(
                    id: achievement.id,
                    type: .achievement,
                    title: achievement.title,
                    description: "\(remaining) more days needed",
                    progressPercentage: progress,
                    pointsNeeded: remaining,
                    icon: achievement.icon,
                    color: achievement.color
                )
            }
            
        case .reflectionDepth(let words):
            // Check if user has written entries close to this word count
            if words <= 300 && gameStats.totalEntries >= 3 {
                return ProximityItem(
                    id: achievement.id,
                    type: .achievement,
                    title: achievement.title,
                    description: "Write a \(words)+ word entry",
                    progressPercentage: 0.7, // Assume they're close
                    pointsNeeded: 1,
                    icon: achievement.icon,
                    color: achievement.color
                )
            }
            
        case .moodTracking(let count):
            let currentCount = getMoodTrackingCount()
            let progress: Double
            if count > 0 {
                let calculatedProgress = Double(currentCount) / Double(count)
                progress = calculatedProgress.isNaN || calculatedProgress.isInfinite ? 0.0 : min(calculatedProgress, 1.0)
            } else {
                progress = 0.0
            }
            let remaining = count - currentCount
            if progress > 0.5 || remaining <= 3 {
                return ProximityItem(
                    id: achievement.id,
                    type: .achievement,
                    title: achievement.title,
                    description: "\(remaining) more mood logs needed",
                    progressPercentage: progress,
                    pointsNeeded: remaining,
                    icon: achievement.icon,
                    color: achievement.color
                )
            }
            
        default:
            // For other achievement types, use simplified logic
            if gameStats.totalEntries >= 5 {
                return ProximityItem(
                    id: achievement.id,
                    type: .achievement,
                    title: achievement.title,
                    description: "Keep journaling to unlock!",
                    progressPercentage: 0.6,
                    pointsNeeded: 1,
                    icon: achievement.icon,
                    color: achievement.color
                )
            }
        }
        
        return nil
    }
    
    func resetGameStats() {
        gameStats = JournalGameStats()
        saveGameStats()
    }
    
    // MARK: - Surprise Bonus System
    
    private func checkSurpriseBonus() -> Int? {
        let hour = Calendar.current.component(.hour, from: Date())
        let userActivity = gameStats.totalEntries
        let lastBonusDay = UserDefaults.standard.integer(forKey: "last_surprise_bonus_day")
        let currentDay = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        
        // Base chance: 8%
        var bonusChance: Double = 0.08
        
        // Increase chance during evening hours (when people typically journal)
        if hour >= 18 && hour <= 22 {
            bonusChance += 0.05
        }
        
        // Increase chance for newer users (first 10 entries)
        if userActivity <= 10 {
            bonusChance += 0.07
        }
        
        // Increase chance for users with good streaks
        if gameStats.currentStreak >= 3 {
            bonusChance += 0.03
        }
        
        // Prevent multiple bonuses per day
        if lastBonusDay == currentDay {
            bonusChance = 0
        }
        
        let randomChance = Double.random(in: 0...1)
        
        if randomChance < bonusChance {
            UserDefaults.standard.set(currentDay, forKey: "last_surprise_bonus_day")
            return generateBonusAmount()
        }
        
        return nil
    }
    
    private func generateBonusAmount() -> Int {
        // Weighted random bonus amounts
        let bonusOptions = [
            (points: 10, weight: 40),  // 40% chance - small bonus
            (points: 25, weight: 30),  // 30% chance - medium bonus
            (points: 50, weight: 20),  // 20% chance - large bonus
            (points: 100, weight: 8),  // 8% chance - huge bonus
            (points: 200, weight: 2)   // 2% chance - jackpot!
        ]
        
        let totalWeight = bonusOptions.reduce(0) { $0 + $1.weight }
        let randomWeight = Int.random(in: 1...totalWeight)
        
        var currentWeight = 0
        for option in bonusOptions {
            currentWeight += option.weight
            if randomWeight <= currentWeight {
                return option.points
            }
        }
        
        return 25 // Fallback
    }
    
    private func triggerSurpriseBonusNotification(points: Int) {
        debugPrint("🔔 Posting notification: SurpriseBonusEarned (\(points) pts)")
        NotificationCenter.default.post(
            name: NSNotification.Name("SurpriseBonusEarned"),
            object: points
        )
    }
}

// MARK: - Extensions for integration

extension JournalGameStatsManager {
    func simulateJournalEntry(wordCount: Int, hasMood: Bool, gratitudeCount: Int) {
        let entry = SupabaseJournalEntry(
            id: UUID(),
            userId: UUID(),
            createdAt: Date(),
            updatedAt: Date(),
            title: "Test Entry",
            content: String(repeating: "word ", count: wordCount),
            mood: hasMood ? 7 : nil,
            gratitudeItems: gratitudeCount > 0 ? Array(repeating: "Grateful for...", count: gratitudeCount) : nil,
            tags: nil,
            isPrivate: false
        )
        
        processNewJournalEntry(entry)
    }
    
    // MARK: - Meditation Integration
    
    func awardMeditationPoints(sessionId: UUID, points: Int, category: MeditationCategory) {
        gameStats.totalPoints += points
        
        // Update level
        updateLevel()
        
        // Track meditation achievements
        checkMeditationAchievements(sessionId: sessionId, category: category)
        
        saveGameStats()
        
        debugPrint("✅ Awarded \(points) points for meditation session")
    }
    
    private func checkMeditationAchievements(sessionId: UUID, category: MeditationCategory) {
        // Track first meditation
        if !gameStats.unlockedAchievements.contains("first_meditation") {
            unlockAchievement("first_meditation")
        }
        
        // Track category-specific achievements
        switch category {
        case .anxiety:
            if !gameStats.unlockedAchievements.contains("anxiety_warrior") {
                // Check if user has completed 5 anxiety sessions
                // This would require database query in production
                unlockAchievement("anxiety_warrior")
            }
        case .sleep:
            if !gameStats.unlockedAchievements.contains("sleep_champion") {
                unlockAchievement("sleep_champion")
            }
        case .all, .focus, .breathwork, .body, .sounds:
            break
        }
    }
    
    private func unlockAchievement(_ achievementId: String) {
        guard !gameStats.unlockedAchievements.contains(achievementId) else { return }
        
        gameStats.unlockedAchievements.insert(achievementId)
        
        if let achievement = JournalAchievement.achievements.first(where: { $0.id == achievementId }) {
            gameStats.totalPoints += achievement.points
            
            // Record in database
            if let userId = databaseService.currentUser?.id {
                Task {
                    do {
                        try await databaseService.recordAchievement(
                            userId: userId,
                            achievementId: achievementId,
                            pointsEarned: achievement.points
                        )
                    } catch {
                        debugPrint("❌ Failed to record achievement in database: \(error)")
                    }
                }
            }
            
            debugPrint("🏆 Achievement unlocked: \(achievement.title) (+\(achievement.points) points)")
        }
    }
}