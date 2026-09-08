import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: root
    spacing: 3

    function workspace(id) {
        const values = Hyprland.workspaces.values
        for (let i = 0; i < values.length; ++i) {
            if (values[i].id === id)
                return values[i]
        }
        return null
    }

    Repeater {
        // Keep the usual first five available and reveal 6–10 when occupied.
        model: 10

        Rectangle {
            required property int index
            readonly property int workspaceId: index + 1
            readonly property var workspaceObject: root.workspace(workspaceId)
            readonly property bool focused: Hyprland.focusedWorkspace !== null
                                                && Hyprland.focusedWorkspace.id === workspaceId
            readonly property bool occupied: workspaceObject !== null
                                                && workspaceObject.toplevels.values.length > 0

            visible: workspaceId <= 5 || occupied || focused
            implicitWidth: visible ? 21 : 0
            implicitHeight: 21
            radius: 6
            color: focused ? "#ff6b9d" : (mouseArea.containsMouse ? "#2a2230" : "transparent")

            Text {
                anchors.centerIn: parent
                text: parent.workspaceId === 10 ? "0" : parent.workspaceId
                color: parent.focused ? "#0a0e18" : "#d0c0c8"
                opacity: parent.occupied || parent.focused ? 1 : 0.55
                font.family: "Comic Code Ligatures"
                font.pixelSize: 10
                font.bold: parent.focused
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([
                    "hyprctl", "dispatch", "workspace", String(parent.workspaceId)
                ])
            }
        }
    }
}
