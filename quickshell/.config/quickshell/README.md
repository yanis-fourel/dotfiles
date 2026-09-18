# Quickshell bar

A small horizontal Quickshell replacement for the previous Waybar setup. It provides:

- Hyprland workspaces and active submap
- Japanese date/time and a clickable month calendar
- PipeWire volume (click opens floating `pavucontrol`, scroll changes volume)
- iwd Wi-Fi status with SSID on hover, direct floating `impala` on click, and a generic default-route fallback
- a graphical system-resource panel with usage bars, CPU/load/temperature, RAM/swap, and top-process cards
- a graphical storage panel with filesystem usage cards and a block-device list
- OpenAI Codex subscription usage, reset countdowns, plan status, and optional credits; the bar shows usage, elapsed/total window (e.g. `2/7d`), and a linear budget reference (`29%`). All three refer to the highest-used reported window. Elapsed time is inferred from reset time minus window duration and updates every minute.
- temperature and battery status, with power-profile emoji and popup switching
- Bluetooth connection status and a floating `bluetui` terminal
- days since the last completed full upgrade, with official Arch news in a popup
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

Hyprland autostart now launches Quickshell instead of Waybar. The bar uses `hyprctl`, `wpctl`, `iw`, `free`, `df`, Python 3, `busctl`, `bluetoothctl`, `kitty`, `bluetui`, `impala`, and `pavucontrol`.

Resource and storage detail collectors poll only while their respective popups are visible (4s/15s). Status commands use non-login shells to avoid repeatedly executing `/etc/profile.d` hooks. CPU temperature comes directly from CPU hwmon sysfs files, without querying unrelated sensors.

## Desktop controls

- Audio, Wi-Fi, and Bluetooth clicks directly open their tools with Hyprland one-shot floating launch rules. They are separate windows, not embedded popups. Existing default tool windows are floated and focused instead of duplicated.
- If an audio, Wi-Fi, Bluetooth, or news-browser launcher is missing, a native command prompt lets you launch and remember a replacement in `~/.config/quickshell/commands.json` (respects `XDG_CONFIG_HOME`). Enter an executable with arguments; quote paths containing spaces. Terminal apps need a terminal command, e.g. `alacritty -e bluetui`. News URLs are appended to the browser command. Delete an entry to restore its default. This fallback applies to application launchers, not status collectors or system-control commands.
- Workspaces and system metrics (RAM/CPU, disk, temperature, battery) sit left of the centered clock. AI usage, audio, Wi-Fi, Bluetooth, updates and the tray sit right.
- Power profiles use the existing `net.hadess.PowerProfiles` D-Bus API (provided here by `tlp-pd`). ⚡ performance, ⚖️ balanced, 🍃 power-saver. Changes respect the service's authorization policy; no privileged helper or competing power daemon is installed.
- Upgrade age counts elapsed days from the last completed full-system-upgrade transaction in `/var/log/pacman.log`. This includes pacman runs initiated by yay, but does not prove AUR builds completed. No-change checks are not recorded as completed transactions.
- Arch news is fetched over HTTPS hourly and when opening/refreshing the popup. Announcements link to official instructions. The limited feed is **not a comprehensive known-issues database or a guarantee that updating is safe**. No package databases are synchronized and no updates are installed by the bar.

Collector regression tests: `python3 -m unittest discover -s ~/.config/quickshell/scripts -p 'test_*.py'`.
