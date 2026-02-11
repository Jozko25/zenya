//
//  DataManager.swift
//  anxiety
//
//  Rewritten to use Supabase instead of Core Data
//

import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let databaseService = DatabaseService.shared
    
    private init() {}
    
    // MARK: - Breathing Sessions
    @MainActor
    func startBreathingSession(technique: String, anxietyBefore: Int? = nil) -> SupabaseBreathingSession? {
        guard let currentUser = databaseService.currentUser else { return nil }
        
        return SupabaseBreathingSession(
            id: UUID(),
            userId: currentUser.id,
            createdAt: Date(),
            technique: technique,
            duration: 0,
            completed: false,
            anxietyBefore: anxietyBefore,
            anxietyAfter: nil,
            effectiveness: nil,
            heartRateBefore: nil,
            heartRateAfter: nil
        )
    }
    
    func completeBreathingSession(_ session: SupabaseBreathingSession, duration: Int, anxietyAfter: Int? = nil) async throws {
        var completedSession = session
        completedSession.completed = true
        completedSession.duration = duration
        completedSession.anxietyAfter = anxietyAfter
        
        try await databaseService.saveBreathingSession(completedSession)
    }
    
    // MARK: - Journal Entries
    @MainActor
    func saveJournalEntry(_ entry: SupabaseJournalEntry) async throws {
        try await databaseService.saveJournalEntry(entry)
    }
    
    @MainActor
    func fetchJournalEntries(limit: Int = 50) async throws -> [SupabaseJournalEntry] {
        guard let currentUser = databaseService.currentUser else { return [] }
        return try await databaseService.getJournalEntries(userId: currentUser.id, limit: limit)
    }
    
    func fetchJournalEntries() -> [SupabaseJournalEntry] {
        // Synchronous version for backwards compatibility
        // TODO: Update UI to use async version
        return []
    }
    
}
