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
}
