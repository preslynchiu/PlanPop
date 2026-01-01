//
//  Category.swift
//  PlanPop
//
//  A model representing a task category (like "School", "Home", etc.)
//

import Foundation
import SwiftUI

/// Represents a category for organizing tasks
struct Category: Identifiable, Codable, Equatable {
    // Unique identifier
    var id: UUID = UUID()

    // Name of the category (e.g., "School", "Hobbies")
    var name: String

    // Color for the category (stored as hex string)
    var colorHex: String

    // Icon name from SF Symbols
    var iconName: String

    // When was this category created?
    var createdAt: Date = Date()
}

// MARK: - Color Helpers

extension Category {
    /// Get SwiftUI Color from hex string
    var color: Color {
        Color(hex: colorHex)
    }

    /// Available pastel colors for categories
    static let pastelColors: [String] = [
        "#FFB5BA", // Soft pink
        "#FFDAB5", // Soft peach
        "#FFF5B5", // Soft yellow
        "#B5FFB5", // Soft green
        "#B5FFFF", // Soft cyan
        "#B5D4FF", // Soft blue
        "#D4B5FF", // Soft purple
        "#FFB5E8"  // Soft magenta
    ]

    /// Available icons for categories
    static let availableIcons: [String] = [
        "book.fill",
        "house.fill",
        "sportscourt.fill",
        "music.note",
        "heart.fill",
        "star.fill",
        "gamecontroller.fill",
        "paintbrush.fill",
        "cart.fill",
        "gift.fill",
        "leaf.fill",
        "sun.max.fill"
    ]
}

// MARK: - Default Categories

extension Category {
    /// Default categories for new users
    static let defaultCategories: [Category] = [
        Category(
            name: "School",
            colorHex: "#B5D4FF",
            iconName: "book.fill"
        ),
        Category(
            name: "Home",
            colorHex: "#FFB5BA",
            iconName: "house.fill"
        ),
        Category(
            name: "Fun",
            colorHex: "#B5FFB5",
            iconName: "star.fill"
        )
    ]
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Create a Color from a hex string
    init(hex: String) {
        // Remove # if present
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128) // Default gray
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
