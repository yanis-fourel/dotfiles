{pkgs, ...}:
{
  programs.wireshark = {
    enable = true;
    dumpcap.enable = true; # Allow non-root users to capture packets
  };

  environment.systemPackages = [
    pkgs.wireshark-cli
  ];

  users.users.yanis.extraGroups = [ "wireshark" ];
}

