//
//  MenuBarView.swift
//  Moov
//
//  Menu bar dropdown interface
//

import SwiftUI

struct MenuBarView: View {
    @Bindable private var settings = UserSettings.shared
    private let scheduler = BreakScheduler.shared

    @Environment(\.dismiss) private var dismissPopover

    var body: some View {
        VStack(spacing: 0) {
            // Status section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(settings.presentationModeEnabled ? .orange : .green)
                    Text("Moov")
                        .font(.headline)
                    Spacer()
                }

                if settings.presentationModeEnabled {
                    Text("Presentation Mode Active")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if let pausedUntil = scheduler.pausedUntil {
                    Text("Paused until \(pausedUntil, style: .time)")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if settings.isEnabled {
                    Text("Next break in \(UserSettings.formatInterval(scheduler.timeUntilNextBreak()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Actions
            VStack(spacing: 0) {
                MenuButton(title: "Take Break Now", disabled: !settings.isEnabled) {
                    scheduler.triggerManualBreak()
                }

                Divider()

                MenuButton(title: "Pause for 1 Hour") {
                    scheduler.pause(for: 60 * 60)
                }

                MenuButton(title: "Pause for 2 Hours") {
                    scheduler.pause(for: 2 * 60 * 60)
                }

                MenuButton(title: "Pause Until Tomorrow") {
                    scheduler.pauseUntilEndOfDay()
                }

                if scheduler.pausedUntil != nil {
                    MenuButton(title: "Resume Breaks") {
                        scheduler.resume()
                    }
                }

                Divider()

                HStack {
                    Text("Presentation Mode")
                    Spacer()
                    Toggle("", isOn: $settings.presentationModeEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                MenuButton(title: "Settings...") {
                    dismissPopover()
                    WindowManager.shared.openSettings()
                }

                MenuButton(title: "Statistics...") {
                    dismissPopover()
                    WindowManager.shared.openStats()
                }
            }

            Divider()

            MenuButton(title: "Quit Moov") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 240)
    }
}

// MARK: - Menu Button with full click area
struct MenuButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(disabled ? .secondary : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isHovered && !disabled ? Color.accentColor.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    MenuBarView()
}
