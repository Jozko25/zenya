//
//  JournalModels.swift
//  anxiety
//
//  Created for Daily Journal Prompts System
//

import Foundation
import SwiftUI

// MARK: - Journal Prompt Model
struct JournalPrompt: Identifiable, Codable {
    let id: UUID
    let questionText: String
    let category: PromptCategory
    let difficultyLevel: DifficultyLevel
    let followUpQuestion: String?
    let createdAt: Date
    let updatedAt: Date
    let isActive: Bool
    
    enum PromptCategory: String, Codable, CaseIterable {
        case reflection = "reflection"
        case gratitude = "gratitude"
        case emotions = "emotions"
        case goals = "goals"
        case growth = "growth"
        case relationships = "relationships"
        case selfCare = "self-care"
        case joy = "joy"
        case creativity = "creativity"
        
        var displayName: String {
            switch self {
            case .reflection: return "Reflection"
            case .gratitude: return "Gratitude"
            case .emotions: return "Emotions"
            case .goals: return "Goals"
            case .growth: return "Growth"
            case .relationships: return "Relationships"
            case .selfCare: return "Self-Care"
            case .joy: return "Joy"
            case .creativity: return "Creativity"
            }
        }
        
        var icon: String {
            switch self {
            case .reflection: return "moon.stars"
            case .gratitude: return "heart.fill"
            case .emotions: return "heart.text.square"
            case .goals: return "target"
            case .growth: return "arrow.up.circle"
            case .relationships: return "person.2.fill"
            case .selfCare: return "leaf.fill"
            case .joy: return "sparkles"
            case .creativity: return "paintbrush.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .reflection: return Color(hex: "9B7EDE")
            case .gratitude: return Color(hex: "F4A460")
            case .emotions: return Color(hex: "FFB6C1")
            case .goals: return Color(hex: "7DB46C")
            case .growth: return Color(hex: "32CD32")
            case .relationships: return Color(hex: "87CEEB")
            case .selfCare: return Color(hex: "DDA0DD")
            case .joy: return Color(hex: "FFD700")
            case .creativity: return Color(hex: "FF69B4")
            }
        }
    }
    
    enum DifficultyLevel: String, Codable {
        case easy = "easy"
        case medium = "medium"
        case deep = "deep"
        
        var displayName: String {
            switch self {
            case .easy: return "Light"
            case .medium: return "Thoughtful"
            case .deep: return "Deep Dive"
            }
        }
    }
}

// MARK: - Daily Prompts Model
struct DailyPrompts: Identifiable, Codable {
    let id: UUID
    let date: Date
    let prompt1Id: UUID
    let prompt2Id: UUID
    let createdAt: Date
    
    // Computed properties for the actual prompts (fetched separately)
    var prompt1: JournalPrompt?
    var prompt2: JournalPrompt?
}

// MARK: - Journal Response Model
struct JournalResponse: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let promptId: UUID
    let date: Date
    var responseText: String
    var moodAtTime: String?
    var wordCount: Int
    var sentimentScore: Float?
    var keyThemes: [String]
    let createdAt: Date
    var updatedAt: Date
    var isComplete: Bool
    var timeSpentSeconds: Int?
    
    // Associated prompt (fetched separately)
    var prompt: JournalPrompt?
    
    // Computed properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var sentimentEmoji: String {
        guard let score = sentimentScore else { return "😐" }
        switch score {
        case ..<(-0.5): return "😢"
        case -0.5..<(-0.2): return "😔"
        case -0.2..<0.2: return "😐"
        case 0.2..<0.5: return "🙂"
        default: return "😊"
        }
    }
}

// MARK: - Journal Insight Model
struct JournalInsight: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let insightType: InsightType
    let insightText: String
    let dataPoints: [String: String]? // Changed from Any to String for Codable
    let periodStart: Date?
    let periodEnd: Date?
    let createdAt: Date
    var isViewed: Bool
    
    enum InsightType: String, Codable {
        case weeklySummary = "weekly_summary"
        case moodPattern = "mood_pattern"
        case themeAnalysis = "theme_analysis"
        case growthArea = "growth_area"
        
        var displayName: String {
            switch self {
            case .weeklySummary: return "Weekly Summary"
            case .moodPattern: return "Mood Pattern"
            case .themeAnalysis: return "Theme Analysis"
            case .growthArea: return "Growth Area"
            }
        }
        
        var icon: String {
            switch self {
            case .weeklySummary: return "calendar"
            case .moodPattern: return "chart.line.uptrend.xyaxis"
            case .themeAnalysis: return "doc.text.magnifyingglass"
            case .growthArea: return "arrow.up.circle.fill"
            }
        }
    }
}

// MARK: - View Models
class DailyJournalViewModel: ObservableObject {
    @Published var todaysPrompts: DailyPrompts?
    @Published var prompt1Response: JournalResponse?
    @Published var prompt2Response: JournalResponse?
    @Published var isLoadingPrompts = false
    @Published var isSavingResponse = false
    @Published var recentInsights: [JournalInsight] = []
    @Published var responseStartTime: Date?
    
    // Track typing time
    func startTyping() {
        if responseStartTime == nil {
            responseStartTime = Date()
        }
    }
    
    func calculateTimeSpent() -> Int {
        guard let startTime = responseStartTime else { return 0 }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    // Calculate word count
    func calculateWordCount(for text: String) -> Int {
        let words = text.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }
    
    // Simple sentiment analysis (can be enhanced with ML)
    func analyzeSentiment(for text: String) -> Float {
        let positiveWords = ["happy", "grateful", "love", "joy", "wonderful", "amazing", "good", "great", "blessed", "thankful", "excited", "peaceful", "calm"]
        let negativeWords = ["sad", "angry", "frustrated", "worried", "anxious", "stressed", "tired", "difficult", "hard", "struggle", "fear", "lonely", "depressed"]
        
        let lowercased = text.lowercased()
        var score: Float = 0.0
        
        for word in positiveWords {
            if lowercased.contains(word) {
                score += 0.1
            }
        }
        
        for word in negativeWords {
            if lowercased.contains(word) {
                score -= 0.1
            }
        }
        
        return max(-1.0, min(1.0, score))
    }
    
    // Extract key themes from text
    func extractThemes(from text: String) -> [String] {
        var themes: [String] = []
        let lowercased = text.lowercased()
        
        let themeKeywords: [String: [String]] = [
            "Family": ["family", "mother", "father", "sister", "brother", "parent", "child"],
            "Work": ["work", "job", "career", "office", "meeting", "project", "colleague"],
            "Health": ["health", "exercise", "sleep", "tired", "energy", "sick", "doctor"],
            "Relationships": ["friend", "partner", "love", "relationship", "connection"],
            "Growth": ["learn", "grow", "improve", "change", "progress", "goal"],
            "Gratitude": ["grateful", "thankful", "appreciate", "blessed"],
            "Stress": ["stress", "pressure", "overwhelm", "anxiety", "worry"],
            "Achievement": ["accomplish", "success", "achieve", "complete", "finish", "proud"]
        ]
        
        for (theme, keywords) in themeKeywords {
            for keyword in keywords {
                if lowercased.contains(keyword) {
                    themes.append(theme)
                    break
                }
            }
        }
        
        return Array(Set(themes)) // Remove duplicates
    }
}