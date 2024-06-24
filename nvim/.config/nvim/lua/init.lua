vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")
require("autocmd")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local plugins = {}
local glob = vim.fn.stdpath("config") .. "/lua/plugins/*.lua"
for _, mod in pairs(vim.fn.glob(glob, true, true)) do
	local content = dofile(mod)
	table.insert(plugins, content)
end

require("lazy").setup(plugins)
