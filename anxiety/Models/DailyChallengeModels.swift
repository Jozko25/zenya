//
//  DailyChallengeModels.swift
//  anxiety
//
//  Interactive daily challenges for user engagement
//

import Foundation

// MARK: - Challenge Types

enum ChallengeType: String, CaseIterable, Codable {
    case reflection = "reflection"
    case gratitude = "gratitude"
    case mindfulness = "mindfulness"
    case selfCare = "self_care"
    case growth = "growth"
    case connection = "connection"
    case creativity = "creativity"
    
    var emoji: String {
        switch self {
        case .reflection: return "🤔"
        case .gratitude: return "🙏"
        case .mindfulness: return "🧘"
        case .selfCare: return "💜"
        case .growth: return "🌱"
        case .connection: return "💕"
        case .creativity: return "🎨"
        }
    }
    
    var color: String {
        switch self {
        case .reflection: return "breathing" // AdaptiveColors.Action.breathing
        case .gratitude: return "mood" // AdaptiveColors.Action.mood
        case .mindfulness: return "coaching" // AdaptiveColors.Action.coaching
        case .selfCare: return "progress" // AdaptiveColors.Action.progress
        case .growth: return "breathing" // AdaptiveColors.Action.breathing
        case .connection: return "mood" // AdaptiveColors.Action.mood
        case .creativity: return "coaching" // AdaptiveColors.Action.coaching
        }
    }
}

enum InteractionType: String, CaseIterable, Codable {
    case multipleChoice = "multiple_choice"
    case textInput = "text_input"
    case slider = "slider"
    case yesNo = "yes_no"
    case rating = "rating"
}

// MARK: - Challenge Models

struct DailyChallenge: Identifiable, Codable {
    let id: UUID
    let type: ChallengeType
    let interactionType: InteractionType
    let question: String
    let description: String?
    let options: [String]? // For multiple choice
    let minValue: Int? // For slider/rating
    let maxValue: Int? // For slider/rating
    let placeholder: String? // For text input
    
    init(
        id: UUID = UUID(),
        type: ChallengeType,
        interactionType: InteractionType,
        question: String,
        description: String? = nil,
        options: [String]? = nil,
        minValue: Int? = nil,
        maxValue: Int? = nil,
        placeholder: String? = nil
    ) {
        self.id = id
        self.type = type
        self.interactionType = interactionType
        self.question = question
        self.description = description
        self.options = options
        self.minValue = minValue
        self.maxValue = maxValue
        self.placeholder = placeholder
    }
}

struct ChallengeResponse: Codable {
    let id: UUID
    let userId: UUID
    let challengeId: UUID
    let date: Date
    let response: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        challengeId: UUID,
        date: Date = Date(),
        response: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.date = date
        self.response = response
        self.createdAt = createdAt
    }
}

// MARK: - Challenge Content

struct ChallengeBank {
    static let challenges: [DailyChallenge] = [
        // Reflection Challenges
        DailyChallenge(
            type: .reflection,
            interactionType: .textInput,
            question: "What's one thing you learned about yourself today?",
            description: "Take a moment to reflect on your day and any insights about yourself.",
            placeholder: "I learned that I..."
        ),
        
        DailyChallenge(
            type: .reflection,
            interactionType: .multipleChoice,
            question: "Which moment today made you feel most like yourself?",
            description: "Think about when you felt most authentic and true to who you are.",
            options: ["Morning routine", "Work/study time", "With friends/family", "During alone time", "Evening wind-down", "Creative activity"]
        ),
        
        DailyChallenge(
            type: .reflection,
            interactionType: .slider,
            question: "How connected did you feel to your values today?",
            description: "Rate how aligned your actions were with what matters most to you.",
            minValue: 1,
            maxValue: 10
        ),
        
        // Gratitude Challenges
        DailyChallenge(
            type: .gratitude,
            interactionType: .textInput,
            question: "What's something small that brought you joy today?",
            description: "Even tiny moments of happiness count - what made you smile?",
            placeholder: "Today I smiled when..."
        ),
        
        DailyChallenge(
            type: .gratitude,
            interactionType: .multipleChoice,
            question: "Who would you like to thank for being in your life?",
            description: "Think of someone who has made a positive impact on you recently.",
            options: ["A family member", "A friend", "A colleague", "A stranger who was kind", "A mentor or teacher", "Someone from my past"]
        ),
        
        DailyChallenge(
            type: .gratitude,
            interactionType: .textInput,
            question: "What's one thing about your body you're grateful for today?",
            description: "Your body does amazing things every day - what are you appreciating?",
            placeholder: "I'm grateful my body..."
        ),
        
        // Mindfulness Challenges
        DailyChallenge(
            type: .mindfulness,
            interactionType: .yesNo,
            question: "Did you take at least 3 mindful breaths today?",
            description: "Mindful breathing helps center us. Even a few conscious breaths make a difference."
        ),
        
        DailyChallenge(
            type: .mindfulness,
            interactionType: .multipleChoice,
            question: "What did you notice about your environment today?",
            description: "Mindfulness helps us observe our surroundings with fresh eyes.",
            options: ["Beautiful sounds", "Interesting textures", "Pleasant smells", "Changing light", "People's expressions", "Natural elements"]
        ),
        
        DailyChallenge(
            type: .mindfulness,
            interactionType: .textInput,
            question: "Describe a moment when you felt fully present today.",
            description: "When did you feel most aware and engaged with the current moment?",
            placeholder: "I felt most present when..."
        ),
        
        // Self-Care Challenges
        DailyChallenge(
            type: .selfCare,
            interactionType: .rating,
            question: "How well did you take care of yourself today?",
            description: "Rate your self-care efforts - remember, small acts of kindness to yourself count.",
            minValue: 1,
            maxValue: 5
        ),
        
        DailyChallenge(
            type: .selfCare,
            interactionType: .multipleChoice,
            question: "What's one way you nurtured yourself today?",
            description: "Self-care comes in many forms - what did you do for your wellbeing?",
            options: ["Got enough rest", "Ate something nourishing", "Moved my body", "Spent time in nature", "Did something creative", "Connected with loved ones"]
        ),
        
        DailyChallenge(
            type: .selfCare,
            interactionType: .textInput,
            question: "What does your inner voice need to hear right now?",
            description: "Sometimes we need to give ourselves the compassion we'd show a friend.",
            placeholder: "I need to hear that..."
        ),
        
        // Growth Challenges
        DailyChallenge(
            type: .growth,
            interactionType: .textInput,
            question: "What's one small step you took toward a goal today?",
            description: "Growth happens through small, consistent actions. What progress did you make?",
            placeholder: "Today I moved forward by..."
        ),
        
        DailyChallenge(
            type: .growth,
            interactionType: .multipleChoice,
            question: "What challenged you in a positive way today?",
            description: "Challenges help us grow - what pushed you out of your comfort zone?",
            options: ["Trying something new", "Having a difficult conversation", "Taking on responsibility", "Learning a skill", "Facing a fear", "Helping someone else"]
        ),
        
        DailyChallenge(
            type: .growth,
            interactionType: .slider,
            question: "How proud are you of yourself today?",
            description: "You deserve recognition for your efforts, big and small.",
            minValue: 1,
            maxValue: 10
        ),
        
        // Connection Challenges
        DailyChallenge(
            type: .connection,
            interactionType: .textInput,
            question: "How did you make someone's day a little brighter?",
            description: "Connection happens through small acts of kindness and attention.",
            placeholder: "I brightened someone's day by..."
        ),
        
        DailyChallenge(
            type: .connection,
            interactionType: .yesNo,
            question: "Did you have a meaningful conversation today?",
            description: "Real connection comes from authentic, heartfelt conversations."
        ),
        
        DailyChallenge(
            type: .connection,
            interactionType: .multipleChoice,
            question: "What made you feel most connected to others today?",
            description: "Connection can happen in many ways - what brought you closer to someone?",
            options: ["Shared laughter", "Deep conversation", "Helping someone", "Being helped", "Shared activity", "Understanding someone's feelings"]
        ),
        
        // Creativity Challenges
        DailyChallenge(
            type: .creativity,
            interactionType: .textInput,
            question: "What's something you created or expressed today?",
            description: "Creativity isn't just art - it's any form of self-expression or problem-solving.",
            placeholder: "Today I created/expressed..."
        ),
        
        DailyChallenge(
            type: .creativity,
            interactionType: .multipleChoice,
            question: "How did you approach a problem creatively today?",
            description: "Creative thinking helps us find new solutions and perspectives.",
            options: ["Found a new way to do something", "Looked at it from a different angle", "Combined ideas in a new way", "Asked for a fresh perspective", "Took a break and came back to it", "Used my imagination"]
        ),
        
        DailyChallenge(
            type: .creativity,
            interactionType: .yesNo,
            question: "Did you do something that sparked your curiosity today?",
            description: "Curiosity is the fuel of creativity - what made you wonder or explore?"
        )
    ]
    
    static func getTodaysChallenge() -> DailyChallenge {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % challenges.count
        return challenges[index]
    }
    
    static func getRandomChallenge(excluding: [UUID] = []) -> DailyChallenge {
        let availableChallenges = challenges.filter { !excluding.contains($0.id) }
        return availableChallenges.randomElement() ?? challenges.randomElement()!
    }
}