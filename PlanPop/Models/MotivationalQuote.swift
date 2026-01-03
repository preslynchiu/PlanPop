//
//  MotivationalQuote.swift
//  PlanPop
//
//  Daily motivational quotes for students
//

import Foundation

/// Provides daily motivational quotes
struct MotivationalQuote {
    /// Collection of motivational quotes for students
    static let quotes: [String] = [
        "You've got this! One task at a time. ✨",
        "Small steps lead to big achievements! 🚀",
        "Today is your day to shine! ⭐",
        "Believe in yourself - you're amazing! 💪",
        "Every completed task is a win! 🎉",
        "Keep going, you're doing great! 🌟",
        "Your future self will thank you! 🙌",
        "Progress, not perfection! 💫",
        "You're stronger than you think! 💪",
        "Make today count! ⚡",
        "Dream big, work hard! 🌈",
        "You're on your way to greatness! 🏆",
        "Stay focused, stay awesome! 🎯",
        "Every day is a fresh start! 🌅",
        "You can do hard things! 💪",
        "Keep pushing forward! 🚀",
        "Your effort matters! ⭐",
        "Be proud of how far you've come! 🎊",
        "Great things take time! ⏰",
        "You're making progress! 📈",
        "Stay positive and keep going! 😊",
        "Champions never give up! 🏅",
        "Today's tasks = tomorrow's success! 🌟",
        "You're unstoppable! 💥",
        "Finish strong! 🏁",
        "Hard work pays off! 💎",
        "Keep that streak alive! 🔥",
        "You're building great habits! 🌱",
        "One step closer to your goals! 👣",
        "Celebrate every small win! 🎈"
    ]

    /// Get today's quote (changes daily)
    static var todaysQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }

    /// Get a random quote
    static var randomQuote: String {
        quotes.randomElement() ?? quotes[0]
    }
}
