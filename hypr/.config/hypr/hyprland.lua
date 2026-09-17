-- Hyprland Lua configuration (Hyprland >= 0.55)
-- See https://wiki.hypr.land/Configuring/Start/

local launcher = "nc -U /run/user/$(id -u)/walker/walker.sock"
local mainMod = "SUPER"

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

hl.on("hyprland.start", function()
    for _, command in ipairs({
        "qs -p ~/.config/quickshell",
        "systemctl --user start hyprpolkitagent",
        "fcitx5",
        "gammastep",
        "elephant",
        "walker --gapplication-service",
        "battery-monitor",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "/usr/lib/xdg-desktop-portal-hyprland",
        "/usr/lib/xdg-desktop-portal",
    }) do
        hl.exec_cmd(command)
    end
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Future-Cyan-Hyprcursor_Theme")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "fcitx")
hl.env("INPUT_METHOD", "fcitx")

hl.config({
    cursor = {
        inactive_timeout = 3,
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    animations = {
        enabled = false,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
    input = {
        kb_layout = "us_qwerty-fr",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("kitty --hold sh -c 'tmux a -t root || tmux new -s root'"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("screenshot.sh"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd("devjournal"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor r"))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor l"))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + Z", hl.dsp.exec_cmd("~/bin/hypr-togglezoom"), { release = true })
hl.bind("SUPER + C", hl.dsp.exec_cmd("hypr-floating bc"), { release = true })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local mediaBinds = {
    { "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
    { "XF86MonBrightnessUp", "brightnessctl -e4 -n2 set 5%+" },
    { "XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-" },
}
for _, bind in ipairs(mediaBinds) do
    hl.bind(bind[1], hl.dsp.exec_cmd(bind[2]), { locked = true, repeating = true })
end
for _, bind in ipairs({
    { "XF86AudioNext", "playerctl next" },
    { "XF86AudioPause", "playerctl play-pause" },
    { "XF86AudioPlay", "playerctl play-pause" },
    { "XF86AudioPrev", "playerctl previous" },
}) do
    hl.bind(bind[1], hl.dsp.exec_cmd(bind[2]), { locked = true })
end

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})
