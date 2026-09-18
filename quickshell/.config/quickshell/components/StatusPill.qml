import QtQuick

Rectangle {
    id: root

    property string text: ""
    property string tooltip: ""
    property color foreground: "#f0e6eb"
    property bool warning: false
    property bool critical: false
    property bool clickable: false

    signal clicked(var mouse)
    signal wheel(var wheel)

    visible: text.length > 0
    implicitWidth: visible ? label.implicitWidth + 12 : 0
    implicitHeight: 22
    radius: 6
    color: mouseArea.containsMouse ? "#2a2230" : "#1a1418"
    border.width: 1
    border.color: critical ? "#ff0080" : (warning ? "#ffb366" : "#332633")

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.critical ? "#ff6b9d" : (root.warning ? "#ffb366" : root.foreground)
        font.family: "Comic Code Ligatures"
        font.pixelSize: 10
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
