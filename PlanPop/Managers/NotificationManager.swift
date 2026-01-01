//
//  NotificationManager.swift
//  PlanPop
//
//  Handles local push notifications for task reminders
//

import Foundation
import UserNotifications

/// Manages all local notifications for task reminders
class NotificationManager {
    // Singleton instance
    static let shared = NotificationManager()

    private init() {}

    // MARK: - Permission

    /// Request permission to show notifications
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                completion(granted)
            }
        }
    }

    /// Check current notification permission status
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule a reminder notification for a task
    func scheduleReminder(for task: Task) {
        // Make sure task has a reminder date
        guard task.hasReminder, let reminderDate = task.reminderDate else {
            return
        }

        // Don't schedule if the date is in the past
        guard reminderDate > Date() else {
            return
        }

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.badge = 1

        // Create trigger based on reminder date
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )

        // Create the request with task ID as identifier
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        // Add the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Cancel a scheduled reminder for a task
    func cancelReminder(for task: Task) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [task.id.uuidString]
        )
    }

    /// Cancel all pending notifications
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Update reminder when task is edited
    func updateReminder(for task: Task) {
        // First cancel the old one
        cancelReminder(for: task)

        // Schedule new one if task still has reminder
        if task.hasReminder && !task.isCompleted {
            scheduleReminder(for: task)
        }
    }

    // MARK: - Badge Management

    /// Clear the app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
    }
}
