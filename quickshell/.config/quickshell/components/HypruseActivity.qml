import QtQuick
import QtQuick.Controls
import Quickshell

StatusPill {
    id: root
    property var state: ({})
    readonly property bool busy: state.active === true
    function duration(seconds) {
        const n = Math.max(0, Math.floor(Number(seconds) || 0))
        return String(Math.floor(n / 60)).padStart(2, "0") + "m "
             + String(n % 60).padStart(2, "0") + "s"
    }
    // Minimal idle icon; expanded text only while a tracked task is running.
    text: busy ? "󰚩 " + duration(state.elapsed) + " · Super+Shift+⌫" : "󰚩"
    implicitWidth: busy ? implicitTextWidth() : 20
    function implicitTextWidth() { return labelMetrics.width + 12 }
    TextMetrics {
        id: labelMetrics
        text: root.text
        font.family: "Comic Code Ligatures"
        font.pixelSize: 10
    }
    critical: busy
    warning: !busy && state.uncertain === true
    foreground: "#7d7181"
    clickable: busy || state.uncertain === true
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton && clickable)
            Quickshell.execDetached(["python3", Quickshell.shellDir + "/scripts/hypruse_activity.py", "stop"])
    }
    ToolTip.visible: hover.hovered
    ToolTip.delay: 500
    ToolTip.text: busy
        ? "Pi desktop task running (" + state.count + " session(s))\nElapsed since first hypruse call, including thinking time.\nSuper + Shift + Backspace or click to interrupt."
        : state.uncertain === true
          ? "Tracking lost or a Pi process exited unexpectedly.\nSuper + Shift + Backspace stops hypruse."
          : "No tracked Pi desktop task.\nSuper + Shift + Backspace stops hypruse."
    HoverHandler { id: hover }
}
