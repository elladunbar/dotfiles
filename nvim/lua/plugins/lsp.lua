return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"folke/lazydev.nvim",
			"p00f/clangd_extensions.nvim",
		},
		config = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				cmp_nvim_lsp.default_capabilities()
			)

			-- LSP server setups
			local servers = {
				"bashls",
				"clangd",
				"cssls",
				"html",
				"jdtls",
				"jsonls",
				"lua_ls",
				"perlnavigator",
				"r_language_server",
				"ruff",
				"rust_analyzer",
				"texlab",
				"ty",
			}

			for _, server in ipairs(servers) do
				if server == "lua_ls" then
					vim.lsp.config(server, {
						capabilities = capabilities,
						on_attach = REGISTER_SERVER(server),
						settings = {
							Lua = {
								completion = { callSnippet = "Replace", showWord = "Fallback" },
								workspace = { checkThirdParty = "Disable" },
							},
						},
					})
				else
					vim.lsp.config(server, {
						capabilities = capabilities,
						on_attach = REGISTER_SERVER(server),
					})
				end
			end

			vim.lsp.enable(servers)
		end,
		event = "BufReadPre",
		keys = {
			-- navigation
			{
				"gd",
				function()
					return require("telescope.builtin").lsp_definitions()
				end,
				desc = "Goto definition",
			},
			{
				"gr",
				function()
					return require("telescope.builtin").lsp_references()
				end,
				desc = "References",
			},
			{
				"gD",
				vim.lsp.buf.declaration,
				desc = "Goto declaration",
			},
			{
				"gI",
				function()
					return require("telescope.builtin").lsp_implementations()
				end,
				desc = "Goto implementation",
			},
			{
				"gy",
				function()
					return require("telescope.builtin").lsp_type_definitions()
				end,
				desc = "Goto t[y]pe definition",
			},

			-- actions
			{
				"<leader>lc",
				function()
					vim.lsp.buf.code_action()
				end,
				desc = "Code actions",
			},
			{
				"<leader>lr",
				function()
					vim.lsp.buf.rename()
				end,
				desc = "Rename symbol",
			},
		},
	},
	{
		"nvimtools/none-ls.nvim",
		config = function()
			local null_ls = require("null-ls")

			null_ls.setup({
				sources = {},
				on_attach = REGISTER_SERVER("null-ls"),
			})
		end,
		event = "BufReadPre",
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
	},
}
