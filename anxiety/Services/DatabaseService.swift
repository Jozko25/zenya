//
//  DatabaseService.swift
//  anxiety
//
//  Simplified service layer for Supabase database operations
//

import Foundation

@MainActor
class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    private let httpClient = SupabaseHTTPClient.shared
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    
    // Device-based UUID - persists across app launches
    private var deviceUserId: UUID {
        return SecureStorage.shared.deviceUserId
    }
    
    private var journalEntriesCache: [UUID: [SupabaseJournalEntry]] = [:]
    private var cacheTimestamps: [UUID: Date] = [:]
    private let cacheExpiration: TimeInterval = 300
    
    private var pendingRequests: [String: Task<Any, Error>] = [:]
    
    private init() {
        Task {
            await initializeUser()
        }
    }
    
    // MARK: - Authentication
    
    func initializeUser() async {
        let userId = deviceUserId
        
        let userProfile = UserProfile(
            id: userId,
            createdAt: Date(),
            updatedAt: Date(),
            email: "device-\(userId.uuidString.prefix(8))@local.app",
            name: "User",
            anxietyLevel: nil,
            hasActiveSubscription: false,
            subscriptionPlan: nil,
            subscriptionStartDate: nil,
            onboardingCompleted: SecureStorage.shared.hasCompletedOnboarding
        )
        
        currentUser = userProfile
        isAuthenticated = true
        debugPrint("✅ Using device-based user: \(userId)")

        // Create user profile in Supabase so journal entries can be saved
        await ensureUserProfileInSupabase(userId)

        // Sync any local entries to Supabase
        await syncLocalEntriesToSupabase()
    }
    
    /// Creates or updates user profile in Supabase database
    private func ensureUserProfileInSupabase(_ userId: UUID) async {
        let body: [String: Any] = [
            "id": userId.uuidString,
            "email": currentUser?.email ?? "device@local.app",
            "name": "User",
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            // Try to insert user (will fail if already exists, which is fine)
            _ = try await httpClient.post(endpoint: "users", body: body)
            debugPrint("✅ User profile created in Supabase: \(userId)")
        } catch {
            let errorStr = String(describing: error)
            if errorStr.contains("23505") || errorStr.contains("duplicate") {
                // User already exists - this is expected, silently continue
            } else if errorStr.contains("PGRST205") {
                // Table doesn't exist yet - log once
                debugPrint("📱 Using local storage (Supabase users table not configured)")
            } else if errorStr.contains("42501") || errorStr.contains("permission denied") {
                // RLS policy issue - table exists but no permission
                debugPrint("� User table exists but RLS blocking - check policies")
            } else {
                // Unknown error - log for debugging
                debugPrint("⚠️ User creation error: \(errorStr.prefix(200))")
            }
        }
    }
    
    private func ensureUserProfile(_ userId: UUID) async throws {
        let body: [String: Any] = [
            "id": userId.uuidString,
            "email": currentUser?.email ?? "device@local.app",
            "name": "User",
            "onboarding_completed": false
        ]
        
        do {
            _ = try await httpClient.post(endpoint: "user_profiles", body: body)
            debugPrint("✅ User profile created")
        } catch {
            debugPrint("⚠️ User profile may already exist or RLS blocking: \(error)")
        }
    }
    
    private func ensureGameStats(_ userId: UUID) async throws {
        let body: [String: Any] = [
            "user_id": userId.uuidString,
            "total_entries": 0,
            "current_streak": 0,
            "longest_streak": 0,
            "total_points": 0,
            "level": 1,
            "weekly_goal": 3,
            "monthly_goal": 12
        ]
        
        do {
            _ = try await httpClient.post(endpoint: "user_game_stats", body: body)
            debugPrint("✅ Game stats initialized")
        } catch {
            debugPrint("⚠️ Game stats may already exist or RLS blocking: \(error)")
        }
    }
    
    func signOut() async throws {
        isAuthenticated = false
        currentUser = nil
        httpClient.setAuthToken(nil)
        debugPrint("✅ User signed out")
    }
    
    // MARK: - Mood Tracking
    
    func saveMoodEntry(_ entry: SupabaseMoodEntry) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(entry)
        try await httpClient.post(endpoint: "mood_entries", data: data)
        debugPrint("✅ Mood entry saved to Supabase: mood=\(entry.mood), anxiety=\(entry.anxietyLevel)")
    }
    
    func getMoodEntries(userId: UUID, limit: Int = 50) async throws -> [SupabaseMoodEntry] {
        // Mood tracking not implemented in UI yet; keep stub to avoid unintended network calls
        debugPrint("⚠️ getMoodEntries called, but mood tracking is not active; returning empty array")
        return []
    }
    
    // MARK: - Breathing Sessions

    func saveBreathingSession(_ session: SupabaseBreathingSession) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(session)
        try await httpClient.post(endpoint: "breathing_sessions", data: data)
        debugPrint("✅ Breathing session saved to Supabase: technique=\(session.technique), duration=\(session.duration)s")
    }

    // MARK: - Meditation Sessions

    func saveMeditationSession(_ session: SupabaseMeditationSession) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(session)
        try await httpClient.post(endpoint: "meditation_sessions", data: data)
        debugPrint("✅ Meditation session saved to Supabase: title=\(session.title), duration=\(session.duration)s")
    }

    // MARK: - Journal Entries
    
    func updateJournalEntryMood(entryId: UUID, userId: UUID, mood: Int) async {
        let clampedMood = max(1, min(10, mood))
        let endpoint = "rest/v1/journal_entries?id=eq.\(entryId)"
        let payload: [String: Any] = [
            "mood": clampedMood
        ]
        
        do {
            _ = try await httpClient.patch(endpoint: endpoint, body: payload)
            debugPrint("✅ Updated mood for entry \(entryId) → \(clampedMood)")
        } catch {
            debugPrint("❌ Failed to update mood for entry \(entryId): \(error)")
        }
        
        updateCachedJournalEntryMood(entryId: entryId, userId: userId, mood: clampedMood)
    }
    
    func saveJournalEntry(_ entry: SupabaseJournalEntry) async throws {
        let pointsEarned = calculatePointsForEntry(entry)
        let entryWithPoints = entry

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entryWithPoints)

        invalidateCache(for: entry.userId)

        // Always save locally first for reliability
        saveJournalEntryLocally(entryWithPoints)

        do {
            try await httpClient.post(endpoint: "journal_entries", data: data)
            debugPrint("✅ Journal entry saved to Supabase")

            async let pointsTask: () = recordJournalEntryPoints(entryId: entry.id, pointsEarned: pointsEarned)
            async let statsTask: () = updateGameStatsAfterJournalEntry(entry, pointsEarned: pointsEarned)
            async let questionTask: () = AIQuestionGenerationService.shared.checkAndGenerateNewBatch()

            _ = try? await (pointsTask, statsTask, questionTask)

        } catch {
            let errorDescription = String(describing: error)
            debugPrint("⚠️ Supabase save failed: \(errorDescription) - entry saved locally")
            await AIQuestionGenerationService.shared.checkAndGenerateNewBatch()
            // Entry already saved locally, so don't throw - data is safe
        }
    }

    /// Syncs local journal entries to Supabase
    func syncLocalEntriesToSupabase() async {
        guard let userId = currentUser?.id else { return }

        let localEntries = getLocalJournalEntries(userId: userId)
        guard !localEntries.isEmpty else { return }

        debugPrint("🔄 Syncing \(localEntries.count) local entries to Supabase...")

        var syncedCount = 0
        for entry in localEntries {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(entry)

                // Use upsert to avoid duplicates
                try await httpClient.post(endpoint: "journal_entries?on_conflict=id", data: data)
                syncedCount += 1
            } catch {
                // Continue with next entry if one fails
                debugPrint("⚠️ Failed to sync entry \(entry.id): \(error)")
            }
        }

        debugPrint("✅ Synced \(syncedCount)/\(localEntries.count) entries to Supabase")
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
        
        return points
    }
    
    private func updateGameStatsAfterJournalEntry(_ entry: SupabaseJournalEntry, pointsEarned: Int) async {
        guard let userId = currentUser?.id else { return }
        
        do {
            // Get current stats from database
            let currentStats = try await loadGameStatsFromDatabase(userId)
            
            // Update stats
            var updatedStats = currentStats
            updatedStats.totalEntries += 1
            updatedStats.totalPoints += pointsEarned
            
            // Update streak (simplified - should be more sophisticated)
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(entry.createdAt)
            if isToday {
                updatedStats.currentStreak += 1
                updatedStats.longestStreak = max(updatedStats.longestStreak, updatedStats.currentStreak)
            }
            
            // Update level based on points
            let newLevel = calculateLevel(for: updatedStats.totalPoints)
            let oldLevel = updatedStats.level
            updatedStats.level = newLevel
            
            // Sync updated stats to database
            try await syncLocalGameStats(updatedStats, userId: userId)
            
            // Record level up if it happened
            if newLevel > oldLevel {
                await recordLevelUp(userId: userId, oldLevel: oldLevel, newLevel: newLevel, points: updatedStats.totalPoints)
            }
            
        } catch {
            debugPrint("❌ Failed to update game stats after journal entry: \(error)")
        }
    }
    
    private func calculateLevel(for points: Int) -> Int {
        // Simple level calculation - customize based on your game design
        switch points {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        case 1000..<1500: return 5
        default: return min(10, 5 + (points - 1500) / 500)
        }
    }
    
    private func recordLevelUp(userId: UUID, oldLevel: Int, newLevel: Int, points: Int) async {
        do {
            let levelUp = LevelUpRecord(
                userId: userId,
                oldLevel: oldLevel,
                newLevel: newLevel,
                pointsAtLevelUp: points,
                achievedAt: Date()
            )
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(levelUp)
            
            _ = try await httpClient.post(endpoint: "level_up_history", data: data)
            debugPrint("🎉 Level up recorded: \(oldLevel) → \(newLevel)")
        } catch {
            debugPrint("❌ Failed to record level up: \(error)")
        }
    }
    
    private func ensureUserProfileExists() async throws {
        guard let user = currentUser else {
            throw NSError(domain: "DatabaseService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        // Try to create user profile (will ignore if already exists due to ON CONFLICT)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(user)
        
        // Use upsert to handle existing users
        try await httpClient.post(endpoint: "user_profiles?on_conflict=id", data: data)
        debugPrint("✅ Ensured user profile exists for: \(user.id)")
    }
    
    func getJournalEntries(userId: UUID, limit: Int = 50, forceRefresh: Bool = false) async throws -> [SupabaseJournalEntry] {
        // Check cache unless force refresh requested
        if !forceRefresh, let cached = getCachedEntries(for: userId), !isCacheExpired(for: userId) {
            debugPrint("💨 Using cached journal entries (\(cached.count) entries)")
            return Array(cached.prefix(limit))
        }
        
        let requestKey = "journal_\(userId.uuidString)"
        if let existing = pendingRequests[requestKey] {
            debugPrint("⏳ Request already in progress, awaiting result")
            if let result = try await existing.value as? [SupabaseJournalEntry] {
                return result
            }
            return []
        }
        
        let task = Task<Any, Error> {
            defer { pendingRequests.removeValue(forKey: requestKey) }
            
            debugPrint("🔄 Fetching journal entries from Supabase for user: \(userId)")
            let endpoint = "journal_entries?user_id=eq.\(userId.uuidString)&order=created_at.desc&limit=\(limit)"
            
            do {
                let data = try await httpClient.get(endpoint: endpoint)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let entries = try decoder.decode([SupabaseJournalEntry].self, from: data)
                debugPrint("📡 SUPABASE returned \(entries.count) entries")
                
                let localEntries = getLocalJournalEntries(userId: userId)
                debugPrint("💾 LOCAL STORAGE has \(localEntries.count) entries")
                
                let mergedEntries = localEntries.isEmpty ? entries : mergeEntries(database: entries, local: localEntries, limit: limit)
                debugPrint("🔢 MERGED TOTAL: \(mergedEntries.count) entries (Supabase: \(entries.count), Local: \(localEntries.count))")
                
                cacheEntries(mergedEntries, for: userId)
                return mergedEntries
            } catch {
                debugPrint("❌ Database fetch failed: \(error)")
                let localEntries = getLocalJournalEntries(userId: userId)
                debugPrint("📱 FALLBACK to local entries: \(localEntries.count)")
                cacheEntries(localEntries, for: userId)
                return localEntries
            }
        }
        
        pendingRequests[requestKey] = task
        if let result = try await task.value as? [SupabaseJournalEntry] {
            return result
        }
        return []
    }
    
    private func getCachedEntries(for userId: UUID) -> [SupabaseJournalEntry]? {
        return journalEntriesCache[userId]
    }
    
    private func isCacheExpired(for userId: UUID) -> Bool {
        guard let timestamp = cacheTimestamps[userId] else { return true }
        return Date().timeIntervalSince(timestamp) > cacheExpiration
    }
    
    private func cacheEntries(_ entries: [SupabaseJournalEntry], for userId: UUID) {
        journalEntriesCache[userId] = entries
        cacheTimestamps[userId] = Date()
    }

    
    private func updateCachedJournalEntryMood(entryId: UUID, userId: UUID, mood: Int) {
        // Update in-memory cache
        if var cached = journalEntriesCache[userId],
           let index = cached.firstIndex(where: { $0.id == entryId }) {
            cached[index] = replacingMood(for: cached[index], with: mood)
            journalEntriesCache[userId] = cached
        }
        
        // Update local storage copy
        var localEntries = getLocalJournalEntries(userId: userId)
        if let localIndex = localEntries.firstIndex(where: { $0.id == entryId }) {
            localEntries[localIndex] = replacingMood(for: localEntries[localIndex], with: mood)
            persistLocalJournalEntries(localEntries, for: userId)
        }
    }
    
    private func replacingMood(for entry: SupabaseJournalEntry, with mood: Int) -> SupabaseJournalEntry {
        SupabaseJournalEntry(
            id: entry.id,
            userId: entry.userId,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt,
            title: entry.title,
            content: entry.content,
            mood: mood,
            gratitudeItems: entry.gratitudeItems,
            tags: entry.tags,
            isPrivate: entry.isPrivate,
            weatherData: entry.weatherData,
            location: entry.location
        )
    }
    
    private func persistLocalJournalEntries(_ entries: [SupabaseJournalEntry], for userId: UUID) {
        let key = "local_journal_entries_\(userId.uuidString)"
        var trimmedEntries = entries
        
        // Keep local storage bounded
        trimmedEntries.sort { $0.createdAt > $1.createdAt }
        if trimmedEntries.count > 100 {
            trimmedEntries = Array(trimmedEntries.prefix(100))
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(trimmedEntries)
            UserDefaults.standard.set(data, forKey: key)
            debugPrint("💾 Persisted \(trimmedEntries.count) local journal entries (mood updated)")
        } catch {
            debugPrint("❌ Failed to persist local journal entries: \(error)")
        }
    }
    
    func invalidateCache(for userId: UUID) {
        journalEntriesCache.removeValue(forKey: userId)
        cacheTimestamps.removeValue(forKey: userId)
    }

    func getRecentEntries(userId: String, limit: Int = 10) async -> [SupabaseJournalEntry] {
        debugPrint("🔍 getRecentEntries called with userId: \(userId), limit: \(limit)")

        // Get recent entries from local storage first
        if let userIdUUID = UUID(uuidString: userId) {
            let localEntries = getLocalJournalEntries(userId: userIdUUID)
            let recentLocal = Array(localEntries
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(limit))

            if !recentLocal.isEmpty {
                debugPrint("📱 Found \(recentLocal.count) recent local entries")
                return recentLocal
            }
        }

        // Try to get from Supabase if no local entries
        do {
            let endpoint = "journal_entries?user_id=eq.\(userId)&order=created_at.desc&limit=\(limit)"
            let data = try await httpClient.get(endpoint: endpoint)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let entries = try decoder.decode([SupabaseJournalEntry].self, from: data)
            debugPrint("✅ Found \(entries.count) recent entries from database")
            return entries
        } catch {
            debugPrint("❌ Failed to get recent entries from Supabase: \(error)")
            return []
        }
    }

    func getTodaysEntries(userId: String) async -> [SupabaseJournalEntry] {
        debugPrint("🔍 getTodaysEntries called with userId: \(userId)")
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today

        let formatter = ISO8601DateFormatter()
        let startString = formatter.string(from: startOfDay)
        let endString = formatter.string(from: endOfDay)

        do {
            let endpoint = "journal_entries?user_id=eq.\(userId)&created_at=gte.\(startString)&created_at=lt.\(endString)&order=created_at.desc"
            let data = try await httpClient.get(endpoint: endpoint)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let entries = try decoder.decode([SupabaseJournalEntry].self, from: data)
            debugPrint("✅ Found \(entries.count) journal entries for today from database")

            // Also check local entries for today
            if let userIdUUID = UUID(uuidString: userId) {
                let localEntries = getLocalJournalEntries(userId: userIdUUID)
                debugPrint("📱 Total local entries: \(localEntries.count)")
                let todaysLocalEntries = localEntries.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
                debugPrint("📱 Today's local entries: \(todaysLocalEntries.count)")

                // Merge and deduplicate
                var allTodaysEntries = entries
                for localEntry in todaysLocalEntries {
                    if !entries.contains(where: { $0.id == localEntry.id }) {
                        allTodaysEntries.append(localEntry)
                    }
                }

                debugPrint("✅ Total entries (database + local): \(allTodaysEntries.count)")
                return allTodaysEntries
            }

            return entries
        } catch {
            debugPrint("❌ Error fetching today's entries from database: \(error)")

            // Fall back to local entries for today
            if let userIdUUID = UUID(uuidString: userId) {
                let localEntries = getLocalJournalEntries(userId: userIdUUID)
                debugPrint("📱 Total local entries in fallback: \(localEntries.count)")
                let todaysLocalEntries = localEntries.filter { calendar.isDate($0.createdAt, inSameDayAs: today) }
                debugPrint("📱 Found \(todaysLocalEntries.count) local entries for today in fallback")
                return todaysLocalEntries
            }

            return []
        }
    }

    // MARK: - Other placeholder methods
    
    func loadUserProfile(userId: UUID) async {
        debugPrint("✅ Loading user profile for: \(userId)")
    }
    
    func createOrUpdateUserProfile(_ profile: UserProfile) async throws {
        debugPrint("✅ Creating/updating user profile: \(profile.name ?? "Unknown")")
    }
    
    // MARK: - Daily Challenge Responses
    
    func saveChallengeResponse(_ response: ChallengeResponse) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(response)
        
        do {
            try await httpClient.post(endpoint: "challenge_responses", data: data)
            debugPrint("✅ Challenge response saved: challengeId=\(response.challengeId)")
        } catch {
            debugPrint("❌ Error saving challenge response: \(error)")
            debugPrint("⚠️ Please create the challenge_responses table in Supabase to enable challenge tracking")
            throw error
        }
    }
    
    func getChallengeResponses(userId: UUID, limit: Int = 50) async throws -> [ChallengeResponse] {
        let endpoint = "challenge_responses?user_id=eq.\(userId.uuidString)&order=created_at.desc&limit=\(limit)"
        debugPrint("🔍 Getting challenge responses for user: \(userId)")
        
        do {
            let data = try await httpClient.get(endpoint: endpoint)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let responses = try decoder.decode([ChallengeResponse].self, from: data)
            debugPrint("✅ Successfully loaded \(responses.count) challenge responses")
            return responses
        } catch {
            debugPrint("❌ Error fetching challenge responses: \(error)")
            // Check if it's a table not found error by examining error description
            let errorDescription = String(describing: error)
            if errorDescription.contains("Could not find the table") || errorDescription.contains("PGRST205") {
                debugPrint("⚠️ Challenge responses table not found - returning empty array. Please create the table in Supabase.")
            }
            return []
        }
    }
    
    func getTodaysChallengeResponse(userId: UUID) async throws -> ChallengeResponse? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let formatter = ISO8601DateFormatter()
        let todayString = formatter.string(from: today)
        let tomorrowString = formatter.string(from: tomorrow)
        
        let endpoint = "challenge_responses?user_id=eq.\(userId.uuidString)&date=gte.\(todayString)&date=lt.\(tomorrowString)&limit=1"
        
        do {
            let data = try await httpClient.get(endpoint: endpoint)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            let responses = try decoder.decode([ChallengeResponse].self, from: data)
            return responses.first
        } catch {
            debugPrint("❌ Error checking today's challenge response: \(error)")
            // If table doesn't exist, return nil (no challenge completed)
            return nil
        }
    }
    
    // MARK: - Local Storage Fallback for MVP
    
    private func saveJournalEntryLocally(_ entry: SupabaseJournalEntry) {
        guard let userId = currentUser?.id else {
            debugPrint("❌ No current user for local journal entry save")
            return
        }
        
        let key = "local_journal_entries_\(userId.uuidString)"
        var localEntries = getLocalJournalEntries(userId: userId)
        
        // Add the new entry
        localEntries.append(entry)
        
        // Keep only the most recent entries (limit to prevent storage bloat)
        localEntries.sort { $0.createdAt > $1.createdAt }
        if localEntries.count > 100 {
            localEntries = Array(localEntries.prefix(100))
        }
        
        // Save to UserDefaults
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(localEntries)
            UserDefaults.standard.set(data, forKey: key)
            debugPrint("💾 Saved journal entry to local storage")
        } catch {
            debugPrint("❌ Failed to save journal entry locally: \(error)")
        }
    }
    
    private func getLocalJournalEntries(userId: UUID) -> [SupabaseJournalEntry] {
        let key = "local_journal_entries_\(userId.uuidString)"
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([SupabaseJournalEntry].self, from: data)
            return entries
        } catch {
            debugPrint("❌ Failed to load local journal entries: \(error)")
            return []
        }
    }
    
    private func mergeEntries(database: [SupabaseJournalEntry], local: [SupabaseJournalEntry], limit: Int) -> [SupabaseJournalEntry] {
        // Combine and deduplicate based on ID
        var allEntries: [SupabaseJournalEntry] = database
        
        for localEntry in local {
            if !database.contains(where: { $0.id == localEntry.id }) {
                allEntries.append(localEntry)
            }
        }
        
        // Sort by creation date (newest first)
        allEntries.sort { $0.createdAt > $1.createdAt }
        
        // Apply limit
        return Array(allEntries.prefix(limit))
    }
    
    // MARK: - Game Stats Sync Methods
    
    func loadGameStatsFromDatabase(_ userId: UUID) async throws -> JournalGameStats {
        do {
            let data = try await httpClient.get(endpoint: "user_game_stats?user_id=eq.\(userId)")
            let stats = try JSONDecoder().decode([DatabaseGameStats].self, from: data)
            
            if let dbStats = stats.first {
                // Convert database stats to local model
                return JournalGameStats(
                    totalEntries: dbStats.totalEntries,
                    currentStreak: dbStats.currentStreak,
                    longestStreak: dbStats.longestStreak,
                    totalPoints: dbStats.totalPoints,
                    level: dbStats.level,
                    unlockedAchievements: parseAchievements(from: dbStats.achievementData),
                    weeklyGoal: dbStats.weeklyGoal,
                    monthlyGoal: dbStats.monthlyGoal
                )
            }
        } catch {
            debugPrint("Error loading game stats from database: \(error)")
        }
        
        // Return default stats if no data found
        return JournalGameStats()
    }
    
    func syncLocalGameStats(_ localStats: JournalGameStats, userId: UUID) async throws {
        // Don't sync if user has no stats yet
        guard localStats.totalEntries > 0 || localStats.totalPoints > 0 else {
            return
        }
        
        // First check if user_game_stats record exists
        do {
            let existingData = try await httpClient.get(endpoint: "user_game_stats?user_id=eq.\(userId)")
            let existingStats = try JSONDecoder().decode([DatabaseGameStats].self, from: existingData)
            
            let dbStats = DatabaseGameStats(
                id: existingStats.first?.id ?? UUID(),
                userId: userId,
                createdAt: existingStats.first?.createdAt ?? Date(),
                updatedAt: Date(),
                totalEntries: localStats.totalEntries,
                currentStreak: localStats.currentStreak,
                longestStreak: localStats.longestStreak,
                totalPoints: localStats.totalPoints,
                level: localStats.level,
                weeklyGoal: localStats.weeklyGoal,
                monthlyGoal: localStats.monthlyGoal,
                achievementData: serializeAchievements(localStats.unlockedAchievements),
                trackingData: [:]
            )
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(dbStats)
            
            if existingStats.isEmpty {
                // Create new record
                _ = try await httpClient.post(endpoint: "user_game_stats", data: jsonData)
                debugPrint("✅ Created new game stats record in database")
            } else if let existingStat = existingStats.first {
                // Update existing record - just use the full stats object
                let updatedStats = DatabaseGameStats(
                    id: existingStat.id,
                    userId: userId,
                    createdAt: existingStat.createdAt,
                    updatedAt: Date(),
                    totalEntries: localStats.totalEntries,
                    currentStreak: localStats.currentStreak,
                    longestStreak: localStats.longestStreak,
                    totalPoints: localStats.totalPoints,
                    level: localStats.level,
                    weeklyGoal: localStats.weeklyGoal,
                    monthlyGoal: localStats.monthlyGoal,
                    achievementData: serializeAchievements(localStats.unlockedAchievements),
                    trackingData: existingStat.trackingData ?? [:]
                )
                
                let updateData = try encoder.encode(updatedStats)
                
                // Using POST with prefer=return=minimal for upsert
                let url = "user_game_stats?user_id=eq.\(userId)"
                _ = try await httpClient.post(endpoint: url, data: updateData)
                debugPrint("✅ Updated game stats in database")
            }
            
        } catch {
            let errorDescription = String(describing: error)
            // Silently ignore foreign key errors for device-based users (expected)
            if errorDescription.contains("23503") || errorDescription.contains("user_game_stats") {
                // Expected - users table not configured, using local storage
                return
            }
            // Only log unexpected errors
            debugPrint("❌ Failed to sync game stats: \(error)")
            throw error
        }
    }
    
    func recordJournalEntryPoints(entryId: UUID, pointsEarned: Int) async throws {
        struct PointsUpdate: Codable {
            let pointsEarned: Int
            
            enum CodingKeys: String, CodingKey {
                case pointsEarned = "points_earned"
            }
        }
        
        let updateData = PointsUpdate(pointsEarned: pointsEarned)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(updateData)
        
        _ = try await httpClient.post(endpoint: "journal_entries?id=eq.\(entryId)", data: jsonData)
        debugPrint("✅ Recorded \(pointsEarned) points for journal entry")
    }
    
    func recordAchievement(userId: UUID, achievementId: String, pointsEarned: Int) async throws {
        let achievement = DatabaseAchievement(
            id: UUID(),
            userId: userId,
            achievementId: achievementId,
            unlockedAt: Date(),
            pointsEarned: pointsEarned
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(achievement)
        
        _ = try await httpClient.post(endpoint: "user_achievements", data: jsonData)
        debugPrint("✅ Recorded achievement: \(achievementId) (+\(pointsEarned) points)")
    }
    
    // Helper methods
    private func parseAchievements(from data: [String: Any]?) -> Set<String> {
        guard let data = data,
              let achievements = data["unlocked"] as? [String] else {
            return Set<String>()
        }
        return Set(achievements)
    }

    private func serializeAchievements(_ achievements: Set<String>) -> [String: Any] {
        return ["unlocked": Array(achievements)]
    }

    // MARK: - Mood Patterns Sync (for cross-device persistence)

    /// Save a mood pattern to Supabase for cross-device sync
    func saveMoodPattern(_ pattern: PersonalMoodPattern) async throws {
        debugPrint("☁️ [MoodPatternSync] Saving pattern to Supabase: \(pattern.name)")

        let supabasePattern = SupabaseMoodPattern(from: pattern)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(supabasePattern)

        do {
            try await httpClient.post(endpoint: "mood_patterns", data: data)
            debugPrint("☁️ [MoodPatternSync] ✅ Pattern saved: \(pattern.name)")
        } catch {
            let errorStr = String(describing: error)
            if errorStr.contains("23505") || errorStr.contains("duplicate") {
                // Pattern already exists, try to update
                debugPrint("☁️ [MoodPatternSync] Pattern exists, updating...")
                try await updateMoodPattern(pattern)
            } else if errorStr.contains("PGRST205") || errorStr.contains("42P01") {
                // Table doesn't exist - save locally only
                debugPrint("☁️ [MoodPatternSync] ⚠️ mood_patterns table not created yet - using local storage")
            } else {
                debugPrint("☁️ [MoodPatternSync] ❌ Error saving pattern: \(errorStr.prefix(200))")
                throw error
            }
        }
    }

    /// Update an existing mood pattern in Supabase
    func updateMoodPattern(_ pattern: PersonalMoodPattern) async throws {
        debugPrint("☁️ [MoodPatternSync] Updating pattern: \(pattern.name)")

        let supabasePattern = SupabaseMoodPattern(from: pattern)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(supabasePattern)

        let endpoint = "mood_patterns?id=eq.\(pattern.id.uuidString)"
        try await httpClient.patch(endpoint: endpoint, body: try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:])
        debugPrint("☁️ [MoodPatternSync] ✅ Pattern updated: \(pattern.name)")
    }

    /// Load all mood patterns for a user from Supabase
    func loadMoodPatterns(userId: UUID) async throws -> [PersonalMoodPattern] {
        debugPrint("☁️ [MoodPatternSync] Loading patterns from Supabase for user: \(userId)")

        do {
            let endpoint = "mood_patterns?user_id=eq.\(userId.uuidString)&order=created_at.desc"
            let data = try await httpClient.get(endpoint: endpoint)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let supabasePatterns = try decoder.decode([SupabaseMoodPattern].self, from: data)
            let localPatterns = supabasePatterns.map { $0.toLocalPattern() }

            debugPrint("☁️ [MoodPatternSync] ✅ Loaded \(localPatterns.count) patterns from Supabase")
            return localPatterns

        } catch {
            let errorStr = String(describing: error)
            if errorStr.contains("PGRST205") || errorStr.contains("42P01") {
                debugPrint("☁️ [MoodPatternSync] ⚠️ mood_patterns table not created yet")
                return []
            }
            debugPrint("☁️ [MoodPatternSync] ❌ Error loading patterns: \(errorStr.prefix(200))")
            throw error
        }
    }

    /// Delete a mood pattern from Supabase
    func deleteMoodPattern(patternId: UUID) async throws {
        debugPrint("☁️ [MoodPatternSync] Deleting pattern: \(patternId)")

        let endpoint = "mood_patterns?id=eq.\(patternId.uuidString)"
        try await httpClient.delete(endpoint: endpoint)
        debugPrint("☁️ [MoodPatternSync] ✅ Pattern deleted")
    }

    /// Sync all local patterns to Supabase (for initial sync or recovery)
    func syncAllMoodPatterns(_ patterns: [PersonalMoodPattern]) async {
        debugPrint("☁️ [MoodPatternSync] Syncing \(patterns.count) patterns to Supabase...")

        for pattern in patterns {
            do {
                try await saveMoodPattern(pattern)
            } catch {
                debugPrint("☁️ [MoodPatternSync] ⚠️ Failed to sync pattern \(pattern.name): \(error)")
                // Continue with other patterns
            }
        }

        debugPrint("☁️ [MoodPatternSync] ✅ Sync complete")
    }

    /// Load patterns from Supabase and merge with local (Supabase takes precedence)
    func loadAndMergeMoodPatterns(userId: UUID, localPatterns: [PersonalMoodPattern]) async -> [PersonalMoodPattern] {
        debugPrint("☁️ [MoodPatternSync] Loading and merging patterns...")

        do {
            let cloudPatterns = try await loadMoodPatterns(userId: userId)

            if cloudPatterns.isEmpty && !localPatterns.isEmpty {
                // No cloud patterns but have local - sync local to cloud
                debugPrint("☁️ [MoodPatternSync] No cloud patterns, syncing local to cloud...")
                await syncAllMoodPatterns(localPatterns)
                return localPatterns
            }

            // Cloud patterns exist - merge (cloud takes precedence for same IDs)
            var mergedPatterns: [UUID: PersonalMoodPattern] = [:]

            // Add local patterns first
            for pattern in localPatterns {
                mergedPatterns[pattern.id] = pattern
            }

            // Override with cloud patterns (newer)
            for pattern in cloudPatterns {
                mergedPatterns[pattern.id] = pattern
            }

            let result = Array(mergedPatterns.values)
            debugPrint("☁️ [MoodPatternSync] ✅ Merged: \(localPatterns.count) local + \(cloudPatterns.count) cloud = \(result.count) total")
            return result

        } catch {
            debugPrint("☁️ [MoodPatternSync] ⚠️ Cloud sync failed, using local patterns: \(error)")
            return localPatterns
        }
    }

    /// Save user's occupation type to their profile
    func saveUserOccupationType(_ occupationType: OccupationType, userId: UUID) async {
        debugPrint("☁️ [MoodPatternSync] Saving occupation type: \(occupationType.rawValue)")

        let body: [String: Any] = [
            "occupation_type": occupationType.rawValue,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]

        do {
            try await httpClient.patch(endpoint: "users?id=eq.\(userId.uuidString)", body: body)
            debugPrint("☁️ [MoodPatternSync] ✅ Occupation type saved to user profile")
        } catch {
            debugPrint("☁️ [MoodPatternSync] ⚠️ Could not save occupation type to profile: \(error)")
        }
    }
}

// MARK: - Database Models for Game Stats

struct DatabaseGameStats: Codable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    let totalEntries: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalPoints: Int
    let level: Int
    let weeklyGoal: Int
    let monthlyGoal: Int
    let achievementData: [String: Any]?
    let trackingData: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalEntries = "total_entries"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalPoints = "total_points"
        case level
        case weeklyGoal = "weekly_goal"
        case monthlyGoal = "monthly_goal"
        case achievementData = "achievement_data"
        case trackingData = "tracking_data"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        totalEntries = try container.decode(Int.self, forKey: .totalEntries)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        level = try container.decode(Int.self, forKey: .level)
        weeklyGoal = try container.decode(Int.self, forKey: .weeklyGoal)
        monthlyGoal = try container.decode(Int.self, forKey: .monthlyGoal)
        
        // Handle JSONB fields
        if let jsonData = try? container.decode(Data.self, forKey: .achievementData) {
            achievementData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        } else {
            achievementData = nil
        }
        
        if let jsonData = try? container.decode(Data.self, forKey: .trackingData) {
            trackingData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        } else {
            trackingData = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(totalEntries, forKey: .totalEntries)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(totalPoints, forKey: .totalPoints)
        try container.encode(level, forKey: .level)
        try container.encode(weeklyGoal, forKey: .weeklyGoal)
        try container.encode(monthlyGoal, forKey: .monthlyGoal)
        
        // Handle JSONB fields
        if let data = achievementData {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try container.encode(jsonData, forKey: .achievementData)
        }
        
        if let data = trackingData {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try container.encode(jsonData, forKey: .trackingData)
        }
    }
    
    init(id: UUID, userId: UUID, createdAt: Date, updatedAt: Date, totalEntries: Int, currentStreak: Int, longestStreak: Int, totalPoints: Int, level: Int, weeklyGoal: Int, monthlyGoal: Int, achievementData: [String: Any]?, trackingData: [String: Any]?) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalEntries = totalEntries
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalPoints = totalPoints
        self.level = level
        self.weeklyGoal = weeklyGoal
        self.monthlyGoal = monthlyGoal
        self.achievementData = achievementData
        self.trackingData = trackingData
    }
}

struct DatabaseAchievement: Codable {
    let id: UUID
    let userId: UUID
    let achievementId: String
    let unlockedAt: Date
    let pointsEarned: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
        case pointsEarned = "points_earned"
    }
}

struct LevelUpRecord: Codable {
    let userId: UUID
    let oldLevel: Int
    let newLevel: Int
    let pointsAtLevelUp: Int
    let achievedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case oldLevel = "old_level"
        case newLevel = "new_level"
        case pointsAtLevelUp = "points_at_level_up"
        case achievedAt = "achieved_at"
    }
}
