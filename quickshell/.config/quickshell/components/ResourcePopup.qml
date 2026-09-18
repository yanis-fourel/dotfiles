import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorItem
    property string dataText: ""
    readonly property var stats: parseData(dataText)

    implicitWidth: 680
    implicitHeight: 485
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

    function bytes(value) {
        const number = Number(value || 0)
        if (number >= 1073741824) return (number / 1073741824).toFixed(1) + " GiB"
        return (number / 1048576).toFixed(0) + " MiB"
    }

    function percent(used, total) {
        return total > 0 ? Math.round(100 * used / total) : 0
    }

    function uptime(seconds) {
        let minutes = Math.floor(Number(seconds || 0) / 60)
        const days = Math.floor(minutes / 1440)
        minutes %= 1440
        const hours = Math.floor(minutes / 60)
        return (days ? days + "d " : "") + hours + "h " + (minutes % 60) + "m"
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#10131c"
        border.width: 1
        border.color: "#ff6b9d"

        Column {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 11

            Item {
                width: parent.width
                height: 25

                Text {
                    text: "システムリソース"
                    color: "#ff6b9d"
                    font.family: "Comic Code Ligatures"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    text: "稼働時間  " + root.uptime(root.stats.uptime)
                    color: "#8f8490"
                    font.family: "Comic Code Ligatures"
                    font.pixelSize: 10
                }
            }

            Row {
                width: parent.width
                height: 125
                spacing: 10

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: 8
                    color: "#191620"
                    border.color: "#302735"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 7

                        Item {
                            width: parent.width
                            height: 22
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "CPU"; color: "#f0e6eb"; font.bold: true; font.pixelSize: 12 }
                            Text {
                                anchors.right: parent.right
                                text: (root.stats.cpu ? root.stats.cpu.usage : 0) + "%"
                                color: "#ff6b9d"; font.bold: true; font.pixelSize: 16
                            }
                        }
                        MetricBar { width: parent.width; value: root.stats.cpu ? root.stats.cpu.usage : 0 }
                        Text {
                            width: parent.width
                            text: root.stats.cpu ? root.stats.cpu.model : "Loading…"
                            elide: Text.ElideRight; color: "#b9acb5"; font.pixelSize: 10
                        }
                        Text {
                            text: "Load  " + (root.stats.cpu ? root.stats.cpu.load.join("  ") : "—")
                                  + "     Temp  " + (root.stats.cpu && root.stats.cpu.temperature !== null ? root.stats.cpu.temperature + "°C" : "—")
                            color: "#8f8490"; font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: 8
                    color: "#191620"
                    border.color: "#302735"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 6
                        readonly property int memoryPercent: root.stats.memory ? root.percent(root.stats.memory.used, root.stats.memory.total) : 0
                        readonly property int swapPercent: root.stats.swap ? root.percent(root.stats.swap.used, root.stats.swap.total) : 0

                        Item {
                            width: parent.width
                            height: 16
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Memory"; color: "#f0e6eb"; font.bold: true; font.pixelSize: 11 }
                            Text { anchors.right: parent.right; text: parent.parent.memoryPercent + "%"; color: "#ff6b9d"; font.bold: true; font.pixelSize: 12 }
                        }
                        MetricBar { width: parent.width; value: parent.memoryPercent }
                        Text { text: root.stats.memory ? root.bytes(root.stats.memory.used) + " / " + root.bytes(root.stats.memory.total) : "Loading…"; color: "#8f8490"; font.pixelSize: 9 }
                        Item {
                            width: parent.width
                            height: 14
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Swap"; color: "#f0e6eb"; font.bold: true; font.pixelSize: 10 }
                            Text { anchors.right: parent.right; text: parent.parent.swapPercent + "%"; color: "#c099ff"; font.pixelSize: 10 }
                        }
                        MetricBar { width: parent.width; value: parent.swapPercent; accent: "#c099ff" }
                    }
                }
            }

            Row {
                width: parent.width
                height: 270
                spacing: 10

                ProcessList {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    heading: "CPUを使用しているプロセス"
                    entries: root.stats.topCpu || []
                    memoryMode: false
                }

                ProcessList {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    heading: "メモリを使用しているプロセス"
                    entries: root.stats.topMemory || []
                    memoryMode: true
                }
            }
        }
    }

    component ProcessList: Rectangle {
        property string heading: ""
        property var entries: []
        property bool memoryMode: false

        radius: 8
        color: "#191620"
        border.color: "#302735"

        Column {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 5

            Text {
                text: heading
                color: "#f0e6eb"
                font.family: "Comic Code Ligatures"
                font.pixelSize: 11
                font.bold: true
            }

            Rectangle { width: parent.width; height: 1; color: "#302735" }

            Repeater {
                model: entries
                Row {
                    required property var modelData
                    width: parent.width
                    height: 25

                    Column {
                        width: parent.width - 72
                        Text { width: parent.width; text: modelData.name; elide: Text.ElideRight; color: "#ded3da"; font.pixelSize: 10 }
                        Text { text: "PID " + modelData.pid; color: "#6f6670"; font.pixelSize: 8 }
                    }
                    Text {
                        width: 72
                        horizontalAlignment: Text.AlignRight
                        text: memoryMode ? root.bytes(modelData.memory) : Number(modelData.cpu).toFixed(1) + "%"
                        color: memoryMode ? "#c099ff" : "#ff6b9d"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }
    }
}
