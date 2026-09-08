import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorItem
    property string title: ""
    property string detailText: ""

    implicitWidth: 430
    implicitHeight: Math.min(360, Math.max(120, content.implicitHeight + 28))
    color: "transparent"
    grabFocus: true

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 5

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: "#10131c"
        border.width: 1
        border.color: "#ff6b9d"

        Flickable {
            anchors.fill: parent
            anchors.margins: 14
            contentWidth: width
            contentHeight: content.implicitHeight
            clip: true

            Column {
                id: content
                width: parent.width
                spacing: 10

                Text {
                    text: root.title
                    color: "#ff6b9d"
                    font.family: "Comic Code Ligatures"
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: root.detailText
                    color: "#f0e6eb"
                    font.family: "Comic Code Ligatures"
                    font.pixelSize: 11
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
