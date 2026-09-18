{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.lazydocker
  ];
  virtualisation.docker.enable = true;

  users.users.yanis.extraGroups = [ "docker" ];

  virtualisation.docker.daemon.settings.features.cdi = true;  # Enables Container Device Interface for GPU access.
}
