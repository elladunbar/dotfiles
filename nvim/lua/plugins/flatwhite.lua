return {
	"elladunbar/flatwhite-theme",
	branch = "neovim",
	lazy = false,
	priority = 1000,
	config = function()
		if vim.o.background == "light" then
			vim.cmd.colorscheme("flatwhite")
			COLOR_THEME = "flatwhite"
		else
			vim.cmd.colorscheme("flatdark")
			COLOR_THEME = "flatdark"
		end
	end,
}
