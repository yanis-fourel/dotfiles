{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.lazydocker
  ];
  virtualisation.docker.enable = true;

  users.users.yanis.extraGroups = [ "docker" ];

}
