//
//  DailyChallengeCard.swift
//  PlanPop
//
//  Displays the daily challenge with progress
//

import SwiftUI

/// Card displaying the current daily challenge
struct DailyChallengeCard: View {
    let challenge: DailyChallenge

    var body: some View {
        HStack(spacing: 12) {
            // Challenge icon
            ZStack {
                Circle()
                    .fill(challenge.isCompleted ? Theme.success.opacity(0.2) : Theme.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: challenge.isCompleted ? "checkmark.circle.fill" : challenge.type.icon)
                    .font(.title3)
                    .foregroundColor(challenge.isCompleted ? Theme.success : Theme.primary)
            }

            // Challenge info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Daily Challenge")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.primary)

                    if challenge.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(Theme.success)
                    }
                }

                Text(challenge.type.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
            }

            Spacer()

            // Progress indicator
            if challenge.type.target > 1 && !challenge.isCompleted {
                VStack(spacing: 4) {
                    Text(challenge.progressText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.primary)

                    // Mini progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.textSecondary.opacity(0.2))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.primary)
                                .frame(width: geo.size.width * challenge.progressPercent)
                        }
                    }
                    .frame(width: 40, height: 4)
                }
            } else if challenge.isCompleted {
                Text("Done!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.success)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(challenge.isCompleted ? Theme.success.opacity(0.3) : Theme.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DailyChallengeCard(challenge: DailyChallenge(
            type: .completeTasks,
            date: Date(),
            progress: 1
        ))

        DailyChallengeCard(challenge: DailyChallenge(
            type: .earlyBird,
            date: Date(),
            isCompleted: true,
            completedAt: Date()
        ))

        DailyChallengeCard(challenge: DailyChallenge(
            type: .streakKeeper,
            date: Date()
        ))
    }
    .padding()
    .background(Theme.background)
}
