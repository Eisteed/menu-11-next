/*
 * SharedConfig.qml
 *
 * Plasma stores plasmoid configuration per applet instance. This component
 * mirrors a curated set of keys into one shared file
 *   ~/.config/swin11-shared.conf
 * so that several Swin-11 widgets on different panels stay in sync.
 *
 * The sync toggle itself is intentionally NOT in the key list, so each panel
 * instance can opt out independently.
 */

import QtQuick 2.15
import QtCore
import Qt.labs.platform 1.1 as Labs
import org.kde.plasma.plasmoid

Item {
    id: sharedConfig

    property bool syncEnabled: true

    readonly property url fileUrl: Labs.StandardPaths.writableLocation(Labs.StandardPaths.ConfigLocation).toString() + "/swin11-shared.conf"

    // Keys mirrored across instances. Migration/throttle markers and the
    // per-instance sync switch are deliberately excluded.
    readonly property var keys: [
        "appsIconSize", "docsIconSize", "displayPosition", "icon",
        "useCustomButtonImage", "customButtonImage", "showFilterList",
        "appNameFormat", "limitDepth", "numberColumns", "numberRows",
        "favoriteApps", "favoriteSystemActions", "hiddenApplications",
        "useExtraRunners", "labels2lines", "extraRunners",
        "alignResultsToBottom", "switchCategoriesOnHover",
        "removeApplicationCommand", "showAtCenter", "viewUser",
        "allAppsViewMode", "allAppsSortMode", "showRecentDocs",
        "showRecentApps", "enableShellRunner", "showSleepButton",
        "showRestartButton", "showShutdownButton", "pinnedFolders",
        "showQuickActions", "showWeather", "weatherLocation",
        "weatherLatitude", "weatherLongitude", "appLaunchCounts",
        "allAppsFolders"
    ]

    property string _lastShared: ""
    property string _lastLocal: ""

    // Writer. Kept alive for the lifetime of the applet.
    Settings {
        id: store
        location: sharedConfig.fileUrl
        property string payload: ""
    }

    // QSettings caches file contents, so re-create a reader whenever we need
    // a fresh view of what another panel instance wrote.
    function readSharedPayload() {
        var qml = 'import QtQuick 2.15; import QtCore; '
                + 'Settings { location: ' + JSON.stringify(sharedConfig.fileUrl.toString())
                + '; property string payload: "" }';
        var reader = Qt.createQmlObject(qml, sharedConfig, "SharedConfigReader");
        var value = reader ? reader.payload : "";
        if (reader)
            reader.destroy();
        return value;
    }

    function readShared() {
        var raw = readSharedPayload();
        if (!raw)
            return null;
        try {
            return JSON.parse(raw);
        } catch (e) {
            console.warn("[ConfigSync] Malformed shared config, reinitializing");
            return null;
        }
    }

    function localConfig() {
        var obj = {};
        for (var i = 0; i < sharedConfig.keys.length; i++) {
            var key = sharedConfig.keys[i];
            obj[key] = Plasmoid.configuration[key];
        }
        return obj;
    }

    function applyShared(shared) {
        for (var i = 0; i < sharedConfig.keys.length; i++) {
            var key = sharedConfig.keys[i];
            if (shared[key] !== undefined && Plasmoid.configuration[key] !== shared[key])
                Plasmoid.configuration[key] = shared[key];
        }
    }

    function initialize() {
        var shared = readShared();
        if (!shared) {
            shared = localConfig();
            store.payload = JSON.stringify(shared);
        } else {
            applyShared(shared);
        }
        _lastShared = JSON.stringify(shared);
        _lastLocal = JSON.stringify(localConfig());
    }

    function tick() {
        if (!sharedConfig.syncEnabled)
            return;

        var shared = readShared();
        if (!shared) {
            initialize();
            return;
        }

        var sharedSig = JSON.stringify(shared);
        var local = localConfig();
        var localSig = JSON.stringify(local);

        if (sharedSig !== _lastShared) {
            console.log("[ConfigSync] Applying settings from another panel instance");
            applyShared(shared);
            _lastLocal = JSON.stringify(localConfig());
            _lastShared = sharedSig;
        } else if (localSig !== _lastLocal) {
            for (var i = 0; i < sharedConfig.keys.length; i++)
                shared[sharedConfig.keys[i]] = local[sharedConfig.keys[i]];
            var sig = JSON.stringify(shared);
            console.log("[ConfigSync] Publishing settings to shared store");
            store.payload = sig;
            _lastShared = sig;
            _lastLocal = localSig;
        }
    }

    Timer {
        interval: 2000
        running: sharedConfig.syncEnabled
        repeat: true
        onTriggered: sharedConfig.tick()
    }

    Component.onCompleted: {
        if (sharedConfig.syncEnabled)
            initialize();
    }

    onSyncEnabledChanged: {
        if (sharedConfig.syncEnabled)
            initialize();
    }
}
