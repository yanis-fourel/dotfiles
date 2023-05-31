local M = {}


local dap = require('dap')
local dapui = require('dapui')


-- should that be local to the tab or something ?
local is_debugging = false
M.is_debugging = function() return is_debugging end


local dapui_setup_arg =
{
	controls =
	{
		element = "repl",
		enabled = false,
		icons =
		{
			disconnect = "",
			pause = "",
			play = "",
			run_last = "",
			step_back = "",
			step_into = "",
			step_out = "",
			step_over = "",
			terminate = ""
		}
	},
	element_mappings = {},
	expand_lines = true,
	floating =
	{
		border = "single",
		mappings =
		{
			close = { "q", "<Esc>" }
		}
	},
	force_buffers = true,
	icons =
	{
		collapsed = "",
		current_frame = "",
		expanded = ""
	},
	layouts =
	{
		{
			elements =
			{
				{
					id = "stacks",
					size = 0.40
				},
				{
					id = "scopes",
					size = 0.40
				},
				{
					id = "watches",
					size = 0.20
				},
			},
			position = "left",
			size = 40
		},
		{
			elements =
			{
				{
					id = "console",
					size = 1.0
				}
			},
			position = "bottom",
			size = 10
		}
	},
	mappings = {},
	render =
	{
		indent = 1,
		max_value_lines = 100
	}
}


function continue_or_start_debug()
	if is_debugging then
		dap.continue()
		return
	end

	if vim.bo.filetype == "rust" then
		vim.cmd("RustDebuggables")
	else
		dap.continue()
	end
end

M.setup = function()
	require('telescope').load_extension('dap')

	-- languages
	require('dap-python').setup('python')

	dapui.setup(dapui_setup_arg)

	vim.keymap.set('n', '<M-Enter>', continue_or_start_debug)

	vim.keymap.set('n', '<M-S-l>', dap.step_over)
	vim.keymap.set('n', '<M-S-u>', dap.step_out)
	vim.keymap.set('n', '<M-S-y>', dap.step_into)
	vim.keymap.set('n', '<M-S-j>', dap.toggle_breakpoint)
	vim.keymap.set('n', '<M-S-v>', dap.run_to_cursor)

	vim.keymap.set('n', '<M-S-k>', dapui.toggle)
	vim.keymap.set('n', '<M-S-h>', dapui.elements.watches.add)
	vim.keymap.set('v', '<M-S-h>', dapui.elements.watches.add)
	vim.keymap.set('n', '<leader>fb', ':Telescope dap list_breakpoints<CR>')



	dap.listeners.after.event_initialized["dapui_config"] = function()
		is_debugging = true
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		is_debugging = false
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		is_debugging = false
	end
end




--- Inspect what's below the cursor on a floating window
--- calling it again will move cursor into the window
M.inspect_symbol = function()
	dapui.eval()
end


M.toggle_focus_depl = function()

end

return M

