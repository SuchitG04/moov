# Moov Features Guide

Complete user guide for all features in Moov - your personal movement reminder app.

---

## What is Moov?

Moov is a macOS menu bar application that helps you maintain healthy movement habits while working at your computer. It reminds you to take regular breaks, suggests stretches and exercises, and tracks your break-taking patterns.

**Key Philosophy:**
- Non-intrusive but effective reminders
- Respects your workflow (snooze, pause, presentation mode)
- Keyboard-friendly for quick interactions
- No nagging - you're in control

---

## Implementation Status

This guide documents both **implemented** and **planned** features. Look for these indicators:

- ✅ **Fully Implemented** - Feature is working and tested
- 🚧 **Partial/In Progress** - Core functionality exists but incomplete
- ⚠️ **Known Limitation** - Documented feature with gaps or bugs
- ❌ **Planned** - Not yet implemented, documented for future versions

### Quick Summary: What Works Now (v1.0.0)

**✅ Working:**
- Break timer with customizable intervals
- Full-screen break overlay with 30-second countdown
- Snooze options (5/10 minutes) via keyboard (`1`, `2`) or mouse
- Quick escape with `Esc` key
- Menu bar controls (pause, resume, presentation mode)
- Settings window (break interval, quiet hours, activity toggle, sound)
- Basic statistics (today's breaks, compliance rate)
- SwiftData persistence

**⚠️ Known Limitations:**
- "I Moved!" button requires mouse click (Enter key shortcut not yet implemented)
- Cmd+Tab implicit snooze not wired up (use `Esc` instead)
- Only one hardcoded activity suggestion (no rotation yet)
- Micro-breaks have data models but no UI/timer

**❌ Coming Soon:**
- Enhanced keyboard shortcuts (Enter key)
- Multiple rotating activity suggestions
- Advanced statistics with charts
- Idle detection
- Calendar integration

---

## Core Features

### 1. Break Reminders ✅

**Status: FULLY IMPLEMENTED**

**How It Works:**
- Timer runs in the background tracking time since your last break
- When it's time, a semi-transparent overlay appears covering your entire screen
- The overlay shows how long you've been sitting and suggests an activity

**Customization:**
- Set your preferred break interval (1-60 minutes)
- Custom interval option for any duration (enter minutes manually)
- Default is 30 minutes
- Changes take effect immediately (no need to wait for current interval)

**Visual Design:**
- 80% opaque dark overlay (you can still see what you were doing)
- Clean, minimal interface with large, easy-to-read text
- Walking figure icon to reinforce movement

### 2. The Break Overlay ✅

**Status: FULLY IMPLEMENTED** (with some keyboard shortcut limitations noted below)

When a break is triggered, you'll see:

**Information Displayed:**
- "Time to move!" heading
- Time since last break (e.g., "You've been sitting for 30 min")
- Activity suggestion card (if enabled)
- Large action buttons

**Your Options:**
1. **"I Moved!" Button (Green)**
   - 30-second countdown before button becomes active
   - Shows remaining time: "I Moved! (25s)"
   - Ensures you actually take a break, not just dismiss
   - Once active: Dismisses the overlay
   - Resets the break timer
   - Logs the break as "taken" in statistics
   - ⚠️ **Note:** Currently requires mouse click (keyboard shortcut not yet implemented)

2. **"Snooze" Dropdown**
   - Click to reveal snooze options
   - Choose 5 or 10 minutes
   - Temporarily delays the break
   - Logs as "snoozed" in statistics
   - Keyboard: `1` for 5 min, `2` for 10 min

3. **Quick Escape**
   - Press `Esc` key to snooze for 5 minutes
   - Fastest way to dismiss if you're in the middle of something

**Special Behavior:**
- Non-blocking - won't lock you out
- ⚠️ **Note:** Cmd+Tab implicit snooze is planned but not yet functional - use Esc key instead

### 3. Activity Suggestions 🚧

**Status: PARTIALLY IMPLEMENTED** (toggle works, but only one hardcoded suggestion)

**What They Are:**
- Simple, quick exercises you can do at your desk
- Designed for 30 seconds to 2 minutes
- No equipment needed

**Current Suggestions:**
- Stand up and stretch with shoulder rolls, arm stretches, and deep breathing
- ⚠️ **Note:** Currently shows one hardcoded suggestion - variety coming in future versions

**Toggle On/Off:**
- Settings → Activities tab
- Uncheck "Show activity suggestions" to disable
- Overlay will still appear, just without the suggestion card

### 4. Menu Bar Interface ✅

**Status: FULLY IMPLEMENTED**

**Accessing Moov:**
- Click the walking figure icon in your menu bar
- Always visible, never intrusive

**Menu Items:**

**Status Section (Top):**
- Shows current state: Active, Paused, or Presentation Mode
- Displays time until next break when active
- Color-coded: Green (active), Orange (paused/presentation)

**Actions:**
- **Take Break Now** - Manually trigger a break reminder
  - Useful if you just returned from being away
  - Disabled if breaks are turned off

- **Pause for 1 Hour** - Temporarily stop breaks
  - Perfect for focused work sessions
  - Automatically resumes after 1 hour

- **Pause for 2 Hours** - Longer pause option
  - Good for meetings or intensive tasks

- **Pause Until Tomorrow** - Disable breaks for the rest of the day
  - Useful if you're done working for the day

- **Resume Breaks** - Manually resume if paused
  - Only appears when breaks are paused

- **Presentation Mode Toggle** - Special mode for presentations
  - Prevents breaks from interrupting you
  - Shows orange indicator in menu
  - Toggle on before presenting, off when done

- **Settings...** - Opens preferences window

- **Statistics...** - Opens your break history dashboard

- **Quit Moov** - Exit the application

### 5. Settings Window ✅

**Status: FULLY IMPLEMENTED**

Comprehensive preferences organized with sidebar navigation.

**Opening Settings:**
- Click menu bar icon → Settings...
- Opens in a separate floating window
- Can be closed by clicking the close button or pressing Esc

#### General Tab

**Break Reminders:**
- Master toggle: Enable/disable all break reminders
- When disabled, timer stops completely

**Break Interval:**
- Dropdown menu with preset durations
- Options: 1, 10, 15, 20, 25, 30, 45, 60 minutes
- "Custom..." option for any duration (enter minutes manually)
- Changes take effect immediately (timer resets to new interval)
- Most popular: 30 minutes (default)
- 1 minute option useful for testing

**Notifications:**
- "Play sound when break starts" toggle
- Currently plays system beep
- Off by default (visual reminder is often enough)

#### Schedule Tab

**Quiet Hours:**
- Prevent breaks during sleep or off-hours
- Toggle to enable/disable
- Set start time (e.g., 10:00 PM)
- Set end time (e.g., 7:00 AM)
- Supports overnight spans (e.g., 10 PM to 7 AM)
- Breaks are automatically paused during these hours

**How It Works:**
- Breaks won't trigger during quiet hours
- Timer doesn't advance during quiet hours
- Automatically resumes when quiet hours end

**Use Cases:**
- Prevent breaks if you work late occasionally
- No interruptions during early morning hours
- Customize for your personal schedule

#### Activities Tab

**Activity Suggestions:**
- Toggle to show/hide exercise suggestions
- When enabled: Overlay shows suggested stretches
- When disabled: Overlay shows only basic break message

**Benefits of Suggestions:**
- Makes breaks more actionable
- Variety in movements
- Reminds you how to stretch properly

#### About Tab

**Information:**
- App version
- Brief description
- Credits

### 6. Statistics Dashboard 🚧

**Status: BASIC VERSION IMPLEMENTED** (today's stats and compliance rate work; charts/trends planned)

Track your break-taking habits over time.

**Today's Summary:**
- Breaks Taken (green card with checkmark)
- Breaks Snoozed (orange card with clock)
- Total Breaks (blue card with list)

**All Time Stats:**
- Total Breaks count
- Compliance Rate percentage
  - Formula: (Breaks Taken / Total Breaks) × 100
  - Example: 80% means you took 8 out of 10 breaks

**Empty State:**
- If no data yet, shows friendly message
- "Take some breaks to see your statistics here"
- Chart icon illustration

**Future Enhancements (❌ Not Yet Implemented):**
- Weekly charts
- Streak tracking
- Break patterns by time of day
- CSV export for data nerds
- Historical trend analysis

---

## Keyboard Shortcuts

### During a Break Overlay

| Key | Action | Status |
|-----|--------|--------|
| `1` | Snooze for 5 minutes | ✅ Working |
| `2` | Snooze for 10 minutes | ✅ Working |
| `Esc` | Quick snooze (5 minutes) - escape hatch | ✅ Working |

**Note:** The "I Moved!" button is disabled for the first 30 seconds to encourage actually taking a break. Currently requires mouse click to activate.

**Why Keyboard Shortcuts Matter:**
- Faster than reaching for mouse (for snooze actions)
- Keep hands on keyboard while working
- Muscle memory develops quickly
- Accessibility-friendly

### Global Shortcuts

⚠️ **Not Yet Implemented - Planned for future versions:**
- `Enter` key to dismiss "I Moved!" button
- `Cmd+Shift+B` - Trigger break manually
- Custom hotkey configuration

---

## Workflow Examples

### Typical Work Session

```
9:00 AM  - Start Moov
9:30 AM  - Break reminder → Take 2 minute stretch
10:00 AM - Resume work
10:30 AM - Break reminder → Snooze 5 min (finishing a task)
10:35 AM - Break reminder → Take break
11:05 AM - Resume work
11:35 AM - Break reminder → Take break
12:00 PM - Lunch (Pause Until Tomorrow if done for the day)
```

### Meeting Day

```
9:00 AM  - Start work
9:30 AM  - Break reminder → Take break
9:50 AM  - Meeting starting soon → Enable Presentation Mode
10:00 AM - Meeting starts (no break interruptions)
11:00 AM - Meeting ends → Disable Presentation Mode
11:30 AM - Break reminder → Take break (back to normal)
```

### Deep Focus Session

```
2:00 PM  - About to start coding
2:00 PM  - Click menu → "Pause for 2 Hours"
2:30 PM  - (No break interruption)
3:00 PM  - (No break interruption)
3:30 PM  - (No break interruption)
4:00 PM  - Pause expires, breaks resume
4:30 PM  - Break reminder → Take break
```

---

## Understanding Break Actions

### "Taken" vs "Snoozed" vs "Dismissed"

**Taken (Good ✅):**
- You clicked "I Moved!" button (after 30s countdown)
- Indicates you actually took a break
- Best for your health
- Contributes to compliance rate

**Snoozed (Neutral 😴):**
- You clicked a snooze option or pressed 1/2
- Break will appear again after snooze duration
- Useful when you're mid-task
- Not counted as "taken" in stats

**Dismissed (Quick Escape):**
- Press `Esc` key to quickly snooze for 5 minutes
- Useful when you're mid-task and can't break immediately
- Logged as "dismissed" in statistics

---

## Tips & Best Practices

### For Maximum Benefit

1. **Start with Longer Intervals**
   - Try 30 minutes first (default)
   - Adjust down if you need more frequent breaks
   - Adjust up if 30 min feels too frequent

2. **Actually Move**
   - Don't just click "I Moved!" without moving
   - Stand up, even if briefly
   - Follow the activity suggestions
   - Walk to get water

3. **Use Snooze Wisely**
   - It's there for a reason - use it!
   - Don't feel guilty about snoozing
   - But try to take the break when it re-appears

4. **Respect Quiet Hours**
   - Set them for your sleep schedule
   - Prevents late-night interruptions if working late

5. **Presentation Mode is Your Friend**
   - Always enable before meetings/demos
   - Prevents embarrassing interruptions
   - Remember to disable after!

### Productivity Integration

1. **Combine with Pomodoro Technique**
   - Set break interval to 25 minutes
   - Each break = end of a pomodoro
   - Take 5 min break (short pomodoro break)
   - Every 4th break, take longer (15 min)

2. **Sync with Calendar (Manual)**
   - Check your schedule in morning
   - Pause before long meetings
   - Resume after meeting blocks

3. **Habit Stacking**
   - Break = time to refill water
   - Break = time to check phone messages
   - Break = quick tidy of desk

---

## What Moov Doesn't Do (Yet)

### Known Limitations & Missing Features

**❌ No Automatic Idle Detection:**
- Won't detect if you're away from computer
- Future feature: Reset timer if idle > 5 minutes
- Workaround: Use "Take Break Now" when you return

**❌ No Calendar Integration:**
- Doesn't know about your meetings
- Won't auto-enable presentation mode
- Workaround: Manual presentation mode toggle

**❌ No DND/Focus Mode Detection:**
- Doesn't respect macOS Focus modes automatically
- Workaround: Use Pause or Presentation Mode

**🚧 Statistics are Basic:**
- No charts/graphs yet
- No streak tracking
- No CSV export
- Coming in future versions

**🚧 Single Break Type:**
- Only one timer/interval currently active
- Micro-breaks are partially implemented (data models ready) but not yet functional in UI
- Workaround: Manually trigger breaks as needed

---

## Troubleshooting

### Break Overlay Not Appearing

**Check these:**
1. Is Moov enabled? (Menu bar → check if grayed out)
2. Are you in Quiet Hours? (Check settings)
3. Is Presentation Mode on? (Menu shows orange status)
4. Are breaks paused? (Menu shows "Paused until...")

**Still not working?**
- Quit Moov completely
- Re-launch
- Set interval to 1 minute to test
- Check Xcode console for error messages

### Overlay Appears But Won't Dismiss

**Try these:**
1. Press `Esc` key (always works)
2. Click "I Moved!" button directly
3. `Cmd+Tab` to another app (implicit dismiss)
4. Worst case: `Cmd+Q` to quit Moov

### Settings Not Persisting

**If changes don't save:**
1. Settings save automatically when changed
2. Stored in UserDefaults
3. Check Console.app for permission errors
4. Try: Quit Moov → Relaunch

### Statistics Not Recording

**If breaks aren't being logged:**
1. Check that SwiftData is configured (see Xcode console)
2. ModelContext must be set up properly
3. Look for error messages in console
4. May need to delete and rebuild app

---

## Privacy & Data

### What Data is Stored

**Locally on Your Mac:**
- Break interval preference
- Quiet hours settings
- Feature toggles (sounds, suggestions)
- Break session history (last 90 days)
  - Timestamp
  - Action taken (taken/snoozed)
  - Snooze duration (if applicable)

**NOT Stored:**
- What apps you were using
- Screen contents
- Keyboard/mouse activity beyond idle detection
- Any personal information

**No Cloud Sync:**
- All data stays on your Mac
- No iCloud sync (yet)
- No external servers
- Completely private

### Permissions

**Required: None for MVP**
- No special permissions needed for basic functionality
- App works out of the box

**Optional (Future):**
- Accessibility permission (for idle detection only)
- Calendar access (for meeting integration)

---

## Advanced Usage

### For Power Users

**Testing Break Logic:**
1. Set interval to 1 minute
2. Test all features rapidly
3. Set back to normal interval

**Quick Disable/Enable:**
- Settings → General → Toggle "Enable break reminders"
- Or just quit the app

**Multiple Interval Strategies:**
- Morning: 20 minutes (fresh, need frequent breaks)
- Afternoon: 45 minutes (in flow state)
- Late night: Disable or use Quiet Hours

**Statistics Analysis:**
- Track compliance over time
- Notice patterns (which times you snooze more)
- Adjust intervals based on data
- Future: Export to CSV for deeper analysis

---

## Future Feature Wishlist

**❌ ALL FEATURES BELOW ARE PLANNED BUT NOT YET IMPLEMENTED**

Features planned for future versions:

### V2 - Smart Features (❌ Not Implemented)
- ⏳ Idle detection (reset timer when you're away)
- 🎯 More activity suggestions with categories and rotation
- 📊 Enhanced statistics with charts and graphs
- 🔥 Streak tracking and gamification
- 📈 Compliance trends over time
- ⌨️ Enter key shortcut for "I Moved!" button
- 🖱️ Cmd+Tab implicit snooze handling

### V3 - Integration (❌ Not Implemented)
- 📅 Calendar integration (auto-pause during meetings)
- 🍎 Apple Health integration (log standing time)
- ⌚ Apple Watch app (trigger breaks from watch)
- ☁️ iCloud sync (cross-device stats)

### V4 - Customization (❌ Not Implemented)
- 🎨 Custom themes and colors
- 🏃 Custom activity editor
- ⏱️ Pomodoro mode (25/5 cycles)
- 🔄 Micro-breaks functionality (models exist, UI/timer needed)
- 🎵 Custom sounds
- ⌨️ Global keyboard shortcuts
- 🖼️ Custom app icon

### V5 - Intelligence (❌ Not Implemented)
- 🤖 ML-based optimal break times
- 📊 Pattern recognition
- 💡 Smart suggestions based on usage
- 🔔 Adaptive reminders

---

## Support & Feedback

### Getting Help

**If you encounter issues:**
1. Check this documentation
2. Read ARCHITECTURE.md for technical details
3. Check CHANGELOG.md for known issues
4. Submit GitHub issue (if this becomes public)

### Feature Requests

Currently a personal project, but planned features:
- See "Future Feature Wishlist" above
- Most requested features will be prioritized

### Contributing

This is a personal learning project for now. Future:
- May open source
- Contributions welcome (guidelines TBD)

---

## Conclusion

Moov is designed to be your friendly companion for maintaining healthy movement habits. It's not a drill sergeant - it's a gentle nudge to take care of yourself while working.

**Remember:**
- Regular movement improves focus and productivity
- Taking breaks is not a distraction - it's essential
- Listen to your body
- Moov is here to help, not hinder

**Happy moving! 🚶‍♂️**

---

*Last updated: January 2026*
*Version: 1.0.0 (MVP)*
