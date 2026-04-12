return {
	"yetone/avante.nvim",
	build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
		or "make",
	version = false,
	event = "VeryLazy",
	---@module 'avante'
	---@type avante.Config
	opts = {
		provider = "claude", -- The provider used in Aider mode or in the planning phase of Cursor Planning Mode
		mode = "agentic", -- The default mode for interaction. "agentic" uses tools to automatically generate code, "legacy" uses the old planning method to generate code.
		instructions_file = "agent.md",

		auto_suggestions_provider = "claude_cheap",
		providers = {
			claude_smart = {
				endpoint = "https://api.anthropic.com",
				auth_type = "api",
				model = "claude-opus-4-6",
				extra_request_body = {
					temperature = 0.75,
					max_tokens = 4096,
				},
			},
			claude_cheap = {
				__inherited_from = "claude",
				model = "claude-haiku-4-5",
			},
		},

		behaviour = {
			auto_suggestions = false, -- Disabled - use copilot.lua instead for inline completions
			auto_set_highlight_group = true,
			auto_set_keymaps = true,
			auto_apply_diff_after_generation = false,
			support_paste_from_clipboard = false,
			minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
			enable_token_counting = true, -- Whether to enable token counting. Default to true.
			auto_add_current_file = true, -- Whether to automatically add the current file when opening a new chat. Default to true.
			auto_approve_tool_permissions = true, -- Default: auto-approve all tools (no prompts)
			-- Examples:
			-- auto_approve_tool_permissions = false,                -- Show permission prompts for all tools
			-- auto_approve_tool_permissions = {"bash", "str_replace"}, -- Auto-approve specific tools only
			---@type "popup" | "inline_buttons"
			confirmation_ui_style = "inline_buttons",
			--- Whether to automatically open files and navigate to lines when ACP agent makes edits
			---@type boolean
			acp_follow_agent_locations = true,
		},
		mappings = {
			--- @class AvanteConflictMappings
			diff = {
				ours = "co",
				theirs = "ct",
				all_theirs = "ca",
				both = "cb",
				cursor = "cc",
				next = "]x",
				prev = "[x",
			},
			suggestion = {
				accept = "<Right>",
				next = "<M-]>",
				prev = "<M-[>",
				dismiss = "<C-]>",
			},
			jump = {
				next = "]]",
				prev = "[[",
			},
			submit = {
				normal = "<CR>",
				insert = "<C-s>",
			},
			cancel = {
				normal = { "<C-c>", "<Esc>", "q" },
				insert = { "<C-c>" },
			},
			sidebar = {
				apply_all = "A",
				apply_cursor = "a",
				retry_user_request = "r",
				edit_user_request = "e",
				switch_windows = "<Tab>",
				reverse_switch_windows = "<S-Tab>",
				remove_file = "d",
				add_file = "@",
				close = { "<Esc>", "q" },
				close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
			},
		},
		selection = {
			enabled = true,
			hint_display = "none",
		},
		windows = {
			---@type "right" | "left" | "top" | "bottom"
			position = "right", -- the position of the sidebar
			wrap = true, -- similar to vim.o.wrap
			width = 30, -- default % based on available width
			sidebar_header = {
				enabled = true, -- true, false to enable/disable the header
				align = "center", -- left, center, right for title
				rounded = true,
			},
			spinner = {
				-- stylua: ignore
				editing = { "⡀", "⠄", "⠂", "⠁", "⠈", "⠐", "⠠", "⢀", "⣀", "⢄", "⢂", "⢁", "⢈", "⢐", "⢠", "⣠", "⢤", "⢢", "⢡", "⢨", "⢰", "⣰", "⢴", "⢲", "⢱", "⢸", "⣸", "⢼", "⢺", "⢹", "⣹", "⢽", "⢻", "⣻", "⢿", "⣿" },
				generating = { "·", "✢", "✳", "∗", "✻", "✽" }, -- Spinner characters for the 'generating' state
				thinking = { "🤯", "🙄" }, -- Spinner characters for the 'thinking' state
			},
			input = {
				prefix = "> ",
				height = 8, -- Height of the input window in vertical layout
			},
			edit = {
				border = "rounded",
				start_insert = true, -- Start insert mode when opening the edit window
			},
			ask = {
				floating = false, -- Open the 'AvanteAsk' prompt in a floating window
				start_insert = true, -- Start insert mode when opening the ask window
				border = "rounded",
				---@type "ours" | "theirs"
				focus_on_apply = "ours", -- which diff to focus after applying
			},
		},
		suggestion = {
			debounce = 600,
			throttle = 600,
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons", -- optional but nice
		"HakonHarnes/img-clip.nvim", -- optional (paste images into chat)

		-- Markdown rendering for the Avante chat window
		{
			"MeanderingProgrammer/render-markdown.nvim",
			ft = { "markdown", "Avante" },
			opts = { file_types = { "markdown", "Avante" } },
		},

		-- Blink-cmp integration (for @mentions, /commands, file selector inside Avante chat)
		"saghen/blink.compat",
	},

	config = function(_, opts)
		require("avante").setup(opts)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "markdown", "help", "gitcommit" }, -- add whatever you want to disable
			callback = function()
				vim.b.avante_auto_suggestions = false
			end,
		})
	end,
}
