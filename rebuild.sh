# Based on NoBoilerplates' dotfiles. I love his youtube channel
set -e

nixhost=$(cat nixhost)
sudo nix flake lock
git add .
echo "NixOS Rebuilding and switching for host $nixhost"
time nh os switch . --hostname "$nixhost"
gen=$(nixos-rebuild list-generations | grep current)
git commit -m "${nixhost}: $gen"
