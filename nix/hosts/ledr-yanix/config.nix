{
pkgs,
...
}:
{
  imports = [
    ./hardware.nix
    ../../modules/shared_config.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  networking.hostName = "ledr-yanix";

  nixpkgs.config.allowUnfree = true; # microsoft teams


  services.openvpn.servers = {
    ledr = {
      config = ''config /home/yanis/Sync/LEDR/vpn/yanis-fourel.corp.ledr.io-openvpn-config.ovpn ''; 
      updateResolvConf = true;
    };
  };

  environment.systemPackages = [
    pkgs.clamav
    pkgs.clamtk
  ];

  services = {
    clamav = {
      daemon. enable = true;
      updater.enable = true;
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?
}
