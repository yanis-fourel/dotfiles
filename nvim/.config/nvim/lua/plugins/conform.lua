local find_ruff_cmd = function()
  local local_ruff = vim.fn.getcwd() .. "/.venv/bin/ruff"
  if vim.fn.executable(local_ruff) == 1 then
    return local_ruff 
  else
    return "ruff"
  end
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    formatters_by_ft = {
      python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
      lua = { "stylua" },
    },

    format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = false,
      async = false,
    },

    formatters = {
      ruff_fix = {
        command = find_ruff_cmd,
        args = { "check", "--fix", "--exit-zero", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      ruff_format = {
        command = find_ruff_cmd,
        args = { "format", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      ruff_organize_imports = {
        command = find_ruff_cmd,
        args = { "check", "--select", "I", "--fix", "--exit-zero", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
    },
  },
}
