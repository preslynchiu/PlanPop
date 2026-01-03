//
//  SuggestionBanner.swift
//  PlanPop
//
//  Displays smart task suggestions based on user patterns
//

import SwiftUI

/// Banner showing task suggestions based on detected patterns
struct SuggestionBanner: View {
    let suggestions: [TaskSuggestion]
    let onAccept: (TaskSuggestion) -> Void
    let onDismiss: () -> Void

    @State private var currentIndex = 0

    /// Safely get current suggestion with bounds checking
    private var currentSuggestion: TaskSuggestion? {
        guard currentIndex >= 0 && currentIndex < suggestions.count else { return nil }
        return suggestions[currentIndex]
    }

    var body: some View {
        if let suggestion = currentSuggestion {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Lightbulb icon
                    Image(systemName: suggestion.icon)
                        .font(.title3)
                        .foregroundColor(Theme.primary)
                        .frame(width: 32, height: 32)
                        .background(Theme.primary.opacity(0.15))
                        .clipShape(Circle())

                    // Suggestion content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textPrimary)

                        Text(suggestion.reason)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 8) {
                        // Add button
                        Button(action: {
                            SoundManager.shared.playButtonTap()
                            onAccept(suggestion)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Theme.primary)
                        }

                        // Dismiss button
                        Button(action: {
                            if currentIndex < suggestions.count - 1 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentIndex += 1
                                }
                            } else {
                                onDismiss()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Theme.textSecondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, Theme.padding)
                .padding(.vertical, 12)
                .background(Theme.cardBackground)
                .cornerRadius(Theme.cornerRadius)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                // Page indicator for multiple suggestions
                if suggestions.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<suggestions.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Theme.primary : Theme.textSecondary.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SuggestionBanner(
            suggestions: [
                TaskSuggestion(
                    title: "Do homework",
                    reason: "You often add this on Mondays",
                    icon: "lightbulb.fill",
                    categoryId: nil
                ),
                TaskSuggestion(
                    title: "Add a School task",
                    reason: "You usually have School tasks on Mondays",
                    icon: "book.fill",
                    categoryId: nil
                )
            ],
            onAccept: { _ in },
            onDismiss: { }
        )
        .padding()

        Spacer()
    }
    .background(Theme.background)
}
