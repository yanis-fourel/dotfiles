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
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      fcitx5-chewing
      fcitx5-hangul
    ];
  };
}
