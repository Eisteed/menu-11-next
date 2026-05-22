# Design Spec: Plugin Removal, Weather Widget, GitHub Auto-Updates

**Date:** 2026-05-21  
**Status:** Approved  
**Scope:** Remove extensibility framework, add built-in weather widget, add GitHub update checker

---

## Overview

This work consolidates Menu 11 Next as a fully built-in feature set (no plugin extensibility), adds an optional weather widget powered by KDE's native weather service, and implements periodic GitHub release checking with manual update verification.

**User-facing changes:**
- Weather card on home page (disabled by default, opt-in via settings)
- "Check for Updates" button in settings
- Removal of plugin infrastructure (no user-visible impact; plugins were never shipped)

**Developer-facing changes:**
- Simpler codebase: no plugin registry, no external loading mechanism
- All features are direct, in-process code
- Lower maintenance surface area

---

## Part 1: Plugin System Removal

### Current State

The plugin system consists of:
- `contents/ui/code/plugins.js` — registry, contract definition, aggregation functions
- `contents/ui/MenuRepresentation.qml` — import, binding to pluginResults, pluginSections, repeaters
- `plugins/` directory — contains only README.md
- Inline `/calc` command — implemented as a plugin callable via `handleQuery()`

The system was designed to allow external plugins to contribute:
- Search providers
- UI sections on the home page
- Palette commands
- Custom query handlers

**No plugins have been shipped; the directory is empty.**

### Removal Plan

**Delete:**
1. `plugins/` directory entirely
2. `contents/ui/code/plugins.js`

**Modify `MenuRepresentation.qml`:**
- Remove: `import "code/plugins.js" as PluginSystem`
- Remove: `rootItem.pluginResults` property and binding
- Remove: `pluginSectionsRepeater` and `pluginSectionsColumn` (entire UI section)
- Remove: `pluginResultsColumn`, `pluginResultItem`, and related model/delegate code (~50 lines)
- Remove: error isolation try/catch for plugin failures

**Modify search query handler (in `main.qml` or search filter logic):**
- Move `/calc` command inline into the search handler
- Parse query for `/calc <expression>`, evaluate math directly using JavaScript's `eval()` or a safe math parser
- Return result as a search card (icon: calculator, title: expression, subtitle: result)

### Impact Analysis

- **UI:** No visible change. Search results page layout unchanged.
- **Performance:** Slight improvement (no plugin system overhead).
- **Breaking change:** None; plugins were never part of the public release.
- **Code removed:** ~130 lines total (plugins.js + references + empty directory)
- **Complexity reduced:** One less subsystem to maintain

### Files Changed

- `contents/ui/MenuRepresentation.qml` — remove ~80 lines
- `contents/ui/main.qml` or search handler — add ~15 lines for inline `/calc`
- `plugins/` — deleted
- `contents/ui/code/plugins.js` — deleted

---

## Part 2: Weather Widget

### Design

**Component:** `WeatherCard.qml`  
**Location:** Home page, between pinned apps section and "All Apps" list  
**Size:** ~60px tall, full width  
**Default state:** Hidden (disabled in settings by default)

### Data Source: KDE Weather Daemon

**Method:** D-Bus query to `org.kde.weather.WeatherEngine`  
**Trigger:** On menu open (not real-time polling)  
**Cached for:** 30 minutes (to reduce D-Bus chatter)

**Query flow:**
1. User opens menu
2. `MenuRepresentation.qml` calls `WeatherCard.updateWeather()`
3. WeatherCard queries D-Bus service for current location + conditions
4. Display: weather icon (from KDE's icon theme) + temperature + condition text
5. If service unavailable or location not configured: show "Weather unavailable — configure in System Settings"

**Data fields displayed:**
- Icon (from KDE theme, e.g., "weather-few-clouds", "weather-rain")
- Temperature (°C or °F based on system locale)
- Condition text (e.g., "Partly Cloudy", "Rainy")

### Settings Integration

**Config file:** `contents/config/main.xml`  
- Add group: `[General]`
- Add key: `showWeather` (type: bool, default: **false**)

**UI:** `ConfigGeneral.qml`  
- Add checkbox under "Display" section: "Show weather widget"
- Checkbox binds to `showWeather` config key
- Saving checkbox triggers re-evaluation of weather visibility in MenuRepresentation

**Behavior:**
- If `showWeather` is false, `WeatherCard` component is hidden (visibility: false)
- If true, card is shown and weather is fetched on menu open
- User can toggle on/off without restarting menu

### Error Handling

- **Service unavailable:** Show placeholder text, log warning (non-fatal)
- **No location configured:** Show help text directing user to System Settings
- **Network timeout:** Fallback to cached value or "unavailable" text
- **Invalid response:** Log error, show "unavailable" text

### Files Changed

- Create: `contents/ui/WeatherCard.qml` (~80 lines)
- Modify: `MenuRepresentation.qml` (add WeatherCard instantiation, visibility binding)
- Modify: `contents/config/main.xml` (add showWeather key)
- Modify: `ConfigGeneral.qml` (add checkbox, ~10 lines)

---

## Part 3: GitHub Auto-Update Mechanism

### User Interface

**Location:** `ConfigGeneral.qml` under new "About" section  
**Button:** "Check for Updates"  
**Display:** Shows current version (from `metadata.json`) vs latest from GitHub

**Manual check flow:**
1. User clicks "Check for Updates"
2. UI shows "Checking..."
3. `UpdateChecker.js` fetches `https://api.github.com/repos/Eisteed/menu-11-next/releases/latest`
4. Parse `tag_name` (e.g., "v1.4.0")
5. Compare against `metadata.json` version field
6. Show result popup:
   - If newer: "Version X.Y.Z available — [Download](link to release page)"
   - If current: "You're up to date (v1.3)"
   - If offline: "Unable to check — try again later"

### Periodic Background Checking

**Frequency:** Read from KDE System Settings (`~/.config/kderc` or KDE ConfigSkeleton API)  
- Typical default: daily
- Respects user's system update check preference

**Trigger:** On menu open, check if last check was >N hours ago (where N = system interval)

**Background behavior:**
- Fetch happens asynchronously (non-blocking)
- Result stored in `~/.config/Menu11Next/lastUpdateCheck.json`:
  ```json
  {
    "lastCheckTime": 1716345600,
    "latestVersion": "1.4.0",
    "latestUrl": "https://github.com/Eisteed/menu-11-next/releases/tag/v1.4.0",
    "updateAvailable": true
  }
  ```
- If update available, show quiet notification (optional: tray icon badge or status text in settings)

**Error handling:**
- If GitHub API unreachable: silently fail, don't block menu
- Log to `~/.config/Menu11Next/updateChecker.log`
- Manual checks always show error message; background checks fail silently

### Implementation Details

**Fetch endpoint:**
```
GET https://api.github.com/repos/Eisteed/menu-11-next/releases/latest
```
No authentication required for public repos. Returns JSON with `tag_name`, `html_url`, `created_at`, etc.

**Version comparison:**
- Extract version string from `tag_name` (e.g., "v1.4.0" → "1.4.0")
- Extract version from `metadata.json` KPlugin.Version field (e.g., "1.3")
- Compare semver: 1.4.0 > 1.3 = update available

**Config storage:**
- Location: `~/.config/Menu11Next/` (follows KDE conventions)
- File: `lastUpdateCheck.json` (timestamp + latest version info)
- File: `updateChecker.log` (errors, optional)

### Files Changed

- Create: `contents/ui/code/UpdateChecker.js` (~60 lines)
- Modify: `ConfigGeneral.qml` (add "About" section with button + status, ~40 lines)
- Modify: `contents/ui/main.qml` (initialize UpdateChecker timer on menu open, ~10 lines)
- Modify: `contents/config/main.xml` (optional: add lastUpdateCheckTime key for persistence)

---

## Integration Points

### Menu Open Flow

When user opens Menu 11 Next:
1. `main.qml` emits `onVisibleChanged` signal
2. MenuRepresentation calls:
   - `WeatherCard.updateWeather()` (if enabled)
   - `UpdateChecker.checkIfDue()` (background check, async)
3. Menu displays with weather card (if enabled) + existing features

### Configuration Persistence

Both weather toggle and update check state are persisted in KDE's config system:
- `metadata.json` — no changes (version field used only for comparison)
- `contents/config/main.xml` — define settable keys
- `contents/ui/main.qml` — bind config to properties
- `~/.config/Menu11Next/lastUpdateCheck.json` — external state file for update info

### No Breaking Changes

- Existing pinned apps, search, keyboard shortcuts, drag-reorder all unchanged
- Plugin removal affects only internal architecture
- Weather and update features are opt-in (settings-controlled)

---

## Testing Checklist

- [ ] Plugin removal: no broken references, code compiles, menu starts
- [ ] Weather widget: D-Bus query succeeds/fails gracefully, caching works, visibility toggle works
- [ ] Update checker: GitHub fetch works, version compare logic correct, manual button responsive
- [ ] Settings: toggles persist across menu restarts
- [ ] Error handling: missing D-Bus service, offline GitHub, invalid JSON all handled gracefully

---

## Scope Summary

**Deletions:** 1 file (plugins.js) + 1 directory (plugins/)  
**Additions:** 2 files (WeatherCard.qml, UpdateChecker.js) + new config keys  
**Modifications:** 4 files (MenuRepresentation.qml, ConfigGeneral.qml, main.xml, main.qml)  
**Lines of code:** ~-130 (removal) + ~180 (additions) = net +50 lines  
**Complexity:** Reduced (plugin system removed) + slightly increased (D-Bus + GitHub integration)

---

## Notes

- Weather relies on KDE's system weather daemon; no custom API keys exposed
- GitHub update checks use public GitHub API; no authentication required
- All network operations are non-blocking to avoid UI freezes
- Error states are designed to degrade gracefully (fail silent, show "unavailable")
