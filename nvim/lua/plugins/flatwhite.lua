return {
	"elladunbar/flatwhite-theme",
	branch = "neovim",
	lazy = false,
	priority = 1000,
	config = function()
		-- 'background' is detected from the terminal (OSC 11) and updated
		-- live when the terminal switches themes (DEC mode 2031)
		local function apply()
			vim.cmd.colorscheme(vim.o.background == "light" and "flatwhite" or "flatdark")
		end
		apply()
		vim.api.nvim_create_autocmd("OptionSet", {
			pattern = "background",
			callback = apply,
		})
	end,
}
