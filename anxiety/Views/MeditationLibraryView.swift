//
//  MeditationLibraryView.swift
//  anxiety
//
//  Created by Ján Harmady on 30/08/2025.
//

import SwiftUI

struct MeditationLibraryView: View {
    @StateObject private var activationService = ActivationService.shared
    @State private var selectedCategory: MeditationCategory = .all
    @State private var searchText = ""
    @State private var showingPaywall = false
    @Environment(\.presentationMode) var presentationMode
    
    let categories: [MeditationCategory] = [
        .all, .sounds
    ]
    
    let meditations = [
        MeditationItem(
            title: "Forest Rain",
            subtitle: "Gentle woodland showers",
            duration: "∞",
            category: .sounds,
            difficulty: .beginner,
            isPremium: false,
            color: Color(red: 0.2, green: 0.6, blue: 0.3),
            icon: "cloud.drizzle.fill",
            imageName: "rain"
        ),
        MeditationItem(
            title: "Ocean Waves",
            subtitle: "Rhythmic coastal sounds",
            duration: "∞",
            category: .sounds,
            difficulty: .beginner,
            isPremium: false,
            color: Color(red: 0.2, green: 0.5, blue: 0.8),
            icon: "water.waves",
            imageName: "ocean"
        ),
        MeditationItem(
            title: "Thunderstorm",
            subtitle: "Powerful nature symphony",
            duration: "∞",
            category: .sounds,
            difficulty: .beginner,
            isPremium: false,
            color: Color(red: 0.3, green: 0.3, blue: 0.5),
            icon: "cloud.bolt.rain.fill",
            imageName: "thunderstorm"
        ),
        MeditationItem(
            title: "Crackling Fire",
            subtitle: "Cozy hearth ambiance",
            duration: "∞",
            category: .sounds,
            difficulty: .beginner,
            isPremium: false,
            color: Color(red: 0.9, green: 0.4, blue: 0.2),
            icon: "flame.fill",
            imageName: "fire"
        )
    ]
    
    private var categoryFiltered: [MeditationItem] {
        selectedCategory == .all ? meditations : meditations.filter { $0.category == selectedCategory }
    }
    
    var filteredMeditations: [MeditationItem] {
        guard !searchText.isEmpty else { return categoryFiltered }
        
        let lowercasedSearch = searchText.lowercased()
        return categoryFiltered.filter {
            $0.title.lowercased().contains(lowercasedSearch) ||
            $0.subtitle.lowercased().contains(lowercasedSearch)
        }
    }
    
    var body: some View {
        ZStack {
            AdaptiveColors.Background.primary
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection

                    searchSection

                    categoryFilter

                    meditationGrid

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Meditation Library")
        .navigationBarHidden(true)
        .smoothModeTransitions()
        .sheet(isPresented: $showingPaywall) {
            PremiumUpsellView(context: .meditation)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Back")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 25))
            }

            Spacer()

            VStack(alignment: .center, spacing: 8) {
                Text("Meditation Library")
                    .font(.quicksand(size: 28, weight: .bold))
                    .foregroundColor(AdaptiveColors.Text.primary)

                Text("Find your perfect practice")
                    .font(.quicksand(size: 16, weight: .regular))
                    .foregroundColor(AdaptiveColors.Text.secondary)
            }

            Spacer()
            
            if !activationService.isActivated {
                Button(action: { showingPaywall = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                        Text("Premium")
                            .font(.quicksand(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [
                                AdaptiveColors.Action.sos,
                                AdaptiveColors.Action.sos.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
        }
    }
    
    private var searchSection: some View {
        TherapeuticCard(elevation: .elevated) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.quicksand(size: 16))
                    .foregroundColor(AdaptiveColors.Text.secondary)
                
                TextField("Search meditations...", text: $searchText)
                    .font(.quicksand(size: 16, weight: .regular))
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.quicksand(size: 16))
                            .foregroundColor(AdaptiveColors.Text.tertiary)
                    }
                }
            }
            .padding(16)
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryFilterChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                            
                            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }
    
    private var meditationGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredMeditations) { meditation in
                NavigationLink(destination: MeditationPlayerView(meditation: meditation)) {
                    RoundedMeditationCard(meditation: meditation) {
                        // Action handled by NavigationLink
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Supporting Models

struct MeditationItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: String
    let category: MeditationCategory
    let difficulty: MeditationDifficulty
    let isPremium: Bool
    let color: Color
    let icon: String
    let imageName: String?
}

enum MeditationCategory: String, CaseIterable {
    case all = "All"
    case sleep = "Sleep"
    case anxiety = "Anxiety"
    case focus = "Focus"
    case breathwork = "Breathwork"
    case body = "Body"
    case sounds = "Sounds"

    var icon: String {
        switch self {
        case .all: return "grid.circle.fill"
        case .sleep: return "moon.stars.fill"
        case .anxiety: return "heart.fill"
        case .focus: return "brain.head.profile"
        case .breathwork: return "wind"
        case .body: return "figure.mind.and.body"
        case .sounds: return "speaker.wave.3.fill"
        }
    }
}

enum MeditationDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return OnboardingColors.wellnessLavender.opacity(0.7)
        case .intermediate: return OnboardingColors.wellnessLavender
        case .advanced: return OnboardingColors.softPurple
        }
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let category: MeditationCategory
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.quicksand(size: 14, weight: .medium))
                
                Text(category.rawValue)
                    .font(.quicksand(size: 14, weight: .semibold))
            }
            .foregroundColor(
                isSelected ? .white : AdaptiveColors.Text.primary
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [
                            OnboardingColors.wellnessLavender,
                            OnboardingColors.softPurple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [
                            AdaptiveColors.Surface.card,
                            AdaptiveColors.Surface.card
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : AdaptiveColors.Text.tertiary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Meditation Card

struct MeditationCard: View {
    let meditation: MeditationItem
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    meditation.color.opacity(colorScheme == .dark ? 0.3 : 0.15),
                                    meditation.color.opacity(colorScheme == .dark ? 0.15 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(meditation.color.opacity(0.2))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: meditation.icon)
                                .font(.quicksand(size: 22, weight: .medium))
                                .foregroundColor(meditation.color)
                        }
                        
                        Text(meditation.duration)
                            .font(.quicksand(size: 12, weight: .semibold))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                    
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(meditation.title)
                        .font(.quicksand(size: 16, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 44, alignment: .top)

                    Text(meditation.subtitle)
                        .font(.quicksand(size: 13, weight: .medium))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 36, alignment: .top)

                    HStack {
                        Circle()
                            .fill(meditation.difficulty.color)
                            .frame(width: 8, height: 8)

                        Text(meditation.difficulty.rawValue)
                            .font(.quicksand(size: 11, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.tertiary)

                        Spacer()
                    }
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
        .padding(16)
        .background(
            TherapeuticCard(elevation: .elevated) {
                Color.clear
            }
        )
    }
}

#Preview {
    MeditationLibraryView()
}