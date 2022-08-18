local lspconfig = require('lspconfig')
local rust_tools = require('rust-tools')

local M = {}

M.setup = function(capabilities)
	rust_tools.setup({
		capabilities = capabilities,
		tools = { -- rust-tools options
			-- automatically set inlay hints (type hints)
			-- There is an issue due to which the hints are not applied on the first
			-- opened file. For now, write to the file to trigger a reapplication of
			-- the hints or just run :RustSetInlayHints.
			-- default: true
			autoSetHints = true,

			-- whether to show hover actions inside the hover window
			-- this overrides the default hover handler so something like lspsaga.nvim's hover would be overriden by this
			-- default: true
			hover_with_actions = true,

			-- how to execute terminal commands
			-- options right now: termopen / quickfix
			executor = require("rust-tools/executors").termopen,

			-- callback to execute once rust-analyzer is done initializing the workspace
			-- The callback receives one parameter indicating the `health` of the server: "ok" | "warning" | "error"
			on_initialized = nil,

			-- These apply to the default RustSetInlayHints command
			inlay_hints = {

				-- Only show inlay hints for the current line
				only_current_line = true,

				-- Event which triggers a refersh of the inlay hints.
				-- You can make this "CursorMoved" or "CursorMoved,CursorMovedI" but
				-- not that this may cause higher CPU usage.
				-- This option is only respected when only_current_line and
				-- autoSetHints both are true.
				only_current_line_autocmd = "CursorHold",

				-- whether to show parameter hints with the inlay hints or not
				-- default: true
				show_parameter_hints = false,

				-- whether to show variable name before type hints with the inlay hints or not
				-- default: false
				show_variable_name = true,

				-- prefix for parameter hints
				-- default: "<-"
				parameter_hints_prefix = "<- ",

				-- prefix for all the other hints (type, chaining)
				-- default: "=>"
				other_hints_prefix = " ",

				-- whether to align to the lenght of the longest line in the file
				max_len_align = false,

				-- padding from the left if max_len_align is true
				max_len_align_padding = 1,

				-- whether to align to the extreme right or not
				right_align = false,

				-- padding from the right if right_align is true
				right_align_padding = 7,

				-- The color of the hints
				highlight = "Comment",
			}
		},

		-- all the opts to send to nvim-lspconfig
		-- these override the defaults set by rust-tools.nvim
		-- see https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer
		server = {
			-- on_attach is a callback called when the language server attachs to the buffer
			-- on_attach = on_attach,
			settings = {
				-- to enable rust-analyzer settings visit:
				-- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
				["rust-analyzer"] = {
					-- enable clippy on save
					checkOnSave = {
						command = "clippy"
					},
				}
			}
		},
	})
end

return M
