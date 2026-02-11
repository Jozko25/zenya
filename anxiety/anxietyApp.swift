//
//  anxietyApp.swift
//  anxiety
//
//  Created by Ján Harmady on 27/08/2025.
//

import SwiftUI
import UserNotifications

@main
struct anxietyApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    init() {
        suppressLayoutWarnings()
        _ = FontLoader.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(databaseService)
                .environmentObject(notificationDelegate)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func suppressLayoutWarnings() {
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        setupNotificationCategories()

        // Request permission immediately if not already determined
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                NotificationManager.shared.requestPermission()
            }
        }
    }

    private func setupNotificationCategories() {
        // Reflection reminder actions
        let reflectNowAction = UNNotificationAction(
            identifier: "REFLECT_NOW",
            title: "Reflect Now",
            options: [.foreground]
        )

        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Later",
            options: []
        )

        let reflectionCategory = UNNotificationCategory(
            identifier: "REFLECTION_REMINDER",
            actions: [reflectNowAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )

        // Mood reminder actions
        let logMoodAction = UNNotificationAction(
            identifier: "LOG_MOOD",
            title: "Log Mood",
            options: [.foreground]
        )

        let moodCategory = UNNotificationCategory(
            identifier: "MOOD_REMINDER",
            actions: [logMoodAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Analysis complete actions
        let viewAnalysisAction = UNNotificationAction(
            identifier: "VIEW_ANALYSIS",
            title: "View Insights",
            options: [.foreground]
        )
        
        let analysisCategory = UNNotificationCategory(
            identifier: "ANALYSIS_COMPLETE",
            actions: [viewAnalysisAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            reflectionCategory,
            moodCategory,
            analysisCategory
        ])
    }
}

// MARK: - Notification Delegate

@MainActor
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var shouldOpenReflectionModal = false
    @Published var shouldOpenEvaluations = false

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let identifier = response.notification.request.identifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier

        // Handle different notification types
        switch categoryIdentifier {
        case "REFLECTION_REMINDER":
            handleReflectionNotification(response, completionHandler: completionHandler)
        case "MOOD_REMINDER":
            handleMoodNotification(response)
            completionHandler()
        case "ANALYSIS_COMPLETE":
            handleAnalysisNotification(response)
            completionHandler()
        default:
            // Handle legacy notifications without categories
            if identifier.contains("reflection") {
                handleReflectionNotification(response, completionHandler: completionHandler)
            } else if identifier.contains("mood") {
                handleMoodNotification(response)
                completionHandler()
            } else if identifier.contains("analysis") {
                handleAnalysisNotification(response)
                completionHandler()
            } else {
                completionHandler()
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.alert, .sound, .badge])
    }

    private func handleReflectionNotification(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "REFLECT_NOW", UNNotificationDefaultActionIdentifier:
            // Check if user can currently submit a journal entry
            if let currentUser = DatabaseService.shared.currentUser {
                Task {
                    let reflectionManager = ReflectionNotificationManager.shared
                    if await reflectionManager.canUserSubmitJournalEntry(userId: currentUser.id) {
                        await MainActor.run {
                            shouldOpenReflectionModal = true
                            NotificationCenter.default.post(name: NSNotification.Name("OpenReflectionModal"), object: nil)
                        }
                    } else {
                        // User is on cooldown - show cooldown message and reschedule
                        if let cooldownTime = await reflectionManager.getCooldownTimeString(userId: currentUser.id) {
                            let content = UNMutableNotificationContent()
                            content.title = "Still on Cooldown ⏳"
                            content.body = "You can reflect again in \(cooldownTime). Taking breaks between reflections helps with deeper insights!"
                            content.sound = .default

                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                            let request = UNNotificationRequest(identifier: "cooldown_notice_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)

                            do {
                                try await UNUserNotificationCenter.current().add(request)
                            } catch {
                                debugPrint("❌ Error scheduling cooldown notice: \(error)")
                            }
                        }
                    }

                    // Call completion handler after async work is done
                    completionHandler()
                }
            } else {
                // No current user - still open modal (should not happen in normal flow)
                shouldOpenReflectionModal = true
                NotificationCenter.default.post(name: NSNotification.Name("OpenReflectionModal"), object: nil)
                completionHandler()
            }
        case "REMIND_LATER":
            scheduleDelayedReminder(type: .reflection)
            completionHandler()
        default:
            completionHandler()
            break
        }
    }

    private func handleMoodNotification(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "LOG_MOOD", UNNotificationDefaultActionIdentifier:
            NotificationCenter.default.post(name: NSNotification.Name("OpenMoodTracker"), object: nil)
        case "REMIND_LATER":
            scheduleDelayedReminder(type: .mood)
        default:
            break
        }
    }
    
    private func handleAnalysisNotification(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "VIEW_ANALYSIS", UNNotificationDefaultActionIdentifier:
            shouldOpenEvaluations = true
            NotificationCenter.default.post(name: NSNotification.Name("OpenEvaluations"), object: nil)
        default:
            break
        }
    }

    enum NotificationType {
        case reflection
        case mood
    }

    private func scheduleDelayedReminder(type: NotificationType) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        switch type {
        case .reflection:
            content.title = "Gentle Reminder 💭"
            content.body = "Ready to reflect now? Take a few minutes to check in with yourself."
            content.categoryIdentifier = "REFLECTION_REMINDER"
        case .mood:
            content.title = "Mood Check 🌟"
            content.body = "How are you feeling right now? Track your mood to see your progress."
            content.categoryIdentifier = "MOOD_REMINDER"
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false) // 30 minutes
        let identifier = "delayed_\(type == .reflection ? "reflection" : "mood")_reminder_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugPrint("❌ Error scheduling delayed reminder: \(error)")
            }
        }
    }
}
