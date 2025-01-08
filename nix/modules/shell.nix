{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
  };

  environment.systemPackages = [
    pkgs.nushell
    pkgs.starship
    pkgs.carapace
  ];

}
