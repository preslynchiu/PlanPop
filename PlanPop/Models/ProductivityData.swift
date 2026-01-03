//
//  ProductivityData.swift
//  PlanPop
//
//  Tracks productivity metrics for insights and smart reminders
//

import Foundation

/// Represents completion data for a single day
struct DailyLog: Codable, Equatable {
    let date: Date  // Start of day (normalized)
    var completedCount: Int
    var completionHours: [Int]  // Hours when tasks were completed (0-23)

    init(date: Date, completedCount: Int = 0, completionHours: [Int] = []) {
        // Normalize to start of day
        self.date = Calendar.current.startOfDay(for: date)
        self.completedCount = completedCount
        self.completionHours = completionHours
    }
}

/// Tracks all productivity metrics for analytics
struct ProductivityData: Codable, Equatable {
    /// Daily completion logs (last 90 days max)
    var dailyLogs: [DailyLog] = []

    /// Histogram of completion counts by hour (0-23)
    var hourlyHistogram: [Int: Int] = [:]

    /// Histogram of completion counts by day of week (1=Sun...7=Sat)
    var dayOfWeekHistogram: [Int: Int] = [:]

    // MARK: - Recording Methods

    /// Record a task completion
    mutating func recordCompletion(at date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let hour = calendar.component(.hour, from: date)
        let dayOfWeek = calendar.component(.weekday, from: date) // 1=Sun...7=Sat

        // Update or create daily log
        if let index = dailyLogs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            dailyLogs[index].completedCount += 1
            dailyLogs[index].completionHours.append(hour)
        } else {
            dailyLogs.append(DailyLog(date: today, completedCount: 1, completionHours: [hour]))
        }

        // Update histograms
        hourlyHistogram[hour, default: 0] += 1
        dayOfWeekHistogram[dayOfWeek, default: 0] += 1

        // Prune old logs (keep last 90 days)
        pruneOldLogs()
    }

    /// Remove logs older than 90 days
    private mutating func pruneOldLogs() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -90, to: Date()) else { return }
        dailyLogs.removeAll { $0.date < cutoffDate }
    }

    // MARK: - Insight Calculations

    /// Get the peak productivity hour (0-23)
    var peakHour: Int? {
        guard !hourlyHistogram.isEmpty else { return nil }
        return hourlyHistogram.max(by: { $0.value < $1.value })?.key
    }

    /// Get the most productive day of week (1=Sun...7=Sat)
    var mostProductiveDayOfWeek: Int? {
        guard !dayOfWeekHistogram.isEmpty else { return nil }
        return dayOfWeekHistogram.max(by: { $0.value < $1.value })?.key
    }

    /// Get day name for weekday number
    static func dayName(for weekday: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard weekday >= 1 && weekday <= 7 else { return "" }
        return days[weekday]
    }

    /// Get formatted hour string (e.g., "3 PM")
    static func hourString(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        // Use today's date as base, then set the hour
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        guard let date = Calendar.current.date(from: components) else { return "\(hour):00" }
        return formatter.string(from: date)
    }

    /// Tasks completed this week
    var completedThisWeek: Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return 0
        }
        return dailyLogs
            .filter { $0.date >= startOfWeek }
            .reduce(0) { $0 + $1.completedCount }
    }

    /// Tasks completed last week
    var completedLastWeek: Int {
        let calendar = Calendar.current
        guard let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek) else {
            return 0
        }
        return dailyLogs
            .filter { $0.date >= startOfLastWeek && $0.date < startOfThisWeek }
            .reduce(0) { $0 + $1.completedCount }
    }

    /// Tasks completed this month
    var completedThisMonth: Int {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return 0
        }
        return dailyLogs
            .filter { $0.date >= startOfMonth }
            .reduce(0) { $0 + $1.completedCount }
    }

    /// Average tasks per day (based on days with activity)
    var averagePerActiveDay: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.completedCount }
        return Double(total) / Double(dailyLogs.count)
    }

    /// Get completion data for the last 7 days
    var last7Days: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var result: [(Date, Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let count = dailyLogs.first { calendar.isDate($0.date, inSameDayAs: startOfDay) }?.completedCount ?? 0
            result.append((startOfDay, count))
        }

        return result
    }
}
