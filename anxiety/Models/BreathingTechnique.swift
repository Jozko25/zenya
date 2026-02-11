//
//  BreathingTechnique.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct BreathingTechnique: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let subtitle: String
    let inhaleTime: Int
    let holdTime: Int
    let exhaleTime: Int
    let color: Color
    let icon: String
    let difficulty: Difficulty
    let benefits: [String]
    
    init(
        name: String,
        description: String,
        subtitle: String,
        inhaleTime: Int,
        holdTime: Int = 0,
        exhaleTime: Int,
        color: Color,
        icon: String,
        difficulty: Difficulty = .beginner,
        benefits: [String] = []
    ) {
        self.name = name
        self.description = description
        self.subtitle = subtitle
        self.inhaleTime = inhaleTime
        self.holdTime = holdTime
        self.exhaleTime = exhaleTime
        self.color = color
        self.icon = icon
        self.difficulty = difficulty
        self.benefits = benefits
    }
    
    enum Difficulty: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var color: Color {
            switch self {
            case .beginner: return AdaptiveColors.Action.progress
            case .intermediate: return AdaptiveColors.Action.breathing
            case .advanced: return AdaptiveColors.Action.coaching
            }
        }
    }
    
    var totalDuration: Int {
        return inhaleTime + holdTime + exhaleTime
    }
    
    var pattern: String {
        if holdTime > 0 {
            return "\(inhaleTime)-\(holdTime)-\(exhaleTime)"
        } else {
            return "\(inhaleTime)-\(exhaleTime)"
        }
    }
}

// MARK: - Predefined Techniques
extension BreathingTechnique {
    
    static let techniques: [BreathingTechnique] = [
        BreathingTechnique(
            name: "4-7-8 Relaxation",
            description: "Classic technique for deep relaxation and sleep preparation",
            subtitle: "Perfect for winding down",
            inhaleTime: 4,
            holdTime: 7,
            exhaleTime: 8,
            color: AdaptiveColors.Action.mood,
            icon: "leaf.fill",
            difficulty: .beginner,
            benefits: ["Reduces anxiety", "Improves sleep", "Calms nervous system"]
        ),
        
        BreathingTechnique(
            name: "Box Breathing",
            description: "Equal-count breathing used by Navy SEALs for focus",
            subtitle: "Enhance focus and calm",
            inhaleTime: 4,
            holdTime: 4,
            exhaleTime: 4,
            color: AdaptiveColors.Action.breathing,
            icon: "square.fill",
            difficulty: .intermediate,
            benefits: ["Improves concentration", "Reduces stress", "Builds discipline"]
        ),
        
        BreathingTechnique(
            name: "Quick Calm",
            description: "Simple 2-count breathing for immediate relief",
            subtitle: "Fast anxiety relief",
            inhaleTime: 2,
            holdTime: 0,
            exhaleTime: 4,
            color: AdaptiveColors.Action.sos,
            icon: "bolt.fill",
            difficulty: .beginner,
            benefits: ["Quick stress relief", "Easy to remember", "Works anywhere"]
        ),
        
        BreathingTechnique(
            name: "Energy Breath",
            description: "Energizing breath work for vitality",
            subtitle: "Boost energy naturally",
            inhaleTime: 3,
            holdTime: 3,
            exhaleTime: 3,
            color: AdaptiveColors.Action.progress,
            icon: "sun.max.fill",
            difficulty: .intermediate,
            benefits: ["Increases energy", "Improves alertness", "Enhances mood"]
        ),
        
        BreathingTechnique(
            name: "Deep Healing",
            description: "Extended breath work for deep restoration",
            subtitle: "Profound relaxation",
            inhaleTime: 6,
            holdTime: 6,
            exhaleTime: 8,
            color: AdaptiveColors.Action.coaching,
            icon: "heart.fill",
            difficulty: .advanced,
            benefits: ["Deep relaxation", "Emotional healing", "Stress recovery"]
        )
    ]
    
    static func technique(for difficulty: Difficulty) -> [BreathingTechnique] {
        return techniques.filter { $0.difficulty == difficulty }
    }
    
    static func quickTechniques() -> [BreathingTechnique] {
        return techniques.filter { $0.totalDuration <= 10 }
    }
}