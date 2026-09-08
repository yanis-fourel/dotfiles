import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

ShellRoot {
    id: root

    readonly property color foreground: "#f0e6eb"
    readonly property color background: "#0a0e18"
    readonly property color accent: "#ff6b9d"

    function percentage(value) {
        const match = String(value).match(/([0-9]+)%/)
        return match ? Number(match[1]) : -1
    }

    function temperatureValue(value) {
        const match = String(value).match(/([0-9]+)°/)
        return match ? Number(match[1]) : -1
    }

    StatusCommand {
        id: submap
        interval: 750
        command: ["bash", "-lc", "s=$(hyprctl submap 2>/dev/null); case \"$s\" in ''|default|reset) ;; *) printf '󰌌 %s' \"$s\";; esac"]
    }

    StatusCommand {
        id: audio
        interval: 2000
        command: ["bash", "-lc", "v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || exit; p=$(awk -v v=\"$(printf '%s' \"$v\" | awk '{print $2}')\" 'BEGIN { printf \"%.0f\", v*100 }'); if printf '%s' \"$v\" | grep -q MUTED; then printf '󰖁 %s%%' \"$p\"; else printf '󰕾 %s%%' \"$p\"; fi"]
    }

    StatusCommand {
        id: network
        interval: 5000
        // This machine uses iwd directly, but retain a generic default-route
        // fallback for wired links and other network managers.
        command: ["bash", "-lc", "wifi=$(iw dev 2>/dev/null | awk '$1==\"Interface\" {d=$2} $1==\"ssid\" {print d; exit}'); if [ -n \"$wifi\" ]; then sig=$(awk -v d=\"$wifi\" '$1 ~ (\"^\" d \":\") {printf \"%.0f\", $3*100/70}' /proc/net/wireless); [ \"${sig:-0}\" -gt 100 ] && sig=100; printf '󰖩 %s%%' \"${sig:-0}\"; else dev=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}'); if [ -n \"$dev\" ]; then printf '󰈀 %s' \"$dev\"; else printf '󰖪 offline'; fi; fi"]
    }

    StatusCommand {
        id: memory
        interval: 5000
        command: ["bash", "-lc", "free -b | awk '/^Mem:/ {printf \"󰍛 %.1fG\", $3/1073741824}'"]
    }

    StatusCommand {
        id: memoryDetails
        interval: 5000
        command: ["bash", "-lc", "free -h | awk 'NR==1 {printf \"%-9s %8s %8s %8s %8s\\n\",\"\",$2,$3,$4,$7} NR==2 {printf \"%-9s %8s %8s %8s %8s  (%d%% used)\\n\",\"Memory\",$2,$3,$4,$7,$3/$2*100} NR==3 {p=$2 ? $3/$2*100 : 0; printf \"%-9s %8s %8s %8s           (%d%% used)\\n\",\"Swap\",$2,$3,$4,p}'; printf '\\nLargest processes by resident memory:\\n'; ps -eo comm,rss --sort=-rss | awk 'NR==1 {printf \"%-24s %s\\n\",$1,\"MEM\"} NR>1 && NR<9 {printf \"%-24s %.1f MiB\\n\",$1,$2/1024}'"]
    }

    StatusCommand {
        id: disk
        interval: 30000
        command: ["bash", "-lc", "df -P \"$HOME\" | awk 'NR==2 {printf \"󰋊 %s\", $5}'"]
    }

    StatusCommand {
        id: diskDetails
        interval: 15000
        command: ["bash", "-lc", "printf 'Mounted filesystems:\\n'; df -hT -x tmpfs -x devtmpfs | awk 'NR==1 {printf \"%-15s %-7s %7s %7s %7s %5s  %s\\n\",$1,$2,$3,$4,$5,$6,$7} NR>1 {printf \"%-15s %-7s %7s %7s %7s %5s  %s\\n\",$1,$2,$3,$4,$5,$6,$7}'; printf '\\nBlock devices:\\n'; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS --noheadings"]
    }

    StatusCommand {
        id: temperature
        interval: 5000
        command: ["bash", "-lc", "sensors 2>/dev/null | awk '/Package id 0:/ {v=$4} /^Tctl:|^Tdie:/ {v=$2} v != \"\" {gsub(/[+°C]/,\"\",v); printf \"󰈸 %.0f°\", v; exit}'"]
    }

    StatusCommand {
        id: battery
        interval: 10000
        command: ["bash", "-lc", "b=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit); [ -n \"$b\" ] || exit 0; p=$(cat \"$b/capacity\"); s=$(cat \"$b/status\"); case \"$s\" in Charging|Full) i=󰂄;; *) i=󰂎;; esac; printf '%s %s%%' \"$i\" \"$p\""]
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData

                screen: modelData
                implicitHeight: 27
                color: "transparent"
                exclusionMode: ExclusionMode.Auto
                WlrLayershell.layer: WlrLayer.Top
                anchors {
                    top: true
                    left: true
                    right: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.background
                    opacity: 0.97
                    border.color: "#261e2e"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Workspaces { }

                        StatusPill {
                            text: submap.output
                            foreground: root.foreground
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        id: clockButton
                        implicitWidth: clock.implicitWidth + 12
                        implicitHeight: 22
                        radius: 6
                        color: "#1a1418"
                        border.color: "#332633"
                        border.width: 1

                        Text {
                            id: clock
                            anchors.centerIn: parent
                            color: root.foreground
                            font.family: "Comic Code Ligatures"
                            font.pixelSize: 10
                            font.bold: true

                            function update() {
                                const date = new Date()
                                const weekdays = ["日", "月", "火", "水", "木", "金", "土"]
                                text = Qt.formatDateTime(date, "yyyy年M月d日")
                                     + "(" + weekdays[date.getDay()] + ") "
                                     + Qt.formatTime(date, "HH:mm")
                            }

                            Component.onCompleted: update()
                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clock.update()
                            }
                        }

                        MouseArea {
                            id: clockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                memoryPopup.visible = false
                                diskPopup.visible = false
                                calendarPopup.visible = !calendarPopup.visible
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        StatusPill {
                            text: audio.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: Quickshell.execDetached(["pavucontrol"])
                            onWheel: wheel => {
                                const direction = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                                Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", direction])
                                audio.refresh()
                            }
                        }

                        StatusPill {
                            text: network.output
                            foreground: root.foreground
                            critical: network.output.indexOf("offline") >= 0
                        }

                        StatusPill {
                            id: memoryPill
                            text: memory.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: {
                                calendarPopup.visible = false
                                diskPopup.visible = false
                                memoryPopup.visible = !memoryPopup.visible
                            }
                        }

                        StatusPill {
                            id: diskPill
                            text: disk.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: {
                                calendarPopup.visible = false
                                memoryPopup.visible = false
                                diskPopup.visible = !diskPopup.visible
                            }
                            warning: root.percentage(disk.output) >= 85
                            critical: root.percentage(disk.output) >= 95
                        }

                        StatusPill {
                            text: temperature.output
                            foreground: root.foreground
                            critical: root.temperatureValue(temperature.output) >= 80
                        }

                        StatusPill {
                            text: battery.output
                            foreground: root.foreground
                            warning: root.percentage(battery.output) >= 0 && root.percentage(battery.output) <= 50
                            critical: root.percentage(battery.output) >= 0 && root.percentage(battery.output) <= 25
                        }

                        Tray {
                            barWindow: barWindow
                        }
                    }

                    CalendarPopup {
                        id: calendarPopup
                        anchorItem: clockButton
                    }

                    DetailPopup {
                        id: memoryPopup
                        anchorItem: memoryPill
                        title: "メモリ使用状況"
                        detailText: memoryDetails.output
                        onVisibleChanged: if (visible) memoryDetails.refresh()
                    }

                    DetailPopup {
                        id: diskPopup
                        anchorItem: diskPill
                        title: "ストレージ使用状況"
                        detailText: diskDetails.output
                        onVisibleChanged: if (visible) diskDetails.refresh()
                    }
                }
            }
        }
    }
}
