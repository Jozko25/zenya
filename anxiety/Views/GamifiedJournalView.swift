//
//  GamifiedJournalView.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import SwiftUI

// MARK: - Dark Theme Palette

private enum FeelPalette {
    // Primary accent - warm coral
    static let accent = Color(hex: "FF6B6B")
    static let accentSoft = Color(hex: "FF8A8A")
    static let accentDeep = Color(hex: "E85555")

    // Dark theme backgrounds
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color(hex: "F7F8FB")
    }

    static func elevatedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    static func modalBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color(hex: "F7F8FB")
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "0A0A0A") : Color.white
    }

    static func modalSurface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "141414") : Color(hex: "FDFDFE")
    }

    static func surfaceSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F1F2F6")
    }

    static func stroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E2E5EE")
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(hex: "1A1C23")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.55) : Color(hex: "4F5560")
    }

    static func tertiaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color(hex: "9AA0AE")
    }

    static func mutedText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color(hex: "9AA0AE")
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "E5E8F0")
    }

    static func fill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "E8EAF2")
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white
    }

    static func shadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color(hex: "FF6B6B").opacity(0.18)
    }
}

// MARK: - Clean Card Styling (Apple HIG)

private struct CleanCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FeelPalette.modalSurface(for: colorScheme))
            )
    }
}

private struct FillCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FeelPalette.fill(for: colorScheme))
            )
    }
}

private extension View {
    // Keeping old names for backwards compatibility but with cleaner implementation
    func modalGlassShape<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        self.background(
            shape.fill(tint?.opacity(0.12) ?? FeelPalette.fill(for: .dark))
        )
    }

    func modalGlassCard(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        self.modifier(CleanCardModifier(cornerRadius: cornerRadius))
    }

    func fillCard(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(FillCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Mood Calendar View

    struct MoodCalendarView: View {
        @State private var selectedDate = Date()
        @State private var currentMonth = Date()
        @State private var showingDayDetail = false
        @State private var selectedDetent: PresentationDetent = .height(340)
        @StateObject private var databaseService = DatabaseService.shared
        @StateObject private var analysisService = JournalAnalysisService.shared
        @State private var moodDataForDate: [SupabaseMoodEntry] = []
        @State private var journalDataForDate: [SupabaseJournalEntry] = []
        @State private var allJournalEntries: [SupabaseJournalEntry] = []
        @State private var dayPredictions: [Date: MoodPrediction] = [:]
        @State private var isLoadingCalendarPredictions = false
        @Environment(\.colorScheme) var colorScheme

        private var calendar: Calendar {
            var cal = Calendar.current
            cal.firstWeekday = 1 // Sunday = 1, ensures grid aligns with S,M,T,W,T,F,S headers
            return cal
        }
        private let dateFormatter = DateFormatter()

        var body: some View {
            VStack(spacing: 20) {
                // Month header - enhanced
                HStack {
                    Button(action: previousMonth) {
                        Circle()
                            .fill(FeelPalette.accent.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FeelPalette.accent)
                            )
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text(monthYearString)
                            .font(.instrumentSerif(size: 22))
                            .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                    }

                    Spacer()

                    Button(action: nextMonth) {
                        Circle()
                            .fill(FeelPalette.accent.opacity(0.1))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(FeelPalette.accent)
                            )
                    }
                }
                .padding(.horizontal, 16)

                // Days of week header - refined
                HStack(spacing: 0) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.quicksand(size: 13, weight: .semibold))
                            .foregroundColor(FeelPalette.mutedText(for: colorScheme))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

                // Calendar grid - better spacing
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(calendarDays, id: \.self) { date in
                        CalendarDayView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                            moodForDay: getMoodForDate(date),
                            prediction: predictionForDay(date)
                        ) {
                            selectedDate = date
                            openDayDetail(for: date)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(FeelPalette.surface(for: colorScheme))
                    .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(FeelPalette.stroke(for: colorScheme), lineWidth: 1)
            )
           .sheet(isPresented: $showingDayDetail) {
                DayMoodDetailView(
                   date: selectedDate,
                   moodEntries: moodDataForDate,
                   journalEntries: journalDataForDate
                )
                .id(selectedDate)
                .presentationDetents([.height(340), .large], selection: $selectedDetent)
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(32)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .interactiveDismissDisabled(false)
            }
           .onChange(of: selectedDate) { _ in
               // Keep sheet at compact height when switching days
               selectedDetent = .height(340)
          }
          .onAppear {
              loadAllJournalEntries()
              // Also ensure analyses are loaded for predictions
              Task {
                  await analysisService.loadEvaluations()
              }
              refreshMonthPredictions()
          }
          .onChange(of: currentMonth) { _ in
              refreshMonthPredictions()
          }
          .onChange(of: analysisService.analyses.count) { newCount in
              // Refresh predictions when analyses are loaded
              if newCount > 0 {
                  refreshMonthPredictions()
              }
          }
    }
    
    private func loadAllJournalEntries() {
        guard let userId = databaseService.currentUser?.id else { return }
        
        Task {
            do {
                let entries = try await databaseService.getJournalEntries(userId: userId, limit: 1000)
                await MainActor.run {
                    allJournalEntries = entries
                    // Preload first day's data if sheet opens immediately
                    if showingDayDetail {
                        journalDataForDate = journalsForDay(for: selectedDate)
                    }
                    refreshMonthPredictions()
                }
            } catch {
                debugPrint("Failed to load journal entries: \(error)")
            }
        }
    }
    
    private func journalsForDay(for date: Date) -> [SupabaseJournalEntry] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        return allJournalEntries.filter { entry in
            entry.createdAt >= startOfDay && entry.createdAt < endOfDay
        }
    }
    
    private func refreshMonthPredictions() {
        if isLoadingCalendarPredictions { return }

        let dates = calendarDays.map { calendar.startOfDay(for: $0) }

        // Combine journal entries with evaluations/analyses for better prediction data
        var combinedEntries = allJournalEntries.filter { $0.mood != nil }

        // Convert analyses (evaluations) to pseudo-entries for prediction
        let analysisEntries = analysisService.analyses.compactMap { analysis -> SupabaseJournalEntry? in
            let analysisDay = calendar.startOfDay(for: analysis.date)
            let hasEntry = combinedEntries.contains { calendar.startOfDay(for: $0.createdAt) == analysisDay }
            if hasEntry { return nil }

            return SupabaseJournalEntry(
                id: analysis.id,
                userId: UUID(uuidString: analysis.userId) ?? UUID(),
                createdAt: analysis.date,
                updatedAt: analysis.date,
                title: "Evaluation",
                content: analysis.summary,
                mood: analysis.maturityScore,
                gratitudeItems: nil,
                tags: analysis.emotionalThemes,
                isPrivate: true
            )
        }

        combinedEntries.append(contentsOf: analysisEntries)

        guard !dates.isEmpty, !combinedEntries.isEmpty else { return }

        isLoadingCalendarPredictions = true

        Task {
            var newPredictions: [Date: MoodPrediction] = [:]
            await withTaskGroup(of: (Date, MoodPrediction).self) { group in
                for date in dates {
                    group.addTask {
                        let prediction = await MoodPredictionService.shared.predictMoodWithInsights(
                            for: date,
                            historicalEntries: combinedEntries,
                            location: nil
                        )
                        return (date, prediction)
                    }
                }

                for await (date, prediction) in group {
                    newPredictions[date] = prediction
                }
            }

            await MainActor.run {
                dayPredictions = newPredictions
                isLoadingCalendarPredictions = false

                // Debug: Print predictions for future dates grouped by weekday
                let today = calendar.startOfDay(for: Date())
                let futurePredictions = newPredictions.filter { $0.key > today }
                    .sorted { $0.key < $1.key }
                    .prefix(7)

                if !futurePredictions.isEmpty {
                    debugPrint("🔮 === MOOD PREDICTIONS (next 7 days) ===")
                    for (date, prediction) in futurePredictions {
                        let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
                        let dateStr = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
                        debugPrint("🔮 \(weekday) \(dateStr): predicted=\(String(format: "%.2f", prediction.predictedMood)), base=\(String(format: "%.2f", prediction.basePrediction))")
                    }
                    debugPrint("🔮 ======================================")
                }
            }
        }
    }
    
    private func getMoodForDate(_ date: Date) -> Double? {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let entriesForDay = allJournalEntries.filter { entry in
            entry.createdAt >= startOfDay && entry.createdAt < endOfDay
        }
        
        let moods = entriesForDay.compactMap { $0.mood }
        guard !moods.isEmpty else { return nil }
        
        return Double(moods.reduce(0, +)) / Double(moods.count)
    }
    
    private func predictionForDay(_ date: Date) -> MoodPrediction? {
        let dayStart = calendar.startOfDay(for: date)
        return dayPredictions[dayStart]
    }
    
      private func openDayDetail(for date: Date) {
          let startOfDay = calendar.startOfDay(for: date)
          let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
  
          let journalsForDay = allJournalEntries.filter { entry in
              entry.createdAt >= startOfDay && entry.createdAt < endOfDay
          }
  
          // Update sheet content in-place and keep detent at compact height
          selectedDetent = .height(340)
          journalDataForDate = journalsForDay
          showingDayDetail = true
      }
    
    private var monthYearString: String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: currentMonth)
    }
    
    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let moodForDay: Double?
    let prediction: MoodPrediction?
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private let calendar = Calendar.current
    private let predictionService = MoodPredictionService.shared

    private var isFutureDate: Bool {
        date > Date()
    }

    private var predictionConfidence: Double {
        if let prediction = prediction {
            return prediction.confidence
        }
        return predictionService.calculateConfidenceForDate(date)
    }

    private var shouldGrayOut: Bool {
        isFutureDate && predictionConfidence < 0.40
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 40, height: 40)

                    // Selected ring
                    if isSelected {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }

                    // Today ring (when not selected)
                    if isToday && !isSelected {
                        Circle()
                            .stroke(FeelPalette.accent.opacity(0.5), lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }

                    Text(dayNumber)
                        .font(.quicksand(size: 16, weight: isToday || isSelected ? .bold : .medium))
                        .foregroundColor(textColor)
                }

                // Mood indicator dot
                Circle()
                    .fill(moodColor)
                    .frame(width: 5, height: 5)
                    .opacity(dotOpacity)
            }
            .frame(width: 44, height: 52)
            .opacity(shouldGrayOut ? 0.35 : (isCurrentMonth ? 1.0 : 0.4))
        }
        .buttonStyle(.plain)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dotOpacity: Double {
        // Always show color; scale only slightly by confidence but never disappear
        if isFutureDate {
            return 0.9
        }
        return 1.0
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(hex: "FF5C7A")
        } else if isCurrentMonth {
            if colorScheme == .dark {
                let base = predictionConfidence
                return .white.opacity(max(0.35, min(1.0, base + 0.35)))
            } else {
                // Light mode - use dark text with varying opacity based on confidence
                let base = predictionConfidence
                return Color(hex: "1A1A1A").opacity(max(0.5, min(1.0, base + 0.35)))
            }
        } else {
            return colorScheme == .dark ? .white.opacity(0.3) : Color(hex: "1A1A1A").opacity(0.3)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "FF5C7A")
        } else if isToday {
            return Color(hex: "FF5C7A").opacity(0.24)
        } else {
            // No colored background for predictions - only use the dot indicator
            return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
        }
    }
    
    private var moodColor: Color {
        if let prediction = prediction {
            return moodGradientColor(for: prediction.predictedMood)
                .opacity(1.0)
        }
        
        if let mood = moodForDay {
            return moodGradientColor(for: mood).opacity(0.95)
        }
        
        if isFutureDate {
            return moodGradientColor(for: 6.0).opacity(predictionConfidence)
        }
        
        return Color.white.opacity(0.16)
    }
    
    private func moodGradientColor(for mood: Double) -> Color {
        let clamped = max(1.0, min(10.0, mood))

        // More intuitive color mapping:
        // 1-4: Red/orange (struggling)
        // 4-6: Amber/yellow (neutral)
        // 6-8: Yellow-green (good)
        // 8-10: Green (great)
        switch clamped {
        case 8.0...:
            // Great - vibrant green
            return Color(red: 0.15, green: 0.75, blue: 0.35)
        case 7.0..<8.0:
            // Good - green-teal
            return Color(red: 0.25, green: 0.70, blue: 0.45)
        case 6.0..<7.0:
            // Above average - yellow-green
            return Color(red: 0.55, green: 0.75, blue: 0.30)
        case 5.0..<6.0:
            // Neutral - amber
            return Color(red: 0.90, green: 0.70, blue: 0.25)
        case 4.0..<5.0:
            // Below average - orange
            return Color(red: 0.95, green: 0.55, blue: 0.25)
        case 3.0..<4.0:
            // Low - red-orange
            return Color(red: 0.95, green: 0.40, blue: 0.30)
        default:
            // Very low - red
            return Color(red: 0.90, green: 0.25, blue: 0.30)
        }
    }
}

// MARK: - Day Mood Detail View

struct DayMoodDetailView: View {
    let date: Date
    let moodEntries: [SupabaseMoodEntry]
    let journalEntries: [SupabaseJournalEntry]

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var predictionService = MoodPredictionService.shared
    @StateObject private var analysisService = JournalAnalysisService.shared
    @State private var allUserJournalEntries: [SupabaseJournalEntry] = []
    @State private var moodPrediction: MoodPrediction?
    @State private var showFactorsDetails = false
    @State private var isLoadingPrediction = true
    
    // Minimum entries required to unlock predictions
    private let minimumEntriesForPrediction = 5
    
    private var robustEntryCount: Int {
        // combine actual entries count with 'ghost' entries from evaluations
        // for days where we don't have local entries
        let entryDays = Set(allUserJournalEntries.map { Calendar.current.startOfDay(for: $0.createdAt) })
        
        let ghostEntriesCount = analysisService.analyses.reduce(0) { count, analysis in
            let analysisDay = Calendar.current.startOfDay(for: analysis.date)
            if !entryDays.contains(analysisDay) {
                return count + analysis.entryCount
            }
            return count
        }
        
        return allUserJournalEntries.count + ghostEntriesCount
    }
    
    private var isPredictionLocked: Bool {
        robustEntryCount < minimumEntriesForPrediction
    }
    
    private var entriesUntilUnlock: Int {
        max(0, minimumEntriesForPrediction - robustEntryCount)
    }
    
    private var progressToUnlock: Double {
        Double(robustEntryCount) / Double(minimumEntriesForPrediction)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var averageMood: Double? {
        let moods = journalEntries.compactMap { $0.mood }
        guard !moods.isEmpty else { return nil }
        return Double(moods.reduce(0, +)) / Double(moods.count)
    }
    
    private var predictedMood: Double {
        return moodPrediction?.predictedMood ?? 7.5
    }
    
    private var isFutureDate: Bool {
        return date > Date()
    }
    
    private var moodComparison: String {
        guard let actual = averageMood else {
            return "No mood data recorded"
        }
        
        let difference = actual - predictedMood
        if abs(difference) < 0.5 {
            return "On track with prediction"
        } else if difference > 0 {
            return "Better than predicted! ↑"
        } else {
            return "Below prediction ↓"
        }
    }
    
    // Weather icon helpers for expanded view
    private func weatherIcon(for condition: WeatherData.WeatherCondition) -> String {
        switch condition {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.fill"
        case .snowy: return "cloud.snow.fill"
        case .foggy: return "cloud.fog.fill"
        }
    }
    
    private func weatherIconColor(for condition: WeatherData.WeatherCondition) -> Color {
        return Color(hex: "FF5C7A")
    }
    
    // Human-readable mood interpretation with narrative approach
    private func getMoodInterpretation(for score: Double, moodState: MoodState) -> String {
        let recentEntryCount = allUserJournalEntries.filter { entry in
            Calendar.current.dateComponents([.day], from: entry.createdAt, to: Date()).day ?? 100 <= 7
        }.count

        let hasBeenJournaling = allUserJournalEntries.count > 5
        let isConsistent = recentEntryCount >= 3

        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: date)
        let dayName = calendar.weekdaySymbols[dayOfWeek - 1]

        // Build contextual narrative
        var narrative = ""

        switch moodState {
        case .radiant:
            narrative = "Tomorrow looks \(moodState.rawValue)"
            if isConsistent {
                return "\(narrative). Based on your patterns, you're likely to feel exceptionally positive. Your consistent self-reflection is paying off."
            }
            return "\(narrative) with bright energy. You might feel joyful and motivated. Great day to embrace what inspires you."

        case .positive:
            narrative = "Tomorrow looks \(moodState.rawValue)"
            if hasBeenJournaling {
                return "\(narrative). Your recent entries suggest you're in a good headspace. Expect to feel engaged and capable."
            }
            return "\(narrative) with good energy. \(dayName)s typically bring steady positivity. Great day to focus on meaningful goals."

        case .balanced:
            narrative = "Tomorrow looks \(moodState.rawValue)"
            if isConsistent {
                return "\(narrative) with steady energy. You might experience some ups and downs, but your routines will help you stay grounded."
            }
            return "\(narrative). Expect comfortable moments mixed with ones requiring patience. Stay present with your routines."

        case .low:
            narrative = "Tomorrow might feel \(moodState.rawValue)"
            if hasBeenJournaling {
                return "\(narrative). You may feel mild stress or uncertainty. Remember the resilience you've shown in previous entries."
            }
            return "\(narrative). Energy levels might dip. Be gentle with yourself and adjust expectations as needed."

        case .challenging:
            narrative = "Tomorrow could feel \(moodState.rawValue)"
            if isConsistent {
                return "\(narrative). Lower energy or difficult emotions might surface. Your past reflections show your strength—lean on what's helped before."
            }
            return "\(narrative). Difficult emotions may surface. Remember: feelings are temporary, and support is available when you need it."
        }
    }
    
    private func getMoodEmoji(for score: Double) -> String {
        switch score {
        case 9.5...10.0: return "🤩"
        case 9.0..<9.5: return "😊"
        case 8.5..<9.0: return "😄"
        case 8.0..<8.5: return "🙂"
        case 7.5..<8.0: return "😌"
        case 7.0..<7.5: return "🙂"
        case 6.5..<7.0: return "😐"
        case 6.0..<6.5: return "😶"
        case 5.5..<6.0: return "😕"
        case 5.0..<5.5: return "😟"
        case 4.5..<5.0: return "😔"
        case 4.0..<4.5: return "☹️"
        case 3.5..<4.0: return "😞"
        case 3.0..<3.5: return "😥"
        case 2.5..<3.0: return "😢"
        case 2.0..<2.5: return "😭"
        default: return "💙"
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Main prediction card - always visible
                mainContentCard
                    .padding(.horizontal, 20)

                // Details section - revealed on swipe up
                VStack(spacing: 16) {
                    // Section divider with subtle hint
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
                            .frame(height: 1)

                        Text("More Details")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.35))
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))
                            .frame(height: 1)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    predictionDetailsContent
                    journalEntriesSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(FeelPalette.modalBackground(for: colorScheme).ignoresSafeArea())
        .onAppear {
            loadHistoricalDataAndCalculatePrediction()
        }
    }

    private var mainContentCard: some View {
        VStack(spacing: 20) {
            // Date header
            Text(formattedDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Main prediction content
            if isPredictionLocked {
                lockedPredictionState
            } else if isLoadingPrediction {
                loadingState
            } else if let prediction = moodPrediction {
                cleanPredictionView(for: prediction)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF"))
        )
    }

    private var dateHeader: some View {
            Text(formattedDate)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var moodPredictionCard: some View {
        VStack(spacing: 16) {
            if isPredictionLocked {
                lockedPredictionState
            } else if isLoadingPrediction {
                loadingState
            } else if let prediction = moodPrediction {
                cleanPredictionView(for: prediction)
            }
        }
    }

    private func cleanPredictionView(for prediction: MoodPrediction) -> some View {
        VStack(spacing: 0) {
            // Hero section with gradient ring
            ZStack {
                // Outer subtle ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                prediction.visualState.primaryColor.opacity(0.35),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 104, height: 104)
                    .blur(radius: 0.5)

                // Inner circle background
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .frame(width: 90, height: 90)

                // Score display
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", prediction.predictedMood))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))

                    Text("/ 10")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                }
            }
            .padding(.bottom, 20)

            // State name with subtle gradient
            Text(prediction.moodState.rawValue)
                .font(.system(size: 23, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                .padding(.bottom, 6)

            // Confidence indicator
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index < Int(prediction.confidence * 5) ?
                              prediction.visualState.primaryColor.opacity(0.5) :
                              (colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.15)))
                        .frame(width: 5.5, height: 5.5)
                }
                Text("confidence")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.35) : Color.black.opacity(0.35))
            }
            .padding(.bottom, 20)

            // Insight card - refined
            if let insight = prediction.primaryInsight {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(prediction.visualState.primaryColor.opacity(0.7))

                        Text("Insight")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.55) : Color.black.opacity(0.55))
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }

                    Text(insight)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.05), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 0) {
            // Animated ring loader
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06), lineWidth: 3)
                    .frame(width: 88, height: 88)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                FeelPalette.accent,
                                FeelPalette.accent.opacity(0.3)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 88, height: 88)
                    .rotationEffect(.degrees(-90))

                // Inner circle
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                    .frame(width: 76, height: 76)

                // Icon
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(FeelPalette.accent.opacity(0.8))
            }
            .padding(.bottom, 20)

            Text("Analyzing")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                .padding(.bottom, 4)

            Text("Looking at your patterns...")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.45) : Color.black.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    private var lockedPredictionState: some View {
        VStack(spacing: 0) {
            // Lock icon with animated ring
            ZStack {
                // Outer dashed ring
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                FeelPalette.accent.opacity(0.4),
                                FeelPalette.accent.opacity(0.1),
                                FeelPalette.accent.opacity(0.3),
                                FeelPalette.accent.opacity(0.1),
                                FeelPalette.accent.opacity(0.4)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2, dash: [4, 4])
                    )
                    .frame(width: 88, height: 88)

                // Inner circle
                Circle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                    .frame(width: 76, height: 76)

                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(FeelPalette.accent)
            }
            .padding(.bottom, 20)

            // Title
            Text("Unlock Predictions")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                .padding(.bottom, 6)

            // Subtitle
            Text("\(entriesUntilUnlock) more \(entriesUntilUnlock == 1 ? "entry" : "entries") to go")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                .padding(.bottom, 24)

            // Progress bar - refined style
            VStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08))

                        // Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [FeelPalette.accent, FeelPalette.accentSoft],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geometry.size.width * min(progressToUnlock, 1.0), 8))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressToUnlock)
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())

                // Progress labels
                HStack {
                    Text("\(robustEntryCount)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(FeelPalette.accent)
                    +
                    Text(" / \(minimumEntriesForPrediction) entries")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(Int(progressToUnlock * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(FeelPalette.accent)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func predictionHero(for prediction: MoodPrediction) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack {
                Text("Predicted Mood")
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                if let outlook = prediction.microOutlook {
                    microOutlookChip(outlook)
                }
            }

            // Main mood display - compact
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(prediction.moodState.rawValue)
                        .font(.quicksand(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: prediction.moodState.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    HStack(spacing: 8) {
                        Text(String(format: "%.1f / 10", prediction.predictedMood))
                            .font(.quicksand(size: 14, weight: .semibold))
                            .foregroundColor(FeelPalette.primaryText(for: colorScheme).opacity(0.8))

                        if let comparative = prediction.comparativeDescription {
                            Text(comparative)
                                .font(.quicksand(size: 11, weight: .medium))
                                .foregroundColor(prediction.visualState.primaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(prediction.visualState.primaryColor.opacity(0.12))
                                )
                        }
                    }
                }

                Spacer()

                Text(getMoodEmoji(for: prediction.predictedMood))
                    .font(.system(size: 32))
            }

            // Confidence bar - simplified
            if let band = prediction.confidenceBand {
                MoodRangeBarView(
                    band: band,
                    predictedMood: prediction.predictedMood,
                    accent: prediction.moodState.color
                )
            }

            // Stats row - compact
            predictionStatsRow(for: prediction)
        }
        .padding(.vertical, 4)
    }

    private func predictionStatsRow(for prediction: MoodPrediction) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                PredictionMetricCard(
                    title: "Confidence",
                    value: String(format: "%d%%", Int(prediction.confidence * 100)),
                    subtitle: prediction.confidenceDescription
                )

                if let stability = prediction.stabilityScore {
                    PredictionMetricCard(
                        title: "Stability",
                        value: String(format: "%d%%", Int(stability * 100)),
                        subtitle: stability > 0.6 ? "even footing" : "expect sway"
                    )
                }

                if let band = prediction.confidenceBand {
                    PredictionMetricCard(
                        title: "Range width",
                        value: String(format: "%.1f pts", band.spread),
                        subtitle: String(format: "%.1f – %.1f", band.lower, band.upper)
                    )
                } else if let actual = averageMood, !isFutureDate {
                    let diff = actual - prediction.predictedMood
                    PredictionMetricCard(
                        title: "Today vs prediction",
                        value: diff >= 0 ? "+\(String(format: "%.1f", diff))" : String(format: "%.1f", diff),
                        subtitle: "calibration check"
                    )
                }
            }
        }
        .padding(.top, 4)
    }

    private func microOutlookChip(_ outlook: MoodMicroOutlook) -> some View {
        HStack(spacing: 6) {
            Image(systemName: outlook.icon)
                .font(.system(size: 12, weight: .semibold))
            Text(outlook.headline)
                .font(.quicksand(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color(for: outlook.direction).opacity(0.18))
        )
        .foregroundColor(color(for: outlook.direction))
    }

    private func color(for direction: MoodTrajectoryDirection) -> Color {
        switch direction {
        case .rising: return Color(hex: "FF5C7A")
        case .steady: return Color.white
        case .easing: return Color(hex: "F97316")
        case .volatile: return Color(hex: "C084FC")
        }
    }

    private func predictionHighlights(for prediction: MoodPrediction) -> some View {
        VStack(spacing: 12) {
            if let insight = prediction.primaryInsight {
                CompactInsightRow(
                    icon: "brain.head.profile",
                    title: "Pattern",
                    detail: insight,
                    tint: Color(hex: "FF5C7A")
                )
            }

            CompactInsightRow(
                icon: "sparkles",
                title: "Outlook",
                detail: getCompactMoodInterpretation(for: prediction.predictedMood),
                tint: Color(hex: "8B5CF6")
            )
        }
    }

    private func getCompactMoodInterpretation(for mood: Double) -> String {
        switch mood {
        case 8.0...: return "Expect a positive day ahead"
        case 7.0..<8.0: return "Looking good with steady energy"
        case 6.0..<7.0: return "Balanced day with mixed moments"
        case 5.0..<6.0: return "Some challenges may arise"
        case 4.0..<5.0: return "Take it easy today"
        default: return "Focus on self-care"
        }
    }

    private func supportSuggestionCard(_ suggestion: MoodSupportSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "FF5C7A"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(hex: "FF5C7A").opacity(0.15))
                    )

                Text(suggestion.title)
                    .font(.quicksand(size: 18, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
            }

            Text(suggestion.detail)
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                .lineSpacing(4)

            Divider().background(FeelPalette.border(for: colorScheme))

            HStack {
                Image(systemName: "bell.badge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "FF8FA3"))
                Text("Add to your ritual reminders")
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "FF8FA3"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "FF8FA3"))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
        )
    }


    // MARK: - Prediction Details Content (Inline, revealed on swipe)

    @ViewBuilder
    private var predictionDetailsContent: some View {
        if moodPrediction != nil || isPredictionLocked {
            VStack(spacing: 0) {
                // Compact header
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FeelPalette.accent.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
                        )

                    Text("Insights")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))

                    Spacer()
                }
                .padding(.bottom, 16)

                if isPredictionLocked {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))

                        Text("Keep journaling to unlock insights")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
                    }
                    .padding(.vertical, 16)
                } else if let prediction = moodPrediction {
                    inlineFactorsDetailView(prediction: prediction)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04), lineWidth: 1)
                    )
            )
        }
    }

    private func inlineFactorsDetailView(prediction: MoodPrediction) -> some View {
        VStack(spacing: 12) {
            // Personal Analytics - compact inline
            if let baseline = prediction.personalBaseline {
                inlinePersonalAnalyticsView(prediction: prediction, baseline: baseline)
            }

            // Contributing Factors - simplified
            if !prediction.factors.isEmpty {
                detailFactorsCard(prediction: prediction)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03), lineWidth: 1)
                )
        )
    }

    private func detailFactorsCard(prediction: MoodPrediction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Factors")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                .textCase(.uppercase)
                .kerning(0.5)

            VStack(spacing: 8) {
                ForEach(prediction.factors, id: \.id) { factor in
                    PredictionFactorRow(factor: factor)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03), lineWidth: 1)
                )
        )
    }

    private func inlinePersonalAnalyticsView(prediction: MoodPrediction, baseline: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Stats")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                .textCase(.uppercase)
                .kerning(0.5)

            // Horizontal stats row
            HStack(spacing: 0) {
                // Baseline
                statItem(value: String(format: "%.1f", baseline), label: "Baseline")

                Divider()
                    .frame(height: 28)
                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))

                // vs Baseline
                if let score = prediction.comparativeScore {
                    statItem(
                        value: String(format: "%+.1f", score),
                        label: "Today",
                        valueColor: prediction.visualState.primaryColor
                    )

                    Divider()
                        .frame(height: 28)
                        .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                }

                // Weekday
                if let weekdayAvg = prediction.weekdayAverage, let rank = prediction.weekdayRank {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: prediction.date)
                    let dayName = calendar.shortWeekdaySymbols[weekday - 1]

                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", weekdayAvg))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
                            // Subtle rank dot
                            Circle()
                                .fill(
                                    rank <= 2 ? Color(hex: "10B981").opacity(0.8) :
                                    rank >= 6 ? Color(hex: "F59E0B").opacity(0.8) :
                                    Color.clear
                                )
                                .frame(width: 5, height: 5)
                        }
                        Text("\(dayName) avg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03), lineWidth: 1)
                    )
            )

            // Trend (if significant)
            if let trend = prediction.trend, let strength = prediction.trendStrength, strength >= 2 {
                HStack(spacing: 6) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text("\(trend.trendDescription) · \(strength) days")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(trend.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(trend.color.opacity(0.12))
                )
            }
        }
    }

    private func statItem(value: String, label: String, valueColor: Color? = nil) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(valueColor ?? (colorScheme == .dark ? .white : Color(hex: "1A1A1A")))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private func inlineAnalyticsRow(label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(valueColor ?? (colorScheme == .dark ? .white : Color(hex: "1A1A1A")))
        }
    }

    private func inlineWeatherView(weather: WeatherData) -> some View {
        HStack(spacing: 10) {
            Image(systemName: weatherIcon(for: weather.condition))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "3B82F6"))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(hex: "3B82F6").opacity(0.12))
                )

            Text(weather.condition.rawValue.capitalized)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))

            Spacer()

            Text("\(Int(weather.temperature))°")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "1A1A1A"))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
        )
    }

    // Keep old section for backwards compatibility if needed elsewhere
    @ViewBuilder
    private var predictionDetailsSection: some View {
        predictionDetailsContent
    }

    private func factorsDetailView(prediction: MoodPrediction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Personal Analytics Summary
            if let baseline = prediction.personalBaseline {
                personalAnalyticsSummaryView(prediction: prediction, baseline: baseline)
            }

            if let weather = prediction.contextualFactors.weather {
                weatherFactorView(weather: weather)
            }

            if !prediction.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                        Text("Contributing Factors")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    }

                    VStack(spacing: 6) {
                        ForEach(prediction.factors, id: \.id) { factor in
                            PredictionFactorRow(factor: factor)
                        }
                    }
                }
            }
        }
    }

    private func personalAnalyticsSummaryView(prediction: MoodPrediction, baseline: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FeelPalette.accent)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(FeelPalette.accent.opacity(0.12))
                    )

                Text("Personal Analytics")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Spacer()
            }

            // Stats grid
            VStack(spacing: 8) {
                // Personal baseline
                analyticsRow(label: "Your baseline", value: String(format: "%.1f", baseline))

                // Comparative score
                if let score = prediction.comparativeScore {
                    analyticsRow(
                        label: "vs baseline",
                        value: String(format: "%+.1f", score),
                        valueColor: prediction.visualState.primaryColor
                    )
                }

                // Weekday info
                if let weekdayAvg = prediction.weekdayAverage, let rank = prediction.weekdayRank {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: prediction.date)
                    let dayName = calendar.weekdaySymbols[weekday - 1]

                    HStack {
                        Text("\(dayName) avg")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                        Spacer()
                        HStack(spacing: 6) {
                            Text(String(format: "%.1f", weekdayAvg))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                            if rank <= 2 {
                                Text("best")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Color(hex: "10B981"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color(hex: "10B981").opacity(0.12)))
                            } else if rank >= 6 {
                                Text("tough")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color(hex: "F59E0B").opacity(0.12)))
                            }
                        }
                    }
                }

                // Trend
                if let trend = prediction.trend, let strength = prediction.trendStrength, strength >= 2 {
                    HStack {
                        Text("Trend")
                            .font(.quicksand(size: 12, weight: .medium))
                            .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text("\(trend.trendDescription) · \(strength)d")
                                .font(.quicksand(size: 11, weight: .semibold))
                        }
                        .foregroundColor(trend.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .modalGlassShape(in: Capsule(), tint: trend.color)
                    }
                }
            }
            .padding(12)
            .modalGlassCard(cornerRadius: 14)
        }
    }

    private func analyticsRow(label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.quicksand(size: 12, weight: .medium))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            Spacer()
            Text(value)
                .font(.quicksand(size: 12, weight: .bold))
                .foregroundColor(valueColor ?? FeelPalette.primaryText(for: colorScheme))
        }
    }

    private func weatherFactorView(weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: weatherIcon(for: weather.condition))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF5C7A"), Color(hex: "FF8FA3")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .modalGlassShape(in: Circle(), tint: Color(hex: "FF5C7A"))

                Text("Weather")
                    .font(.quicksand(size: 14, weight: .semibold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Spacer()
            }

            HStack {
                Text(weather.condition.rawValue.capitalized)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                Spacer()
                Text("\(Int(weather.temperature))°")
                    .font(.quicksand(size: 14, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
            }
            .padding(12)
            .modalGlassCard(cornerRadius: 14)
        }
    }

    @ViewBuilder
    private var journalEntriesSection: some View {
        if !journalEntries.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    Text("Journal Entries")
                        .font(.quicksand(size: 15, weight: .semibold))
                        .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                }

                ForEach(journalEntries) { entry in
                    JournalEntryPreviewCard(entry: entry)
                }
            }
        } else if !isFutureDate {
            emptyStateView
        }
    }
    
    private func loadHistoricalDataAndCalculatePrediction() {
        guard let userId = databaseService.currentUser?.id else {
            isLoadingPrediction = false
            return
        }

        Task {
            do {
                // Force refresh from Supabase to get latest entries
                debugPrint("🔄 DayMoodDetailView: Loading entries for predictions...")
                let allEntries = try await databaseService.getJournalEntries(userId: userId, limit: 200, forceRefresh: true)
                debugPrint("📊 DayMoodDetailView: Got \(allEntries.count) total entries for unlock progress")
                
                let entriesWithMood = allEntries.filter { $0.mood != nil }
                debugPrint("📊 DayMoodDetailView: \(entriesWithMood.count) entries have mood data")

                await MainActor.run {
                    // Use ALL entries for unlock progress count (not just those with mood)
                    allUserJournalEntries = allEntries
                    debugPrint("📊 DayMoodDetailView: Set allUserJournalEntries to \(allEntries.count)")
                }

                let prediction = await predictionService.predictMoodWithInsights(
                    for: date,
                    historicalEntries: entriesWithMood,
                    location: nil
                )

                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.25)) {
                        moodPrediction = prediction
                        isLoadingPrediction = false
                    }
                }
            } catch {
                debugPrint("Failed to load historical data: \(error)")
                await MainActor.run {
                    isLoadingPrediction = false
                }
            }
        }
    }
    

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))

            Text("No entries for this day")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1C").opacity(0.5) : Color(hex: "F5F5F7"))
        )
    }
    
    private func getMoodComparisonIcon() -> String {
        guard let actual = averageMood else {
            return "info.circle"
        }
        
        let difference = actual - predictedMood
        if abs(difference) < 0.5 {
            return "checkmark.circle.fill"
        } else if difference > 0 {
            return "arrow.up.circle.fill"
        } else {
            return "arrow.down.circle.fill"
        }
    }
    
    private func getMoodComparisonColor() -> Color {
        guard let actual = averageMood else {
            return Color.white.opacity(0.7)
        }

        let difference = actual - predictedMood
        if abs(difference) < 0.5 {
            return Color(hex: "FF5C7A")
        } else if difference > 0 {
            return Color(hex: "FF5C7A")
        } else {
            return Color(hex: "FF8FA3")
        }
    }
}

struct MoodRangeBarView: View {
    let band: MoodConfidenceBand
    let predictedMood: Double
    let accent: Color
    @Environment(\.colorScheme) var colorScheme

    private var normalizedStart: Double {
        min(max((band.lower - 2.0) / 8.0, 0.0), 1.0)
    }

    private var normalizedEnd: Double {
        min(max((band.upper - 2.0) / 8.0, 0.0), 1.0)
    }

    private var normalizedPrediction: Double {
        min(max((predictedMood - 2.0) / 8.0, 0.0), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Confidence window")
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                Spacer()
                Text(String(format: "%.1f – %.1f", band.lower, band.upper))
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FeelPalette.border(for: colorScheme))
                        .frame(height: 12)

                    Capsule()
                        .fill(accent.opacity(0.3))
                        .frame(
                            width: geometry.size.width * max(0.02, normalizedEnd - normalizedStart),
                            height: 12
                        )
                        .offset(x: geometry.size.width * normalizedStart)

                    Circle()
                        .fill(accent)
                        .frame(width: 16, height: 16)
                        .shadow(color: accent.opacity(0.6), radius: 8, x: 0, y: 2)
                        .offset(x: geometry.size.width * normalizedPrediction - 8)
                }
            }
            .frame(height: 16)
        }
    }
}

struct PredictionMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.quicksand(size: 10, weight: .bold))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))

            Text(value)
                .font(.quicksand(size: 18, weight: .bold))
                .foregroundColor(FeelPalette.primaryText(for: colorScheme))

            Text(subtitle)
                .font(.quicksand(size: 11, weight: .medium))
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : FeelPalette.accent.opacity(0.05))
        )
    }
}

struct PredictionHighlightCard: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Enhanced icon with gradient backdrop
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .shadow(color: tint.opacity(0.3), radius: 8, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Content with improved hierarchy
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.quicksand(size: 15, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text(detail)
                    .font(.quicksand(size: 14, weight: .regular))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04),
                            colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// Compact insight row for cleaner modal
struct CompactInsightRow: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text(detail)
                    .font(.quicksand(size: 12, weight: .regular))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
        )
    }
}

struct JournalEntryPreviewCard: View {
    let entry: SupabaseJournalEntry
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let mood = entry.mood {
                    Circle()
                        .fill(moodColor(for: mood))
                        .frame(width: 12, height: 12)
                }
                
                Text(formattedTime)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                if let mood = entry.mood {
                    Text("\(mood)/10")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                }
            }

            if isExpanded {
                Text(entry.content)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1A1A1C") : Color(hex: "FFFFFF"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func moodColor(for mood: Int) -> Color {
        switch mood {
        case 8...10:
            return Color(hex: "FF5C7A")
        case 5...7:
            return Color(hex: "FF8FA3")
        default:
            return Color(hex: "A34865")
        }
    }
}

// MARK: - Weather Context Card

struct WeatherContextCard: View {
    let weather: WeatherData
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            weatherIconColor.opacity(0.3),
                            weatherIconColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: weatherIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(weatherIconColor)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Expected Weather")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))

                Text(weather.condition.rawValue.capitalized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 12))
                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 13, weight: .medium))
                    }

                    if let humidity = weather.humidity {
                        HStack(spacing: 4) {
                            Image(systemName: "humidity")
                                .font(.system(size: 12))
                            Text("\(Int(humidity))%")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                }
                .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1A1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var weatherIcon: String {
        switch weather.condition {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "cloud.bolt.fill"
        case .snowy: return "snowflake"
        case .foggy: return "cloud.fog.fill"
        }
    }
    
    private var weatherIconColor: Color {
        return Color(hex: "FF5C7A")
    }
}

// MARK: - Prediction Factor Row

struct PredictionFactorRow: View {
    let factor: PredictionFactor
    @Environment(\.colorScheme) var colorScheme

    private var impactColor: Color {
        factor.impact >= 0 ? Color(hex: "10B981") : Color(hex: "F59E0B")
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: factorIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(impactColor)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(impactColor.opacity(0.12))
                )

            Text(factor.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.8))
                .lineLimit(1)

            Spacer()

            Text(factor.impact > 0 ? "+\(String(format: "%.1f", abs(factor.impact)))" : String(format: "%.1f", factor.impact))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(impactColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.04))
        )
    }

    private var factorIcon: String {
        let lowercased = factor.name.lowercased()

        if lowercased.contains("weather") {
            return "cloud.sun.fill"
        } else if lowercased.contains("season") {
            return "sparkles"
        } else if lowercased.contains("moon") {
            return "moon.stars.fill"
        } else if lowercased.contains("trend") || lowercased.contains("recent") {
            return "chart.line.uptrend.xyaxis"
        } else if lowercased.contains("reflection") || lowercased.contains("habit") {
            return "book.fill"
        } else if lowercased.contains("gap") {
            return "clock.arrow.circlepath"
        } else if lowercased.contains("processing") || lowercased.contains("thoughtful") {
            return "brain.head.profile"
        } else if lowercased.contains("time") || lowercased.contains("holiday") {
            return "calendar"
        } else if lowercased.contains("day") || lowercased.contains("week") {
            return "calendar.badge.clock"
        } else {
            return "sparkles"
        }
    }
}

// MARK: - Mood Insight Card

struct MoodInsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FeelPalette.surface(for: colorScheme), FeelPalette.surfaceSecondary(for: colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 12, x: 0, y: 8)
        )
    }
}

private struct HeroPromptContent: View {
    let label: String
    let promptText: String
    let categoryLabel: String
    let emoji: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                FeelPalette.accent.opacity(0.3),
                                FeelPalette.accentSoft.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .overlay(
                        Circle()
                            .stroke(FeelPalette.border(for: colorScheme), lineWidth: 1)
                    )

                Text(emoji)
                    .font(.system(size: 34))
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(label.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    .kerning(1.1)

                Text(promptText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                    .lineLimit(3)

                HStack(spacing: 12) {
                    Text(categoryLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(FeelPalette.accent.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(FeelPalette.accent.opacity(0.3), lineWidth: 1)
                                )
                        )

                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "scribble.variable")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Writing")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        FeelPalette.accent,
                                        FeelPalette.accentDeep
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: FeelPalette.accent.opacity(0.45), radius: 15, x: 0, y: 8)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [FeelPalette.surface(for: colorScheme), FeelPalette.surfaceSecondary(for: colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    FeelPalette.accent.opacity(0.5),
                                    FeelPalette.border(for: colorScheme)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 25, x: 0, y: 15)
        )
    }
}

struct GamifiedJournalView: View {
    @StateObject private var gameStatsManager = JournalGameStatsManager.shared
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var questionManager = DailyQuestionManager.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var showingNewEntry = false
    @State private var showingEvaluations = false
    @State private var showingAchievements = false
    @State private var newAchievementUnlocked: JournalAchievement?
    @State private var currentPrompt: JournalPrompt?
    @State private var animateContent = false
    @State private var recentEntries: [SupabaseJournalEntry] = []
    @State private var isLoadingEntries = false

    private var cachedLevelContext: (current: JournalLevel, next: JournalLevel?)? {
        let points = gameStatsManager.gameStats.totalPoints
        let currentLevel = JournalLevel.levelForPoints(points)
        let nextPoints = currentLevel.requiredPoints + 100
        let nextLevel = JournalLevel.levelForPoints(nextPoints)
        return (currentLevel, nextLevel.level != currentLevel.level ? nextLevel : nil)
    }

    var body: some View {
        ZStack {
            // Background adapts to color scheme
            FeelPalette.background(for: colorScheme)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    modernHeader

                    moodCalendarSection
                        .opacity(animateContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: animateContent)

                    // Quick action button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        showingNewEntry = true
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(FeelPalette.accent.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(FeelPalette.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("New Reflection")
                                    .font(.quicksand(size: 17, weight: .semibold))
                                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                                Text("Capture how you're feeling right now")
                                    .font(.quicksand(size: 13, weight: .medium))
                                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(FeelPalette.mutedText(for: colorScheme))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(FeelPalette.surface(for: colorScheme))
                                .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 12, x: 0, y: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(FeelPalette.stroke(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            loadDailyQuestion()
            loadRecentEntries()
            
            withAnimation {
                animateContent = true
            }
        }
        .onChange(of: showingNewEntry) { newValue in
            if !newValue {
                loadRecentEntries()
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            GamifiedJournalEntryView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingEvaluations) {
            EvaluationsModalView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingAchievements) {
            JournalAchievementsView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .overlay(
            Group {
                if let achievement = newAchievementUnlocked {
                    AchievementUnlockedView(achievement: achievement) {
                        newAchievementUnlocked = nil
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
            }
        )
    }
    
    // MARK: - Modern Header

    private var modernHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mood Calendar")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text("Track your emotional journey")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }

            Spacer()

            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showingAchievements = true
            }) {
                Circle()
                    .fill(FeelPalette.surface(for: colorScheme))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FFD700"))
                    )
                    .overlay(
                        Circle()
                            .stroke(FeelPalette.border(for: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Hero Journal Prompt
    
    private var heroJournalPrompt: some View {
        let label = currentPrompt == nil ? "Ready to reflect?" : "Today's prompt"
        let promptText = currentPrompt?.questionText ?? "Give your feelings space. Capture what's moving through you."
        let emoji = currentPrompt.map { getCategoryEmoji($0.category) } ?? "📝"
        let categoryLabel = currentPrompt?.category.displayName ?? "Open Reflection"

        return Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            showingNewEntry = true
        }) {
            HeroPromptContent(
                label: label,
                promptText: promptText,
                categoryLabel: categoryLabel,
                emoji: emoji
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stats Snapshot
    
    private var statsSnapshot: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Spacer()

                Button(action: {
                    showingEvaluations = true
                }) {
                    HStack(spacing: 6) {
                        Text("View insights")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(FeelPalette.accent)
                }
            }

            HStack(spacing: 14) {
                EnhancedStatCard(
                    icon: "flame.fill",
                    value: "\(gameStatsManager.gameStats.currentStreak)",
                    label: "Day streak",
                    color: Color(hex: "FF5C7A"),
                    colorScheme: colorScheme
                )

                EnhancedStatCard(
                    icon: "pencil.line",
                    value: "\(gameStatsManager.gameStats.totalEntries)",
                    label: "Entries",
                    color: Color(hex: "FF8FA3"),
                    colorScheme: colorScheme
                )

                EnhancedStatCard(
                    icon: "star.fill",
                    value: "\(gameStatsManager.gameStats.totalPoints)",
                    label: "Points",
                    color: Color(hex: "A34865"),
                    colorScheme: colorScheme
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FeelPalette.surface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(FeelPalette.border(for: colorScheme), lineWidth: 1)
                )
                .shadow(color: FeelPalette.shadow(for: colorScheme), radius: 15, x: 0, y: 8)
        )
    }
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Reflections")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                
                Spacer()
                
                if !recentEntries.isEmpty {
                    Button(action: {
                        showingEvaluations = true
                    }) {
                        HStack(spacing: 4) {
                            Text("View all")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(FeelPalette.accent)
                    }
                }
            }
            
            if isLoadingEntries {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(FeelPalette.accent)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if recentEntries.isEmpty {
                emptyEntriesState
            } else {
                VStack(spacing: 12) {
                    ForEach(recentEntries.prefix(3)) { entry in
                        RecentEntryCard(entry: entry)
                    }
                }
            }
        }
    }
    
    private var emptyEntriesState: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(FeelPalette.accent.opacity(0.2))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(FeelPalette.accent)
                )

            VStack(spacing: 6) {
                Text("No reflections yet")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text("Start your journey by writing your first entry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FeelPalette.surface(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(FeelPalette.border(for: colorScheme), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Functions
    
    private func getCategoryEmoji(_ category: JournalPrompt.PromptCategory) -> String {
        switch category {
        case .reflection: return "🤔"
        case .gratitude: return "🙏"
        case .emotions: return "💖"
        case .goals: return "🎯"
        case .growth: return "🌱"
        case .relationships: return "👥"
        case .selfCare: return "💆‍♀️"
        case .joy: return "😊"
        case .creativity: return "🎨"
        }
    }
    
    private func loadDailyQuestion() {
        Task {
            let question = await questionManager.getDailyQuestion()
            await MainActor.run {
                currentPrompt = question
            }
        }
    }
    
    private func loadRecentEntries() {
        guard let userId = databaseService.currentUser?.id else {
            return
        }
        
        Task {
            isLoadingEntries = true
            
            do {
                let entries = try await databaseService.getJournalEntries(userId: userId, limit: 5)
                await MainActor.run {
                    recentEntries = entries
                    isLoadingEntries = false
                }
            } catch {
                debugPrint("Error loading recent entries: \(error)")
                await MainActor.run {
                    isLoadingEntries = false
                }
            }
        }
    }
    
    // MARK: - Mood Calendar Section

    private var moodCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MoodCalendarView()
        }
    }
    
    // MARK: - Mood Insights Section
    
    private var moodInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Insights")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(FeelPalette.primaryText(for: colorScheme))
            
            HStack(spacing: 12) {
                MoodInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Best Day",
                    value: "Wednesday",
                    color: Color(hex: "FF5C7A")
                )
                
                MoodInsightCard(
                    icon: "heart.fill",
                    title: "Average Mood",
                    value: "7.2/10",
                    color: Color(hex: "FF8FA3")
                )
                
                MoodInsightCard(
                    icon: "calendar.badge.clock",
                    title: "Active Days",
                    value: "5/7",
                    color: Color(hex: "A34865")
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text("Shortcuts to keep your rhythm")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                Button(action: {
                    showingNewEntry = true
                }) {
                    QuickActionCard(
                        icon: "pencil.circle.fill",
                        title: "Log Mood",
                        subtitle: "How are you feeling?",
                        color: FeelPalette.accent
                    )
                }
                
                Button(action: {
                    showingEvaluations = true
                }) {
                    QuickActionCard(
                        icon: "chart.bar.doc.horizontal.fill",
                        title: "View Trends",
                        subtitle: "See your progress",
                        color: FeelPalette.accentSoft
                    )
                }
            }
        }
    }
    
}

struct RecentEntryCard: View {
    let entry: SupabaseJournalEntry
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme

    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(entry.createdAt) {
            formatter.timeStyle = .short
            return "Today at " + formatter.string(from: entry.createdAt)
        } else if calendar.isDateInYesterday(entry.createdAt) {
            formatter.timeStyle = .short
            return "Yesterday at " + formatter.string(from: entry.createdAt)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: entry.createdAt)
        }
    }
    
    private var contentPreview: String {
        let maxLength = 120
        if entry.content.count > maxLength {
            return String(entry.content.prefix(maxLength)) + "..."
        }
        return entry.content
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(FeelPalette.accent.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(FeelPalette.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedDate)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                        Text("\(entry.content.split(separator: " ").count) words")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                }

                if isExpanded {
                    Text(entry.content)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FeelPalette.primaryText(for: colorScheme))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    Text(contentPreview)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FeelPalette.surface(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(FeelPalette.border(for: colorScheme), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Card Component

struct EnhancedStatCard: View, Equatable {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var colorScheme: ColorScheme = .dark

    static func == (lhs: EnhancedStatCard, rhs: EnhancedStatCard) -> Bool {
        lhs.value == rhs.value && lhs.label == rhs.label && lhs.colorScheme == rhs.colorScheme
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1A1A1A")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "666666")
    }

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                )

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryTextColor)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StatCard: View, Equatable {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var colorScheme: ColorScheme = .dark

    static func == (lhs: StatCard, rhs: StatCard) -> Bool {
        lhs.value == rhs.value && lhs.label == rhs.label && lhs.colorScheme == rhs.colorScheme
    }

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.25),
                            color.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                )
                .shadow(color: color.opacity(0.25), radius: 8, x: 0, y: 4)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(FeelPalette.primaryText(for: colorScheme))

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FeelPalette.secondaryText(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [FeelPalette.surface(for: colorScheme), FeelPalette.surfaceSecondary(for: colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Shared Helpers

private struct DelayedAppear: ViewModifier {
    let isVisible: Bool
    let delay: Double
    
    func body(content: Content) -> some View {
        return content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(delay), value: isVisible)
    }
}

private extension View {
    func delayedAppearance(isVisible: Bool, delay: Double) -> some View {
        modifier(DelayedAppear(isVisible: isVisible, delay: delay))
    }
}



#Preview {
    GamifiedJournalView()
}
