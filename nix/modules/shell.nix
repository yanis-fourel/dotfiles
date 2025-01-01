{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "rust"
      ];
    };
  };

  environment.systemPackages = [
    pkgs.nushell
    pkgs.starship
    pkgs.eza
  ];

}
