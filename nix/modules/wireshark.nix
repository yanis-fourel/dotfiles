{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.wireshark-cli
  ];

  users.users.yanis.extraGroups = [ "toto" ];
}

