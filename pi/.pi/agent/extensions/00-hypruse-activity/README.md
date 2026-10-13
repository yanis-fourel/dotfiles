# Hypruse activity

After `/reload`, Pi emits a lease at `$XDG_RUNTIME_DIR/pi-hypruse/<pid>.json`
from the first detected hypruse call until `agent_settled`. This is desktop-task
elapsed time, including reasoning, not accumulated tool execution time.
Multiple sessions are aggregated; the widget shows the oldest active timer.
Minutes do not wrap at 60 (60m 00s follows 59m 59s).

The lease includes session/run IDs, PID, Linux process-start identity, and a
heartbeat. It contains no commands, screenshots, email contents, or model text.
A dead process or a heartbeat older than five seconds produces an amber unknown
indicator rather than claiming completion. Shutdown/settle removes the lease.

Detection covers Pi's `mcp__hypruse__*` tool execution events (including nested
codemode calls), plus direct hypruse command text in bash tool events. CLI
matching is heuristic: quoted mentions can cause false positives; shell aliases,
computed executable names, and calls hidden inside scripts are not detected.
Other agent harnesses need their own lifecycle producer; a long-lived native
hypruse beacon is deliberately NOT treated as active work.

Super+Shift+Backspace runs the Quickshell `hypruse_activity.py stop` helper.
It writes targeted run IDs, invokes `/usr/bin/hypruse stop`, and tracked Pi
sessions observe the request within ~200ms, abort, and block further tools until
a new run. No model cooperation is needed. This is not a security boundary:
a hung event loop can delay abort, native stop has hypruse's own scope, and
reconnecting an MCP server stopped by the panic key may require `/reload`.

Files:
- `~/.config/quickshell/components/HypruseActivity.qml`
- `~/.config/quickshell/scripts/hypruse_activity.py`
- `~/.config/hypr/hyprland.lua` (panic key)

Tests: `node --test activity.test.mjs`, and Python unittest discovery for
`test_hypruse_activity.py` in the Quickshell scripts directory.
