//
//  EnhancedAnalyticsView.swift
//  anxiety
//
//  Enhanced analytics and insights view for the Grow tab
//

import SwiftUI
import Charts

// MARK: - Analytics Theme Palette

private enum AnalyticsPalette {
    static let accent = Color(hex: "FF5C7A")
    static let accentSoft = Color(hex: "FF8FA3")
    static let accentDeep = Color(hex: "A34865")

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "0F0F10") : Color(hex: "F8F8FA")
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(hex: "1A1A1A")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color(hex: "666666")
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color(hex: "E8E8EA")
    }

    static func shadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color(hex: "FF5C7A").opacity(0.1)
    }
}

struct EnhancedAnalyticsView: View {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var gameStatsManager = JournalGameStatsManager.shared
    @StateObject private var analyticsService = AnalyticsDataService.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Real data from analytics service
    @State private var currentStreak = 0
    @State private var totalEntries = 0
    @State private var averageMood = 0.0
    @State private var weeklyProgress = 0.0
    @State private var monthlyTrend: TrendDirection = .neutral
    @State private var activityTrend: TrendDirection = .neutral
    @State private var totalActiveDays = 0
    @State private var isLoading = true
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingDetailedStats = false
    @State private var showingAchievements = false
    @State private var showingProfile = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }
    
    var body: some View {
        ZStack {
            // Background
            AnalyticsPalette.background(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                        .padding(.top, 20)
                    
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Key Metrics
                    keyMetricsDashboard
                    
                    // Activity Heatmap
                    activityHeatmapSection

                    // Insights Section
                    insightsSection

                    // Achievements Button
                    achievementsButton

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .task {
            await loadAnalyticsData()
        }
        .refreshable {
            await loadAnalyticsData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("JournalEntrySubmitted"))) { _ in
            Task {
                await loadAnalyticsData()
            }
        }
        .sheet(isPresented: $showingAchievements) {
            JournalAchievementsView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Growth")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

                Text("Track your emotional journey")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
            }

            Spacer()

            // Profile shortcut
            Button {
                showingProfile = true
            } label: {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AnalyticsPalette.accent, AnalyticsPalette.accentDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: AnalyticsPalette.accent.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: "person.fill")
                            .font(.quicksand(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("Account")
                        .font(.quicksand(size: 10, weight: .medium))
                        .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                }
            }
        }
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTimeRange = range
                    }
                    Task { await loadAnalyticsData() }
                }) {
                    Text(range.rawValue)
                        .font(.quicksand(size: 14, weight: selectedTimeRange == range ? .bold : .medium))
                        .foregroundColor(selectedTimeRange == range ? .white : AnalyticsPalette.secondaryText(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                if selectedTimeRange == range {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [AnalyticsPalette.accent, AnalyticsPalette.accentDeep],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: AnalyticsPalette.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                                        .matchedGeometryEffect(id: "rangeTab", in: namespace)
                                }
                            }
                        )
                }
            }
        }
        .padding(6)
        .background(
            ZStack {
                Capsule()
                    .fill(colorScheme == .dark ? Color(hex: "0A0A0B") : Color(hex: "F8F8FA"))

                Capsule()
                    .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.1 : 0.3))

                Capsule()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.05) : Color(hex: "E8E8EA"),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: AnalyticsPalette.shadow(for: colorScheme), radius: 10, x: 0, y: 4)
        )
    }
    @Namespace private var namespace
    
    // MARK: - Key Metrics
    private var keyMetricsDashboard: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Streak
                metricCard(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    subtitle: currentStreak == 1 ? "day" : "days",
                    icon: "flame.fill",
                    color: Color(hex: "FF5C7A")
                )
                
                // Total Entries
                metricCard(
                    title: "Total Entries",
                    value: "\(totalEntries)",
                    subtitle: "reflections",
                    icon: "doc.text.fill",
                    color: Color(hex: "FF8FA3")
                )
                
                // Avg Mood
                metricCard(
                    title: "Avg Mood",
                    value: averageMood > 0 ? String(format: "%.1f", averageMood) : "—",
                    subtitle: "out of 10",
                    icon: "heart.fill",
                    color: Color(hex: "A34865")
                )
                
                // Active Days
                metricCard(
                    title: "Active Days",
                    value: "\(totalActiveDays)",
                    subtitle: "this month",
                    icon: "calendar",
                    color: Color(hex: "FF2E50")
                )
            }
        }
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.25), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.quicksand(size: 26, weight: .bold))
                    .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

                Text(title)
                    .font(.quicksand(size: 12, weight: .semibold))
                    .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))

                Text(subtitle)
                    .font(.quicksand(size: 10, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.35) : Color(hex: "999999"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Dark base
                RoundedRectangle(cornerRadius: 18)
                    .fill(colorScheme == .dark ? Color(hex: "0A0A0B") : Color(hex: "F8F8FA"))

                // Subtle glass
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.1 : 0.3))

                // Top gradient
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.05) : Color(hex: "E8E8EA"),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: AnalyticsPalette.shadow(for: colorScheme), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Activity Heatmap
    private var activityHeatmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Heatmap")
                        .font(.quicksand(size: 18, weight: .bold))
                        .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

                    Text("Last 5 weeks")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                }

                Spacer()

                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.quicksand(size: 10, weight: .medium))
                        .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))

                    ForEach(0..<5, id: \.self) { level in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(activityColor(for: level))
                            .frame(width: 12, height: 12)
                    }

                    Text("More")
                        .font(.quicksand(size: 10, weight: .medium))
                        .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                }
            }

            VStack(spacing: 10) {
                // Days Header
                HStack(spacing: 6) {
                    ForEach(Array(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.quicksand(size: 10, weight: .semibold))
                            .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Grid
                VStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { week in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { day in
                                heatmapCell(activity: getActivityForDay(week: week, day: day))
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Dark base
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(hex: "0A0A0B") : Color(hex: "F8F8FA"))

                    // Subtle glass
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.1 : 0.3))

                    // Top gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark ? Color.white.opacity(0.03) : Color.white.opacity(0.5),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.05) : Color(hex: "E8E8EA"),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: AnalyticsPalette.shadow(for: colorScheme), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    private func heatmapCell(activity: Int) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(activityColor(for: activity))
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        activity > 0 ? AnalyticsPalette.accent.opacity(0.1) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
    
    private func activityColor(for level: Int) -> Color {
        let baseEmpty = colorScheme == .dark ? Color.white.opacity(0.03) : Color(hex: "FF5C7A").opacity(0.06)
        switch level {
        case 0: return baseEmpty
        case 1: return AnalyticsPalette.accent.opacity(0.25)
        case 2: return AnalyticsPalette.accent.opacity(0.45)
        case 3: return AnalyticsPalette.accent.opacity(0.65)
        default: return AnalyticsPalette.accent.opacity(0.85)
        }
    }
    
    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.quicksand(size: 18, weight: .bold))
                .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

            VStack(spacing: 12) {
                insightCard(
                    icon: "lightbulb.fill",
                    title: getInsightTitle(),
                    description: getInsightDescription(),
                    color: Color(hex: "FFB347")
                )

                if currentStreak > 0 {
                    insightCard(
                        icon: "flame.fill",
                        title: "Keep it up!",
                        description: "You're on a \(currentStreak)-day streak. Consistency is the key to growth.",
                        color: AnalyticsPalette.accent
                    )
                }
            }
        }
    }

    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.quicksand(size: 15, weight: .bold))
                    .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

                Text(description)
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color(hex: "1C1C1E"),
                            Color(hex: "141416")
                        ] : [
                            Color.white,
                            Color(hex: "FFF8FA")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.2), AnalyticsPalette.border(for: colorScheme)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: AnalyticsPalette.shadow(for: colorScheme), radius: 10, x: 0, y: 4)
        )
    }

    private func getInsightTitle() -> String {
        if totalEntries == 0 {
            return "Start Your Journey"
        } else if averageMood >= 7 {
            return "You're Doing Great!"
        } else if averageMood >= 5 {
            return "Keep Growing"
        } else {
            return "Every Step Counts"
        }
    }

    private func getInsightDescription() -> String {
        if totalEntries == 0 {
            return "Write your first reflection to begin tracking your emotional growth."
        } else if averageMood >= 7 {
            return "Your mood has been positive lately. Keep up the great work!"
        } else if averageMood >= 5 {
            return "You're making progress. Small steps lead to big changes."
        } else {
            return "Remember, it's okay to have tough days. What matters is showing up."
        }
    }

    // MARK: - Achievements Button
    private var achievementsButton: some View {
        Button(action: {
            showingAchievements = true
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AnalyticsPalette.accent.opacity(0.3), AnalyticsPalette.accentDeep.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AnalyticsPalette.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements")
                        .font(.quicksand(size: 16, weight: .bold))
                        .foregroundColor(AnalyticsPalette.primaryText(for: colorScheme))

                    Text("\(gameStatsManager.gameStats.unlockedAchievements.count) unlocked")
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AnalyticsPalette.secondaryText(for: colorScheme))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color(hex: "1C1C1E"),
                                Color(hex: "141416")
                            ] : [
                                Color.white,
                                Color(hex: "FFF8FA")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [AnalyticsPalette.accent.opacity(0.2), AnalyticsPalette.border(for: colorScheme)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: AnalyticsPalette.shadow(for: colorScheme), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Logic Helpers
    
    func loadAnalyticsData() async {
        await MainActor.run { isLoading = true }

        // Recalculate stats from actual entries to ensure accuracy
        await gameStatsManager.recalculateStatsFromEntries()
        gameStatsManager.reloadGameStats()
        await analyticsService.refreshAnalyticsData()

        await MainActor.run {
            let stats = gameStatsManager.gameStats
            currentStreak = stats.currentStreak
            totalEntries = stats.totalEntries
            averageMood = analyticsService.getWeeklyMoodAverage()
            monthlyTrend = analyticsService.getMoodTrend()
            activityTrend = analyticsService.getActivityTrend()
            totalActiveDays = analyticsService.getTotalActiveDays()
            isLoading = false
        }
    }
    
    func getActivityForDay(week: Int, day: Int) -> Int {
        let calendar = Calendar.current
        let daysAgo = week * 7 + (6 - day)
        let targetDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

        if let activity = analyticsService.activityHeatmap.first(where: {
            calendar.isDate($0.date, inSameDayAs: targetDate)
        }) {
            return activity.level
        }
        return 0
    }
}

#Preview {
    EnhancedAnalyticsView()
}
