return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "1.*",
	dependencies = {
		"fang2hou/blink-copilot",
		-- Snippet Engine & friendly-snippets (exactly like before)
		{
			"L3MON4D3/LuaSnip",
			build = (function()
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				{
					"rafamadriz/friendly-snippets",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
				},
			},
		},

		-- Lua dev environment (exactly like before)
		{
			"folke/lazydev.nvim",
			ft = "lua",
			opts = {
				library = {
					{ path = "luvit-meta/library", words = { "vim%.uv" } },
				},
			},
		},
		{ "Bilal2453/luvit-meta", lazy = true },
	},

	opts = {
		keymap = {
			preset = "none", -- we define everything manually to match your old config
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },

			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },

			["<C-n>"] = { "accept", "fallback" }, -- same as your old confirm
			["<C-Space>"] = { "show", "fallback" }, -- manual trigger

			["<C-l>"] = { "snippet_forward", "fallback" },
			["<C-h>"] = { "snippet_backward", "fallback" },
		},

		appearance = {
			nerd_font_variant = "mono", -- clean icons (replaces lspkind)
		},

		completion = {
			documentation = { auto_show = true }, -- shows docs automatically in the menu
			ghost_text = { enabled = true }, -- subtle preview of the selected item
			menu = {
				auto_show = true,
				draw = {
					columns = { { "kind_icon" }, { "label", "kind" } },
				},
			},
		},

		signature = { enabled = true }, -- built-in, replaces lsp_signature.nvim

		snippets = { preset = "luasnip" }, -- native LuaSnip support, no extra cmp_luasnip needed

		sources = {
			default = {
				"lsp",
				"path",
				"snippets",
				"buffer",
				"copilot",
				"avante_commands",
				"avante_mentions",
				"avante_files",
				"avante_shortcuts",
			},
			providers = {
				copilot = {
					name = "copilot",
					module = "blink-copilot",
					async = true,
				},
				avante_commands = {
					name = "avante_commands",
					module = "blink.compat.source",
					score_offset = 90,
				},
				avante_mentions = {
					name = "avante_mentions",
					module = "blink.compat.source",
					score_offset = 1000,
				},
				avante_files = {
					name = "avante_files",
					module = "blink.compat.source",
					score_offset = 100,
				},
				avante_shortcuts = {
					name = "avante_shortcuts",
					module = "blink.compat.source",
					score_offset = 1000,
				},
			},
		},
	},
}
