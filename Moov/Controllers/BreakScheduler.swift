//
//  BreakScheduler.swift
//  Moov
//
//  Manages break timing and scheduling logic
//

import Foundation
import SwiftData

@Observable
class BreakScheduler {
    // Singleton instance
    static let shared = BreakScheduler()

    // Timer for scheduling breaks
    private var timer: Timer?

    // Last break time
    private(set) var lastBreakTime: Date

    // Scheduled break time
    private(set) var nextBreakTime: Date

    // Pause state
    private(set) var pausedUntil: Date?

    // SwiftData model context (will be injected)
    var modelContext: ModelContext?

    private init() {
        self.lastBreakTime = Date()
        self.nextBreakTime = Date().addingTimeInterval(UserSettings.shared.breakInterval)
    }

    // Start the scheduler
    func start() {
        stop() // Stop any existing timer

        // Schedule timer to check every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForBreak()
        }

        // Also trigger immediately in case we're already past break time
        checkForBreak()

        print("✅ BreakScheduler started. Next break at: \(nextBreakTime)")
    }

    // Stop the scheduler
    func stop() {
        timer?.invalidate()
        timer = nil
        print("⏹️  BreakScheduler stopped")
    }

    // Check if it's time for a break
    private func checkForBreak() {
        let now = Date()

        // Check if paused
        if let pausedUntil = pausedUntil {
            if now < pausedUntil {
                // Still paused
                return
            } else {
                // Pause expired, clear it
                self.pausedUntil = nil
                print("⏰ Pause expired, resuming breaks")
            }
        }

        // Check if disabled
        guard UserSettings.shared.isEnabled else {
            return
        }

        // Check quiet hours
        if UserSettings.shared.isInQuietHours() {
            return
        }

        // Check presentation mode
        if UserSettings.shared.presentationModeEnabled {
            return
        }

        // Check if it's time for a break
        if now >= nextBreakTime {
            triggerBreak()
        }
    }

    // Trigger a break
    private func triggerBreak() {
        print("🔔 Break time!")

        // Post notification to show overlay
        NotificationCenter.default.post(name: .showBreakOverlay, object: nil)

        // Reschedule for next break (in case user doesn't interact)
        rescheduleBreak(after: UserSettings.shared.breakInterval)
    }

    // Manual break trigger
    func triggerManualBreak() {
        print("👆 Manual break triggered")
        NotificationCenter.default.post(name: .showBreakOverlay, object: nil)
    }

    // User took the break
    func breakTaken() {
        print("✅ Break taken")
        logBreakSession(action: "taken")
        lastBreakTime = Date()
        rescheduleBreak(after: UserSettings.shared.breakInterval)
    }

    // User snoozed the break
    func breakSnoozed(duration: TimeInterval) {
        print("😴 Break snoozed for \(Int(duration/60)) minutes")
        logBreakSession(action: "snoozed", snoozeDuration: duration)
        rescheduleBreak(after: duration)
    }

    // User dismissed the break
    func breakDismissed() {
        print("❌ Break dismissed")
        logBreakSession(action: "dismissed")
        // Treat dismiss same as snooze 5 min
        rescheduleBreak(after: Constants.snooze5Min)
    }

    // Pause breaks for a duration
    func pause(for duration: TimeInterval) {
        pausedUntil = Date().addingTimeInterval(duration)
        print("⏸️  Breaks paused until \(pausedUntil!)")
    }

    // Pause until end of day
    func pauseUntilEndOfDay() {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: Date().addingTimeInterval(24 * 60 * 60))
        pausedUntil = tomorrow
        print("⏸️  Breaks paused until tomorrow")
    }

    // Resume breaks
    func resume() {
        pausedUntil = nil
        print("▶️  Breaks resumed")
    }

    // Reset timer with new interval (called when settings change)
    func resetWithCurrentInterval() {
        let newInterval = UserSettings.shared.breakInterval
        nextBreakTime = Date().addingTimeInterval(newInterval)
        print("🔄 Break interval changed. Next break in \(Int(newInterval/60)) minutes")
    }

    // Reschedule the next break
    private func rescheduleBreak(after interval: TimeInterval) {
        nextBreakTime = Date().addingTimeInterval(interval)
        print("📅 Next break scheduled for: \(nextBreakTime)")
    }

    // Log break session to SwiftData
    private func logBreakSession(action: String, snoozeDuration: TimeInterval? = nil) {
        guard let modelContext = modelContext else {
            print("⚠️  ModelContext not set, skipping session log")
            return
        }

        let session = BreakSession(type: "regular", action: action, snoozeDuration: snoozeDuration)
        modelContext.insert(session)

        do {
            try modelContext.save()
            print("💾 Break session logged: \(action)")
        } catch {
            print("❌ Failed to save break session: \(error)")
        }
    }

    // Get time until next break
    func timeUntilNextBreak() -> TimeInterval {
        return max(0, nextBreakTime.timeIntervalSinceNow)
    }

    // Get time since last break
    func timeSinceLastBreak() -> TimeInterval {
        return Date().timeIntervalSince(lastBreakTime)
    }

    // Format time for display
    static func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }
}

// Notification names
extension Notification.Name {
    static let showBreakOverlay = Notification.Name("showBreakOverlay")
}
