//
//  AchievementsView.swift
//  PlanPop
//
//  Displays all achievements in a grid layout
//

import SwiftUI

/// Grid view displaying all achievements with locked/unlocked states
struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: TaskViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress header
                    progressHeader

                    // Achievements grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Achievement.all) { achievement in
                            AchievementCard(
                                achievement: achievement,
                                isUnlocked: viewModel.settings.unlockedAchievements.contains(achievement.id)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Theme.background)
            .navigationTitle("Achievements")
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

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(Theme.primary.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Theme.primary)
            }

            // Progress text
            Text("\(viewModel.settings.unlockedAchievements.count) of \(Achievement.totalCount)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)

            Text("achievements unlocked")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.textSecondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.primary)
                        .frame(width: progressWidth(totalWidth: geometry.size.width), height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private func progressWidth(totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat(viewModel.settings.unlockedAchievements.count) / CGFloat(Achievement.totalCount)
        return totalWidth * progress
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Theme.primary.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                if isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 28))
                        .foregroundColor(Theme.primary)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            // Name
            Text(achievement.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isUnlocked ? Theme.textPrimary : Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Description
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Unlocked indicator
            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("Unlocked")
                        .font(.caption2)
                }
                .foregroundColor(Theme.success)
            } else {
                Text(achievement.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadius)
        .opacity(isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
        .environmentObject(TaskViewModel())
}
