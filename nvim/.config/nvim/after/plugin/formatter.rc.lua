if not vim.g.loaded_formatter then return end

require('formatter').setup({
  filetype = {
    c = {
        -- clang-format
       function()
          return {
            exe = "clang-format",
            args = {"--assume-filename", vim.api.nvim_buf_get_name(0)},
            stdin = true,
            cwd = vim.fn.expand('%:p:h')  -- Run clang-format in cwd of the file.
          }
        end
    },
  }
});

vim.api.nvim_set_keymap('n', '<Leader>f', ':Format<CR>', {noremap = true})
