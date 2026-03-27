return {
	"elladunbar/flatwhite-theme",
	branch = "neovim",
	lazy = false,
	priority = 1000,
	config = function()
		if vim.o.background == "light" then
			COLOR_THEME = "flatwhite"
		else
			COLOR_THEME = "flatdark"
		end
		vim.cmd.colorscheme(COLOR_THEME)
	end,
}
