//
//  PersonalMoodPattern.swift
//  anxiety
//
//  Personal mood patterns extracted from journal entries using LLM
//

import Foundation

// MARK: - Pattern Types

enum MoodPatternType: String, Codable {
    case occupationType          // Employee, business owner, student, etc.
    case weekdayPreference       // Loves/hates specific days
    case significantDate         // Anniversary, death date, etc.
    case seasonalPattern         // SAD, seasonal happiness
    case recurringTrigger        // Specific triggers that affect mood
}

enum OccupationType: String, Codable {
    case employee                // Happy Friday, sad Monday
    case businessOwner           // Happy Monday (business opens), mixed weekend
    case student                 // Happy Friday, stressed during exams
    case freelancer              // Variable, deadline-driven
    case unemployed              // May have complex patterns
    case retired                 // Generally stable, activity-based
    case unknown
    
    /// Mood impact by day of week (1 = Sunday, 2 = Monday, ... 7 = Saturday)
    func moodImpactForWeekday(_ weekday: Int) -> Double {
        switch self {
        case .employee:
            // Happy toward weekend, sad at start
            switch weekday {
            case 1: return 0.3   // Sunday - relaxed but dreading Monday
            case 2: return -0.6  // Monday - worst
            case 3: return -0.3  // Tuesday
            case 4: return 0.0   // Wednesday - middle
            case 5: return 0.3   // Thursday - almost there
            case 6: return 0.8   // Friday - best
            case 7: return 0.5   // Saturday - weekend
            default: return 0.0
            }
        case .businessOwner:
            // Happy at week start when business is active
            switch weekday {
            case 1: return -0.2  // Sunday - business closed
            case 2: return 0.7   // Monday - business opens
            case 3: return 0.5   // Tuesday
            case 4: return 0.4   // Wednesday
            case 5: return 0.3   // Thursday
            case 6: return 0.2   // Friday
            case 7: return -0.1  // Saturday - may or may not work
            default: return 0.0
            }
        case .student:
            // Similar to employee but stress during week
            switch weekday {
            case 1: return 0.2   // Sunday - homework stress
            case 2: return -0.4  // Monday
            case 3: return -0.2  // Tuesday
            case 4: return 0.0   // Wednesday
            case 5: return 0.2   // Thursday
            case 6: return 0.7   // Friday
            case 7: return 0.5   // Saturday
            default: return 0.0
            }
        case .freelancer:
            // Less day-dependent, more deadline-driven
            return 0.0
        case .unemployed, .retired, .unknown:
            return 0.0
        }
    }
}

// MARK: - Personal Mood Pattern

struct PersonalMoodPattern: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let patternType: MoodPatternType
    let name: String
    let description: String
    let moodImpact: Double          // -3.0 to +3.0
    let confidence: Double          // 0.0 to 1.0
    
    // Optional pattern-specific data
    let dayOfWeek: Int?             // 1-7 for weekday patterns
    let monthDay: MonthDay?         // For recurring yearly dates
    let occupationType: OccupationType?
    let triggerKeywords: [String]?  // Keywords that indicate this pattern
    
    // Metadata
    let extractedFromEntryId: UUID?
    let extractedSnippet: String?   // Relevant text from journal
    let createdAt: Date
    let lastValidated: Date?        // When pattern was last confirmed
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        patternType: MoodPatternType,
        name: String,
        description: String,
        moodImpact: Double,
        confidence: Double,
        dayOfWeek: Int? = nil,
        monthDay: MonthDay? = nil,
        occupationType: OccupationType? = nil,
        triggerKeywords: [String]? = nil,
        extractedFromEntryId: UUID? = nil,
        extractedSnippet: String? = nil,
        createdAt: Date = Date(),
        lastValidated: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.patternType = patternType
        self.name = name
        self.description = description
        self.moodImpact = moodImpact
        self.confidence = confidence
        self.dayOfWeek = dayOfWeek
        self.monthDay = monthDay
        self.occupationType = occupationType
        self.triggerKeywords = triggerKeywords
        self.extractedFromEntryId = extractedFromEntryId
        self.extractedSnippet = extractedSnippet
        self.createdAt = createdAt
        self.lastValidated = lastValidated
    }
}

struct MonthDay: Codable, Equatable {
    let month: Int  // 1-12
    let day: Int    // 1-31
    
    func matches(date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        return components.month == month && components.day == day
    }
    
    func daysUntil(from date: Date) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        var targetComponents = DateComponents()
        targetComponents.year = year
        targetComponents.month = month
        targetComponents.day = day
        
        guard let targetDate = calendar.date(from: targetComponents) else { return 365 }
        
        let days = calendar.dateComponents([.day], from: date, to: targetDate).day ?? 365
        
        // If date has passed this year, calculate for next year
        if days < 0 {
            targetComponents.year = year + 1
            guard let nextYearDate = calendar.date(from: targetComponents) else { return 365 }
            return calendar.dateComponents([.day], from: date, to: nextYearDate).day ?? 365
        }
        
        return days
    }
}

// MARK: - LLM Extraction Response

struct LLMPatternExtractionResponse: Codable {
    let occupationType: String?
    let significantDates: [ExtractedSignificantDate]?
    let weekdayPatterns: [ExtractedWeekdayPattern]?
    let emotionalTriggers: [ExtractedTrigger]?
}

struct ExtractedSignificantDate: Codable {
    let monthDay: String           // "MM-DD" format
    let description: String
    let isPositive: Bool
    let moodImpact: Double         // -3 to +3
    let confidence: Double
}

struct ExtractedWeekdayPattern: Codable {
    let dayName: String            // "Monday", "Tuesday", etc.
    let description: String
    let moodImpact: Double
    let confidence: Double
}

struct ExtractedTrigger: Codable {
    let keywords: [String]
    let description: String
    let moodImpact: Double
    let confidence: Double
}

// MARK: - Pattern Store

@MainActor
class PersonalPatternStore: ObservableObject {
    static let shared = PersonalPatternStore()

    @Published var patterns: [PersonalMoodPattern] = []
    @Published var occupationType: OccupationType = .unknown
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?

    private let userDefaultsKey = "personal_mood_patterns"
    private let occupationKey = "user_occupation_type"
    private let lastSyncKey = "pattern_store_last_sync"

    private init() {
        debugPrint("📦 [PatternStore] Initializing PersonalPatternStore...")
        loadPatternsFromLocal()

        // Attempt cloud sync on init
        Task {
            await syncWithCloud()
        }
    }

    // MARK: - Local Storage

    func loadPatternsFromLocal() {
        debugPrint("📦 [PatternStore] Loading patterns from UserDefaults...")
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([PersonalMoodPattern].self, from: data) {
            patterns = decoded
            debugPrint("📦 [PatternStore] ✅ Loaded \(patterns.count) patterns from local storage")
            for (index, pattern) in patterns.enumerated() {
                debugPrint("📦 [PatternStore]   [\(index)] \(pattern.patternType.rawValue): \(pattern.name)")
            }
        } else {
            debugPrint("📦 [PatternStore] No existing patterns found in local storage")
        }

        if let occupationRaw = UserDefaults.standard.string(forKey: occupationKey),
           let occupation = OccupationType(rawValue: occupationRaw) {
            occupationType = occupation
            debugPrint("📦 [PatternStore] ✅ Loaded occupation type: \(occupation.rawValue)")
        } else {
            debugPrint("📦 [PatternStore] No occupation type in storage (using unknown)")
        }

        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = lastSync
        }
    }

    func savePatternsToLocal() {
        debugPrint("📦 [PatternStore] Saving \(patterns.count) patterns to UserDefaults...")
        if let encoded = try? JSONEncoder().encode(patterns) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            debugPrint("📦 [PatternStore] ✅ Patterns saved locally")
        } else {
            debugPrint("📦 [PatternStore] ❌ Failed to encode patterns")
        }
        UserDefaults.standard.set(occupationType.rawValue, forKey: occupationKey)
        debugPrint("📦 [PatternStore] ✅ Occupation type saved: \(occupationType.rawValue)")
    }

    // MARK: - Cloud Sync

    /// Sync patterns with Supabase (call on app launch and after changes)
    func syncWithCloud() async {
        guard let userId = DatabaseService.shared.currentUser?.id else {
            debugPrint("📦 [PatternStore] ⚠️ No user ID - skipping cloud sync")
            return
        }

        guard !isSyncing else {
            debugPrint("📦 [PatternStore] ⏳ Sync already in progress")
            return
        }

        isSyncing = true
        debugPrint("📦 [PatternStore] ☁️ Starting cloud sync...")

        // Merge local and cloud patterns
        let mergedPatterns = await DatabaseService.shared.loadAndMergeMoodPatterns(
            userId: userId,
            localPatterns: patterns
        )

        patterns = mergedPatterns
        savePatternsToLocal()

        // Sync occupation type
        if occupationType != .unknown {
            await DatabaseService.shared.saveUserOccupationType(occupationType, userId: userId)
        }

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        isSyncing = false

        debugPrint("📦 [PatternStore] ☁️ Cloud sync complete - \(patterns.count) patterns")
    }

    // MARK: - Pattern Management

    func addPattern(_ pattern: PersonalMoodPattern) {
        debugPrint("📦 [PatternStore] Adding pattern: \(pattern.patternType.rawValue) - \(pattern.name)")

        // Check for duplicates
        if let existingIndex = patterns.firstIndex(where: { existing in
            existing.patternType == pattern.patternType &&
            existing.dayOfWeek == pattern.dayOfWeek &&
            existing.monthDay == pattern.monthDay
        }) {
            // Update existing pattern if new one has higher confidence
            if pattern.confidence > patterns[existingIndex].confidence {
                patterns[existingIndex] = pattern
                debugPrint("📦 [PatternStore] → Updated existing pattern (higher confidence)")
            } else {
                debugPrint("📦 [PatternStore] → Skipped (existing has higher confidence)")
                return
            }
        } else {
            patterns.append(pattern)
            debugPrint("📦 [PatternStore] → Added new pattern (total: \(patterns.count))")
        }

        // Save locally first (for immediate access)
        savePatternsToLocal()

        // Sync to cloud in background
        Task {
            do {
                try await DatabaseService.shared.saveMoodPattern(pattern)
            } catch {
                debugPrint("📦 [PatternStore] ⚠️ Cloud save failed (local saved): \(error)")
            }
        }
    }

    func setOccupationType(_ type: OccupationType) {
        debugPrint("📦 [PatternStore] Setting occupation type: \(type.rawValue)")
        occupationType = type
        savePatternsToLocal()

        // Sync to cloud
        Task {
            if let userId = DatabaseService.shared.currentUser?.id {
                await DatabaseService.shared.saveUserOccupationType(type, userId: userId)
            }
        }
    }

    func getPatternsAffecting(date: Date) -> [PersonalMoodPattern] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)

        let affectingPatterns = patterns.filter { pattern in
            switch pattern.patternType {
            case .weekdayPreference:
                return pattern.dayOfWeek == weekday
            case .significantDate:
                return pattern.monthDay?.matches(date: date) == true
            case .occupationType:
                return true // Always applies
            default:
                return false
            }
        }

        return affectingPatterns
    }

    func clearPatterns(for userId: UUID) {
        let patternsToDelete = patterns.filter { $0.userId == userId }
        patterns.removeAll { $0.userId == userId }
        savePatternsToLocal()

        // Delete from cloud
        Task {
            for pattern in patternsToDelete {
                do {
                    try await DatabaseService.shared.deleteMoodPattern(patternId: pattern.id)
                } catch {
                    debugPrint("📦 [PatternStore] ⚠️ Failed to delete pattern from cloud: \(error)")
                }
            }
        }
    }

    /// Force a full resync from cloud (useful after device restore)
    func forceCloudSync() async {
        guard let userId = DatabaseService.shared.currentUser?.id else { return }

        isSyncing = true
        debugPrint("📦 [PatternStore] ☁️ Force syncing from cloud...")

        do {
            let cloudPatterns = try await DatabaseService.shared.loadMoodPatterns(userId: userId)
            if !cloudPatterns.isEmpty {
                patterns = cloudPatterns
                savePatternsToLocal()
                debugPrint("📦 [PatternStore] ☁️ Force sync complete - loaded \(cloudPatterns.count) patterns from cloud")
            } else {
                debugPrint("📦 [PatternStore] ☁️ No patterns in cloud, keeping local")
            }
        } catch {
            debugPrint("📦 [PatternStore] ❌ Force sync failed: \(error)")
        }

        isSyncing = false
    }

    // Legacy compatibility
    func loadPatterns() {
        loadPatternsFromLocal()
    }

    func savePatterns() {
        savePatternsToLocal()
    }
}
