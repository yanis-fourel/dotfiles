local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.completion.spell,

		-- TODO: check that: null_ls.builtins.formatting.autopep8
		-- TODO:    or that: null_ls.builtins.formatting.black

		-- Go
        null_ls.builtins.formatting.gofmt,
        -- null_ls.builtins.formatting.goimports_reviser

		-- Python
		null_ls.builtins.formatting.black,

		-- Rust
		null_ls.builtins.formatting.rustfmt,
    },
})
