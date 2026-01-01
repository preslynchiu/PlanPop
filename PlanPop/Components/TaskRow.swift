//
//  TaskRow.swift
//  PlanPop
//
//  A single row displaying a task in the list
//

import SwiftUI

/// Displays a single task row with checkbox, title, and category
struct TaskRow: View {
    // The task to display
    let task: Task

    // Optional category for this task
    let category: Category?

    // Action when checkbox is tapped
    var onToggle: () -> Void

    // Action when row is tapped (for editing)
    var onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox button
            Button(action: onToggle) {
                ZStack {
                    // Outer circle
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? Theme.success : Theme.primary,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    // Filled circle when completed
                    if task.isCompleted {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                // Task title
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                // Subtitle row (category, due date, etc.)
                HStack(spacing: 8) {
                    // Category badge
                    if let category = category {
                        HStack(spacing: 4) {
                            Image(systemName: category.iconName)
                                .font(.caption2)
                            Text(category.name)
                                .font(.caption)
                        }
                        .foregroundColor(category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.15))
                        .cornerRadius(Theme.smallCornerRadius)
                    }

                    // Due date/time
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: task.isOverdue ? "exclamationmark.circle.fill" : "clock")
                                .font(.caption2)
                            Text(formattedDueDate(dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(task.isOverdue ? Theme.error : Theme.textSecondary)
                    }

                    // Reminder indicator
                    if task.hasReminder && !task.isCompleted {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.warning)
                    }
                }
            }

            Spacer()

            // Priority indicator
            if task.priority == 3 && !task.isCompleted {
                Image(systemName: "exclamationmark.2")
                    .font(.caption)
                    .foregroundColor(Theme.error)
            }

            // Chevron for navigation
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textSecondary.opacity(0.5))
        }
        .padding(Theme.padding)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // Format the due date nicely
    private func formattedDueDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TaskRow(
            task: Task(title: "Complete homework", dueDate: Date(), priority: 3),
            category: Category.defaultCategories[0],
            onToggle: {},
            onTap: {}
        )

        TaskRow(
            task: Task(title: "Practice piano for 30 minutes", isCompleted: true),
            category: nil,
            onToggle: {},
            onTap: {}
        )

        TaskRow(
            task: Task(title: "Read chapter 5", dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())),
            category: Category.defaultCategories[0],
            onToggle: {},
            onTap: {}
        )
    }
    .padding()
    .background(Theme.background)
}
