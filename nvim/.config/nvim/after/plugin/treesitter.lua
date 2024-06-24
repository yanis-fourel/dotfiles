require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = { "c", "cpp" },
  },
  ensure_installed = {
    "c",
    "cpp",
    "lua",
    "rust",
    "python",
    "json",
    "yaml",
  },
}

local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.hypr = {
  install_info = {
    url = 'https://github.com/luckasRanarison/tree-sitter-hypr',
    files = { 'src/parser.c' },
    branch = 'master',
  },
  filetype = 'hypr',
}
