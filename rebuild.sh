# Based on NoBoilerplates' dotfiles. I love his youtube channel

set -e
git add nix flake.nix flake.lock
sudo nix flake lock
echo "NixOS Rebuilding..."
sudo nixos-rebuild --flake .#yanix switch # || (cat nixos-switch.log | grep --color error && false)
gen=$(nixos-rebuild list-generations | grep current)
git commit -m "$gen"
