//
//  EmptyStateView.swift
//  PlanPop
//
//  Friendly message shown when there are no tasks
//

import SwiftUI

/// Displays a friendly empty state message
struct EmptyStateView: View {
    // Which type of empty state to show
    let type: EmptyStateType

    var body: some View {
        VStack(spacing: 20) {
            // Cute illustration/emoji
            Text(type.emoji)
                .font(.system(size: 80))

            // Main message
            Text(type.title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(type.subtitle)
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Types of empty states
enum EmptyStateType {
    case noTasksToday
    case noTasksTomorrow
    case noTasksThisWeek
    case allComplete
    case noTasks

    var emoji: String {
        switch self {
        case .noTasksToday:
            return "🌟"
        case .noTasksTomorrow:
            return "🌅"
        case .noTasksThisWeek:
            return "📅"
        case .allComplete:
            return "🎉"
        case .noTasks:
            return "✨"
        }
    }

    var title: String {
        switch self {
        case .noTasksToday:
            return "Nothing for today!"
        case .noTasksTomorrow:
            return "Tomorrow is clear!"
        case .noTasksThisWeek:
            return "Week looks free!"
        case .allComplete:
            return "You're all done!"
        case .noTasks:
            return "Let's get started!"
        }
    }

    var subtitle: String {
        switch self {
        case .noTasksToday:
            return "Tap + to add your first task for today"
        case .noTasksTomorrow:
            return "No tasks scheduled for tomorrow yet"
        case .noTasksThisWeek:
            return "Plan ahead by adding some tasks"
        case .allComplete:
            return "Great job completing all your tasks! Take a well-deserved break."
        case .noTasks:
            return "Add your first task and start being productive!"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        EmptyStateView(type: .allComplete)
    }
    .background(Theme.background)
}
