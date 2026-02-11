//
//  ReflectionNotificationManager.swift
//  anxiety
//
//  Created by Claude Code on 09/09/2025.
//

import Foundation
import UserNotifications
import UIKit

class ReflectionNotificationManager: ObservableObject {
    static let shared = ReflectionNotificationManager()
    
    private init() {}
    
    // MARK: - Notification Setup
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    debugPrint("✅ Notification permission granted")
                    self.scheduleReflectionReminders()
                } else {
                    debugPrint("❌ Notification permission denied")
                }
            }
        }
    }
    
    // MARK: - Scheduling Notifications
    
    func scheduleReflectionReminders() {
        // Schedule next reflection reminder based on cooldown
        Task { @MainActor in
            // Remove only reflection-related notifications
            await clearReflectionNotifications()

            // Migrate local data if needed
            if let currentUser = DatabaseService.shared.currentUser {
                await migrateLocalCooldownDataIfNeeded(userId: currentUser.id)
            }

            await scheduleNextCooldownBasedReminder()
        }

        debugPrint("📅 Scheduled cooldown-based reflection reminder")
    }

    private func clearReflectionNotifications() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let reflectionNotificationIDs = requests.compactMap { request in
            if request.identifier.contains("reflection") || request.content.categoryIdentifier == "REFLECTION_REMINDER" {
                return request.identifier
            }
            return nil
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: reflectionNotificationIDs)
    }

    @MainActor
    private func scheduleNextCooldownBasedReminder() async {
        guard let currentUser = DatabaseService.shared.currentUser else {
            debugPrint("❌ No current user - cannot schedule reflection reminder")
            return
        }

        let userId = currentUser.id
        let currentTime = Date()

        // Calculate when to schedule the next notification
        let nextNotificationTime: Date

        let userOnCooldown = await isUserOnCooldown(userId: userId)
        if userOnCooldown {
            // User is on cooldown - schedule notification for when cooldown expires
            nextNotificationTime = (await getNextSubmissionTime(userId: userId)) ?? currentTime
            debugPrint("⏳ User on cooldown - scheduling reflection reminder for \(nextNotificationTime)")
        } else {
            // User not on cooldown - do NOT schedule any reflection reminder
            debugPrint("🛑 User not on cooldown - no reflection reminder scheduled")
            return
        }

        let timeInterval = nextNotificationTime.timeIntervalSince(currentTime)

        // Don't schedule past notifications or notifications less than 30 seconds away
        guard timeInterval > 30 else {
            debugPrint("⚠️ Cannot schedule notification too close to current time or in the past")
            return
        }

        // Context-aware messages based on time of day
        let hour = Calendar.current.component(.hour, from: nextNotificationTime)
        let reflectionMessage = getContextualMessage(for: hour)

        let content = UNMutableNotificationContent()
        content.title = reflectionMessage.title
        content.body = reflectionMessage.body
        content.sound = .default
        content.categoryIdentifier = "REFLECTION_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(
            identifier: "cooldown_based_reflection_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            debugPrint("✅ Cooldown-based reflection reminder scheduled for \(nextNotificationTime)")
        } catch {
            debugPrint("❌ Error scheduling cooldown-based reflection reminder: \(error)")
        }
    }

    // MARK: - Contextual Notification Messages

    private struct NotificationMessage {
        let title: String
        let body: String
    }

    private func getContextualMessage(for hour: Int) -> NotificationMessage {
        // Morning messages (6 AM - 11 AM)
        let morningMessages = [
            NotificationMessage(
                title: "Good Morning",
                body: "Start your day with intention. How are you feeling this morning?"
            ),
            NotificationMessage(
                title: "Morning Check-in",
                body: "A new day, a fresh start. Take a moment to set your intentions."
            ),
            NotificationMessage(
                title: "Rise & Reflect",
                body: "Before the day sweeps you away, pause and check in with yourself."
            )
        ]

        // Afternoon messages (12 PM - 4 PM)
        let afternoonMessages = [
            NotificationMessage(
                title: "Midday Pause",
                body: "Take a breath. How has your day been so far?"
            ),
            NotificationMessage(
                title: "Afternoon Check-in",
                body: "A moment of reflection can reset your entire afternoon."
            ),
            NotificationMessage(
                title: "Pause & Reflect",
                body: "Step away from the noise. What's on your mind right now?"
            )
        ]

        // Evening messages (5 PM - 9 PM)
        let eveningMessages = [
            NotificationMessage(
                title: "Evening Reflection",
                body: "As the day winds down, take a moment to process and let go."
            ),
            NotificationMessage(
                title: "Day's End Check-in",
                body: "Reflect on your day. What moments stood out to you?"
            ),
            NotificationMessage(
                title: "Unwind & Reflect",
                body: "Before you rest, capture your thoughts and feelings."
            )
        ]

        // Night messages (10 PM - 5 AM)
        let nightMessages = [
            NotificationMessage(
                title: "Late Night Thoughts",
                body: "Can't sleep? Sometimes writing helps clear the mind."
            ),
            NotificationMessage(
                title: "Quiet Moment",
                body: "The world is quiet. A perfect time for reflection."
            )
        ]

        // Select message based on time
        let messages: [NotificationMessage]
        switch hour {
        case 6...11:
            messages = morningMessages
        case 12...16:
            messages = afternoonMessages
        case 17...21:
            messages = eveningMessages
        default:
            messages = nightMessages
        }

        // Use consistent but varied selection based on day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return messages[dayOfYear % messages.count]
    }

    private func schedule4HourIntervalReminders() async {
        let reflectionMessages = [
            ("Time to Reflect", "How are you feeling right now? Take a moment to check in with yourself."),
            ("Mindful Moment", "Pause and reflect on your current thoughts and emotions."),
            ("Reflection Check-in", "What's on your mind? Take a few minutes to journal your feelings."),
            ("Self-Awareness Break", "Notice what you're experiencing in this moment. How can you care for yourself?"),
            ("Emotional Check-in", "Take time to acknowledge and process your current emotional state."),
            ("Mindfulness Reminder", "Step back and reflect on your inner world. What do you notice?")
        ]
        
        // Schedule 6 notifications throughout the day, every 4 hours starting at 8 AM
        let startHours = [8, 12, 16, 20, 0, 4]
        
        for (index, hour) in startHours.enumerated() {
            let message = reflectionMessages[index % reflectionMessages.count]
            
            let content = UNMutableNotificationContent()
            content.title = message.0
            content.body = message.1
            content.sound = .default
            content.categoryIdentifier = "REFLECTION_REMINDER"
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(
                identifier: "reflection_reminder_\(hour)h",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                debugPrint("✅ Reflection reminder scheduled for \(hour):00")
            } catch {
                debugPrint("❌ Error scheduling \(hour):00 reflection reminder: \(error)")
            }
        }
    }
    
    // MARK: - Smart Notifications (Don't notify if already reflected)
    
    @MainActor
    func checkAndScheduleSmartReminders() {
        guard let currentUser = DatabaseService.shared.currentUser else { return }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Check if user has reflected in the current 4-hour window
        let currentWindow = get4HourWindow(for: currentHour)
        
        if hasUserReflectedInWindow(userId: currentUser.id, window: currentWindow) {
            debugPrint("✅ User has already reflected in the \(currentWindow) window")
        } else {
            debugPrint("⏰ User hasn't reflected in the \(currentWindow) window - keeping reminder active")
        }
    }
    
    private func get4HourWindow(for hour: Int) -> String {
        switch hour {
        case 8..<12: return "8-12"
        case 12..<16: return "12-16" 
        case 16..<20: return "16-20"
        case 20..<24: return "20-24"
        case 0..<4: return "0-4"
        case 4..<8: return "4-8"
        default: return "unknown"
        }
    }
    
    private func hasUserReflectedInWindow(userId: UUID, window: String) -> Bool {
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: Date())?.start.timeIntervalSince1970 ?? 0
        let key = "journal_submission_\(userId.uuidString)_window_\(window)_\(today)"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    // MARK: - Submission-Based Cooldown System
    
    func getCooldownHours() -> Int {
        return 4 // Default cooldown period in hours
    }
    
    // MARK: - Dev Testing (Remove before production)
    #if DEBUG
    /// Reset cooldown for testing - sets an override flag to bypass checks
    func devResetCooldown(userId: UUID) {
        let key = "dev_override_cooldown_\(userId.uuidString)"
        UserDefaults.standard.set(true, forKey: key)
        debugPrint("🧪 DEV: Cooldown enforced override enabled for user \(userId)")
        
        // Also clear the legacy key just in case
        let legacyKey = "last_journal_submission_\(userId.uuidString)"
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
    #endif
    
    func recordJournalSubmission(userId: UUID) {
        debugPrint("📝 Recording journal submission for user: \(userId)")
        
        // Clear dev override on new submission
        let overrideKey = "dev_override_cooldown_\(userId.uuidString)"
        UserDefaults.standard.removeObject(forKey: overrideKey)

        // Reschedule next notification for when cooldown expires
        Task { @MainActor in
            // Clear any pending reflection notifications since user just submitted
            await clearReflectionNotifications()

            await scheduleNextCooldownBasedReminder()
        }
    }
    
    func getLastSubmissionTime(userId: UUID) async -> Date? {
        do {
            // Get the most recent journal entry from database
            let entries = try await DatabaseService.shared.getJournalEntries(userId: userId, limit: 1)
            return entries.first?.createdAt
        } catch {
            debugPrint("❌ Error fetching last submission time from database: \(error)")

            // Fallback to UserDefaults for backward compatibility
            let key = "last_journal_submission_\(userId.uuidString)"
            let localTime = UserDefaults.standard.object(forKey: key) as? Date
            debugPrint("📱 Using local fallback time: \(String(describing: localTime))")
            return localTime
        }
    }
    
    func getNextSubmissionTime(userId: UUID) async -> Date? {
        guard let lastSubmissionTime = await getLastSubmissionTime(userId: userId) else {
            return nil // No previous submission, no cooldown
        }

        let cooldownHours = getCooldownHours()
        return Calendar.current.date(byAdding: .hour, value: cooldownHours, to: lastSubmissionTime)
    }

    func isUserOnCooldown(userId: UUID) async -> Bool {
        // Check dev override first
        let overrideKey = "dev_override_cooldown_\(userId.uuidString)"
        if UserDefaults.standard.bool(forKey: overrideKey) {
            debugPrint("🧪 DEV: Cooldown overridden - allowing submission")
            return false
        }
        
        guard let nextSubmissionTime = await getNextSubmissionTime(userId: userId) else {
            return false // No previous submission, no cooldown
        }

        return Date() < nextSubmissionTime
    }

    func getRemainingCooldownTime(userId: UUID) async -> TimeInterval {
        // Check dev override
        let overrideKey = "dev_override_cooldown_\(userId.uuidString)"
        if UserDefaults.standard.bool(forKey: overrideKey) {
            return 0
        }
        
        guard let nextSubmissionTime = await getNextSubmissionTime(userId: userId) else {
            return 0 // No cooldown
        }

        let remainingTime = nextSubmissionTime.timeIntervalSince(Date())
        return max(0, remainingTime)
    }

    // Check if user can currently submit a journal entry
    func canUserSubmitJournalEntry(userId: UUID) async -> Bool {
        return !(await isUserOnCooldown(userId: userId))
    }

    // Get formatted string for remaining cooldown time
    func getCooldownTimeString(userId: UUID) async -> String? {
        let remainingTime = await getRemainingCooldownTime(userId: userId)

        guard remainingTime > 0 else { return nil }

        let hours = Int(remainingTime) / 3600
        let minutes = Int(remainingTime.truncatingRemainder(dividingBy: 3600)) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Migration Helper

    func migrateLocalCooldownDataIfNeeded(userId: UUID) async {
        let key = "last_journal_submission_\(userId.uuidString)"
        guard let localSubmissionTime = UserDefaults.standard.object(forKey: key) as? Date else {
            debugPrint("📱 No local cooldown data to migrate")
            return
        }

        do {
            // Check if we have any database entries
            let entries = try await DatabaseService.shared.getJournalEntries(userId: userId, limit: 1)

            if entries.isEmpty {
                // No database entries but we have local cooldown data
                // This suggests user has only used local storage
                debugPrint("🔄 Found local cooldown data but no database entries - keeping local fallback")
            } else if let latestEntry = entries.first {
                // Compare times and clean up if database is newer
                if latestEntry.createdAt > localSubmissionTime {
                    UserDefaults.standard.removeObject(forKey: key)
                    debugPrint("🧹 Cleaned up outdated local cooldown data - using database time")
                }
            }
        } catch {
            debugPrint("❌ Error during cooldown migration: \(error)")
            debugPrint("📱 Keeping local cooldown data as fallback")
        }
    }

    // MARK: - Legacy 4-Hour Window System (for backward compatibility)
    
    func getNextResetTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        // Find the next 4-hour window boundary
        let nextBoundaryHour: Int
        switch currentHour {
        case 0..<4: nextBoundaryHour = 4
        case 4..<8: nextBoundaryHour = 8
        case 8..<12: nextBoundaryHour = 12
        case 12..<16: nextBoundaryHour = 16
        case 16..<20: nextBoundaryHour = 20
        case 20..<24: nextBoundaryHour = 24
        default: nextBoundaryHour = 24
        }
        
        if nextBoundaryHour == 24 {
            // Next boundary is midnight tomorrow
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) ?? now
        } else {
            return calendar.date(bySettingHour: nextBoundaryHour, minute: 0, second: 0, of: now) ?? now
        }
    }
    
    func getCurrentPeriod() -> String {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return get4HourWindow(for: currentHour)
    }
    
    // MARK: - Helper Methods
    
    private func hasUserSubmittedToday(userId: UUID, timeSlot: GamifiedJournalEntryView.TimeSlot) -> Bool {
        let calendar = Calendar.current
        let key = "journal_submission_\(userId.uuidString)_\(timeSlot)_\(calendar.dateInterval(of: .day, for: Date())?.start.timeIntervalSince1970 ?? 0)"
        return UserDefaults.standard.bool(forKey: key)
    }
}


// MARK: - Notification Categories

extension ReflectionNotificationManager {
    func setupNotificationCategories() {
        let reflectAction = UNNotificationAction(
            identifier: "REFLECT_NOW",
            title: "Reflect Now",
            options: [.foreground]
        )
        
        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Later",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "REFLECTION_REMINDER",
            actions: [reflectAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}