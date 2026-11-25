# Plugin Removal, Weather Widget & GitHub Updates Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the unused plugin system, add a built-in weather widget powered by KDE's weather daemon, and implement GitHub release checking for updates.

**Architecture:** Plugin system is completely removed (no extensibility). Weather and update features are built directly into the menu using KDE native services (D-Bus weather daemon, public GitHub API). Both features are optional and controlled via settings.

**Tech Stack:** QML, D-Bus (for weather), HTTP fetch (for GitHub), KDE ConfigSkeleton (for persistence)

---

## Task 1: Delete plugins directory and plugins.js

**Files:**
- Delete: `plugins/`
- Delete: `contents/ui/code/plugins.js`

- [ ] **Step 1: Verify plugins.js content before deletion**

```bash
cat contents/ui/code/plugins.js | head -20
```

Expected output: Shows pragma library and plugin registry code.

- [ ] **Step 2: Delete plugins.js**

```bash
rm contents/ui/code/plugins.js
```

- [ ] **Step 3: Delete plugins directory**

```bash
rm -r plugins/
```

- [ ] **Step 4: Verify deletions**

```bash
git status
```

Expected output: `deleted: plugins/README.md` and `deleted: contents/ui/code/plugins.js`

- [ ] **Step 5: Stage for commit (do not commit yet)**

```bash
git add plugins/ contents/ui/code/plugins.js
```

(Will commit all changes together at the end)

---

## Task 2: Remove plugin imports and references from MenuRepresentation.qml

**Files:**
- Modify: `contents/ui/MenuRepresentation.qml`

- [ ] **Step 1: Find the PluginSystem import line**

```bash
grep -n "import.*plugins.js" contents/ui/MenuRepresentation.qml
```

Expected: Line number showing `import "code/plugins.js" as PluginSystem`

- [ ] **Step 2: Remove the import statement**

From `contents/ui/MenuRepresentation.qml`, delete this line:
```qml
import "code/plugins.js" as PluginSystem
```

- [ ] **Step 3: Find and remove plugin-related properties**

```bash
grep -n "pluginResults\|pluginSections" contents/ui/MenuRepresentation.qml | head -10
```

This will show lines with plugin references. Remove:
- `property var pluginResults: []`
- `pluginResults = (query && query.length >= 2) ? ...` binding
- Any other `pluginResults` or `pluginSections` property definitions

- [ ] **Step 4: Find and remove pluginSectionsColumn UI**

```bash
grep -n "pluginSectionsColumn\|pluginSectionsRepeater" contents/ui/MenuRepresentation.qml
```

From `contents/ui/MenuRepresentation.qml`, find and delete the entire section:
```qml
ColumnLayout {
    id: pluginSectionsColumn
    visible: pluginSectionsRepeater.count > 0
    // ... entire block including Repeater
}
```

This is approximately 20-30 lines. Look for the opening `ColumnLayout { id: pluginSectionsColumn` and close after the closing `}`.

- [ ] **Step 5: Find and remove pluginResultsColumn UI**

```bash
grep -n "pluginResultsColumn\|pluginResultItem" contents/ui/MenuRepresentation.qml
```

From `contents/ui/MenuRepresentation.qml`, find and delete the entire section:
```qml
ColumnLayout {
    id: pluginResultsColumn
    visible: rootItem.query.text && rootItem.query.text.length >= 2
             && rootItem.pluginResults.length > 0
    model: rootItem.pluginResults
    // ... entire block with delegate
}
```

This is approximately 40-50 lines. Look for the opening and delete through the closing `}`.

- [ ] **Step 6: Verify no plugin references remain**

```bash
grep -i "plugin" contents/ui/MenuRepresentation.qml
```

Expected: No output (clean removal).

- [ ] **Step 7: Stage for commit (do not commit yet)**

```bash
git add contents/ui/MenuRepresentation.qml
```

(Will commit all changes together at the end)

---

## Task 3: Move /calc command inline into search handler

**Files:**
- Modify: `contents/ui/main.qml` (search filter/handler logic)

- [ ] **Step 1: Find the search query handler in main.qml**

```bash
grep -n "onTextChanged\|handleQuery\|/calc" contents/ui/main.qml | head -10
```

Look for where search query is processed. This is typically in the search input component's `onTextChanged` handler or a dedicated search filter function.

- [ ] **Step 2: Locate the existing /calc handling (if any) or create new handler**

Find the search results filtering logic. If `/calc` handling already exists inline, skip to Step 5. If not, find the `onTextChanged` handler for the search input field.

- [ ] **Step 3: Add /calc command handler**

In the search filter/handler logic, add this code to detect and handle `/calc` queries:

```qml
// Handle /calc command
if (query.startsWith("/calc ")) {
    var expression = query.substring(6).trim(); // Remove "/calc "
    try {
        var result = Function('"use strict"; return (' + expression + ')')();
        return {
            icon: "accessories-calculator",
            title: expression,
            subtitle: String(result),
            action: function() {
                // Copy result to clipboard or display
                console.log("Calculation: " + expression + " = " + result);
            }
        };
    } catch(e) {
        return {
            icon: "accessories-calculator",
            title: "/calc " + expression,
            subtitle: "Invalid expression: " + e.message,
            action: function() { }
        };
    }
}
```

- [ ] **Step 4: Test /calc in search**

Run the menu and open the search. Type `/calc 2+2` and verify:
- Result card appears with "2+2" as title
- "4" as subtitle
- Calculator icon shown

Type `/calc bad expression` and verify error message appears.

- [ ] **Step 5: Stage for commit (do not commit yet)**

```bash
git add contents/ui/main.qml
```

(Will commit all changes together at the end)

---

## Task 4: Create WeatherCard.qml component

**Files:**
- Create: `contents/ui/WeatherCard.qml`

- [ ] **Step 1: Create the WeatherCard.qml file**

```bash
touch contents/ui/WeatherCard.qml
```

- [ ] **Step 2: Write WeatherCard.qml**

Create file `contents/ui/WeatherCard.qml` with this content:

```qml
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Rectangle {
    id: weatherCard
    
    visible: plasmoid.configuration.showWeather
    height: visible ? 60 : 0
    width: parent.width
    color: PlasmaCore.ColorScope.backgroundColor
    radius: 4
    border.color: PlasmaCore.ColorScope.textColor
    border.width: 1
    
    property string temperature: "--°C"
    property string condition: "Unavailable"
    property string weatherIcon: "weather-clear"
    property var weatherCache: null
    property var lastUpdateTime: 0
    property int cacheValidityMs: 30 * 60 * 1000 // 30 minutes
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12
        
        PlasmaComponents.Icon {
            id: weatherIconItem
            source: weatherCard.weatherIcon
            implicitWidth: 40
            implicitHeight: 40
            colorGroup: PlasmaComponents.ColorScope.colorGroup
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            PlasmaComponents.Label {
                text: weatherCard.temperature
                font.pixelSize: 18
                font.bold: true
            }
            
            PlasmaComponents.Label {
                text: weatherCard.condition
                font.pixelSize: 12
                opacity: 0.7
            }
        }
    }
    
    function updateWeather() {
        var now = Date.now();
        
        // Check cache validity
        if (weatherCache !== null && (now - lastUpdateTime) < cacheValidityMs) {
            applyWeatherData(weatherCache);
            return;
        }
        
        // Query KDE weather daemon via D-Bus
        var process = Qt.createQmlObject(
            "import QtCore; Process { }",
            weatherCard
        );
        
        // Use qdbus to query weather service
        process.program = "qdbus";
        process.arguments = [
            "org.kde.weather",
            "/weather",
            "org.kde.weather.WeatherProvider.currentWeather"
        ];
        
        process.finished.connect(function() {
            var output = process.readAllStandardOutput().toString();
            var error = process.readAllStandardError().toString();
            
            if (error || !output) {
                weatherCard.condition = "Weather unavailable — check System Settings";
                weatherCard.temperature = "";
                weatherCard.weatherIcon = "dialog-warning";
                return;
            }
            
            try {
                var data = JSON.parse(output);
                weatherCache = data;
                lastUpdateTime = now;
                applyWeatherData(data);
            } catch(e) {
                weatherCard.condition = "Error parsing weather data";
                weatherCard.temperature = "";
                weatherCard.weatherIcon = "dialog-error";
                console.error("Weather parsing error:", e);
            }
        });
        
        process.errorOccurred.connect(function() {
            weatherCard.condition = "Weather service unavailable";
            weatherCard.temperature = "";
            weatherCard.weatherIcon = "dialog-warning";
            console.warn("D-Bus query failed:", process.errorString());
        });
        
        try {
            process.start();
        } catch(e) {
            weatherCard.condition = "Cannot connect to weather service";
            weatherCard.temperature = "";
            weatherCard.weatherIcon = "dialog-error";
            console.error("Process start error:", e);
        }
    }
    
    function applyWeatherData(data) {
        if (data.temperature !== undefined) {
            weatherCard.temperature = Math.round(data.temperature) + "°C";
        }
        if (data.condition !== undefined) {
            weatherCard.condition = data.condition;
        }
        if (data.icon !== undefined) {
            weatherCard.weatherIcon = data.icon;
        }
    }
    
    Component.onCompleted: {
        updateWeather();
    }
}
```

- [ ] **Step 3: Verify syntax**

```bash
qmlformat -i contents/ui/WeatherCard.qml 2>&1 | head -20
```

Expected: No syntax errors (or just formatting adjustments).

- [ ] **Step 4: Stage for commit (do not commit yet)**

```bash
git add contents/ui/WeatherCard.qml
```

(Will commit all changes together at the end)

---

## Task 5: Add showWeather config key to main.xml

**Files:**
- Modify: `contents/config/main.xml`

- [ ] **Step 1: Check current main.xml structure**

```bash
head -30 contents/config/main.xml
```

Expected output shows existing config groups and keys structure.

- [ ] **Step 2: Add showWeather key**

In `contents/config/main.xml`, find the `<group>` section (usually named something like "General" or "Display"). Add this key inside it:

```xml
<entry name="showWeather" type="Bool">
    <default>false</default>
    <label>Show weather widget on home page</label>
</entry>
```

If there is no existing group, add a complete group section:

```xml
<group name="Display">
    <entry name="showWeather" type="Bool">
        <default>false</default>
        <label>Show weather widget on home page</label>
    </entry>
</group>
```

- [ ] **Step 3: Verify XML syntax**

```bash
xmllint contents/config/main.xml > /dev/null && echo "Valid XML"
```

Expected: "Valid XML" output.

- [ ] **Step 4: Stage for commit (do not commit yet)**

```bash
git add contents/config/main.xml
```

(Will commit all changes together at the end)

---

## Task 6: Modify MenuRepresentation.qml to include WeatherCard

**Files:**
- Modify: `contents/ui/MenuRepresentation.qml`

- [ ] **Step 1: Add WeatherCard import at the top**

Add this import statement with other imports in `MenuRepresentation.qml`:

```qml
import "ui/" as CustomUI
```

(or if imports are organized differently, adjust path accordingly)

- [ ] **Step 2: Find the home page layout section**

```bash
grep -n "Column.*Layout\|home\|homeItems" contents/ui/MenuRepresentation.qml | head -10
```

Look for the main content ColumnLayout that contains pinned apps and other home page items.

- [ ] **Step 3: Add WeatherCard component**

Find the main ColumnLayout for home page content. At the beginning (after pinned apps section), add:

```qml
CustomUI.WeatherCard {
    id: weatherCard
    Layout.fillWidth: true
}
```

Or if the import structure differs, use the appropriate path to WeatherCard.

- [ ] **Step 4: Hook up weather update on menu visibility**

Find the `onVisibleChanged` handler in MenuRepresentation (or create one). Add:

```qml
onVisibleChanged: {
    if (visible) {
        weatherCard.updateWeather();
        // ... other existing logic
    }
}
```

- [ ] **Step 5: Test weather widget**

Run the menu and verify:
- Weather card is hidden by default (setting is false)
- No errors in console
- Menu opens without lag

- [ ] **Step 6: Stage for commit (do not commit yet)**

```bash
git add contents/ui/MenuRepresentation.qml
```

(Will commit all changes together at the end)

---

## Task 7: Add weather toggle to ConfigGeneral.qml

**Files:**
- Modify: `contents/ui/ConfigGeneral.qml`

- [ ] **Step 1: Find the ConfigGeneral.qml structure**

```bash
head -50 contents/ui/ConfigGeneral.qml
```

Expected: Shows existing config UI structure with CheckBoxes or other controls.

- [ ] **Step 2: Find where to add weather toggle**

Look for a section labeled "Display", "Appearance", or similar. If none exists, add a new section.

- [ ] **Step 3: Add weather checkbox**

In the appropriate section, add this control:

```qml
CheckBox {
    id: showWeatherCheckbox
    text: i18n("Show weather widget")
    checked: plasmoid.configuration.showWeather
    onCheckedChanged: {
        plasmoid.configuration.showWeather = checked;
    }
}
```

- [ ] **Step 4: Test the toggle**

Run the menu settings:
- Open Settings (right-click menu → Configure)
- Look for "Show weather widget" checkbox
- Toggle it on/off
- Save and restart menu
- Verify weather card appears/disappears based on setting

- [ ] **Step 5: Stage for commit (do not commit yet)**

```bash
git add contents/ui/ConfigGeneral.qml
```

(Will commit all changes together at the end)

---

## Task 8: Create UpdateChecker.js

**Files:**
- Create: `contents/ui/code/UpdateChecker.js`

- [ ] **Step 1: Create the UpdateChecker.js file**

```bash
touch contents/ui/code/UpdateChecker.js
```

- [ ] **Step 2: Write UpdateChecker.js**

Create file `contents/ui/code/UpdateChecker.js` with this content:

```javascript
.pragma library

Qt.include("core.js");

var updateCheckUrl = "https://api.github.com/repos/Eisteed/menu-11-next/releases/latest";
var configDir = Qt.binding(function() {
    return Qt.locale().system().name + "/.config/Menu11Next";
});
var lastCheckFile = "lastUpdateCheck.json";

function parseVersion(versionString) {
    // Remove 'v' prefix if present (v1.3.0 -> 1.3.0)
    var version = versionString.replace(/^v/, '');
    var parts = version.split('.');
    return {
        major: parseInt(parts[0]) || 0,
        minor: parseInt(parts[1]) || 0,
        patch: parseInt(parts[2]) || 0,
        full: version
    };
}

function compareVersions(current, latest) {
    var cur = parseVersion(current);
    var lat = parseVersion(latest);
    
    if (lat.major > cur.major) return 1;     // newer
    if (lat.major < cur.major) return -1;    // older
    if (lat.minor > cur.minor) return 1;
    if (lat.minor < cur.minor) return -1;
    if (lat.patch > cur.patch) return 1;
    if (lat.patch < cur.patch) return -1;
    return 0; // equal
}

function fetchLatestRelease(callback) {
    var xhr = new XMLHttpRequest();
    xhr.timeout = 10000; // 10 second timeout
    
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var result = {
                        success: true,
                        version: data.tag_name,
                        url: data.html_url,
                        releaseNotes: data.body || "",
                        publishedAt: data.published_at
                    };
                    callback(result);
                } catch(e) {
                    callback({
                        success: false,
                        error: "Failed to parse response: " + e.message
                    });
                }
            } else {
                callback({
                    success: false,
                    error: "HTTP " + xhr.status + ": " + xhr.statusText
                });
            }
        }
    };
    
    xhr.onerror = function() {
        callback({
            success: false,
            error: "Network error: " + xhr.statusText
        });
    };
    
    xhr.ontimeout = function() {
        callback({
            success: false,
            error: "Request timeout"
        });
    };
    
    try {
        xhr.open("GET", updateCheckUrl, true);
        xhr.send();
    } catch(e) {
        callback({
            success: false,
            error: "Failed to initiate request: " + e.message
        });
    }
}

function checkForUpdates(currentVersion, callback) {
    fetchLatestRelease(function(release) {
        if (!release.success) {
            callback({
                success: false,
                error: release.error
            });
            return;
        }
        
        var comparison = compareVersions(currentVersion, release.version);
        var result = {
            success: true,
            currentVersion: currentVersion,
            latestVersion: release.version,
            releaseUrl: release.url,
            releaseNotes: release.releaseNotes,
            updateAvailable: comparison < 0,
            error: null
        };
        
        callback(result);
    });
}

function formatUpdateStatus(checkResult, currentVersion) {
    if (!checkResult.success) {
        return {
            title: "Update Check Failed",
            subtitle: checkResult.error
        };
    }
    
    if (checkResult.updateAvailable) {
        return {
            title: "Update Available: " + checkResult.latestVersion,
            subtitle: "Current: " + currentVersion,
            url: checkResult.releaseUrl
        };
    } else {
        return {
            title: "You're Up to Date",
            subtitle: "Version " + currentVersion
        };
    }
}
```

- [ ] **Step 3: Verify syntax**

```bash
node -c contents/ui/code/UpdateChecker.js 2>&1
```

Or manually check for obvious syntax errors by viewing:

```bash
head -20 contents/ui/code/UpdateChecker.js
```

- [ ] **Step 4: Stage for commit (do not commit yet)**

```bash
git add contents/ui/code/UpdateChecker.js
```

(Will commit all changes together at the end)

---

## Task 9: Add update check button to ConfigGeneral.qml

**Files:**
- Modify: `contents/ui/ConfigGeneral.qml`

- [ ] **Step 1: Add import for UpdateChecker**

At the top of `ConfigGeneral.qml`, add:

```qml
import "ui/code/UpdateChecker.js" as UpdateChecker
```

(Adjust path if different)

- [ ] **Step 2: Add About section with update button**

Find the end of ConfigGeneral.qml and add a new section:

```qml
ColumnLayout {
    Layout.fillWidth: true
    
    Text {
        text: "About"
        font.pixelSize: 14
        font.bold: true
        Layout.topMargin: 16
    }
    
    RowLayout {
        Layout.fillWidth: true
        
        Text {
            text: "Version: " + plasmoid.configuration.version || "1.3"
            Layout.fillWidth: true
        }
        
        Button {
            id: checkUpdatesBtn
            text: checkUpdatesBtn.checking ? "Checking..." : "Check for Updates"
            property bool checking: false
            
            onClicked: {
                checkUpdatesBtn.checking = true;
                UpdateChecker.checkForUpdates("1.3", function(result) {
                    checkUpdatesBtn.checking = false;
                    
                    var status = UpdateChecker.formatUpdateStatus(result, "1.3");
                    if (result.updateAvailable) {
                        showUpdateDialog(status.title, status.subtitle, result.releaseUrl);
                    } else {
                        showUpdateDialog(status.title, status.subtitle, "");
                    }
                });
            }
        }
    }
}
```

- [ ] **Step 3: Add helper function for update dialog**

At the end of ConfigGeneral.qml, add:

```qml
function showUpdateDialog(title, subtitle, url) {
    // Create and show a message dialog
    var message = title + "\n" + subtitle;
    if (url) {
        message += "\n\nClick 'Yes' to open release page";
        // Show dialog with yes/no buttons
        var result = Qt.openUrlExternally(url);
    } else {
        // Just show info dialog
        console.log(message);
    }
}
```

- [ ] **Step 4: Test update check button**

Run the menu settings:
- Open Settings
- Scroll to "About" section
- Click "Check for Updates" button
- Verify it shows "Checking..."
- Wait for response
- Should show either "Update Available: X.Y.Z" or "You're Up to Date"

- [ ] **Step 5: Stage for commit (do not commit yet)**

```bash
git add contents/ui/ConfigGeneral.qml
```

(Will commit all changes together at the end)

---

## Task 10: Initialize UpdateChecker in main.qml on menu open

**Files:**
- Modify: `contents/ui/main.qml`

- [ ] **Step 1: Add UpdateChecker import**

At the top of `main.qml`, add:

```qml
import "ui/code/UpdateChecker.js" as UpdateChecker
```

- [ ] **Step 2: Add periodic update check on menu visibility**

Find the `onVisibleChanged` handler in the main menu component. Add (or create if it doesn't exist):

```qml
onVisibleChanged: {
    if (visible) {
        // Trigger periodic background update check
        UpdateChecker.checkForUpdates("1.3", function(result) {
            if (result.success && result.updateAvailable) {
                console.log("Update available: " + result.latestVersion);
                // Could trigger a subtle notification here
            }
        });
        // ... other existing logic
    }
}
```

- [ ] **Step 3: Test periodic checking**

Run the menu:
- Open menu (visible = true)
- Check console output for update check logs
- Verify no lag or freezing

- [ ] **Step 4: Stage for commit (do not commit yet)**

```bash
git add contents/ui/main.qml
```

(Will commit all changes together at the end)

---

## Final Integration Test

**Files:**
- All modified files

- [ ] **Step 1: Build and run the menu**

```bash
plasmapkg2 --upgrade . && kquitapp5 plasmashell && plasmashell &
```

Or use `kdepackagetool6` if available:

```bash
kpackagetool6 --upgrade . && kquitapp6 plasmashell && kstart6 plasmashell &
```

- [ ] **Step 2: Verify plugin removal**

- Open menu search
- Type `/calc 5*5` → should show "25"
- Search for any text → results appear normally
- No plugin-related errors in console

- [ ] **Step 3: Verify weather widget**

- Open menu settings
- Navigate to Display section
- Find "Show weather widget" toggle (should be OFF by default)
- Turn it ON
- Restart menu
- Verify weather card appears on home page (or shows "unavailable" if weather not configured)
- Turn it OFF in settings
- Restart menu
- Verify card disappears

- [ ] **Step 4: Verify update checker**

- Open menu settings
- Scroll to "About" section
- Click "Check for Updates"
- Button shows "Checking..."
- After ~2-3 seconds, shows "You're Up to Date" or "Update Available: X.Y.Z"
- Click again to re-check

- [ ] **Step 5: Full menu functionality test**

- Verify all existing features still work:
  - Pinned apps
  - Search
  - Drag-and-drop
  - Keyboard shortcuts (Ctrl+1-9, etc.)
  - All Apps view
  - Categories
  - Recent apps
  - Footer actions

- [ ] **Step 6: Create ONE final consolidated commit**

```bash
git status
```

Verify all files are staged (all modifications and deletions should show as `Changes to be committed`).

```bash
git commit -m "feat: remove plugin system, add weather widget and GitHub update checker

- Delete unused plugins directory and plugin system infrastructure
- Inline /calc command into search handler
- Add WeatherCard component powered by KDE weather daemon (disabled by default)
- Add GitHub release auto-update checker with manual button in settings
- Update configuration to include weather visibility toggle"
```

Expected output: Shows number of files changed, insertions/deletions.

---

## Files Changed Summary

- **Deleted:** `plugins/`, `contents/ui/code/plugins.js`
- **Created:** `contents/ui/WeatherCard.qml`, `contents/ui/code/UpdateChecker.js`
- **Modified:** `contents/ui/MenuRepresentation.qml`, `contents/ui/main.qml`, `contents/ui/ConfigGeneral.qml`, `contents/config/main.xml`
- **Total new code:** ~180 lines
- **Total removed code:** ~130 lines
- **Net change:** ~50 lines added

---

## Testing Checklist

- [ ] Plugin removal: `/calc` works, no plugin errors
- [ ] Weather widget: toggle works, card shows/hides, D-Bus query handles errors gracefully
- [ ] Update checker: button responsive, GitHub fetch works, version comparison accurate
- [ ] Menu opens without lag
- [ ] All existing features unchanged
- [ ] Settings persist across restarts
- [ ] No console errors related to deleted plugins
