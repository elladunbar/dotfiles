return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		spec = {
			-- buffers
			{
				"<leader>b",
				group = "buffers",
				expand = function()
					return require("which-key.extras").expand.buf()
				end,
			},
			{ "<leader>bn", "<cmd>bn<cr>", desc = "Jump to next buffer" },
			{ "<leader>bp", "<cmd>bp<cr>", desc = "Jump to previous buffer" },
			{ "<leader>bx", "<cmd>bd<cr>", desc = "Close current buffer" },

			-- custom user
			{ "<leader>c", group = "custom" },
			{
				"<leader>cc",
				function()
					vim.cmd('normal! gg"+yG')
					vim.cmd("x")
				end,
				desc = "Copy & exit",
			},
			{ "<leader>ce", "<cmd>!./%<cr>", desc = "Execute current file" },
			{ "<leader>cp", "<cmd>silent !pandoc -V geometry:margin=1in -i % -o %:r.pdf<cr>", desc = "Convert to PDF" },

			-- telescope
			{ "<leader>f", group = "telescope" },

			-- misc
			{ "<leader>h", "<cmd>nohlsearch<cr>", desc = "Remove match highlighting" },

			-- lsp
			{ "<leader>l", proxy = "gr", group = "lsp" },

			-- windows
			{ "<leader>w", proxy = "<c-w>", group = "windows" },
		},
		icons = {
			separator = "",
		},
	},
}
