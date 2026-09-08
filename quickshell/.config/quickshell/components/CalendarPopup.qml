import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorItem
    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property var monthNames: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"]
    readonly property var weekdays: ["日", "月", "火", "水", "木", "金", "土"]
    readonly property int firstWeekday: new Date(viewYear, viewMonth, 1).getDay()
    readonly property int daysInMonth: new Date(viewYear, viewMonth + 1, 0).getDate()

    implicitWidth: 294
    implicitHeight: 300
    color: "transparent"
    grabFocus: true

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 5

    function stepMonth(delta) {
        const target = new Date(viewYear, viewMonth + delta, 1)
        viewYear = target.getFullYear()
        viewMonth = target.getMonth()
    }

    function resetToToday() {
        today = new Date()
        viewYear = today.getFullYear()
        viewMonth = today.getMonth()
    }

    onVisibleChanged: if (visible) resetToToday()

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: "#10131c"
        border.width: 1
        border.color: "#ff6b9d"

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            Item {
                width: parent.width
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: root.viewYear + "年 " + root.monthNames[root.viewMonth]
                    color: "#f0e6eb"
                    font.family: "Comic Code Ligatures"
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "‹"
                    color: "#ff6b9d"
                    font.pixelSize: 23
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.stepMonth(-1) }
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›"
                    color: "#ff6b9d"
                    font.pixelSize: 23
                    MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.stepMonth(1) }
                }
            }

            Grid {
                width: parent.width
                columns: 7
                rowSpacing: 3
                columnSpacing: 3

                Repeater {
                    model: root.weekdays
                    Text {
                        required property string modelData
                        width: 35
                        height: 21
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: modelData === "日" ? "#ff6b9d" : (modelData === "土" ? "#7aa2f7" : "#a99da5")
                        font.family: "Comic Code Ligatures"
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property int day: index - root.firstWeekday + 1
                        readonly property bool validDay: day >= 1 && day <= root.daysInMonth
                        readonly property bool isToday: validDay
                                                        && root.viewYear === root.today.getFullYear()
                                                        && root.viewMonth === root.today.getMonth()
                                                        && day === root.today.getDate()
                        width: 35
                        height: 29
                        radius: 7
                        color: isToday ? "#ff6b9d" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: parent.validDay ? parent.day : ""
                            color: parent.isToday ? "#0a0e18" : "#f0e6eb"
                            font.family: "Comic Code Ligatures"
                            font.pixelSize: 11
                            font.bold: parent.isToday
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "今日に戻る"
                color: "#a99da5"
                font.family: "Comic Code Ligatures"
                font.pixelSize: 10
                MouseArea { anchors.fill: parent; anchors.margins: -5; onClicked: root.resetToToday() }
            }
        }
    }
}
