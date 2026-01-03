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

    // MARK: - Streak Freeze (Premium Feature)

    /// Number of streak freezes available (premium users get 2/month)
    var streakFreezeCount: Int = 0

    /// Date when freezes were last refreshed (monthly)
    var lastFreezeRefreshDate: Date?

    /// Date when a streak freeze was last used (for display)
    var lastFreezeUsedDate: Date?

    // MARK: - App State

    /// Has the user completed onboarding?
    var hasCompletedOnboarding: Bool = false

    /// Total tasks ever completed
    var totalTasksCompleted: Int = 0

    // MARK: - Achievements

    /// IDs of unlocked achievements
    var unlockedAchievements: Set<String> = []

    // MARK: - Productivity Analytics

    /// Productivity tracking data for insights
    var productivityData: ProductivityData = ProductivityData()

    // MARK: - Daily Challenges

    /// Current daily challenge
    var currentChallenge: DailyChallenge?

    /// Total challenges completed
    var totalChallengesCompleted: Int = 0
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
    /// Uses a streak freeze if available and streak would otherwise break
    mutating func validateStreak() {
        // First, refresh freezes if needed (for premium users)
        refreshFreezesIfNeeded()

        guard let lastDate = lastCompletionDate else { return }
        guard currentStreak > 0 else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // If last completion was today or yesterday, streak is fine
        if lastDay == today || lastDay == yesterday {
            return
        }

        // Streak would break - check if we can use a freeze
        let daysSinceLastCompletion = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

        // Only use freeze if it's been 2 days (missed exactly 1 day)
        // Don't use freeze if multiple days missed
        if daysSinceLastCompletion == 2 && streakFreezeCount > 0 && isPremium {
            // Use a streak freeze!
            streakFreezeCount -= 1
            lastFreezeUsedDate = Date()
            // Update lastCompletionDate to yesterday so streak continues
            lastCompletionDate = yesterday
        } else if daysSinceLastCompletion > 1 {
            // Streak is broken
            currentStreak = 0
        }
    }

    /// Refresh streak freezes monthly for premium users (2 per month)
    mutating func refreshFreezesIfNeeded() {
        guard isPremium else {
            // Non-premium users don't get freezes
            streakFreezeCount = 0
            return
        }

        let today = Date()
        let calendar = Calendar.current

        if let lastRefresh = lastFreezeRefreshDate {
            // Check if we're in a new month
            let lastMonth = calendar.component(.month, from: lastRefresh)
            let lastYear = calendar.component(.year, from: lastRefresh)
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)

            if currentYear > lastYear || currentMonth > lastMonth {
                // New month - refresh freezes
                streakFreezeCount = 2
                lastFreezeRefreshDate = today
            }
        } else {
            // First time - grant freezes
            streakFreezeCount = 2
            lastFreezeRefreshDate = today
        }
    }

    /// Manually use a streak freeze (for future UI if needed)
    mutating func useStreakFreeze() -> Bool {
        guard isPremium && streakFreezeCount > 0 else { return false }
        streakFreezeCount -= 1
        lastFreezeUsedDate = Date()
        return true
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
