local function pyright(capabilities)
	return {
		capabilities = capabilities,
		settings = {
			python = {
				analysis = {
					diagnosticSeverityOverrides = {
						reportInvalidTypeForm = "none", -- causes problem with avial types
					},
				},
			},
		},
	}
end

local function pylint(capabilities)
	local venv = os.getenv("VIRTUAL_ENV")
	local pylint_executable = "pylint"
	if venv ~= nil then
		if vim.fn.executable(venv .. "/bin/pylint") == 1 then
			pylint_executable = venv .. "/bin/pylint"
		else
			vim.notify(
				"pylint not found in virtual environment: "
					.. venv
					.. ". It may not resolve depencies correctly. `pip install pylint` in your venv",
				vim.log.levels.WARN
			)
		end
	end

	vim.notify("Using pylint executable: " .. pylint_executable, vim.log.levels.INFO)

	return {
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
					},
				},
			},
		},
	}
end

local function ruff(capabilities)
	return {
		capabilities = capabilities,
		settings = {},
	}
end

return function(capabilities)
	local capabilities_ruff = vim.deepcopy(capabilities)
	capabilities_ruff.documentFormattingProvider = false

	return {
		pyright = pyright(capabilities),
		-- pylint = pylint(capabilities),
		ruff = ruff(capabilities_ruff),
	}
end
