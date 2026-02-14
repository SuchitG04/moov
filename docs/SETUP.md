# Moov Setup and Build Guide

## Prerequisites

- macOS with Xcode 15+

## Setup in Xcode

If Xcode is not installed:
1. Open the Mac App Store
2. Install Xcode
3. Open Xcode once and accept the license

Create/open the project:
1. Open `Moov.xcodeproj`
2. Select target `Moov`
3. Verify deployment target is macOS 14.0+
4. Verify `Application is agent (UIElement)` is enabled (`LSUIElement = YES`)
5. Verify `SwiftData.framework` is linked in Build Phases

## Build and Run

In Xcode:
1. Select `My Mac` as destination
2. Press `Cmd+R`
3. Confirm the Moov icon appears in the menu bar

## Quick Functional Test

1. Open menu bar icon -> `Settings...`
2. Set break interval to `1 minute`
3. Wait one minute
4. Confirm overlay appears
5. Validate actions:
   - `I Moved!` dismisses and resets timer
   - `Snooze` shows options
   - `Esc` snoozes for 5 minutes

## Build DMG for GitHub Releases

Use the helper script to avoid missing the `Applications` shortcut:

```bash
./scripts/release-dmg.sh
```

What it does:
- builds `Moov.app` in Release mode
- stages `Moov.app` plus `/Applications` symlink
- creates `Moov.dmg` in repo root

Custom DMG filename:

```bash
./scripts/release-dmg.sh "Moov-v1.0.2"
```

This creates `Moov-v1.0.2.dmg`.

## Troubleshooting

### `Cannot find 'NSSound' in scope`
- Verify deployment target is macOS 14.0+

### `No such module 'SwiftData'`
- Verify `SwiftData.framework` is linked
- Verify deployment target is macOS 14.0+

### Menu bar icon does not appear
- Verify `LSUIElement = YES` in target Info
- Quit and relaunch the app

### App crashes on launch
- Check Xcode console logs
- Verify SwiftData model context initialization is successful
