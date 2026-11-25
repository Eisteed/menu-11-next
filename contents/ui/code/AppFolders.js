/*
 * Folder/model helpers for MenuRepresentation.qml.
 *
 * Deliberately NOT a .pragma library: this file is instantiated in the
 * importing component's scope, so it can still use Plasmoid, rootItem and
 * the QML models/properties it operates on. Extraction keeps the 3k-line
 * monolith smaller without changing behavior.
 */

function loadFolders() {
    var raw = cfg.pinnedFolders;
    if (!raw || raw.length === 0) { rootItem.pinnedFoldersData = []; return; }
    try { rootItem.pinnedFoldersData = JSON.parse(raw); } catch(e) { rootItem.pinnedFoldersData = []; }
}

function saveFolders() {
    cfg.pinnedFolders = JSON.stringify(rootItem.pinnedFoldersData);
}

function loadAllAppsFolders() {
    var raw = cfg.allAppsFolders;
    if (!raw || raw.length === 0) { rootItem.allAppsFoldersData = []; return; }
    try { rootItem.allAppsFoldersData = JSON.parse(raw); } catch(e) { rootItem.allAppsFoldersData = []; }
}

function saveAllAppsFolders() {
    cfg.allAppsFolders = JSON.stringify(rootItem.allAppsFoldersData);
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

// Kicker role IDs (from plasma-workspace/applets/kicker/actionlist.h)
function lookupAppInfo(favId) {
    for (var i = 0; i < sortedAppsModel.rowCount(); i++) {
        var midx = sortedAppsModel.index(i, 0);
        if (sortedAppsModel.data(midx, rootItem.kickerFavoriteIdRole) === favId) {
            return {
                name:        sortedAppsModel.data(midx, rootItem.kickerDisplayRole)    || displayNameForId(favId),
                decoration:  sortedAppsModel.data(midx, rootItem.kickerDecorationRole) || iconForId(favId),
                description: sortedAppsModel.data(midx, rootItem.kickerDescriptionRole) || ""
            };
        }
    }
    return { name: displayNameForId(favId), decoration: iconForId(favId), description: "" };
}

function buildAllAppsCombo() {
    allAppsComboModel.clear();
    if (!sortedAppsModel.sourceModel) return;

    var displayRole    = rootItem.kickerDisplayRole;
    var decorationRole = rootItem.kickerDecorationRole;
    var favoriteIdRole = rootItem.kickerFavoriteIdRole;
    var descRole       = rootItem.kickerDescriptionRole;
    var urlRole        = rootItem.kickerUrlRole;
    var folders        = rootItem.allAppsFoldersData;
    var sortMode       = cfg.allAppsSortMode;

    var folderedIds = {};
    for (var fi = 0; fi < folders.length; fi++) {
        var fd0 = folders[fi];
        if (fd0.items) {
            for (var ai0 = 0; ai0 < fd0.items.length; ai0++) folderedIds[fd0.items[ai0]] = fi;
        }
    }

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

    var folderRows = [];
    for (var fi2 = 0; fi2 < folders.length; fi2++) {
        var fd2 = folders[fi2];
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

    if (sortMode === 0 || sortMode === 4)
        folderRows.sort(function(a, b) { return a.display.localeCompare(b.display); });
    else if (sortMode === 1)
        folderRows.sort(function(a, b) { return b.display.localeCompare(a.display); });
    else if (sortMode === 2)
        folderRows.sort(function(a, b) { return (folders[b.folderIdx].createdAt||0) - (folders[a.folderIdx].createdAt||0); });
    else if (sortMode === 3)
        folderRows.sort(function(a, b) { return (folders[a.folderIdx].createdAt||0) - (folders[b.folderIdx].createdAt||0); });

    var combined = [];
    if (sortMode === 4) {
        combined = folderRows.concat(appRows);
    } else if (sortMode === 0 || sortMode === 1) {
        var ai = 0, fri = 0;
        while (ai < appRows.length && fri < folderRows.length) {
            var cmp = appRows[ai].display.localeCompare(folderRows[fri].display);
            if ((sortMode === 0 && cmp <= 0) || (sortMode === 1 && cmp >= 0)) combined.push(appRows[ai++]);
            else combined.push(folderRows[fri++]);
        }
        while (ai < appRows.length)   combined.push(appRows[ai++]);
        while (fri < folderRows.length) combined.push(folderRows[fri++]);
    } else {
        combined = (sortMode === 2) ? folderRows.concat(appRows) : appRows.concat(folderRows);
    }

    for (var ci = 0; ci < combined.length; ci++) allAppsComboModel.append(combined[ci]);
}

function toggleFolderExpand(folderComboIdx) {
    if (folderComboIdx < 0 || folderComboIdx >= allAppsComboModel.count) return;
    var entry = allAppsComboModel.get(folderComboIdx);
    if (entry.itemType !== "folder") return;
    var fi = entry.folderIdx;
    var folders = rootItem.allAppsFoldersData;
    if (fi < 0 || fi >= folders.length) return;
    var folder = folders[fi];

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
