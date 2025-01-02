{
  description = "Yanis system";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    # rust toolchain
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    rnix = {
      url = "github:nix-community/rnix-lsp";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      fenix,
      ghostty,
      ...
    }@inputs:
    {
      packages.x86_64-linux.default = fenix.packages.x86_64-linux.minimal.toolchain;

      nixosConfigurations.yanix = nixpkgs.lib.nixosSystem {
        specialArgs = rec {
          system = "x86_64-linux";
          inherit inputs;
          pkg_ghostty = ghostty.packages.${system}.default;
        };
        modules = [ ./nix/hosts/yanix/config.nix ];
      };

      nixosConfigurations.ledr-yanix = nixpkgs.lib.nixosSystem {
        specialArgs = rec {
          system = "x86_64-linux";
          inherit inputs;
          pkg_ghostty = ghostty.packages.${system}.default;
        };
        modules = [ ./nix/hosts/ledr-yanix/config.nix ];
      };
    };
}
