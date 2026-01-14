//
//  WindowManager.swift
//  Moov
//
//  Manages separate windows for Settings and Stats
//

import SwiftUI
import SwiftData
import AppKit

class WindowManager {
    static let shared = WindowManager()

    private var settingsWindow: NSWindow?
    private var statsWindow: NSWindow?

    // ModelContainer for SwiftData views (set by AppDelegate)
    var modelContainer: ModelContainer?

    private init() {}

    func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Moov Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openStats() {
        if let window = statsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard let modelContainer = modelContainer else {
            print("⚠️ ModelContainer not set in WindowManager")
            return
        }

        let statsView = StatsView()
            .modelContainer(modelContainer)
        let hostingController = NSHostingController(rootView: statsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Moov Statistics"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating

        statsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeAll() {
        settingsWindow?.close()
        statsWindow?.close()
    }
}
