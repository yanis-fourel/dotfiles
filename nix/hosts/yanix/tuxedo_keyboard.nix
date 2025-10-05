{ config, pkgs, lib, ... }:

let
  kernel = config.boot.kernelPackages.kernel;

  clevoKeyboardModule = pkgs.stdenv.mkDerivation rec {
    pname = "clevo-keyboard";
    version = "unstable-2025-10-05";

    src = pkgs.fetchFromGitHub {
      owner = "wessel-novacustom";
      repo = "clevo-keyboard";
      rev = "master";
      sha256 = "sha256-Gy9DJvj4FZ3NyFAxYkmUCFR/D9iPAE/fRX1rGX0J+NY=";  # Compute via: nix-prefetch-github wessel-novacustom clevo-keyboard --rev master
    };

    nativeBuildInputs = [ kernel.moduleBuildDependencies ];

    makeFlags = [
      "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
      "INSTALL_MOD_PATH=$(out)"
    ];

    buildFlags = [ ];
    installTargets = [ ];  # Omit; use custom installPhase instead.

    prePatch = ''
      # Patch DMI matches for Aftershock compatibility.
      sed -i 's/DMI_MATCH(DMI_SYS_VENDOR, "TUXEDO")/DMI_MATCH(DMI_SYS_VENDOR, "AFTERSHOCK")/g' src/tuxedo_keyboard.c
      sed -i 's/DMI_MATCH(DMI_BOARD_VENDOR, "TUXEDO")/DMI_MATCH(DMI_BOARD_VENDOR, "AFTERSHOCK")/g' src/tuxedo_keyboard.c
      sed -i 's/DMI_MATCH(DMI_CHASSIS_VENDOR, "TUXEDO")/DMI_MATCH(DMI_CHASSIS_VENDOR, "AFTERSHOCK")/g' src/tuxedo_keyboard.c
    '';

    installPhase = ''
      runHook preInstall

      # Create directory structure for kernel modules.
      mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86
      mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/tuxedo_io

      # Copy built modules to appropriate locations.
      cp src/tuxedo_keyboard.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/
      cp src/clevo_wmi.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/
      cp src/clevo_acpi.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/
      cp src/uniwill_wmi.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/
      cp src/tuxedo_io/tuxedo_io.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/tuxedo_io/

      runHook postInstall
    '';

    meta = with lib; {
      description = "Kernel module for Clevo/Aftershock keyboard backlight control";
      platforms = platforms.linux;
      license = licenses.gpl2;
    };
  };
in
{
  boot.extraModulePackages = [ clevoKeyboardModule ];

  boot.kernelModules = [ "tuxedo_keyboard" ];

  # Disable backlight entirely via module parameters.
  boot.extraModprobeConfig = ''
    options tuxedo_keyboard brightness=0
  '';
}
