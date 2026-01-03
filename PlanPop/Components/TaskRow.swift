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

    // Haptic feedback generators
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox button
            Button(action: {
                // Trigger haptic feedback
                if task.isCompleted {
                    // Light tap when uncompleting
                    impactFeedback.impactOccurred()
                } else {
                    // Success feedback when completing
                    successFeedback.notificationOccurred(.success)
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            }) {
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
                            .transition(.scale.combined(with: .opacity))

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 44, height: 44) // Minimum tap target size
                .contentShape(Rectangle()) // Expand tap area
            }
            .buttonStyle(PlainButtonStyle())

            // Task icon (if set)
            if let iconName = task.iconName {
                ZStack {
                    Circle()
                        .fill(Theme.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(task.isCompleted ? Theme.textSecondary : Theme.primary)
                }
            }

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(task.isCompleted ? "Double tap to mark as incomplete" : "Double tap to mark as complete")
        .accessibilityAddTraits(task.isCompleted ? .isSelected : [])
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var label = task.title

        if task.isCompleted {
            label = "Completed: \(label)"
        }

        if task.iconName != nil {
            label += ", Has icon"
        }

        if let category = category {
            label += ", Category: \(category.name)"
        }

        if let dueDate = task.dueDate {
            if task.isOverdue {
                label += ", Overdue"
            } else if Calendar.current.isDateInToday(dueDate) {
                label += ", Due today"
            } else if Calendar.current.isDateInTomorrow(dueDate) {
                label += ", Due tomorrow"
            }
        }

        if task.priority == 3 {
            label += ", High priority"
        }

        if task.hasReminder && !task.isCompleted {
            label += ", Has reminder"
        }

        return label
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
            task: Task(title: "Complete homework", dueDate: Date(), iconName: "book.fill", priority: 3),
            category: Category.defaultCategories[0],
            onToggle: {},
            onTap: {}
        )

        TaskRow(
            task: Task(title: "Practice piano for 30 minutes", isCompleted: true, iconName: "star.fill"),
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
