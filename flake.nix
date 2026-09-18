{
  description = "Yanis system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # rust toolchain
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      fenix,
      ghostty,
      zen-browser,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      upkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    in
    {
      packages.${system}.default = fenix.packages.${system}.minimal.toolchain;

      nixosConfigurations.yanix = nixpkgs.lib.nixosSystem {
        specialArgs = rec {
          inherit inputs;
          inherit upkgs;
          inherit system;
          pkg_ghostty = ghostty.packages.${system}.default;
          pkg_zen-browser = zen-browser.packages.${system}.specific;
        };
        modules = [ ./nix/hosts/yanix/config.nix ];
      };

      nixosConfigurations.ledr-yanix = nixpkgs.lib.nixosSystem {
        specialArgs = rec {
          system = "x86_64-linux";
          inherit inputs;
          inherit upkgs;
          pkg_ghostty = ghostty.packages.${system}.default;
        };
        modules = [ ./nix/hosts/ledr-yanix/config.nix ];
      };
    };
}
