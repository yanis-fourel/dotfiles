{
  pkgs,
  upkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.sonarlint-ls

    pkgs.typescript
    pkgs.typescript-language-server
    pkgs.svelte-language-server
    pkgs.vscode-langservers-extracted # for eslint and more
    pkgs.nodejs_22
    pkgs.eslint_d
    pkgs.nodemon

    pkgs.yaml-language-server

    pkgs.bash-language-server

    pkgs.lua-language-server
    pkgs.stylua

    pkgs.go
    pkgs.gopls

    pkgs.nil # Nix Language server

    pkgs.clang
    pkgs.clang-tools

    pkgs.python311 # LEDR uses python 3.11
    pkgs.black
    pkgs.pyright
    pkgs.ruff

    (pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    pkgs.rust-analyzer-nightly

    upkgs.zls
    upkgs.zig

    pkgs.kotlin
    pkgs.kotlin-language-server
    pkgs.openjdk
    pkgs.gradle
  ];
}
