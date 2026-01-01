//
//  StreakBadge.swift
//  PlanPop
//
//  Shows the user's current streak count
//

import SwiftUI

/// Displays the current streak with a flame icon
struct StreakBadge: View {
    // Current streak count
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            // Flame icon
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .foregroundColor(streak > 0 ? .orange : Theme.textSecondary)

            // Streak count
            Text("\(streak)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(streak > 0 ? .orange : Theme.textSecondary)

            Text("day streak")
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            streak > 0 ?
                Color.orange.opacity(0.15) :
                Theme.textSecondary.opacity(0.1)
        )
        .cornerRadius(20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(streak == 1 ? "1 day streak" : "\(streak) day streak")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StreakBadge(streak: 0)
        StreakBadge(streak: 5)
        StreakBadge(streak: 30)
    }
    .padding()
}
