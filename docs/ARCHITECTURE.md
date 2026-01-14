# Moov Architecture Guide

## Project Structure

```
Moov/
├── MoovApp.swift                      # 🚀 Main app entry point
│   ├── AppDelegate                    # Handles app lifecycle
│   ├── Sets up menu bar               # Creates status bar item
│   ├── Configures SwiftData           # Sets up database
│   └── Starts BreakScheduler          # Begins timer
│
├── Models/                            # 📦 Data models
│   ├── UserSettings.swift             # App preferences (persisted to UserDefaults)
│   ├── BreakSession.swift             # SwiftData model for break history
│   └── [BreakActivity.swift]          # (Future) Activity suggestions
│
├── Views/                             # 🎨 User interface
│   ├── MenuBarView.swift              # Menu bar dropdown menu
│   ├── SettingsView.swift             # Settings/preferences window
│   │   ├── GeneralSettingsView        # Break interval, sounds
│   │   ├── ScheduleSettingsView       # Quiet hours
│   │   ├── ActivitiesSettingsView     # Activity toggles
│   │   └── AboutView                  # App info
│   ├── OverlayWindow.swift            # Full-screen overlay window manager
│   ├── BreakView.swift                # Break reminder UI (shown in overlay)
│   └── StatsView.swift                # Statistics dashboard
│
├── Controllers/                       # 🎮 Business logic
│   ├── BreakScheduler.swift           # Timer and scheduling logic
│   └── [IdleDetector.swift]           # (Future) Idle detection
│
├── Services/                          # 🔧 Helper services
│   └── [StatisticsManager.swift]      # (Future) Stats calculations
│
└── Utilities/                         # 🛠️ Constants and helpers
    └── Constants.swift                # App-wide constants
```

## Data Flow

### 1. App Launch
```
MoovApp.swift (main)
  ├─> AppDelegate.applicationDidFinishLaunching()
  ├─> setupSwiftData()                # Create model container
  ├─> setupMenuBar()                  # Create status item
  └─> BreakScheduler.shared.start()  # Start timer
```

### 2. Break Timer Flow
```
BreakScheduler
  ├─> Timer fires every 1 second
  ├─> checkForBreak()
  │   ├─> Check if paused?
  │   ├─> Check if disabled?
  │   ├─> Check quiet hours?
  │   ├─> Check presentation mode?
  │   └─> Time for break?
  │       └─> triggerBreak()
  │           └─> Post notification "showBreakOverlay"
  │
  └─> OverlayWindowManager receives notification
      └─> Shows OverlayWindow with BreakView
```

### 3. User Interaction Flow
```
BreakView (overlay shown)
  ├─> User clicks "I Moved!"
  │   └─> scheduler.breakTaken()
  │       ├─> Log to SwiftData
  │       └─> Reset timer for next break
  │
  ├─> User clicks "Snooze"
  │   └─> scheduler.breakSnoozed(duration)
  │       ├─> Log to SwiftData
  │       └─> Reschedule timer for snooze duration
  │
  └─> User presses Esc
      └─> scheduler.breakSnoozed(5 min)
```

### 4. Settings Flow
```
User opens Settings
  ├─> SettingsView appears
  ├─> User changes breakInterval
  └─> UserSettings.breakInterval setter
      └─> Saves to UserDefaults
          └─> BreakScheduler uses new interval for next break
```

## Key Components Explained

### UserSettings.swift
- **Purpose**: Stores all user preferences
- **Persistence**: UserDefaults (automatic via property observers)
- **Pattern**: Singleton (`UserSettings.shared`)
- **Observable**: Uses `@Observable` macro for SwiftUI binding

### BreakScheduler.swift
- **Purpose**: Manages break timing logic
- **Timer**: Runs every 1 second to check conditions
- **Responsibilities**:
  - Check if it's time for a break
  - Respect quiet hours, presentation mode, pauses
  - Trigger overlay display
  - Log sessions to SwiftData
- **Pattern**: Singleton (`BreakScheduler.shared`)

### OverlayWindow.swift
- **Purpose**: Full-screen transparent window
- **Window Level**: `.floating` (above normal apps, below system UI)
- **Features**:
  - Fade in/out animations
  - Covers all screens
  - Doesn't block Cmd+Tab
  - Handles Escape key
- **Implementation Notes**:
  - Uses `NSHostingView` to host SwiftUI content
  - `autoresizingMask = [.width, .height]` ensures proper sizing
  - Window is recreated fresh on each show (prevents state issues)

### BreakView.swift
- **Purpose**: The UI shown during a break
- **Features**:
  - Shows time since last break
  - Activity suggestions (if enabled)
  - Buttons: "I Moved!" and "Snooze"
  - Keyboard shortcuts
- **Actions**: Calls BreakScheduler methods on user interaction
- **Layout Approach**: Uses `GeometryReader` for explicit positioning
  - ⚠️ **Important**: Don't use `Spacer()`-based centering with borderless NSWindow
  - SwiftUI's implicit layout doesn't work reliably with NSHostingView in custom windows
  - Explicit `frame(width:height:)` with geometry ensures proper centering

### BreakSession.swift (SwiftData)
- **Purpose**: Stores break history
- **Fields**:
  - `id`: Unique identifier
  - `timestamp`: When break occurred
  - `type`: "micro" or "regular"
  - `action`: "taken", "snoozed", or "dismissed"
  - `snoozeDuration`: How long (if snoozed)
- **Storage**: Automatic via SwiftData (SQLite under the hood)

## Communication Patterns

### 1. Notification Pattern (Break Trigger)
```swift
// BreakScheduler posts
NotificationCenter.default.post(name: .showBreakOverlay, object: nil)

// OverlayWindowManager listens
NotificationCenter.default.addObserver(...)
```

### 2. Callback Pattern (User Actions)
```swift
BreakView(
  onDismiss: { /* hide overlay */ },
  onSnooze: { duration in /* hide and snooze */ }
)
```

### 3. Singleton Pattern (Shared State)
```swift
UserSettings.shared
BreakScheduler.shared
OverlayWindowManager.shared
```

### 4. SwiftUI Environment (Settings)
```swift
@ObservedObject private var settings = UserSettings.shared
// Settings changes automatically update UI
```

## Configuration Files

### Info.plist
- **LSUIElement**: Makes app menu bar only (no dock icon)
- **LSMinimumSystemVersion**: Requires macOS 14.0+
- **CFBundleIdentifier**: `com.suchit.moov`

### No Entitlements Needed (MVP)
- No sandbox (not required for Mac App Store in MVP)
- No hardened runtime needed yet
- No network, camera, mic access needed

## Build Configuration

### Minimum Requirements
- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

### Frameworks
- **SwiftUI**: UI framework
- **SwiftData**: Persistence
- **AppKit**: Menu bar, NSWindow
- **Foundation**: Date, Timer, UserDefaults

### No External Dependencies
- No CocoaPods
- No Swift Package Manager dependencies
- No third-party libraries
- Pure Swift/SwiftUI

## Testing Strategy

### Manual Testing (MVP)
1. **Smoke Test**: See README.md "Step 5: Test It!"
2. **Full Checklist**: See plan file testing section

### Future: Unit Tests
- `BreakSchedulerTests`: Timer logic, quiet hours, pauses
- `UserSettingsTests`: Persistence, quiet hours calculation
- `StatisticsTests`: Stats calculations, compliance rate

### Future: UI Tests
- Overlay appearance
- Keyboard shortcuts
- Settings persistence

## Performance Considerations

### Current Implementation
- ✅ Timer fires every 1 second (minimal CPU)
- ✅ No network calls
- ✅ Minimal memory (< 50MB)
- ✅ SwiftData handles persistence efficiently

### Potential Optimizations (if needed)
- Use longer timer interval (10 seconds) and calculate delta
- Lazy load statistics view
- Implement pagination for break history

## Future Enhancements

### Phase 5: Smart Features
- **IdleDetector**: CGEventSource for idle time
- **ActivitiesProvider**: Database of stretches

### Phase 6: Statistics
- **StatisticsManager**: Complex queries, aggregations
- **Charts**: Swift Charts for visualizations

### Phase 7: Gamification
- Streak tracking
- Achievements
- Milestones

### Phase 8: Polish
- Global keyboard shortcuts
- Launch at login
- Custom app icon
- Accessibility improvements

## Debugging Tips

### Enable Debug Logging
Look for print statements with emojis:
- 🚀 App lifecycle
- ✅ Success/setup
- 🔔 Break triggered
- ⏰ Timer events
- ⚠️ Warnings
- ❌ Errors

### Common Issues
1. **Timer not firing**: Check `isEnabled` in UserSettings
2. **Overlay not showing**: Check presentation mode, quiet hours
3. **Overlay content cut off**: Ensure BreakView uses GeometryReader, not Spacer()-based layout
4. **Settings not persisting**: Check UserDefaults in Console.app
5. **SwiftData errors**: Check model container setup in AppDelegate

### Xcode Debugging
- Set breakpoints in `BreakScheduler.checkForBreak()`
- Watch `nextBreakTime` variable
- Check console for print statements

## Code Style

### Naming Conventions
- **Classes**: PascalCase (`BreakScheduler`)
- **Properties**: camelCase (`breakInterval`)
- **Constants**: PascalCase in enum (`Constants.UserDefaultsKeys.breakInterval`)
- **Files**: Match class name (`BreakScheduler.swift`)

### Organization
- **MARK comments**: Section views and methods
- **Comments**: Explain "why", not "what"
- **Spacing**: Blank lines between logical sections

### SwiftUI Best Practices
- Extract subviews when > 50 lines
- Use `@Observable` macro for models (not ObservableObject protocol)
- Use `@Bindable var` when bindings ($property) are needed
- Use plain `let` for read-only access to @Observable objects
- Use `Environment` for shared context

That's the complete architecture! 🎉
