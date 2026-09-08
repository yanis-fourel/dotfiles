import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
    id: root

    required property var barWindow
    spacing: 5

    Repeater {
        model: SystemTray.items

        Item {
            id: trayItem
            required property var modelData

            visible: modelData.status !== Status.Passive
            width: visible ? 19 : 0
            height: 22

            Image {
                anchors.centerIn: parent
                width: 15
                height: 15
                source: String(parent.modelData.icon || "")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                anchor.window: root.barWindow
                anchor.item: trayItem
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                        if (trayItem.modelData.hasMenu)
                            menuAnchor.open()
                    } else if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.secondaryActivate()
                    } else {
                        trayItem.modelData.activate()
                    }
                }
                onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
            }
        }
    }
}
