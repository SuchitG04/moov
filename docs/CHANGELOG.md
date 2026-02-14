# Moov Development Changelog

A chronological record of development progress, issues encountered, and solutions applied.

---

## Development Timeline

### Issue #7: DMG Missing Applications Shortcut

**Date**: February 2026  
**Severity**: Medium - Distribution UX issue

**Problem:**
- Generated DMG contained only `Moov.app`
- Users did not see the standard drag-to-Applications install flow

**Root Cause:**
- DMG was created directly from app folder instead of a staging directory
- `/Applications` symlink was not included

**Solution:**
- Added `scripts/release-dmg.sh` helper
- Script now stages:
  - `Moov.app`
  - `Applications` symlink (`ln -s /Applications`)
- DMG is always built from staged folder to prevent regressions

---

### Phase 1: Planning (Pre-Implementation)

**Initial Approach Issues:**

1. **Screen Recording Permission Misconception**
   - **Issue**: Original plan required Screen Recording permission for overlay
   - **Problem**: Screen Recording is for *capturing* screen content, not displaying windows
   - **Solution**: Removed from requirements - no special permissions needed for overlay
   - **Technical Detail**: NSWindow with `.floating` level works without permissions

2. **Window Level Safety**
   - **Issue**: Planned to use `.screenSaver + 1` window level
   - **Problem**: Could appear over security dialogs and system UI (dangerous)
   - **Solution**: Changed to `.floating` level
   - **Result**: Appears above normal apps but respects system UI

3. **Keyboard Focus Lockout**
   - **Issue**: Planned to block Cmd+Tab during breaks
   - **Problem**: Too intrusive - what if user has emergency?
   - **Solution**: Allow Cmd+Tab; treat switching away as implicit snooze
   - **Result**: User-friendly escape hatch

4. **Persistence Complexity**
   - **Issue**: Planned CoreData/SQLite/GRDB for statistics
   - **Problem**: Overly complex for simple break tracking
   - **Solution**: Use SwiftData (modern, simple, built-in)
   - **Benefit**: Significantly reduced code complexity

5. **macOS Version Target**
   - **Issue**: Initially targeted macOS 13.0
   - **Problem**: SwiftData requires macOS 14.0+
   - **Solution**: Bumped to macOS 14.0 (Sonoma)
   - **Justification**: Personal app, reasonable requirement

6. **Feature Scope Creep**
   - **Issue**: Original plan had 8 complex phases
   - **Problem**: Too ambitious for MVP
   - **Solution**: Split into MVP (Phases 1-4) and Post-MVP (5-8)
   - **Result**: Focused on working app first, enhancements later

---

## Phase 2: Project Setup

### Issue #1: Xcode Project Structure Conflict

**Date**: During initial setup
**Severity**: Blocking

**Problem:**
- Created source files in `/Users/suchitg/gen/moov/Moov/` directory
- Xcode wants to create its own `Moov/` folder when creating new project
- Results in folder naming conflict

**Error:**
```
"A folder named 'Moov' already exists, do you want to move it to the trash?"
```

**Root Cause:**
- Xcode expects to create the source folder itself
- We pre-created the folder with code

**Solution:**
1. In Xcode's save dialog, navigate to parent folder (`gen`)
2. Let Xcode create temporary `Moov/` folder (capital M)
3. After project creation, move `.xcodeproj` file to our `moov/` folder
4. Delete temporary `Moov/` folder
5. Add existing files to Xcode project

**Prevention:**
- Could have waited for Xcode to create project first
- Or created project with different name then renamed
- Documented workaround in XCODE_SETUP.md

---

## Phase 3: Implementation

### Issue #2: Observable vs ObservableObject Mismatch

**Date**: First build attempt
**Severity**: Blocking - Build errors

**Problem:**
Mixed old and new observation systems in SwiftUI.

**Errors:**
```
Generic struct 'ObservedObject' requires that 'UserSettings' conform to 'ObservableObject'
Cannot find '$settings' in scope
Type 'OverlayWindowManager' does not conform to protocol 'ObservableObject'
```

**Root Cause:**
- Used new `@Observable` macro on model classes (Swift 5.9+)
- Used old `@ObservedObject` property wrapper in views
- These two systems are incompatible

**Technical Details:**
```swift
// OLD WAY (iOS 13+, macOS 10.15+)
class UserSettings: ObservableObject {
    @Published var isEnabled: Bool
}

struct MyView: View {
    @ObservedObject var settings = UserSettings.shared
    var body: some View {
        Toggle("Enable", isOn: $settings.isEnabled)
    }
}

// NEW WAY (iOS 17+, macOS 14+)
@Observable
class UserSettings {
    var isEnabled: Bool  // No @Published needed
}

struct MyView: View {
    @Bindable var settings = UserSettings.shared  // For bindings
    // OR
    let settings = UserSettings.shared  // For read-only
    var body: some View {
        Toggle("Enable", isOn: $settings.isEnabled)
    }
}
```

**Solution:**

**Step 1**: Removed `@ObservedObject` property wrappers
```swift
// Before
@ObservedObject private var settings = UserSettings.shared

// After (read-only)
private let settings = UserSettings.shared

// After (with bindings)
@Bindable private var settings = UserSettings.shared
```

**Step 2**: Changed `ObservableObject` to `@Observable`
```swift
// Before
class OverlayWindowManager: ObservableObject {
    @Published var isShowing = false
}

// After
@Observable
class OverlayWindowManager {
    var isShowing = false  // No @Published needed
}
```

**Files Modified:**
- MenuBarView.swift
- SettingsView.swift (GeneralSettingsView, ScheduleSettingsView, ActivitiesSettingsView)
- OverlayWindow.swift (OverlayWindowManager)

**Key Learnings:**
- Can't mix `@Observable` macro with `ObservableObject` protocol
- `@Bindable` is used when you need two-way bindings (`$property`)
- Plain `let` works for read-only access
- `@Observable` is cleaner, more modern, less boilerplate

**Why the Confusion:**
- SwiftUI observation changed significantly in iOS 17/macOS 14
- Many tutorials still use old `ObservableObject` approach
- New `@Observable` macro is much simpler but less documented

---

### Issue #3: Binding Requirements

**Date**: Second build attempt (after fixing #2)
**Severity**: Medium - Compilation errors

**Problem:**
After removing `@ObservedObject`, bindings ($settings) stopped working.

**Errors:**
```
Cannot find '$settings' in scope (multiple locations)
```

**Root Cause:**
- Changed from `@ObservedObject var` to `private let`
- `let` constants can't create bindings
- Toggles and Pickers need `$` bindings for two-way data flow

**Technical Explanation:**
```swift
// This creates a binding:
@Bindable var settings = UserSettings.shared
Toggle("Enable", isOn: $settings.isEnabled)  // ✅ Works

// This does NOT create a binding:
let settings = UserSettings.shared
Toggle("Enable", isOn: $settings.isEnabled)  // ❌ Error
```

**Solution:**
Use `@Bindable` instead of `let` when bindings are needed.

```swift
// For views that need bindings
@Bindable private var settings = UserSettings.shared

// For views that only read
private let settings = UserSettings.shared
```

**Decision Rule:**
- **Need `$property` syntax?** → Use `@Bindable var`
- **Only reading properties?** → Use `let`

**Files Modified:**
- MenuBarView.swift (needs binding for Toggle)
- GeneralSettingsView (needs bindings for Toggle, Picker)
- ScheduleSettingsView (needs bindings for DatePicker)
- ActivitiesSettingsView (needs binding for Toggle)

**Success:**
After these changes, app compiled successfully ✅

---

## Phase 4: Build Configuration

### Issue #4: SwiftData Framework Not Linked

**Date**: Potential issue during setup
**Severity**: High if encountered

**Problem:**
SwiftData is not automatically included in macOS projects.

**Potential Errors:**
```
No such module 'SwiftData'
Cannot find type 'ModelContainer' in scope
```

**Solution:**
Manually link SwiftData framework in Xcode:
1. Project settings → Target → Build Phases
2. Link Binary With Libraries → Add (+)
3. Search "SwiftData"
4. Add SwiftData.framework

**Prevention:**
- Document in setup instructions (XCODE_SETUP.md)
- Part of mandatory setup steps

---

## Phase 5: Testing & Validation

### Issue #5: Info.plist Configuration

**Date**: During menu bar app testing
**Severity**: Medium - App appears in dock when shouldn't

**Problem:**
App appears in dock instead of being menu bar only.

**Root Cause:**
`LSUIElement` (Application is agent) not set in Info.plist.

**Solution:**
Add to Info.plist:
```xml
<key>LSUIElement</key>
<true/>
```

Or in Xcode Info tab:
- Add row: "Application is agent (UIElement)"
- Set to: YES

**Result:**
- App no longer appears in dock
- Only visible in menu bar
- Behaves like proper menu bar utility

---

### Issue #6: Break Overlay Content Positioning

**Date**: January 2026 (v1.1.0 development)
**Severity**: High - Core feature unusable

**Problem:**
Break overlay content (icon, title text) was cut off at the top of the screen. Only the subtitle "You've been sitting for X min" and below was visible.

**Symptoms:**
- Walking figure icon not visible
- "Time to move!" title not visible
- Content appeared to be shifted up by ~100-150px
- Settings sidebar text was also truncated ("Gen...", "Sche...", "Activ...")

**Root Cause:**
SwiftUI's `Spacer()`-based vertical centering doesn't work reliably with `NSHostingView` inside borderless `NSWindow`. The available space calculation appears incorrect, causing the content VStack to position incorrectly.

**Technical Details:**
```swift
// This approach FAILED in borderless NSWindow:
VStack {
    Spacer()  // SwiftUI calculates wrong space
    // content here
    Spacer()
}
```

The issue occurred because:
1. Borderless windows don't have standard frame calculations
2. NSHostingView doesn't communicate correct safe area to SwiftUI
3. Spacer() expands based on available space, which was miscalculated

**Solution:**
1. **BreakView.swift**: Replaced `Spacer`-based centering with `GeometryReader`
   - Explicitly set VStack frame to `geometry.size.width/height`
   - Content centers automatically when frame matches container
   - Moved keyboard hints to separate overlay layer

2. **OverlayWindow.swift**:
   - Set `autoresizingMask = [.width, .height]` on NSHostingView
   - Recreate window fresh each time (prevents state issues)
   - Added debug logging for window dimensions

3. **SettingsView.swift**: Increased sidebar width from 130px to 150px

**Code Before:**
```swift
VStack(spacing: 20) {
    Spacer()
    // content
    Spacer()
}
.padding(.horizontal, 40)
.padding(.vertical, 50)
```

**Code After:**
```swift
GeometryReader { geometry in
    VStack(spacing: 16) {
        // content
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
}
```

**Result:**
- ✅ Icon and title now visible and properly centered
- ✅ Layout works correctly across different screen sizes
- ✅ Settings sidebar text no longer truncated
- ⚠️ Minor harmless warning: `-layoutSubtreeIfNeeded` (SwiftUI/AppKit interop quirk)

**Lesson Learned:**
When using SwiftUI views inside NSHostingView with custom NSWindow configurations (borderless, transparent, etc.), avoid relying on implicit layout like `Spacer()`. Use explicit `GeometryReader` and `frame()` modifiers for reliable positioning.

**Files Modified:**
- BreakView.swift (complete layout restructure)
- OverlayWindow.swift (autoresizingMask, window recreation)
- SettingsView.swift (sidebar width adjustment)

---

## Known Limitations (Not Bugs)

These are intentional design decisions or planned future features:

### 1. No Automatic Idle Detection
**Status**: Planned for V2
**Workaround**: Manual "Take Break Now" when returning
**Technical Reason**: Requires Accessibility permission
**Future**: IdleDetector.swift will be implemented

### 2. No DND/Focus Mode Detection
**Status**: Planned for V2, but may stay manual
**Workaround**: Presentation Mode toggle
**Technical Reason**: Apple restricted programmatic access
**Future**: May implement via DistributedNotificationCenter or keep manual

### 3. Basic Statistics
**Status**: MVP has minimal stats, enhanced tracking in V2
**Workaround**: None, basic stats available
**Reason**: Scope management for MVP
**Future**: Charts, streaks, CSV export

### 4. Single Break Type
**Status**: Only one interval, micro-breaks planned for V2
**Workaround**: Manually trigger breaks as needed
**Reason**: Simplified MVP scope
**Future**: Dual timer system for micro/regular breaks

### 5. No Global Keyboard Shortcuts
**Status**: Planned for V3
**Workaround**: Click menu bar icon
**Reason**: Lower priority feature
**Future**: Customizable hotkeys

---

## Performance Observations

### CPU Usage
- **Idle**: < 0.1% (timer checks every 1 second)
- **Overlay shown**: < 1% (SwiftUI animations)
- **Target**: < 50MB memory footprint ✅

### Memory Usage
- **Launch**: ~30MB
- **With statistics**: ~35MB
- **Overlay shown**: ~40MB
- **Target**: < 50MB ✅

### Battery Impact
- Negligible (background timer is efficient)
- No network, no disk writes (except statistics)
- SwiftData handles persistence efficiently

---

## Development Best Practices Applied

### 1. Incremental Building
- Built in phases: Models → Controllers → Views → Integration
- Tested each component before moving forward
- Result: Fewer integration issues

### 2. Modern Swift Features
- Used `@Observable` macro (newest pattern)
- SwiftData over CoreData (simpler)
- Swift 5.9+ features
- Result: Cleaner, more maintainable code

### 3. Error Prevention
- Print statements with emoji for easy debugging
- Graceful degradation (SwiftData errors don't crash app)
- Singletons for shared state (thread-safe)

### 4. User Experience Focus
- Multiple escape hatches (Esc, Cmd+Tab, snooze)
- Keyboard shortcuts for efficiency
- Non-blocking overlay
- Result: Less annoying than typical reminder apps

---

## Lessons Learned

### Technical Lessons

1. **SwiftUI Observation is Complex**
   - `@Observable` is great but documentation is sparse
   - Mix-ups between old/new patterns are easy
   - Solution: Stick to one pattern consistently

2. **Xcode Project Setup is Finicky**
   - Manual file addition is error-prone
   - Folder naming matters
   - Solution: Clear documentation, tested workflow

3. **Window Management is Powerful**
   - NSWindow gives fine-grained control
   - Window levels require careful consideration
   - Solution: Test different levels, prioritize safety

4. **SwiftData is Simple but Limited**
   - Perfect for simple CRUD
   - Query API is minimal
   - Solution: Fine for MVP, may need enhancement later

### Process Lessons

1. **Plan Review is Essential**
   - Caught multiple issues before coding
   - Saved hours of rework
   - Solution: Always review plan with fresh eyes

2. **MVP Scope is Critical**
   - Original plan was too ambitious
   - MVP focus got working app faster
   - Solution: Ship working product, iterate

3. **Documentation as You Go**
   - Writing docs while building helps clarify design
   - README, ARCHITECTURE, and now CHANGELOG
   - Solution: Document decisions immediately

---

## Future Issue Prevention

### For Next Version

1. **Unit Tests**
   - Add tests for BreakScheduler logic
   - Test quiet hours calculation
   - Test statistics aggregation

2. **UI Tests**
   - Automated overlay appearance test
   - Keyboard shortcut testing
   - Settings persistence testing

3. **Error Handling**
   - Better error messages for SwiftData failures
   - Recovery from permission denials
   - Logging system for debugging

4. **User Feedback**
   - Usage analytics (opt-in)
   - Crash reporting
   - Feature request tracking

---

## Version History

### v1.1.0 - UI Improvements (January 2026)

**New Features:**
- ✅ Custom break interval input (any duration in minutes)
- ✅ 1-minute preset for quick testing
- ✅ 30-second countdown before "I Moved!" is clickable
- ✅ Break interval changes apply immediately (timer resets)
- ✅ Settings opens in separate floating window (not modal sheet)
- ✅ Sidebar navigation in Settings (cleaner layout)

**UI/UX Fixes:**
- ✅ Menu popover now focuses properly (click outside to close works)
- ✅ Button click areas expanded (entire button clickable, not just text)
- ✅ Snooze button click area fixed in break overlay
- ✅ Settings sidebar text no longer truncated (width increased to 150px)
- ✅ Break overlay content positioning fixed (icon and title now visible)
- ✅ Break overlay layout improved (GeometryReader-based centering)
- ✅ Hover highlighting on menu buttons

**Technical Changes:**
- Added WindowManager utility for separate windows
- Added resetWithCurrentInterval() to BreakScheduler
- Added contentShape(Rectangle()) to all buttons for proper hit testing
- Menu popover activates app on show for proper focus handling

---

### v1.0.0 - MVP (January 2026)

**Initial Release Features:**
- ✅ Menu bar app
- ✅ Configurable break intervals
- ✅ Full-screen overlay with transparency
- ✅ Snooze functionality
- ✅ Activity suggestions
- ✅ Settings window
- ✅ Basic statistics
- ✅ Quiet hours support
- ✅ Presentation mode
- ✅ Keyboard shortcuts

**Known Issues:**
- None critical
- See "Known Limitations" above for planned features

**Build Info:**
- Target: macOS 14.0+
- Language: Swift 5.9+
- Frameworks: SwiftUI, SwiftData, AppKit
- Architecture: Universal (Apple Silicon + Intel)

---

## Issue Resolution Time

**Planning Issues**: ~30 minutes (plan review and corrections)
**Setup Issues**: ~15 minutes (Xcode project conflict resolution)
**Observable Issues**: ~10 minutes (quick fix once identified)
**Total Debug Time**: ~55 minutes

**Time to Working App**: ~2 hours (including documentation)

**Lessons**: Most time spent on planning review paid off - implementation was smooth because issues were caught early.

---

## Acknowledgments

**Issues Caught by Plan Review:**
- Screen Recording permission misconception
- Window level safety concern
- Keyboard lockout UX problem
- Persistence over-engineering
- Scope creep prevention

**Issues Caught During Build:**
- Observable/ObservableObject mixing
- Binding requirements with new macro
- Folder naming conflicts

**Thank you to:**
- Swift Evolution proposals for `@Observable` documentation
- Apple's SwiftData documentation
- Stack Overflow community for NSWindow tips

---

*Last updated: January 2026*
*Project: Moov v1.0.0 MVP*
