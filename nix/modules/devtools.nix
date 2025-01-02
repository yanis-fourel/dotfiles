{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.typescript
    pkgs.typescript-language-server
    pkgs.svelte-language-server
    pkgs.vscode-langservers-extracted # for eslint and more
    pkgs.nodejs_22

    pkgs.bash-language-server

    pkgs.lua-language-server

    pkgs.go
    pkgs.gopls

    pkgs.zig
    pkgs.zls

    inputs.rnix

    pkgs.clang
    pkgs.clang-tools

    pkgs.python3
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
  ];
}
