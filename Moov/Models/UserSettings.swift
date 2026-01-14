//
//  UserSettings.swift
//  Moov
//
//  User preferences and settings
//

import Foundation
import SwiftUI

@Observable
class UserSettings {
    // Singleton instance
    static let shared = UserSettings()

    // Break intervals
    var breakInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(breakInterval, forKey: Constants.UserDefaultsKeys.breakInterval)
        }
    }

    var microBreakInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(microBreakInterval, forKey: Constants.UserDefaultsKeys.microBreakInterval)
        }
    }

    // Feature toggles
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Constants.UserDefaultsKeys.isEnabled)
        }
    }

    var showActivitySuggestions: Bool {
        didSet {
            UserDefaults.standard.set(showActivitySuggestions, forKey: Constants.UserDefaultsKeys.showActivitySuggestions)
        }
    }

    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Constants.UserDefaultsKeys.soundEnabled)
        }
    }

    var presentationModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(presentationModeEnabled, forKey: Constants.UserDefaultsKeys.presentationModeEnabled)
        }
    }

    // Quiet hours (optional)
    var quietHoursStart: Date? {
        didSet {
            if let date = quietHoursStart {
                UserDefaults.standard.set(date, forKey: Constants.UserDefaultsKeys.quietHoursStart)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.quietHoursStart)
            }
        }
    }

    var quietHoursEnd: Date? {
        didSet {
            if let date = quietHoursEnd {
                UserDefaults.standard.set(date, forKey: Constants.UserDefaultsKeys.quietHoursEnd)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.quietHoursEnd)
            }
        }
    }

    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        }
    }

    // Private initializer for singleton
    private init() {
        // Load from UserDefaults or use defaults
        self.breakInterval = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.breakInterval) as? TimeInterval ?? Constants.defaultBreakInterval
        self.microBreakInterval = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.microBreakInterval) as? TimeInterval ?? Constants.defaultMicroBreakInterval
        self.isEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.isEnabled) as? Bool ?? true
        self.showActivitySuggestions = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.showActivitySuggestions) as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.soundEnabled) as? Bool ?? false
        self.presentationModeEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.presentationModeEnabled) as? Bool ?? false
        self.quietHoursStart = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.quietHoursStart) as? Date
        self.quietHoursEnd = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.quietHoursEnd) as? Date
        self.hasCompletedOnboarding = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding) as? Bool ?? false
    }

    // Helper to check if currently in quiet hours
    func isInQuietHours() -> Bool {
        guard let start = quietHoursStart, let end = quietHoursEnd else {
            return false
        }

        let calendar = Calendar.current
        let now = Date()

        // Extract time components
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        guard let startMinutes = startComponents.hour.map({ $0 * 60 + (startComponents.minute ?? 0) }),
              let endMinutes = endComponents.hour.map({ $0 * 60 + (endComponents.minute ?? 0) }),
              let nowMinutes = nowComponents.hour.map({ $0 * 60 + (nowComponents.minute ?? 0) }) else {
            return false
        }

        // Handle overnight quiet hours (e.g., 10 PM to 7 AM)
        if startMinutes > endMinutes {
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        } else {
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        }
    }

    // Format time interval for display
    static func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(remainingMinutes) min"
            }
        }
    }
}
