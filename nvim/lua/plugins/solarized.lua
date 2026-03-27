return {
	"maxmx03/solarized.nvim",
    enabled = false,
	lazy = false,
	priority = 1000,
	config = function()
		require("solarized").setup({
			transparent = { enabled = true },
			variant = "autumn",
			styles = {
				comments = { italic = true },
				keywords = { italic = true },
				types = { italic = true, bold = true },
			},
		})

        vim.cmd("color solarized")
        COLOR_THEME = "solarized"
	end,
}
