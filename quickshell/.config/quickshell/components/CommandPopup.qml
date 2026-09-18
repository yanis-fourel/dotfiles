import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: root
    required property var anchorItem
    property string tool: ""
    property string message: ""
    property alias commandText: input.text
    property bool busy: false
    signal submitted(string command)
    implicitWidth: 480
    implicitHeight: 220
    color: "transparent"
    grabFocus: true
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 5
    onVisibleChanged: if (visible) input.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#10131c"
        border.color: "#ff6b9d"
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            Text {
                text: "Choose a command · " + root.tool
                color: "#ff6b9d"
                font.pixelSize: 17
            }
            Text {
                width: parent.width
                text: root.message
                textFormat: Text.PlainText
                color: "#f0e6eb"
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            TextField {
                id: input
                width: parent.width
                placeholderText: "Executable and arguments (quote paths with spaces)"
                enabled: !root.busy
                onAccepted: if (text.trim()) root.submitted(text)
            }
            Row {
                spacing: 10
                Button {
                    text: root.busy ? "Launching…" : "Launch & remember"
                    enabled: !root.busy && input.text.trim().length > 0
                    onClicked: root.submitted(input.text)
                }
                Button {
                    text: "Cancel"
                    onClicked: root.visible = false
                }
            }
        }
    }
}
