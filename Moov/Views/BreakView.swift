//
//  BreakView.swift
//  Moov
//
//  The break reminder overlay UI
//

import SwiftUI

struct BreakView: View {
    @Environment(\.dismiss) private var dismiss
    let onDismiss: () -> Void
    let onSnooze: (TimeInterval) -> Void

    @State private var showSnoozeOptions = false
    @State private var remainingSeconds: Int = 30
    @State private var canDismiss = false
    private let scheduler = BreakScheduler.shared
    private let requiredWaitTime = 30 // seconds before "I Moved" is clickable

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.8)

                // Main content - explicitly centered using geometry
                VStack(spacing: 16) {
                    // Icon and title
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 48))
                            .foregroundColor(.white)

                        Text("Time to move!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("You've been sitting for \(UserSettings.formatInterval(scheduler.timeSinceLastBreak()))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Activity suggestion (if enabled)
                    if UserSettings.shared.showActivitySuggestions {
                        VStack(spacing: 8) {
                            Text("Try this:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Stand up and stretch")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)

                                Text("• Roll your shoulders back 5 times\n• Stretch your arms above your head\n• Take 3 deep breaths")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .frame(maxWidth: 380)
                    }

                    // Buttons
                    VStack(spacing: 10) {
                        // Primary action button with countdown
                        Button(action: {
                            if canDismiss {
                                handleDismiss(taken: true)
                            }
                        }) {
                            Text(canDismiss ? "I Moved!" : "I Moved! (\(remainingSeconds)s)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(canDismiss ? .white : .white.opacity(0.5))
                                .frame(maxWidth: 280)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canDismiss ? Color.green : Color.green.opacity(0.4))
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canDismiss)

                        // Snooze button
                        Button(action: {
                            showSnoozeOptions.toggle()
                        }) {
                            HStack {
                                Text("Snooze")
                                    .font(.system(size: 16))
                                Image(systemName: showSnoozeOptions ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: 280)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        // Snooze options
                        if showSnoozeOptions {
                            VStack(spacing: 6) {
                                Button(action: {
                                    handleSnooze(duration: Constants.snooze5Min)
                                }) {
                                    Text("5 minutes")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .frame(maxWidth: 280)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.1))
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .keyboardShortcut("1", modifiers: [])

                                Button(action: {
                                    handleSnooze(duration: Constants.snooze10Min)
                                }) {
                                    Text("10 minutes")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .frame(maxWidth: 280)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.1))
                                        )
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .keyboardShortcut("2", modifiers: [])
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Keyboard hints pinned to bottom
                VStack {
                    Spacer()
                    Text(canDismiss
                        ? "Press Enter to continue • 1 or 2 to snooze • Esc to snooze 5 min"
                        : "Wait \(remainingSeconds)s • 1 or 2 to snooze • Esc to snooze 5 min")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 30)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Play sound if enabled
            if UserSettings.shared.soundEnabled {
                NSSound.beep()
            }

            // Start countdown timer
            remainingSeconds = requiredWaitTime
            canDismiss = false

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if remainingSeconds > 0 {
                    remainingSeconds -= 1
                } else {
                    canDismiss = true
                    timer.invalidate()
                }
            }
        }
        // Handle Escape key
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EscapePressed"))) { _ in
            handleSnooze(duration: Constants.snooze5Min)
        }
    }

    private func handleDismiss(taken: Bool) {
        if taken {
            scheduler.breakTaken()
        } else {
            scheduler.breakDismissed()
        }
        onDismiss()
    }

    private func handleSnooze(duration: TimeInterval) {
        scheduler.breakSnoozed(duration: duration)
        onSnooze(duration)
    }
}

#Preview {
    BreakView(
        onDismiss: {},
        onSnooze: { _ in }
    )
}
