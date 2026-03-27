return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = {
			ensure_installed = {
				"arduino-language-server",
				"bash-language-server",
				"clang-format",
				"clangd",
				"css-lsp",
				"haskell-language-server",
				"html-lsp",
				"jdtls",
				"json-lsp",
				"lua-language-server",
				"perlnavigator",
				"ruff",
				"rust-analyzer",
				"stylua",
				"texlab",
				"ty",
				"typescript-language-server",
				"zls",
			},
		},
		cmd = { "MasonToolsInstall", "MasonToolsClean", "MasonToolsUpdate" },
	},
	{
		"williamboman/mason.nvim",
		lazy = true,
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			vim.cmd("MasonToolsClean")
			vim.cmd("MasonToolsUpdate")
		end,
	},
}
