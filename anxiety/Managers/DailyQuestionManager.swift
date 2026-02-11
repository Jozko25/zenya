//
//  DailyQuestionManager.swift
//  anxiety
//
//  Created by Claude Code on 09/09/2025.
//

import Foundation

@MainActor
class DailyQuestionManager: ObservableObject {
    static let shared = DailyQuestionManager()

    @Published var isLoadingAIQuestion = false
    private let aiQuestionService = AIQuestionGenerationService.shared

    private init() {}
    
    // MARK: - Question Pools
    
    private let morningQuestions: [JournalPrompt] = [
        JournalPrompt(
            id: UUID(),
            questionText: "What intention do you want to set for today, and how can you honor your energy levels?",
            category: .reflection,
            difficultyLevel: .easy,
            followUpQuestion: "What small step can you take right now to align with this intention?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What are you most grateful for in this moment, and how can you carry that feeling throughout your day?",
            category: .gratitude,
            difficultyLevel: .easy,
            followUpQuestion: "Who or what has contributed to this feeling of gratitude?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What emotions are you noticing this morning, and what might they be telling you?",
            category: .emotions,
            difficultyLevel: .medium,
            followUpQuestion: "How can you nurture yourself based on these feelings?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What personal strength will serve you best today?",
            category: .growth,
            difficultyLevel: .easy,
            followUpQuestion: "How have you developed this strength over time?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What creative idea or inspiration is calling to you today?",
            category: .creativity,
            difficultyLevel: .medium,
            followUpQuestion: "What would it look like to explore this inspiration?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "How do you want to show up for yourself and others today?",
            category: .relationships,
            difficultyLevel: .medium,
            followUpQuestion: "What values will guide your interactions?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What self-care practice would most nourish you today?",
            category: .selfCare,
            difficultyLevel: .easy,
            followUpQuestion: "How can you realistically incorporate this into your day?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
    ]
    
    private let eveningQuestions: [JournalPrompt] = [
        JournalPrompt(
            id: UUID(),
            questionText: "What moments from today do you want to hold onto, and what are you ready to release?",
            category: .reflection,
            difficultyLevel: .medium,
            followUpQuestion: "How do these experiences contribute to your growth?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What brought you the most joy today, and how can you invite more of this into your life?",
            category: .joy,
            difficultyLevel: .easy,
            followUpQuestion: "What patterns do you notice in what brings you joy?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "How did you show kindness to yourself and others today?",
            category: .gratitude,
            difficultyLevel: .easy,
            followUpQuestion: "What opportunities for kindness did you notice?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What challenged you today, and what did it teach you about your resilience?",
            category: .growth,
            difficultyLevel: .deep,
            followUpQuestion: "How can you apply this insight moving forward?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What emotions showed up for you today, and how did you respond to them?",
            category: .emotions,
            difficultyLevel: .medium,
            followUpQuestion: "What would you like to say to those emotions?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "How did your relationships nourish or challenge you today?",
            category: .relationships,
            difficultyLevel: .medium,
            followUpQuestion: "What do you appreciate about the people in your life?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        ),
        JournalPrompt(
            id: UUID(),
            questionText: "What progress did you make toward your goals today, however small?",
            category: .goals,
            difficultyLevel: .easy,
            followUpQuestion: "What would you like to focus on tomorrow?",
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
    ]
    
    // MARK: - Question Selection Logic

    func getDailyQuestion() async -> JournalPrompt {
        // Try to get AI-generated question first
        return await getAIGeneratedQuestion()
    }

    @MainActor
    func getAIGeneratedQuestion() async -> JournalPrompt {
        isLoadingAIQuestion = true

        let question = await aiQuestionService.getDailyQuestion()

        isLoadingAIQuestion = false
        return question
    }

    // Fallback method for static questions (kept for backup)
    func getStaticDailyQuestion() -> JournalPrompt {
        let hour = Calendar.current.component(.hour, from: Date())
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

        let isMorning = hour >= 6 && hour < 17
        let questions = isMorning ? morningQuestions : eveningQuestions

        // Use day of year to rotate through questions
        let questionIndex = dayOfYear % questions.count
        return questions[questionIndex]
    }
    
    func getQuestionForDate(_ date: Date) -> JournalPrompt {
        let hour = Calendar.current.component(.hour, from: date)
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        
        let isMorning = hour >= 6 && hour < 17
        let questions = isMorning ? morningQuestions : eveningQuestions
        
        let questionIndex = dayOfYear % questions.count
        return questions[questionIndex]
    }
    
    // MARK: - Question Metadata
    
    func getCurrentPeriod() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        return (hour >= 6 && hour < 17) ? "morning" : "evening"
    }
    
    func getEncouragingMessage() -> String {
        let period = getCurrentPeriod()
        
        if period == "morning" {
            return "Take a moment to connect with yourself and set your intentions."
        } else {
            return "Reflect on your day and celebrate your experiences."
        }
    }
}