vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("ts-remove-unused-imports", { clear = true }),
	buffer = 0,
	callback = function()
		local clients = vim.lsp.get_clients({ bufnr = 0, name = "ts_ls" })
		if #clients == 0 then
			return
		end
		vim.lsp.buf.code_action({
			apply = true,
			context = {
				only = { "source.removeUnusedImports.ts" },
				diagnostics = {},
			},
		})
	end,
})
