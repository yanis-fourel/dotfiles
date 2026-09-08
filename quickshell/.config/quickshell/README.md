# Quickshell bar

A small horizontal Quickshell replacement for the previous Waybar setup. It provides:

- Hyprland workspaces and active submap
- Japanese date/time and a clickable month calendar
- PipeWire volume (click opens `pavucontrol`, scroll changes volume)
- iwd Wi-Fi status with a generic default-route fallback
- memory and storage status with clickable detail panels
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
