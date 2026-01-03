//
//  PersistenceManager.swift
//  PlanPop
//
//  Handles saving and loading data from local storage (UserDefaults)
//

import Foundation
import WidgetKit

/// Manages all local data persistence using UserDefaults
class PersistenceManager {
    // Singleton instance - use PersistenceManager.shared to access
    static let shared = PersistenceManager()

    // App Group identifier for sharing data with widget
    static let appGroupId = "group.com.planpop.app"

    // UserDefaults instance - uses App Group for widget sharing
    private let defaults: UserDefaults

    // Keys for storing data
    private enum Keys {
        static let tasks = "planpop_tasks"
        static let categories = "planpop_categories"
        static let settings = "planpop_settings"
    }

    // Private init for singleton pattern
    private init() {
        // Use shared UserDefaults for App Group (falls back to standard if group unavailable)
        self.defaults = UserDefaults(suiteName: PersistenceManager.appGroupId) ?? .standard
    }

    // MARK: - Tasks

    /// Save all tasks to storage
    func saveTasks(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            defaults.set(data, forKey: Keys.tasks)

            // Refresh widget when tasks change
            WidgetCenter.shared.reloadTimelines(ofKind: "PlanPopWidget")
        } catch {
            print("Error saving tasks: \(error)")
        }
    }

    /// Load all tasks from storage
    func loadTasks() -> [Task] {
        guard let data = defaults.data(forKey: Keys.tasks) else {
            return []
        }

        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            return tasks
        } catch {
            print("Error loading tasks: \(error)")
            return []
        }
    }

    // MARK: - Categories

    /// Save all categories to storage
    func saveCategories(_ categories: [Category]) {
        do {
            let data = try JSONEncoder().encode(categories)
            defaults.set(data, forKey: Keys.categories)
        } catch {
            print("Error saving categories: \(error)")
        }
    }

    /// Load all categories from storage
    func loadCategories() -> [Category] {
        guard let data = defaults.data(forKey: Keys.categories) else {
            // Return default categories for new users
            return Category.defaultCategories
        }

        do {
            let categories = try JSONDecoder().decode([Category].self, from: data)
            return categories
        } catch {
            print("Error loading categories: \(error)")
            return Category.defaultCategories
        }
    }

    // MARK: - Settings

    /// Save user settings to storage
    func saveSettings(_ settings: UserSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: Keys.settings)

            // Refresh widget when settings change (streak updates)
            WidgetCenter.shared.reloadTimelines(ofKind: "PlanPopWidget")
        } catch {
            print("Error saving settings: \(error)")
        }
    }

    /// Load user settings from storage
    func loadSettings() -> UserSettings {
        guard let data = defaults.data(forKey: Keys.settings) else {
            return UserSettings()
        }

        do {
            var settings = try JSONDecoder().decode(UserSettings.self, from: data)
            // Validate streak on load
            settings.validateStreak()
            return settings
        } catch {
            print("Error loading settings: \(error)")
            return UserSettings()
        }
    }

    // MARK: - Utility

    /// Clear all app data (for debugging or reset)
    func clearAllData() {
        defaults.removeObject(forKey: Keys.tasks)
        defaults.removeObject(forKey: Keys.categories)
        defaults.removeObject(forKey: Keys.settings)
    }

    /// Check if this is a fresh install
    var isFirstLaunch: Bool {
        return defaults.data(forKey: Keys.settings) == nil
    }
}
