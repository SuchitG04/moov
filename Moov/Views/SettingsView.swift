//
//  SettingsView.swift
//  Moov
//
//  Settings/Preferences window
//

import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case schedule = "Schedule"
    case activities = "Activities"
    case about = "About"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .schedule: return "clock"
        case .activities: return "figure.walk"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    private let settings = UserSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                                .frame(width: 20)
                            Text(tab.rawValue)
                                .font(.system(size: 13))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: 150)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .schedule:
                    ScheduleSettingsView()
                case .activities:
                    ActivitiesSettingsView()
                case .about:
                    AboutView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 550, height: 380)
    }
}

// MARK: - General Settings
struct GeneralSettingsView: View {
    @Bindable private var settings = UserSettings.shared
    @State private var isCustomInterval = false
    @State private var customMinutes: String = "1"
    @State private var selectedPreset: TimeInterval = 30 * 60

    // Preset intervals in seconds
    private let presetIntervals: [TimeInterval] = [
        1 * 60,      // 1 minute (for testing)
        10 * 60,     // 10 minutes
        15 * 60,     // 15 minutes
        20 * 60,     // 20 minutes
        25 * 60,     // 25 minutes
        30 * 60,     // 30 minutes
        45 * 60,     // 45 minutes
        60 * 60      // 60 minutes
    ]

    var body: some View {
        Form {
            Section {
                Toggle("Enable break reminders", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { _, newValue in
                        if newValue {
                            BreakScheduler.shared.start()
                        } else {
                            BreakScheduler.shared.stop()
                        }
                    }
            }

            Section(header: Text("Break Interval")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remind me every:")
                        .font(.subheadline)

                    Picker("", selection: $selectedPreset) {
                        Text("1 minute").tag(TimeInterval(1 * 60))
                        Text("10 minutes").tag(TimeInterval(10 * 60))
                        Text("15 minutes").tag(TimeInterval(15 * 60))
                        Text("20 minutes").tag(TimeInterval(20 * 60))
                        Text("25 minutes").tag(TimeInterval(25 * 60))
                        Text("30 minutes").tag(TimeInterval(30 * 60))
                        Text("45 minutes").tag(TimeInterval(45 * 60))
                        Text("60 minutes").tag(TimeInterval(60 * 60))
                        Text("Custom...").tag(TimeInterval(-1))
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: selectedPreset) { _, newValue in
                        if newValue == -1 {
                            isCustomInterval = true
                        } else {
                            isCustomInterval = false
                            settings.breakInterval = newValue
                            BreakScheduler.shared.resetWithCurrentInterval()
                        }
                    }

                    if isCustomInterval {
                        HStack(spacing: 8) {
                            TextField("Minutes", text: $customMinutes)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .onChange(of: customMinutes) { _, newValue in
                                    // Filter to only allow digits
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        customMinutes = filtered
                                    }

                                    // Update the break interval
                                    if let minutes = Int(filtered), minutes > 0 {
                                        settings.breakInterval = TimeInterval(minutes * 60)
                                        BreakScheduler.shared.resetWithCurrentInterval()
                                    }
                                }

                            Text("minutes")
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                        .padding(.top, 4)

                        Text("Enter any value in minutes (e.g., 1 for quick testing)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Notifications")) {
                Toggle("Play sound when break starts", isOn: $settings.soundEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            // Check if current interval matches a preset
            if presetIntervals.contains(settings.breakInterval) {
                selectedPreset = settings.breakInterval
                isCustomInterval = false
            } else {
                selectedPreset = -1
                isCustomInterval = true
                let minutes = Int(settings.breakInterval / 60)
                customMinutes = "\(minutes)"
            }
        }
    }
}

// MARK: - Schedule Settings
struct ScheduleSettingsView: View {
    @Bindable private var settings = UserSettings.shared
    @State private var quietHoursEnabled = false

    var body: some View {
        Form {
            Section(header: Text("Quiet Hours")) {
                Toggle("Enable quiet hours", isOn: $quietHoursEnabled)
                    .onChange(of: quietHoursEnabled) { _, newValue in
                        if !newValue {
                            settings.quietHoursStart = nil
                            settings.quietHoursEnd = nil
                        } else {
                            // Set default quiet hours (10 PM to 7 AM)
                            let calendar = Calendar.current
                            var startComponents = DateComponents()
                            startComponents.hour = 22 // 10 PM
                            startComponents.minute = 0

                            var endComponents = DateComponents()
                            endComponents.hour = 7 // 7 AM
                            endComponents.minute = 0

                            settings.quietHoursStart = calendar.date(from: startComponents)
                            settings.quietHoursEnd = calendar.date(from: endComponents)
                        }
                    }

                if quietHoursEnabled {
                    DatePicker(
                        "Start time:",
                        selection: Binding(
                            get: { settings.quietHoursStart ?? Date() },
                            set: { settings.quietHoursStart = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End time:",
                        selection: Binding(
                            get: { settings.quietHoursEnd ?? Date() },
                            set: { settings.quietHoursEnd = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )

                    Text("Breaks will be paused during these hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            quietHoursEnabled = settings.quietHoursStart != nil
        }
    }
}

// MARK: - Activities Settings
struct ActivitiesSettingsView: View {
    @Bindable private var settings = UserSettings.shared

    var body: some View {
        Form {
            Section {
                Toggle("Show activity suggestions", isOn: $settings.showActivitySuggestions)

                if settings.showActivitySuggestions {
                    Text("Simple stretch and movement suggestions will appear during breaks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Moov")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("A simple app to remind you to move and stretch regularly")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 300)

            Spacer()

            Text("Built with ❤️ using Swift & SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
}

#Preview {
    SettingsView()
}
