//
//  PlanPopWidget.swift
//  PlanPopWidget
//
//  Home screen widget showing today's tasks and streak
//

import WidgetKit
import SwiftUI

// MARK: - Widget Data

/// Data passed to the widget view
struct PlanPopEntry: TimelineEntry {
    let date: Date
    let incompleteTodayCount: Int
    let completedTodayCount: Int
    let currentStreak: Int
    let nextTaskTitle: String?
    let nextTaskDueTime: Date?
}

// MARK: - Timeline Provider

struct PlanPopProvider: TimelineProvider {
    // App Group for shared data
    private let appGroupId = "group.com.planpop.app"

    func placeholder(in context: Context) -> PlanPopEntry {
        PlanPopEntry(
            date: Date(),
            incompleteTodayCount: 3,
            completedTodayCount: 2,
            currentStreak: 5,
            nextTaskTitle: "Do homework",
            nextTaskDueTime: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PlanPopEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanPopEntry>) -> Void) {
        let entry = loadEntry()

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    /// Load data from shared UserDefaults
    private func loadEntry() -> PlanPopEntry {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return PlanPopEntry(
                date: Date(),
                incompleteTodayCount: 0,
                completedTodayCount: 0,
                currentStreak: 0,
                nextTaskTitle: nil,
                nextTaskDueTime: nil
            )
        }

        // Load tasks
        var tasks: [WidgetTask] = []
        if let data = defaults.data(forKey: "planpop_tasks") {
            tasks = (try? JSONDecoder().decode([WidgetTask].self, from: data)) ?? []
        }

        // Load settings for streak
        var streak = 0
        if let data = defaults.data(forKey: "planpop_settings") {
            if let settings = try? JSONDecoder().decode(WidgetSettings.self, from: data) {
                streak = settings.currentStreak
            }
        }

        // Filter today's tasks
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todaysTasks = tasks.filter { task in
            // Task is for today if:
            // 1. Due date is today, OR
            // 2. Created today with no due date
            if let dueDate = task.dueDate {
                let taskDay = calendar.startOfDay(for: dueDate)
                return taskDay >= today && taskDay < tomorrow
            } else {
                let createdDay = calendar.startOfDay(for: task.createdAt)
                return createdDay == today
            }
        }

        let incomplete = todaysTasks.filter { !$0.isCompleted }
        let completed = todaysTasks.filter { $0.isCompleted }

        // Find next upcoming task
        let upcomingWithDue = incomplete
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }

        let nextTask = upcomingWithDue.first ?? incomplete.first

        return PlanPopEntry(
            date: Date(),
            incompleteTodayCount: incomplete.count,
            completedTodayCount: completed.count,
            currentStreak: streak,
            nextTaskTitle: nextTask?.title,
            nextTaskDueTime: nextTask?.dueDate
        )
    }
}

// MARK: - Lightweight Models for Widget

/// Simplified Task model for widget (avoids importing full app)
struct WidgetTask: Codable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let dueDate: Date?
    let createdAt: Date
}

/// Simplified Settings model for widget
struct WidgetSettings: Codable {
    let currentStreak: Int
}

// MARK: - Widget Views

struct PlanPopWidgetEntryView: View {
    var entry: PlanPopEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with streak
            HStack {
                Text("PlanPop")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.7))

                Spacer()

                if entry.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(entry.currentStreak)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            // Task count
            if entry.incompleteTodayCount == 0 && entry.completedTodayCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("All done!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            } else if entry.incompleteTodayCount == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.7))
                    Text("Add a task")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.incompleteTodayCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.7))
                    Text(entry.incompleteTodayCount == 1 ? "task left" : "tasks left")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Progress indicator
            if entry.completedTodayCount > 0 || entry.incompleteTodayCount > 0 {
                let total = entry.completedTodayCount + entry.incompleteTodayCount
                let progress = total > 0 ? Double(entry.completedTodayCount) / Double(total) : 0

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 1.0, green: 0.6, blue: 0.7))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding()
        .widgetBackground()
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left side - counts
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PlanPop")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.7))

                    if entry.currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(entry.currentStreak)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                if entry.incompleteTodayCount == 0 && entry.completedTodayCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("All done for today!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.incompleteTodayCount)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.7))
                        Text(entry.incompleteTodayCount == 1 ? "task" : "tasks")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side - next task
            if let nextTask = entry.nextTaskTitle {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Up next")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(nextTask)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    if let dueTime = entry.nextTaskDueTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(dueTime, style: .time)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 1),
                    alignment: .leading
                )
            }
        }
        .padding()
        .widgetBackground()
    }
}

// MARK: - Widget Background Extension

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(UIColor.systemBackground))
        }
    }
}

// MARK: - Widget Configuration

struct PlanPopWidget: Widget {
    let kind: String = "PlanPopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlanPopProvider()) { entry in
            PlanPopWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your tasks at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

