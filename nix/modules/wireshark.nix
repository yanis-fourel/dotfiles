{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.wireshark-cli
  ];

  users.groups.wireshark.members = [ "yanis" ];
}

