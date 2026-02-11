#if TEST_HARNESS
import Foundation
import SwiftUI

// MARK: - Trend + Visual State (copied from production for fidelity)

enum MoodTrendDirection: String {
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
        case .improving: return Color(hex: "10B981")
        case .declining: return Color(hex: "F59E0B")
        case .stable: return Color(hex: "6B7280")
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

enum MoodVisualState {
    case significantlyAbove
    case aboveBaseline
    case nearBaseline
    case belowBaseline
    case significantlyBelow

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

struct AdaptiveColors {
    struct Text {
        static let secondary = Color.gray
    }
}

struct OnboardingColors {
    static let wellnessGreen = Color.green
    static let wellnessOrange = Color.orange
    static let wellnessLavender = Color.purple
    static let softTeal = Color.cyan
}

struct MoodInsight {
    let personalBaseline: Double
    let comparativeScore: Double
    let weekdayAverage: Double?
    let weekdayRank: Int?
    let primaryInsight: String
    let trend: MoodTrendDirection
    let trendStrength: Int
}

final class PersonalMoodAnalytics {
    static let shared = PersonalMoodAnalytics()

    func generateInsight(
        for date: Date,
        entries: [SupabaseJournalEntry],
        existingPrediction: Any? = nil
    ) async -> MoodInsight {
        return MoodInsight(
            personalBaseline: 6.0,
            comparativeScore: 0.0,
            weekdayAverage: nil,
            weekdayRank: nil,
            primaryInsight: "Harness stub insight.",
            trend: .stable,
            trendStrength: 1
        )
    }
}

// MARK: - Pattern Store Stubs

enum MoodPatternType: String {
    case occupationType
    case weekdayPreference
    case significantDate
    case seasonalPattern
    case recurringTrigger
}

enum OccupationType: String {
    case employee, businessOwner, student, freelancer, unemployed, retired, unknown

    func moodImpactForWeekday(_ weekday: Int) -> Double {
        switch self {
        case .employee:
            switch weekday {
            case 1: return 0.3
            case 2: return -0.6
            case 3: return -0.3
            case 4: return 0.0
            case 5: return 0.3
            case 6: return 0.8
            case 7: return 0.5
            default: return 0.0
            }
        case .businessOwner:
            switch weekday {
            case 1: return -0.2
            case 2: return 0.7
            case 3: return 0.5
            case 4: return 0.4
            case 5: return 0.3
            case 6: return 0.2
            case 7: return -0.1
            default: return 0.0
            }
        case .student:
            switch weekday {
            case 1: return 0.2
            case 2: return -0.4
            case 3: return -0.2
            case 4: return 0.0
            case 5: return 0.2
            case 6: return 0.7
            case 7: return 0.5
            default: return 0.0
            }
        case .freelancer, .unemployed, .retired, .unknown:
            return 0.0
        }
    }
}

struct MonthDay: Equatable {
    let month: Int
    let day: Int

    func matches(date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: date)
        return components.month == month && components.day == day
    }
}

struct PersonalMoodPattern: Identifiable {
    let id: UUID
    let userId: UUID
    let patternType: MoodPatternType
    let name: String
    let description: String
    let moodImpact: Double
    let confidence: Double
    let dayOfWeek: Int?
    let monthDay: MonthDay?
    let occupationType: OccupationType?
}

final class PersonalPatternStore: ObservableObject {
    static let shared = PersonalPatternStore()

    @Published var patterns: [PersonalMoodPattern] = []
    @Published var occupationType: OccupationType = .unknown

    func getPatternsAffecting(date: Date) -> [PersonalMoodPattern] {
        return []
    }
}

// MARK: - Lightweight Journal Entry

struct SupabaseJournalEntry: Identifiable {
    let id: UUID
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    let title: String?
    let content: String
    let mood: Int?
    let gratitudeItems: [String]?
    let tags: [String]?
    let isPrivate: Bool

    init(
        id: UUID = UUID(),
        userId: UUID,
        createdAt: Date,
        updatedAt: Date,
        title: String? = nil,
        content: String,
        mood: Int?,
        gratitudeItems: [String]? = nil,
        tags: [String]? = nil,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.content = content
        self.mood = mood
        self.gratitudeItems = gratitudeItems
        self.tags = tags
        self.isPrivate = isPrivate
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
#endif
