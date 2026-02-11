//
//  EvaluationsModalView.swift
//  anxiety
//
//  Daily evaluations modal with bottom sheet presentation
//

import SwiftUI

// MARK: - Evaluations Theme Palette

private enum EvaluationsPalette {
    static let accent = Color(hex: "FF5C7A")
    static let accentSoft = Color(hex: "FF8FA3")

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color(hex: "F7F8FB")
    }

    static func surface(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1C") : Color.white
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : Color(hex: "1A1C23")
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color(hex: "4F5560")
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E3E6EE")
    }
}

struct EvaluationsModalView: View {
    @StateObject private var analysisService = JournalAnalysisService.shared
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedAnalysis: DailyJournalAnalysis?
    @State private var isCheckingForAnalysis = false
    @State private var showingEvaluationModal = false
    @State private var showNewEvaluationBanner = false
    @State private var newEvaluationText = ""

    var body: some View {
        ZStack {
            EvaluationsPalette.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Content
                if analysisService.analyses.isEmpty {
                    emptyStateView
                } else {
                    evaluationsList
                }
            }
        }
        .sheet(item: $selectedAnalysis) { analysis in
            AnalysisDetailViewSheet(analysis: analysis)
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingEvaluationModal) {
            GamifiedJournalEntryView()
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .onAppear {
            debugPrint("📊 EvaluationsModalView appeared, current analyses count: \(analysisService.analyses.count)")
            Task {
                await analysisService.loadEvaluationsFromDatabase()
                await MainActor.run {
                    debugPrint("📊 After reload, analyses count: \(analysisService.analyses.count)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("EvaluationCompleted"))) { notification in
            debugPrint("🎉 Evaluation completed notification received")
            
            // Show banner notification
            if let evaluation = notification.userInfo?["evaluation"] as? DailyJournalAnalysis {
                newEvaluationText = "New evaluation ready: \(evaluation.maturityDescription)"
                showNewEvaluationBanner = true
                
                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showNewEvaluationBanner = false
                }
            }
            
            // Reload evaluations
            Task {
                await analysisService.loadEvaluationsFromDatabase()
            }
        }
        .overlay(alignment: .top) {
            if showNewEvaluationBanner {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "FF5C7A"))

                        Text(newEvaluationText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(EvaluationsPalette.surface(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(EvaluationsPalette.border(for: colorScheme), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 80)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showNewEvaluationBanner)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(EvaluationsPalette.border(for: colorScheme))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(EvaluationsPalette.border(for: colorScheme), lineWidth: 1)
                                )

                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(EvaluationsPalette.accent)
                        }

                        Text("Insights")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                    }

                    Text("Your Evaluations")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                    Text("AI-powered insights from your journey")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                }

                Spacer()

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(EvaluationsPalette.surface(for: colorScheme))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle()
                                    .stroke(EvaluationsPalette.border(for: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : EvaluationsPalette.accent.opacity(0.1), radius: 6, x: 0, y: 3)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))
                    }
                }
            }

            if isCheckingForAnalysis || analysisService.isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FF5C7A")))
                        .scaleEffect(0.8)

                    Text(isCheckingForAnalysis ? "Analyzing..." : "Processing entries...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(EvaluationsPalette.surface(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(EvaluationsPalette.border(for: colorScheme), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var evaluationsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 18, pinnedViews: []) {
                ForEach(analysisService.analyses) { analysis in
                    EvaluationCard(analysis: analysis) {
                        selectedAnalysis = analysis
                    }
                    .id(analysis.id)
                    .drawingGroup()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyStateView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(EvaluationsPalette.surface(for: colorScheme))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(EvaluationsPalette.border(for: colorScheme), lineWidth: 1.5)
                        )
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.25) : EvaluationsPalette.accent.opacity(0.15), radius: 18, x: 0, y: 8)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(EvaluationsPalette.accent)
                }

                VStack(spacing: 16) {
                    Text("No Evaluations Yet")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                    Text("Start journaling today. After you submit your first entry, AI will analyze your emotional journey and provide personalized insights")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
            }

            VStack(spacing: 20) {
                // Start Journaling button
                Button(action: {
                    showingEvaluationModal = true
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            // Icon background with gradient
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.25), lineWidth: 1)
                                )
                            
                            // Enhanced icon
                            Image(systemName: "book.pages")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Journaling")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Begin your wellness journey")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "FF5C7A"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color(hex: "FF5C7A").opacity(0.4), radius: 18, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }


}

// MARK: - Evaluation Card Component (Simplified)

struct EvaluationCard: View {
    let analysis: DailyJournalAnalysis
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    private var primaryFocus: String? {
        analysis.growthAreas.first
    }

    private var statusColor: Color {
        Color(hex: analysis.maturityColor)
    }

    private var shortSummary: String {
        let words = analysis.summary.split(separator: " ").prefix(8)
        let text = words.joined(separator: " ")
        return words.count >= 8 ? text + "..." : text
    }

    private func extractFocusTitle(from text: String) -> String {
        if let colonIndex = text.firstIndex(of: ":") {
            let title = String(text[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            if title.count <= 25 {
                return title
            }
        }
        let words = text.split(separator: " ").prefix(3)
        return words.joined(separator: " ")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Score indicator
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    statusColor.opacity(0.16),
                                    statusColor.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: statusColor.opacity(0.25), radius: 8, x: 0, y: 4)

                    VStack(spacing: 0) {
                        Text("\(analysis.maturityScore)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(statusColor)
                        Text("/10")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(statusColor.opacity(0.7))
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center) {
                        Text(analysis.formattedDate)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                        Spacer()

                        Text(analysis.maturityDescription)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    Text(shortSummary)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                        .lineLimit(2)

                    if let focus = primaryFocus {
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "FF5C7A"))

                            Text(extractFocusTitle(from: focus))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme).opacity(0.75))
                                .lineLimit(1)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme).opacity(0.35))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        colorScheme == .dark ?
                        Color.white.opacity(0.04) :
                        Color(hex: "F8F8FA")
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.07), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalysisDetailViewSheet: View {
    let analysis: DailyJournalAnalysis
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    private var statusColor: Color {
        Color(hex: analysis.maturityColor)
    }

    private func extractKeyPoint(from text: String) -> String {
        let colonIndex = text.firstIndex(of: ":")
        if let colonIndex = colonIndex {
            let afterColon = text[text.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            if afterColon.count > 60 {
                let endIndex = afterColon.index(afterColon.startIndex, offsetBy: 57, limitedBy: afterColon.endIndex) ?? afterColon.endIndex
                return String(afterColon[..<endIndex]) + "..."
            }
            return String(afterColon)
        }
        if text.count > 80 {
            let endIndex = text.index(text.startIndex, offsetBy: 77, limitedBy: text.endIndex) ?? text.endIndex
            return String(text[..<endIndex]) + "..."
        }
        return text
    }

    private func extractTitle(from text: String) -> String? {
        if let colonIndex = text.firstIndex(of: ":") {
            let title = String(text[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            if title.count <= 30 {
                return title
            }
        }
        return nil
    }

    private var snapshotSection: some View {
        HStack(spacing: 12) {
            compactMetricCard(
                icon: "chart.bar.fill",
                value: "\(analysis.maturityScore)/10",
                label: "Score",
                color: statusColor
            )

            compactMetricCard(
                icon: "leaf.fill",
                value: analysis.maturityDescription,
                label: "State",
                color: statusColor
            )

            compactMetricCard(
                icon: "doc.text.fill",
                value: "\(analysis.entryCount)",
                label: "Entries",
                color: EvaluationsPalette.secondaryText(for: colorScheme)
            )
        }
    }

    @ViewBuilder
    private func compactMetricCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color(hex: "FFF3F9"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08), lineWidth: 1)
                )
        )
    }

    private var summaryHighlights: [String] {
        let sentences = analysis.summary.components(separatedBy: ". ")
        return Array(sentences.prefix(2)).map { sentence in
            var s = sentence.trimmingCharacters(in: .whitespaces)
            if !s.hasSuffix(".") { s += "." }
            return s
        }
    }

    var body: some View {
        ZStack {
            EvaluationsPalette.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Compact header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(analysis.formattedDate)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))
                    }

                    Spacer()

                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(EvaluationsPalette.surface(for: colorScheme))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        snapshotSection

                        // Themes at the top as context
                        if !analysis.emotionalThemes.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(analysis.emotionalThemes.prefix(4), id: \.self) { theme in
                                Text(theme)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme).opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : EvaluationsPalette.accent.opacity(0.08))
                                        )
                                }
                            }
                        }

                        // Summary - condensed to key points
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Summary")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                .textCase(.uppercase)
                                .kerning(0.6)

                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(summaryHighlights, id: \.self) { point in
                                    HStack(alignment: .top, spacing: 8) {
                                        Circle()
                                            .fill(Color(hex: "FF5C7A"))
                                            .frame(width: 4, height: 4)
                                            .padding(.top, 7)

                                        Text(point)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))
                                            .lineSpacing(3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color(hex: "FAFAFC"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08), lineWidth: 1)
                                )
                        )

                        // Focus Areas - compact actionable cards
                        if !analysis.growthAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Focus Areas")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                        .textCase(.uppercase)
                                        .kerning(0.6)

                                    Spacer()

                                    Text("\(analysis.growthAreas.count) areas")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme).opacity(0.7))
                                }

                                VStack(spacing: 10) {
                                    ForEach(Array(analysis.growthAreas.enumerated()), id: \.offset) { index, area in
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: "FF5C7A").opacity(0.12))
                                                    .frame(width: 32, height: 32)

                                                Text("\(index + 1)")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(Color(hex: "FF5C7A"))
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                if let title = extractTitle(from: area) {
                                                    Text(title)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                                                    Text(extractKeyPoint(from: area))
                                                        .font(.system(size: 13, weight: .regular))
                                                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                                        .lineLimit(2)
                                                } else {
                                                    Text(extractKeyPoint(from: area))
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))
                                                        .lineLimit(2)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme).opacity(0.4))
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color(hex: "FFF2F8"))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // Quick action card
                        if let _ = analysis.growthAreas.first {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "4CAF50").opacity(0.12))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "4CAF50"))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Quick Win")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(EvaluationsPalette.primaryText(for: colorScheme))

                                    Text("Try 2 min of breathing, a short walk, or message someone")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                        .lineLimit(2)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(colorScheme == .dark ? Color(hex: "4CAF50").opacity(0.08) : Color(hex: "E8F5E9"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color(hex: "4CAF50").opacity(0.15), lineWidth: 1)
                                    )
                            )
                        }

                        // Patterns - compact list
                        if !analysis.keyInsights.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Patterns")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                    .textCase(.uppercase)
                                    .kerning(0.6)

                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(analysis.keyInsights.prefix(3), id: \.self) { insight in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "arrow.turn.down.right")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme).opacity(0.6))
                                                .padding(.top, 4)

                                            Text(extractKeyPoint(from: insight))
                                                .font(.system(size: 13, weight: .regular))
                                                .foregroundColor(EvaluationsPalette.secondaryText(for: colorScheme))
                                                .lineLimit(2)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color(hex: "FAFAFC"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.white.opacity(colorScheme == .dark ? 0.04 : 0.08), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: currentY + lineHeight)
            self.positions = positions
        }
    }
}

#Preview {
    EvaluationsModalView()
}
