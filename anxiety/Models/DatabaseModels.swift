//
//  DatabaseModels.swift
//  anxiety
//
//  Database models for Supabase integration
//

import Foundation

// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let email: String?
    let name: String?
    let anxietyLevel: Int? // 1-10 scale
    let hasActiveSubscription: Bool
    let subscriptionPlan: String?
    let subscriptionStartDate: Date?
    let onboardingCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case email
        case name
        case anxietyLevel = "anxiety_level"
        case hasActiveSubscription = "has_active_subscription"
        case subscriptionPlan = "subscription_plan"
        case subscriptionStartDate = "subscription_start_date"
        case onboardingCompleted = "onboarding_completed"
    }
}

// MARK: - Mood Entry
struct SupabaseMoodEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let mood: Int // 1-10 scale
    let anxietyLevel: Int // 1-10 scale
    let stressLevel: Int // 1-10 scale
    let notes: String?
    let triggers: [String]? // Array of trigger categories
    let location: String? // Optional location context
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case mood
        case anxietyLevel = "anxiety_level"
        case stressLevel = "stress_level"
        case notes
        case triggers
        case location
    }
}

// MARK: - Breathing Session
struct SupabaseBreathingSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let technique: String // "4-7-8", "box", "calm", etc.
    var duration: Int // seconds
    var completed: Bool
    let anxietyBefore: Int? // 1-10 scale
    var anxietyAfter: Int? // 1-10 scale
    let effectiveness: Int? // 1-10 scale, how helpful it was
    let heartRateBefore: Int?
    let heartRateAfter: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case technique
        case duration
        case completed
        case anxietyBefore = "anxiety_before"
        case anxietyAfter = "anxiety_after"
        case effectiveness
        case heartRateBefore = "heart_rate_before"
        case heartRateAfter = "heart_rate_after"
    }
}

// MARK: - Journal Entry
struct SupabaseJournalEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    let title: String?
    let content: String
    let mood: Int? // 1-10 scale
    let gratitudeItems: [String]?
    let tags: [String]?
    let isPrivate: Bool
    
    var weatherData: WeatherContextData?
    var location: LocationData?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
        case content
        case mood
        case gratitudeItems = "gratitude_items"
        case tags
        case isPrivate = "is_private"
        case weatherData = "weather_data"
        case location = "location_data"
    }
}

struct WeatherContextData: Codable {
    let temperature: Double?
    let condition: String?
    let humidity: Double?
    let uvIndex: Double?
    let feelsLike: Double?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case condition
        case humidity
        case uvIndex = "uv_index"
        case feelsLike = "feels_like"
    }
}

struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case city
        case country
    }
}

// MARK: - Meditation Session
struct SupabaseMeditationSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let type: String // "guided", "sleep_story", "nature_sounds"
    let title: String
    var duration: Int // seconds
    var completed: Bool
    var completionRate: Double // 0.0 - 1.0
    let effectiveness: Int? // 1-10 scale
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case type
        case title
        case duration
        case completed
        case completionRate = "completion_rate"
        case effectiveness
    }
}

// MARK: - Panic Attack Log
struct SupabasePanicAttackLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let severity: Int // 1-10 scale
    let duration: Int? // minutes
    let triggers: [String]?
    let location: String?
    let copingStrategiesUsed: [String]?
    let effectiveness: Int? // 1-10 scale for coping strategies
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case severity
        case duration
        case triggers
        case location
        case copingStrategiesUsed = "coping_strategies_used"
        case effectiveness
        case notes
    }
}

// MARK: - Mood Pattern (for prediction system - synced to Supabase)
struct SupabaseMoodPattern: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let patternType: String          // occupationType, weekdayPreference, significantDate, seasonalPattern, recurringTrigger
    let name: String
    let description: String
    let moodImpact: Double           // -3.0 to +3.0
    let confidence: Double           // 0.0 to 1.0
    let dayOfWeek: Int?              // 1-7 for weekday patterns
    let monthDay: String?            // "MM-DD" format for recurring dates
    let occupationType: String?      // employee, businessOwner, student, etc.
    let triggerKeywords: [String]?   // Array of keywords
    let extractedFromEntryId: UUID?
    let extractedSnippet: String?
    let lastValidated: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case patternType = "pattern_type"
        case name
        case description
        case moodImpact = "mood_impact"
        case confidence
        case dayOfWeek = "day_of_week"
        case monthDay = "month_day"
        case occupationType = "occupation_type"
        case triggerKeywords = "trigger_keywords"
        case extractedFromEntryId = "extracted_from_entry_id"
        case extractedSnippet = "extracted_snippet"
        case lastValidated = "last_validated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Convert from local PersonalMoodPattern to Supabase format
    init(from localPattern: PersonalMoodPattern) {
        self.id = localPattern.id
        self.userId = localPattern.userId
        self.patternType = localPattern.patternType.rawValue
        self.name = localPattern.name
        self.description = localPattern.description
        self.moodImpact = localPattern.moodImpact
        self.confidence = localPattern.confidence
        self.dayOfWeek = localPattern.dayOfWeek
        self.monthDay = localPattern.monthDay.map { String(format: "%02d-%02d", $0.month, $0.day) }
        self.occupationType = localPattern.occupationType?.rawValue
        self.triggerKeywords = localPattern.triggerKeywords
        self.extractedFromEntryId = localPattern.extractedFromEntryId
        self.extractedSnippet = localPattern.extractedSnippet
        self.lastValidated = localPattern.lastValidated
        self.createdAt = localPattern.createdAt
        self.updatedAt = Date()
    }

    /// Convert to local PersonalMoodPattern
    func toLocalPattern() -> PersonalMoodPattern {
        let patternTypeEnum = MoodPatternType(rawValue: patternType) ?? .recurringTrigger
        let occupationTypeEnum = occupationType.flatMap { OccupationType(rawValue: $0) }
        let monthDayParsed: MonthDay? = monthDay.flatMap { str in
            let parts = str.split(separator: "-")
            guard parts.count == 2,
                  let month = Int(parts[0]),
                  let day = Int(parts[1]) else { return nil }
            return MonthDay(month: month, day: day)
        }

        return PersonalMoodPattern(
            id: id,
            userId: userId,
            patternType: patternTypeEnum,
            name: name,
            description: description,
            moodImpact: moodImpact,
            confidence: confidence,
            dayOfWeek: dayOfWeek,
            monthDay: monthDayParsed,
            occupationType: occupationTypeEnum,
            triggerKeywords: triggerKeywords,
            extractedFromEntryId: extractedFromEntryId,
            extractedSnippet: extractedSnippet,
            createdAt: createdAt,
            lastValidated: lastValidated
        )
    }
}

// MARK: - User Mood Profile Summary (compact profile for predictions)
struct SupabaseUserMoodProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let occupationType: String?
    let llmSummary: String?          // Compressed text summary from LLM
    let totalEntriesAnalyzed: Int
    let lastExtractionDate: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case occupationType = "occupation_type"
        case llmSummary = "llm_summary"
        case totalEntriesAnalyzed = "total_entries_analyzed"
        case lastExtractionDate = "last_extraction_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Daily Check-in
struct SupabaseDailyCheckIn: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    let createdAt: Date
    let overallMood: Int // 1-10 scale
    let anxietyLevel: Int // 1-10 scale
    let stressLevel: Int // 1-10 scale
    let energyLevel: Int // 1-10 scale
    let sleepQuality: Int? // 1-10 scale
    let sleepHours: Double?
    let exerciseMinutes: Int?
    let gratitudeNote: String?
    let goals: [String]?
    let goalsCompleted: [Bool]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case createdAt = "created_at"
        case overallMood = "overall_mood"
        case anxietyLevel = "anxiety_level"
        case stressLevel = "stress_level"
        case energyLevel = "energy_level"
        case sleepQuality = "sleep_quality"
        case sleepHours = "sleep_hours"
        case exerciseMinutes = "exercise_minutes"
        case gratitudeNote = "gratitude_note"
        case goals
        case goalsCompleted = "goals_completed"
    }
}