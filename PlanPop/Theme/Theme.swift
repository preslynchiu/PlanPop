//
//  Theme.swift
//  PlanPop
//
//  Defines the app's color palette and styling
//

import SwiftUI
import Combine

// MARK: - Theme Manager (Observable)

/// Manages the current theme and notifies views of changes
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme = .pastelPink

    private init() {
        // Load saved theme from UserDefaults
        loadSavedTheme()
    }

    func loadSavedTheme() {
        let settings = PersistenceManager.shared.loadSettings()
        if let theme = AppTheme(rawValue: settings.themeName) {
            currentTheme = theme
        }
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }

    // MARK: - Current Theme Colors (Computed)

    var colors: ThemeColors {
        Theme.colors(for: currentTheme)
    }

    var primary: Color { colors.primary }
    var secondary: Color { colors.secondary }
    var themeBackground: Color { colors.background }
    var accent: Color { colors.accent }

    var isDarkTheme: Bool {
        currentTheme == .dark
    }

    var cardBackground: Color {
        isDarkTheme ? Color(hex: "#2C2C2E") : Color.white
    }

    var textPrimary: Color {
        isDarkTheme ? Color.white : Color(hex: "#4A4A4A")
    }

    var textSecondary: Color {
        isDarkTheme ? Color(hex: "#EBEBF5").opacity(0.6) : Color(hex: "#767676")
    }
}

/// App-wide theme and color definitions
struct Theme {
    // MARK: - Shared Theme Manager

    static var current: ThemeManager { ThemeManager.shared }

    // MARK: - Legacy Static Colors (for backwards compatibility during migration)
    // These now read from the current theme

    /// Primary accent color
    static var primary: Color { current.primary }

    /// Secondary accent color
    static var secondary: Color { current.secondary }

    /// Background color
    static var background: Color { current.themeBackground }

    /// Card/surface background
    static var cardBackground: Color { current.cardBackground }

    /// Text colors
    static var textPrimary: Color { current.textPrimary }
    static var textSecondary: Color { current.textSecondary }

    /// Success color (soft green)
    static let success = Color(hex: "#A8E6CF")

    /// Warning color (soft yellow)
    static let warning = Color(hex: "#FFE5A0")

    /// Error/overdue color (soft red)
    static let error = Color(hex: "#FF9999")

    // MARK: - Theme-Specific Colors

    /// Get colors for a specific theme
    static func colors(for theme: AppTheme) -> ThemeColors {
        switch theme {
        case .pastelPink:
            return ThemeColors(
                primary: Color(hex: "#FF9EAA"),
                secondary: Color(hex: "#FFD4DA"),
                background: Color(hex: "#FFF5F5"),
                accent: Color(hex: "#FF6B8A")
            )
        case .pastelBlue:
            return ThemeColors(
                primary: Color(hex: "#89CFF0"),
                secondary: Color(hex: "#B8E0F6"),
                background: Color(hex: "#F5FAFF"),
                accent: Color(hex: "#5BA4D9")
            )
        case .pastelGreen:
            return ThemeColors(
                primary: Color(hex: "#A8E6CF"),
                secondary: Color(hex: "#C8F0DC"),
                background: Color(hex: "#F5FFF9"),
                accent: Color(hex: "#7DD3A8")
            )
        case .pastelPurple:
            return ThemeColors(
                primary: Color(hex: "#C4B0FF"),
                secondary: Color(hex: "#DDD4FF"),
                background: Color(hex: "#FAF5FF"),
                accent: Color(hex: "#9B7FE6")
            )
        case .light:
            return ThemeColors(
                primary: Color(hex: "#007AFF"),
                secondary: Color(hex: "#E5E5EA"),
                background: Color(hex: "#F2F2F7"),
                accent: Color(hex: "#007AFF")
            )
        case .dark:
            return ThemeColors(
                primary: Color(hex: "#0A84FF"),
                secondary: Color(hex: "#3A3A3C"),
                background: Color(hex: "#1C1C1E"),
                accent: Color(hex: "#0A84FF")
            )
        }
    }

    // MARK: - UI Constants

    /// Corner radius for buttons and cards
    static let cornerRadius: CGFloat = 16

    /// Smaller corner radius
    static let smallCornerRadius: CGFloat = 10

    /// Standard padding
    static let padding: CGFloat = 16

    /// Small padding
    static let smallPadding: CGFloat = 8

    /// Shadow radius
    static let shadowRadius: CGFloat = 8

    /// Button height
    static let buttonHeight: CGFloat = 50

    /// Icon size
    static let iconSize: CGFloat = 24
}

/// Colors for a specific theme
struct ThemeColors {
    let primary: Color
    let secondary: Color
    let background: Color
    let accent: Color
}

// MARK: - View Modifier for Rounded Cards

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadius)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: Theme.shadowRadius,
                x: 0,
                y: 2
            )
    }
}

extension View {
    /// Apply card styling to a view
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.primary)
            .cornerRadius(Theme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Theme.primary)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.primary.opacity(0.15))
            .cornerRadius(Theme.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
