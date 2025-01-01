require("ibl").setup({
	scope = {
		enabled = true,
		show_exact_scope = true,
		show_end = false,
		include = {
			node_type = { lua = { "return_statement", "table_constructor" } },
		},
	},
})
