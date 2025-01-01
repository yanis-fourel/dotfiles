# Based on NoBoilerplates' dotfiles. I love his youtube channel

set -e
git add .
sudo nix flake lock
git add .
echo "NixOS Rebuilding..."
sudo nixos-rebuild --flake .#ledr-yanix switch # || (cat nixos-switch.log | grep --color error && false)
gen=$(nixos-rebuild list-generations | grep current)
git add .
git commit -m "$gen"
