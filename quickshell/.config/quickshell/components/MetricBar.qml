import QtQuick

Item {
    id: root
    property real value: 0
    property color accent: "#ff6b9d"

    implicitHeight: 7

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#29232e"

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.value)) / 100
            height: parent.height
            radius: height / 2
            color: root.value >= 90 ? "#ff5370" : (root.value >= 70 ? "#ffb366" : root.accent)

            Behavior on width { NumberAnimation { duration: 250 } }
        }
    }
}
