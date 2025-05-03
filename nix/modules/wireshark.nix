{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.wireshark-cli
  ];

  users.groups.wireshark = {};
  users.users.yanis.extraGroups = [ "wireshark" ];
}

