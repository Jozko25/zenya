import Foundation
import SwiftUI

@main
struct MoodPredictionHarness {
    static func main() async {
        let service = MoodPredictionService.shared
        let calendar = Calendar.current
        let userId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let targetDate = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        var entries = makeBaseEntries(userId: userId)
        let baseline = await service.predictMood(for: targetDate, historicalEntries: entries, location: nil)
        logPrediction(label: "Baseline", prediction: baseline)

        entries.append(makeEntry(daysAgo: 1, mood: 2, content: "Panicked presentation, felt terrible, cried in the bathroom.", userId: userId))
        let afterTerrible = await service.predictMood(for: targetDate, historicalEntries: entries, location: nil)
        logPrediction(label: "After terrible event", prediction: afterTerrible)

        entries.append(makeEntry(daysAgo: 0, mood: 9, content: "Therapy win + sunset walk, felt proud and light.", userId: userId))
        let afterPositive = await service.predictMood(for: targetDate, historicalEntries: entries, location: nil)
        logPrediction(label: "After positive event", prediction: afterPositive)

        let downShift = baseline.predictedMood - afterTerrible.predictedMood
        let upShift = afterPositive.predictedMood - afterTerrible.predictedMood
        print(String(format: "Δ terrible vs baseline: %.2f pts", downShift))
        print(String(format: "Δ positive rebound: %.2f pts", upShift))
    }

    private static func logPrediction(label: String, prediction: MoodPrediction) {
        let moodString = String(format: "%.2f", prediction.predictedMood)
        print("\(label): \(moodString) (\(prediction.moodState.rawValue))")
    }

    private static func makeBaseEntries(userId: UUID) -> [SupabaseJournalEntry] {
        var items: [SupabaseJournalEntry] = []
        for daysAgo in 3...14 {
            items.append(makeEntry(
                daysAgo: daysAgo,
                mood: Int.random(in: 6...7),
                content: "Routine day with breathing practice and journaling.",
                userId: userId
            ))
        }
        return items
    }

    private static func makeEntry(daysAgo: Int, mood: Int, content: String, userId: UUID) -> SupabaseJournalEntry {
        let calendar = Calendar.current
        let created = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return SupabaseJournalEntry(
            id: UUID(),
            userId: userId,
            createdAt: created,
            updatedAt: created,
            title: nil,
            content: content,
            mood: mood,
            gratitudeItems: nil,
            tags: nil,
            isPrivate: false
        )
    }
}
