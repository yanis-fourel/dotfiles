local lspconfig = require('lspconfig')

local M = {}

local augroup = vim.api.nvim_create_augroup("BlackAutoFmt", {})


local function autofmt_black(_, bufnr)
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = bufnr,
		callback = function()
			vim.lsp.buf.format({ bufnr = bufnr })
		end
	})
end

local function setup_pyright(capabilities)
	lspconfig.pyright.setup({
		capabilities = capabilities,
		settings = {
			python = {
				analysis = {
					diagnosticSeverityOverrides = {
						reportInvalidTypeForm = 'none', -- causes problem with avial types
					}
				},
			}
		},
		on_attach = autofmt_black,
	})
end

local function setup_pylint(capabilities)
	local venv = os.getenv("VIRTUAL_ENV")
	local pylint_executable = "pylint"
	if venv ~= nil then
		if vim.fn.executable(venv .. "/bin/pylint") == 1 then
			pylint_executable = venv .. "/bin/pylint"
		else
			vim.notify("pylint not found in virtual environment: " .. venv .. ". It may not resolve depencies correctly. `pip install pylint` in your venv", vim.log.levels.WARN)
		end
	end

	vim.notify("Using pylint executable: " .. pylint_executable, vim.log.levels.INFO)

	lspconfig.pylsp.setup({
		capabilities = capabilities,
		settings = {
			pylsp = {
				plugins = {
					autopep8 = {
						enabled = false,
					},
					flake8 = {
						enabled = false,
					},
					mccabe = { -- automatically detects over-complex code basing on cyclomatic complexity
						enabled = true,
					},
					preload = { -- give feedback while importing heavy modules
						enabled = false,
					},
					pycodestyle = {
						enabled = false, -- we use black
					},
					pydocstyle = {
						enabled = false,
					},
					pyflakes = {
						enabled = false,
					},
					pylint = {
						enabled = true,
						executable = pylint_executable,
					},
					yapf = {
						enabled = false,
					}
				}
			}
		},
		on_attach = autofmt_black,
	})
end


local function setup_ruff(capabilities)
	-- Used when in combinaison with pyright
	capabilities.documentFormattingProvider = false
	-- capabilities.hoverProvider = false
	-- capabilities.renameProvider = false

	lspconfig.ruff_lsp.setup({
		capabilities = capabilities,
		settings = {},
		-- on_attach = autofmt_black, -- disabled when used in combination with pyright
	})
end


M.setup = function(capabilities)
	setup_pyright(capabilities)
	-- setup_pylint(capabilities)
	setup_ruff(capabilities)
end

return M
