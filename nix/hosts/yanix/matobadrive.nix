{ config, pkgs, ... }:

let
  # Script to handle decryption and mounting
  mountScript = pkgs.writeShellScriptBin "external-drive-mount.sh" ''
    #!/bin/bash

    ACTION=$1
    DEVICE_ID="6a0796b5-7774-4b55-822e-d8aab9865740"
    DEVICE="/dev/disk/by-uuid/$DEVICE_ID"
    MAPPER_NAME="matoba"
    MAPPER_DEVICE="/dev/mapper/$MAPPER_NAME"
    MOUNT_POINT="/home/yanis/Videos/x2r/"
    PASSWORD_FILE="/root/pwd"

    do_remove() {
      echo "do_remove called"
      if ${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_POINT"; then
        ${pkgs.util-linux}/bin/umount "$MOUNT_POINT" --lazy
        echo "Unmounted $MOUNT_POINT."
      fi
      if [ -b "$MAPPER_DEVICE" ]; then
        ${pkgs.cryptsetup}/bin/cryptsetup luksClose "$MAPPER_NAME"
        echo "Closed $MAPPER_NAME."
      fi
    }

    do_add() {
      echo "do_add called"
      if [ -b "$MAPPER_DEVICE" ]; then
        echo "Device $MAPPER_DEVICE already exists."
        return 0
      fi
      if [ ! -b "$DEVICE" ]; then
        echo "Device $DEVICE not found."
        exit 1
      fi
      cat "$PASSWORD_FILE" | ${pkgs.cryptsetup}/bin/cryptsetup luksOpen "$DEVICE" "$MAPPER_NAME"
      if [ $? -ne 0 ]; then
        echo "Decryption failed."
        exit 1
      fi

      mkdir -p "$MOUNT_POINT"
      OPTS="defaults,noatime"
      if ! ${pkgs.util-linux}/bin/mount -o "$OPTS" "$MAPPER_DEVICE" "$MOUNT_POINT"; then
        echo "Mount failed."
        do_remove
        exit 1
      fi
      echo "Mounted $MAPPER_DEVICE at $MOUNT_POINT."
    }

    case "$ACTION" in
      add)
        do_add
        ;;
      remove)
        do_remove
        ;;
      *)
        echo "Invalid action: $ACTION"
        exit 1
        ;;
    esac
  '';
in
{
  # Enable required packages
  environment.systemPackages = with pkgs; [ cryptsetup util-linux mountScript ];

  # Udev rules to detect the specific USB block device and trigger service
  services.udev.extraRules = ''
    KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl start external-mount@%k.service"
    KERNEL=="sd[a-z][0-9]", SUBSYSTEMS=="usb", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl stop external-mount@%k.service"
  '';

  # Systemd service template for mounting
  systemd.services."external-mount@" = {
    description = "Mount External Encrypted Drive on %i";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${mountScript}/bin/external-drive-mount.sh add %i";
      ExecStop = "${mountScript}/bin/external-drive-mount.sh remove %i";
    };
  };

  # Optional: Declare the filesystem for systemd awareness
  fileSystems."/home/yanis/Videos/x2r" = {
    device = "/dev/mapper/matoba";
    fsType = "ext4";  # Adjust to match your inner filesystem type (e.g., ext4, xfs)
    options = [ "noauto" "nofail" ];
  };
}
