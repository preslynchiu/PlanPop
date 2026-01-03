//
//  Achievement.swift
//  PlanPop
//
//  Achievement/badge model for gamification
//

import Foundation

/// Represents an achievement badge that users can unlock
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory

    /// Achievement categories for grouping
    enum AchievementCategory: String, Codable {
        case tasks = "Tasks"
        case streaks = "Streaks"
        case time = "Time"
        case special = "Special"
    }
}

// MARK: - All Achievements

extension Achievement {
    /// All available achievements in the app
    static let all: [Achievement] = [
        // Task completion achievements
        Achievement(
            id: "first_step",
            name: "First Step",
            description: "Complete your first task",
            icon: "figure.walk",
            category: .tasks
        ),
        Achievement(
            id: "high_five",
            name: "High Five",
            description: "Complete 5 tasks",
            icon: "hand.raised.fill",
            category: .tasks
        ),
        Achievement(
            id: "task_master",
            name: "Task Master",
            description: "Complete 25 tasks",
            icon: "checkmark.seal.fill",
            category: .tasks
        ),
        Achievement(
            id: "centurion",
            name: "Centurion",
            description: "Complete 100 tasks",
            icon: "star.circle.fill",
            category: .tasks
        ),

        // Streak achievements
        Achievement(
            id: "streak_starter",
            name: "Streak Starter",
            description: "Get a 3-day streak",
            icon: "flame",
            category: .streaks
        ),
        Achievement(
            id: "week_warrior",
            name: "Week Warrior",
            description: "Get a 7-day streak",
            icon: "flame.fill",
            category: .streaks
        ),
        Achievement(
            id: "monthly_master",
            name: "Monthly Master",
            description: "Get a 30-day streak",
            icon: "bolt.fill",
            category: .streaks
        ),

        // Time-based achievements
        Achievement(
            id: "early_bird",
            name: "Early Bird",
            description: "Complete a task before 8am",
            icon: "sunrise.fill",
            category: .time
        ),
        Achievement(
            id: "night_owl",
            name: "Night Owl",
            description: "Complete a task after 10pm",
            icon: "moon.stars.fill",
            category: .time
        ),

        // Special achievements
        Achievement(
            id: "organizer",
            name: "Organizer",
            description: "Create a custom category",
            icon: "folder.badge.plus",
            category: .special
        ),
        Achievement(
            id: "premium_member",
            name: "Premium Member",
            description: "Upgrade to Premium",
            icon: "crown.fill",
            category: .special
        )
    ]

    /// Get achievement by ID
    static func get(_ id: String) -> Achievement? {
        return all.first { $0.id == id }
    }

    /// Total number of achievements
    static var totalCount: Int {
        return all.count
    }
}

// MARK: - Achievement Checking

extension Achievement {
    /// Check which achievements should be unlocked based on current state
    static func checkUnlocks(
        totalTasksCompleted: Int,
        currentStreak: Int,
        longestStreak: Int,
        categoryCount: Int,
        isPremium: Bool,
        completionHour: Int?,
        alreadyUnlocked: Set<String>
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        // Task completion achievements
        if totalTasksCompleted >= 1 && !alreadyUnlocked.contains("first_step") {
            if let achievement = get("first_step") {
                newlyUnlocked.append(achievement)
            }
        }
        if totalTasksCompleted >= 5 && !alreadyUnlocked.contains("high_five") {
            if let achievement = get("high_five") {
                newlyUnlocked.append(achievement)
            }
        }
        if totalTasksCompleted >= 25 && !alreadyUnlocked.contains("task_master") {
            if let achievement = get("task_master") {
                newlyUnlocked.append(achievement)
            }
        }
        if totalTasksCompleted >= 100 && !alreadyUnlocked.contains("centurion") {
            if let achievement = get("centurion") {
                newlyUnlocked.append(achievement)
            }
        }

        // Streak achievements (check both current and longest)
        let maxStreak = max(currentStreak, longestStreak)
        if maxStreak >= 3 && !alreadyUnlocked.contains("streak_starter") {
            if let achievement = get("streak_starter") {
                newlyUnlocked.append(achievement)
            }
        }
        if maxStreak >= 7 && !alreadyUnlocked.contains("week_warrior") {
            if let achievement = get("week_warrior") {
                newlyUnlocked.append(achievement)
            }
        }
        if maxStreak >= 30 && !alreadyUnlocked.contains("monthly_master") {
            if let achievement = get("monthly_master") {
                newlyUnlocked.append(achievement)
            }
        }

        // Time-based achievements
        if let hour = completionHour {
            if hour < 8 && !alreadyUnlocked.contains("early_bird") {
                if let achievement = get("early_bird") {
                    newlyUnlocked.append(achievement)
                }
            }
            if hour >= 22 && !alreadyUnlocked.contains("night_owl") {
                if let achievement = get("night_owl") {
                    newlyUnlocked.append(achievement)
                }
            }
        }

        // Category achievement (more than default 3)
        if categoryCount > 3 && !alreadyUnlocked.contains("organizer") {
            if let achievement = get("organizer") {
                newlyUnlocked.append(achievement)
            }
        }

        // Premium achievement
        if isPremium && !alreadyUnlocked.contains("premium_member") {
            if let achievement = get("premium_member") {
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }
}
