# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Moov is a macOS menu bar application (Xcode project) that reminds users to take movement breaks. Built with SwiftUI, targeting macOS 14.0+.

**Key Characteristics:**
- Menu bar only app (no dock icon via `LSUIElement`)
- Uses SwiftData for persistence (requires macOS 14.0+)
- No external dependencies or package managers
- Single target macOS app with manual Xcode setup

## Building and Running

### Prerequisites
- Xcode 15+ installed
- macOS 14.0+ for running the app

### Build Commands

**Build and run in Xcode:**
```bash
# Open project
open Moov.xcodeproj

# Or build from command line
xcodebuild -project Moov.xcodeproj -scheme Moov -configuration Debug build

# Run (must be done from Xcode GUI or with xcodebuild run)
```

**Testing the app:**
1. Build and run (Cmd+R in Xcode)
2. Look for walking figure icon in menu bar
3. Set break interval to 1 minute in Settings for quick testing
4. Overlay should appear after interval expires

**Important:** There are no automated tests yet. All testing is manual.

### Required Build Configuration

The Xcode project **must** have:
1. **Deployment Target**: macOS 14.0 minimum
2. **SwiftData framework linked** (Build Phases → Link Binary With Libraries)
3. **Info.plist setting**: `LSUIElement = YES` (Application is agent)
4. **No code signing required** for local development

## Architecture Overview

### State Management: @Observable Pattern

**Critical:** This project uses Swift's **new @Observable macro** (Swift 5.9+, macOS 14+), not the old ObservableObject protocol.

```swift
// Correct pattern used in this codebase
@Observable
class UserSettings {
    var breakInterval: TimeInterval  // No @Published needed
}

// In views - use @Bindable for two-way bindings
@Bindable private var settings = UserSettings.shared

// Or plain let for read-only
private let settings = UserSettings.shared
```

**DO NOT mix with old patterns:**
- ❌ Don't use `ObservableObject` protocol
- ❌ Don't use `@Published` property wrapper
- ❌ Don't use `@ObservedObject` in views
- ✅ Use `@Observable` macro on model classes
- ✅ Use `@Bindable` in views when bindings ($property) are needed
- ✅ Use plain `let` in views for read-only access

### Core Data Flow

**Break Timer Lifecycle:**
```
BreakScheduler (singleton)
  └─> Timer fires every 1 second
      └─> checkForBreak()
          └─> Checks: paused? disabled? quiet hours? presentation mode?
              └─> If time for break: Post NotificationCenter notification "showBreakOverlay"
                  └─> OverlayWindowManager listens
                      └─> Creates/shows OverlayWindow with BreakView
```

**User Interaction Flow:**
```
User action in BreakView
  └─> Calls BreakScheduler method (breakTaken/breakSnoozed)
      ├─> Logs to SwiftData (BreakSession model)
      └─> Reschedules timer
```

**Settings Persistence:**
```
UserSettings (singleton)
  └─> Properties have didSet observers
      └─> Auto-save to UserDefaults on change
          └─> BreakScheduler reads current values each check
```

### Key Singletons

Three main singletons coordinate app behavior:
1. **UserSettings.shared** - App preferences (persisted to UserDefaults)
2. **BreakScheduler.shared** - Timer logic and break state
3. **OverlayWindowManager.shared** - Window display management

All three use `@Observable` macro for SwiftUI reactivity.

### Communication Patterns

**NotificationCenter** used for decoupled break triggering:
- `Notification.Name.showBreakOverlay` posted by BreakScheduler
- Received by OverlayWindowManager to display overlay

**Callbacks** used for overlay interactions:
- BreakView takes `onDismiss` and `onSnooze` closures
- Called when user interacts with break overlay

**SwiftData** for persistence:
- ModelContainer created in AppDelegate
- MainContext injected into BreakScheduler
- BreakSession model auto-persists via context.save()

## File Organization

```
Moov/
├── MoovApp.swift              # Entry point, AppDelegate, menu bar setup
├── Models/
│   ├── UserSettings.swift      # @Observable, persists to UserDefaults
│   ├── BreakSession.swift      # @Model (SwiftData), logs break history
│   └── BreakActivity.swift     # (Future) Activity suggestions
├── Views/
│   ├── MenuBarView.swift       # Popover content for menu bar
│   ├── SettingsView.swift      # Tabbed settings window (4 sub-views)
│   ├── BreakView.swift         # Break reminder UI content
│   ├── OverlayWindow.swift     # NSWindow subclass + manager
│   └── StatsView.swift         # Statistics dashboard
├── Controllers/
│   └── BreakScheduler.swift    # @Observable, timer + scheduling logic
└── Utilities/
    └── Constants.swift         # App constants, UserDefaults keys
```

**Note:** Services/ and Controllers/IdleDetector are not yet implemented (planned for V2).

## SwiftData Usage

**Model definition:**
```swift
@Model
class BreakSession {
    var id: UUID
    var timestamp: Date
    var type: String        // "micro" or "regular"
    var action: String      // "taken", "snoozed", "dismissed"
    var snoozeDuration: TimeInterval?
}
```

**Setup in AppDelegate:**
```swift
let schema = Schema([BreakSession.self])
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
```

**Accessing in views:**
```swift
@Query private var sessions: [BreakSession]  // Auto-fetches all
```

**Inserting data:**
```swift
// Via injected context in BreakScheduler
modelContext.insert(session)
try modelContext.save()
```

## NSWindow Overlay Implementation

**Window configuration:**
- Window level: `.floating` (above normal apps, below system UI)
- Style mask: `.borderless` (no title bar/chrome)
- Background: `.clear` with 0.8 alpha black overlay
- Collection behavior: `.canJoinAllSpaces, .fullScreenAuxiliary`
- Allows Cmd+Tab (doesn't block user escape)

**Multi-monitor support:**
- Uses `NSScreen.main` frame
- Could be extended to cover all screens with multiple windows

**Keyboard handling:**
- Override `keyDown()` to catch Escape key (keyCode 53)
- Posts notification for BreakView to handle

## Common Gotchas

### Xcode Project Setup Issues

If project won't build or files are missing:
1. Verify all Swift files are in Xcode project navigator (left sidebar)
2. Check Build Phases → Compile Sources includes all .swift files
3. Verify SwiftData.framework is linked
4. Check deployment target is macOS 14.0+
5. Verify Info.plist has `LSUIElement = true`

### @Observable Pattern Issues

If you see these errors:
- `'ObservableObject' requires that X conform to 'ObservableObject'` → Don't mix with old pattern
- `Cannot find '$settings' in scope` → Use `@Bindable var` instead of `let` for bindings
- `'@Published' is only applicable to classes` → Remove @Published, use @Observable macro

### Timer Not Firing

If breaks don't trigger:
- Check `UserSettings.shared.isEnabled` is true
- Check not in quiet hours (UserSettings.isInQuietHours())
- Check `presentationModeEnabled` is false
- Check `pausedUntil` is nil
- Verify `BreakScheduler.shared.start()` was called in AppDelegate

### Overlay Not Appearing

If break triggers but no overlay:
- Verify NotificationCenter observer is registered (OverlayWindowManager.init)
- Check overlay window creation doesn't fail
- Verify NSApp.activate() is called
- Check window alphaValue and isVisible

## Code Modification Guidelines

### Adding New Settings

1. Add property to UserSettings with didSet observer
2. Add UserDefaults key to Constants.UserDefaultsKeys
3. Add UI control to appropriate SettingsView sub-view
4. Use `@Bindable` in view to enable $binding syntax

### Adding New Break Actions

1. Add method to BreakScheduler (e.g., `breakSkipped()`)
2. Log to SwiftData via modelContext
3. Call from BreakView button/gesture
4. Update statistics query in StatsView if needed

### Modifying Break Logic

Core scheduling in `BreakScheduler.checkForBreak()`:
- Runs every 1 second via Timer
- Checks conditions sequentially (pause, disabled, quiet hours, etc.)
- Posts notification when all conditions pass
- Keep checks lightweight (no heavy computation)

### Window Behavior Changes

Overlay configuration in `OverlayWindow.init()`:
- Window level affects z-ordering
- Don't use `.screenSaver + 1` (too aggressive)
- Fade animations in show()/hide() methods
- Test with multiple monitors if changing frame logic

## Future Enhancements (Not Yet Implemented)

These features are planned but not in current codebase:
- Idle detection via CGEventSource (requires Accessibility permission)
- DND/Focus mode detection (programmatic access restricted by Apple)
- Enhanced statistics with charts (Swift Charts framework)
- Micro-breaks (second timer type)
- More activity suggestions (need ActivitiesProvider implementation)

Don't assume these exist - they're documented in plan but not implemented.

## Debugging

**Console output uses emoji prefixes:**
- 🚀 App lifecycle events
- ✅ Success/setup confirmations
- 🔔 Break triggered
- ⏰ Timer/scheduling events
- ⚠️ Warnings
- ❌ Errors

**Key debug points:**
- `BreakScheduler.checkForBreak()` - Why breaks aren't triggering
- `OverlayWindowManager.showOverlay()` - Overlay display issues
- `UserSettings` didSet observers - Settings persistence
- `AppDelegate.setupSwiftData()` - Database setup errors

## Documentation Files

- **README.md** - Setup instructions for building from scratch
- **docs/FEATURES.md** - Complete user-facing feature documentation
- **docs/ARCHITECTURE.md** - Detailed technical architecture guide
- **docs/CHANGELOG.md** - Development issues encountered and solutions

Refer to these for deeper context on design decisions and known issues.

### Keeping Documentation Updated

**IMPORTANT:** When making changes to this codebase, update the relevant documentation files:

**Update FEATURES.md when:**
- Adding new user-facing features (menu items, settings, keyboard shortcuts)
- Changing how existing features work
- Modifying the break overlay UI or behavior
- Adding/changing statistics or tracking
- Implementing any planned future features from the wishlist

**Update ARCHITECTURE.md when:**
- Changing core data flow patterns
- Adding new singletons or managers
- Modifying the observation pattern (e.g., switching models)
- Changing communication patterns (NotificationCenter, callbacks)
- Adding new frameworks or dependencies
- Restructuring file organization significantly
- Implementing major architectural changes (like idle detection, DND monitoring)

**Update CHANGELOG.md when:**
- Encountering build/compilation errors during development
- Discovering bugs and their root causes
- Finding workarounds for Swift/SwiftUI issues
- Making architectural decisions that differ from initial plan
- Running into Xcode configuration issues
- Learning lessons about Swift patterns or macOS development

**Format for updates:**
- FEATURES.md: Add new sections or update existing ones with clear user-facing language
- ARCHITECTURE.md: Update data flow diagrams and add technical explanations
- CHANGELOG.md: Add dated entries with Issue #, Problem, Root Cause, Solution format

**When in doubt:** If a change requires understanding multiple files or could confuse future developers, document it.
