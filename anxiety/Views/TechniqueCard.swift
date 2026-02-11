//
//  TechniqueCard.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct TechniqueCard: View {
    let technique: BreathingTechnique
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(technique.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: technique.icon)
                        .font(.quicksand(size: 28, weight: .medium))
                        .foregroundColor(technique.color)
                }
                
                // Content
                VStack(spacing: 8) {
                    Text(technique.name)
                        .font(.quicksand(size: 18, weight: .semibold))
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(technique.subtitle)
                        .font(.quicksand(size: 14, weight: .regular))
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Duration info
                    HStack(spacing: 4) {
                        Text("\(technique.inhaleTime)")
                        Text("·")
                        if technique.holdTime > 0 {
                            Text("\(technique.holdTime)")
                            Text("·")
                        }
                        Text("\(technique.exhaleTime)")
                    }
                    .font(.quicksand(size: 12, weight: .medium))
                    .foregroundColor(technique.color)
                }
                
                Spacer()
            }
            .padding(20)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? technique.color : Color(.systemGray5),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? technique.color.opacity(0.2) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    TechniqueCard(
        technique: BreathingTechnique.techniques[0],
        isSelected: true,
        action: {}
    )
    .padding()
}