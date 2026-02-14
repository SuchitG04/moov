# Moov - Movement Break Reminder

A simple macOS menu bar app that reminds you to move and stretch regularly.

## Prerequisites

You need **Xcode 15+** installed from the Mac App Store.

## Setup Instructions

Since you don't have Xcode installed yet (or it's not configured), here's how to get Moov running:

### Step 1: Install Xcode

1. Open the **Mac App Store**
2. Search for "Xcode"
3. Click "Get" or "Install" (it's free, but ~15GB download)
4. Wait for it to download and install (this can take a while)
5. Open Xcode once to accept the license agreement

### Step 2: Create the Xcode Project

1. Open **Xcode**
2. Click "Create New Project"
3. Select **macOS** → **App** → Click "Next"
4. Fill in:
   - Product Name: **Moov**
   - Team: (leave as is or select your Apple ID if you have one)
   - Organization Identifier: **com.suchit**
   - Bundle Identifier: (will auto-fill as `com.suchit.Moov`)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests"
5. Click "Next"
6. Save location: Select `/Users/suchitg/gen/moov` (this folder)
7. Uncheck "Create Git repository" (optional)
8. Click "Create"

### Step 3: Configure the Project

1. In Xcode, in the left sidebar (Navigator), you'll see a `Moov` folder with some default files
2. **Delete these default files:**
   - Right-click `ContentView.swift` → Delete → Move to Trash
   - Right-click `MoovApp.swift` (the default one) → Delete → Move to Trash

3. **Add our files:**
   - Right-click the `Moov` folder in Xcode
   - Select "Add Files to Moov..."
   - Navigate to `/Users/suchitg/gen/moov/Moov`
   - Select ALL the folders: `Models`, `Views`, `Controllers`, `Services`, `Utilities`, and `MoovApp.swift`
   - Make sure "Copy items if needed" is **UNCHECKED**
   - Make sure "Create groups" is **SELECTED**
   - Click "Add"

4. **Configure project settings:**
   - Click on the blue "Moov" project icon at the very top of the left sidebar
   - Under "Targets" select "Moov"
   - Go to the "General" tab
   - Set "Minimum Deployments" to **macOS 14.0**
   - Scroll down to "Frameworks, Libraries, and Embedded Content"
   - This should be empty - we don't need any external frameworks

5. **Add Info.plist:**
   - In the project settings (same place as above)
   - Go to the "Info" tab
   - You should see a list of properties
   - Right-click in the list → "Add Row"
   - Add: "Application is agent (UIElement)" → Type: Boolean → Value: YES
   - This makes the app a menu bar only app (no dock icon)

6. **Enable SwiftData:**
   - Click on "Moov" in the left sidebar (the blue project icon)
   - Select the "Moov" target
   - Go to "Build Phases" tab
   - Expand "Link Binary With Libraries"
   - Click the "+" button
   - Search for "SwiftData"
   - Add "SwiftData.framework"

### Step 4: Build and Run

1. At the top of Xcode, make sure "My Mac" is selected in the device dropdown (next to the "Moov" scheme)
2. Click the **Play button** (▶) or press **Cmd+R**
3. Xcode will compile the app (first time takes a minute)
4. If successful, you should see a walking figure icon (🚶) appear in your menu bar!
5. Click it to see the menu

### Step 5: Test It!

1. Click the menu bar icon
2. Click "Settings..."
3. Change the break interval to **1 minute** (for testing)
4. Close settings
5. Wait 1 minute
6. A semi-transparent overlay should appear prompting you to take a break!
7. Try the buttons:
   - "I Moved!" - dismisses and resets timer
   - "Snooze" - shows snooze options
   - Press "Esc" key - snoozes for 5 minutes
   - Try "Space" or "Enter" - also dismisses

## Troubleshooting

### "Cannot find 'NSSound' in scope"
- Make sure you're targeting macOS 14.0+ in project settings

### "No such module 'SwiftData'"
- Make sure SwiftData is linked (Step 3.6 above)
- Make sure Deployment Target is macOS 14.0+

### Menu bar icon doesn't appear
- Make sure `LSUIElement` is set to YES in Info.plist (or "Application is agent" in the Info tab)
- Quit and restart the app

### App crashes on launch
- Check the console output in Xcode for error messages
- Common issue: Model context not set up - make sure SwiftData is properly linked

## Build DMG for GitHub Releases

Use the helper script to avoid missing the `Applications` shortcut in the DMG:

```bash
./scripts/release-dmg.sh
```

This script:
- builds `Moov.app` in Release mode
- stages both `Moov.app` and `/Applications` symlink
- creates `Moov.dmg` in the repo root

Optional custom DMG filename:

```bash
./scripts/release-dmg.sh "Moov-v1.0.2"
```

This creates `Moov-v1.0.2.dmg`.

## Features

- ✅ Menu bar app (no dock icon)
- ✅ Configurable break intervals
- ✅ Full-screen semi-transparent overlay
- ✅ Snooze functionality (5/10 min)
- ✅ Activity suggestions
- ✅ Quiet hours support
- ✅ Presentation mode toggle
- ✅ Basic statistics tracking
- ✅ Keyboard shortcuts

## Usage

### Menu Bar
Click the walking figure icon in your menu bar to access:
- **Take Break Now** - Manually trigger a break
- **Pause for X hours** - Temporarily disable breaks
- **Presentation Mode** - Toggle to prevent breaks during presentations
- **Settings** - Configure intervals, quiet hours, etc.
- **Statistics** - View your break history

### During a Break
- **Space/Enter** - "I moved!" (dismiss and reset)
- **1** - Snooze 5 minutes
- **2** - Snooze 10 minutes
- **Esc** - Snooze 5 minutes (quick escape)

### Settings
- **General**: Break interval, sound notifications
- **Schedule**: Quiet hours (no breaks during sleep)
- **Activities**: Toggle activity suggestions
- **About**: App info

## What's Next?

This is the MVP! Future enhancements could include:
- Idle detection (detect when you're away and reset timer)
- More activity suggestions with categories
- Advanced statistics and streak tracking
- Gamification (achievements, milestones)
- Calendar integration
- Apple Health integration

Enjoy moving more! 🚶
