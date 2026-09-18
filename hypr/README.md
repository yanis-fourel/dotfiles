# Hyprland

`hyprland.lua` uses the Lua API introduced in Hyprland 0.55. Validated with
Hyprland 0.56.2:

```sh
Hyprland --verify-config -c "$PWD/hypr/.config/hypr/hyprland.lua"
```

Install/restow this package as usual, ensuring `~/.config/hypr/hyprland.lua`
points at this repository, then log out and back in. An existing session may
continue watching the old `.conf` path and regenerate a legacy stub; it is
ignored and can be deleted after restarting. No old-config backups are kept.

Hyprlock still uses `hyprlock.conf` and the Catppuccin `themes/*.conf` palettes.
These are not Hyprland Lua configs and must retain their current format.
Likewise, the Hyprcursor `manifest.hl` and cursor assets in
`hyprcursor_themes/` do not require Lua conversion.
