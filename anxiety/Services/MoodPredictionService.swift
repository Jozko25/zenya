//
//  MoodPredictionService.swift
//  anxiety
//
//  Advanced mood prediction using contextual factors
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Time of Day Pattern

enum TimeOfDay: String, CaseIterable {
    case earlyMorning = "Early Morning"  // 5-8 AM
    case morning = "Morning"              // 8-12 PM
    case afternoon = "Afternoon"          // 12-5 PM
    case evening = "Evening"              // 5-9 PM
    case night = "Night"                  // 9 PM - 5 AM

    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<8: return .earlyMorning
        case 8..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    var icon: String {
        switch self {
        case .earlyMorning: return "sunrise.fill"
        case .morning: return "sun.max.fill"
        case .afternoon: return "sun.min.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }
}

// MARK: - Outlier Detection

struct OutlierInfo {
    let isOutlier: Bool
    let deviationFromMean: Double
    let dampeningFactor: Double // 1.0 = full weight, 0.3 = dampened

    static func analyze(mood: Double, mean: Double, standardDeviation: Double) -> OutlierInfo {
        guard standardDeviation > 0 else {
            return OutlierInfo(isOutlier: false, deviationFromMean: 0, dampeningFactor: 1.0)
        }

        let deviation = abs(mood - mean) / standardDeviation

        if deviation >= 2.5 {
            // Extreme outlier - heavily dampen
            return OutlierInfo(isOutlier: true, deviationFromMean: deviation, dampeningFactor: 0.2)
        } else if deviation >= 2.0 {
            // Significant outlier - moderate dampening
            return OutlierInfo(isOutlier: true, deviationFromMean: deviation, dampeningFactor: 0.4)
        } else if deviation >= 1.5 {
            // Mild outlier - light dampening
            return OutlierInfo(isOutlier: true, deviationFromMean: deviation, dampeningFactor: 0.7)
        } else {
            return OutlierInfo(isOutlier: false, deviationFromMean: deviation, dampeningFactor: 1.0)
        }
    }
}

// MARK: - Life Change Detection

struct PatternShiftInfo {
    let hasRecentShift: Bool
    let shiftMagnitude: Double      // How much the pattern changed
    let daysSinceShift: Int?
    let recentWeight: Double        // How much to weight recent vs historical (0.5-1.0)
    let description: String?

    static let noShift = PatternShiftInfo(
        hasRecentShift: false,
        shiftMagnitude: 0,
        daysSinceShift: nil,
        recentWeight: 0.5,
        description: nil
    )
}

// MARK: - Locale-Aware Holidays

struct LocaleHoliday {
    let name: String
    let date: Date
    let isNational: Bool
    let moodImpact: Double // Positive for happy holidays, negative for somber ones

    static func getHolidays(for date: Date, locale: Locale = .current) -> [LocaleHoliday] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let regionCode = locale.region?.identifier ?? "US"

        var holidays: [LocaleHoliday] = []

        // Universal holidays
        holidays.append(contentsOf: universalHolidays(year: year, calendar: calendar))

        // Region-specific holidays
        switch regionCode {
        case "US":
            holidays.append(contentsOf: usHolidays(year: year, calendar: calendar))
        case "GB":
            holidays.append(contentsOf: ukHolidays(year: year, calendar: calendar))
        case "DE", "AT", "CH":
            holidays.append(contentsOf: germanHolidays(year: year, calendar: calendar))
        case "FR":
            holidays.append(contentsOf: frenchHolidays(year: year, calendar: calendar))
        case "ES":
            holidays.append(contentsOf: spanishHolidays(year: year, calendar: calendar))
        case "CZ", "SK":
            holidays.append(contentsOf: czechHolidays(year: year, calendar: calendar))
        case "PL":
            holidays.append(contentsOf: polishHolidays(year: year, calendar: calendar))
        case "JP":
            holidays.append(contentsOf: japaneseHolidays(year: year, calendar: calendar))
        case "CN":
            holidays.append(contentsOf: chineseHolidays(year: year, calendar: calendar))
        case "IN":
            holidays.append(contentsOf: indianHolidays(year: year, calendar: calendar))
        case "BR":
            holidays.append(contentsOf: brazilianHolidays(year: year, calendar: calendar))
        case "AU":
            holidays.append(contentsOf: australianHolidays(year: year, calendar: calendar))
        case "CA":
            holidays.append(contentsOf: canadianHolidays(year: year, calendar: calendar))
        default:
            // Fallback to US holidays for unknown regions
            holidays.append(contentsOf: usHolidays(year: year, calendar: calendar))
        }

        return holidays.sorted { $0.date < $1.date }
    }

    private static func universalHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "New Year's Day", date: calendar.date(from: DateComponents(year: year, month: 1, day: 1))!, isNational: true, moodImpact: 0.5),
            LocaleHoliday(name: "Valentine's Day", date: calendar.date(from: DateComponents(year: year, month: 2, day: 14))!, isNational: false, moodImpact: 0.2),
            LocaleHoliday(name: "New Year's Eve", date: calendar.date(from: DateComponents(year: year, month: 12, day: 31))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func usHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        var holidays: [LocaleHoliday] = []

        // MLK Day - 3rd Monday of January
        if let mlk = nthWeekday(nth: 3, weekday: 2, month: 1, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "MLK Day", date: mlk, isNational: true, moodImpact: 0.2))
        }

        // Presidents Day - 3rd Monday of February
        if let presidents = nthWeekday(nth: 3, weekday: 2, month: 2, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Presidents Day", date: presidents, isNational: true, moodImpact: 0.2))
        }

        // Memorial Day - Last Monday of May
        if let memorial = lastWeekday(weekday: 2, month: 5, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Memorial Day", date: memorial, isNational: true, moodImpact: 0.1))
        }

        holidays.append(LocaleHoliday(name: "Independence Day", date: calendar.date(from: DateComponents(year: year, month: 7, day: 4))!, isNational: true, moodImpact: 0.6))

        // Labor Day - 1st Monday of September
        if let labor = nthWeekday(nth: 1, weekday: 2, month: 9, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Labor Day", date: labor, isNational: true, moodImpact: 0.3))
        }

        // Thanksgiving - 4th Thursday of November
        if let thanksgiving = nthWeekday(nth: 4, weekday: 5, month: 11, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Thanksgiving", date: thanksgiving, isNational: true, moodImpact: 0.5))
        }

        holidays.append(LocaleHoliday(name: "Christmas Eve", date: calendar.date(from: DateComponents(year: year, month: 12, day: 24))!, isNational: false, moodImpact: 0.5))
        holidays.append(LocaleHoliday(name: "Christmas", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6))

        return holidays
    }

    private static func ukHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        var holidays: [LocaleHoliday] = []

        // Early May Bank Holiday - 1st Monday of May
        if let mayDay = nthWeekday(nth: 1, weekday: 2, month: 5, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "May Day", date: mayDay, isNational: true, moodImpact: 0.3))
        }

        // Spring Bank Holiday - Last Monday of May
        if let spring = lastWeekday(weekday: 2, month: 5, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Spring Bank Holiday", date: spring, isNational: true, moodImpact: 0.3))
        }

        // Summer Bank Holiday - Last Monday of August
        if let summer = lastWeekday(weekday: 2, month: 8, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Summer Bank Holiday", date: summer, isNational: true, moodImpact: 0.3))
        }

        holidays.append(LocaleHoliday(name: "Boxing Day", date: calendar.date(from: DateComponents(year: year, month: 12, day: 26))!, isNational: true, moodImpact: 0.4))
        holidays.append(LocaleHoliday(name: "Christmas", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6))

        return holidays
    }

    private static func germanHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Tag der Arbeit", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Tag der Deutschen Einheit", date: calendar.date(from: DateComponents(year: year, month: 10, day: 3))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Weihnachten", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
            LocaleHoliday(name: "Zweiter Weihnachtstag", date: calendar.date(from: DateComponents(year: year, month: 12, day: 26))!, isNational: true, moodImpact: 0.4),
        ]
    }

    private static func frenchHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Fête du Travail", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Fête Nationale", date: calendar.date(from: DateComponents(year: year, month: 7, day: 14))!, isNational: true, moodImpact: 0.6),
            LocaleHoliday(name: "Assomption", date: calendar.date(from: DateComponents(year: year, month: 8, day: 15))!, isNational: true, moodImpact: 0.2),
            LocaleHoliday(name: "Toussaint", date: calendar.date(from: DateComponents(year: year, month: 11, day: 1))!, isNational: true, moodImpact: 0.1),
            LocaleHoliday(name: "Noël", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func spanishHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Día del Trabajo", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Fiesta Nacional", date: calendar.date(from: DateComponents(year: year, month: 10, day: 12))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "Navidad", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func czechHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Svátek práce", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Den vítězství", date: calendar.date(from: DateComponents(year: year, month: 5, day: 8))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Den státnosti", date: calendar.date(from: DateComponents(year: year, month: 9, day: 28))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Den vzniku Československa", date: calendar.date(from: DateComponents(year: year, month: 10, day: 28))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "Den boje za svobodu", date: calendar.date(from: DateComponents(year: year, month: 11, day: 17))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Vánoce", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func polishHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Święto Pracy", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Święto Konstytucji", date: calendar.date(from: DateComponents(year: year, month: 5, day: 3))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "Święto Niepodległości", date: calendar.date(from: DateComponents(year: year, month: 11, day: 11))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "Boże Narodzenie", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func japaneseHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "成人の日", date: calendar.date(from: DateComponents(year: year, month: 1, day: 9))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "建国記念の日", date: calendar.date(from: DateComponents(year: year, month: 2, day: 11))!, isNational: true, moodImpact: 0.2),
            LocaleHoliday(name: "こどもの日", date: calendar.date(from: DateComponents(year: year, month: 5, day: 5))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "文化の日", date: calendar.date(from: DateComponents(year: year, month: 11, day: 3))!, isNational: true, moodImpact: 0.3),
        ]
    }

    private static func chineseHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "劳动节", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.4),
            LocaleHoliday(name: "国庆节", date: calendar.date(from: DateComponents(year: year, month: 10, day: 1))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func indianHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Republic Day", date: calendar.date(from: DateComponents(year: year, month: 1, day: 26))!, isNational: true, moodImpact: 0.5),
            LocaleHoliday(name: "Independence Day", date: calendar.date(from: DateComponents(year: year, month: 8, day: 15))!, isNational: true, moodImpact: 0.6),
            LocaleHoliday(name: "Gandhi Jayanti", date: calendar.date(from: DateComponents(year: year, month: 10, day: 2))!, isNational: true, moodImpact: 0.3),
        ]
    }

    private static func brazilianHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Tiradentes", date: calendar.date(from: DateComponents(year: year, month: 4, day: 21))!, isNational: true, moodImpact: 0.2),
            LocaleHoliday(name: "Dia do Trabalho", date: calendar.date(from: DateComponents(year: year, month: 5, day: 1))!, isNational: true, moodImpact: 0.3),
            LocaleHoliday(name: "Independência", date: calendar.date(from: DateComponents(year: year, month: 9, day: 7))!, isNational: true, moodImpact: 0.5),
            LocaleHoliday(name: "Natal", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
        ]
    }

    private static func australianHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        return [
            LocaleHoliday(name: "Australia Day", date: calendar.date(from: DateComponents(year: year, month: 1, day: 26))!, isNational: true, moodImpact: 0.5),
            LocaleHoliday(name: "Anzac Day", date: calendar.date(from: DateComponents(year: year, month: 4, day: 25))!, isNational: true, moodImpact: 0.2),
            LocaleHoliday(name: "Christmas", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6),
            LocaleHoliday(name: "Boxing Day", date: calendar.date(from: DateComponents(year: year, month: 12, day: 26))!, isNational: true, moodImpact: 0.4),
        ]
    }

    private static func canadianHolidays(year: Int, calendar: Calendar) -> [LocaleHoliday] {
        var holidays: [LocaleHoliday] = []

        // Victoria Day - Monday before May 25
        if let victoria = mondayBefore(month: 5, day: 25, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Victoria Day", date: victoria, isNational: true, moodImpact: 0.3))
        }

        holidays.append(LocaleHoliday(name: "Canada Day", date: calendar.date(from: DateComponents(year: year, month: 7, day: 1))!, isNational: true, moodImpact: 0.6))

        // Labour Day - 1st Monday of September
        if let labour = nthWeekday(nth: 1, weekday: 2, month: 9, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Labour Day", date: labour, isNational: true, moodImpact: 0.3))
        }

        // Thanksgiving - 2nd Monday of October
        if let thanksgiving = nthWeekday(nth: 2, weekday: 2, month: 10, year: year, calendar: calendar) {
            holidays.append(LocaleHoliday(name: "Thanksgiving", date: thanksgiving, isNational: true, moodImpact: 0.5))
        }

        holidays.append(LocaleHoliday(name: "Christmas", date: calendar.date(from: DateComponents(year: year, month: 12, day: 25))!, isNational: true, moodImpact: 0.6))

        return holidays
    }

    // Helper: Get nth weekday of month (e.g., 3rd Monday)
    private static func nthWeekday(nth: Int, weekday: Int, month: Int, year: Int, calendar: Calendar) -> Date? {
        var components = DateComponents(year: year, month: month, weekday: weekday, weekdayOrdinal: nth)
        return calendar.date(from: components)
    }

    // Helper: Get last weekday of month
    private static func lastWeekday(weekday: Int, month: Int, year: Int, calendar: Calendar) -> Date? {
        var components = DateComponents(year: year, month: month)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return nil
        }

        // Start from last day and work backwards
        for day in range.reversed() {
            components.day = day
            if let date = calendar.date(from: components),
               calendar.component(.weekday, from: date) == weekday {
                return date
            }
        }
        return nil
    }

    // Helper: Monday before a specific date
    private static func mondayBefore(month: Int, day: Int, year: Int, calendar: Calendar) -> Date? {
        guard let targetDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }

        var date = targetDate
        var iterations = 0
        while calendar.component(.weekday, from: date) != 2 && iterations < 7 { // 2 = Monday, max 7 iterations
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                break
            }
            date = previousDay
            iterations += 1
        }
        return date
    }
}

struct ContextualFactors {
    let weather: WeatherData?
    let season: Season
    let timeOfYear: TimeOfYearContext
    let moonPhase: MoonPhase?
    let isHoliday: Bool
    let daysSinceHoliday: Int?
    let location: CLLocation?
}

struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double?
    let uvIndex: Double?
    let airQuality: Int?
    
    enum WeatherCondition: String, Codable {
        case sunny
        case partlyCloudy
        case cloudy
        case rainy
        case stormy
        case snowy
        case foggy
        
        var moodImpact: Double {
            switch self {
            case .sunny: return 0.8
            case .partlyCloudy: return 0.3
            case .cloudy: return -0.2
            case .rainy: return -0.5
            case .stormy: return -0.8
            case .snowy: return 0.2
            case .foggy: return -0.3
            }
        }
    }
}

enum Season: String {
    case spring, summer, fall, winter
    
    var moodImpact: Double {
        switch self {
        case .spring: return 0.5
        case .summer: return 0.7
        case .fall: return 0.0
        case .winter: return -0.4
        }
    }
    
    static func from(date: Date) -> Season {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        
        switch month {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .winter
        }
    }
}

enum MoonPhase: String {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent
    
    var moodImpact: Double {
        switch self {
        case .fullMoon: return -0.2
        case .newMoon: return 0.1
        default: return 0.0
        }
    }
    
    static func calculate(for date: Date) -> MoonPhase {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return .newMoon
        }
        
        var y = year
        var m = month
        
        if m < 3 {
            y -= 1
            m += 12
        }
        
        let a = y / 100
        let b = a / 4
        let c = 2 - a + b
        let e = Int(365.25 * Double(y + 4716))
        let f = Int(30.6001 * Double(m + 1))
        let jd = Double(c + day + e + f) - 1524.5
        
        let daysSinceNew = jd - 2451549.5
        let newMoons = daysSinceNew / 29.53
        let phase = (newMoons - floor(newMoons)) * 29.53
        
        switch phase {
        case 0..<1.84566: return .newMoon
        case 1.84566..<5.53699: return .waxingCrescent
        case 5.53699..<9.22831: return .firstQuarter
        case 9.22831..<12.91963: return .waxingGibbous
        case 12.91963..<16.61096: return .fullMoon
        case 16.61096..<20.30228: return .waningGibbous
        case 20.30228..<23.99361: return .lastQuarter
        default: return .waningCrescent
        }
    }
}

struct TimeOfYearContext {
    let daysUntilHoliday: Int?
    let holidayName: String?
    let isBackToSchoolSeason: Bool
    let isTaxSeason: Bool
    let isNewYearPeriod: Bool
    
    var moodImpact: Double {
        var impact = 0.0
        
        if let days = daysUntilHoliday {
            if days <= 7 {
                impact += 0.3
            }
        }
        
        if isNewYearPeriod {
            impact += 0.2
        }
        
        if isTaxSeason {
            impact -= 0.3
        }
        
        return impact
    }
}

@MainActor
class MoodPredictionService: ObservableObject {
    static let shared = MoodPredictionService()

    private let openWeatherService = OpenWeatherService.shared
    private let patternStore = PersonalPatternStore.shared
    private var cachedWeather: [Date: WeatherData] = [:]

    private init() {
        debugPrint("🔮 [MoodPrediction] Service initialized")
        debugPrint("🔮 [MoodPrediction] PatternStore has \(patternStore.patterns.count) patterns")
        debugPrint("🔮 [MoodPrediction] Occupation type: \(patternStore.occupationType.rawValue)")
    }
    
    /// Calculate confidence based on days in future (decays over time)
    func calculateConfidenceForDate(_ date: Date) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        let daysInFuture = calendar.dateComponents([.day], from: today, to: targetDay).day ?? 0
        
        // Past dates or today: high base confidence
        if daysInFuture <= 0 {
            return 0.85
        }
        
        // Confidence decay: exponential decay with distance
        // Day 1-3: 70-85%
        // Day 4-7: 40-60%
        // Day 8-14: 20-35%
        // Day 15+: <20%
        switch daysInFuture {
        case 1...3:
            return 0.85 - (Double(daysInFuture - 1) * 0.05) // 0.85, 0.80, 0.75
        case 4...7:
            return 0.60 - (Double(daysInFuture - 4) * 0.05) // 0.60, 0.55, 0.50, 0.45
        case 8...14:
            return 0.35 - (Double(daysInFuture - 8) * 0.02) // 0.35 -> 0.21
        default:
            return max(0.1, 0.20 - (Double(daysInFuture - 15) * 0.01)) // Minimum 0.1
        }
    }
    
    /// Returns whether a date should be shown as grayed out (low confidence)
    func shouldGrayOutDate(_ date: Date) -> Bool {
        return calculateConfidenceForDate(date) < 0.40
    }
    
    func predictMood(
        for date: Date,
        historicalEntries: [SupabaseJournalEntry],
        location: CLLocation? = nil
    ) async -> MoodPrediction {
        let contextualFactors = await gatherContextualFactors(for: date, location: location)

        let basePrediction = calculateBasePrediction(
            for: date,
            historicalEntries: historicalEntries
        )

        let adjustedPrediction = applyContextualAdjustments(
            basePrediction: basePrediction,
            factors: contextualFactors,
            historicalEntries: historicalEntries,
            targetDate: date
        )

        // Apply distance-based confidence decay
        let distanceConfidence = calculateConfidenceForDate(date)
        let finalConfidence = adjustedPrediction.confidence * distanceConfidence

        return MoodPrediction(
            date: date,
            predictedMood: adjustedPrediction.mood,
            confidence: finalConfidence,
            factors: adjustedPrediction.contributingFactors,
            basePrediction: basePrediction,
            contextualFactors: contextualFactors
        )
    }

    /// Enhanced prediction with comparative analytics
    func predictMoodWithInsights(
        for date: Date,
        historicalEntries: [SupabaseJournalEntry],
        location: CLLocation? = nil
    ) async -> MoodPrediction {
        // Get base prediction
        var prediction = await predictMood(for: date, historicalEntries: historicalEntries, location: location)

        // Enrich with PersonalMoodAnalytics
        let analytics = PersonalMoodAnalytics.shared
        let insight = await analytics.generateInsight(for: date, entries: historicalEntries, existingPrediction: prediction)

        // Update prediction with comparative data
        prediction.personalBaseline = insight.personalBaseline
        prediction.comparativeScore = insight.comparativeScore
        prediction.weekdayAverage = insight.weekdayAverage
        prediction.weekdayRank = insight.weekdayRank
        prediction.primaryInsight = insight.primaryInsight
        prediction.trend = insight.trend
        prediction.trendStrength = insight.trendStrength

        let volatilityScore = calculateVolatilityScore(
            historicalEntries: historicalEntries,
            targetDate: date
        )
        let stabilityScore = max(0.0, min(1.0, 1.0 - volatilityScore))

        prediction.volatilityScore = volatilityScore
        prediction.stabilityScore = stabilityScore
        prediction.confidenceBand = buildConfidenceBand(
            predictedMood: prediction.predictedMood,
            confidence: prediction.confidence,
            volatilityScore: volatilityScore
        )

        let outlook = determineMicroOutlook(
            for: prediction,
            stabilityScore: stabilityScore,
            volatilityScore: volatilityScore
        )
        prediction.microOutlook = outlook
        prediction.supportSuggestion = buildSupportSuggestion(
            for: prediction,
            outlook: outlook
        )

        return prediction
    }

    private func gatherContextualFactors(
        for date: Date,
        location: CLLocation?
    ) async -> ContextualFactors {
        let season = Season.from(date: date)
        let moonPhase = MoonPhase.calculate(for: date)
        let timeOfYear = analyzeTimeOfYear(date: date)
        
        let weather = await fetchWeather(for: date, location: location)
        
        return ContextualFactors(
            weather: weather,
            season: season,
            timeOfYear: timeOfYear,
            moonPhase: moonPhase,
            isHoliday: isHoliday(date),
            daysSinceHoliday: daysSinceLastHoliday(date),
            location: location
        )
    }
    
    private func fetchWeather(
        for date: Date,
        location: CLLocation?
    ) async -> WeatherData? {
        if let cached = cachedWeather[date] {
            return cached
        }

        // Only use real weather data - simulated weather adds noise, not signal
        guard let location = location else {
            return nil
        }

        do {
            let response = try await openWeatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                date: date
            )

            let weatherData = openWeatherService.convertToWeatherData(response, for: date)
            cachedWeather[date] = weatherData

            return weatherData
        } catch {
            debugPrint("Failed to fetch weather data: \(error.localizedDescription)")
            return nil // No weather data is better than random weather data
        }
    }
    
    private func calculateBasePrediction(
        for targetDate: Date,
        historicalEntries: [SupabaseJournalEntry]
    ) -> Double {
        let calendar = Calendar.current
        let targetWeekday = calendar.component(.weekday, from: targetDate)

        // Default base prediction of 6.0 (Balanced) with weekday variation
        if historicalEntries.isEmpty {
            return 6.0 + defaultWeekdayVariation(for: targetWeekday)
        }

        let entriesBeforeTarget = historicalEntries.filter { $0.createdAt < targetDate }

        if entriesBeforeTarget.isEmpty {
            return 6.0 + defaultWeekdayVariation(for: targetWeekday)
        }

        // Only use entries with mood data
        let entriesWithMood = entriesBeforeTarget.filter { $0.mood != nil }

        if entriesWithMood.isEmpty {
            return 6.0 + defaultWeekdayVariation(for: targetWeekday)
        }

        // Get same-weekday entries with recency weighting (last 8 weeks max)
        let eightWeeksAgo = calendar.date(byAdding: .day, value: -56, to: targetDate) ?? targetDate
        let sameDayEntries = entriesWithMood
            .filter {
                calendar.component(.weekday, from: $0.createdAt) == targetWeekday &&
                $0.createdAt >= eightWeeksAgo
            }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(6) // Max 6 same-weekday samples

        // Get recent trend (last 7 days, excluding same-weekday to avoid double count)
        let last7DaysEntries = entriesWithMood.filter {
            let daysDiff = calendar.dateComponents([.day], from: $0.createdAt, to: targetDate).day ?? 0
            let isSameWeekday = calendar.component(.weekday, from: $0.createdAt) == targetWeekday
            return daysDiff >= 0 && daysDiff <= 7 && !isSameWeekday
        }

        // Get overall baseline (last 30 days)
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: targetDate) ?? targetDate
        let baselineEntries = entriesWithMood.filter { $0.createdAt >= thirtyDaysAgo }

        var weightedScores: [(score: Double, weight: Double, source: String)] = []

        // SAME WEEKDAY: Apply recency-weighted average
        // Weight decays: most recent = 1.0, 2nd = 0.8, 3rd = 0.6, etc.
        if !sameDayEntries.isEmpty {
            var weightedSum = 0.0
            var totalWeight = 0.0
            for (index, entry) in sameDayEntries.enumerated() {
                let recencyWeight = max(0.3, 1.0 - Double(index) * 0.15)
                if let mood = entry.mood {
                    weightedSum += Double(mood) * recencyWeight
                    totalWeight += recencyWeight
                }
            }
            if totalWeight > 0 {
                let recencyWeightedAvg = weightedSum / totalWeight
                // Reduce weekday weight if we have few samples
                let sampleConfidence = min(1.0, Double(sameDayEntries.count) / 3.0)
                let weekdayWeight = 0.55 * sampleConfidence
                weightedScores.append((recencyWeightedAvg, weekdayWeight, "Same weekday"))
            }
        }

        // RECENT TREND: Last 7 days (excluding same weekday)
        if !last7DaysEntries.isEmpty {
            let trendMoods = last7DaysEntries.compactMap { $0.mood }
            if !trendMoods.isEmpty {
                let trendAvg = Double(trendMoods.reduce(0, +)) / Double(trendMoods.count)
                weightedScores.append((trendAvg, 0.30, "Recent trend"))
            }
        }

        // OVERALL BASELINE: Stabilizing anchor
        if !baselineEntries.isEmpty {
            let baselineMoods = baselineEntries.compactMap { $0.mood }
            if !baselineMoods.isEmpty {
                let baselineAvg = Double(baselineMoods.reduce(0, +)) / Double(baselineMoods.count)
                weightedScores.append((baselineAvg, 0.15, "Baseline"))
            }
        }

        // Fallback if no weighted scores
        if weightedScores.isEmpty {
            let allMoods = entriesWithMood.compactMap { $0.mood }
            return allMoods.isEmpty ? 6.0 : Double(allMoods.reduce(0, +)) / Double(allMoods.count)
        }

        let totalWeight = weightedScores.reduce(0.0) { $0 + $1.weight }
        let weightedSum = weightedScores.reduce(0.0) { $0 + ($1.score * $1.weight) }
        return weightedSum / totalWeight
    }

    private func defaultWeekdayVariation(for weekday: Int) -> Double {
        switch weekday {
        case 1: return 0.3   // Sunday
        case 2: return -0.5  // Monday
        case 3: return -0.2  // Tuesday
        case 4: return 0.0   // Wednesday
        case 5: return 0.2   // Thursday
        case 6: return 0.6   // Friday
        case 7: return 0.4   // Saturday
        default: return 0.0
        }
    }
    
    private func applyContextualAdjustments(
        basePrediction: Double,
        factors: ContextualFactors,
        historicalEntries: [SupabaseJournalEntry],
        targetDate: Date
    ) -> (mood: Double, confidence: Double, contributingFactors: [PredictionFactor]) {

        var adjustedMood = basePrediction
        var contributingFactors: [PredictionFactor] = []
        var confidence = 0.7

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: targetDate)
        let dayName = calendar.weekdaySymbols[weekday - 1]

        // ADAPTIVE WEIGHTS: More data = trust personal history more, less data = use general patterns
        // personalWeight: 0.0 (no data) -> 1.0 (20+ entries)
        // generalWeight: 1.0 (no data) -> 0.0 (20+ entries)
        let entryCount = Double(historicalEntries.count)
        let personalWeight = min(1.0, entryCount / 20.0)
        let generalWeight = 1.0 - personalWeight

        // === GENERAL PATTERNS (only applied when we have very little personal data) ===
        // When we have personal data, the base prediction already incorporates weekday patterns
        // from the user's actual history, so we don't need to add general population patterns

        // Only apply general patterns if we have < 7 entries (not enough for reliable weekday averages)
        if historicalEntries.count < 7 {
            // Seasonal impact (winter tends to be lower for most people)
            let seasonalAdjustment = factors.season.moodImpact * 0.3 * generalWeight
            if abs(seasonalAdjustment) > 0.05 {
                adjustedMood += seasonalAdjustment
                contributingFactors.append(PredictionFactor(
                    name: "Seasonal",
                    impact: seasonalAdjustment,
                    description: "General \(factors.season.rawValue) mood pattern",
                    confidence: 0.5
                ))
            }

            // General weekday patterns (Mondays harder, weekends better - for most people)
            // Only use when no personal weekday data available
            let generalWeekdayImpact: Double
            switch weekday {
            case 1: generalWeekdayImpact = 0.4   // Sunday - relaxation
            case 2: generalWeekdayImpact = -0.6  // Monday - hardest day
            case 3: generalWeekdayImpact = -0.2  // Tuesday
            case 4: generalWeekdayImpact = 0.0   // Wednesday - neutral
            case 5: generalWeekdayImpact = 0.1   // Thursday
            case 6: generalWeekdayImpact = 0.5   // Friday - weekend anticipation
            case 7: generalWeekdayImpact = 0.4   // Saturday
            default: generalWeekdayImpact = 0.0
            }
            let weekdayAdjustment = generalWeekdayImpact * generalWeight
            if abs(weekdayAdjustment) > 0.05 {
                adjustedMood += weekdayAdjustment
                contributingFactors.append(PredictionFactor(
                    name: "Day of Week",
                    impact: weekdayAdjustment,
                    description: "\(dayName)s are typically \(generalWeekdayImpact > 0 ? "better" : "harder")",
                    confidence: 0.4
                ))
            }
        }

        // Holiday proximity boost (light impact, applies broadly)
        if factors.isHoliday || (factors.timeOfYear.daysUntilHoliday ?? 100) < 3 {
            let holidayBoost = 0.3 * generalWeight
            if holidayBoost > 0.05 {
                adjustedMood += holidayBoost
                if let holidayName = factors.timeOfYear.holidayName {
                    contributingFactors.append(PredictionFactor(
                        name: "Holiday",
                        impact: holidayBoost,
                        description: "Near \(holidayName)",
                        confidence: 0.6
                    ))
                }
            }
        }

        // === PERSONAL PATTERNS (applied more when more personal data) ===

        // Personal significant dates (birthdays, anniversaries)
        let personalDatePatterns = patternStore.getPatternsAffecting(date: targetDate)
        for pattern in personalDatePatterns {
            if pattern.patternType == .significantDate {
                let impact = pattern.moodImpact * personalWeight
                adjustedMood += impact
                contributingFactors.append(PredictionFactor(
                    name: "Personal Date",
                    impact: impact,
                    description: pattern.description,
                    confidence: pattern.confidence
                ))
            }
        }

        // Personal occupation-based pattern
        // Only apply when we have some data but not enough for reliable weekday patterns
        // Once we have 10+ entries, the actual historical weekday data is more accurate
        let occupationType = patternStore.occupationType
        if occupationType != .unknown && historicalEntries.count >= 3 && historicalEntries.count < 10 {
            let occupationImpact = occupationType.moodImpactForWeekday(weekday) * 0.3
            if abs(occupationImpact) > 0.1 {
                adjustedMood += occupationImpact
                contributingFactors.append(PredictionFactor(
                    name: "Your Pattern",
                    impact: occupationImpact,
                    description: occupationImpact > 0
                        ? "\(dayName)s tend to be better for you"
                        : "\(dayName)s can be challenging for you",
                    confidence: 0.5
                ))
            }
        }

        // Confidence scales with data amount
        if historicalEntries.count < 5 {
            confidence = 0.3
        } else if historicalEntries.count < 10 {
            confidence = 0.5
        } else if historicalEntries.count < 20 {
            confidence = 0.65
        } else {
            confidence = 0.8
        }

        // Clamp to valid range
        adjustedMood = max(2.0, min(10.0, adjustedMood))

        return (adjustedMood, confidence, contributingFactors)
    }
    
    // NEW: Analyze personal patterns from journal history
    private func analyzePersonalPatterns(
        historicalEntries: [SupabaseJournalEntry],
        targetDate: Date
    ) -> [PredictionFactor] {
        var patterns: [PredictionFactor] = []
        let calendar = Calendar.current
        
        // Recent mood trend
        let recentEntries = historicalEntries
            .filter { calendar.dateComponents([.day], from: $0.createdAt, to: targetDate).day ?? 100 <= 7 }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
        
        if !recentEntries.isEmpty {
            let recentMoods = recentEntries.compactMap { $0.mood }
            if recentMoods.count >= 2 {
                let avgMood = Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
                let trend = avgMood - 6.0 // Difference from neutral
                let impact = trend * 0.4
                
                let trendDescription = trend > 0.5 ? "You've been feeling more positive lately" :
                                      trend < -0.5 ? "You've had some challenging days recently" :
                                      "Your mood has been relatively stable"
                
                patterns.append(PredictionFactor(
                    name: "Recent Trend",
                    impact: impact,
                    description: trendDescription,
                    confidence: 0.75
                ))
            }
        }
        
        // Journaling consistency impact
        let entriesLast7Days = historicalEntries
            .filter { calendar.dateComponents([.day], from: $0.createdAt, to: targetDate).day ?? 100 <= 7 }
        
        if entriesLast7Days.count >= 3 {
            patterns.append(PredictionFactor(
                name: "Reflection Habit",
                impact: 0.6,
                description: "Your consistent journaling supports your wellbeing",
                confidence: 0.8
            ))
        } else if entriesLast7Days.count == 0 && historicalEntries.count > 5 {
            patterns.append(PredictionFactor(
                name: "Reflection Gap",
                impact: -0.4,
                description: "It's been a while since your last reflection",
                confidence: 0.6
            ))
        }
        
        // Entry length/depth pattern
        let recentDepth = recentEntries.map { $0.content.count }
        if !recentDepth.isEmpty {
            let avgDepth = recentDepth.reduce(0, +) / recentDepth.count
            if avgDepth > 200 {
                patterns.append(PredictionFactor(
                    name: "Thoughtful Processing",
                    impact: 0.5,
                    description: "Your detailed reflections show deep self-awareness",
                    confidence: 0.7
                ))
            }
        }
        
        return patterns
    }

    private func calculateVolatilityScore(
        historicalEntries: [SupabaseJournalEntry],
        targetDate: Date
    ) -> Double {
        let calendar = Calendar.current
        let recentMoods = historicalEntries
            .filter {
                let days = calendar.dateComponents([.day], from: $0.createdAt, to: targetDate).day ?? 999
                return days >= 0 && days <= 14
            }
            .compactMap { entry -> Double? in
                guard let mood = entry.mood else { return nil }
                return Double(mood)
            }

        guard recentMoods.count >= 3 else {
            return 0.45
        }

        let mean = recentMoods.reduce(0.0, +) / Double(recentMoods.count)
        let variance = recentMoods.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(recentMoods.count)
        let standardDeviation = sqrt(variance)

        // Normalize using 0-2.0 std window (typical for 1-10 scale moods)
        return min(1.0, max(0.0, standardDeviation / 2.0))
    }

    private func buildConfidenceBand(
        predictedMood: Double,
        confidence: Double,
        volatilityScore: Double
    ) -> MoodConfidenceBand {
        let baseSpread = (1.0 - confidence) * 1.4
        let volatilitySpread = volatilityScore * 1.2
        let spread = max(0.4, baseSpread + volatilitySpread)
        let lower = max(2.0, predictedMood - spread)
        let upper = min(10.0, predictedMood + spread)
        return MoodConfidenceBand(lower: lower, upper: upper)
    }

    private func determineMicroOutlook(
        for prediction: MoodPrediction,
        stabilityScore: Double,
        volatilityScore: Double
    ) -> MoodMicroOutlook {
        let comparative = prediction.comparativeScore ?? 0.0
        let trendStrength = prediction.trendStrength ?? 0
        let stateName = prediction.moodState.rawValue

        var direction: MoodTrajectoryDirection = .steady
        var headline = "Steady \(stateName)"
        var summary = stabilityScore > 0.6
            ? "Recent days have hovered in a healthy range. Keep leaning on what works."
            : "You're holding steady, but there is some wobble—keep routines gentle."
        var icon = "waveform.path.ecg"

        if let trend = prediction.trend, trendStrength >= 3 {
            switch trend {
            case .improving:
                direction = .rising
                headline = "Lifting \(stateName)"
                summary = "Momentum has been improving for \(trendStrength) days."
                icon = "arrow.up.right.circle.fill"
            case .declining:
                direction = .easing
                headline = "Softening \(stateName)"
                summary = "Energy has dipped for \(trendStrength) days—plan lighter touchpoints."
                icon = "arrow.down.right.circle.fill"
            case .stable:
                direction = .steady
                headline = "Even \(stateName)"
                summary = "Patterns are remarkably steady—keep your anchors nearby."
                icon = "arrow.right.circle.fill"
            }
        } else if abs(comparative) >= 0.4 {
            if comparative > 0 {
                direction = .rising
                headline = "Above your usual"
                summary = String(format: "Tracking %.1f above baseline. Capture what feels helpful.", comparative)
                icon = "plus.circle.fill"
            } else {
                direction = .easing
                headline = "Below your typical"
                summary = String(format: "Running %.1f below baseline. Build in softness tomorrow.", abs(comparative))
                icon = "minus.circle.fill"
            }
        } else if volatilityScore > 0.55 {
            direction = .volatile
            headline = "Keep anchors nearby"
            summary = "Mood has been oscillating this week—ground yourself with predictable rituals."
            icon = "wave.3.forward.circle.fill"
        }

        return MoodMicroOutlook(
            direction: direction,
            headline: headline,
            summary: summary,
            icon: icon
        )
    }

    private func buildSupportSuggestion(
        for prediction: MoodPrediction,
        outlook: MoodMicroOutlook
    ) -> MoodSupportSuggestion {
        switch outlook.direction {
        case .rising:
            return MoodSupportSuggestion(
                title: "Double down on what works",
                detail: "Protect the routines that sparked this lift—especially your first 10 minutes in the morning.",
                icon: "sparkles"
            )
        case .steady:
            return MoodSupportSuggestion(
                title: "Stay consistent",
                detail: "Keep the daily cadence: short check-ins + breath resets to maintain the steady state.",
                icon: "line.horizontal.3.decrease.circle"
            )
        case .easing:
            return MoodSupportSuggestion(
                title: "Pre-plan support",
                detail: "Schedule a gentle ritual before the time of day that usually dips to soften the landing.",
                icon: "hands.sparkles.fill"
            )
        case .volatile:
            return MoodSupportSuggestion(
                title: "Create buffers",
                detail: "Keep recovery snacks ready: 2-min breaths, light movement, and one person to text.",
                icon: "shield.lefthalf.fill"
            )
        }
    }
    
    private func analyzeWeatherCorrelation(
        weather: WeatherData,
        historicalEntries: [SupabaseJournalEntry]
    ) -> Double {
        return 0.7
    }
    
    private func analyzeTimeOfYear(date: Date) -> TimeOfYearContext {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let holidays = getUpcomingHolidays(from: date)
        let nextHoliday = holidays.first
        
        let daysUntilHoliday: Int? = nextHoliday.flatMap { holiday in
            calendar.dateComponents([.day], from: date, to: holiday.date).day
        }
        
        let isBackToSchoolSeason = month == 8 || month == 9
        let isTaxSeason = month >= 3 && month <= 4 && day <= 15
        let isNewYearPeriod = (month == 12 && day >= 20) || (month == 1 && day <= 15)
        
        return TimeOfYearContext(
            daysUntilHoliday: daysUntilHoliday,
            holidayName: nextHoliday?.name,
            isBackToSchoolSeason: isBackToSchoolSeason,
            isTaxSeason: isTaxSeason,
            isNewYearPeriod: isNewYearPeriod
        )
    }
    
    private func isHoliday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        let holidays: [(month: Int, day: Int)] = [
            (1, 1),
            (2, 14),
            (7, 4),
            (10, 31),
            (12, 25),
            (12, 31)
        ]
        
        return holidays.contains { $0.month == month && $0.day == day }
    }
    
    private func daysSinceLastHoliday(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let pastHolidays = getUpcomingHolidays(from: date.addingTimeInterval(-90 * 24 * 60 * 60))
            .filter { $0.date < date }
        
        guard let lastHoliday = pastHolidays.last else { return nil }
        
        return calendar.dateComponents([.day], from: lastHoliday.date, to: date).day
    }
    
    private func getUpcomingHolidays(from date: Date) -> [(name: String, date: Date)] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        
        let holidays: [(name: String, month: Int, day: Int)] = [
            ("New Year's Day", 1, 1),
            ("Valentine's Day", 2, 14),
            ("Independence Day", 7, 4),
            ("Halloween", 10, 31),
            ("Thanksgiving", 11, 24),
            ("Christmas", 12, 25),
            ("New Year's Eve", 12, 31)
        ]
        
        return holidays.compactMap { holiday in
            var components = DateComponents()
            components.year = year
            components.month = holiday.month
            components.day = holiday.day
            
            if let holidayDate = calendar.date(from: components), holidayDate >= date {
                return (holiday.name, holidayDate)
            } else if let nextYearDate = calendar.date(from: DateComponents(year: year + 1, month: holiday.month, day: holiday.day)), nextYearDate >= date {
                return (holiday.name, nextYearDate)
            }
            return nil
        }.sorted { $0.date < $1.date }
    }
}

// Mood state categories for better user experience
enum MoodState: String {
    case radiant = "Radiant"
    case positive = "Positive"
    case balanced = "Balanced"
    case low = "Low"
    case challenging = "Challenging"

    var color: Color {
        switch self {
        case .radiant: return Color(hex: "FF5C7A")
        case .positive: return Color(hex: "FF8FA3")
        case .balanced: return Color(hex: "B87FA3")
        case .low: return Color(hex: "A34865")
        case .challenging: return Color(hex: "8A3855")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .radiant: return [Color(hex: "FF5C7A"), Color(hex: "FF8FA3")]
        case .positive: return [Color(hex: "FF8FA3"), Color(hex: "FFB0BE")]
        case .balanced: return [Color(hex: "B87FA3"), Color(hex: "D4A5C3")]
        case .low: return [Color(hex: "A34865"), Color(hex: "B87FA3")]
        case .challenging: return [Color(hex: "8A3855"), Color(hex: "A34865")]
        }
    }

    static func from(mood: Double) -> MoodState {
        switch mood {
        case 8.5...10.0: return .radiant
        case 7.0..<8.5: return .positive
        case 5.5..<7.0: return .balanced
        case 4.0..<5.5: return .low
        default: return .challenging
        }
    }
}

struct MoodPrediction {
    let date: Date
    let predictedMood: Double
    let confidence: Double
    let factors: [PredictionFactor]
    let basePrediction: Double
    let contextualFactors: ContextualFactors

    // NEW: Comparative data from PersonalMoodAnalytics
    var personalBaseline: Double?
    var comparativeScore: Double?
    var weekdayAverage: Double?
    var weekdayRank: Int?
    var primaryInsight: String?
    var trend: MoodTrendDirection?
    var trendStrength: Int?
    var stabilityScore: Double?
    var volatilityScore: Double?
    var confidenceBand: MoodConfidenceBand?
    var microOutlook: MoodMicroOutlook?
    var supportSuggestion: MoodSupportSuggestion?

    var moodState: MoodState {
        return MoodState.from(mood: predictedMood)
    }

    var confidenceDescription: String {
        switch confidence {
        case 0.8...:
            return "High confidence"
        case 0.6..<0.8:
            return "Medium confidence"
        default:
            return "Low confidence"
        }
    }

    /// Comparative description (e.g., "+0.8 above your average")
    var comparativeDescription: String? {
        guard let score = comparativeScore else { return nil }
        let absScore = abs(score)

        if absScore < 0.3 {
            return "Near your typical range"
        } else if score > 0 {
            return String(format: "+%.1f above average", absScore)
        } else {
            return String(format: "%.1f below average", absScore)
        }
    }

    /// Short comparative for calendar display (e.g., "+0.8")
    var shortComparative: String? {
        guard let score = comparativeScore else { return nil }

        if abs(score) < 0.3 {
            return nil // Don't show for near-baseline
        } else if score > 0 {
            return String(format: "+%.1f", score)
        } else {
            return String(format: "%.1f", score)
        }
    }

    /// Visual state for UI rendering
    var visualState: MoodVisualState {
        guard let score = comparativeScore else {
            return .nearBaseline
        }
        return MoodVisualState.from(comparativeScore: score)
    }
}

struct MoodConfidenceBand {
    let lower: Double
    let upper: Double

    var spread: Double {
        upper - lower
    }
}

enum MoodTrajectoryDirection {
    case rising
    case steady
    case easing
    case volatile
}

struct MoodMicroOutlook {
    let direction: MoodTrajectoryDirection
    let headline: String
    let summary: String
    let icon: String
}

struct MoodSupportSuggestion {
    let title: String
    let detail: String
    let icon: String
}

struct PredictionFactor: Identifiable {
    let id = UUID()
    let name: String
    let impact: Double
    let description: String
    let confidence: Double
    
    var impactDescription: String {
        let absImpact = abs(impact)
        let direction = impact > 0 ? "positive" : "negative"
        
        switch absImpact {
        case 0.5...:
            return "Strong \(direction) impact"
        case 0.2..<0.5:
            return "Moderate \(direction) impact"
        default:
            return "Slight \(direction) impact"
        }
    }
    
    var impactColor: Color {
        if abs(impact) < 0.1 {
            return AdaptiveColors.Text.secondary
        }
        return impact > 0 ? OnboardingColors.wellnessGreen : OnboardingColors.wellnessOrange
    }
}
