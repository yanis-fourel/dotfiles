//@ pragma UseQApplication
//@ pragma IconTheme Adwaita

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.components

ShellRoot {
    id: root

    readonly property color foreground: "#f0e6eb"
    readonly property color background: "#0a0e18"
    readonly property color accent: "#ff6b9d"
    readonly property var powerData: parseJson(powerStatus.output)
    readonly property var bluetoothData: parseJson(bluetoothStatus.output)
    readonly property var updateData: parseJson(updateStatus.output)
    property string profileMessage: ""

    Process {
        id: profileChange
        onExited: (exitCode, exitStatus) => powerStatus.refresh()
        stdout: StdioCollector {
            onStreamFinished: root.profileMessage = root.parseJson(text).detail || ""
        }
    }

    StatusCommand {
        id: powerStatus
        interval: 5000
        command: ["python3", Quickshell.shellDir + "/scripts/desktop_status.py", "power"]
    }
    StatusCommand {
        id: bluetoothStatus
        interval: 10000
        command: ["python3", Quickshell.shellDir + "/scripts/desktop_status.py", "bluetooth"]
    }
    StatusCommand {
        id: updateStatus
        interval: 3600000
        command: ["python3", Quickshell.shellDir + "/scripts/desktop_status.py", "updates"]
    }
    readonly property var codexData: parseJson(codexUsage.output)
    readonly property var codexLimit: selectedCodexLimit(codexData)
    readonly property real codexPercent: codexLimit ? Number(codexLimit.usedPercent || 0) : -1
    property double budgetNow: Date.now() / 1000
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.budgetNow = Date.now() / 1000
    }

    function parseJson(value) {
        try { return JSON.parse(value || "{}") }
        catch (_) { return {} }
    }

    function selectedCodexLimit(data) {
        const limits = data && data.limits ? data.limits : []
        let selected = null
        for (const limit of limits) {
            if (!selected || Number(limit.usedPercent || 0) > Number(selected.usedPercent || 0))
                selected = limit
        }
        return selected
    }

    function budgetProgress(limit, now) {
        const span = Number(limit.windowSeconds)
        const reset = Number(limit.resetAt)
        if (!(span > 0) || !(reset > 0)) return null
        const elapsed = Math.max(0, Math.min(span, now - (reset - span)))
        const unit = span >= 86400 ? 86400 : span >= 3600 ? 3600 : 60
        const suffix = unit === 86400 ? "d" : unit === 3600 ? "h" : "m"
        const compact = value => String(Math.round(value * 10) / 10)
        return { period: compact(elapsed / unit) + "/" + compact(span / unit) + suffix,
                 reference: Math.round(elapsed / span * 100) }
    }

    function codexLabel(data) {
        if (!codexUsage.output.length) return "󱚣 …"
        if (!data.ok) return "󱚣 !"
        const limit = codexLimit
        if (!limit) return "󱚣 —"
        const group = limit.group === "Codex" ? "" : (limit.group.indexOf("Spark") >= 0 ? "Spark " : limit.group + " ")
        const usage = "󱚣 " + group + Math.round(codexPercent) + "%"
        const progress = budgetProgress(limit, budgetNow)
        return usage + (progress ? " · 󰥔 " + progress.period + " · 󰓾 " + progress.reference + "%" : " · 󰥔 —")
    }

    function codexTooltip() {
        if (!codexData.ok) return codexData.error || "Loading Codex usage"
        const limit = codexLimit
        if (!limit) return "No usage windows reported"
        let text = limit.group + " · " + limit.label + "\nUsage · elapsed/total · linear budget reference"
        const progress = budgetProgress(limit, budgetNow)
        if (progress) {
            const format = seconds => Qt.formatDateTime(new Date(seconds * 1000), "MMM d HH:mm")
            text += "\n" + format(limit.resetAt - limit.windowSeconds) + " → " + format(limit.resetAt)
            text += "\n" + Math.abs(Math.round(codexPercent) - progress.reference) + " percentage points "
                  + (codexPercent > progress.reference ? "over" : "under") + " linear budget"
        }
        return text
    }

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
        id: networkName
        interval: 5000
        command: ["bash", "-lc", "iw dev 2>/dev/null | awk '$1==\"ssid\" {$1=\"\"; sub(/^ /,\"\"); print; exit}'"]
    }

    StatusCommand {
        id: memory
        interval: 5000
        command: ["bash", "-lc", "free -b | awk '/^Mem:/ {printf \"󰍛 %.1fG\", $3/1073741824}'"]
    }

    StatusCommand {
        id: memoryDetails
        interval: 4000
        command: ["python3", Quickshell.shellDir + "/scripts/system_stats.py"]
    }

    StatusCommand {
        id: disk
        interval: 30000
        command: ["bash", "-lc", "df -P \"$HOME\" | awk 'NR==2 {printf \"󰋊 %s\", $5}'"]
    }

    StatusCommand {
        id: diskDetails
        interval: 15000
        command: ["python3", Quickshell.shellDir + "/scripts/storage_stats.py"]
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

    StatusCommand {
        id: codexUsage
        interval: 300000
        command: ["python3", Quickshell.shellDir + "/scripts/codex_usage.py"]
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData

                function togglePopup(popup) {
                    const opening = !popup.visible
                    for (const item of [calendarPopup, aiPopup, memoryPopup, diskPopup, powerPopup, commandPopup, updatesPopup])
                        item.visible = false
                    popup.visible = opening
                }

                property string launchTool: ""
                property string launchUrl: ""
                property var launchAnchor: null
                function launchApp(tool, anchor, command, url) {
                    if (appLauncher.running) return
                    launchTool = tool
                    launchAnchor = anchor
                    launchUrl = url || ""
                    appLauncher.command = ["python3", Quickshell.shellDir + "/scripts/floating_tool.py", tool, command || "", launchUrl]
                    appLauncher.running = true
                }
                Process {
                    id: appLauncher
                    stdout: StdioCollector {
                        onStreamFinished: {
                            const result = root.parseJson(text)
                            if (result.ok) commandPopup.visible = false
                            else {
                                commandPopup.commandText = result.command || commandPopup.commandText
                                commandPopup.message = result.error || "Unable to launch application."
                                if (!commandPopup.visible) barWindow.togglePopup(commandPopup)
                            }
                        }
                    }
                }

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

                        StatusPill {
                            id: batteryPill
                            text: (root.powerData.emoji || "") + " " + battery.output
                            tooltip: "Power profile: " + (root.powerData.profile || "unavailable")
                            clickable: true
                            onClicked: barWindow.togglePopup(powerPopup)
                            foreground: root.foreground
                            warning: root.percentage(battery.output) >= 0 && root.percentage(battery.output) <= 50
                            critical: root.percentage(battery.output) >= 0 && root.percentage(battery.output) <= 25
                        }
                        StatusPill {
                            text: temperature.output
                            foreground: root.foreground
                            critical: root.temperatureValue(temperature.output) >= 80
                        }
                        StatusPill {
                            id: diskPill
                            text: disk.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: barWindow.togglePopup(diskPopup)
                            warning: root.percentage(disk.output) >= 85
                            critical: root.percentage(disk.output) >= 95
                        }
                        StatusPill {
                            id: memoryPill
                            text: memory.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: barWindow.togglePopup(memoryPopup)
                        }
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
                                barWindow.togglePopup(calendarPopup)
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        StatusPill {
                            id: aiPill
                            text: root.codexLabel(root.codexData)
                            tooltip: root.codexTooltip()
                            foreground: root.foreground
                            clickable: true
                            warning: !root.codexData.ok || root.codexPercent >= 75
                            critical: root.codexData.ok === true && root.codexPercent >= 90
                            onClicked: {
                                barWindow.togglePopup(aiPopup)
                            }
                        }

                        StatusPill {
                            id: audioPill
                            text: audio.output
                            foreground: root.foreground
                            clickable: true
                            onClicked: barWindow.launchApp("audio", audioPill, "", "")
                            onWheel: wheel => {
                                const direction = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                                Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", direction])
                                audio.refresh()
                            }
                        }

                        StatusPill {
                            id: wifiPill
                            text: network.output
                            tooltip: networkName.output || "Wi-Fi · open impala"
                            foreground: root.foreground
                            critical: network.output.indexOf("offline") >= 0
                            clickable: true
                            onClicked: barWindow.launchApp("wifi", wifiPill, "", "")
                        }

                        StatusPill {
                            id: bluetoothPill
                            text: root.bluetoothData.label || "󰂯 …"
                            tooltip: root.bluetoothData.detail || "Bluetooth"
                            clickable: true
                            onClicked: barWindow.launchApp("bluetooth", bluetoothPill, "", "")
                        }
                        StatusPill {
                            id: updatesPill
                            text: root.updateData.label || "󰚰 …"
                            tooltip: "Days since last recorded full upgrade · click for Arch news"
                            clickable: true
                            onClicked: barWindow.togglePopup(updatesPopup)
                        }
                        Tray {
                            barWindow: barWindow
                        }
                    }

                    ControlsPopup {
                        id: powerPopup
                        anchorItem: batteryPill
                        heading: "Power · " + (root.powerData.profile || "unavailable")
                        detail: (root.powerData.detail || "Loading…") + (root.profileMessage ? "\n\n" + root.profileMessage : "")
                        actions: (root.powerData.profiles || []).map(p => ({label: (p === root.powerData.profile ? "✓ " : "") + p, action: p}))
                        onVisibleChanged: if (visible) { root.profileMessage = ""; powerStatus.refresh() }
                        onActionTriggered: action => {
                            if (profileChange.running) return
                            root.profileMessage = "Applying…"
                            profileChange.command = ["python3", Quickshell.shellDir + "/scripts/desktop_status.py", "set-profile", action]
                            profileChange.running = true
                        }
                    }
                    CommandPopup {
                        id: commandPopup
                        anchorItem: barWindow.launchAnchor || bluetoothPill
                        tool: barWindow.launchTool
                        busy: appLauncher.running
                        onSubmitted: command => barWindow.launchApp(barWindow.launchTool, barWindow.launchAnchor, command, barWindow.launchUrl)
                    }
                    ControlsPopup {
                        id: updatesPopup
                        anchorItem: updatesPill
                        heading: "Arch updates"
                        detail: root.updateData.detail || "Checking upgrade history and official Arch news…"
                        toolbarActions: [{label: updateStatus.process.running ? "Checking…" : "↻ Refresh", action: "refresh", primary: true}, {label: "Arch news ↗", url: "https://archlinux.org/news/"}]
                        actions: root.updateData.links || []
                        onVisibleChanged: if (visible) updateStatus.refresh()
                        onActionTriggered: action => {
                            if (action === "refresh") updateStatus.refresh()
                            else barWindow.launchApp("browser", updatesPill, "", action)
                        }
                    }

                    CalendarPopup {
                        id: calendarPopup
                        anchorItem: clockButton
                    }

                    AiUsagePopup {
                        id: aiPopup
                        anchorItem: aiPill
                        dataText: codexUsage.output
                        onRefreshRequested: codexUsage.refresh()
                        onVisibleChanged: if (visible) codexUsage.refresh()
                    }

                    ResourcePopup {
                        id: memoryPopup
                        anchorItem: memoryPill
                        dataText: memoryDetails.output
                        onVisibleChanged: if (visible) memoryDetails.refresh()
                    }

                    StoragePopup {
                        id: diskPopup
                        anchorItem: diskPill
                        dataText: diskDetails.output
                        onVisibleChanged: if (visible) diskDetails.refresh()
                    }
                }
            }
        }
    }
}
