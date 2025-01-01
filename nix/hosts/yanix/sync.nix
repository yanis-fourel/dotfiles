{ config, lib, ... }:
let
  cfg = config.services.sync;
in
{
  options.services.sync = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable sync.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # This requires manually creating the /etc/davfs2/secrets file like:
    # https://u425237.your-storagebox.de  <username>  <password>
    services.davfs2 = {
      enable = true;
      settings = {
        globalSection = {
          cache_size = 10240; # 10Gib
        };
      };
    };

    systemd.mounts = [
      {
        enable = true;
        description = "'sync' webdav mount point";
        what = "https://u425237.your-storagebox.de";
        where = "/mnt/mys3";
        options = "uid=1000,gid=100,file_mode=0664,dir_mode=2775";
        type = "davfs";
        mountConfig.TimeoutSec = 15;
      }
    ];
    systemd.automounts = [
      {
        description = "Automount for 'sync' webdav mount point";
        where = "/mnt/mys3";
        wantedBy = [ "multi-user.target" ];
      }
    ];
  };
}
