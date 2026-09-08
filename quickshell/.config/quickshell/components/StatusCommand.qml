import QtQuick
import Quickshell.Io

// Small polling adapter for status values that do not need a full QML service.
QtObject {
    id: root

    property var command: []
    property int interval: 5000
    property bool enabled: true
    property string output: ""

    function refresh() {
        if (!process.running && root.command.length > 0)
            process.running = true
    }

    property Process process: Process {
        id: process
        command: root.command
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.output = text.trim()
        }
    }

    property Timer timer: Timer {
        interval: root.interval
        repeat: true
        running: root.enabled
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
