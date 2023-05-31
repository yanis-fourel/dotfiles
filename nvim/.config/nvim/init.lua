require('dz')

function reload_config()
	for name,_ in pairs(package.loaded) do
		if name:match('^dz') then
			package.loaded[name] = nil
		end
	end

	require('dz')

	-- Reload after/ directory
	local glob = vim.fn.stdpath('config') .. '/after/**/*.lua'
	local after_lua_filepaths = vim.fn.glob(glob, true, true)

	for _, filepath in ipairs(after_lua_filepaths) do
		dofile(filepath)
	end

	vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
end
vim.keymap.set('n', '<leader><leader><leader>x', reload_config)


