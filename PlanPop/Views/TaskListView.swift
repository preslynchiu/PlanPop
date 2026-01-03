//
//  TaskListView.swift
//  PlanPop
//
//  Main task list view with filtering and task management
//

import SwiftUI

/// Main view showing the list of tasks
struct TaskListView: View {
    // Access shared view model
    @EnvironmentObject var viewModel: TaskViewModel

    // Sheet states
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with streak
                    headerView

                    // Daily challenge card
                    if let challenge = viewModel.settings.currentChallenge {
                        DailyChallengeCard(challenge: challenge)
                            .padding(.horizontal, Theme.padding)
                            .padding(.bottom, 8)
                    }

                    // Filter pills
                    filterScrollView

                    // Task list or empty state
                    if viewModel.filteredTasks.isEmpty {
                        emptyStateForCurrentFilter
                    } else {
                        taskList
                    }
                }
            }
            .navigationTitle("PlanPop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Add task button
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(taskToEdit: task)
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Greeting based on time of day
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // Streak badge
                StreakBadge(streak: viewModel.settings.currentStreak)
            }

            // Motivational quote
            Text(MotivationalQuote.todaysQuote)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(Theme.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, Theme.padding)
        .padding(.vertical, Theme.smallPadding)
    }

    // MARK: - Filter Pills

    private var filterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: viewModel.selectedFilter == filter,
                        count: taskCount(for: filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, Theme.smallPadding)
        }
    }

    // MARK: - Task List

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredTasks) { task in
                    TaskRow(
                        task: task,
                        category: viewModel.category(for: task.categoryId),
                        onToggle: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.toggleTaskCompletion(task)
                            }
                        },
                        onTap: {
                            taskToEdit = task
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.padding)
            .padding(.vertical, Theme.smallPadding)
        }
    }

    // MARK: - Empty State

    private var emptyStateForCurrentFilter: some View {
        let type: EmptyStateType = {
            // Check if there are completed tasks for today
            let todaysTasks = viewModel.tasks.filter {
                $0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil)
            }

            if viewModel.selectedFilter == .today && !todaysTasks.isEmpty && todaysTasks.allSatisfy({ $0.isCompleted }) {
                return .allComplete
            }

            switch viewModel.selectedFilter {
            case .today:
                return .noTasksToday
            case .tomorrow:
                return .noTasksTomorrow
            case .thisWeek:
                return .noTasksThisWeek
            default:
                return .noTasks
            }
        }()

        return EmptyStateView(type: type)
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        default:
            return "Good evening!"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private func taskCount(for filter: TaskFilter) -> Int {
        switch filter {
        case .today:
            return viewModel.tasks.filter { !$0.isCompleted && ($0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil)) }.count
        case .tomorrow:
            return viewModel.tasks.filter { !$0.isCompleted && $0.isDueTomorrow }.count
        case .thisWeek:
            return viewModel.tasks.filter { !$0.isCompleted && $0.isDueThisWeek }.count
        case .all:
            return viewModel.tasks.filter { !$0.isCompleted }.count
        case .completed:
            return viewModel.tasks.filter { $0.isCompleted }.count
        }
    }
}

// MARK: - Filter Pill Component

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ?
                                Color.white.opacity(0.3) :
                                Theme.primary.opacity(0.2)
                        )
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.primary : Theme.cardBackground)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) filter, \(count) tasks")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to filter by \(title.lowercased())")
    }
}

// MARK: - Preview

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
}
