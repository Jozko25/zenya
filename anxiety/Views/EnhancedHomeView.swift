//
//  EnhancedHomeView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct EnhancedHomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var analysisService = JournalAnalysisService.shared
    @StateObject private var homeCache = HomeStateCache.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var energyState: EnergyState = .balanced
    @State private var showingRegulation = false
    @State private var showingJournalList = false
    @State private var showingEvaluations = false
    @State private var showingNewEntry = false
    @State private var showingSOSSupport = false
    @State private var pulseAnimation = false
    @State private var showingProfile = false

    // Real Data State
    @State private var rhythmData: [Double] = [] // Last 7 days mood
    @State private var isLoadingData = false

    // Reflection Progress (max 4 reflections per day)
    private let maxDailyReflections: Double = 4.0
    @State private var todayReflectionCount: Int = 0
    @State private var reflectionProgress: Double = 0.0  // 0.0 to 1.0 animated value

    // Theme Colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color(hex: "F8F8FA")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(hex: "1A1A1A")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "666666")
    }

    private var cardBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E8E8EA")
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning."
        } else if hour < 17 {
            return "Good afternoon."
        } else {
            return "Good evening."
        }
    }


    
    var body: some View {
        ZStack {
            // Clean background
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Header
                    headerSection
                        .padding(.top, 20)

                    // Main Circular Widget
                    mainCircularWidget
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)

                    // Action Buttons (Reflect + Evaluations)
                    HStack(spacing: 16) {
                        reflectButton

                        Button(action: { showingEvaluations = true }) {
                            Circle()
                                .fill(cardBackgroundColor)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "chart.xyaxis.line")
                                        .font(.quicksand(size: 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF5C7A"))
                                )
                                .overlay(
                                    Circle()
                                        .stroke(cardBorderColor, lineWidth: 1)
                                )
                                .shadow(
                                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "FF5C7A").opacity(0.15),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        }
                        .accessibilityLabel("Evaluations")
                        .accessibilityHint("View your mood evaluations and progress")
                    }

                    // Rhythm Graph
                    rhythmGraph

                    // Quick Actions Grid (without Evaluations)
                    quickActionsGridWithoutEvaluations
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for bottom bar
            }
        }
        .onAppear {
            // Use cached state immediately if available
            if let cachedState = homeCache.cachedEnergyState {
                energyState = cachedState
            }
            if let cachedRhythm = homeCache.cachedRhythmData {
                rhythmData = cachedRhythm
            }
            if let cachedCount = homeCache.cachedReflectionCount {
                todayReflectionCount = cachedCount
                let targetProgress = min(Double(cachedCount) / maxDailyReflections, 1.0)
                reflectionProgress = targetProgress
            }

            // Only fetch fresh data if cache is stale
            if homeCache.shouldRefresh {
                loadRhythmData()
                loadTodaysReflections()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("JournalEntrySubmitted"))) { _ in
            // Force refresh when a new entry is submitted
            homeCache.markNeedsRefresh()
            loadTodaysReflections()
            loadRhythmData()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EvaluationCompleted"))) { _ in
            // Force refresh when AI analysis finishes
            debugPrint("🤖 AI Analysis complete - refreshing graph")
            homeCache.markNeedsRefresh()
            loadRhythmData()
        }
        .onChange(of: databaseService.currentUser?.id) { oldValue, newValue in
            if newValue != nil && oldValue != newValue {
                debugPrint("👤 User loaded/changed, fetching rhythm data...")
                homeCache.clearCache()
                loadRhythmData()
                loadTodaysReflections()
            }
        }
        .sheet(isPresented: $showingRegulation) {
            EmergencyBreathingView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingJournalList) {
            JournalListModalView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingEvaluations) {
            EvaluationsModalView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileView()
        }
        .fullScreenCover(isPresented: $showingSOSSupport) {
            SOSSupportView()
        }
        .sheet(isPresented: $showingNewEntry) {
            GamifiedJournalEntryView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Data Loading
    private func loadRhythmData() {
        guard let userId = databaseService.currentUser?.id else {
            debugPrint("⏳ loadRhythmData: Waiting for user...")
            // Retry after a short delay if user not loaded yet
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                await MainActor.run {
                    if databaseService.currentUser?.id != nil {
                        loadRhythmData()
                    }
                }
            }
            return
        }
        isLoadingData = true

        Task {
            // 1. Ensure we have the latest evaluations loaded
            await analysisService.loadEvaluations()

            // 2. Fetch recent entries (fallback)
            let entries = await databaseService.getRecentEntries(userId: userId.uuidString, limit: 20)

            // 3. Process data for last 7 days
            let calendar = Calendar.current
            var dailyScores: [Double] = []
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for i in (0..<7).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    var dayScore: Double = 0
                    let dayString = dateFormatter.string(from: date)

                    // Priority A: Check for Evaluation Maturity Score (from analysis)
                    if let analysis = analysisService.analyses.first(where: {
                        let anaString = dateFormatter.string(from: $0.date)
                        return anaString == dayString
                    }) {
                        dayScore = Double(analysis.maturityScore)
                    }
                    // Priority B: Fallback to direct mood entry
                    else {
                        let dayEntries = entries.filter {
                            let entryString = dateFormatter.string(from: $0.createdAt)
                            return entryString == dayString
                        }

                        if let validMoodEntry = dayEntries.first(where: { $0.mood != nil }), let mood = validMoodEntry.mood {
                            dayScore = Double(mood)
                        }
                        // Priority C: Placeholder if entries exist but no evaluation yet
                        else if !dayEntries.isEmpty {
                            dayScore = 5.0
                        }
                    }

                    dailyScores.append(dayScore)
                }
            }


            await MainActor.run {
                self.rhythmData = dailyScores
                self.isLoadingData = false
                let newState = calculateEnergyState(from: dailyScores)
                self.energyState = newState

                // Update cache
                homeCache.updateEnergyState(newState)
                homeCache.updateRhythmData(dailyScores)
            }
        }
    }

    /// Calculate energy state based on recent mood data
    private func calculateEnergyState(from data: [Double]) -> EnergyState {
        // Filter out zero values (days with no data)
        let validData = data.filter { $0 > 0 }

        guard !validData.isEmpty else {
            return .elevated // Default when no data
        }

        // Calculate average mood (1-10 scale where higher = better mood/lower anxiety)
        let average = validData.reduce(0, +) / Double(validData.count)

        // Map mood score to energy state
        // Higher mood = calmer state, Lower mood = more elevated/anxious
        switch average {
        case 8...10:
            return .calm
        case 6..<8:
            return .balanced
        case 4..<6:
            return .elevated
        default:
            return .high
        }
    }
    
    /// Load today's reflection count and animate the progress ring
    private func loadTodaysReflections() {
        guard let userId = databaseService.currentUser?.id else {
            debugPrint("⚠️ loadTodaysReflections: No user ID yet, retrying in 0.5s")
            // Retry after a short delay if user not loaded yet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadTodaysReflections()
            }
            return
        }
        
        Task {
            let entries = await databaseService.getRecentEntries(userId: userId.uuidString, limit: 20)
            let calendar = Calendar.current
            
            // Count today's entries
            let todaysEntries = entries.filter { calendar.isDateInToday($0.createdAt) }
            let count = todaysEntries.count
            
            debugPrint("📊 loadTodaysReflections: Found \(entries.count) total, \(count) today")
            
            await MainActor.run {
                todayReflectionCount = count

                // Update cache
                homeCache.updateReflectionCount(count)

                // Only animate if the count changed significantly
                let targetProgress = min(Double(count) / maxDailyReflections, 1.0)
                let shouldAnimate = abs(reflectionProgress - targetProgress) > 0.01

                if shouldAnimate {
                    // Animate progress with "pull" effect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100.0, damping: 12.0, initialVelocity: 0)) {
                            reflectionProgress = targetProgress
                        }

                        // Trigger haptics if we have progress
                        if count > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                            }
                        }
                    }
                } else {
                    reflectionProgress = targetProgress
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                // Personalized greeting with name from UserDefaults (saved during onboarding)
                if let userName = UserDefaults.standard.string(forKey: "user_name"),
                   !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   userName != "Friend" {
                    (Text(timeBasedGreeting.replacingOccurrences(of: ".", with: ","))
                        .font(.quicksand(size: 26, weight: .medium))
                        .foregroundColor(primaryTextColor)
                    + Text(" \(userName.split(separator: " ").first.map(String.init) ?? userName)")
                        .font(.quicksand(size: 26, weight: .medium))
                        .foregroundColor(Color(hex: "FF5C7A")))
                } else {
                    Text(timeBasedGreeting)
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(primaryTextColor)
                }

                // Dynamic subtitle based on reflection count
                Text(dynamicSubtitle)
                    .font(.quicksand(size: 15, weight: .regular))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Button {
                showingProfile = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "161616"),
                                    Color(hex: "1F1F21")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)

                    Image(systemName: "person.fill")
                        .font(.quicksand(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "FF5C7A"))
                }
                .overlay(
                    Circle()
                        .stroke(cardBorderColor, lineWidth: 1)
                )
            }
            .accessibilityLabel("Profile")
            .accessibilityHint("Opens your profile settings")
        }
    }

    private var dynamicSubtitle: String {
        switch todayReflectionCount {
        case 0:
            return "Ready to check in with yourself?"
        case 1:
            return "Great start! Your energy is shifting."
        case 2:
            return "You're building momentum."
        case 3:
            return "Almost at your daily goal!"
        default:
            return "You're on a reflection streak!"
        }
    }

    // MARK: - Main Circular Widget
    private var mainCircularWidget: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let phase = computeBlobPhase(from: timeline.date)
            let isDark = colorScheme == .dark

            ZStack {
                // Morphing Organic Blob with animation - smooth edges
                ZStack {
                    // Layer 1: Outer ambient glow - very soft and diffuse
                    BlobShape(phase: phase, complexity: 0.6)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FF5C7A").opacity(isDark ? 0.12 : 0.18),
                                    Color(hex: "FF5C7A").opacity(isDark ? 0.06 : 0.12),
                                    Color(hex: "FF2E50").opacity(isDark ? 0.02 : 0.06),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 200
                            )
                        )
                        .frame(width: 350, height: 350)
                        .blur(radius: 50)

                    // Layer 2: Main blob body - visible morphing
                    BlobShape(phase: phase * 1.3, complexity: 0.8)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FF8FA3").opacity(isDark ? 0.95 : 0.85),
                                    Color(hex: "FF5C7A").opacity(isDark ? 0.85 : 0.75),
                                    Color(hex: "D94467").opacity(isDark ? 0.6 : 0.4),
                                    Color(hex: "D94467").opacity(isDark ? 0.2 : 0.12)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)

                    // Layer 3: Inner core highlight - subtle movement
                    BlobShape(phase: phase * 0.7, complexity: 0.5)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "FFAABB").opacity(isDark ? 0.85 : 0.7),
                                    Color(hex: "FF8FA3").opacity(isDark ? 0.5 : 0.4),
                                    Color(hex: "FF8FA3").opacity(isDark ? 0.15 : 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                }
                .compositingGroup()
                .drawingGroup()
                .allowsHitTesting(false)

                // Text Overlay
                VStack(spacing: 6) {
                    Text("Current State")
                        .font(.quicksand(size: 11, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .tracking(1.8)
                        .textCase(.uppercase)

                    Text(energyState.rawValue)
                        .font(.quicksand(size: 36, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                }
            }
            .frame(width: 300, height: 300)
        }
    }

    // Compute blob phase based on elapsed time - truly continuous, no resets
    private func computeBlobPhase(from date: Date) -> Double {
        // 12 degrees per second = 30 second full cycle (slower, smoother)
        let elapsed = date.timeIntervalSinceReferenceDate
        return (elapsed * 12.0).truncatingRemainder(dividingBy: 360)
    }

    // MARK: - Reflect Button (Replaces Regulate Now)
    private var reflectButton: some View {
        Button(action: {
            showingNewEntry = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 16, weight: .semibold))

                Text("Reflect")
                    .font(.quicksand(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 170, height: 52)
            .background(
                ZStack {
                    // Base shadow layer for lift
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                        .offset(y: 4)
                        .blur(radius: 3)

                    // Main gradient body (darker, less purple)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FF6363"),
                                    Color(hex: "FF4E6A"),
                                    Color(hex: "C73F55")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)

                    // Specular highlight
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )

                    // Inner glow for depth
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(4)
                        .blendMode(.screen)
                }
            )
            .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 10)
        }
        .accessibilityLabel("Reflect")
        .accessibilityHint("Start a new journal reflection")
    }

    // MARK: - Rhythm Graph (Real Data)
    private var rhythmGraph: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Today's Rhythm")
                    .font(.quicksand(size: 16, weight: .medium))
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text("Last 7 Days")
                    .font(.quicksand(size: 12, weight: .regular))
                    .foregroundColor(secondaryTextColor)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark ? [
                                Color(hex: "1A1A1C"),
                                Color(hex: "121214")
                            ] : [
                                Color.white,
                                Color(hex: "FFF8FA")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(cardBorderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.clear : Color(hex: "FF5C7A").opacity(0.1),
                        radius: 10,
                        x: 0,
                        y: 5
                    )

                if isLoadingData {
                    ProgressView()
                        .tint(colorScheme == .dark ? .white : Color(hex: "FF5C7A"))
                } else {
                    // Graph Container - always show graph view
                    let displayData = rhythmData.isEmpty || rhythmData.allSatisfy({ $0 == 0 })
                        ? [5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0] // Flat line placeholder
                        : rhythmData
                    let hasRealData = !rhythmData.isEmpty && !rhythmData.allSatisfy({ $0 == 0 })

                    VStack(spacing: 8) {
                        ZStack(alignment: .leading) {
                            // Y-Axis Scale
                            VStack {
                                Text("High")
                                Spacer()
                                Text("Low")
                            }
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                            .padding(.vertical, 8)

                            // Graph
                            ZStack {
                                // Horizontal grid lines
                                VStack {
                                    ForEach(0..<3) { _ in
                                        Divider()
                                            .background(secondaryTextColor.opacity(0.2))
                                        Spacer()
                                    }
                                    Divider()
                                        .background(secondaryTextColor.opacity(0.2))
                                }

                                // Graph Line - only show when there's real data
                                if hasRealData {
                                    DataWaveShape(dataPoints: displayData)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FF8FA3").opacity(0.5),
                                                    Color(hex: "FF5C7A"),
                                                    Color(hex: "FF8FA3").opacity(0.5)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                                        )

                                    // Fill below graph
                                    DataWaveShape(dataPoints: displayData, closePath: true)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FF5C7A").opacity(0.15),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                }
                            }
                            .frame(height: 70)
                            .padding(.leading, 30) // Make room for Y-Axis labels
                        }

                        // X-Axis Labels
                        HStack {
                            ForEach(getLast7DaysLabels(), id: \.self) { day in
                                Text(day)
                                    .font(.quicksand(size: 11, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.leading, 30) // Align with graph
                    }
                    .padding(16)
                }
            }
            .frame(height: 160) // Increased height for labels
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
    
    // Helper for X-Axis Labels
    private func getLast7DaysLabels() -> [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, Wed
        
        var days: [String] = []
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                days.append(formatter.string(from: date))
            }
        }
        return days
    }
    
    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Progress / Evaluations (Prominent)
                quickActionCard(
                    icon: "chart.xyaxis.line",
                    title: "Progress",
                    subtitle: "View evaluations",
                    color: Color(hex: "FF5C7A"),
                    action: { showingEvaluations = true }
                )

                // Breathe
                quickActionCard(
                    icon: "wind",
                    title: "Breathe",
                    subtitle: "Quick calm",
                    color: Color(hex: "FF8FA3"),
                    action: { showingRegulation = true }
                )
            }

            HStack(spacing: 12) {
                // SOS (Important)
                quickActionCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "SOS",
                    subtitle: "Get help now",
                    color: Color(hex: "FF2E50"),
                    action: { showingSOSSupport = true }
                )
                
                // Placeholder for balance
                quickActionCard(
                    icon: "heart.fill",
                    title: "Heart",
                    subtitle: "Connect",
                    color: Color(hex: "A34865"),
                    action: { selectedTab = 1 } // Switch to Heart tab
                )
            }
        }
    }

    // MARK: - Quick Actions Grid Without Evaluations
    private var quickActionsGridWithoutEvaluations: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Breathe
                quickActionCard(
                    icon: "wind",
                    title: "Breathe",
                    subtitle: "Quick calm",
                    color: Color(hex: "FF8FA3"),
                    action: { showingRegulation = true }
                )

                // SOS (Important)
                quickActionCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "SOS",
                    subtitle: "Get help now",
                    color: Color(hex: "FF2E50"),
                    action: { showingSOSSupport = true }
                )
            }

            HStack(spacing: 12) {
                // Heart tab
                quickActionCard(
                    icon: "heart.fill",
                    title: "Heart",
                    subtitle: "Connect",
                    color: Color(hex: "A34865"),
                    action: { selectedTab = 1 }
                )

                // Journal list
                quickActionCard(
                    icon: "book.fill",
                    title: "Journal",
                    subtitle: "Past entries",
                    color: Color(hex: "FF5C7A"),
                    action: { showingJournalList = true }
                )
            }
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                // Icon with gradient ring
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.5),
                                    color.opacity(0.15),
                                    color.opacity(0.35),
                                    color.opacity(0.1),
                                    color.opacity(0.5)
                                ]),
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 42, height: 42)
                        .blur(radius: 0.5)
                    
                    // Inner circle
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.12 : 0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryTextColor)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(secondaryTextColor.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        colorScheme == .dark ?
                        Color(hex: "161618") :
                        Color.white
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: colorScheme == .dark ? [
                                        color.opacity(0.2),
                                        color.opacity(0.05)
                                    ] : [
                                        color.opacity(0.25),
                                        color.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(QuickActionButtonStyle(color: color))
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

// Premium button style with press animation
private struct QuickActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shapes

struct BlobShape: Shape {
    var phase: Double
    var complexity: Double = 1.0

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let points = 16
        let angleStep = (Double.pi * 2) / Double(points)
        // Convert phase to radians - use full 2*pi for seamless looping
        let normalizedPhase = (phase / 360.0) * (Double.pi * 2)

        var pathPoints: [CGPoint] = []

        for i in 0..<points {
            let angle = Double(i) * angleStep

            // Use integer multipliers that ensure full cycles when phase goes 0 to 2*pi
            // All multipliers are integers so sin/cos complete full cycles
            let offset1 = Foundation.sin(Double(i) * 0.8 + normalizedPhase * 2.0) * 20
            let offset2 = Foundation.cos(Double(i) * 1.3 + normalizedPhase * 3.0) * 16
            let offset3 = Foundation.sin(Double(i) * 2.1 + normalizedPhase * 4.0) * 12
            let offset4 = Foundation.cos(Double(i) * 0.5 + normalizedPhase * 5.0) * 10

            let totalOffset = (offset1 + offset2 + offset3 + offset4) * complexity

            let r = radius + totalOffset

            let x = center.x + Foundation.cos(angle) * r
            let y = center.y + Foundation.sin(angle) * r

            pathPoints.append(CGPoint(x: x, y: y))
        }

        guard !pathPoints.isEmpty else { return path }

        path.move(to: pathPoints[0])

        for i in 0..<pathPoints.count {
            let current = pathPoints[i]
            let next = pathPoints[(i + 1) % pathPoints.count]

            // More organic control points with integer phase multipliers
            let distance = Foundation.sqrt(Foundation.pow(next.x - current.x, 2) + Foundation.pow(next.y - current.y, 2))
            let controlDistance = distance * 0.4

            let angle1 = Foundation.atan2(next.y - current.y, next.x - current.x)
            let perpAngle1 = angle1 + .pi / 2

            // Use integer multipliers for seamless looping
            let waveOffset1 = Foundation.sin(Double(i) * 1.5 + normalizedPhase * 2.0) * 6
            let waveOffset2 = Foundation.cos(Double(i) * 1.8 + normalizedPhase * 3.0) * 5

            let control1 = CGPoint(
                x: current.x + Foundation.cos(angle1) * controlDistance + Foundation.cos(perpAngle1) * waveOffset1,
                y: current.y + Foundation.sin(angle1) * controlDistance + Foundation.sin(perpAngle1) * waveOffset1
            )

            let control2 = CGPoint(
                x: next.x - Foundation.cos(angle1) * controlDistance + Foundation.cos(perpAngle1) * waveOffset2,
                y: next.y - Foundation.sin(angle1) * controlDistance + Foundation.sin(perpAngle1) * waveOffset2
            )

            path.addCurve(to: next, control1: control1, control2: control2)
        }

        path.closeSubpath()
        return path
    }
}

struct DataWaveShape: Shape {
    var dataPoints: [Double]
    var closePath: Bool = false
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        guard !dataPoints.isEmpty else { return path }
        
        let stepX = width / CGFloat(dataPoints.count - 1)
        
        // Normalize data to fit height (0-10 scale assumed)
        let points = dataPoints.enumerated().map { index, value in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: height - (CGFloat(value) / 10.0 * height)
            )
        }
        
        if let first = points.first {
            path.move(to: first)
            
            for i in 1..<points.count {
                let p1 = points[i-1]
                let p2 = points[i]
                let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                
                path.addQuadCurve(to: mid, control: CGPoint(x: (p1.x + mid.x) / 2, y: p1.y))
                path.addQuadCurve(to: p2, control: CGPoint(x: (mid.x + p2.x) / 2, y: p2.y))
            }
        }
        
        if closePath {
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Energy State

enum EnergyState: String {
    case calm = "Calm"
    case balanced = "Balanced"
    case elevated = "Elevated"
    case high = "High"
}

// MARK: - Preview
#Preview {
    EnhancedHomeView(selectedTab: .constant(0))
}
