require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
  },
  ensure_installed = {
    "c",
    "lua",
    "rust",
    "cpp",
    "python",
    "json",
    "yaml",
  },
}
