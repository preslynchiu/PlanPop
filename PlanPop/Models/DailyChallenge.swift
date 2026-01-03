//
//  DailyChallenge.swift
//  PlanPop
//
//  Daily challenge system for gamification
//

import Foundation

/// Types of daily challenges
enum ChallengeType: String, Codable, CaseIterable {
    case completeTasks      // Complete X tasks today
    case earlyBird          // Complete a task before 9 AM
    case nightOwl           // Complete a task after 8 PM
    case streakKeeper       // Maintain your streak
    case categoryFocus      // Complete 2 tasks in same category
    case allDone            // Complete all tasks for today

    /// Challenge descriptions with target
    var description: String {
        switch self {
        case .completeTasks:
            return "Complete 3 tasks today"
        case .earlyBird:
            return "Complete a task before 9 AM"
        case .nightOwl:
            return "Complete a task after 8 PM"
        case .streakKeeper:
            return "Keep your streak alive!"
        case .categoryFocus:
            return "Complete 2 tasks from the same category"
        case .allDone:
            return "Complete all your tasks for today"
        }
    }

    /// Icon for the challenge
    var icon: String {
        switch self {
        case .completeTasks:
            return "checkmark.circle.fill"
        case .earlyBird:
            return "sunrise.fill"
        case .nightOwl:
            return "moon.stars.fill"
        case .streakKeeper:
            return "flame.fill"
        case .categoryFocus:
            return "folder.fill"
        case .allDone:
            return "star.fill"
        }
    }

    /// Target value for progress-based challenges
    var target: Int {
        switch self {
        case .completeTasks:
            return 3
        case .categoryFocus:
            return 2
        default:
            return 1
        }
    }
}

/// Represents the daily challenge state
struct DailyChallenge: Codable, Equatable {
    /// The type of challenge
    var type: ChallengeType

    /// Date this challenge is for
    var date: Date

    /// Is the challenge completed?
    var isCompleted: Bool = false

    /// Current progress (for multi-step challenges)
    var progress: Int = 0

    /// When was it completed?
    var completedAt: Date?

    /// Get today's challenge (deterministic based on date)
    static func forToday() -> DailyChallenge {
        let today = Calendar.current.startOfDay(for: Date())
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: today) ?? 1
        let challenges = ChallengeType.allCases
        let index = (dayOfYear - 1) % challenges.count
        return DailyChallenge(type: challenges[index], date: today)
    }

    /// Check if this challenge is for today
    var isForToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Progress text (e.g., "1/3")
    var progressText: String {
        "\(min(progress, type.target))/\(type.target)"
    }

    /// Progress percentage (0.0 to 1.0)
    var progressPercent: Double {
        Double(min(progress, type.target)) / Double(type.target)
    }
}

// MARK: - Challenge Checking Logic

extension DailyChallenge {
    /// Check if challenge is completed based on current state
    mutating func checkCompletion(
        tasksCompletedToday: Int,
        completionHour: Int?,
        hasStreak: Bool,
        categoryCompletions: [UUID: Int],
        allTodayTasksDone: Bool
    ) -> Bool {
        guard !isCompleted else { return false }

        var completed = false

        switch type {
        case .completeTasks:
            progress = tasksCompletedToday
            if progress >= type.target {
                completed = true
            }

        case .earlyBird:
            if let hour = completionHour, hour < 9 {
                progress = 1
                completed = true
            }

        case .nightOwl:
            if let hour = completionHour, hour >= 20 {
                progress = 1
                completed = true
            }

        case .streakKeeper:
            if hasStreak {
                progress = 1
                completed = true
            }

        case .categoryFocus:
            // Check if any category has 2+ completions
            let maxInCategory = categoryCompletions.values.max() ?? 0
            progress = maxInCategory
            if maxInCategory >= type.target {
                completed = true
            }

        case .allDone:
            if allTodayTasksDone && tasksCompletedToday > 0 {
                progress = 1
                completed = true
            }
        }

        if completed {
            isCompleted = true
            completedAt = Date()
        }

        return completed
    }
}
