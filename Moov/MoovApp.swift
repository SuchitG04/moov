//
//  MoovApp.swift
//  Moov
//
//  Main app entry point
//

import SwiftUI
import SwiftData

@main
struct MoovApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup needed - we're a menu bar only app
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let overlayManager = OverlayWindowManager.shared
    private let scheduler = BreakScheduler.shared

    // SwiftData model container
    private var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Set up SwiftData
        setupSwiftData()

        // Set up menu bar
        setupMenuBar()

        // Start break scheduler
        scheduler.start()

        print("🚀 Moov started successfully!")
    }

    private func setupSwiftData() {
        do {
            let schema = Schema([BreakSession.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Inject model context into scheduler
            if let context = modelContainer?.mainContext {
                scheduler.modelContext = context
            }

            // Inject model container into WindowManager for Stats view
            WindowManager.shared.modelContainer = modelContainer

            print("✅ SwiftData configured")
        } catch {
            print("❌ Failed to set up SwiftData: \(error)")
        }
    }

    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: "Moov")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 240, height: 400)
        popover?.behavior = .transient

        // Create menu bar view with model context
        if let modelContainer = modelContainer {
            let menuBarView = MenuBarView()
                .modelContainer(modelContainer)

            popover?.contentViewController = NSHostingController(rootView: menuBarView)
        }

        print("✅ Menu bar configured")
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Activate the app so popover gets focus and can be dismissed by clicking outside
                NSApp.activate(ignoringOtherApps: true)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        scheduler.stop()
        print("👋 Moov stopped")
    }
}
