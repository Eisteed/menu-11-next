/*
 * Launch-frequency / workflow helpers for MenuRepresentation.qml.
 * See AppFolders.js for why this is not a .pragma library.
 */

function loadLaunchCounts() {
    var raw = cfg.appLaunchCounts;
    if (!raw || raw.length === 0) { rootItem.launchCounts = ({}); return; }
    try { rootItem.launchCounts = JSON.parse(raw); } catch(e) { rootItem.launchCounts = ({}); }
}

function saveLaunchCounts() {
    cfg.appLaunchCounts = JSON.stringify(rootItem.launchCounts);
}

// "day-slot": 0=Sun..6=Sat, slot 0=night, 1=morning, 2=afternoon, 3=evening
function currentBucket() {
    var now = new Date();
    var day = now.getDay();
    var h = now.getHours();
    var slot = h < 6 ? 0 : h < 12 ? 1 : h < 18 ? 2 : 3;
    return day + "-" + slot;
}

// 0-10 score for how strongly an app matches the current time/day slot
function workflowScore(appId) {
    if (!appId) return 0;
    var entry = rootItem.launchCounts[appId];
    if (!entry || typeof entry !== "object") return 0;
    var bucketCount = (entry.buckets && entry.buckets[currentBucket()]) || 0;
    var total = entry.total || 1;
    return Math.round((bucketCount / total) * 10);
}

function recordLaunch(appId) {
    if (!appId || appId === "") return;
    var updated = JSON.parse(JSON.stringify(rootItem.launchCounts));
    var bucket = currentBucket();
    var prev = updated[appId];
    // Migrate legacy plain-number entries to the new schema
    var prevTotal = (typeof prev === "number") ? prev : (prev && prev.total ? prev.total : 0);
    var prevBuckets = (prev && typeof prev === "object" && prev.buckets) ? prev.buckets : {};
    prevBuckets[bucket] = (prevBuckets[bucket] || 0) + 1;
    updated[appId] = { total: prevTotal + 1, buckets: prevBuckets };
    rootItem.launchCounts = updated;
    saveLaunchCounts();
}

function computeContextLabel() {
    var counts = rootItem.launchCounts;
    var hasWorkflow = false;
    for (var id in counts) {
        if (workflowScore(id) >= 6) { hasWorkflow = true; break; }
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
    var topCount = 0;
    for (var aid in counts) {
        var entry = counts[aid];
        var t = (entry && typeof entry === "object") ? (entry.total || 0) : (entry || 0);
        if (t > topCount) topCount = t;
    }
    if (topCount >= 10) return i18n("Your top picks");
    if (topCount >= 5)  return i18n("Frequently used");
    var hour = new Date().getHours();
    if (hour >= 5  && hour < 9)  return i18n("Your morning session");
    if (hour >= 9  && hour < 12) return i18n("Good morning apps");
    if (hour >= 12 && hour < 14) return i18n("Midday picks");
    if (hour >= 14 && hour < 18) return i18n("Afternoon session");
    if (hour >= 18 && hour < 21) return i18n("Evening apps");
    return i18n("Late night");
}
