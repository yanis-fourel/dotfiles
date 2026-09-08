import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorItem
    property string dataText: ""
    property double nowMs: Date.now()
    readonly property var stats: parseData(dataText)

    signal refreshRequested()

    implicitWidth: 470
    implicitHeight: 550
    color: "transparent"
    grabFocus: true

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 5

    function parseData(value) {
        try { return JSON.parse(value || "{}") }
        catch (_) { return {} }
    }

    function duration(seconds) {
        let minutes = Math.max(0, Math.floor(Number(seconds || 0) / 60))
        const days = Math.floor(minutes / 1440)
        minutes %= 1440
        const hours = Math.floor(minutes / 60)
        if (days > 0) return days + "d " + hours + "h"
        if (hours > 0) return hours + "h " + (minutes % 60) + "m"
        return Math.max(1, minutes) + "m"
    }

    function resetText(epochSeconds) {
        if (!epochSeconds) return "Reset time unavailable"
        const remaining = Number(epochSeconds) * 1000 - nowMs
        return remaining > 0 ? "Resets in " + duration(remaining / 1000) : "Resetting now"
    }

    function updatedText(value) {
        const timestamp = new Date(value || "").getTime()
        if (!isFinite(timestamp)) return ""
        const seconds = Math.max(0, Math.floor((nowMs - timestamp) / 1000))
        if (seconds < 60) return "Updated just now"
        return "Updated " + duration(seconds) + " ago"
    }

    onVisibleChanged: if (visible) nowMs = Date.now()

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#10131c"
        border.width: 1
        border.color: "#ff6b9d"

        Flickable {
            anchors.fill: parent
            anchors.margins: 15
            contentHeight: content.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 12

                Item {
                    width: parent.width
                    height: 48

                    Rectangle {
                        width: 38
                        height: 38
                        radius: 9
                        color: "#ff6b9d"
                        Text {
                            anchors.centerIn: parent
                            text: "󱚣"
                            color: "#10131c"
                            font.family: "Comic Code Ligatures"
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }

                    Column {
                        x: 48
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { text: "OpenAI Codex"; color: "#f0e6eb"; font.pixelSize: 15; font.bold: true }
                        Text {
                            text: root.stats.ok ? String(root.stats.plan || "Subscription") : "Usage unavailable"
                            color: root.stats.ok ? "#ff6b9d" : "#ffb366"
                            font.pixelSize: 10
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: refreshLabel.implicitWidth + 16
                        height: 25
                        radius: 6
                        color: refreshMouse.containsMouse ? "#2a2230" : "#191620"
                        border.color: "#3a303f"
                        Text { id: refreshLabel; anchors.centerIn: parent; text: "↻  Refresh"; color: "#b9acb5"; font.pixelSize: 9 }
                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshRequested()
                        }
                    }
                }

                Rectangle {
                    visible: !root.stats.ok && String(root.stats.error || "") !== ""
                    width: parent.width
                    height: errorColumn.implicitHeight + 22
                    radius: 8
                    color: "#261820"
                    border.color: "#704052"
                    Column {
                        id: errorColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 11
                        spacing: 5
                        Text { text: root.stats.error || ""; color: "#ffb366"; font.pixelSize: 11; font.bold: true }
                        Text { width: parent.width; text: root.stats.hint || ""; color: "#a99da5"; font.pixelSize: 9; wrapMode: Text.WordWrap }
                    }
                }

                Text {
                    visible: root.stats.ok === true
                    text: "SUBSCRIPTION LIMITS"
                    color: "#8f8490"
                    font.pixelSize: 9
                    font.bold: true
                }

                Repeater {
                    model: root.stats.limits || []

                    Rectangle {
                        required property var modelData
                        width: content.width
                        height: 73
                        radius: 8
                        color: "#191620"
                        border.color: modelData.usedPercent >= 90 ? "#704052" : "#302735"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    anchors.left: parent.left
                                    anchors.right: percentLabel.left
                                    anchors.rightMargin: 8
                                    text: (modelData.group === "Codex" ? "" : modelData.group + "  ·  ") + modelData.label
                                    elide: Text.ElideRight
                                    color: "#ded3da"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    id: percentLabel
                                    anchors.right: parent.right
                                    text: Math.round(Number(modelData.usedPercent || 0)) + "% used"
                                    color: modelData.usedPercent >= 90 ? "#ff5370" : "#ff6b9d"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            MetricBar { width: parent.width; value: Number(modelData.usedPercent || 0) }
                            Text { text: root.resetText(modelData.resetAt); color: "#8f8490"; font.pixelSize: 9 }
                        }
                    }
                }

                Rectangle {
                    visible: root.stats.ok === true && !root.stats.sessionWindowReported
                    width: parent.width
                    height: 39
                    radius: 7
                    color: "#15121a"
                    border.color: "#302735"
                    Text {
                        anchors.centerIn: parent
                        text: "No 5h window is currently reported for the main Codex allowance."
                        color: "#8f8490"
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    visible: root.stats.ok === true
                    width: parent.width
                    height: 67
                    radius: 8
                    color: "#191620"
                    border.color: "#302735"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        Item {
                            width: parent.width
                            height: 16
                            Text { text: "ACCOUNT"; color: "#8f8490"; font.pixelSize: 9; font.bold: true }
                            Text {
                                anchors.right: parent.right
                                text: root.stats.allowed ? "Ready" : "Limit reached"
                                color: root.stats.allowed ? "#77dba3" : "#ff5370"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                        Text {
                            text: {
                                const credits = root.stats.credits || {}
                                if (credits.unlimited) return "Extra credits: unlimited"
                                if (credits.available) return "Extra credit balance: $" + credits.balance
                                return "Extra credits: not enabled"
                            }
                            color: "#b9acb5"
                            font.pixelSize: 9
                        }
                        Text {
                            visible: Number(root.stats.resetCredits || 0) > 0
                            text: "Rate-limit resets available: " + root.stats.resetCredits
                            color: "#b9acb5"
                            font.pixelSize: 9
                        }
                    }
                }

                Text {
                    visible: String(root.stats.updatedAt || "") !== ""
                    width: parent.width
                    text: root.updatedText(root.stats.updatedAt)
                    horizontalAlignment: Text.AlignHCenter
                    color: "#6f6670"
                    font.pixelSize: 8
                }
            }
        }
    }
}
