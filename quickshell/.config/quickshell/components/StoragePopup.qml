import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorItem
    property string dataText: ""
    readonly property var stats: parseData(dataText)

    implicitWidth: 820
    implicitHeight: 520
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
        if (number >= 1099511627776) return (number / 1099511627776).toFixed(1) + " TiB"
        if (number >= 1073741824) return (number / 1073741824).toFixed(1) + " GiB"
        return (number / 1048576).toFixed(0) + " MiB"
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

            Text {
                text: "ストレージ使用状況"
                color: "#ff6b9d"
                font.family: "Comic Code Ligatures"
                font.pixelSize: 14
                font.bold: true
            }

            Text { text: "マウント済みファイルシステム"; color: "#f0e6eb"; font.pixelSize: 11; font.bold: true }

            Row {
                width: parent.width
                height: 145
                spacing: 9

                Repeater {
                    model: root.stats.mounts || []

                    Rectangle {
                        required property var modelData
                        width: Math.min(250, (parent.width - 18) / Math.max(1, Math.min(3, (root.stats.mounts || []).length)))
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
                                height: 24
                                Text { text: modelData.target; color: "#f0e6eb"; font.bold: true; font.pixelSize: 14 }
                                Text { anchors.right: parent.right; text: modelData.percent + "%"; color: "#ff6b9d"; font.bold: true; font.pixelSize: 13 }
                            }
                            Text { width: parent.width; text: modelData.source + "  ·  " + modelData.type; elide: Text.ElideMiddle; color: "#8f8490"; font.pixelSize: 9 }
                            MetricBar { width: parent.width; value: modelData.percent }
                            Text { text: root.bytes(modelData.used) + " used"; color: "#ded3da"; font.pixelSize: 10 }
                            Text { text: root.bytes(modelData.available) + " available of " + root.bytes(modelData.size); color: "#8f8490"; font.pixelSize: 9 }
                        }
                    }
                }
            }

            Text { text: "ブロックデバイス"; color: "#f0e6eb"; font.pixelSize: 11; font.bold: true }

            Rectangle {
                width: parent.width
                height: 265
                radius: 8
                color: "#191620"
                border.color: "#302735"

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 10
                    contentHeight: devices.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: devices
                        width: parent.width
                        spacing: 1

                        Repeater {
                            model: root.stats.devices || []

                            Rectangle {
                                required property var modelData
                                required property int index
                                width: parent.width
                                height: 29
                                radius: 5
                                color: index % 2 ? "#15121a" : "transparent"

                                Text {
                                    x: 8 + modelData.depth * 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (modelData.depth ? "↳  " : "󰋊  ") + modelData.name
                                    color: modelData.depth ? "#c8bbc3" : "#f0e6eb"
                                    font.pixelSize: 10
                                    font.bold: modelData.depth === 0
                                }
                                Text {
                                    x: 245
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.type + (modelData.fstype ? "  ·  " + modelData.fstype : "")
                                    color: "#8f8490"
                                    font.pixelSize: 9
                                }
                                Text {
                                    x: 480
                                    width: 170
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.mount || ""
                                    elide: Text.ElideMiddle
                                    color: "#8f8490"
                                    font.pixelSize: 9
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.bytes(modelData.size)
                                    color: "#ff6b9d"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
