//
//  Task.swift
//  PlanPop
//
//  A model representing a single to-do task
//

import Foundation

/// Represents a single task in the to-do list
struct Task: Identifiable, Codable, Equatable {
    // Unique identifier for each task
    var id: UUID = UUID()

    // The main text of the task (what needs to be done)
    var title: String

    // Optional longer description
    var notes: String = ""

    // Is the task completed?
    var isCompleted: Bool = false

    // When was this task created?
    var createdAt: Date = Date()

    // When is this task due? (optional)
    var dueDate: Date?

    // Should we send a reminder notification?
    var hasReminder: Bool = false

    // When to send the reminder
    var reminderDate: Date?

    // Which category does this task belong to?
    var categoryId: UUID?

    // Icon/sticker for this task (premium feature)
    var iconName: String?

    // Priority level (1 = low, 2 = medium, 3 = high)
    var priority: Int = 2
}

// MARK: - Helper Extensions

extension Task {
    /// Check if task is due today
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    /// Check if task is due tomorrow
    var isDueTomorrow: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInTomorrow(dueDate)
    }

    /// Check if task is due this week
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        let calendar = Calendar.current
        let today = Date()
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: today) else {
            return false
        }
        return dueDate >= today && dueDate <= weekEnd
    }

    /// Check if task is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
}

// MARK: - Available Icons (Premium Feature)

extension Task {
    /// Available icons for tasks (SF Symbols)
    static let availableIcons: [String] = [
        "star.fill",
        "heart.fill",
        "bolt.fill",
        "flag.fill",
        "book.fill",
        "pencil",
        "lightbulb.fill",
        "target",
        "gift.fill",
        "cart.fill",
        "phone.fill",
        "envelope.fill",
        "airplane",
        "car.fill",
        "leaf.fill",
        "sun.max.fill"
    ]
}

// MARK: - Sample Data for Previews

extension Task {
    static let sampleTasks: [Task] = [
        Task(title: "Finish math homework", dueDate: Date(), categoryId: nil, iconName: "book.fill", priority: 3),
        Task(title: "Read chapter 5", notes: "History textbook", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), categoryId: nil, iconName: "pencil", priority: 2),
        Task(title: "Practice piano", dueDate: Date(), categoryId: nil, priority: 1),
        Task(title: "Call grandma", isCompleted: true, dueDate: Date(), categoryId: nil, iconName: "phone.fill")
    ]
}
