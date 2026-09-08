# Quickshell bar

A small horizontal Quickshell replacement for the previous Waybar setup. It provides:

- Hyprland workspaces and active submap
- Japanese date/time and a clickable month calendar
- PipeWire volume (click opens `pavucontrol`, scroll changes volume)
- iwd Wi-Fi status with click-to-toggle SSID and a generic default-route fallback
- a graphical system-resource panel with usage bars, CPU/load/temperature, RAM/swap, and top-process cards
- a graphical storage panel with filesystem usage cards and a block-device list
- OpenAI Codex subscription usage, reset countdowns, plan status, and optional credits
- temperature and battery status
- StatusNotifier system tray with application context menus

The Codex widget reuses the `openai-codex` OAuth session in `~/.pi/agent/auth.json`. Its collector sends the access token only to OpenAI's HTTPS usage endpoint and never prints credentials, account IDs, or email addresses.

## Try it

```sh
qs -p ~/.config/quickshell
```

Once it is working, replace the existing Waybar autostart command in your Hyprland configuration with:

```ini
exec-once = qs -p ~/.config/quickshell
```

The existing Waybar and Hyprland files were intentionally left unchanged. The bar expects the tools already used by the system: `hyprctl`, `wpctl`, `nmcli`, `free`, `df`, and `sensors`.
