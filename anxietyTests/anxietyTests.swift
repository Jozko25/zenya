//
//  anxietyTests.swift
//  anxietyTests
//
//  Created by Ján Harmady on 27/08/2025.


import Testing
@testable import zenya

struct anxietyTests {
    private let predictionService = MoodPredictionService.shared
    private let calendar = Calendar.current
    private let testUserId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    @Test func predictionRespondsToNegativeAndPositiveEvents() async throws {
        let targetDate = calendar.date(byAdding: .day, value: 1, to: Date())!

        var entries = baseCalmEntries()
        let baseline = await predictionService.predictMoodWithInsights(
            for: targetDate,
            historicalEntries: entries,
            location: nil
        )

        entries.append(
            makeEntry(
                daysAgo: 1,
                mood: 2,
                content: "Terrible panic episode at work, felt overwhelmed and hopeless."
            )
        )

        let afterTerrible = await predictionService.predictMoodWithInsights(
            for: targetDate,
            historicalEntries: entries,
            location: nil
        )

        #expect(
            afterTerrible.predictedMood < baseline.predictedMood,
            "Prediction should dip after logging a terrible event"
        )

        entries.append(
            makeEntry(
                daysAgo: 0,
                mood: 9,
                content: "Breakthrough therapy session and sunset walk, felt proud and calm."
            )
        )

        let afterPositive = await predictionService.predictMoodWithInsights(
            for: targetDate,
            historicalEntries: entries,
            location: nil
        )

        #expect(
            afterPositive.predictedMood > afterTerrible.predictedMood,
            "Prediction should rebound upward after a positive event"
        )
    }

    private func baseCalmEntries() -> [SupabaseJournalEntry] {
        var items: [SupabaseJournalEntry] = []
        for dayOffset in 2...14 {
            items.append(
                makeEntry(
                    daysAgo: dayOffset,
                    mood: Int.random(in: 6...7),
                    content: "Normal day with breathing practice and focus sessions. Energy level medium."
                )
            )
        }
        return items
    }

    private func makeEntry(daysAgo: Int, mood: Int, content: String) -> SupabaseJournalEntry {
        let created = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return SupabaseJournalEntry(
            id: UUID(),
            userId: testUserId,
            createdAt: created,
            updatedAt: created,
            title: nil,
            content: content,
            mood: mood,
            gratitudeItems: nil,
            tags: nil,
            isPrivate: false,
            weatherData: nil,
            location: nil
        )
    }
}
