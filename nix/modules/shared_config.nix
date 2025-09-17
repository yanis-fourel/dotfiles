{
  config,
  pkgs,
  inputs,
  pkg_ghostty,
  ...
}:
{
  imports = [
    ./keyboard.nix
    ./shell.nix
    ./devtools.nix
    ./docker.nix
    ./wireshark.nix
  ];

  users.users.yanis = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.nushell;
  };

  services.tailscale.enable = true;

  systemd.timers."dotfile-fetch" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "dotfile-fetch.service";
    };
  };

  systemd.services."dotfile-fetch" = {
    script = ''
      set -eu
      cd /home/yanis/dotfiles/ && ${pkgs.git}/bin/git fetch
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "yanis";
    };
  };

  services.syncthing = {
    enable = true;
    group = "users";
    user = "yanis";
    dataDir = "/home/yanis/Sync"; # Default folder for new synced folders
    configDir = "/home/yanis/Sync/.config/syncthing"; # Folder for Syncthing's settings and keys
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "yanis" ];

  nix.settings.allowed-users = [ "yanis" ];
  security.sudo.wheelNeedsPassword = false;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
  services.blueman.enable = true;

  nixpkgs.overlays = [
    inputs.fenix.overlays.default
  ];

  environment.systemPackages = [
    pkgs.vim # needed for rvim
    pkgs.neovim
    pkgs.pavucontrol
    pkgs.wget
    pkgs.lshw
    pkgs.tmux
    pkgs.git
    pkgs.dunst
    pkgs.stow
    pkgs.grim
    pkgs.slurp
    pkgs.swappy
    pkgs.zsh # TODO: remove
    pkgs.oh-my-zsh
    pkgs.zsh-autocomplete
    pkgs.zsh-autosuggestions
    pkgs.brave
    pkgs.kdePackages.kwallet # brave needs
    pkgs.kdePackages.kwalletmanager # brave needs
    pkgs.fzf
    pkgs.unzip
    pkgs.waybar
    pkgs.man
    pkgs.man-pages
    pkgs.brightnessctl
    pkgs.ripgrep
    pkgs.wl-clipboard
    pkgs.fd
    pkgs.tig
    pkgs.rclone
    pkgs.rsync
    pkgs.gnupg
    pkgs.nix-search-cli
    pkgs.cachix
    pkgs.file
    pkgs.openai-whisper # TODO: remove
    pkgs.cryptomator
    pkgs.obsidian
    pkgs.tofi
    pkgs.wofi
    pkgs.libreoffice
    pkgs.kdePackages.okular
    pkgs.gimp
    pkgs.i3
    pkgs.lmms
    pkgs.gammastep
    pkgs.openssl # needed to dev on nushell, TODO make it nix shell?
    # When cleaning this up, also need to remove PKG_CONFIG_PATH sessionVariables
    pkgs.yazi
    pkgs.btop
    pkg_ghostty
    pkgs.trash-cli
    pkgs.spotify
    pkgs.rlwrap
    pkgs.virtualenv
    pkgs.hyprcursor
    pkgs.hyprlock
    pkgs.gromit-mpx # draw on screen
    pkgs.ghidra
    pkgs.direnv
    pkgs.devenv
    pkgs.aichat # llm cli
    pkgs.obs-studio
    pkgs.ncdu
    pkgs.tokei # code statistics
    pkgs.dua # disk usage analyzer
    pkgs.ripgrep-all # like ripgrep but for all file types (pdf, docx, zip, etc.)
    pkgs.ncspot # ncurses spotify client
    pkgs.audacity
    pkgs.code-cursor
    pkgs.xdg-desktop-portal-hyprland
    pkgs.kitty
    pkgs.mpv
    pkgs.vlc
    pkgs.qbittorrent
    pkgs.tor-browser
    pkgs.protonvpn-gui
  ];

  environment.sessionVariables = {
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };

  system.activationScripts = {
    cleartoficache.text = "rm -f /home/yanis/.cache/tofi-drun"; # https://github.com/philj56/tofi/issues/115
  };

  fonts.packages = [
    pkgs.noto-fonts
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-emoji
    pkgs.nerd-fonts.symbols-only
  ];

  programs.gnupg.agent.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "yanis";
      };
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --user-menu --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  security.pam.services.hyprland.kwallet.enable = true;

  services.upower.enable = true; # brave wants

  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;

  # Needed for NVIDIA, might want to only allow unfree NVIDIA
  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    extraPackages = [
      pkgs.mesa
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/supend to fail.
    # Enable this is you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the base essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independant third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommanded setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Found using `lshw -c display`
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  users.extraGroups.networkmanager.members = [ "yanis" ];


  # Set your time zone.
  time.timeZone = "Asia/Bangkok";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  programs.hyprland.enable = true;
  # Hints electron apps to use wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # TODO: hyprcursor https://gitlab.com/Pummelfisch/future-cyan-hyprcursor

  environment.sessionVariables = {
    VISUAL = "nvim";
    EDITOR = "nvim";
    SUDO_EDITOR = "rvim";
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # NOTE: currently not compatible with flakes
  system.copySystemConfiguration = false;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
