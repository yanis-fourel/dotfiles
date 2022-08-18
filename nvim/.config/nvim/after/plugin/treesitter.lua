require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = false,
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
