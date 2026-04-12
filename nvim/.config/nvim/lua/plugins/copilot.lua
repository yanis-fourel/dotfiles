return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	opts = {
		server = {
			settings = {
				["*"] = {
					-- stylua: ignore
					filetypes = { "javascript", "typescript", "python", "lua", "rust", "go", "java", "c", "cpp", "ruby", "php", "swift", "kotlin", "scala", "html", "css", "scss", "json", "yaml", "toml", "markdown", "sql", "shell", "bash", "zsh", "fish", "dockerfile", "nix" },
				},
			},
		},
		suggestion = {
			auto_trigger = true,
			keymap = {
				accept = "<Right>",
			},
		},
		panel = {
			keymap = {
				accept = "<Right>",
			},
		},
	},
}
