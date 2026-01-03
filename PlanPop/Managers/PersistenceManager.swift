//
//  PersistenceManager.swift
//  PlanPop
//
//  Handles saving and loading data from local storage (UserDefaults)
//

import Foundation
import WidgetKit
import Combine

/// Manages all local data persistence using UserDefaults
class PersistenceManager: ObservableObject {
    // Singleton instance - use PersistenceManager.shared to access
    static let shared = PersistenceManager()

    // App Group identifier for sharing data with widget
    static let appGroupId = "group.com.planpop.app"

    // UserDefaults instance - uses App Group for widget sharing
    private let defaults: UserDefaults

    // Published error for UI to observe and display
    @Published var lastError: PersistenceError?

    // Keys for storing data
    private enum Keys {
        static let tasks = "planpop_tasks"
        static let categories = "planpop_categories"
        static let settings = "planpop_settings"
    }

    /// Errors that can occur during persistence operations
    enum PersistenceError: LocalizedError {
        case saveFailed(String)
        case loadFailed(String)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let detail):
                return "Failed to save data: \(detail)"
            case .loadFailed(let detail):
                return "Failed to load data: \(detail)"
            }
        }
    }

    // Private init for singleton pattern
    private init() {
        // Use shared UserDefaults for App Group (falls back to standard if group unavailable)
        self.defaults = UserDefaults(suiteName: PersistenceManager.appGroupId) ?? .standard
    }

    /// Clear any displayed error
    func clearError() {
        lastError = nil
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
            lastError = .saveFailed("Tasks could not be saved. Please try again.")
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
            lastError = .loadFailed("Tasks could not be loaded. Some data may be lost.")
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
            lastError = .saveFailed("Categories could not be saved. Please try again.")
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
            lastError = .loadFailed("Categories could not be loaded. Using defaults.")
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
            lastError = .saveFailed("Settings could not be saved. Please try again.")
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
            lastError = .loadFailed("Settings could not be loaded. Using defaults.")
            return UserSettings()
        }
    }

    /// Atomically update settings with a closure to prevent race conditions
    func updateSettings(_ update: (inout UserSettings) -> Void) {
        var settings = loadSettings()
        update(&settings)
        saveSettings(settings)
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
