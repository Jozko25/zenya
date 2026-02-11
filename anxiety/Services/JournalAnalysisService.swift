//
//  JournalAnalysisService.swift
//  anxiety
//
//  AI-powered daily journal analysis using GPT-4o-mini
//
//  FLOW:
//  1. User submits journal entry via GamifiedJournalEntryView
//  2. After submission, checkAndAnalyzeIfNeeded() is called automatically
//  3. Service analyzes all entries from today using GPT-4o-mini
//  4. Evaluation is saved to database (journal_evaluations table)
//  5. Notification is sent when evaluation completes
//  6. User can view evaluation history in EvaluationsModalView
//

import Foundation
import UserNotifications

// MARK: - Analysis Models

struct DailyJournalAnalysis: Codable, Identifiable {
    let id: UUID
    let date: Date
    let analysisText: String?
    let maturityScore: Int
    let moodScore: Int?
    let keyInsights: [String]
    let emotionalThemes: [String]
    let growthAreas: [String]
    let summary: String
    let entryCount: Int
    let userId: String
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case date = "evaluation_date"
        case analysisText = "analyzed_content"
        case maturityScore = "maturity_score"
        case moodScore = "mood_score"
        case keyInsights = "key_insights"
        case emotionalThemes = "emotional_themes"
        case growthAreas = "growth_areas"
        case summary
        case entryCount = "entry_count"
        case userId = "user_id"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        analysisText: String? = nil,
        maturityScore: Int,
        moodScore: Int? = nil,
        keyInsights: [String],
        emotionalThemes: [String],
        growthAreas: [String],
        summary: String,
        entryCount: Int,
        userId: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.analysisText = analysisText
        self.maturityScore = maturityScore
        self.moodScore = moodScore
        self.keyInsights = keyInsights
        self.emotionalThemes = emotionalThemes
        self.growthAreas = growthAreas
        self.summary = summary
        self.entryCount = entryCount
        self.userId = userId
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        analysisText = try container.decodeIfPresent(String.self, forKey: .analysisText)
        maturityScore = try container.decode(Int.self, forKey: .maturityScore)
        moodScore = try container.decodeIfPresent(Int.self, forKey: .moodScore)
        keyInsights = try container.decode([String].self, forKey: .keyInsights)
        emotionalThemes = try container.decode([String].self, forKey: .emotionalThemes)
        growthAreas = try container.decode([String].self, forKey: .growthAreas)
        summary = try container.decode(String.self, forKey: .summary)
        entryCount = try container.decode(Int.self, forKey: .entryCount)
        userId = try container.decode(String.self, forKey: .userId)
        
        // Decode date (can be Date or String)
        // IMPORTANT: Try string first because JSONDecoder may incorrectly decode "2025-12-21" as Date
        // with wrong timezone, causing day-shift issues
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            // Use UTC timezone and add 12 hours to get noon, avoiding day boundary issues
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            if let parsedDate = dateFormatter.date(from: dateString) {
                date = parsedDate.addingTimeInterval(12 * 60 * 60)
            } else {
                // Try ISO8601 format as fallback
                let iso8601Formatter = ISO8601DateFormatter()
                date = iso8601Formatter.date(from: dateString) ?? Date()
            }
        } else if let dateValue = try? container.decode(Date.self, forKey: .date) {
            // Fallback to Date decoding if string fails
            date = dateValue
        } else {
            date = Date()
        }
        
        // Decode createdAt (can be Date or String or nil)
        if let createdValue = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = createdValue
        } else if let createdString = try? container.decode(String.self, forKey: .createdAt) {
            let iso8601Formatter = ISO8601DateFormatter()
            createdAt = iso8601Formatter.date(from: createdString)
        } else {
            createdAt = nil
        }
    }

    // For display formatting
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    var maturityDescription: String {
        switch maturityScore {
        case 1...3: return "Developing"
        case 4...6: return "Growing"
        case 7...8: return "Mature"
        case 9...10: return "Highly Mature"
        default: return "Developing"
        }
    }

    var maturityColor: String {
        switch maturityScore {
        case 1...3: return "FFA500" // Orange
        case 4...6: return "3B82F6" // Blue
        case 7...8: return "10B981" // Green
        case 9...10: return "FF4F9A" // Pink
        default: return "6B7280" // Gray
        }
    }
}

struct AnalysisResponse: Codable {
    let maturityScore: Int
    let moodScore: Int?  // NEW: 1-10 scale for emotional state (1=very low, 10=very happy)
    let keyInsights: [String]
    let emotionalThemes: [String]
    let growthAreas: [String]
    let summary: String
}

// MARK: - Analysis Service

class JournalAnalysisService: ObservableObject {
    static let shared = JournalAnalysisService()

    @Published var analyses: [DailyJournalAnalysis] = []
    @Published var isAnalyzing = false

    private let openAIClient = OpenAIClient()
    private let databaseService = DatabaseService.shared
    private let httpClient = SupabaseHTTPClient.shared
    
    private var analysisTask: Task<Void, Never>?
    
    // Local storage key
    private let localAnalysesKey = "local_journal_evaluations"

    private init() {
        Task {
            await loadEvaluations()
        }
    }
    
    // MARK: - Local Storage Helpers
    
    private func saveAnalysesLocally() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let encoded = try? encoder.encode(analyses) {
            UserDefaults.standard.set(encoded, forKey: localAnalysesKey)
            debugPrint("💾 Saved \(analyses.count) evaluations to local storage")
        }
    }
    
    private func loadAnalysesLocally() -> [DailyJournalAnalysis] {
        guard let data = UserDefaults.standard.data(forKey: localAnalysesKey) else {
            debugPrint("📱 No local evaluations found")
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let decoded = try? decoder.decode([DailyJournalAnalysis].self, from: data) {
            debugPrint("📱 Loaded \(decoded.count) evaluations from local storage")
            return decoded
        }
        
        return []
    }

    // MARK: - Public Methods

    func checkAndAnalyzeIfNeeded() async {
        let userId = await MainActor.run { databaseService.currentUser?.id.uuidString }
        guard let userId = userId else {
            debugPrint("❌ No current user found for analysis check")
            return
        }
        await checkAndAnalyzeIfNeeded(for: userId)
    }
    
    func analyzeHistoricalEntries(for userId: String) async {
        await MainActor.run { isAnalyzing = true }
        
        debugPrint("📚 Starting historical analysis for user: \(userId)")
        
        // Get all entries grouped by day
        guard let userUUID = UUID(uuidString: userId) else {
            debugPrint("❌ Invalid user ID")
            await MainActor.run { isAnalyzing = false }
            return
        }
        
        let allEntries: [SupabaseJournalEntry]
        do {
            allEntries = try await databaseService.getJournalEntries(userId: userUUID, limit: 1000)
        } catch {
            debugPrint("❌ Failed to fetch journal entries: \(error)")
            await MainActor.run { isAnalyzing = false }
            return
        }
        
        // Group entries by date
        var entriesByDate: [Date: [SupabaseJournalEntry]] = [:]
        let calendar = Calendar.current
        
        for entry in allEntries {
            let entryDate = entry.createdAt
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: entryDate)
            if let dayStart = calendar.date(from: dateComponents) {
                entriesByDate[dayStart, default: []].append(entry)
            }
        }
        
        debugPrint("📊 Found entries across \(entriesByDate.count) different days")
        
        // Analyze each day that doesn't have an analysis yet
        for (date, entries) in entriesByDate.sorted(by: { $0.key > $1.key }) {
            // Check if we already have an analysis for this date
            let hasExistingAnalysis = await MainActor.run {
                analyses.contains { calendar.isDate($0.date, inSameDayAs: date) }
            }
            
            if !hasExistingAnalysis && entries.count >= 1 {
                debugPrint("✍️ Analyzing \(entries.count) entries from \(date)")
                
                let combinedContent = entries.map(\.content).joined(separator: "\n\n---\n\n")
                
                do {
                    let analysis = try await analyzeJournalContent(combinedContent, entryCount: entries.count)
                    let moodScore = max(1, min(10, analysis.moodScore ?? 6))
                    
                    // Apply mood score back to individual entries
                    await applyMoodScore(moodScore, to: entries, userId: userId)
                    
                    let dailyAnalysis = DailyJournalAnalysis(
                        date: date,
                        analysisText: combinedContent,
                        maturityScore: analysis.maturityScore,
                        moodScore: moodScore,
                        keyInsights: analysis.keyInsights,
                        emotionalThemes: analysis.emotionalThemes,
                        growthAreas: analysis.growthAreas,
                        summary: analysis.summary,
                        entryCount: entries.count,
                        userId: userId
                    )
                    
                    do {
                        try await saveEvaluationToDatabase(dailyAnalysis)
                        
                        await MainActor.run {
                            analyses.append(dailyAnalysis)
                            analyses.sort { $0.date > $1.date }
                        }
                    } catch {
                        debugPrint("❌ Failed to save historical evaluation: \(error)")
                    }
                    
                    // Small delay to avoid rate limiting
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    
                } catch {
                    debugPrint("❌ Failed to analyze entries from \(date): \(error)")
                }
            }
        }
        
        await MainActor.run { isAnalyzing = false }
        debugPrint("✅ Historical analysis complete - \(analyses.count) total analyses")
    }

    func checkAndAnalyzeIfNeeded(for userId: String) async {
        analysisTask?.cancel()
        
        analysisTask = Task {
            guard !Task.isCancelled else {
                debugPrint("⚠️ Analysis task was cancelled")
                return
            }
            
            debugPrint("🔍 Checking analysis for user: \(userId)")

            let todaysEntries = await getTodaysEntries(for: userId)
            debugPrint("📊 Found \(todaysEntries.count) today's entries")
            
            // Always generate evaluation after journal submission if we have entries
            if !todaysEntries.isEmpty && !Task.isCancelled {
                let hasAnalysis = hasAnalysisForToday()
                debugPrint("📊 Has analysis for today: \(hasAnalysis)")
                
                let shouldUpdate = hasAnalysis ? shouldUpdateAnalysis(for: todaysEntries) : true
                debugPrint("📊 Should update analysis: \(shouldUpdate)")
                
                if shouldUpdate {
                    debugPrint("✅ Triggering analysis...")
                    await performDailyAnalysis(entries: todaysEntries, userId: userId)
                } else {
                    debugPrint("⏭️ Skipping analysis - already up to date")
                }
            } else {
                debugPrint("⏭️ Skipping analysis - no entries yet")
            }
        }
        
        await analysisTask?.value
    }

    private func shouldUpdateAnalysis(for entries: [SupabaseJournalEntry]) -> Bool {
        // If we have existing analysis for today, check if we have new entries since then
        guard let todaysAnalysis = analyses.first(where: { Calendar.current.isDateInToday($0.date) }) else {
            return true // No analysis exists, should create one
        }

        // Update analysis if we have different number of entries than what was previously analyzed
        // This catches both new entries and if user somehow has fewer entries
        return entries.count != todaysAnalysis.entryCount
    }

    func performDailyAnalysis(entries: [SupabaseJournalEntry], userId: String) async {
        debugPrint("🎯 performDailyAnalysis started with \(entries.count) entries")
        await MainActor.run { isAnalyzing = true }

        let combinedContent = entries.map(\.content).joined(separator: "\n\n---\n\n")
        debugPrint("📝 Combined content length: \(combinedContent.count) characters")

        do {
            debugPrint("🤖 Calling OpenAI for analysis...")
            let analysis = try await analyzeJournalContent(combinedContent, entryCount: entries.count)
            debugPrint("✅ OpenAI analysis completed")
            let moodScore = max(1, min(10, analysis.moodScore ?? 6))
            
            // Apply mood score back to each entry for prediction accuracy
            await applyMoodScore(moodScore, to: entries, userId: userId)

            let dailyAnalysis = DailyJournalAnalysis(
                date: Date(),
                analysisText: combinedContent,
                maturityScore: analysis.maturityScore,
                moodScore: moodScore,
                keyInsights: analysis.keyInsights,
                emotionalThemes: analysis.emotionalThemes,
                growthAreas: analysis.growthAreas,
                summary: analysis.summary,
                entryCount: entries.count,
                userId: userId
            )

            // Save to database
            do {
                try await saveEvaluationToDatabase(dailyAnalysis)
                
                await MainActor.run {
                    // Remove any existing analysis for today before adding the new one
                    analyses.removeAll { Calendar.current.isDateInToday($0.date) }
                    
                    // Insert new analysis at the beginning
                    analyses.insert(dailyAnalysis, at: 0)
                    
                    // Sort by date (newest first)
                    analyses.sort { $0.date > $1.date }
                    
                    isAnalyzing = false
                }
            } catch {
                debugPrint("❌ Failed to save evaluation to database: \(error)")
                await MainActor.run { isAnalyzing = false }
            }
            
            // Schedule notification that evaluation is ready
            Task { @MainActor in
                NotificationManager.shared.scheduleAnalysisCompletedNotification()
                
                // Post notification for UI to refresh
                NotificationCenter.default.post(
                    name: Notification.Name("EvaluationCompleted"),
                    object: nil,
                    userInfo: ["evaluation": dailyAnalysis]
                )
            }

        } catch {
            debugPrint("❌ Analysis failed: \(error)")
            await MainActor.run { isAnalyzing = false }
        }
    }

    // MARK: - Private Methods

    private func analyzeJournalContent(_ content: String, entryCount: Int) async throws -> AnalysisResponse {
        debugPrint("📤 Sending to OpenAI...")
        let response = try await openAIClient.sendMessage(
            buildAnalysisPrompt(content: content, entryCount: entryCount),
            conversationHistory: [] as [SimpleChatMessage] // No conversation history needed for analysis
        )
        debugPrint("📥 Received response from OpenAI: \(response.prefix(100))...")

        // Clean the response - extract JSON from response
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If response contains text before JSON, extract just the JSON object
        if let jsonStart = cleanedResponse.range(of: "{") {
            cleanedResponse = String(cleanedResponse[jsonStart.lowerBound...])
            // Find the matching closing brace
            var braceCount = 0
            var endIndex = cleanedResponse.startIndex
            for (index, char) in cleanedResponse.enumerated() {
                if char == "{" { braceCount += 1 }
                else if char == "}" { 
                    braceCount -= 1
                    if braceCount == 0 {
                        endIndex = cleanedResponse.index(cleanedResponse.startIndex, offsetBy: index)
                        break
                    }
                }
            }
            if braceCount == 0 && endIndex != cleanedResponse.startIndex {
                cleanedResponse = String(cleanedResponse[...endIndex])
            }
        }

        debugPrint("🧹 Cleaned response: \(cleanedResponse.prefix(200))...")

        // Parse JSON response
        guard let data = cleanedResponse.data(using: .utf8),
              let analysisResponse = try? JSONDecoder().decode(AnalysisResponse.self, from: data) else {
            debugPrint("❌ Failed to parse JSON: \(cleanedResponse)")
            throw AnalysisError.invalidResponse
        }

        debugPrint("✅ Successfully parsed analysis response")
        return analysisResponse
    }
    
    private func applyMoodScore(_ moodScore: Int, to entries: [SupabaseJournalEntry], userId: String) async {
        guard !entries.isEmpty else { return }
        
        let clampedMood = max(1, min(10, moodScore))
        let resolvedUserId = UUID(uuidString: userId) ?? entries.first?.userId
        
        guard let userUUID = resolvedUserId else {
            debugPrint("❌ Unable to resolve user ID for mood update")
            return
        }
        
        for entry in entries {
            await databaseService.updateJournalEntryMood(entryId: entry.id, userId: userUUID, mood: clampedMood)
        }
    }

    private func buildAnalysisPrompt(content: String, entryCount: Int) -> String {
        return """
        Analyze these \(entryCount) journal entries and provide direct, actionable insights. Write in second person ("you", "your") as if speaking directly to the person.

        JOURNAL ENTRIES:
        \(content)

        Provide analysis as JSON with this exact structure:
        {
          "maturityScore": [1-10 integer based on self-awareness, emotional regulation, perspective-taking],
          "moodScore": [1-10 integer based on how positive or negative their emotional state feels (1=very low/overwhelmed, 10=very positive/energized)],
          "keyInsights": [
            "Direct observation about your emotional patterns",
            "Specific strength or positive behavior you demonstrated", 
            "Pattern or habit that stands out in your entries"
          ],
          "emotionalThemes": ["specific emotion", "recurring feeling", "dominant mood"],
          "growthAreas": [
            "Try: [specific actionable suggestion based on entries]",
            "Consider: [another concrete action you could take]"
          ],
          "summary": "Direct, honest 2-3 sentence summary speaking directly to the person about their emotional state today. Focus on what YOU notice, what YOU're experiencing, and what this might mean for YOUR growth."
        }

        CRITICAL INSTRUCTIONS:
        - Write in SECOND PERSON ("you", "your") - never third person ("the individual", "they")
        - moodScore should reflect how the person FEELS (emotional valence/energy), not maturity
        - Make keyInsights SPECIFIC and OBSERVATIONAL - point out exact patterns, behaviors, or emotions mentioned
        - Make growthAreas ACTIONABLE - start with "Try:" or "Consider:" followed by concrete steps
        - Use bullet-point style thinking - clear, direct, no fluff
        - Be honest but supportive - point out both strengths and areas to work on
        - Reference specific details from the entries when possible

        Example good keyInsights:
        ✅ "You mentioned feeling overwhelmed twice today - this suggests stress is building"
        ✅ "You took time to acknowledge your progress, showing good self-awareness"
        ❌ "The individual is experiencing positive emotions" (too vague, wrong person)

        Example good growthAreas:
        ✅ "Try: Set 3 specific boundaries with work to reduce evening stress"
        ✅ "Consider: Journal about what triggers your anxiety before meetings"
        ❌ "Developing emotional vocabulary" (not actionable)
        """
    }

    private func getTodaysEntries(for userId: String) async -> [SupabaseJournalEntry] {
        return await databaseService.getTodaysEntries(userId: userId)
    }

    private func hasAnalysisForToday() -> Bool {
        let calendar = Calendar.current
        return analyses.contains { calendar.isDateInToday($0.date) }
    }

    // MARK: - Database Methods
    
    // NEW: Combined load from database + local storage
    func loadEvaluations() async {
        var userId = await MainActor.run { databaseService.currentUser?.id.uuidString }

        // If user not loaded yet, wait briefly and retry once
        if userId == nil {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            userId = await MainActor.run { databaseService.currentUser?.id.uuidString }
        }

        guard let userId = userId else {
            debugPrint("❌ No current user found for loading evaluations")
            return
        }
        
        debugPrint("🔄 Loading evaluations for user: \(userId)")
        
        // Always load from local storage first (fast)
        let localEvaluations = loadAnalysesLocally()
        
        do {
            // Try to load from database
            let endpoint = "journal_evaluations?user_id=eq.\(userId)&order=evaluation_date.desc&limit=100"
            
            debugPrint("📤 Fetching evaluations from: \(endpoint)")
            let data = try await httpClient.get(endpoint: endpoint)
            
            // Response data logging removed to reduce console clutter
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Try ISO8601 format first (for created_at)
                let iso8601Formatter = ISO8601DateFormatter()
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
                
                // Try simple date format (for evaluation_date)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
            }
            
            let dbEvaluations = try decoder.decode([DailyJournalAnalysis].self, from: data)
            
            // Merge database and local evaluations (database takes precedence)
            var merged = dbEvaluations
            for localEval in localEvaluations {
                // Add local evaluation if not in database
                if !merged.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: localEval.date) && $0.userId == localEval.userId }) {
                    merged.append(localEval)
                }
            }
            
            // Sort by date descending
            merged.sort { $0.date > $1.date }
            
            await MainActor.run {
                self.analyses = merged
                debugPrint("✅ Loaded \(dbEvaluations.count) from database + \(localEvaluations.count) local = \(merged.count) total evaluations")
            }
        } catch {
            debugPrint("❌ Failed to load from database: \(error)")
            // Fall back to local storage only
            await MainActor.run {
                self.analyses = localEvaluations
                debugPrint("📱 Using \(localEvaluations.count) local evaluations only (database unavailable)")
            }
        }
    }
    
    // Keep old method for compatibility
    func loadEvaluationsFromDatabase() async {
        await loadEvaluations()
    }
    
    private func saveEvaluationToDatabase(_ analysis: DailyJournalAnalysis) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: analysis.date)
        
        debugPrint("💾 Saving evaluation to database...")
        debugPrint("   User ID: \(analysis.userId)")
        debugPrint("   Date: \(dateString)")
        debugPrint("   Maturity Score: \(analysis.maturityScore)")
        debugPrint("   Entry Count: \(analysis.entryCount)")
        
        var evaluation: [String: Any] = [
            "user_id": analysis.userId,
            "evaluation_date": dateString,
            "maturity_score": analysis.maturityScore,
            "summary": analysis.summary,
            "key_insights": analysis.keyInsights,
            "emotional_themes": analysis.emotionalThemes,
            "growth_areas": analysis.growthAreas,
            "entry_count": analysis.entryCount,
            "analyzed_content": analysis.analysisText ?? ""
        ]
        
        if let moodScore = analysis.moodScore {
            evaluation["mood_score"] = moodScore
        }
        
        debugPrint("📦 Evaluation payload: \(evaluation)")
        
        let endpoint = "journal_evaluations"
        
        do {
            let result = try await httpClient.post(endpoint: endpoint, body: evaluation)
            if let resultString = String(data: result, encoding: .utf8) {
                debugPrint("✅ Saved to database. Response: \(resultString)")
            }
            debugPrint("✅ Saved evaluation to database for date: \(dateString)")
            
            // Reload evaluations to update UI
            await loadEvaluationsFromDatabase()
            
        } catch let error as NSError {
            debugPrint("⚠️ Insert failed with error: \(error)")
            debugPrint("   Error code: \(error.code)")
            debugPrint("   Error domain: \(error.domain)")
            
            // Retry without mood_score if the column doesn't exist yet
            if evaluation["mood_score"] != nil,
               error.localizedDescription.contains("mood_score") {
                debugPrint("⚠️ mood_score column missing - retrying without it")
                evaluation.removeValue(forKey: "mood_score")
                do {
                    let retryResult = try await httpClient.post(endpoint: endpoint, body: evaluation)
                    if let resultString = String(data: retryResult, encoding: .utf8) {
                        debugPrint("✅ Saved to database after removing mood_score. Response: \(resultString)")
                    }
                    await loadEvaluationsFromDatabase()
                    return
                } catch {
                    debugPrint("❌ Retry without mood_score failed: \(error)")
                }
            }
            
            // Save locally regardless of database error
            await MainActor.run {
                // Add or update in local analyses array
                if let index = self.analyses.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: analysis.date) && $0.userId == analysis.userId }) {
                    self.analyses[index] = analysis
                } else {
                    self.analyses.append(analysis)
                    self.analyses.sort { $0.date > $1.date }
                }
                self.saveAnalysesLocally()
                debugPrint("💾 Saved evaluation locally due to database error")
            }
            
            // If unique constraint violation, try upsert
            let upsertEndpoint = "rest/v1/journal_evaluations?user_id=eq.\(analysis.userId)&evaluation_date=eq.\(dateString)"
            do {
                let upsertResult = try await httpClient.patch(endpoint: upsertEndpoint, body: evaluation)
                if let resultString = String(data: upsertResult, encoding: .utf8) {
                    debugPrint("✅ Updated in database. Response: \(resultString)")
                }
                debugPrint("✅ Updated evaluation in database for date: \(dateString)")
                
                // Reload evaluations to update UI
                await loadEvaluationsFromDatabase()
            } catch {
                debugPrint("❌ Upsert also failed: \(error)")
                throw error
            }
        }
    }
}

// MARK: - Errors

enum AnalysisError: Error {
    case invalidResponse
    case networkError
    case insufficientEntries
}
