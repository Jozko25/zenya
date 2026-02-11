//
//  AIQuestionGenerationService.swift
//  anxiety
//
//  AI-powered dynamic journal question generation service
//

import Foundation

@MainActor
class AIQuestionGenerationService: ObservableObject {
    static let shared = AIQuestionGenerationService()

    @Published var isGeneratingQuestions = false
    @Published var cachedQuestions: [JournalPrompt] = []
    @Published var questionsUsedCount = 0

    private let openAIClient = OpenAIClient()
    private let databaseService = DatabaseService.shared
    private let cacheKey = "AIGeneratedQuestions"
    private let lastGenerationKey = "LastQuestionGeneration"
    private let usedCountKey = "QuestionsUsedCount"
    private let batchSize = 12
    private let regenerateThreshold = 8 // Regenerate when 8 out of 12 questions used

    private init() {
        loadCachedQuestions()
    }

    // MARK: - Public Methods

    func getDailyQuestion() async -> JournalPrompt {
        // Select question from current batch (no generation here)
        let question = selectQuestionFromCache()

        // Mark question as used
        markQuestionUsed()

        return question
    }

    func needsInitialQuestions() async -> Bool {
        return cachedQuestions.isEmpty
    }

    func generateInitialQuestionBatch() async {
        guard cachedQuestions.isEmpty else { return }

        await generateQuestionBatch(isInitial: true)
    }

    func checkAndGenerateNewBatch() async {
        // Only generate new batch if we've used enough questions
        if questionsUsedCount >= regenerateThreshold {
            await generateQuestionBatch(isInitial: false)
        }
    }

    private func generateQuestionBatch(isInitial: Bool) async {
        guard !isGeneratingQuestions else { return }

        isGeneratingQuestions = true
        print(isInitial ? "🎯 Generating initial question batch..." : "🔄 Generating new question batch after \(questionsUsedCount) questions used...")

        do {
            let userContext = await getUserContext()
            let newQuestions = try await generateQuestionsWithAI(context: userContext)

            // Replace all questions with new batch
            cachedQuestions = newQuestions
            questionsUsedCount = 0 // Reset usage counter

            saveCachedQuestions()
            saveUsedCount()

            debugPrint("✨ Generated \(newQuestions.count) new AI questions")
        } catch {
            if case OpenAIError.missingAPIKey = error {
                debugPrint("ℹ️ Using fallback questions - OpenAI API not configured")
            } else {
                debugPrint("❌ Question generation failed: \(error)")
            }

            if isInitial {
                // For initial generation, use fallback questions
                cachedQuestions = generateFallbackQuestions()
                debugPrint("✅ Loaded \(cachedQuestions.count) fallback questions")
            }
            // For subsequent generations, keep existing questions if generation fails
        }

        isGeneratingQuestions = false
    }

    private func markQuestionUsed() {
        questionsUsedCount += 1
        saveUsedCount()
        debugPrint("📊 Question used. Count: \(questionsUsedCount)/\(batchSize)")

        // Trigger background generation if threshold reached
        if questionsUsedCount >= regenerateThreshold {
            debugPrint("🔄 Threshold reached, scheduling new batch generation...")
            Task.detached {
                await self.checkAndGenerateNewBatch()
            }
        }
    }

    // MARK: - AI Question Generation

    private func generateQuestionsWithAI(context: UserContext) async throws -> [JournalPrompt] {
        let prompt = createQuestionGenerationPrompt(context: context)

        // Combine system prompt and user prompt for sendMessage API
        let fullPrompt = """
        \(systemPrompt)

        USER REQUEST:
        \(prompt)
        """

        let response = try await openAIClient.sendMessage(
            fullPrompt,
            conversationHistory: [] as [SimpleChatMessage] // No conversation history needed for question generation
        )

        return parseAIResponse(response)
    }

    private var systemPrompt: String {
        """
        You are an expert therapist, philosopher, and journal prompt creator with deep understanding of human psychology and emotional development. Generate profound yet accessible reflection questions that guide users toward meaningful self-discovery and emotional growth.

        Core Principles:
        - Create questions that invite genuine introspection without being overwhelming
        - Balance accessibility with depth - questions should feel approachable but lead to profound insights
        - Use language that feels warm, curious, and supportive rather than clinical
        - Focus on process and exploration rather than judgment or fixed outcomes
        - Include questions that connect past experiences to present awareness
        - Encourage both analytical thinking and intuitive feeling

        Question Depth Guidelines:
        - Easy: Gentle entry points that feel safe and accessible, focusing on present moment awareness
        - Medium: Questions that bridge surface thoughts with deeper patterns, encouraging connections
        - Deep: Transformative questions that explore core beliefs, life meaning, and authentic self

        Categories with Enhanced Focus:
        - Reflection: Self-awareness, life patterns, personal truths, values clarification
        - Emotions: Emotional intelligence, feeling landscapes, emotional wisdom, inner dialogue
        - Growth: Personal evolution, learning from challenges, expanding comfort zones, becoming
        - Gratitude: Appreciation depth, interconnectedness, finding beauty in complexity
        - Relationships: Connection quality, boundaries, love languages, human understanding
        - Goals: Purpose alignment, meaningful progress, vision clarification, authentic desires
        - Self-Care: Inner nurturing, personal needs, energy management, self-compassion
        - Joy: Authentic happiness, celebration, play, lightness in life
        - Creativity: Creative expression, inspiration sources, innovative thinking, artistic soul

        Advanced Techniques:
        - Use sensory and embodied language ("Notice...", "What does it feel like...", "Where in your body...")
        - Include temporal perspectives (past wisdom, present awareness, future visioning)
        - Incorporate metaphorical and symbolic thinking
        - Ask about inner conversations and multiple perspectives
        - Explore the space between thoughts and feelings
        - Invite curiosity about unconscious patterns

        Output format: Return exactly 12 questions in JSON format with this structure:
        {
          "questions": [
            {
              "questionText": "Main question here - should be thought-provoking yet accessible",
              "category": "one of the categories above",
              "difficultyLevel": "easy/medium/deep",
              "followUpQuestion": "Optional deeper follow-up question that builds on the main question",
              "timeOfDay": "morning/evening/any"
            }
          ]
        }

        Question Examples by Level:
        Easy: "What's one small thing you noticed today that brought you a moment of peace?"
        Medium: "How does your relationship with uncertainty show up in your daily choices?"
        Deep: "What part of yourself are you still learning to accept, and what would it mean to befriend that aspect?"
        """
    }

    private func createQuestionGenerationPrompt(context: UserContext) -> String {
        var prompt = "Generate 12 unique, personalized journal reflection questions based on this user context:\n\n"

        // Add user journey insights
        prompt += "User Journey:\n"
        prompt += "- Current streak: \(context.currentStreak) days\n"
        prompt += "- Total entries: \(context.totalEntries)\n"
        prompt += "- Recent activity: \(context.recentActivityPattern)\n\n"

        // Add recent themes
        if !context.recentThemes.isEmpty {
            prompt += "Recent themes in their writing:\n"
            for theme in context.recentThemes {
                prompt += "- \(theme)\n"
            }
            prompt += "\n"
        }

        // Add emotional patterns
        if !context.emotionalPatterns.isEmpty {
            prompt += "Recent emotional patterns:\n"
            for pattern in context.emotionalPatterns {
                prompt += "- \(pattern)\n"
            }
            prompt += "\n"
        }

        // Time context
        let hour = Calendar.current.component(.hour, from: Date())
        let timeContext = (hour >= 6 && hour < 17) ? "morning" : "evening"
        prompt += "Current time context: \(timeContext)\n"
        prompt += "Season: \(getCurrentSeason())\n\n"

        prompt += "Create questions that:\n"
        prompt += "1. Build on their recent reflections while opening new pathways for exploration\n"
        prompt += "2. Honor their current emotional landscape while gently encouraging growth\n"
        prompt += "3. Feel deeply personal yet universally relatable\n"
        prompt += "4. Create a thoughtful journey from surface awareness to deeper truth\n"
        prompt += "5. Include questions that surprise them with their own wisdom\n"
        prompt += "6. Balance validation of where they are with invitation to where they're growing\n"
        prompt += "7. Use language that feels like a wise friend asking, not a therapist probing\n"
        prompt += "8. Vary in approach: some analytical, some intuitive, some creative\n"

        return prompt
    }

    // MARK: - User Context Analysis

    private func getUserContext() async -> UserContext {
        guard let currentUser = databaseService.currentUser else {
            return UserContext.empty()
        }

        // Get recent entries for analysis
        let recentEntries = await databaseService.getRecentEntries(userId: currentUser.id.uuidString, limit: 10)

        return UserContext(
            currentStreak: getCurrentStreak(),
            totalEntries: getTotalEntryCount(),
            recentThemes: extractThemes(from: recentEntries),
            emotionalPatterns: extractEmotionalPatterns(from: recentEntries),
            recentActivityPattern: getActivityPattern(from: recentEntries)
        )
    }

    private func extractThemes(from entries: [SupabaseJournalEntry]) -> [String] {
        // Simple keyword extraction for themes
        let commonThemes = ["work", "family", "stress", "joy", "anxiety", "growth", "relationships", "goals", "creativity", "self-care"]
        var detectedThemes: [String] = []

        let allContent = entries.map { $0.content.lowercased() }.joined(separator: " ")

        for theme in commonThemes {
            if allContent.contains(theme) {
                detectedThemes.append(theme)
            }
        }

        return Array(detectedThemes.prefix(5)) // Limit to top 5 themes
    }

    private func extractEmotionalPatterns(from entries: [SupabaseJournalEntry]) -> [String] {
        let emotionKeywords = ["happy", "sad", "anxious", "excited", "frustrated", "peaceful", "overwhelmed", "grateful", "angry", "content"]
        var patterns: [String] = []

        let allContent = entries.map { $0.content.lowercased() }.joined(separator: " ")

        for emotion in emotionKeywords {
            if allContent.contains(emotion) {
                patterns.append("experiencing \(emotion) feelings")
            }
        }

        return Array(patterns.prefix(3))
    }

    private func getActivityPattern(from entries: [SupabaseJournalEntry]) -> String {
        let entriesThisWeek = entries.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }

        if entriesThisWeek.count >= 5 {
            return "highly active this week"
        } else if entriesThisWeek.count >= 2 {
            return "moderately active"
        } else {
            return "getting back into journaling"
        }
    }

    private func getCurrentStreak() -> Int {
        // Get actual streak from journal game stats
        return JournalGameStatsManager.shared.gameStats.currentStreak
    }

    private func getTotalEntryCount() -> Int {
        // Get actual total from journal game stats
        return JournalGameStatsManager.shared.gameStats.totalEntries
    }

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return "winter"
        case 3, 4, 5: return "spring"
        case 6, 7, 8: return "summer"
        default: return "autumn"
        }
    }

    // MARK: - Response Parsing

    private func parseAIResponse(_ response: String) -> [JournalPrompt] {
        guard let data = response.data(using: .utf8) else {
            debugPrint("❌ Failed to convert response to data")
            return generateFallbackQuestions()
        }

        do {
            let questionResponse = try JSONDecoder().decode(QuestionResponse.self, from: data)

            return questionResponse.questions.map { q in
                JournalPrompt(
                    id: UUID(),
                    questionText: q.questionText,
                    category: mapCategory(q.category),
                    difficultyLevel: mapDifficultyLevel(q.difficultyLevel),
                    followUpQuestion: q.followUpQuestion,
                    createdAt: Date(),
                    updatedAt: Date(),
                    isActive: true
                )
            }
        } catch {
            debugPrint("❌ Failed to parse AI response: \(error)")
            return generateFallbackQuestions()
        }
    }

    private func mapCategory(_ category: String) -> JournalPrompt.PromptCategory {
        switch category.lowercased() {
        case "reflection": return .reflection
        case "emotions": return .emotions
        case "growth": return .growth
        case "gratitude": return .gratitude
        case "relationships": return .relationships
        case "goals": return .goals
        case "self-care": return .selfCare
        case "joy": return .joy
        case "creativity": return .creativity
        default: return .reflection
        }
    }

    private func mapDifficultyLevel(_ level: String) -> JournalPrompt.DifficultyLevel {
        switch level.lowercased() {
        case "easy": return .easy
        case "medium": return .medium
        case "deep": return .deep
        default: return .medium
        }
    }

    // MARK: - Question Selection & Caching

    private func selectQuestionFromCache() -> JournalPrompt {
        guard !cachedQuestions.isEmpty else {
            return generateFallbackQuestions().first ?? createDefaultQuestion()
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let isMorning = hour >= 6 && hour < 17

        // Try to find a question appropriate for the time
        let timeAppropriate = cachedQuestions.filter { question in
            // This is a simple heuristic - you could store timeOfDay in the model
            if isMorning {
                return question.category == .goals || question.category == .selfCare || question.category == .reflection
            } else {
                return question.category == .gratitude || question.category == .emotions || question.category == .growth
            }
        }

        if !timeAppropriate.isEmpty {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
            return timeAppropriate[dayOfYear % timeAppropriate.count]
        }

        // Fallback to any cached question
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return cachedQuestions[dayOfYear % cachedQuestions.count]
    }

    private func shouldGenerateNewQuestions() -> Bool {
        // Check if we have cached questions
        if cachedQuestions.isEmpty {
            return true
        }

        // Check when we last generated questions
        let lastGeneration = UserDefaults.standard.object(forKey: lastGenerationKey) as? Date ?? Date.distantPast
        let daysSinceLastGeneration = Calendar.current.dateComponents([.day], from: lastGeneration, to: Date()).day ?? 0

        // Generate new questions every 3-4 days
        return daysSinceLastGeneration >= 3
    }

    // MARK: - Fallback & Caching

    private func generateFallbackQuestions() -> [JournalPrompt] {
        // Generate thoughtful fallback questions if AI fails
        return [
            createQuestionWithText("What's stirring in your inner world today that deserves attention?", category: .reflection),
            createQuestionWithText("How is your heart feeling right now, and what might it be trying to tell you?", category: .emotions),
            createQuestionWithText("What small act of growth feels both scary and exciting to you today?", category: .growth),
            createQuestionWithText("What unexpected moment of beauty crossed your path recently?", category: .gratitude),
            createQuestionWithText("If your soul could ask for one thing today, what would it be?", category: .selfCare),
            createQuestionWithText("How do you show up differently in various relationships, and what does that teach you?", category: .relationships),
            createQuestionWithText("What dream or vision is quietly calling to you these days?", category: .goals),
            createQuestionWithText("What brought lightness to your spirit recently, and how can you invite more of that?", category: .joy),
            createQuestionWithText("What wants to be created or expressed through you right now?", category: .creativity),
            createQuestionWithText("What old story about yourself are you ready to question or rewrite?", category: .growth),
            createQuestionWithText("How has a recent challenge revealed a hidden strength you didn't know you had?", category: .reflection),
            createQuestionWithText("What would change if you trusted yourself completely in this moment?", category: .selfCare)
        ]
    }

    private func createQuestionWithText(_ text: String, category: JournalPrompt.PromptCategory) -> JournalPrompt {
        JournalPrompt(
            id: UUID(),
            questionText: text,
            category: category,
            difficultyLevel: .medium,
            followUpQuestion: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
    }

    private func createDefaultQuestion() -> JournalPrompt {
        createQuestionWithText("What's on your mind today?", category: .reflection)
    }

    private func saveCachedQuestions() {
        if let data = try? JSONEncoder().encode(cachedQuestions) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: lastGenerationKey)
        }
    }

    private func loadCachedQuestions() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let questions = try? JSONDecoder().decode([JournalPrompt].self, from: data) {
            cachedQuestions = questions
        }

        // Also load the used count
        questionsUsedCount = UserDefaults.standard.integer(forKey: usedCountKey)
    }

    private func saveUsedCount() {
        UserDefaults.standard.set(questionsUsedCount, forKey: usedCountKey)
    }
}

// MARK: - Supporting Models

struct UserContext {
    let currentStreak: Int
    let totalEntries: Int
    let recentThemes: [String]
    let emotionalPatterns: [String]
    let recentActivityPattern: String

    static func empty() -> UserContext {
        UserContext(
            currentStreak: 0,
            totalEntries: 0,
            recentThemes: [],
            emotionalPatterns: [],
            recentActivityPattern: "new to journaling"
        )
    }
}

struct QuestionResponse: Codable {
    let questions: [AIGeneratedQuestion]
}

struct AIGeneratedQuestion: Codable {
    let questionText: String
    let category: String
    let difficultyLevel: String
    let followUpQuestion: String?
    let timeOfDay: String?
}