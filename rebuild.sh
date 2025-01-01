# Based on NoBoilerplates' dotfiles. I love his youtube channel
set -e

nixhost=$(cat nixhost)
git add nix flake.nix flake.lock
sudo nix flake lock
echo "NixOS Rebuilding and switching for host $nixhost"
sudo nixos-rebuild --flake ".#$nixhost" switch # || (cat nixos-switch.log | grep --color error && false)
gen=$(nixos-rebuild list-generations | grep current)
git commit -m "${nixhost}: $gen"
