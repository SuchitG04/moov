//
//  OverlayWindow.swift
//  Moov
//
//  Full-screen transparent overlay window
//

import AppKit
import SwiftUI

class OverlayWindow: NSWindow {
    init() {
        // Create a window that covers the entire screen
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let frame = screen.frame

        print("🖥️ Screen frame: \(frame)")

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        print("🪟 Window frame after init: \(self.frame)")

        // Configure window properties
        self.level = .floating // Above normal apps but below system UI
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Make window visible on all spaces
        self.isMovableByWindowBackground = false

        // Start with zero opacity for fade-in animation
        self.alphaValue = 0.0
    }

    // Show with fade-in animation
    func show() {
        self.makeKeyAndOrderFront(nil)

        // Activate the app to ensure window is in front
        NSApp.activate(ignoringOtherApps: true)

        // Fade in
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.overlayFadeInDuration
            self.animator().alphaValue = 1.0
        })

        print("🪟 Overlay window shown")
    }

    // Hide with fade-out animation
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Constants.overlayFadeOutDuration
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
            completion?()
            print("🪟 Overlay window hidden")
        })
    }

    // Override to handle Escape key
    override func keyDown(with event: NSEvent) {
        // Check for Escape key
        if event.keyCode == 53 { // Escape key code
            NotificationCenter.default.post(name: NSNotification.Name("EscapePressed"), object: nil)
        } else {
            super.keyDown(with: event)
        }
    }

    // Prevent window from becoming key when user Cmd+Tabs away
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}

// Window manager to handle overlay
@Observable
class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private var window: OverlayWindow?
    var isShowing = false

    private init() {
        // Listen for break notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showOverlay),
            name: .showBreakOverlay,
            object: nil
        )
    }

    @objc private func showOverlay() {
        guard !isShowing else {
            print("⚠️  Overlay already showing, skipping")
            return
        }

        print("🪟 Creating overlay window...")

        // Clean up any existing window
        if let existingWindow = window {
            existingWindow.orderOut(nil)
            existingWindow.contentView = nil
        }

        // Create fresh window and content
        window = OverlayWindow()

        let breakView = BreakView(
            onDismiss: { [weak self] in
                self?.hideOverlay()
            },
            onSnooze: { [weak self] duration in
                self?.hideOverlay()
            }
        )
        let hostingView = NSHostingView(rootView: breakView)
        hostingView.autoresizingMask = [.width, .height]
        window?.contentView = hostingView

        // Show the window
        window?.show()
        isShowing = true

        print("🪟 Overlay window created and shown")
    }

    func hideOverlay() {
        window?.hide { [weak self] in
            self?.isShowing = false
        }
    }

    // Handle window losing focus (user Cmd+Tab away)
    func handleWindowDeactivated() {
        if isShowing {
            print("🔄 Window deactivated, treating as snooze")
            BreakScheduler.shared.breakSnoozed(duration: Constants.snooze5Min)
            hideOverlay()
        }
    }
}
