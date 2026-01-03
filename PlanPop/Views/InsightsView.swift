//
//  InsightsView.swift
//  PlanPop
//
//  Weekly and monthly productivity insights
//

import SwiftUI

/// Displays productivity insights and analytics
struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel

    private var data: ProductivityData {
        viewModel.settings.productivityData
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly comparison card
                    weeklyComparisonCard

                    // Last 7 days chart
                    last7DaysChart

                    // Peak productivity card
                    peakProductivityCard

                    // Monthly stats
                    monthlyStatsCard
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Weekly Comparison Card

    private var weeklyComparisonCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(Theme.primary)
                Text("Weekly Progress")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 24) {
                // This week
                VStack(spacing: 4) {
                    Text("\(data.completedThisWeek)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Theme.primary)
                    Text("This Week")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Theme.textSecondary.opacity(0.2))
                    .frame(width: 1, height: 50)

                // Last week
                VStack(spacing: 4) {
                    Text("\(data.completedLastWeek)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Last Week")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                // Trend
                VStack(spacing: 4) {
                    trendIndicator
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }

    private var trendIndicator: some View {
        let thisWeek = data.completedThisWeek
        let lastWeek = data.completedLastWeek

        let icon: String
        let color: Color

        if lastWeek == 0 {
            icon = thisWeek > 0 ? "arrow.up.circle.fill" : "minus.circle.fill"
            color = thisWeek > 0 ? Theme.success : Theme.textSecondary
        } else if thisWeek > lastWeek {
            icon = "arrow.up.circle.fill"
            color = Theme.success
        } else if thisWeek < lastWeek {
            icon = "arrow.down.circle.fill"
            color = .orange
        } else {
            icon = "equal.circle.fill"
            color = Theme.textSecondary
        }

        return Image(systemName: icon)
            .font(.system(size: 28))
            .foregroundColor(color)
    }

    // MARK: - Last 7 Days Chart

    private var last7DaysChart: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(Theme.primary)
                Text("Last 7 Days")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            let days = data.last7Days
            let maxCount = max(days.map { $0.count }.max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.count > 0 ? Theme.primary : Theme.textSecondary.opacity(0.2))
                            .frame(height: CGFloat(day.count) / CGFloat(maxCount) * 100 + 4)

                        // Count
                        Text("\(day.count)")
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)

                        // Day label
                        Text(dayLabel(for: day.date))
                            .font(.caption2)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Peak Productivity Card

    private var peakProductivityCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("Peak Productivity")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            if data.hourlyHistogram.isEmpty {
                Text("Complete more tasks to discover your peak productivity times!")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                HStack(spacing: 24) {
                    // Best hour
                    if let peakHour = data.peakHour {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.title)
                                .foregroundColor(Theme.primary)
                            Text(ProductivityData.hourString(for: peakHour))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.textPrimary)
                            Text("Best Hour")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Best day
                    if let peakDay = data.mostProductiveDayOfWeek {
                        VStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            Text(ProductivityData.dayName(for: peakDay))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.textPrimary)
                            Text("Best Day")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            // Smart reminder suggestion
            if let peakHour = data.peakHour {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Set reminders around \(ProductivityData.hourString(for: peakHour)) for best results!")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }

    // MARK: - Monthly Stats Card

    private var monthlyStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(Theme.primary)
                Text("Monthly Stats")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 16) {
                // This month
                StatItem(
                    value: "\(data.completedThisMonth)",
                    label: "This Month",
                    icon: "checkmark.circle.fill",
                    color: Theme.success
                )

                // Average
                StatItem(
                    value: String(format: "%.1f", data.averagePerActiveDay),
                    label: "Avg/Day",
                    icon: "chart.line.flattrend.xyaxis",
                    color: Theme.primary
                )

                // Total logged
                StatItem(
                    value: "\(data.dailyLogs.count)",
                    label: "Days Active",
                    icon: "calendar.badge.checkmark",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
    }
}

// MARK: - Stat Item Component

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    InsightsView()
        .environmentObject(TaskViewModel())
}
