import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: root
    required property var anchorItem
    property string heading: ""
    property string detail: ""
    property var actions: []
    property var toolbarActions: []
    signal actionTriggered(string action)

    implicitWidth: 460
    implicitHeight: 440
    color: "transparent"
    grabFocus: true
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 5

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#10131c"
        border.color: "#ff6b9d"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 16
            contentWidth: availableWidth
            clip: true

            Column {
                width: parent.width
                spacing: 12
                Text {
                    width: parent.width
                    text: root.heading
                    color: "#ff6b9d"
                    font.pixelSize: 17
                    font.bold: true
                    wrapMode: Text.Wrap
                }
                Text {
                    width: parent.width
                    text: root.detail
                    textFormat: Text.PlainText
                    color: "#f0e6eb"
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
                Row {
                    spacing: 10
                    visible: root.toolbarActions.length > 0
                    Repeater {
                        model: root.toolbarActions
                        Rectangle {
                            id: toolButton
                            required property var modelData
                            implicitWidth: toolLabel.implicitWidth + 22
                            implicitHeight: 30
                            radius: 6
                            color: modelData.primary ? (toolMouse.containsMouse ? "#ff8ab2" : "#ff6b9d") : (toolMouse.containsMouse ? "#29202c" : "transparent")
                            border.color: modelData.primary ? "transparent" : "#665065"
                            Text {
                                id: toolLabel
                                anchors.centerIn: parent
                                text: toolButton.modelData.label
                                color: toolButton.modelData.primary ? "#10131c" : "#e5b4cb"
                                font.pixelSize: 12
                                font.bold: true
                            }
                            MouseArea {
                                id: toolMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.actionTriggered(toolButton.modelData.action || toolButton.modelData.url)
                            }
                        }
                    }
                }
                Repeater {
                    model: root.actions
                    Rectangle {
                        id: button
                        required property var modelData
                        width: parent.width
                        implicitHeight: label.implicitHeight + 18
                        radius: 6
                        color: mouse.containsMouse ? "#392536" : "#211c29"
                        Text {
                            id: label
                            anchors.centerIn: parent
                            width: parent.width - 20
                            text: button.modelData.label
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            color: "#f0e6eb"
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.actionTriggered(button.modelData.action || button.modelData.url)
                        }
                    }
                }
            }
        }
    }
}
