.pragma library

var updateCheckUrl = "https://api.github.com/repos/Eisteed/menu-11-next/releases/latest";

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
            error: "Network error: " + (xhr.statusText || "Connection failed")
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

function shouldCheckForUpdates(plasmoidConfig) {
    // Get last check time from configuration (or default to 0)
    var lastCheckTime = plasmoidConfig.lastUpdateCheckTime || 0;
    var now = Math.floor(Date.now() / 1000); // Current time in seconds
    var checkInterval = 24 * 60 * 60; // 24 hours in seconds (1 day)

    // Return true only if enough time has passed
    return (now - lastCheckTime) > checkInterval;
}

function recordLastCheckTime(plasmoidConfig) {
    // Save current time to configuration
    plasmoidConfig.lastUpdateCheckTime = Math.floor(Date.now() / 1000);
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
