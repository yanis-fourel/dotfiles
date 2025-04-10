{
  pkgs,
  lib,
  ...
}:
let
  xkb-qwerty-fr = pkgs.callPackage ../qwerty-fr { };
in
{
  environment.systemPackages = [
    xkb-qwerty-fr
  ];

  environment.sessionVariables.XKB_CONFIG_EXTRA_PATH = lib.mkBefore ''${xkb-qwerty-fr}/usr/share/X11/xkb'';


  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      waylandFrontend = true;
      addons = [
        pkgs.fcitx5-mozc # TODO: remove, that's japanese?
        pkgs.fcitx5-gtk
        pkgs.fcitx5-chewing
        pkgs.fcitx5-hangul
        # TODO: try fcitx5-fluent or fcitx5-nord-unstable, there're themes
      ];
    };
  };
}
