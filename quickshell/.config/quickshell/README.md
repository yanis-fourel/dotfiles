# Quickshell bar

A small horizontal Quickshell replacement for the previous Waybar setup. It provides:

- Hyprland workspaces and active submap
- Japanese date/time and a clickable month calendar
- PipeWire volume (click opens `pavucontrol`, scroll changes volume)
- iwd Wi-Fi status with click-to-toggle SSID and a generic default-route fallback
- a graphical system-resource panel with usage bars, CPU/load/temperature, RAM/swap, and top-process cards
- a graphical storage panel with filesystem usage cards and a block-device list
- temperature and battery status
- StatusNotifier system tray with application context menus

## Try it

```sh
qs -p ~/.config/quickshell
```

Once it is working, replace the existing Waybar autostart command in your Hyprland configuration with:

```ini
exec-once = qs -p ~/.config/quickshell
```

The existing Waybar and Hyprland files were intentionally left unchanged. The bar expects the tools already used by the system: `hyprctl`, `wpctl`, `nmcli`, `free`, `df`, and `sensors`.
