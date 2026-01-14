//
//  Constants.swift
//  Moov
//
//  Constants used throughout the app
//

import Foundation

enum Constants {
    // Default settings
    static let defaultBreakInterval: TimeInterval = 30 * 60 // 30 minutes
    static let defaultMicroBreakInterval: TimeInterval = 10 * 60 // 10 minutes
    static let defaultSnoozeDurations: [TimeInterval] = [5 * 60, 10 * 60] // 5 and 10 minutes

    // Snooze options
    static let snooze5Min: TimeInterval = 5 * 60
    static let snooze10Min: TimeInterval = 10 * 60

    // Idle detection
    static let idleThreshold: TimeInterval = 5 * 60 // 5 minutes

    // Animation durations
    static let overlayFadeInDuration: Double = 0.3
    static let overlayFadeOutDuration: Double = 0.2

    // UserDefaults keys
    enum UserDefaultsKeys {
        static let breakInterval = "breakInterval"
        static let microBreakInterval = "microBreakInterval"
        static let isEnabled = "isEnabled"
        static let quietHoursStart = "quietHoursStart"
        static let quietHoursEnd = "quietHoursEnd"
        static let showActivitySuggestions = "showActivitySuggestions"
        static let soundEnabled = "soundEnabled"
        static let presentationModeEnabled = "presentationModeEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
