//
//  TaskSuggestion.swift
//  PlanPop
//
//  Smart task suggestions based on user patterns
//

import Foundation

/// Represents a task suggestion based on detected patterns
struct TaskSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let reason: String
    let icon: String
    let categoryId: UUID?

    static func == (lhs: TaskSuggestion, rhs: TaskSuggestion) -> Bool {
        lhs.title == rhs.title && lhs.reason == rhs.reason
    }
}

/// Tracks task creation patterns for suggestions
struct TaskPatternTracker: Codable, Equatable {
    /// Task titles by day of week (1=Sun...7=Sat)
    var tasksByDayOfWeek: [Int: [String]] = [:]

    /// How many times each task title has been created
    var taskTitleCounts: [String: Int] = [:]

    /// Category usage by day of week
    var categoryByDayOfWeek: [Int: [String: Int]] = [:] // day -> [categoryId: count]

    /// Record a task creation
    mutating func recordTaskCreation(title: String, categoryId: UUID?, date: Date = Date()) {
        let dayOfWeek = Calendar.current.component(.weekday, from: date)

        // Normalize title (lowercase, trimmed)
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Track title by day
        if tasksByDayOfWeek[dayOfWeek] == nil {
            tasksByDayOfWeek[dayOfWeek] = []
        }
        tasksByDayOfWeek[dayOfWeek]?.append(normalizedTitle)

        // Keep only last 20 tasks per day to avoid growing too large
        if let count = tasksByDayOfWeek[dayOfWeek]?.count, count > 20 {
            tasksByDayOfWeek[dayOfWeek]?.removeFirst()
        }

        // Track overall title counts
        taskTitleCounts[normalizedTitle, default: 0] += 1

        // Track category by day
        if let catId = categoryId {
            let catString = catId.uuidString
            if categoryByDayOfWeek[dayOfWeek] == nil {
                categoryByDayOfWeek[dayOfWeek] = [:]
            }
            categoryByDayOfWeek[dayOfWeek]?[catString, default: 0] += 1
        }
    }

    /// Get suggestions for today based on patterns
    func getSuggestions(existingTasks: [Task], categories: [Category]) -> [TaskSuggestion] {
        var suggestions: [TaskSuggestion] = []
        let today = Calendar.current.component(.weekday, from: Date())
        let dayName = dayName(for: today)

        // Get existing task titles (normalized)
        let existingTitles = Set(existingTasks.map {
            $0.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        })

        // Find common tasks for today that aren't already added
        if let todaysTasks = tasksByDayOfWeek[today] {
            // Count occurrences of each task
            var titleCounts: [String: Int] = [:]
            for title in todaysTasks {
                titleCounts[title, default: 0] += 1
            }

            // Find tasks that appear at least 2 times on this day
            for (title, count) in titleCounts where count >= 2 {
                // Skip if already exists today
                if existingTitles.contains(title) { continue }

                // Capitalize first letter for display
                let displayTitle = title.prefix(1).uppercased() + title.dropFirst()

                suggestions.append(TaskSuggestion(
                    title: displayTitle,
                    reason: "You often add this on \(dayName)s",
                    icon: "lightbulb.fill",
                    categoryId: nil
                ))
            }
        }

        // Find most used category for today
        if let todaysCategories = categoryByDayOfWeek[today],
           let topCategoryId = todaysCategories.max(by: { $0.value < $1.value })?.key,
           let uuid = UUID(uuidString: topCategoryId),
           let category = categories.first(where: { $0.id == uuid }) {

            // Only suggest if used at least 3 times on this day
            if todaysCategories[topCategoryId, default: 0] >= 3 {
                // Check if there's no task in this category today
                let hasCategoryTask = existingTasks.contains { $0.categoryId == uuid }
                if !hasCategoryTask {
                    suggestions.append(TaskSuggestion(
                        title: "Add a \(category.name) task",
                        reason: "You usually have \(category.name) tasks on \(dayName)s",
                        icon: category.iconName,
                        categoryId: uuid
                    ))
                }
            }
        }

        // Limit to 2 suggestions
        return Array(suggestions.prefix(2))
    }

    private func dayName(for weekday: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return days[weekday]
    }
}
