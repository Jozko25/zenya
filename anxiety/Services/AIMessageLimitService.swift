//
//  AIMessageLimitService.swift
//  anxiety
//
//  Created by AI Assistant on 09/09/2025.
//

import Foundation

@MainActor
class AIMessageLimitService: ObservableObject {
    @Published var dailyMessageCount: Int = 0
    @Published var isAtLimit: Bool = false
    
    private let dailyLimit = 30
    private let supabaseClient = SupabaseHTTPClient.shared
    
    static let shared = AIMessageLimitService()
    
    private init() {
        // Initialize with current user session if available
        loadDailyUsageSync()
    }
    
    // MARK: - Public Interface
    
    func loadDailyUsage() async {
        do {
            let usage = try await getCurrentDailyUsage()
            dailyMessageCount = usage.messageCount
            isAtLimit = dailyMessageCount >= dailyLimit
        } catch {
            debugPrint("Error loading daily usage: \(error)")
            // Fallback to UserDefaults if database fails
            loadFromUserDefaults()
        }
    }
    
    func canSendMessage() async -> Bool {
        await loadDailyUsage()
        return dailyMessageCount < dailyLimit
    }
    
    func incrementMessageCount() async -> Bool {
        guard dailyMessageCount < dailyLimit else {
            return false
        }
        
        do {
            try await incrementUsageInDatabase()
            dailyMessageCount += 1
            isAtLimit = dailyMessageCount >= dailyLimit
            
            // Also save to UserDefaults as backup
            saveToUserDefaults()
            return true
        } catch {
            debugPrint("Error incrementing usage: \(error)")
            
            // Fallback to UserDefaults
            if dailyMessageCount < dailyLimit {
                dailyMessageCount += 1
                isAtLimit = dailyMessageCount >= dailyLimit
                saveToUserDefaults()
                return true
            }
            return false
        }
    }
    
    func getRemainingMessages() -> Int {
        return max(0, dailyLimit - dailyMessageCount)
    }
    
    func getDailyLimit() -> Int {
        return dailyLimit
    }
    
    // MARK: - Database Operations
    
    private func getCurrentDailyUsage() async throws -> AIUsageRecord {
        let today = getCurrentDateString()
        
        // For now, since we can't create the table, use a simple approach with user_profiles
        // Store daily usage in a JSON field or use UserDefaults as primary storage
        
        // Fallback to UserDefaults for now until database migration is possible
        throw AIMessageLimitError.databaseError("Database not available - using local storage")
    }
    
    private func incrementUsageInDatabase() async throws {
        // Since we can't create the ai_message_usage table in read-only mode,
        // we'll use UserDefaults as the primary storage mechanism
        // In production, this would use the real database
        throw AIMessageLimitError.databaseError("Database not available - using local storage")
    }
    
    private func getCurrentUserId() -> String? {
        // In a real implementation, this would get the current authenticated user
        // For now, return a placeholder
        return UserDefaults.standard.string(forKey: "current_user_id") ?? "anonymous_user"
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - UserDefaults Implementation
    
    private func loadDailyUsageSync() {
        loadFromUserDefaults()
    }
    
    private func loadFromUserDefaults() {
        let today = Date()
        let calendar = Calendar.current
        let lastResetDate = UserDefaults.standard.object(forKey: "ai_message_last_reset") as? Date ?? Date.distantPast
        
        // Check if we need to reset (new day)
        if calendar.isDate(lastResetDate, inSameDayAs: today) {
            // Same day - load existing count
            dailyMessageCount = UserDefaults.standard.integer(forKey: "ai_message_count")
        } else {
            // New day - reset count
            dailyMessageCount = 0
            saveToUserDefaults()
        }
        
        isAtLimit = dailyMessageCount >= dailyLimit
        debugPrint("📊 AI Message Usage: \(dailyMessageCount)/\(dailyLimit)")
    }
    
    private func saveToUserDefaults() {
        UserDefaults.standard.set(dailyMessageCount, forKey: "ai_message_count")
        UserDefaults.standard.set(Date(), forKey: "ai_message_last_reset")
        debugPrint("💾 Saved AI usage: \(dailyMessageCount)")
    }
}

// MARK: - Data Models

struct AIUsageRecord {
    let messageCount: Int
    let dailyLimit: Int
}

struct AIUsageResponse: Codable {
    let message_count: Int
    let daily_limit: Int
}

struct AIUsageInsert: Codable {
    let user_id: UUID
    let message_date: String
    let message_count: Int
    let daily_limit: Int
}

enum AIMessageLimitError: Error {
    case notAuthenticated
    case limitExceeded
    case databaseError(String)
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .limitExceeded:
            return "Daily message limit exceeded"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}