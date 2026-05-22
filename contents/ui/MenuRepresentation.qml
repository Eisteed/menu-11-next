/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kquickcontrolsaddons 2.0

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.coreaddons 1.0 as KCoreAddons
import "." as CustomUI
import "code/UpdateChecker.js" as UpdateChecker

PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: {
        if (Plasmoid.configuration.displayPosition === 1)
            return PlasmaCore.Types.Floating;
        else if (Plasmoid.configuration.displayPosition === 2)
            return PlasmaCore.Types.BottomEdge;
        else
            return Plasmoid.location;
    }
    hideOnWindowDeactivate: true

    // Ensure minimum dimensions to prevent empty dialog error
    width: Math.max(rootItem.width, 300)
    height: Math.max(rootItem.height, 200)

    property int iconSize: {
        switch (Plasmoid.configuration.appsIconSize) {
        case 0:
            return Kirigami.Units.iconSizes.smallMedium;
        case 1:
            return Kirigami.Units.iconSizes.medium;
        case 2:
            return Kirigami.Units.iconSizes.large;
        case 3:
            return Kirigami.Units.iconSizes.huge;
        default:
            return 64;
        }
    }

    property int docsIconSize: {
        switch (Plasmoid.configuration.docsIconSize) {
        case 0:
            return Kirigami.Units.iconSizes.smallMedium;
        case 1:
            return Kirigami.Units.iconSizes.medium;
        case 2:
            return Kirigami.Units.iconSizes.large;
        case 3:
            return Kirigami.Units.iconSizes.huge;
        default:
            return Kirigami.Units.iconSizes.medium;
        }
    }

    property int cellSizeHeight: iconSize + Kirigami.Units.gridUnit * 2 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom, highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property int cellSizeWidth: cellSizeHeight + Kirigami.Units.gridUnit

    property bool searching: (searchField.text != "")

    onSearchingChanged: {
        if (searching) {
            view.currentIndex = 2;
        } else {
            view.currentIndex = 0;
            kicker.searchRunnerFilter = "all";
        }
    }
    onVisibleChanged: {
        if (visible) {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            reset();
            rootItem.loadFolders();
            rootItem.loadAllAppsFolders();
            rootItem.loadLaunchCounts();
            if (Plasmoid.configuration.allAppsViewMode === 2) {
                ensureCategoryModel();
            }
            if (weatherCard) {
                weatherCard.updateWeather();
            }
            // Trigger periodic background update check (throttled to once per 24 hours)
            if (UpdateChecker.shouldCheckForUpdates(Plasmoid.configuration)) {
                UpdateChecker.checkForUpdates("1.3", function(result) {
                    if (result.success) {
                        UpdateChecker.recordLastCheckTime(Plasmoid.configuration);
                        if (result.updateAvailable) {
                            console.log("Update available: " + result.latestVersion);
                            // Could trigger a subtle notification here
                        }
                    }
                });
            }
        } else {
            view.currentIndex = 0;
        }
    }

    onHeightChanged: {
        if (visible) {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }
    }

    onWidthChanged: {
        if (visible) {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
        }
    }

    function toggle() {
        root.visible = !root.visible;
    }

    function reset() {
        searchDebounce.stop();
        searchField.text = "";
        searchField.focus = true;
        view.currentIndex = 0;
        globalFavoritesGrid.currentIndex = -1;
        documentsGrid.currentIndex = -1;
        allAppsGrid.currentIndex = -1;
        rootItem.pinnedCurrentPage = 0;
        kicker.searchRunnerFilter = "all";
        folderContentPopup.visible = false;
        createFolderOverlay.visible = false;
        folderRenameOverlay.visible = false;
        allAppsFolderPopup.visible = false;
        createAllAppsFolderOverlay.visible = false;
    }

    function popupPosition(width, height) {
        var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x, screenAvail.y + screenGeom.y, screenAvail.width, screenAvail.height);

        var offset = Kirigami.Units.smallSpacing;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;
        var appletTopLeft;
        var horizMidPoint;
        var vertMidPoint;

        if (Plasmoid.configuration.displayPosition === 1) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = vertMidPoint - height / 2;
        } else if (Plasmoid.configuration.displayPosition === 2) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (Plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (Plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + panelSvg.margins.bottom + offset;
        } else if (Plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x * 2 + parent.width + panelSvg.margins.right + offset;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (Plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }
        return Qt.point(x, y);
    }

    function colorWithAlpha(color: color, alpha: real): color {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    mainItem: FocusScope {
        id: rootItem


        property int widthComputed: root.cellSizeWidth * Plasmoid.configuration.numberColumns + Kirigami.Units.gridUnit * 2

        property int pinnedCurrentPage: 0
        property int pinnedItemsPerPage: Plasmoid.configuration.numberColumns * Plasmoid.configuration.numberRows
        property bool ctrlHeld: false
        property int pinnedTotalPages: globalFavoritesGrid.count > 0
            ? Math.max(1, Math.ceil(globalFavoritesGrid.count / pinnedItemsPerPage))
            : 1

        onPinnedCurrentPageChanged: {
            globalFavoritesGrid.positionAtIndex(pinnedCurrentPage * pinnedItemsPerPage);
        }

        onPinnedTotalPagesChanged: {
            if (pinnedCurrentPage >= pinnedTotalPages) {
                pinnedCurrentPage = Math.max(0, pinnedTotalPages - 1);
            }
        }

        width: Math.max(widthComputed + Kirigami.Units.gridUnit * 2, 300)
        height: view.height + searchField.height + quickActionsBar.height + footer.height + Kirigami.Units.gridUnit * 3

        Layout.minimumWidth: width
        Layout.maximumWidth: width
        Layout.minimumHeight: height
        Layout.maximumHeight: height

        focus: true
        onFocusChanged: searchField.focus = true

        KCoreAddons.KUser { id: menuUser }

        property string timeGreeting: {
            var h = new Date().getHours();
            if (h < 12) return i18n("Good morning");
            if (h < 18) return i18n("Good afternoon");
            return i18n("Good evening");
        }

        // ── Pinned Folders ──────────────────────────────────────────────────
        property var pinnedFoldersData: []

        function loadFolders() {
            var raw = Plasmoid.configuration.pinnedFolders;
            if (!raw || raw.length === 0) { pinnedFoldersData = []; return; }
            try { pinnedFoldersData = JSON.parse(raw); } catch(e) { pinnedFoldersData = []; }
        }

        function saveFolders() {
            Plasmoid.configuration.pinnedFolders = JSON.stringify(pinnedFoldersData);
        }

        // ── All Apps Folders ────────────────────────────────────────────────
        property var allAppsFoldersData: []

        function loadAllAppsFolders() {
            var raw = Plasmoid.configuration.allAppsFolders;
            if (!raw || raw.length === 0) { allAppsFoldersData = []; return; }
            try { allAppsFoldersData = JSON.parse(raw); } catch(e) { allAppsFoldersData = []; }
        }

        function saveAllAppsFolders() {
            Plasmoid.configuration.allAppsFolders = JSON.stringify(allAppsFoldersData);
        }

        function launchFolderApp(desktopId) {
            var favList = globalFavorites.favorites;
            for (var i = 0; i < favList.length; i++) {
                if (favList[i] === desktopId) {
                    rootItem.recordLaunch(desktopId);
                    globalFavorites.trigger(i, "", null);
                    root.toggle();
                    return;
                }
            }
        }

        function displayNameForId(id) {
            if (id.startsWith("preferred://")) {
                var s = id.slice(12);
                return s.charAt(0).toUpperCase() + s.slice(1);
            }
            var base = id.replace(/\.desktop$/, "");
            var name = base.split(".").pop();
            return name.split("-").map(function(w) {
                return w.length > 0 ? w.charAt(0).toUpperCase() + w.slice(1) : "";
            }).join(" ");
        }

        function iconForId(id) {
            return id.startsWith("preferred://") ? "emblem-default" : id.replace(/\.desktop$/, "");
        }

        property bool _needsComboRebuild: false

        onAllAppsFoldersDataChanged: {
            if (sortedAppsModel.sourceModel) {
                if (folderAppPickerPopup.visible) {
                    _needsComboRebuild = true
                } else {
                    buildAllAppsCombo()
                }
            }
        }

        function openFolderAppPicker(folderIdx, px, py) {
            folderAppPickerPopup.openForFolder(folderIdx, px, py)
        }

        // ── All Apps combo model helpers ─────────────────────────────────────
        // Kicker role IDs (from plasma-workspace/applets/kicker/actionlist.h)
        readonly property int kickerDisplayRole:     Qt.DisplayRole          // 0
        readonly property int kickerDecorationRole:  Qt.DecorationRole       // 1
        readonly property int kickerDescriptionRole: Qt.UserRole + 1         // 257
        readonly property int kickerFavoriteIdRole:  Qt.UserRole + 3         // 259
        readonly property int kickerUrlRole:         Qt.UserRole + 10        // 266

        function lookupAppInfo(favId) {
            for (var i = 0; i < sortedAppsModel.rowCount(); i++) {
                var midx = sortedAppsModel.index(i, 0);
                if (sortedAppsModel.data(midx, kickerFavoriteIdRole) === favId) {
                    return {
                        name:        sortedAppsModel.data(midx, kickerDisplayRole)    || displayNameForId(favId),
                        decoration:  sortedAppsModel.data(midx, kickerDecorationRole) || iconForId(favId),
                        description: sortedAppsModel.data(midx, kickerDescriptionRole) || ""
                    };
                }
            }
            return { name: displayNameForId(favId), decoration: iconForId(favId), description: "" };
        }

        function buildAllAppsCombo() {
            allAppsComboModel.clear();
            if (!sortedAppsModel.sourceModel) return;

            var displayRole    = kickerDisplayRole;
            var decorationRole = kickerDecorationRole;
            var favoriteIdRole = kickerFavoriteIdRole;
            var descRole       = kickerDescriptionRole;
            var urlRole        = kickerUrlRole;
            var sortMode       = Plasmoid.configuration.allAppsSortMode;

            // Build set of foldered app IDs
            var folderedIds = {};
            for (var fi = 0; fi < allAppsFoldersData.length; fi++) {
                var fd0 = allAppsFoldersData[fi];
                if (fd0.items) {
                    for (var ai0 = 0; ai0 < fd0.items.length; ai0++) folderedIds[fd0.items[ai0]] = fi;
                }
            }

            // Non-foldered app entries (already sorted by sortedAppsModel)
            var appRows = [];
            for (var i = 0; i < sortedAppsModel.rowCount(); i++) {
                var midx = sortedAppsModel.index(i, 0);
                var favId = favoriteIdRole !== undefined ? (sortedAppsModel.data(midx, favoriteIdRole) || "") : "";
                if (favId !== "" && folderedIds[favId] !== undefined) continue;
                appRows.push({
                    itemType:    "app",
                    display:     sortedAppsModel.data(midx, displayRole)    || "",
                    decoration:  sortedAppsModel.data(midx, decorationRole) || "",
                    favoriteId:  favId,
                    description: descRole !== undefined ? (sortedAppsModel.data(midx, descRole) || "") : "",
                    url:         urlRole  !== undefined ? (sortedAppsModel.data(midx, urlRole)  || "") : "",
                    disabled: false, hasActionList: false,
                    sourceRow: i, folderIdx: -1, indented: false, expanded: false
                });
            }

            // Folder entries
            var folderRows = [];
            for (var fi2 = 0; fi2 < allAppsFoldersData.length; fi2++) {
                var fd2 = allAppsFoldersData[fi2];
                folderRows.push({
                    itemType:    "folder",
                    display:     fd2.name,
                    decoration:  "folder",
                    favoriteId:  "",
                    description: i18np("%1 app", "%1 apps", fd2.items ? fd2.items.length : 0),
                    url: "",
                    disabled: false, hasActionList: true,
                    sourceRow: -1, folderIdx: fi2, indented: false, expanded: false
                });
            }

            // Sort folder entries per mode
            if (sortMode === 0 || sortMode === 4)
                folderRows.sort(function(a, b) { return a.display.localeCompare(b.display); });
            else if (sortMode === 1)
                folderRows.sort(function(a, b) { return b.display.localeCompare(a.display); });
            else if (sortMode === 2)
                folderRows.sort(function(a, b) { return (allAppsFoldersData[b.folderIdx].createdAt||0) - (allAppsFoldersData[a.folderIdx].createdAt||0); });
            else if (sortMode === 3)
                folderRows.sort(function(a, b) { return (allAppsFoldersData[a.folderIdx].createdAt||0) - (allAppsFoldersData[b.folderIdx].createdAt||0); });

            // Combine based on sort mode
            var combined = [];
            if (sortMode === 4) {
                combined = folderRows.concat(appRows);
            } else if (sortMode === 0) {
                var ai = 0, fri = 0;
                while (ai < appRows.length && fri < folderRows.length) {
                    if (appRows[ai].display.localeCompare(folderRows[fri].display) <= 0) combined.push(appRows[ai++]);
                    else combined.push(folderRows[fri++]);
                }
                while (ai < appRows.length)   combined.push(appRows[ai++]);
                while (fri < folderRows.length) combined.push(folderRows[fri++]);
            } else if (sortMode === 1) {
                var ai2 = 0, fri2 = 0;
                while (ai2 < appRows.length && fri2 < folderRows.length) {
                    if (appRows[ai2].display.localeCompare(folderRows[fri2].display) >= 0) combined.push(appRows[ai2++]);
                    else combined.push(folderRows[fri2++]);
                }
                while (ai2 < appRows.length)   combined.push(appRows[ai2++]);
                while (fri2 < folderRows.length) combined.push(folderRows[fri2++]);
            } else {
                // Modes 2/3: newest folders first, oldest folders last
                combined = (sortMode === 2) ? folderRows.concat(appRows) : appRows.concat(folderRows);
            }

            for (var ci = 0; ci < combined.length; ci++) allAppsComboModel.append(combined[ci]);
        }

        function toggleFolderExpand(folderComboIdx) {
            if (folderComboIdx < 0 || folderComboIdx >= allAppsComboModel.count) return;
            var entry = allAppsComboModel.get(folderComboIdx);
            if (entry.itemType !== "folder") return;
            var fi = entry.folderIdx;
            if (fi < 0 || fi >= allAppsFoldersData.length) return;
            var folder = allAppsFoldersData[fi];

            if (!entry.expanded) {
                allAppsComboModel.set(folderComboIdx, { expanded: true });
                var items = folder.items || [];
                for (var i = 0; i < items.length; i++) {
                    var info = lookupAppInfo(items[i]);
                    allAppsComboModel.insert(folderComboIdx + 1 + i, {
                        itemType:    "app",
                        display:     info.name,
                        decoration:  info.decoration,
                        favoriteId:  items[i],
                        description: info.description,
                        url: "",
                        disabled: false, hasActionList: false,
                        sourceRow: -1, folderIdx: fi, indented: true, expanded: false
                    });
                }
            } else {
                allAppsComboModel.set(folderComboIdx, { expanded: false });
                while (folderComboIdx + 1 < allAppsComboModel.count) {
                    var next = allAppsComboModel.get(folderComboIdx + 1);
                    if (next.indented && next.folderIdx === fi) allAppsComboModel.remove(folderComboIdx + 1);
                    else break;
                }
            }
        }

        // ── Launch Frequency Tracking ───────────────────────────────────────
        property var launchCounts: ({})

        function loadLaunchCounts() {
            var raw = Plasmoid.configuration.appLaunchCounts;
            if (!raw || raw.length === 0) { launchCounts = ({}); return; }
            try { launchCounts = JSON.parse(raw); } catch(e) { launchCounts = ({}); }
        }

        function saveLaunchCounts() {
            Plasmoid.configuration.appLaunchCounts = JSON.stringify(launchCounts);
        }

        // Returns the current workflow bucket key: "day-slot"
        // day: 0=Sun…6=Sat, slot: 0=night(0-5h), 1=morning(6-11h), 2=afternoon(12-17h), 3=evening(18-23h)
        function currentBucket() {
            var now = new Date();
            var day = now.getDay();
            var h = now.getHours();
            var slot = h < 6 ? 0 : h < 12 ? 1 : h < 18 ? 2 : 3;
            return day + "-" + slot;
        }

        // Returns a 0-10 score for how strongly an app matches the current time/day slot
        function workflowScore(appId) {
            if (!appId) return 0;
            var entry = launchCounts[appId];
            if (!entry || typeof entry !== "object") return 0;
            var bucket = currentBucket();
            var bucketCount = (entry.buckets && entry.buckets[bucket]) || 0;
            var total = entry.total || 1;
            return Math.round((bucketCount / total) * 10);
        }

        function recordLaunch(appId) {
            if (!appId || appId === "") return;
            var updated = JSON.parse(JSON.stringify(launchCounts));
            var bucket = currentBucket();
            var prev = updated[appId];
            // Migrate legacy plain-number entries to the new schema
            var prevTotal = (typeof prev === "number") ? prev : (prev && prev.total ? prev.total : 0);
            var prevBuckets = (prev && typeof prev === "object" && prev.buckets) ? prev.buckets : {};
            prevBuckets[bucket] = (prevBuckets[bucket] || 0) + 1;
            updated[appId] = { total: prevTotal + 1, buckets: prevBuckets };
            launchCounts = updated;
            saveLaunchCounts();
        }

        // ── Smart Context ────────────────────────────────────────────────────
        property string contextLabel: {
            var counts = rootItem.launchCounts;
            // Check for workflow pattern: any app with bucket score >= 6
            var hasWorkflow = false;
            for (var id in counts) {
                if (rootItem.workflowScore(id) >= 6) { hasWorkflow = true; break; }
            }
            if (hasWorkflow) {
                var now = new Date();
                var days = [i18n("Sunday"), i18n("Monday"), i18n("Tuesday"),
                            i18n("Wednesday"), i18n("Thursday"), i18n("Friday"), i18n("Saturday")];
                var h = now.getHours();
                var dayName = days[now.getDay()];
                if (h < 6)  return i18n("%1 night session", dayName);
                if (h < 12) return i18n("%1 morning picks", dayName);
                if (h < 18) return i18n("%1 afternoon picks", dayName);
                return i18n("%1 evening picks", dayName);
            }
            // Frequency-based fallback
            var topCount = 0;
            for (var aid in counts) {
                var entry = counts[aid];
                var t = (entry && typeof entry === "object") ? (entry.total || 0) : (entry || 0);
                if (t > topCount) topCount = t;
            }
            if (topCount >= 10) return i18n("Your top picks");
            if (topCount >= 5)  return i18n("Frequently used");
            // Time-of-day fallback
            var hour = new Date().getHours();
            if (hour >= 5  && hour < 9)  return i18n("Your morning session");
            if (hour >= 9  && hour < 12) return i18n("Good morning apps");
            if (hour >= 12 && hour < 14) return i18n("Midday picks");
            if (hour >= 14 && hour < 18) return i18n("Afternoon session");
            if (hour >= 18 && hour < 21) return i18n("Evening apps");
            return i18n("Late night");
        }

        // ── Command Palette ──────────────────────────────────────────────────
        readonly property var paletteCommands: ([
            { name: "lock",       icon: "system-lock-screen",  desc: i18n("Lock the screen"),       cmd: "loginctl lock-session" },
            { name: "sleep",      icon: "system-suspend",      desc: i18n("Suspend to RAM"),         cmd: "systemctl suspend" },
            { name: "reboot",     icon: "system-reboot",       desc: i18n("Restart the computer"),   cmd: "systemctl reboot" },
            { name: "shutdown",   icon: "system-shutdown",     desc: i18n("Shut down the computer"), cmd: "systemctl poweroff" },
            { name: "screenshot", icon: "spectacle",           desc: i18n("Take a screenshot"),      cmd: "spectacle --gui" },
            { name: "settings",   icon: "preferences-system",  desc: i18n("Open System Settings"),   cmd: "systemsettings" },
            { name: "files",      icon: "system-file-manager", desc: i18n("Open file manager"),      cmd: "dolphin" },
            { name: "terminal",   icon: "utilities-terminal",  desc: i18n("Open a terminal"),        cmd: "konsole" },
            { name: "logout",     icon: "system-log-out",      desc: i18n("Log out"),                cmd: "loginctl terminate-user " + Qt.application.name }
        ])

        Plasma5Support.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []

            property bool dolphinRunning: false

            onNewData: function (source, data) {
                if (source.includes("pgrep")) {
                    dolphinRunning = data["exit code"] === 0;
                }
                disconnectSource(source);
            }

            function exec(cmd) {
                connectSource(cmd);
            }

            function checkDolphin() {
                connectSource("pgrep dolphin");
            }
        }

        Kirigami.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 5
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        KItemModels.KSortFilterProxyModel {
            id: sortedAppsModel

            sortRoleName: {
                var m = Plasmoid.configuration.allAppsSortMode;
                if (m === 4) return "description";
                if (m === 2 || m === 3) return "url";
                return "display";
            }
            sortOrder: {
                var m = Plasmoid.configuration.allAppsSortMode;
                return (m === 1 || m === 3) ? Qt.DescendingOrder : Qt.AscendingOrder;
            }

            function trigger(row, actionId, argument) {
                var srcIdx = mapToSource(index(row, 0))
                if (srcIdx.valid && sourceModel)
                    sourceModel.trigger(srcIdx.row, actionId, argument)
            }

            property var favoritesModel: sourceModel ? sourceModel.favoritesModel : null
        }

        ListModel {
            id: allAppsComboModel
            // Exposes favoritesModel so delegates can Pin/Unpin via the same KActivities model
            property var favoritesModel: sortedAppsModel.favoritesModel
        }

        PC3.TextField {
            id: searchField
            anchors {
                top: parent.top
                topMargin: Kirigami.Units.gridUnit
                left: parent.left
                leftMargin: Kirigami.Units.gridUnit
                right: parent.right
                rightMargin: Kirigami.Units.gridUnit
            }
            focus: true
            placeholderText: i18n("Type here to search ...")
            topPadding: 10
            bottomPadding: 10
            leftPadding: Kirigami.Units.gridUnit + Kirigami.Units.iconSizes.small
            text: ""
            font.pointSize: Kirigami.Theme.defaultFont.pointSize

            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                radius: 20
                border.width: 1
                border.color: colorWithAlpha(Kirigami.Theme.textColor, 0.05)
            }

            onTextChanged: {
                if (text.startsWith('>') && Plasmoid.configuration.enableShellRunner) {
                    searchDebounce.stop();
                    runnerModel.query = "";
                } else if (text.startsWith('/')) {
                    searchDebounce.stop();
                    runnerModel.query = "";
                } else {
                    searchDebounce.restart();
                }
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (root.searching) {
                        searchField.clear();
                    } else {
                        root.toggle();
                    }
                }
                // In '/' palette mode, Down focuses the palette list
                if (searchField.text.startsWith('/') && event.key === Qt.Key_Down) {
                    event.accepted = true;
                    commandPaletteList.currentIndex = 0;
                    commandPaletteList.forceActiveFocus();
                    return;
                }

                // Forward Up/Down keys directly to runnerGrid when on search page
                if (view.currentIndex === 2 && (event.key === Qt.Key_Up || event.key === Qt.Key_Down)) {
                    event.accepted = true;
                    runnerGrid.focus = true;

                    if (event.key === Qt.Key_Down) {
                        if (!runnerGrid.focus || runnerGrid.currentIndex === -1) {
                            runnerGrid.tryActivate(0, 0);
                        } else {
                            var currentGrid = runnerGrid.subGridAt(0);
                            if (currentGrid) {
                                currentGrid.forceActiveFocus();
                                currentGrid.keyNavDown();
                            }
                        }
                    } else if (event.key === Qt.Key_Up) {
                        var lastGridIndex = runnerGrid.count - 1;
                        if (lastGridIndex >= 0) {
                            var lastGrid = runnerGrid.subGridAt(lastGridIndex);
                            if (lastGrid && lastGrid.count > 0) {
                                lastGrid.tryActivate(lastGrid.lastRow(), 0);
                                lastGrid.focus = true;
                            }
                        }
                    }
                    return;
                }

                if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    event.accepted = true;
                    if (view.currentIndex === 2) {
                        // For search results page
                        runnerGrid.focus = true;
                        runnerGrid.tryActivate(0, 0);
                    } else {
                        // For other pages
                        view.currentItem.forceActiveFocus();
                        view.currentItem.tryActivate(0, 0);
                    }
                }

                
            }
            Keys.onReturnPressed: {
                if (root.searching && searchField.text.startsWith('>') && Plasmoid.configuration.enableShellRunner) {
                    var cmd = searchField.text.slice(1).trim();
                    if (cmd.length > 0) {
                        executable.exec(cmd);
                        root.toggle();
                        return;
                    }
                }
                if (root.searching && searchField.text.startsWith('/')) {
                    // Calculator result: copy to clipboard
                    if (commandPaletteContainer.calcResult !== "") {
                        executable.exec("printf '%s' '" + commandPaletteContainer.calcResult + "' | xclip -selection clipboard 2>/dev/null || printf '%s' '" + commandPaletteContainer.calcResult + "' | xsel --clipboard --input 2>/dev/null");
                        root.toggle();
                        return;
                    }
                    // Normal command execution
                    var query = searchField.text.slice(1).toLowerCase().trim();
                    var matched = rootItem.paletteCommands.filter(function(c) {
                        return query === "" || c.name.startsWith(query);
                    });
                    if (matched.length > 0 && matched[0].cmd !== "") {
                        executable.exec(matched[0].cmd);
                        root.toggle();
                    }
                    return;
                }
                if (view.currentIndex === 2) {
                    // On search results page, activate the first available item
                    runnerGrid.focus = true;

                    // Find the first grid with items and activate its first item
                    for (var i = 0; i < runnerGrid.count; i++) {
                        var grid = runnerGrid.subGridAt(i);
                        if (grid && grid.count > 0) {
                            grid.currentIndex = 0;
                            grid.focus = true;
                            grid.itemActivated(0, "", null);
                       
                            if ("trigger" in grid.model) {
                                //console.log("Calling grid.model.trigger(0)");
                                grid.model.trigger(0, "", null);
                                root.toggle();
                            }
                            return;
                        }
                    }
                } else {
                    // Original logic for other pages
                    for (var i = 0; i < runnerGrid.count; i++) {
                        var grid = runnerGrid.subGridAt(i)
                        if (grid && grid.count > 0) {
                            grid.currentIndex = 0
                            grid.focus = true
                            grid.itemActivated(0, "", null)
                            return
                        }
                    }
                }
            }
            function backspace() {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text.slice(0, -1);
            }

            function appendText(newText) {
                if (!root.visible) {
                    return;
                }
                focus = true;
                text = text + newText;
            }

            Kirigami.Icon {
                source: root.searching && searchField.text.startsWith('>')
                        ? 'utilities-terminal'
                        : root.searching && searchField.text.startsWith('/')
                        ? 'run-build'
                        : 'search'
                anchors {
                    left: searchField.left
                    verticalCenter: searchField.verticalCenter
                    leftMargin: Kirigami.Units.smallSpacing * 2
                }
                height: Kirigami.Units.iconSizes.small
                width: height

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }

        // ── Quick Actions Bar ────────────────────────────────────────────────
        // Shows contextual single-click actions when search is idle; slides away while searching.
        Item {
            id: quickActionsBar
            anchors.top: searchField.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing
            anchors.left: parent.left
            anchors.leftMargin: Kirigami.Units.gridUnit
            anchors.right: parent.right
            anchors.rightMargin: Kirigami.Units.gridUnit
            clip: true
            height: (root.searching || !Plasmoid.configuration.showQuickActions) ? 0 : qaRow.implicitHeight + Kirigami.Units.smallSpacing

            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Row {
                id: qaRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: Kirigami.Units.smallSpacing / 2

                Repeater {
                    model: [
                        { icon: "spectacle",           tip: i18n("Screenshot"),     cmd: "spectacle --gui" },
                        { icon: "system-lock-screen",  tip: i18n("Lock Screen"),    cmd: "loginctl lock-session" },
                        { icon: "utilities-terminal",  tip: i18n("Open Terminal"),  cmd: "konsole" },
                        { icon: "system-file-manager", tip: i18n("Open Files"),     cmd: "dolphin" },
                        { icon: "accessories-calculator", tip: i18n("Calculator"),  cmd: "kcalc" },
                        { icon: "preferences-system",  tip: i18n("System Settings"), cmd: "systemsettings" }
                    ]

                    delegate: PC3.ToolButton {
                        icon.name: modelData.icon
                        display: AbstractButton.IconOnly
                        PC3.ToolTip.text: modelData.tip
                        PC3.ToolTip.visible: hovered
                        PC3.ToolTip.delay: 400
                        opacity: hovered ? 1.0 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                        onClicked: {
                            executable.exec(modelData.cmd);
                            root.toggle();
                        }
                    }
                }
            }
        }

        SwipeView {
            id: view

            interactive: false
            currentIndex: 0
            clip: true

            anchors {
                top: quickActionsBar.bottom
                topMargin: Kirigami.Units.smallSpacing
                left: parent.left
                leftMargin: Kirigami.Units.gridUnit
                right: parent.right
                rightMargin: Kirigami.Units.gridUnit
            }
            onCurrentIndexChanged: {
                globalFavoritesGrid.currentIndex = -1;
                documentsGrid.currentIndex = -1;
            }

            width: rootItem.widthComputed / 0.1
            height: (root.cellSizeHeight * Plasmoid.configuration.numberRows)
                  + (topRow.height * 2)
                  + ((docsIconSize + Kirigami.Units.largeSpacing) * 5)
                  + (3 * Kirigami.Units.largeSpacing)
                  + Kirigami.Units.gridUnit
                  + Kirigami.Units.largeSpacing * 2
                  + (Plasmoid.configuration.showRecentApps
                     ? Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 3
                     : 0)
                  + (rootItem.pinnedFoldersData.length > 0
                     ? (Math.ceil(rootItem.pinnedFoldersData.length / Math.max(1, Plasmoid.configuration.numberColumns)) * root.cellSizeHeight + Kirigami.Units.largeSpacing * 2)
                     : 0)

            // PAGE 1
            Column {
                width: rootItem.widthComputed
                spacing: Kirigami.Units.largeSpacing * 2
                function tryActivate(row, col) {
                    globalFavoritesGrid.tryActivate(row, col);
                }

                RowLayout {
                    id: topRow
                    width: parent.width

                    Column {
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        PlasmaExtras.Heading {
                            id: headLabelGreeting
                            color: colorWithAlpha(Kirigami.Theme.textColor, 0.9)
                            level: 5
                            font.weight: Font.Bold
                            text: {
                                var first = menuUser.fullName.split(" ")[0];
                                return first.length > 0
                                    ? rootItem.timeGreeting + ", " + first
                                    : rootItem.timeGreeting;
                            }
                        }

                        Text {
                            text: i18n("Pinned")
                            color: colorWithAlpha(Kirigami.Theme.textColor, 0.45)
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.8
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    PC3.ToolButton {
                        icon.name: "folder-new"
                        display: AbstractButton.IconOnly
                        PC3.ToolTip.text: i18n("New folder")
                        PC3.ToolTip.visible: hovered
                        PC3.ToolTip.delay: 500
                        onClicked: {
                            newFolderNameField.text = "";
                            appPickerListView.checkedIds = [];
                            createFolderOverlay.visible = true;
                        }
                    }

                    AToolButton {
                        id: butttonActionAllApps
                        flat: false
                        iconName: "go-next"
                        text: i18n("All apps")
                        buttonHeight: 25
                        onClicked: {
                            view.currentIndex = 1;
                        }
                    }
                }

                ItemGridView {
                    id: globalFavoritesGrid
                    width: parent.width
                    height: root.cellSizeHeight * Plasmoid.configuration.numberRows
                    itemColumns: 1
                    dragEnabled: true
                    dropEnabled: true
                    cellWidth: parent.width / Plasmoid.configuration.numberColumns
                    cellHeight: root.cellSizeHeight
                    iconSize: root.iconSize
                    onKeyNavUp: {
                        if (rootItem.pinnedCurrentPage > 0) {
                            rootItem.pinnedCurrentPage--;
                            globalFavoritesGrid.tryActivate(Plasmoid.configuration.numberRows - 1, 0);
                        } else {
                            globalFavoritesGrid.focus = false;
                            searchField.focus = true;
                        }
                    }
                    onKeyNavDown: {
                        if (rootItem.pinnedCurrentPage < rootItem.pinnedTotalPages - 1) {
                            rootItem.pinnedCurrentPage++;
                            globalFavoritesGrid.tryActivate(0, 0);
                        } else {
                            globalFavoritesGrid.focus = false;
                            documentsGrid.tryActivate(0, 0);
                        }
                    }
                    onKeyNavLeft: {
                        if (rootItem.pinnedCurrentPage > 0) {
                            rootItem.pinnedCurrentPage--;
                            globalFavoritesGrid.tryActivate(0, Plasmoid.configuration.numberColumns - 1);
                        }
                    }
                    onKeyNavRight: {
                        if (rootItem.pinnedCurrentPage < rootItem.pinnedTotalPages - 1) {
                            rootItem.pinnedCurrentPage++;
                            globalFavoritesGrid.tryActivate(0, 0);
                        }
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab) {
                            event.accepted = true;
                            searchField.focus = true;
                            globalFavoritesGrid.focus = false;
                        } else if (event.key === Qt.Key_PageDown) {
                            event.accepted = true;
                            if (rootItem.pinnedCurrentPage < rootItem.pinnedTotalPages - 1) {
                                rootItem.pinnedCurrentPage++;
                                globalFavoritesGrid.tryActivate(0, 0);
                            }
                        } else if (event.key === Qt.Key_PageUp) {
                            event.accepted = true;
                            if (rootItem.pinnedCurrentPage > 0) {
                                rootItem.pinnedCurrentPage--;
                                globalFavoritesGrid.tryActivate(0, 0);
                            }
                        } else if (event.key === Qt.Key_Home) {
                            event.accepted = true;
                            rootItem.pinnedCurrentPage = 0;
                            globalFavoritesGrid.tryActivate(0, 0);
                        } else if (event.key === Qt.Key_End) {
                            event.accepted = true;
                            rootItem.pinnedCurrentPage = rootItem.pinnedTotalPages - 1;
                            globalFavoritesGrid.tryActivate(0, 0);
                        }
                    }
                }

                // Page indicator dots for pinned apps pagination
                Item {
                    width: parent.width
                    height: Kirigami.Units.gridUnit

                    Row {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.smallSpacing * 2
                        visible: rootItem.pinnedTotalPages > 1

                        Repeater {
                            model: rootItem.pinnedTotalPages
                            delegate: Item {
                                readonly property bool isCurrent: rootItem.pinnedCurrentPage === index
                                width: isCurrent ? 20 : 8
                                height: 8
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on width {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: isCurrent
                                           ? Kirigami.Theme.highlightColor
                                           : root.colorWithAlpha(Kirigami.Theme.textColor, 0.3)

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rootItem.pinnedCurrentPage = index
                                }
                            }
                        }
                    }
                }

                // ── Pinned Folders strip ────────────────────────────────────────
                Flow {
                    id: folderStrip
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing
                    visible: rootItem.pinnedFoldersData.length > 0

                    Repeater {
                        id: folderTilesRepeater
                        model: rootItem.pinnedFoldersData

                        delegate: Item {
                            id: folderTile
                            width: root.cellSizeWidth
                            height: root.cellSizeHeight

                            property var fd: rootItem.pinnedFoldersData[index] || {name:"", items:[]}

                            focus: true
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: fd.name

                            Keys.onReturnPressed: {
                                var pos = mapToItem(rootItem, 0, 0);
                                folderContentPopup.showAt(index, pos.x, pos.y, width, height);
                            }
                            Keys.onSpacePressed: Keys.onReturnPressed

                            // Hover/focus background
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing / 2
                                radius: Kirigami.Units.smallSpacing + 2
                                color: Kirigami.Theme.highlightColor
                                opacity: tileHover.containsMouse ? 0.12 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }

                            // Keyboard focus ring
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Kirigami.Units.smallSpacing + 3
                                color: "transparent"
                                border.width: folderTile.activeFocus ? 2 : 0
                                border.color: Kirigami.Theme.highlightColor
                                opacity: 0.75
                                Behavior on border.width { NumberAnimation { duration: 80 } }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Kirigami.Units.smallSpacing

                                // Icon mosaic
                                Item {
                                    id: mosaicBox
                                    width: Kirigami.Units.iconSizes.medium
                                    height: Kirigami.Units.iconSizes.medium
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Kirigami.Units.smallSpacing
                                        color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.15)
                                        border.width: 1
                                        border.color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.35)
                                    }

                                    Grid {
                                        anchors.centerIn: parent
                                        columns: 2
                                        spacing: 2

                                        Repeater {
                                            model: Math.min(4, folderTile.fd.items.length)
                                            delegate: Kirigami.Icon {
                                                width: (mosaicBox.width - 10) / 2
                                                height: width
                                                source: rootItem.iconForId(folderTile.fd.items[index])
                                                animated: false
                                            }
                                        }
                                    }

                                    // Empty folder icon
                                    Kirigami.Icon {
                                        visible: folderTile.fd.items.length === 0
                                        anchors.centerIn: parent
                                        source: "folder"
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                        animated: false
                                    }
                                }

                                // Folder name
                                Text {
                                    width: root.cellSizeWidth - Kirigami.Units.largeSpacing * 2
                                    text: folderTile.fd.name
                                    color: Kirigami.Theme.textColor
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }

                            MouseArea {
                                id: tileHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        folderContextMenu.targetIndex = index;
                                        folderContextMenu.popup();
                                    } else {
                                        var pos = mapToItem(rootItem, 0, 0);
                                        folderContentPopup.showAt(index, pos.x, pos.y, width, height);
                                    }
                                }
                            }

                            // Drag-to-folder drop target
                            DropArea {
                                id: folderDropTarget
                                anchors.fill: parent

                                onDropped: {
                                    var src = kicker.dragSource;
                                    if (!src || !src.favoriteId || src.favoriteId === "") return;
                                    var favId = src.favoriteId;
                                    var folders = rootItem.pinnedFoldersData.slice();
                                    var folder = folders[index];
                                    if (!folder || folder.items.indexOf(favId) >= 0) return;
                                    folders[index] = { name: folder.name, items: folder.items.concat([favId]) };
                                    rootItem.pinnedFoldersData = folders;
                                    rootItem.saveFolders();
                                }

                                // Drop-hover highlight ring
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing + 3
                                    color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.22)
                                    border.width: 2
                                    border.color: Kirigami.Theme.highlightColor
                                    visible: folderDropTarget.containsDrag
                                             && typeof kicker.dragSource !== "undefined"
                                             && kicker.dragSource !== null
                                }
                            }
                        }
                    }
                }

                // ── Weather Card ────────────────────────────────────────────────
                CustomUI.WeatherCard {
                    id: weatherCard
                    width: parent.width
                }

                // Fixed-height container so the menu never resizes when docs/recent-apps are toggled
                Item {
                    id: docsContainer
                    width: parent.width

                    readonly property int recentAppsStripHeight: Plasmoid.configuration.showRecentApps
                        ? Kirigami.Units.iconSizes.medium + Kirigami.Units.largeSpacing * 3
                        : 0

                    height: recentAppsStripHeight
                          + butttonActionAllApps.implicitHeight
                          + Kirigami.Units.largeSpacing * 2
                          + (docsIconSize + Kirigami.Units.largeSpacing * 2) * 3

                    // Recently opened apps — horizontal icon strip
                    Item {
                        id: recentAppsStrip
                        width: parent.width
                        height: docsContainer.recentAppsStripHeight
                        visible: Plasmoid.configuration.showRecentApps

                        // Smart context header
                        Row {
                            id: recentAppsHeader
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Kirigami.Units.smallSpacing / 2

                            Kirigami.Icon {
                                id: recentAppsHeaderIcon
                                source: 'view-history'
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: Kirigami.Units.iconSizes.smallMedium
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: rootItem.contextLabel
                                color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.55)
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.78
                            }
                        }

                        ListView {
                            id: recentAppsListView
                            anchors.left: recentAppsHeader.right
                            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            orientation: ListView.Horizontal
                            interactive: false
                            spacing: Kirigami.Units.smallSpacing
                            clip: true

                            delegate: Item {
                                id: recentAppItem
                                width: Kirigami.Units.iconSizes.medium + Kirigami.Units.gridUnit * 2
                                height: recentAppsListView.height

                                PC3.ToolTip.text: model.display || ""
                                PC3.ToolTip.visible: recentAppHover.containsMouse && recentAppLabel.truncated
                                PC3.ToolTip.delay: 800

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -Kirigami.Units.smallSpacing / 2
                                    radius: Kirigami.Units.smallSpacing + 2
                                    color: Kirigami.Theme.highlightColor
                                    opacity: recentAppHover.containsMouse ? 0.12 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 100 } }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing / 2

                                    Kirigami.Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        source: model.decoration || ""
                                        width: Kirigami.Units.iconSizes.smallMedium
                                        height: width
                                    }

                                    Text {
                                        id: recentAppLabel
                                        width: recentAppItem.width - Kirigami.Units.smallSpacing * 2
                                        text: model.display || ""
                                        color: Kirigami.Theme.textColor
                                        opacity: 0.75
                                        font.pointSize: Math.max(6, Kirigami.Theme.defaultFont.pointSize * 0.77)
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                MouseArea {
                                    id: recentAppHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (recentAppsListView.model && "trigger" in recentAppsListView.model) {
                                            recentAppsListView.model.trigger(index, "", null);
                                            root.toggle();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        id: docsHeaderRow
                        width: parent.width
                        height: butttonActionAllApps.implicitHeight
                        y: docsContainer.recentAppsStripHeight
                        opacity: Plasmoid.configuration.showRecentDocs ? 1.0 : 0.0
                        enabled: Plasmoid.configuration.showRecentDocs

                        Kirigami.Icon {
                            source: 'tag-recents'
                            implicitHeight: Kirigami.Units.iconSizes.smallMedium
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                        }

                        PlasmaExtras.Heading {
                            color: colorWithAlpha(Kirigami.Theme.textColor, 0.8)
                            level: 5
                            text: i18n("Recent documents")
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                            font.weight: Font.Bold
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        AToolButton {
                            id: butttonActionRecentMore
                            flat: false
                            iconName: "go-next"
                            text: i18n("Show more")
                            buttonHeight: 25
                            onClicked: {
                                executable.checkDolphin();
                                if (executable.dolphinRunning) {
                                    executable.exec("dolphin 'recentlyused:/files/'");
                                } else {
                                    executable.exec("dolphin --new-window 'recentlyused:/files/'");
                                }
                                root.toggle();
                            }
                        }
                    }

                    ItemGridView {
                        id: documentsGrid
                        y: docsContainer.recentAppsStripHeight + butttonActionAllApps.implicitHeight + Kirigami.Units.largeSpacing * 2
                        width: rootItem.widthComputed
                        height: (docsIconSize + Kirigami.Units.largeSpacing * 2) * 3
                        itemColumns: 2
                        dragEnabled: true
                        dropEnabled: true
                        cellWidth: rootItem.widthComputed * 0.48
                        cellHeight: docsIconSize + Kirigami.Units.largeSpacing * 2
                        iconSize: docsIconSize
                        clip: true
                        visible: Plasmoid.configuration.showRecentDocs
                        onKeyNavUp: {
                            globalFavoritesGrid.tryActivate(0, 0);
                            documentsGrid.focus = false;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) {
                                event.accepted = true;
                                documentsGrid.focus = false;
                                footerContent.forceActiveFocus();
                            }
                        }
                    }
                }
            }
            // PAGE 2
            Column {
                id: allAppsPage
                width: rootItem.widthComputed
                spacing: Kirigami.Units.largeSpacing

                function tryActivate(row, col) {
                    if (Plasmoid.configuration.allAppsViewMode === 2)
                        allAppsCategoryGrid.tryActivate(row, col);
                    else
                        allAppsGrid.tryActivate(row, col);
                }

                function onViewModeChanged() {
                    if (Plasmoid.configuration.allAppsViewMode === 2) {
                        ensureCategoryModel();
                    }
                }

                RowLayout {
                    id: allAppsHeader
                    width: parent.width
                    height: butttonActionAllApps.implicitHeight

                    Kirigami.Icon {
                        source: 'application-menu'
                        implicitHeight: Kirigami.Units.iconSizes.smallMedium
                        implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    }

                    PlasmaExtras.Heading {
                        color: colorWithAlpha(Kirigami.Theme.textColor, 0.8)
                        level: 5
                        text: i18n("All apps")
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    AToolButton {
                        flat: true
                        iconName: 'folder-new'
                        text: i18n("New Folder")
                        buttonHeight: 25
                        onClicked: {
                            newAllAppsFolderNameField.text = "";
                            createAllAppsFolderOverlay.visible = true;
                            newAllAppsFolderNameField.forceActiveFocus();
                        }
                    }

                    AToolButton {
                        flat: false
                        iconName: 'go-previous'
                        text: i18n("Pinned")
                        buttonHeight: 25
                        onClicked: view.currentIndex = 0
                    }
                }

                Item {
                    id: allAppsGridContainer
                    width: parent.width
                    height: allAppsGrid.height
                    visible: Plasmoid.configuration.allAppsViewMode !== 2

                    Row {
                        id: allAppsGridRow
                        width: parent.width
                        spacing: Kirigami.Units.smallSpacing

                        // Alphabet slider — LEFT side
                        Item {
                            id: alphabetSliderWrapper
                            width: Kirigami.Units.gridUnit * 1.5
                            height: allAppsGrid.height

                            property string activeLetter: ""

                            Column {
                                anchors.fill: parent

                                Repeater {
                                    id: letterRepeater
                                    model: ["#","A","B","C","D","E","F","G","H","I","J","K","L","M",
                                            "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

                                    delegate: Item {
                                        width: alphabetSliderWrapper.width
                                        height: alphabetSliderWrapper.height / 27

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: Math.max(7, Math.min(11, parent.height * 0.72))
                                            color: alphabetSliderWrapper.activeLetter === modelData
                                                   ? Kirigami.Theme.highlightColor
                                                   : Kirigami.Theme.textColor
                                            opacity: alphabetSliderWrapper.activeLetter === modelData ? 1.0 : 0.5
                                            font.bold: alphabetSliderWrapper.activeLetter === modelData

                                            Behavior on color { ColorAnimation { duration: 80 } }
                                            Behavior on opacity { NumberAnimation { duration: 80 } }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                function letterAtY(y) {
                                    var letters = ["#","A","B","C","D","E","F","G","H","I","J","K","L","M",
                                                   "N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
                                    var idx = Math.floor(y / height * letters.length);
                                    idx = Math.max(0, Math.min(letters.length - 1, idx));
                                    return letters[idx];
                                }

                                onClicked: {
                                    var letter = letterAtY(mouse.y);
                                    alphabetSliderWrapper.activeLetter = letter;
                                    root.scrollToLetter(letter);
                                }
                                onPositionChanged: {
                                    if (pressed) {
                                        var letter = letterAtY(mouse.y);
                                        alphabetSliderWrapper.activeLetter = letter;
                                        root.scrollToLetter(letter);
                                    }
                                }
                                onReleased: alphabetSliderWrapper.activeLetter = ""
                                onExited: alphabetSliderWrapper.activeLetter = ""
                            }
                        }

                        // App grid — RIGHT side
                        ItemGridView {
                            id: allAppsGrid
                            width: parent.width - alphabetSliderWrapper.width - parent.spacing
                            height: Math.floor((view.height - allAppsHeader.height - Kirigami.Units.largeSpacing * 2) / cellHeight) * cellHeight
                            itemColumns: Plasmoid.configuration.allAppsViewMode === 1 ? 1 : 2
                            dragEnabled: true
                            dropEnabled: false
                            verticalScrollBarPolicy: PC3.ScrollBar.AsNeeded
                            cellWidth: Plasmoid.configuration.allAppsViewMode === 1
                                       ? root.cellSizeWidth
                                       : width - Kirigami.Units.gridUnit * 2
                            cellHeight: Plasmoid.configuration.allAppsViewMode === 1
                                        ? root.cellSizeHeight
                                        : root.iconSize + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
                            iconSize: root.iconSize
                            clip: true
                            onKeyNavUp: {
                                searchField.focus = true;
                                allAppsGrid.focus = false;
                            }
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Tab) {
                                    event.accepted = true;
                                    searchField.focus = true;
                                    allAppsGrid.focus = false;
                                }
                            }
                        }
                    }

                    // Large letter overlay — appears on alphabet slider use, then fades
                    Rectangle {
                        id: alphabetOverlay
                        anchors.centerIn: parent
                        width: Kirigami.Units.gridUnit * 10
                        height: width
                        radius: Kirigami.Units.smallSpacing * 3
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                                       Kirigami.Theme.backgroundColor.g,
                                       Kirigami.Theme.backgroundColor.b, 0.92)
                        border.width: 1
                        border.color: colorWithAlpha(Kirigami.Theme.textColor, 0.12)
                        opacity: 0
                        visible: opacity > 0
                        z: 10

                        property string currentLetter: ""

                        Text {
                            anchors.centerIn: parent
                            text: parent.currentLetter
                            font.pixelSize: Kirigami.Units.gridUnit * 5
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }

                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                ItemMultiGridView {
                    id: allAppsCategoryGrid
                    visible: Plasmoid.configuration.allAppsViewMode === 2
                    width: rootItem.widthComputed
                    height: visible
                            ? view.height - allAppsHeader.height - Kirigami.Units.largeSpacing * 2
                            : 0
                    itemColumns: 2
                    cellWidth: rootItem.widthComputed - Kirigami.Units.gridUnit * 2
                    cellHeight: root.iconSize + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
                    grabFocus: false
                    onKeyNavUp: {
                        searchField.focus = true;
                        allAppsCategoryGrid.focus = false;
                    }
                }
            }

            // PAGE 3 — Search Results
            Item {
                id: searchPage
                width: rootItem.widthComputed
                height: view.height

                function tryActivate(row, col) { runnerGrid.tryActivate(row, col); }

                // ── Filter pills (slide in when searching, hidden in shell/palette mode) ──
                Item {
                    id: filterPillsWrapper
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    height: (root.searching && !searchField.text.startsWith('>') && !searchField.text.startsWith('/'))
                            ? pillsRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                            : 0

                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Row {
                        id: pillsRow
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: [
                                { key: "all",      label: i18n("All")      },
                                { key: "apps",     label: i18n("Apps")     },
                                { key: "files",    label: i18n("Files")    },
                                { key: "settings", label: i18n("Settings") },
                                { key: "actions",  label: i18n("Actions")  }
                            ]

                            delegate: Item {
                                id: pillDelegate
                                property bool isActive: kicker.searchRunnerFilter === modelData.key
                                height: Kirigami.Units.gridUnit * 2
                                width: pillText.implicitWidth + Kirigami.Units.gridUnit * 2

                                focus: true
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.label
                                Accessible.checked: isActive

                                function activate() {
                                    kicker.searchRunnerFilter = modelData.key;
                                    var q = searchField.text;
                                    runnerModel.query = "";
                                    runnerModel.query = q;
                                }

                                Keys.onReturnPressed: activate()
                                Keys.onSpacePressed:  activate()

                                // Fill background
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: isActive
                                           ? Kirigami.Theme.highlightColor
                                           : colorWithAlpha(Kirigami.Theme.textColor, 0.08)
                                    border.width: isActive ? 0 : 1
                                    border.color: colorWithAlpha(Kirigami.Theme.textColor, 0.12)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                // Keyboard focus ring
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -2
                                    radius: height / 2 + 2
                                    color: "transparent"
                                    border.width: pillDelegate.activeFocus ? 2 : 0
                                    border.color: Kirigami.Theme.highlightColor
                                    opacity: 0.8
                                    Behavior on border.width { NumberAnimation { duration: 80 } }
                                }

                                Text {
                                    id: pillText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: isActive
                                           ? "white"
                                           : colorWithAlpha(Kirigami.Theme.textColor, 0.75)
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                                    font.bold: isActive
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pillDelegate.activate()
                                }
                            }
                        }
                    }
                }

                // ── Command Palette (visible when text starts with '/') ──────
                Item {
                    id: commandPaletteContainer
                    anchors.top: filterPillsWrapper.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.bottom: parent.bottom
                    visible: root.searching && searchField.text.startsWith('/')

                    property string paletteQuery: searchField.text.startsWith('/')
                                                  ? searchField.text.slice(1).toLowerCase().trim()
                                                  : ""

                    // Inline calculator: /calc 2+2  or /= 2+2
                    property string calcQuery: {
                        var q = paletteQuery.trim();
                        if (q.startsWith("calc ")) return q.slice(5).trim();
                        if (q.startsWith("= "))    return q.slice(2).trim();
                        return "";
                    }

                    property string calcResult: {
                        var expr = calcQuery;
                        if (!expr) return "";
                        try {
                            var r = Function("return (" + expr + ")")();
                            if (r === undefined || (typeof r === "number" && isNaN(r))) return "";
                            return String(r);
                        } catch(e) { return ""; }
                    }

                    // Inline AI: /ai <prompt>
                    property var filteredCmds: {
                        var q = paletteQuery;
                        if (q === "") return rootItem.paletteCommands;
                        // Hide normal commands when in calc mode
                        if (calcQuery !== "") return [];
                        function fuzzyMatch(str, query) {
                            var qi = 0;
                            for (var ci = 0; ci < str.length && qi < query.length; ci++) {
                                if (str[ci] === query[qi]) qi++;
                            }
                            return qi === query.length;
                        }
                        var matches = rootItem.paletteCommands.filter(function(c) {
                            var searchStr = c.name + " " + c.desc.toLowerCase();
                            return c.name.startsWith(q) || fuzzyMatch(searchStr, q);
                        });
                        // Prefix matches first, then fuzzy-only
                        matches.sort(function(a, b) {
                            var aPrefix = a.name.startsWith(q) ? 0 : 1;
                            var bPrefix = b.name.startsWith(q) ? 0 : 1;
                            return aPrefix - bPrefix;
                        });
                        return matches;
                    }

                    // Calculator result card
                    Item {
                        id: calcResultItem
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: commandPaletteContainer.calcResult !== ""
                                ? Kirigami.Units.gridUnit * 3.5 : 0
                        clip: true
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Kirigami.Units.smallSpacing
                            color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.08)
                            border.width: 1
                            border.color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.22)
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Kirigami.Units.smallSpacing

                            Rectangle {
                                width: Kirigami.Units.gridUnit * 2; height: width
                                radius: width / 2
                                color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.18)
                                anchors.verticalCenter: parent.verticalCenter
                                Kirigami.Icon {
                                    source: "accessories-calculator"
                                    width: Kirigami.Units.iconSizes.small; height: width
                                    anchors.centerIn: parent; animated: false
                                }
                            }

                            Column {
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: "= " + commandPaletteContainer.calcResult
                                    color: Kirigami.Theme.textColor
                                    font.bold: true
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                                }
                                Text {
                                    text: i18n("Enter or click to copy result")
                                    color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.55)
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.78
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                executable.exec("printf '%s' '" + commandPaletteContainer.calcResult + "' | xclip -selection clipboard 2>/dev/null || printf '%s' '" + commandPaletteContainer.calcResult + "' | xsel --clipboard --input 2>/dev/null");
                            }
                        }
                    }

                    // AI result card
                    // Hint when nothing narrowed yet
                    Text {
                        visible: commandPaletteContainer.paletteQuery === ""
                        anchors.left: parent.left
                        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                        anchors.top: calcResultItem.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        text: i18n("Type a command  ·  ↓ navigate  ·  /calc expr  ·  Enter run")
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.42)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.82
                    }

                    ListView {
                        id: commandPaletteList
                        anchors.top: calcResultItem.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        clip: true
                        model: commandPaletteContainer.filteredCmds
                        currentIndex: -1
                        keyNavigationWraps: true

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < model.length) {
                                executable.exec(model[currentIndex].cmd);
                                root.toggle();
                            }
                        }
                        Keys.onEscapePressed: {
                            currentIndex = -1;
                            searchField.forceActiveFocus();
                        }

                        highlight: Rectangle {
                            color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.18)
                            radius: Kirigami.Units.smallSpacing
                        }
                        highlightMoveDuration: 80

                        delegate: Item {
                            width: commandPaletteList.width
                            height: Kirigami.Units.gridUnit * 3

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Kirigami.Units.smallSpacing
                                color: cmdItemHover.containsMouse && commandPaletteList.currentIndex !== index
                                       ? root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.08)
                                       : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Kirigami.Units.smallSpacing

                                Rectangle {
                                    width: Kirigami.Units.gridUnit * 2
                                    height: width
                                    radius: width / 2
                                    color: root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.15)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Kirigami.Icon {
                                        source: modelData.icon
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                        anchors.centerIn: parent
                                        animated: false
                                    }
                                }

                                Column {
                                    spacing: 1
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: "/" + modelData.name
                                        color: Kirigami.Theme.textColor
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                                        font.bold: true
                                    }
                                    Text {
                                        text: modelData.desc
                                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.6)
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.82
                                    }
                                }
                            }

                            MouseArea {
                                id: cmdItemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    executable.exec(modelData.cmd);
                                    root.toggle();
                                }
                            }
                        }
                    }
                }

                // ── Alt+1-9 hint (subtle, shown when results exist) ──
                Text {
                    anchors.right: parent.right
                    anchors.top: filterPillsWrapper.bottom
                    anchors.topMargin: 2
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    visible: root.searching && runnerGrid.count > 0
                             && !searchField.text.startsWith('/')
                             && !searchField.text.startsWith('>')
                    text: i18n("Alt+1–9 to launch")
                    color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.3)
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.72
                }

                // ── Results grid ──
                ItemMultiGridView {
                    id: runnerGrid
                    anchors.top: filterPillsWrapper.bottom
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: !(root.searching && searchField.text.startsWith('/'))
                    clip: true
                    itemColumns: 3
                    cellWidth: rootItem.widthComputed - Kirigami.Units.gridUnit * 2
                    cellHeight: root.iconSize + Kirigami.Units.gridUnit + Kirigami.Units.largeSpacing
                    model: runnerModel
                    grabFocus: true
                    focus: view.currentIndex === 2
                    onKeyNavUp: {
                        runnerGrid.focus = false;
                        searchField.focus = true;
                    }
                }

                // ── Empty state ──
                Column {
                    anchors.centerIn: parent
                    visible: root.searching && !searchField.text.startsWith('/') && runnerGrid.count === 0
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: searchField.text.startsWith('>') && Plasmoid.configuration.enableShellRunner
                                ? "utilities-terminal" : "edit-find-none"
                        width: Kirigami.Units.iconSizes.huge
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.4
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (searchField.text.startsWith('>') && Plasmoid.configuration.enableShellRunner) {
                                var cmd = searchField.text.slice(1).trim();
                                return cmd.length > 0
                                    ? i18n("Press Enter to run: %1", cmd)
                                    : i18n("Type a shell command after '>'");
                            }
                            if (kicker.searchRunnerFilter !== "all") {
                                return i18n("No %1 results for \"%2\"",
                                            kicker.searchRunnerFilter, searchField.text);
                            }
                            return i18n("No results for \"%1\"", searchField.text);
                        }
                        color: Kirigami.Theme.textColor
                        opacity: 0.55
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                    }
                }
            }
        }

        PlasmaExtras.PlasmoidHeading {
            id: footer
            contentWidth: parent.width
            contentHeight: Kirigami.Units.gridUnit * 3
            anchors.bottom: parent.bottom
            position: PC3.ToolBar.Footer

            Footer {
                id: footerContent
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                onTabOut: searchField.forceActiveFocus()
            }
        }

        NumberAnimation {
            id: letterScrollAnim
            target: allAppsGrid
            property: "contentY"
            duration: 220
            easing.type: Easing.OutCubic
        }

        Timer {
            id: overlayTimer
            interval: 700
            repeat: false
            onTriggered: alphabetOverlay.opacity = 0
        }

        Timer {
            id: searchDebounce
            interval: 120
            repeat: false
            onTriggered: {
                runnerModel.query = searchField.text;
            }
        }

        // ── All Apps grid — activation dispatch ──────────────────────────────
        Connections {
            target: allAppsGrid
            function onItemActivated(index, actionId, argument) {
                if (index < 0 || index >= allAppsComboModel.count) return;
                var entry = allAppsComboModel.get(index);
                if (entry.itemType === "folder") {
                    rootItem.toggleFolderExpand(index);
                } else {
                    // App item (regular or indented folder child)
                    if (entry.sourceRow >= 0) {
                        sortedAppsModel.trigger(entry.sourceRow, "", null);
                        root.toggle();
                    } else {
                        // Indented child — look up row in sortedAppsModel by favoriteId
                        for (var i = 0; i < sortedAppsModel.rowCount(); i++) {
                            var midx = sortedAppsModel.index(i, 0);
                            if (sortedAppsModel.data(midx, rootItem.kickerFavoriteIdRole) === entry.favoriteId) {
                                sortedAppsModel.trigger(i, "", null);
                                root.toggle();
                                return;
                            }
                        }
                    }
                }
            }
        }

        // ── All Apps grid: folder edit button dispatch ───────────────────────
        Connections {
            target: allAppsGrid
            function onFolderEditRequested(index) {
                if (index < 0 || index >= allAppsComboModel.count) return
                var entry = allAppsComboModel.get(index)
                if (!entry || entry.itemType !== "folder") return
                var cols = Math.max(1, Math.floor(allAppsGrid.width / allAppsGrid.cellWidth))
                var row = Math.floor(index / cols)
                var itemY = row * allAppsGrid.cellHeight - allAppsGrid.contentY
                var p = allAppsGrid.mapToItem(rootItem, allAppsGrid.width * 0.55,
                                              itemY + allAppsGrid.cellHeight)
                rootItem.openFolderAppPicker(entry.folderIdx, p.x, p.y)
            }
        }

        // ── Folder content popup ─────────────────────────────────────────────
        // Click-outside dismiss layer
        MouseArea {
            id: folderPopupDismiss
            anchors.fill: parent
            z: 198
            visible: folderContentPopup.visible
            onClicked: folderContentPopup.visible = false
        }

        Item {
            id: folderContentPopup
            visible: false
            z: 200
            width: 240
            height: popupBg.height

            function showAt(idx, tileX, tileY, tileW, tileH) {
                folderContentPopup.property_folderIndex = idx;
                var h = popupBg.height;
                x = Math.max(0, Math.min(tileX, rootItem.width - width));
                y = tileY - h - Kirigami.Units.smallSpacing;
                if (y < 0) y = tileY + tileH + Kirigami.Units.smallSpacing;
                visible = true;
            }

            property int property_folderIndex: -1

            Rectangle {
                id: popupBg
                width: parent.width
                height: popupColumn.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: popupColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 2

                    Text {
                        leftPadding: Kirigami.Units.smallSpacing
                        text: folderContentPopup.property_folderIndex >= 0 && folderContentPopup.property_folderIndex < rootItem.pinnedFoldersData.length
                              ? rootItem.pinnedFoldersData[folderContentPopup.property_folderIndex].name
                              : ""
                        font.bold: true
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    Repeater {
                        model: folderContentPopup.property_folderIndex >= 0 && folderContentPopup.property_folderIndex < rootItem.pinnedFoldersData.length
                               ? rootItem.pinnedFoldersData[folderContentPopup.property_folderIndex].items
                               : []

                        delegate: Item {
                            width: folderContentPopup.width - Kirigami.Units.smallSpacing * 2
                            height: Kirigami.Units.gridUnit * 2.5

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Kirigami.Units.smallSpacing
                                color: appEntryHover.containsMouse
                                       ? root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.12)
                                       : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    source: rootItem.iconForId(modelData)
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    animated: false
                                }

                                Text {
                                    text: rootItem.displayNameForId(modelData)
                                    color: Kirigami.Theme.textColor
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: appEntryHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    folderContentPopup.visible = false;
                                    rootItem.launchFolderApp(modelData);
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Create-folder overlay ────────────────────────────────────────────
        Item {
            id: createFolderOverlay
            anchors.fill: parent
            visible: false
            z: 202

            // Dim background
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.45
                MouseArea { anchors.fill: parent; onClicked: createFolderOverlay.visible = false }
            }

            // Dialog card
            Rectangle {
                id: createDialog
                width: Math.min(340, rootItem.width - Kirigami.Units.largeSpacing * 4)
                height: dialogCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                anchors.centerIn: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: dialogCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        text: i18n("New Folder")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    }

                    PC3.TextField {
                        id: newFolderNameField
                        width: parent.width
                        placeholderText: i18n("Folder name")
                    }

                    Text {
                        text: i18n("Choose apps from Pinned:")
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.7)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                        topPadding: Kirigami.Units.smallSpacing
                    }

                    // App picker list
                    Rectangle {
                        width: parent.width
                        height: 160
                        radius: Kirigami.Units.smallSpacing
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.05)
                        clip: true

                        ListView {
                            id: appPickerListView
                            anchors.fill: parent
                            anchors.margins: 4
                            model: globalFavorites
                            clip: true

                            property var checkedIds: []

                            delegate: Item {
                                width: appPickerListView.width
                                height: Kirigami.Units.gridUnit * 2.5

                                property string favId: model.favoriteId !== undefined ? model.favoriteId : ""
                                property bool isChecked: appPickerListView.checkedIds.indexOf(favId) >= 0

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing
                                    color: pickHover.containsMouse
                                           ? root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.08)
                                           : "transparent"
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Kirigami.Units.smallSpacing
                                    anchors.rightMargin: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    CheckBox {
                                        anchors.verticalCenter: parent.verticalCenter
                                        checked: isChecked
                                        onToggled: {
                                            if (!favId) return;
                                            var arr = appPickerListView.checkedIds.slice();
                                            var idx = arr.indexOf(favId);
                                            if (checked && idx < 0) arr.push(favId);
                                            else if (!checked && idx >= 0) arr.splice(idx, 1);
                                            appPickerListView.checkedIds = arr;
                                        }
                                    }

                                    Kirigami.Icon {
                                        source: model.decoration !== undefined ? model.decoration : ""
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                        animated: false
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: model.display !== undefined ? model.display : ""
                                        color: Kirigami.Theme.textColor
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                        elide: Text.ElideRight
                                        width: appPickerListView.width - Kirigami.Units.iconSizes.small
                                               - Kirigami.Units.gridUnit * 2 - Kirigami.Units.smallSpacing * 3
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: pickHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!favId) return;
                                        var arr = appPickerListView.checkedIds.slice();
                                        var idx = arr.indexOf(favId);
                                        if (idx >= 0) arr.splice(idx, 1);
                                        else arr.push(favId);
                                        appPickerListView.checkedIds = arr;
                                    }
                                }
                            }
                        }
                    }

                    // Action buttons
                    RowLayout {
                        width: parent.width

                        Item { Layout.fillWidth: true }

                        PC3.Button {
                            text: i18n("Cancel")
                            onClicked: createFolderOverlay.visible = false
                        }

                        PC3.Button {
                            text: i18n("Create")
                            highlighted: true
                            enabled: newFolderNameField.text.trim().length > 0
                                  && appPickerListView.checkedIds.length > 0
                            onClicked: {
                                var folders = rootItem.pinnedFoldersData.slice();
                                folders.push({
                                    name: newFolderNameField.text.trim(),
                                    items: appPickerListView.checkedIds.slice()
                                });
                                rootItem.pinnedFoldersData = folders;
                                rootItem.saveFolders();
                                createFolderOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // ── Folder context menu (right-click on tile) ───────────────────────
        Menu {
            id: folderContextMenu
            property int targetIndex: -1

            MenuItem {
                text: i18n("Rename folder")
                icon.name: "edit-rename"
                onTriggered: {
                    var idx = folderContextMenu.targetIndex;
                    if (idx < 0 || idx >= rootItem.pinnedFoldersData.length) return;
                    folderRenameField.text = rootItem.pinnedFoldersData[idx].name;
                    folderRenameOverlay.targetIndex = idx;
                    folderRenameOverlay.visible = true;
                    folderRenameField.forceActiveFocus();
                    folderRenameField.selectAll();
                }
            }

            MenuItem {
                text: i18n("Delete folder")
                icon.name: "delete"
                onTriggered: {
                    var folders = rootItem.pinnedFoldersData.slice();
                    folders.splice(folderContextMenu.targetIndex, 1);
                    rootItem.pinnedFoldersData = folders;
                    rootItem.saveFolders();
                }
            }

            MenuItem {
                text: i18n("Unpin all apps in folder")
                icon.name: "bookmark-remove"
                onTriggered: {
                    if (folderContextMenu.targetIndex < 0) return;
                    var folder = rootItem.pinnedFoldersData[folderContextMenu.targetIndex];
                    if (!folder) return;
                    folder.items.forEach(function(id) {
                        if (globalFavorites.isFavorite(id))
                            globalFavorites.removeFavorite(id);
                    });
                    var folders = rootItem.pinnedFoldersData.slice();
                    folders.splice(folderContextMenu.targetIndex, 1);
                    rootItem.pinnedFoldersData = folders;
                    rootItem.saveFolders();
                }
            }
        }

        // ── Folder rename overlay ────────────────────────────────────────────
        Item {
            id: folderRenameOverlay
            anchors.fill: parent
            visible: false
            z: 202

            property int targetIndex: -1

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.45
                MouseArea { anchors.fill: parent; onClicked: folderRenameOverlay.visible = false }
            }

            Rectangle {
                width: Math.min(300, rootItem.width - Kirigami.Units.largeSpacing * 4)
                height: renameDialogCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                anchors.centerIn: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: renameDialogCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        text: i18n("Rename Folder")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                    }

                    PC3.TextField {
                        id: folderRenameField
                        width: parent.width
                        Keys.onReturnPressed: renameSaveBtn.clicked()
                        Keys.onEscapePressed: folderRenameOverlay.visible = false
                    }

                    RowLayout {
                        width: parent.width
                        Item { Layout.fillWidth: true }
                        PC3.Button {
                            text: i18n("Cancel")
                            onClicked: folderRenameOverlay.visible = false
                        }
                        PC3.Button {
                            id: renameSaveBtn
                            text: i18n("Save")
                            highlighted: true
                            enabled: folderRenameField.text.trim().length > 0
                            onClicked: {
                                var folders = rootItem.pinnedFoldersData.slice();
                                if (folderRenameOverlay.targetIndex >= 0 && folderRenameOverlay.targetIndex < folders.length) {
                                    folders[folderRenameOverlay.targetIndex] = {
                                        name: folderRenameField.text.trim(),
                                        items: folders[folderRenameOverlay.targetIndex].items
                                    };
                                    rootItem.pinnedFoldersData = folders;
                                    rootItem.saveFolders();
                                }
                                folderRenameOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // ── All Apps folder popup ────────────────────────────────────────────
        MouseArea {
            anchors.fill: parent
            z: 199
            visible: allAppsFolderPopup.visible
            onClicked: allAppsFolderPopup.visible = false
        }

        Item {
            id: allAppsFolderPopup
            visible: false
            z: 200
            width: 240
            height: aafPopupBg.height

            property int folderIndex: -1

            function showAt(idx, tileX, tileY, tileW, tileH) {
                folderIndex = idx;
                var h = aafPopupBg.height;
                x = Math.max(0, Math.min(tileX, rootItem.width - width));
                y = tileY - h - Kirigami.Units.smallSpacing;
                if (y < 0) y = tileY + tileH + Kirigami.Units.smallSpacing;
                visible = true;
            }

            Rectangle {
                id: aafPopupBg
                width: parent.width
                height: aafPopupCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: aafPopupCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 2

                    Text {
                        leftPadding: Kirigami.Units.smallSpacing
                        text: allAppsFolderPopup.folderIndex >= 0
                              && allAppsFolderPopup.folderIndex < rootItem.allAppsFoldersData.length
                              ? rootItem.allAppsFoldersData[allAppsFolderPopup.folderIndex].name : ""
                        font.bold: true
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    Repeater {
                        model: allAppsFolderPopup.folderIndex >= 0
                               && allAppsFolderPopup.folderIndex < rootItem.allAppsFoldersData.length
                               ? rootItem.allAppsFoldersData[allAppsFolderPopup.folderIndex].items : []

                        delegate: Item {
                            width: allAppsFolderPopup.width - Kirigami.Units.smallSpacing * 2
                            height: Kirigami.Units.gridUnit * 2.5

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Kirigami.Units.smallSpacing
                                color: aafAppHover.containsMouse
                                       ? root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.12) : "transparent"
                                Behavior on color { ColorAnimation { duration: 80 } }
                            }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                anchors.right: removeFromFolderBtn.left
                                anchors.rightMargin: Kirigami.Units.smallSpacing
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Kirigami.Units.smallSpacing

                                Kirigami.Icon {
                                    source: rootItem.iconForId(modelData)
                                    width: Kirigami.Units.iconSizes.small; height: width
                                    animated: false
                                }
                                Text {
                                    text: rootItem.displayNameForId(modelData)
                                    color: Kirigami.Theme.textColor
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                    elide: Text.ElideRight
                                    width: allAppsFolderPopup.width - Kirigami.Units.iconSizes.small
                                           - Kirigami.Units.gridUnit * 3.5
                                }
                            }

                            // Remove-from-folder × button
                            Text {
                                id: removeFromFolderBtn
                                anchors.right: parent.right
                                anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                                anchors.verticalCenter: parent.verticalCenter
                                text: "×"
                                color: removeHover.containsMouse
                                       ? Kirigami.Theme.negativeTextColor
                                       : root.colorWithAlpha(Kirigami.Theme.textColor, 0.35)
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                                visible: aafAppHover.containsMouse || removeHover.containsMouse

                                MouseArea {
                                    id: removeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var fi = allAppsFolderPopup.folderIndex;
                                        if (fi < 0 || fi >= rootItem.allAppsFoldersData.length) return;
                                        var folders = rootItem.allAppsFoldersData.slice();
                                        var folder = folders[fi];
                                        var idx = folder.items.indexOf(modelData);
                                        if (idx < 0) return;
                                        var newItems = folder.items.slice();
                                        newItems.splice(idx, 1);
                                        folders[fi] = { name: folder.name, items: newItems, createdAt: folder.createdAt || 0 };
                                        rootItem.allAppsFoldersData = folders;
                                        rootItem.saveAllAppsFolders();
                                    }
                                }
                            }

                            MouseArea {
                                id: aafAppHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    allAppsFolderPopup.visible = false;
                                    rootItem.launchFolderApp(modelData);
                                }
                            }
                        }
                    }

                    // Empty state
                    Text {
                        visible: allAppsFolderPopup.folderIndex >= 0
                                 && allAppsFolderPopup.folderIndex < rootItem.allAppsFoldersData.length
                                 && rootItem.allAppsFoldersData[allAppsFolderPopup.folderIndex].items.length === 0
                        leftPadding: Kirigami.Units.smallSpacing
                        topPadding: Kirigami.Units.smallSpacing
                        bottomPadding: Kirigami.Units.smallSpacing
                        text: i18n("Drag apps here to add them")
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.45)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                        font.italic: true
                    }
                }
            }
        }

        // ── All Apps folder context menu ─────────────────────────────────────
        Menu {
            id: allAppsFolderContextMenu
            property int targetIndex: -1

            MenuItem {
                text: i18n("Rename folder")
                icon.name: "edit-rename"
                onTriggered: {
                    var idx = allAppsFolderContextMenu.targetIndex;
                    if (idx < 0 || idx >= rootItem.allAppsFoldersData.length) return;
                    aafRenameField.text = rootItem.allAppsFoldersData[idx].name;
                    aafRenameOverlay.targetIndex = idx;
                    aafRenameOverlay.visible = true;
                    aafRenameField.forceActiveFocus();
                    aafRenameField.selectAll();
                }
            }

            MenuItem {
                text: i18n("Delete folder")
                icon.name: "delete"
                onTriggered: {
                    var folders = rootItem.allAppsFoldersData.slice();
                    folders.splice(allAppsFolderContextMenu.targetIndex, 1);
                    rootItem.allAppsFoldersData = folders;
                    rootItem.saveAllAppsFolders();
                }
            }
        }

        // ── Create All Apps folder overlay ───────────────────────────────────
        Item {
            id: createAllAppsFolderOverlay
            anchors.fill: parent
            visible: false
            z: 202

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.45
                MouseArea { anchors.fill: parent; onClicked: createAllAppsFolderOverlay.visible = false }
            }

            Rectangle {
                width: Math.min(300, rootItem.width - Kirigami.Units.largeSpacing * 4)
                height: aafCreateCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                anchors.centerIn: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: aafCreateCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        text: i18n("New Folder")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    }

                    PC3.TextField {
                        id: newAllAppsFolderNameField
                        width: parent.width
                        placeholderText: i18n("Folder name")
                        Keys.onReturnPressed: {
                            if (text.trim().length > 0) aafCreateBtn.clicked()
                        }
                        Keys.onEscapePressed: createAllAppsFolderOverlay.visible = false
                    }

                    Text {
                        text: i18n("Drag apps from the list onto this folder to add them.")
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.6)
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.82
                        wrapMode: Text.Wrap
                        width: parent.width
                    }

                    RowLayout {
                        width: parent.width
                        Item { Layout.fillWidth: true }
                        PC3.Button {
                            text: i18n("Cancel")
                            onClicked: createAllAppsFolderOverlay.visible = false
                        }
                        PC3.Button {
                            id: aafCreateBtn
                            text: i18n("Create")
                            highlighted: true
                            enabled: newAllAppsFolderNameField.text.trim().length > 0
                            onClicked: {
                                var folders = rootItem.allAppsFoldersData.slice();
                                folders.push({
                                    name: newAllAppsFolderNameField.text.trim(),
                                    items: [],
                                    createdAt: Date.now()
                                });
                                rootItem.allAppsFoldersData = folders;
                                rootItem.saveAllAppsFolders();
                                createAllAppsFolderOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // ── All Apps folder rename overlay ───────────────────────────────────
        Item {
            id: aafRenameOverlay
            anchors.fill: parent
            visible: false
            z: 202
            property int targetIndex: -1

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.45
                MouseArea { anchors.fill: parent; onClicked: aafRenameOverlay.visible = false }
            }

            Rectangle {
                width: Math.min(300, rootItem.width - Kirigami.Units.largeSpacing * 4)
                height: aafRenameCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                anchors.centerIn: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.15)

                Column {
                    id: aafRenameCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        text: i18n("Rename Folder")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    }

                    PC3.TextField {
                        id: aafRenameField
                        width: parent.width
                        Keys.onReturnPressed: aafRenameConfirmBtn.clicked()
                        Keys.onEscapePressed: aafRenameOverlay.visible = false
                    }

                    RowLayout {
                        width: parent.width
                        Item { Layout.fillWidth: true }
                        PC3.Button {
                            text: i18n("Cancel")
                            onClicked: aafRenameOverlay.visible = false
                        }
                        PC3.Button {
                            id: aafRenameConfirmBtn
                            text: i18n("Rename")
                            highlighted: true
                            enabled: aafRenameField.text.trim().length > 0
                            onClicked: {
                                var idx = aafRenameOverlay.targetIndex;
                                var folders = rootItem.allAppsFoldersData.slice();
                                if (idx >= 0 && idx < folders.length) {
                                    folders[idx] = {
                                        name: aafRenameField.text.trim(),
                                        items: folders[idx].items,
                                        createdAt: folders[idx].createdAt || 0
                                    };
                                    rootItem.allAppsFoldersData = folders;
                                    rootItem.saveAllAppsFolders();
                                }
                                aafRenameOverlay.visible = false;
                            }
                        }
                    }
                }
            }
        }

        // ── All Apps folder app-picker popup ────────────────────────────────
        MouseArea {
            anchors.fill: parent
            z: 204
            visible: folderAppPickerPopup.visible
            onClicked: {
                folderAppPickerPopup.visible = false
                if (rootItem._needsComboRebuild) {
                    rootItem._needsComboRebuild = false
                    rootItem.buildAllAppsCombo()
                }
            }
        }

        Item {
            id: folderAppPickerPopup
            visible: false
            z: 205
            width: 300
            height: 400

            property int folderIndex: -1

            function openForFolder(idx, px, py) {
                folderIndex = idx
                pickerSearchField.text = ""
                rebuildPickerModel()
                var popW = width, popH = height
                x = Math.max(4, Math.min(px - popW / 2, rootItem.width - popW - 4))
                var yAbove = py - popH - 4
                y = yAbove >= 4 ? yAbove : Math.min(py + 4, rootItem.height - popH - 4)
                y = Math.max(4, y)
                visible = true
                pickerSearchField.forceActiveFocus()
            }

            function rebuildPickerModel() {
                pickerAppsModel.clear()
                if (folderIndex < 0 || folderIndex >= rootItem.allAppsFoldersData.length) return
                var folder = rootItem.allAppsFoldersData[folderIndex]
                var folderItems = folder.items || []
                var otherIds = {}
                for (var fi = 0; fi < rootItem.allAppsFoldersData.length; fi++) {
                    if (fi === folderIndex) continue
                    var f = rootItem.allAppsFoldersData[fi]
                    if (f.items) for (var j = 0; j < f.items.length; j++) otherIds[f.items[j]] = true
                }
                for (var i = 0; i < sortedAppsModel.rowCount(); i++) {
                    var midx = sortedAppsModel.index(i, 0)
                    var fid = sortedAppsModel.data(midx, rootItem.kickerFavoriteIdRole) || ""
                    if (!fid || otherIds[fid]) continue
                    pickerAppsModel.append({
                        appName: sortedAppsModel.data(midx, rootItem.kickerDisplayRole) || rootItem.displayNameForId(fid),
                        appIcon: sortedAppsModel.data(midx, rootItem.kickerDecorationRole) || rootItem.iconForId(fid),
                        appId: fid,
                        inFolder: folderItems.indexOf(fid) >= 0
                    })
                }
            }

            function toggleApp(appId) {
                if (folderIndex < 0 || folderIndex >= rootItem.allAppsFoldersData.length) return
                var folders = rootItem.allAppsFoldersData.slice()
                var folder = folders[folderIndex]
                var items = (folder.items || []).slice()
                var pos = items.indexOf(appId)
                var nowIn = pos < 0
                if (pos >= 0) items.splice(pos, 1)
                else items.push(appId)
                folders[folderIndex] = { name: folder.name, items: items, createdAt: folder.createdAt || 0 }
                rootItem.allAppsFoldersData = folders
                rootItem.saveAllAppsFolders()
                for (var i = 0; i < pickerAppsModel.count; i++) {
                    var e = pickerAppsModel.get(i)
                    if (e.appId === appId) {
                        pickerAppsModel.set(i, { appName: e.appName, appIcon: e.appIcon, appId: appId, inFolder: nowIn })
                        break
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.18)

                Column {
                    id: pickerFrameCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Text {
                        width: parent.width
                        text: folderAppPickerPopup.folderIndex >= 0
                              && folderAppPickerPopup.folderIndex < rootItem.allAppsFoldersData.length
                              ? i18n("Add apps — %1", rootItem.allAppsFoldersData[folderAppPickerPopup.folderIndex].name)
                              : i18n("Add apps to folder")
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                        elide: Text.ElideRight
                    }

                    PC3.TextField {
                        id: pickerSearchField
                        width: parent.width
                        placeholderText: i18n("Filter…")
                        Keys.onEscapePressed: {
                            folderAppPickerPopup.visible = false
                            if (rootItem._needsComboRebuild) {
                                rootItem._needsComboRebuild = false
                                rootItem.buildAllAppsCombo()
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 310
                        color: root.colorWithAlpha(Kirigami.Theme.textColor, 0.04)
                        radius: Kirigami.Units.smallSpacing
                        clip: true

                        ListView {
                            id: pickerListView
                            anchors.fill: parent
                            anchors.margins: 2
                            model: pickerAppsModel
                            clip: true

                            PC3.ScrollBar.vertical: PC3.ScrollBar {
                                policy: pickerListView.contentHeight > pickerListView.height
                                        ? PC3.ScrollBar.AlwaysOn : PC3.ScrollBar.AlwaysOff
                                width: 6
                            }

                            delegate: Item {
                                readonly property bool matchesSearch: {
                                    var q = pickerSearchField.text.toLowerCase()
                                    return q === "" || model.appName.toLowerCase().indexOf(q) >= 0
                                }
                                width: pickerListView.width
                                height: matchesSearch ? Math.round(Kirigami.Units.gridUnit * 2.2) : 0
                                clip: true
                                visible: matchesSearch

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    radius: Kirigami.Units.smallSpacing
                                    color: pickerRowHover.containsMouse
                                           ? root.colorWithAlpha(Kirigami.Theme.highlightColor, 0.12)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }

                                Kirigami.Icon {
                                    id: pickerAppIcon
                                    anchors.left: parent.left
                                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: model.appIcon
                                    width: Kirigami.Units.iconSizes.small
                                    height: width
                                    animated: false
                                }

                                Text {
                                    anchors.left: pickerAppIcon.right
                                    anchors.leftMargin: Kirigami.Units.smallSpacing
                                    anchors.right: pickerCheckRect.left
                                    anchors.rightMargin: Kirigami.Units.smallSpacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: model.appName
                                    color: Kirigami.Theme.textColor
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    id: pickerCheckRect
                                    anchors.right: parent.right
                                    anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Kirigami.Units.gridUnit
                                    height: width
                                    radius: 3
                                    border.width: 1.5
                                    border.color: model.inFolder
                                                  ? Kirigami.Theme.highlightColor
                                                  : root.colorWithAlpha(Kirigami.Theme.textColor, 0.35)
                                    color: model.inFolder ? Kirigami.Theme.highlightColor : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    Behavior on border.color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: "white"
                                        font.pixelSize: parent.width * 0.62
                                        visible: model.inFolder
                                    }
                                }

                                MouseArea {
                                    id: pickerRowHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: folderAppPickerPopup.toggleApp(model.appId)
                                }
                            }
                        }
                    }
                }
            }

            ListModel { id: pickerAppsModel }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Control) {
                rootItem.ctrlHeld = true;
            }
            if (event.modifiers & Qt.ShiftModifier && event.text !== "") {
                searchField.focus = true;
                return;
            }
            // Ctrl+1..9 — quick-launch pinned apps on current page
            if (event.modifiers === Qt.ControlModifier) {
                var digit = event.key - Qt.Key_1;
                if (digit >= 0 && digit <= 8) {
                    var perPage = Plasmoid.configuration.numberColumns * Plasmoid.configuration.numberRows;
                    var appIdx = rootItem.pinnedCurrentPage * perPage + digit;
                    if (appIdx < globalFavorites.count) {
                        event.accepted = true;
                        rootItem.recordLaunch(globalFavorites.favorites[appIdx]);
                        globalFavorites.trigger(appIdx, "", null);
                        root.toggle();
                    }
                    return;
                }
            }
            // Alt+1-9 — quick-launch Nth search result
            if (view.currentIndex === 2 && event.modifiers === Qt.AltModifier) {
                var altDigit = event.key - Qt.Key_1;
                if (altDigit >= 0 && altDigit <= 8) {
                    event.accepted = true;
                    var resultCount = 0;
                    for (var si = 0; si < runnerGrid.count; si++) {
                        var sg = runnerGrid.subGridAt(si);
                        if (!sg) continue;
                        if (resultCount + sg.count > altDigit) {
                            var localIdx = altDigit - resultCount;
                            if ("trigger" in sg.model) {
                                sg.model.trigger(localIdx, "", null);
                                root.toggle();
                            }
                            return;
                        }
                        resultCount += sg.count;
                    }
                    return;
                }
            }

            if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
                event.accepted = true;
                searchField.focus = true;
                return;
            }
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                if (root.searching) {
                    reset();
                } else if (view.currentIndex === 1) {
                    view.currentIndex = 0;
                    searchField.focus = true;
                } else {
                    root.visible = false;
                }
                return;
            }

            if (searchField.focus) {
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                event.accepted = true;
                searchField.backspace();
            } else if (event.text !== "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

        Keys.onReleased: event => {
            if (event.key === Qt.Key_Control) {
                rootItem.ctrlHeld = false;
            }
        }
    }

    function setModels() {
        globalFavoritesGrid.model = globalFavorites;
        // Row order: [RecentApps(0), RecentDocs(1 if enabled), AllApps(1 or 2)]
        recentAppsListView.model = rootModel.modelForRow(0);
        var allAppsRow = Plasmoid.configuration.showRecentDocs ? 2 : 1;
        sortedAppsModel.sourceModel = rootModel.modelForRow(allAppsRow);
        allAppsGrid.model = allAppsComboModel;
        rootItem.buildAllAppsCombo();
        if (Plasmoid.configuration.showRecentDocs) {
            documentsGrid.model = rootModel.modelForRow(1);
        }
    }

    property bool categoryModelLoaded: false

    function setCategoryModel() {
        allAppsCategoryGrid.model = categoryRootModel;
    }

    function ensureCategoryModel() {
        if (!categoryModelLoaded) {
            categoryModelLoaded = true;
            categoryRootModel.appletInterface = kicker;
            categoryRootModel.refreshed.connect(setCategoryModel);
            categoryRootModel.refresh();
        }
    }

    function scrollToLetter(letter) {
        if (allAppsComboModel.count === 0) return;

        alphabetOverlay.currentLetter = letter;
        alphabetOverlay.opacity = 1;
        overlayTimer.restart();

        var targetIndex = -1;
        for (var i = 0; i < allAppsComboModel.count; i++) {
            var entry = allAppsComboModel.get(i);
            if (entry.indented) continue;  // skip expanded folder children
            var name = entry.display;
            if (name && name.length > 0) {
                var c = name[0].toUpperCase();
                if (letter === "#") {
                    if (c < "A" || c > "Z") { targetIndex = i; break; }
                } else if (c >= letter) {
                    targetIndex = i; break;
                }
            }
        }
        if (targetIndex < 0) return;

        var columns = Math.max(1, Math.floor(allAppsGrid.width / allAppsGrid.cellWidth));
        var targetY = Math.floor(targetIndex / columns) * allAppsGrid.cellHeight;
        var maxY = Math.max(0, allAppsGrid.contentHeight - allAppsGrid.height);
        targetY = Math.min(targetY, maxY);

        allAppsGrid.currentIndex = -1;
        letterScrollAnim.stop();
        letterScrollAnim.to = targetY;
        letterScrollAnim.start();
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(setModels);
        reset();
        rootModel.refresh();
    }
}
