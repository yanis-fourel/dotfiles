{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
  ];
  virtualisation.docker.enable = true;

  users.users.yanis.extraGroups = [ "docker" ];

}
