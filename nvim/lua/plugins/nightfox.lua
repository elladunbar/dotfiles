return {
	"EdenEast/nightfox.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("nightfox").setup({
			options = {
				transparent = true,
				styles = {
					comments = "italic",
					conditionals = "bold",
					keywords = "italic",
					types = "italic,bold",
				},
			},
		})
	end,
}
