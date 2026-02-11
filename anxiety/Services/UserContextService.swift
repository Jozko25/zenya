//
//  UserContextService.swift
//  anxiety
//
//  Provides user context data for AI conversations
//

import Foundation

@MainActor
class UserContextService {
    static let shared = UserContextService()
    private let database = DatabaseService.shared
    
    private init() {}
    
    func generateContextSummary() async -> String {
        guard let userId = database.currentUser?.id else {
            return "No user data available."
        }
        
        var contextParts: [String] = []
        
        async let journalData = fetchJournalContext(userId: userId)
        async let statsData = fetchStatsContext(userId: userId)
        
        let (journal, stats) = await (journalData, statsData)
        
        if let journal = journal {
            contextParts.append(journal)
        }
        if let stats = stats {
            contextParts.append(stats)
        }
        
        if contextParts.isEmpty {
            return """
            USER CONTEXT:
            - New user with no journal entries yet
            - Encourage them to start journaling in the Feel tab to track their progress
            """
        }
        
        return """
        USER CONTEXT (Use this to personalize responses):
        
        \(contextParts.joined(separator: "\n\n"))
        
        IMPORTANT: Reference this data naturally when relevant. For example:
        - "I see you've been journaling consistently for the past week"
        - "Your mood has been improving - from an average of 5 to 7 over the last 7 days"
        - "You're on a 3-day streak! Keep it up!"
        """
    }
    
    private func fetchJournalContext(userId: UUID) async -> String? {
        do {
            let entries = try await database.getJournalEntries(userId: userId, limit: 30)
            guard !entries.isEmpty else { return nil }
            
            let last7Days = entries.filter { 
                Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 999 < 7
            }
            
            let last30Days = entries.filter {
                Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 999 < 30
            }
            
            let totalWords = entries.reduce(0) { count, entry in
                count + entry.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
            }
            
            let avgWordsPerEntry = entries.isEmpty ? 0 : totalWords / entries.count
            
            let recentMoods = entries.prefix(10).compactMap { $0.mood }
            let avgRecentMood = recentMoods.isEmpty ? nil : Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
            
            var context = """
            JOURNAL DATA:
            - Total entries (last 30 days): \(last30Days.count)
            - Entries this week: \(last7Days.count)
            - Average words per entry: \(avgWordsPerEntry)
            """
            
            if let avgMood = avgRecentMood {
                context += "\n- Recent average mood (last 10 entries): \(String(format: "%.1f", avgMood))/10"
            }
            
            if let lastEntry = entries.first {
                let daysSince = Calendar.current.dateComponents([.day], from: lastEntry.createdAt, to: Date()).day ?? 0
                context += "\n- Last journal entry: \(formatRelativeDate(lastEntry.createdAt))"
                
                if daysSince == 0 {
                    context += " (today!)"
                } else if daysSince == 1 {
                    context += " (yesterday)"
                }
            }
            
            let gratitudeCount = entries.reduce(0) { count, entry in
                count + (entry.gratitudeItems?.count ?? 0)
            }
            if gratitudeCount > 0 {
                context += "\n- Total gratitude items recorded: \(gratitudeCount)"
            }
            
            return context
            
        } catch {
            debugPrint("❌ Failed to fetch journal context: \(error)")
            return nil
        }
    }
    
    private func fetchStatsContext(userId: UUID) async -> String? {
        do {
            let stats = try await database.loadGameStatsFromDatabase(userId)
            
            var context = """
            PROGRESS & ACHIEVEMENTS:
            - Level: \(stats.level)
            - Total points: \(stats.totalPoints)
            - Current streak: \(stats.currentStreak) days
            - Longest streak: \(stats.longestStreak) days
            - Total journal entries: \(stats.totalEntries)
            """
            
            if stats.currentStreak >= 7 {
                context += "\n- 🔥 On fire! Week+ streak!"
            } else if stats.currentStreak >= 3 {
                context += "\n- 💪 Building momentum with a \(stats.currentStreak)-day streak"
            }
            
            return context
            
        } catch {
            debugPrint("❌ Failed to fetch stats context: \(error)")
            return nil
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Structured Context for UI Display

    func fetchUserContextSummary() async -> (journalCount: Int, streak: Int, avgMood: Double?, lastEntry: Date?, level: Int, points: Int, gratitudeCount: Int) {
        guard let userId = database.currentUser?.id else {
            return (0, 0, nil, nil, 1, 0, 0)
        }

        var journalCount = 0
        var avgMood: Double? = nil
        var lastEntry: Date? = nil
        var gratitudeCount = 0
        var streak = 0
        var level = 1
        var points = 0

        // Fetch journal data
        do {
            let entries = try await database.getJournalEntries(userId: userId, limit: 30)
            journalCount = entries.count
            lastEntry = entries.first?.createdAt

            let moods = entries.compactMap { $0.mood }
            if !moods.isEmpty {
                avgMood = Double(moods.reduce(0, +)) / Double(moods.count)
            }

            gratitudeCount = entries.reduce(0) { $0 + ($1.gratitudeItems?.count ?? 0) }
        } catch {
            debugPrint("❌ Failed to fetch journal entries for summary: \(error)")
        }

        // Fetch stats
        do {
            let stats = try await database.loadGameStatsFromDatabase(userId)
            streak = stats.currentStreak
            level = stats.level
            points = stats.totalPoints
        } catch {
            debugPrint("❌ Failed to fetch stats for summary: \(error)")
        }

        return (journalCount, streak, avgMood, lastEntry, level, points, gratitudeCount)
    }
}
