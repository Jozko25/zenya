//
//  NotificationManager.swift
//  anxiety
//
//  Created by Ján Harmady on 27/08/2025.
//

import SwiftUI
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    debugPrint("Notification permission granted")
                    self.scheduleDailyMoodReminders()
                } else {
                    debugPrint("Notification permission denied")
                }
            }
        }
    }
    
    func scheduleDailyMoodReminders() {
        // Only clear mood-related notifications
        clearMoodNotifications()

        // Schedule daily mood check-in reminders
        let morningReminder = createMoodReminderNotification(
            identifier: "morning-mood",
            title: "Good Morning! 🌅",
            body: "How are you feeling today? Take a moment to track your mood.",
            hour: 9,
            minute: 0
        )

        let eveningReminder = createMoodReminderNotification(
            identifier: "evening-mood",
            title: "End of Day Check-in 🌙",
            body: "How was your day? Log your mood and reflect on your feelings.",
            hour: 20,
            minute: 0
        )
        
        // Schedule the notifications
        UNUserNotificationCenter.current().add(morningReminder)
        UNUserNotificationCenter.current().add(eveningReminder)
        
        // Schedule weekly motivation
        scheduleWeeklyMotivation()
    }

    private func clearMoodNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let moodNotificationIDs = requests.compactMap { request in
                if request.identifier.contains("mood") || request.content.categoryIdentifier == "MOOD_REMINDER" {
                    return request.identifier
                }
                return nil
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: moodNotificationIDs)
        }
    }

    private func createMoodReminderNotification(identifier: String, title: String, body: String, hour: Int, minute: Int) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MOOD_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
    
    private func scheduleWeeklyMotivation() {
        let content = UNMutableNotificationContent()
        content.title = "You're Doing Great! ⭐"
        content.body = "Remember: it's okay to have ups and downs. You're stronger than you think."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WEEKLY_MOTIVATION"
        
        var dateComponents = DateComponents()
        dateComponents.weekday = 2 // Monday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-motivation", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleBreathingReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Take a Deep Breath 🫁"
        content.body = "Feeling stressed? Try a 2-minute breathing exercise to center yourself."
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "BREATHING_REMINDER"
        
        // Trigger in 5 minutes from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        let request = UNNotificationRequest(identifier: "breathing-reminder-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func sendMotivationalPush(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MOTIVATION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleAnalysisCompletedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Reflection Complete ✨"
        content.body = "Your journal analysis is ready. Discover insights about your emotional growth!"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ANALYSIS_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "journal_analysis_complete", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    func setupNotificationCategories() {
        // Mood reminder actions
        let trackMoodAction = UNNotificationAction(
            identifier: "TRACK_MOOD",
            title: "Track Mood",
            options: [.foreground]
        )
        
        let laterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Later",
            options: []
        )
        
        let moodReminderCategory = UNNotificationCategory(
            identifier: "MOOD_REMINDER",
            actions: [trackMoodAction, laterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Breathing reminder actions
        let breatheAction = UNNotificationAction(
            identifier: "START_BREATHING",
            title: "Start Breathing",
            options: [.foreground]
        )
        
        let breathingReminderCategory = UNNotificationCategory(
            identifier: "BREATHING_REMINDER",
            actions: [breatheAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Motivation category
        let motivationCategory = UNNotificationCategory(
            identifier: "MOTIVATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let weeklyMotivationCategory = UNNotificationCategory(
            identifier: "WEEKLY_MOTIVATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let analysisCompleteCategory = UNNotificationCategory(
            identifier: "ANALYSIS_COMPLETE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            moodReminderCategory,
            breathingReminderCategory,
            motivationCategory,
            weeklyMotivationCategory,
            analysisCompleteCategory
        ])
    }
    
    func checkNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}