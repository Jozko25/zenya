//
//  JournalListModalView.swift
//  anxiety
//
//  Modal view for displaying journal entries list
//

import SwiftUI

struct JournalListModalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var databaseService = DatabaseService.shared
    @State private var journalEntries: [SupabaseJournalEntry] = []
    @State private var isLoading = true
    @State private var showNewEntry = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AdaptiveColors.Background.primary,
                        AdaptiveColors.Background.secondary.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AdaptiveColors.Action.mood)
                        
                        Text("Loading your reflections...")
                            .font(.quicksand(size: 14, weight: .medium))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                    }
                } else if journalEntries.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Icon
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(AdaptiveColors.Action.mood.opacity(0.5))
                        
                        VStack(spacing: 12) {
                            Text("No Journal Entries Yet")
                                .font(.quicksand(size: 22, weight: .bold))
                                .foregroundColor(AdaptiveColors.Text.primary)
                            
                            Text("Start your wellness journey by\ncreating your first reflection")
                                .font(.quicksand(size: 14, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Create button - 3D style matching home page
                        Button(action: {
                            showNewEntry = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "pencil.and.outline")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Reflect")
                                    .font(.quicksand(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 170, height: 52)
                            .background(
                                ZStack {
                                    // Shadow layer for 3D effect
                                    Capsule()
                                        .fill(Color(hex: "C83555"))
                                        .offset(y: 3)

                                    // Main gradient
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "FF7A95"),
                                                    Color(hex: "FF5C7A"),
                                                    Color(hex: "D94467")
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )

                                    // Highlight
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: Color(hex: "FF5C7A").opacity(0.4), radius: 16, x: 0, y: 8)
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                } else {
                    // Journal entries list
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16, pinnedViews: []) {
                            // Header with count
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Your Reflections")
                                        .font(.quicksand(size: 24, weight: .bold))
                                        .foregroundColor(AdaptiveColors.Text.primary)
                                    
                                    Text("\(journalEntries.count) entries")
                                        .font(.quicksand(size: 14, weight: .medium))
                                        .foregroundColor(AdaptiveColors.Text.secondary)
                                }
                                
                                Spacer()
                                
                                // New entry button
                                Button(action: {
                                    showNewEntry = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.quicksand(size: 24, weight: .medium))
                                        .foregroundColor(AdaptiveColors.Action.mood)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Journal entries
                            ForEach(journalEntries) { entry in
                                JournalEntryModalCard(entry: entry)
                                    .padding(.horizontal, 20)
                                    .id(entry.id)
                            }
                            
                            // Bottom padding for scrolling
                            Color.clear.frame(height: 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Journal")
                        .font(.quicksand(size: 18, weight: .bold))
                        .foregroundColor(AdaptiveColors.Text.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.quicksand(size: 16, weight: .semibold))
                    .foregroundColor(AdaptiveColors.Action.mood)
                }
            }
        }
        .task {
            await loadJournalEntries()
        }
        .fullScreenCover(isPresented: $showNewEntry) {
            GamifiedJournalEntryView()
        }
        .refreshable {
            await loadJournalEntries()
        }
    }
    
    private func loadJournalEntries() async {
        isLoading = true
        
        guard let userId = databaseService.currentUser?.id else {
            isLoading = false
            return
        }
        
        do {
            let entries = try await databaseService.getJournalEntries(userId: userId, limit: 50)
            await MainActor.run {
                self.journalEntries = entries
                self.isLoading = false
            }
        } catch {
            debugPrint("Error loading journal entries: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

// MARK: - Journal Entry Card

struct JournalEntryModalCard: View {
    let entry: SupabaseJournalEntry
    @State private var isExpanded = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }
    
    private var moodEmoji: String {
        guard let mood = entry.mood else { return "😐" }
        switch mood {
        case 8...10: return "😊"
        case 6..<8: return "🙂"
        case 4..<6: return "😐"
        case 2..<4: return "😔"
        default: return "😢"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Mood indicator
                Text(moodEmoji)
                    .font(.quicksand(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.quicksand(size: 12, weight: .semibold))
                        .foregroundColor(AdaptiveColors.Text.secondary)
                    
                    if let mood = entry.mood {
                        HStack(spacing: 4) {
                            Text("Mood:")
                                .font(.quicksand(size: 11, weight: .medium))
                                .foregroundColor(AdaptiveColors.Text.tertiary)
                            
                            Text("\(Int(mood))/10")
                                .font(.quicksand(size: 11, weight: .bold))
                                .foregroundColor(moodColor(for: Double(mood)))
                        }
                    }
                }
                
                Spacer()
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle" : "chevron.down.circle")
                        .font(.quicksand(size: 18, weight: .medium))
                        .foregroundColor(AdaptiveColors.Action.mood)
                }
            }
            
            // Content preview or full
            Text(entry.content)
                .font(.quicksand(size: 14, weight: .medium))
                .foregroundColor(AdaptiveColors.Text.primary)
                .lineLimit(isExpanded ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Tags if present
            if let tags = entry.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.quicksand(size: 11, weight: .semibold))
                                .foregroundColor(AdaptiveColors.Action.mood)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(AdaptiveColors.Action.mood.opacity(0.15))
                                )
                        }
                    }
                }
            }
            
            // Gratitude items if expanded and present
            if isExpanded {
                if let gratitude = entry.gratitudeItems, !gratitude.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gratitude")
                            .font(.quicksand(size: 12, weight: .bold))
                            .foregroundColor(AdaptiveColors.Text.secondary)
                        
                        ForEach(gratitude, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "heart.fill")
                                    .font(.quicksand(size: 10))
                                    .foregroundColor(AdaptiveColors.Action.sos.opacity(0.6))
                                
                                Text(item)
                                    .font(.quicksand(size: 13, weight: .medium))
                                    .foregroundColor(AdaptiveColors.Text.primary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.Surface.card)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func moodColor(for mood: Double) -> Color {
        switch mood {
        case 8...10: return AdaptiveColors.Action.progress
        case 6..<8: return AdaptiveColors.Action.mood
        case 4..<6: return Color.orange
        default: return AdaptiveColors.Action.sos
        }
    }
}

#Preview {
    JournalListModalView()
}