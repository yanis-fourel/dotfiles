{pkgs, ...}:
{
  environment.systemPackages = [
    pkgs.docker
    pkgs.docker-compose
    pkgs.lazydocker
    pkgs.nvidia-container-toolkit
  ];
  virtualisation.docker.enable = true;

  users.users.yanis.extraGroups = [ "docker" ];

}
