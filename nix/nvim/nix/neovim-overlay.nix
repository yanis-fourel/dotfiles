# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{ inputs }:
final: prev:
with final.pkgs.lib;
let
  pkgs = final;

  # Use this to create a plugin from a flake input
  mkNvimPlugin =
    src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
    };

  # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
  # otherwise it could have an incompatible signature when applying this overlay.
  pkgs-wrapNeovim = inputs.nixpkgs.legacyPackages.${pkgs.system};

  # This is the helper function that builds the Neovim derivation.
  mkNeovim = pkgs.callPackage ./mkNeovim.nix { inherit pkgs-wrapNeovim; };

  # A plugin can either be a package or an attrset, such as
  # { plugin = <plugin>; # the package, e.g. pkgs.vimPlugins.nvim-cmp
  #   config = <config>; # String; a config that will be loaded with the plugin
  #   # Boolean; Whether to automatically load the plugin as a 'start' plugin,
  #   # or as an 'opt' plugin, that can be loaded with `:packadd!`
  #   optional = <true|false>; # Default: false
  #   ...
  # }

  my-lazydev-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "my-lazydev-nvim";
    version = "2024-07-25";
    src = pkgs.fetchFromGitHub {
      owner = "folke";
      repo = "lazydev.nvim";
      rev = "491452cf1ca6f029e90ad0d0368848fac717c6d2";
      sha256 = "0f980fdab54f62859cf21b254eb1fb67dd1c13b5c4bbeb5f903e8567363f88f9";
    };
    meta.homepage = "https://github.com/folke/lazydev.nvim";
  };

  my-rainbow-csv-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "my-rainbow-csv-nvim";
    version = "2024-07-9";
    src = pkgs.fetchFromGitHub {
      owner = "cameron-wags";
      repo = "rainbow_csv.nvim";
      rev = "7f3fddfe813641035fac2cdf94c2ff69bb0bf0b9";
      sha256 = "fd71d077ffacaa155e78c02470a36f143285b8579c0a1ae0a79ea8a77290021b";
    };
    meta.homepage = "https://https://github.com/cameron-wags/rainbow_csv.nvim/commits/main/";
  };

  all-plugins = with pkgs.vimPlugins; [
    # https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=vimPlugins
    nvim-treesitter.withAllGrammars
    nvim-lspconfig
    fidget-nvim # https://github.com/j-hui/fidget.nvim/
    my-lazydev-nvim

    gruvbox-nvim # https://github.com/ellisonleao/gruvbox.nvim/
    tokyonight-nvim # https://github.com/folke/tokyonight.nvim/
    catppuccin-nvim # https://github.com/catppuccin/catppuccin
    dracula-nvim # https://github.com/Mofiqul/dracula.nvim/

    indent-blankline-nvim

    luasnip # snippets | https://github.com/l3mon4d3/luasnip/

    nvim-cmp # https://github.com/hrsh7th/nvim-cmp
    cmp_luasnip # snippets autocompletion extension for nvim-cmp | https://github.com/saadparwaiz1/cmp_luasnip/
    lspkind-nvim # vscode-like LSP pictograms | https://github.com/onsails/lspkind.nvim/
    cmp-nvim-lsp # LSP as completion source | https://github.com/hrsh7th/cmp-nvim-lsp/
    cmp-nvim-lsp-signature-help # https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/
    cmp-path # file paths as completion source | https://github.com/hrsh7th/cmp-path/
    cmp-nvim-lua # neovim lua API as completion source | https://github.com/hrsh7th/cmp-nvim-lua/
    cmp-cmdline # cmp command line suggestions
    cmp-cmdline-history # cmp command line history suggestions

    diffview-nvim # https://github.com/sindrets/diffview.nvim/
    neogit # https://github.com/TimUntersberger/neogit/
    gitsigns-nvim # https://github.com/lewis6991/gitsigns.nvim/

    oil-nvim # https://github.com/stevearc/oil.nvim/
    harpoon2 # https://github.com/ThePrimeagen/harpoon/

    telescope-nvim # https://github.com/nvim-telescope/telescope.nvim/
    telescope-fzf-native-nvim
    telescope-ui-select-nvim # https://github.com/nvim-telescope/telescope-ui-select.nvim
    telescope-file-browser-nvim # https://github.com/nvim-telescope/telescope-file-browser.nvim/

    nvim-treesitter-context # nvim-treesitter-context

    vim-unimpaired # predefined ] and [ navigation keymaps | https://github.com/tpope/vim-unimpaired/
    eyeliner-nvim # Highlights unique characters for f/F and t/T motions | https://github.com/jinh0/eyeliner.nvim
    nvim-surround # https://github.com/kylechui/nvim-surround/
    nvim-treesitter-textobjects # https://github.com/nvim-treesitter/nvim-treesitter-textobjects/
    nvim-ts-context-commentstring # https://github.com/joosepalviste/nvim-ts-context-commentstring/

    nvim-unception # Prevent nested neovim sessions | nvim-unception
    nvim-notify # https://github.com/rcarriga/nvim-notify/
    vim-sleuth # Detect tabstop and shiftwidth automatically
    vim-cool # Disables hlsearch when you are done searching and re-enables it when you search again
    vim-abolish # :S command and more I don't know
    mini-nvim # https://github.com/echasnovski/mini.nvim/
    tabular
    my-rainbow-csv-nvim
    todo-comments-nvim
    treesj # https://github.com/Wansmer/treesj/
    undotree

    conform-nvim # autoformat

    crates-nvim # https://github.com/saecki/crates.nvim/
    # TODO https://github.com/vxpm/ferris.nvim/

    # libraries that other plugins depend on
    sqlite-lua
    plenary-nvim
    nvim-web-devicons # https://github.com/nvim-tree/nvim-web-devicons/
    vim-repeat
    # ^ libraries that other plugins depend on
    # bleeding-edge plugins from flake inputs
    # (mkNvimPlugin inputs.wf-nvim "wf.nvim") # (example) keymap hints | https://github.com/Cassin01/wf.nvim
    # ^ bleeding-edge plugins from flake inputs
    which-key-nvim
  ];

  extraPackages = with pkgs; [
    # language servers, etc.
    lua-language-server
    nil # nix LSP
    nixfmt-rfc-style
    stylua # lua formatter
    gopls
  ];
in
{
  # This is the neovim derivation
  # returned by the overlay
  nvim-pkg = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
  };

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json { plugins = all-plugins; };

  # You can add as many derivations as you like.
  # Use `ignoreConfigRegexes` to filter out config
  # files you would not like to include.
  #
  # For example:
  #
  # nvim-pkg-no-telescope = mkNeovim {
  #   plugins = [];
  #   ignoreConfigRegexes = [
  #     "^plugin/telescope.lua"
  #     "^ftplugin/.*.lua"
  #   ];
  #   inherit extraPackages;
  # };
}
