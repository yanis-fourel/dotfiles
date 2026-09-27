import QtQuick

StatusPill {
    id: root

    // Fixed UTC+7 endpoints keep progress unchanged across restarts/timezone changes.
    readonly property double startTime: Date.parse("2026-09-27T07:45:37+07:00")
    readonly property double endTime: Date.parse("2026-10-24T20:00:00+07:00")
    property double now: Date.now()
    readonly property real progress: Math.max(0, Math.min(1, (now - startTime) / (endTime - startTime)))

    text: String(Math.floor(1815 + (2000 - 1815) * progress))

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = Date.now()
    }
}
