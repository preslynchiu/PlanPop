//
//  TaskViewModel.swift
//  PlanPop
//
//  Main view model for managing tasks and categories
//

import Foundation
import SwiftUI

/// Main view model that manages all task and category operations
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties (UI updates when these change)

    /// All tasks
    @Published var tasks: [Task] = []

    /// All categories
    @Published var categories: [Category] = []

    /// User settings
    @Published var settings: UserSettings = UserSettings()

    /// Show confetti animation
    @Published var showConfetti: Bool = false

    /// Currently selected filter
    @Published var selectedFilter: TaskFilter = .today

    /// Newly unlocked achievement (for celebration UI)
    @Published var newlyUnlockedAchievement: Achievement?

    /// Daily challenge completed (for celebration UI)
    @Published var challengeJustCompleted: Bool = false

    // MARK: - Constants

    /// Maximum categories for free users
    let maxFreeCategories = 3

    // MARK: - Initialization

    init() {
        loadData()
    }

    /// Load all data from storage
    func loadData() {
        tasks = PersistenceManager.shared.loadTasks()
        categories = PersistenceManager.shared.loadCategories()
        settings = PersistenceManager.shared.loadSettings()

        // Initialize or refresh daily challenge
        refreshDailyChallenge()
    }

    /// Refresh the daily challenge if needed
    private func refreshDailyChallenge() {
        if let existing = settings.currentChallenge, existing.isForToday {
            // Challenge is still valid for today
            return
        }

        // Create new challenge for today
        settings.currentChallenge = DailyChallenge.forToday()
        saveSettings()
    }

    // MARK: - Task CRUD Operations

    /// Add a new task
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()

        // Record pattern for suggestions
        settings.taskPatterns.recordTaskCreation(
            title: task.title,
            categoryId: task.categoryId
        )
        saveSettings()

        // Schedule notification if needed
        if task.hasReminder {
            NotificationManager.shared.scheduleReminder(for: task)
        }
    }

    /// Update an existing task
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()

            // Update notification
            NotificationManager.shared.updateReminder(for: task)
        }
    }

    /// Delete a task
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()

        // Cancel any pending notification
        NotificationManager.shared.cancelReminder(for: task)
    }

    /// Toggle task completion status
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()

            // If completing the task, record for streak
            if tasks[index].isCompleted {
                let now = Date()

                // Play completion sound
                SoundManager.shared.playTaskComplete()

                // Record completion timestamp
                tasks[index].completedAt = now

                // Record for streak tracking
                settings.recordTaskCompletion()

                // Record for productivity analytics
                settings.productivityData.recordCompletion(at: now)

                saveSettings()

                // Cancel reminder since task is done
                NotificationManager.shared.cancelReminder(for: tasks[index])

                // Check for achievements
                checkForAchievements()

                // Check daily challenge
                checkDailyChallenge()

                // Check if all tasks for today are complete
                checkForConfetti()
            } else {
                // Play uncomplete sound
                SoundManager.shared.playTaskUncomplete()

                // Clear completion timestamp when uncompleting
                tasks[index].completedAt = nil
            }

            saveTasks()
        }
    }

    /// Delete multiple tasks at once
    func deleteTasks(at offsets: IndexSet, from filteredTasks: [Task]) {
        let tasksToDelete = offsets.map { filteredTasks[$0] }
        for task in tasksToDelete {
            deleteTask(task)
        }
    }

    // MARK: - Category Operations

    /// Add a new category
    func addCategory(_ category: Category) -> Bool {
        // Check if free user is at limit
        if !settings.isPremium && categories.count >= maxFreeCategories {
            return false
        }

        categories.append(category)
        saveCategories()

        // Check for organizer achievement
        checkForAchievements()

        return true
    }

    /// Update a category
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    /// Delete a category
    func deleteCategory(_ category: Category) {
        // Remove category ID from all tasks that use it
        for index in tasks.indices {
            if tasks[index].categoryId == category.id {
                tasks[index].categoryId = nil
            }
        }
        saveTasks()

        // Remove the category
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    /// Get category by ID
    func category(for id: UUID?) -> Category? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }

    /// Check if user can add more categories
    var canAddCategory: Bool {
        settings.isPremium || categories.count < maxFreeCategories
    }

    // MARK: - Filtered Tasks

    /// Get tasks based on current filter
    var filteredTasks: [Task] {
        switch selectedFilter {
        case .today:
            return tasks.filter { $0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil) }
        case .tomorrow:
            return tasks.filter { $0.isDueTomorrow }
        case .thisWeek:
            return tasks.filter { $0.isDueThisWeek }
        case .all:
            return tasks
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }

    /// Get incomplete tasks for today
    var incompleteTodayTasks: [Task] {
        tasks.filter { !$0.isCompleted && ($0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil)) }
    }

    /// Get overdue tasks
    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue }
    }

    /// Get task suggestions based on patterns
    var taskSuggestions: [TaskSuggestion] {
        settings.taskPatterns.getSuggestions(
            existingTasks: tasks,
            categories: categories
        )
    }

    // MARK: - Confetti Logic

    /// Check if all today's tasks are complete and trigger confetti
    private func checkForConfetti() {
        let todaysTasks = tasks.filter {
            $0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil)
        }

        // Only show confetti if there are tasks and all are complete
        if !todaysTasks.isEmpty && todaysTasks.allSatisfy({ $0.isCompleted }) {
            showConfetti = true

            // Play celebration sound
            SoundManager.shared.playAllTasksComplete()

            // Hide confetti after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.showConfetti = false
            }
        }
    }

    // MARK: - Achievement Logic

    /// Check for newly unlocked achievements
    func checkForAchievements() {
        let hour = Calendar.current.component(.hour, from: Date())

        let newAchievements = Achievement.checkUnlocks(
            totalTasksCompleted: settings.totalTasksCompleted,
            currentStreak: settings.currentStreak,
            longestStreak: settings.longestStreak,
            categoryCount: categories.count,
            isPremium: settings.isPremium,
            completionHour: hour,
            alreadyUnlocked: settings.unlockedAchievements
        )

        // Unlock each new achievement
        for achievement in newAchievements {
            unlockAchievement(achievement.id)
        }

        // Show celebration for the first newly unlocked achievement
        if let first = newAchievements.first {
            newlyUnlockedAchievement = first

            // Play achievement sound
            SoundManager.shared.playAchievementUnlocked()
        }
    }

    /// Unlock an achievement by ID
    func unlockAchievement(_ id: String) {
        settings.unlockedAchievements.insert(id)
        saveSettings()
    }

    /// Clear the newly unlocked achievement (after showing celebration)
    func clearNewlyUnlockedAchievement() {
        newlyUnlockedAchievement = nil
    }

    // MARK: - Daily Challenge Logic

    /// Check if daily challenge is completed
    func checkDailyChallenge() {
        guard var challenge = settings.currentChallenge, !challenge.isCompleted else { return }

        let hour = Calendar.current.component(.hour, from: Date())

        // Count tasks completed today
        let tasksCompletedToday = tasks.filter {
            $0.isCompleted && $0.completedAt != nil && Calendar.current.isDateInToday($0.completedAt!)
        }.count

        // Count completions per category today
        var categoryCompletions: [UUID: Int] = [:]
        for task in tasks where task.isCompleted && task.completedAt != nil && Calendar.current.isDateInToday(task.completedAt!) {
            if let catId = task.categoryId {
                categoryCompletions[catId, default: 0] += 1
            }
        }

        // Check if all today's tasks are done
        let todaysTasks = tasks.filter {
            $0.isDueToday || (Calendar.current.isDateInToday($0.createdAt) && $0.dueDate == nil)
        }
        let allTodayTasksDone = !todaysTasks.isEmpty && todaysTasks.allSatisfy { $0.isCompleted }

        // Check the challenge
        let wasCompleted = challenge.checkCompletion(
            tasksCompletedToday: tasksCompletedToday,
            completionHour: hour,
            hasStreak: settings.currentStreak > 0,
            categoryCompletions: categoryCompletions,
            allTodayTasksDone: allTodayTasksDone
        )

        // Update settings
        settings.currentChallenge = challenge

        if wasCompleted {
            settings.totalChallengesCompleted += 1
            challengeJustCompleted = true

            // Play challenge complete sound
            SoundManager.shared.playChallengeComplete()

            // Auto-hide celebration after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.challengeJustCompleted = false
            }
        }

        saveSettings()
    }

    // MARK: - Settings Operations

    /// Update premium status
    func setPremiumStatus(_ isPremium: Bool) {
        settings.isPremium = isPremium
        saveSettings()

        // Check for premium achievement
        if isPremium {
            checkForAchievements()
        }
    }

    /// Update theme
    func setTheme(_ theme: AppTheme) {
        // Only allow premium themes for premium users
        if theme.isPremiumOnly && !settings.isPremium {
            return
        }
        settings.themeName = theme.rawValue
        saveSettings()
    }

    // MARK: - Persistence Helpers

    private func saveTasks() {
        PersistenceManager.shared.saveTasks(tasks)
    }

    private func saveCategories() {
        PersistenceManager.shared.saveCategories(categories)
    }

    private func saveSettings() {
        PersistenceManager.shared.saveSettings(settings)
    }
}

// MARK: - Task Filter Enum

enum TaskFilter: String, CaseIterable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case thisWeek = "This Week"
    case all = "All"
    case completed = "Completed"

    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .tomorrow: return "sunrise.fill"
        case .thisWeek: return "calendar"
        case .all: return "list.bullet"
        case .completed: return "checkmark.circle.fill"
        }
    }
}
