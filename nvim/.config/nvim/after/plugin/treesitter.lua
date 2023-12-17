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

local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.hypr = {
  install_info = {
    url = 'https://github.com/luckasRanarison/tree-sitter-hypr',
    files = { 'src/parser.c' },
    branch = 'master',
  },
  filetype = 'hypr',
}
