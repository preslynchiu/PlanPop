//
//  SoundManager.swift
//  PlanPop
//
//  Plays satisfying sounds for app interactions
//

import AVFoundation
import UIKit

/// Manages sound effects for the app
class SoundManager {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session for playing sounds with other audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Sound Effects

    /// Play sound when task is completed
    func playTaskComplete() {
        // Use haptic feedback + system sound
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Play a subtle pop sound
        AudioServicesPlaySystemSound(1104) // Pop sound
    }

    /// Play sound when task is uncompleted
    func playTaskUncomplete() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Play sound when achievement is unlocked
    func playAchievementUnlocked() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Play a celebratory sound
        AudioServicesPlaySystemSound(1025) // Fanfare-like sound
    }

    /// Play sound when daily challenge is completed
    func playChallengeComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Play a rewarding sound
        AudioServicesPlaySystemSound(1114) // Positive sound
    }

    /// Play sound when all daily tasks are done (confetti moment)
    func playAllTasksComplete() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Play a celebratory sound
        AudioServicesPlaySystemSound(1335) // Celebration sound
    }

    /// Play sound when adding a new task
    func playTaskAdded() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        AudioServicesPlaySystemSound(1156) // Subtle add sound
    }

    /// Play sound for button taps
    func playButtonTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Play error/warning sound
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        AudioServicesPlaySystemSound(1521) // Vibrate for error
    }
}
