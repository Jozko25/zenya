//
//  RoundedMeditationCard.swift
//  anxiety
//
//  Beautiful rounded card design inspired by modern travel apps
//

import SwiftUI

struct RoundedMeditationCard: View {
    let meditation: MeditationItem
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
                // Image Section with Overlay
                ZStack(alignment: .topLeading) {
                    // Background Image
                    Group {
                        if let imageName = meditation.imageName {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            meditation.color
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Back Button (top left)
                    HStack {
                        Button(action: {}) {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .opacity(0) // Hidden but taking space
                        
                        Spacer()
                        
                        // Premium Badge
                        if meditation.isPremium {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.yellow)
                                )
                        }
                    }
                    .padding(16)
                    
                    // Title and Location at Bottom
                    VStack(alignment: .leading, spacing: 8) {
                        Spacer()
                        
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(meditation.title)
                                    .font(.quicksand(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(meditation.subtitle)
                                        .font(.quicksand(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            // Duration Chip
                            if meditation.duration != "∞" {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Duration")
                                        .font(.quicksand(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(meditation.duration)
                                        .font(.quicksand(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .frame(height: 200)
                }
                .clipShape(RoundedRectangle(cornerRadius: 32))
                
                // Details Section
                VStack(spacing: 20) {
                    // Tab Section
                    HStack(spacing: 24) {
                        Text("Overview")
                            .font(.quicksand(size: 16, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.primary)
                        
                        Text("Details")
                            .font(.quicksand(size: 16, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    
                    // Stats Row
                    HStack(spacing: 12) {
                        StatChip(
                            icon: "clock",
                            text: meditation.duration == "∞" ? "Continuous" : meditation.duration
                        )
                        
                        StatChip(
                            icon: "waveform",
                            text: "Sounds"
                        )
                        
                        StatChip(
                            icon: "star.fill",
                            text: "4.8"
                        )
                    }
                    // Action Button
                    HStack(spacing: 12) {
                        Text(meditation.isPremium ? "Unlock & Play" : "Play Now")
                            .font(.quicksand(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18) 
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        OnboardingColors.wellnessLavender,
                                        OnboardingColors.softPurple
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: OnboardingColors.wellnessLavender.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(24)
            }
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 15)
            )
            .padding(20)
    }
}

// MARK: - Stat Chip Component

struct StatChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(OnboardingColors.wellnessLavender)
            
            Text(text)
                .font(.quicksand(size: 12, weight: .bold))
                .foregroundColor(AdaptiveColors.Text.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            OnboardingColors.wellnessLavender.opacity(0.15),
                            OnboardingColors.softPurple.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(OnboardingColors.wellnessLavender.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0A0A0A").ignoresSafeArea()
        
        RoundedMeditationCard(
            meditation: MeditationItem(
                title: "Forest Rain",
                subtitle: "Gentle woodland showers",
                duration: "∞",
                category: .sounds,
                difficulty: .beginner,
                isPremium: false,
                color: Color(red: 0.2, green: 0.6, blue: 0.3),
                icon: "cloud.rain",
                imageName: "rain"
            ),
            action: {}
        )
    }
}
