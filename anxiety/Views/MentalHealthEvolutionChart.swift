//
//  MentalHealthEvolutionChart.swift
//  anxiety
//
//  Created by Ján Harmady on 02/09/2025.
//

import SwiftUI

struct MentalHealthEvolutionChart: View {
    let dataPoints: [MentalHealthDataPoint]
    let selectedPeriod: MentalHealthTrend.TimePeriod
    
    @State private var selectedMetric: HealthMetric = .mood
    @State private var showingTrendAnalysis = false
    
    enum HealthMetric: String, CaseIterable {
        case mood = "Mood"
        case anxiety = "Anxiety"
        case stress = "Stress"
        case wellness = "Overall Wellness"
        
        var color: Color {
            switch self {
            case .mood: return AdaptiveColors.Action.mood
            case .anxiety: return AdaptiveColors.Action.sos.opacity(0.7)
            case .stress: return Color(hex: "FF6B35")
            case .wellness: return AdaptiveColors.Action.progress
            }
        }
        
        var icon: String {
            switch self {
            case .mood: return "heart.fill"
            case .anxiety: return "brain.head.profile"
            case .stress: return "exclamationmark.triangle.fill"
            case .wellness: return "leaf.fill"
            }
        }
    }
    
    var body: some View {
        TherapeuticCard(elevation: .elevated) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                // Metric Selector
                metricSelector
                
                // Chart
                if !dataPoints.isEmpty {
                    chartSection
                } else {
                    emptyStateView
                }
                
                // Insights
                insightsSection
            }
            .padding(20)
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mental Health Evolution")
                    .font(.quicksand(size: 20, weight: .bold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text("Track your wellness journey over time")
                    .font(.quicksand(size: 14, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            
            Spacer()
            
            Button(action: { showingTrendAnalysis = true }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Action.progress)
            }
        }
    }
    
    private var metricSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HealthMetric.allCases, id: \.self) { metric in
                    MetricButton(
                        metric: metric,
                        isSelected: selectedMetric == metric,
                        action: { selectedMetric = metric }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Title
            HStack {
                Image(systemName: selectedMetric.icon)
                    .font(.quicksand(size: 16))
                    .foregroundColor(selectedMetric.color)
                
                Text(selectedMetric.rawValue + " Trend")
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Spacer()
                
                Text(selectedPeriod.displayName)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            
            // Simple Chart Placeholder (would need Charts framework for full implementation)
            VStack(spacing: 16) {
                HStack {
                    Text("Chart visualization")
                        .font(.quicksand(size: 14, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                    Spacer()
                    Text("Requires Charts framework")
                        .font(.quicksand(size: 12, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary.opacity(0.7))
                }
                
                // Simple visual representation
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedMetric.color.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.quicksand(size: 32))
                                .foregroundColor(selectedMetric.color.opacity(0.5))
                            
                            Text("Mental Health Trend")
                                .font(.quicksand(size: 14, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                        }
                    )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.quicksand(size: 48))
                .foregroundColor(AdaptiveColors.Text.secondary.opacity(0.5))
            
            Text("Start Your Journey")
                .font(.quicksand(size: 18, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            Text("Journal regularly to see your mental health evolution")
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Insights")
                .font(.quicksand(size: 16, weight: .semibold))
                .foregroundColor(AdaptiveColors.Text.primary)
            
            if !dataPoints.isEmpty {
                let insights = generateInsights()
                
                ForEach(insights, id: \.title) { insight in
                    InsightRow(insight: insight)
                }
            } else {
                Text("Complete more journal entries to unlock personalized insights")
                    .font(.quicksand(size: 13, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
        }
    }
    
    private func getValueForMetric(_ dataPoint: MentalHealthDataPoint, metric: HealthMetric) -> Double {
        switch metric {
        case .mood: return dataPoint.moodScore
        case .anxiety: return 11 - dataPoint.anxietyLevel // Invert so higher is better
        case .stress: return 11 - dataPoint.stressLevel // Invert so higher is better
        case .wellness: return calculateWellnessScore(dataPoint)
        }
    }
    
    private func calculateWellnessScore(_ dataPoint: MentalHealthDataPoint) -> Double {
        let moodWeight = 0.4
        let anxietyWeight = 0.3
        let stressWeight = 0.3
        
        let invertedAnxiety = 11 - dataPoint.anxietyLevel
        let invertedStress = 11 - dataPoint.stressLevel
        
        return (dataPoint.moodScore * moodWeight) +
               (invertedAnxiety * anxietyWeight) +
               (invertedStress * stressWeight)
    }
    
    private func generateInsights() -> [MentalHealthInsight] {
        guard dataPoints.count >= 2 else { return [] }
        
        var insights: [MentalHealthInsight] = []
        
        let recentData = Array(dataPoints.suffix(7)) // Last week
        let averageMood = recentData.map(\.moodScore).reduce(0, +) / Double(recentData.count)
        
        if averageMood >= 7.0 {
            insights.append(MentalHealthInsight(
                title: "Positive Trend",
                description: "Your mood has been consistently good this week",
                icon: "arrow.up.heart.fill",
                color: AdaptiveColors.Action.progress
            ))
        } else if averageMood <= 4.0 {
            insights.append(MentalHealthInsight(
                title: "Support Available",
                description: "Consider reaching out for additional support",
                icon: "hand.raised.fill",
                color: AdaptiveColors.Action.sos.opacity(0.7)
            ))
        }
        
        // Streak insight
        insights.append(MentalHealthInsight(
            title: "Tracking Streak",
            description: "You've logged \(dataPoints.count) journal entries",
            icon: "flame.fill",
            color: AdaptiveColors.Action.mood
        ))
        
        return insights
    }
}

// MARK: - Supporting Views

struct MetricButton: View {
    let metric: MentalHealthEvolutionChart.HealthMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.quicksand(size: 12))
                
                Text(metric.rawValue)
                    .font(.quicksand(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : metric.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ? metric.color : metric.color.opacity(0.1)
            )
            .cornerRadius(20)
        }
    }
}

struct MentalHealthInsight {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct InsightRow: View {
    let insight: MentalHealthInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.quicksand(size: 14))
                .foregroundColor(insight.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.quicksand(size: 13, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Text.primary)
                
                Text(insight.description)
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleData = [
        MentalHealthDataPoint(
            date: Date().addingTimeInterval(-7*24*60*60),
            moodScore: 6.0,
            anxietyLevel: 4.0,
            stressLevel: 5.0,
            gratitudeCount: 3,
            wordCount: 200,
            reflectionQuality: 7.0
        ),
        MentalHealthDataPoint(
            date: Date().addingTimeInterval(-5*24*60*60),
            moodScore: 7.5,
            anxietyLevel: 3.0,
            stressLevel: 4.0,
            gratitudeCount: 4,
            wordCount: 250,
            reflectionQuality: 8.0
        ),
        MentalHealthDataPoint(
            date: Date().addingTimeInterval(-3*24*60*60),
            moodScore: 8.0,
            anxietyLevel: 2.5,
            stressLevel: 3.0,
            gratitudeCount: 5,
            wordCount: 300,
            reflectionQuality: 8.5
        )
    ]
    
    MentalHealthEvolutionChart(
        dataPoints: sampleData,
        selectedPeriod: .week
    )
}