//
//  UserSettings.swift
//  PlanPop
//
//  Stores user preferences and premium status
//

import Foundation

/// Stores all user settings and preferences
struct UserSettings: Codable {
    // MARK: - Premium Status

    /// Is the user a premium subscriber?
    var isPremium: Bool = false

    // MARK: - Theme Settings

    /// Current theme (light, dark, or pastel variations)
    var themeName: String = "pastelPink"

    /// Use system appearance setting
    var useSystemAppearance: Bool = true

    // MARK: - Notification Settings

    /// Are notifications enabled?
    var notificationsEnabled: Bool = true

    /// Default reminder time (minutes before due date)
    var defaultReminderMinutes: Int = 30

    // MARK: - Streak Tracking

    /// Current streak (consecutive days with completed tasks)
    var currentStreak: Int = 0

    /// Longest streak ever achieved
    var longestStreak: Int = 0

    /// Last date when at least one task was completed
    var lastCompletionDate: Date?

    // MARK: - App State

    /// Has the user completed onboarding?
    var hasCompletedOnboarding: Bool = false

    /// Total tasks ever completed
    var totalTasksCompleted: Int = 0
}

// MARK: - Streak Logic

extension UserSettings {
    /// Update streak when a task is completed
    mutating func recordTaskCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        totalTasksCompleted += 1

        if let lastDate = lastCompletionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)

            if lastDay == today {
                // Already completed a task today, streak unchanged
                return
            }

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                // Completed yesterday, continue streak!
                currentStreak += 1
            } else {
                // Streak broken, start over
                currentStreak = 1
            }
        } else {
            // First ever completion
            currentStreak = 1
        }

        // Update longest streak if needed
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastCompletionDate = today
    }

    /// Check if streak is still valid (called on app launch)
    mutating func validateStreak() {
        guard let lastDate = lastCompletionDate else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // If last completion wasn't today or yesterday, streak is broken
        if lastDay != today && lastDay != yesterday {
            currentStreak = 0
        }
    }
}

// MARK: - Theme Options

enum AppTheme: String, CaseIterable, Codable {
    case pastelPink = "pastelPink"
    case pastelBlue = "pastelBlue"
    case pastelGreen = "pastelGreen"
    case pastelPurple = "pastelPurple"
    case light = "light"
    case dark = "dark"

    /// Display name for the theme
    var displayName: String {
        switch self {
        case .pastelPink: return "Cotton Candy"
        case .pastelBlue: return "Ocean Breeze"
        case .pastelGreen: return "Mint Fresh"
        case .pastelPurple: return "Lavender Dream"
        case .light: return "Classic Light"
        case .dark: return "Night Mode"
        }
    }

    /// Whether this is a premium theme
    var isPremiumOnly: Bool {
        switch self {
        case .pastelPink, .light:
            return false
        default:
            return true
        }
    }
}
