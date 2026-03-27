return {
	"nvim-treesitter/nvim-treesitter",
	config = function()
		local filetypes = {
			"arduino",
			"asm",
			"bash",
			"c",
			"clojure",
			"cmake",
			"css",
			"csv",
			"djot",
			"fish",
			"gitcommit",
			"gitignore",
			"haskell",
			"html",
			"hyprlang",
			"java",
			"javascript",
			"json",
			"julia",
			"latex",
			"lua",
			"make",
			"markdown",
			"markdown_inline",
			"matlab",
			"nix",
			"nu",
			"printf",
			"prolog",
			"python",
			"query",
			"r",
			"racket",
			"regex",
			"requirements",
			"ruby",
			"rust",
			"scss",
			"sql",
			"swift",
			"toml",
			"vim",
			"vimdoc",
			"xml",
			"yaml",
			"yuck",
			"zathurarc",
			"zig",
		}
		require("nvim-treesitter").install(filetypes)

		for _, filetype in ipairs(filetypes) do
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { filetype },
				callback = function()
					vim.treesitter.start()
					vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					vim.wo[0][0].foldmethod = "expr"
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end
	end,
	lazy = false,
	build = ":TSUpdate",
}
