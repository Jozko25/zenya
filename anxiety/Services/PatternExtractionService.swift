//
//  PatternExtractionService.swift
//  anxiety
//
//  LLM-powered service to extract personal mood patterns from journal entries
//

import Foundation

@MainActor
class PatternExtractionService: ObservableObject {
    static let shared = PatternExtractionService()
    
    private let openAIClient = OpenAIClient()
    private let patternStore = PersonalPatternStore.shared
    
    private init() {}
    
    /// Extracts personal mood patterns from a batch of journal entries
    func extractPatterns(from entries: [SupabaseJournalEntry], userId: UUID) async {
        debugPrint("🧠 ═══════════════════════════════════════════════════════════")
        debugPrint("🧠 [PatternExtraction] STARTING PATTERN EXTRACTION")
        debugPrint("🧠 [PatternExtraction] User ID: \(userId)")
        debugPrint("🧠 [PatternExtraction] Total entries provided: \(entries.count)")

        guard !entries.isEmpty else {
            debugPrint("🧠 [PatternExtraction] ❌ No entries provided - aborting")
            return
        }

        // Combine recent entries for context
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }.prefix(10)
        debugPrint("🧠 [PatternExtraction] Using \(sortedEntries.count) most recent entries")

        let combinedContent = sortedEntries
            .map { entry in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "EEEE, MMM d yyyy"
                let dateStr = dateFormatter.string(from: entry.createdAt)
                return "[\(dateStr)] (Mood: \(entry.mood ?? 5)/10)\n\(entry.content)"
            }
            .joined(separator: "\n\n---\n\n")

        debugPrint("🧠 [PatternExtraction] Combined content length: \(combinedContent.count) chars")
        
        let systemPrompt = """
        You are an expert psychologist analyzing journal entries to identify personal mood patterns.
        
        Your task is to extract patterns that can predict future mood, including:
        
        1. **Occupation Type**: Determine if the person is an employee, business owner, student, freelancer, unemployed, or retired based on their writing.
        
        2. **Significant Dates**: Look for mentions of important personal dates (anniversaries, deaths, birthdays, traumatic events) that might affect mood on specific calendar days.
        
        3. **Weekday Patterns**: Identify if certain days of the week consistently affect their mood (e.g., "I hate Mondays", "Fridays are my favorite").
        
        4. **Emotional Triggers**: Identify recurring themes, keywords, or situations that affect their mood.
        
        Respond ONLY with valid JSON in this exact format:
        {
            "occupationType": "employee|businessOwner|student|freelancer|unemployed|retired|unknown",
            "significantDates": [
                {
                    "monthDay": "MM-DD",
                    "description": "Brief description",
                    "isPositive": true/false,
                    "moodImpact": -3.0 to 3.0,
                    "confidence": 0.0 to 1.0
                }
            ],
            "weekdayPatterns": [
                {
                    "dayName": "Monday",
                    "description": "Brief description",
                    "moodImpact": -3.0 to 3.0,
                    "confidence": 0.0 to 1.0
                }
            ],
            "emotionalTriggers": [
                {
                    "keywords": ["word1", "word2"],
                    "description": "Brief description",
                    "moodImpact": -3.0 to 3.0,
                    "confidence": 0.0 to 1.0
                }
            ]
        }
        
        Only include patterns you are confident about. If you don't find a pattern type, return an empty array for that field.
        Be conservative with confidence scores - only use high confidence (>0.7) for very clear patterns.
        """
        
        let userMessage = """
        Analyze these journal entries and extract mood patterns:
        
        \(combinedContent)
        """
        
        do {
            debugPrint("🧠 [PatternExtraction] Sending to OpenAI for analysis...")
            let response = try await openAIClient.sendMessage(
                userMessage,
                conversationHistory: [],
                systemPrompt: systemPrompt
            )

            debugPrint("🧠 [PatternExtraction] Received response (\(response.count) chars)")
            debugPrint("🧠 [PatternExtraction] Raw response preview: \(String(response.prefix(500)))...")

            // Parse LLM response
            if let patterns = parsePatternResponse(response, userId: userId, entries: entries) {
                debugPrint("🧠 [PatternExtraction] ✅ Successfully parsed LLM response")
                processExtractedPatterns(patterns, userId: userId)
            } else {
                debugPrint("🧠 [PatternExtraction] ❌ Failed to parse LLM response")
            }

        } catch {
            debugPrint("🧠 [PatternExtraction] ❌ Pattern extraction failed: \(error.localizedDescription)")
        }
        debugPrint("🧠 ═══════════════════════════════════════════════════════════")
    }
    
    private func parsePatternResponse(_ response: String, userId: UUID, entries: [SupabaseJournalEntry]) -> LLMPatternExtractionResponse? {
        // Clean up response (remove markdown code blocks if present)
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanedResponse.data(using: .utf8) else { return nil }
        
        do {
            let decoded = try JSONDecoder().decode(LLMPatternExtractionResponse.self, from: data)
            return decoded
        } catch {
            debugPrint("Failed to parse LLM pattern response: \(error)")
            debugPrint("Raw response: \(cleanedResponse)")
            return nil
        }
    }
    
    private func processExtractedPatterns(_ response: LLMPatternExtractionResponse, userId: UUID) {
        debugPrint("🧠 [PatternExtraction] ──── PROCESSING EXTRACTED PATTERNS ────")

        // Set occupation type
        if let occupationStr = response.occupationType,
           let occupation = OccupationType(rawValue: occupationStr) {
            debugPrint("🧠 [PatternExtraction] Occupation detected: \(occupation.rawValue)")
            patternStore.setOccupationType(occupation)

            // Create occupation pattern
            let occupationPattern = PersonalMoodPattern(
                userId: userId,
                patternType: .occupationType,
                name: "Occupation Pattern",
                description: "Based on \(occupation.rawValue) work schedule",
                moodImpact: 0.0, // Impact calculated per weekday
                confidence: 0.7,
                occupationType: occupation
            )
            patternStore.addPattern(occupationPattern)
            debugPrint("🧠 [PatternExtraction] → Added occupation pattern")
        } else {
            debugPrint("🧠 [PatternExtraction] No occupation type detected (raw: \(response.occupationType ?? "nil"))")
        }

        // Process significant dates
        if let dates = response.significantDates {
            debugPrint("🧠 [PatternExtraction] Significant dates found: \(dates.count)")
            for dateInfo in dates {
                debugPrint("🧠 [PatternExtraction]   - \(dateInfo.monthDay): \(dateInfo.description) (conf: \(String(format: "%.0f%%", dateInfo.confidence * 100)), impact: \(String(format: "%+.1f", dateInfo.moodImpact)))")
                guard dateInfo.confidence >= 0.5 else {
                    debugPrint("🧠 [PatternExtraction]     → Skipped (confidence < 50%)")
                    continue
                }

                if let monthDay = parseMonthDay(dateInfo.monthDay) {
                    let pattern = PersonalMoodPattern(
                        userId: userId,
                        patternType: .significantDate,
                        name: "Significant Date",
                        description: dateInfo.description,
                        moodImpact: dateInfo.moodImpact,
                        confidence: dateInfo.confidence,
                        monthDay: monthDay
                    )
                    patternStore.addPattern(pattern)
                    debugPrint("🧠 [PatternExtraction]     → Added significant date pattern for \(monthDay.month)/\(monthDay.day)")
                }
            }
        } else {
            debugPrint("🧠 [PatternExtraction] No significant dates in response")
        }

        // Process weekday patterns
        if let weekdayPatterns = response.weekdayPatterns {
            debugPrint("🧠 [PatternExtraction] Weekday patterns found: \(weekdayPatterns.count)")
            for weekdayInfo in weekdayPatterns {
                debugPrint("🧠 [PatternExtraction]   - \(weekdayInfo.dayName): \(weekdayInfo.description) (conf: \(String(format: "%.0f%%", weekdayInfo.confidence * 100)), impact: \(String(format: "%+.1f", weekdayInfo.moodImpact)))")
                guard weekdayInfo.confidence >= 0.5 else {
                    debugPrint("🧠 [PatternExtraction]     → Skipped (confidence < 50%)")
                    continue
                }

                if let weekday = weekdayNameToNumber(weekdayInfo.dayName) {
                    let pattern = PersonalMoodPattern(
                        userId: userId,
                        patternType: .weekdayPreference,
                        name: "\(weekdayInfo.dayName) Pattern",
                        description: weekdayInfo.description,
                        moodImpact: weekdayInfo.moodImpact,
                        confidence: weekdayInfo.confidence,
                        dayOfWeek: weekday
                    )
                    patternStore.addPattern(pattern)
                    debugPrint("🧠 [PatternExtraction]     → Added weekday pattern for \(weekdayInfo.dayName)")
                }
            }
        } else {
            debugPrint("🧠 [PatternExtraction] No weekday patterns in response")
        }

        // Process emotional triggers
        if let triggers = response.emotionalTriggers {
            debugPrint("🧠 [PatternExtraction] Emotional triggers found: \(triggers.count)")
            for trigger in triggers {
                debugPrint("🧠 [PatternExtraction]   - Keywords: \(trigger.keywords.joined(separator: ", ")): \(trigger.description) (conf: \(String(format: "%.0f%%", trigger.confidence * 100)))")
                guard trigger.confidence >= 0.5 else {
                    debugPrint("🧠 [PatternExtraction]     → Skipped (confidence < 50%)")
                    continue
                }

                let pattern = PersonalMoodPattern(
                    userId: userId,
                    patternType: .recurringTrigger,
                    name: "Emotional Trigger",
                    description: trigger.description,
                    moodImpact: trigger.moodImpact,
                    confidence: trigger.confidence,
                    triggerKeywords: trigger.keywords
                )
                patternStore.addPattern(pattern)
                debugPrint("🧠 [PatternExtraction]     → Added emotional trigger pattern")
            }
        } else {
            debugPrint("🧠 [PatternExtraction] No emotional triggers in response")
        }

        debugPrint("🧠 [PatternExtraction] ════════════════════════════════════════")
        debugPrint("🧠 [PatternExtraction] ✅ TOTAL PATTERNS IN STORE: \(patternStore.patterns.count)")
        debugPrint("🧠 [PatternExtraction] Current occupation type: \(patternStore.occupationType.rawValue)")
        for (index, pattern) in patternStore.patterns.enumerated() {
            debugPrint("🧠 [PatternExtraction]   [\(index)] \(pattern.patternType.rawValue): \(pattern.name) - \(pattern.description)")
        }
        debugPrint("🧠 [PatternExtraction] ════════════════════════════════════════")
    }
    
    private func parseMonthDay(_ dateString: String) -> MonthDay? {
        let parts = dateString.split(separator: "-")
        guard parts.count == 2,
              let month = Int(parts[0]),
              let day = Int(parts[1]),
              month >= 1 && month <= 12,
              day >= 1 && day <= 31 else {
            return nil
        }
        return MonthDay(month: month, day: day)
    }
    
    private func weekdayNameToNumber(_ name: String) -> Int? {
        switch name.lowercased() {
        case "sunday": return 1
        case "monday": return 2
        case "tuesday": return 3
        case "wednesday": return 4
        case "thursday": return 5
        case "friday": return 6
        case "saturday": return 7
        default: return nil
        }
    }
}
