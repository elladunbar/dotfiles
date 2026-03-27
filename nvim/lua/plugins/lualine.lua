local function current_servers()
	local servers = LSP_SERVERS[vim.api.nvim_get_current_buf()] or {}

	local current = ""
	local num_servers = 0
	for server, loaded in pairs(servers) do
		if loaded then
			current = current .. " " .. server
			num_servers = num_servers + 1
		end
	end

	if num_servers ~= 0 then
		current = "󰒋" .. current
	end

	return current
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = "nvim-tree/nvim-web-devicons",
	lazy = false,
	config = function()
		local opts = {}

		if vim.g.started_by_firenvim == true then
			opts = {
				options = {
					theme = COLOR_THEME,
					component_separators = { left = "|", right = "|" },
					section_separators = { left = "", right = "" },
					always_divide_middle = false,
					globalstatus = true,
				},
				sections = {
					lualine_a = {
						{ "mode", separator = { left = "", right = "" } },
					},
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { current_servers },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = {
						{ "location", separator = { left = "", right = "" } },
					},
				},
				extensions = { "lazy" },
			}
		else
			opts = {
				options = {
					theme = COLOR_THEME,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					always_divide_middle = false,
					globalstatus = true,
				},
				sections = {
					lualine_a = {
						{ "mode", separator = { left = "", right = "" } },
					},
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { current_servers },
					lualine_x = { "encoding", "fileformat", "filetype" },
					lualine_y = { "progress" },
					lualine_z = {
						{ "location", separator = { left = "", right = "" } },
					},
				},
				tabline = {
					lualine_a = {
						{
							"buffers",
							separator = { left = "", right = "" },
							buffers_color = { inactive = "lualine_b_normal" },
							symbols = { alternate_file = "󰤖 " },
						},
					},
					lualine_z = {
						{
							"tabs",
							separator = { left = "", right = "" },
							tabs_color = { inactive = "lualine_b_normal" },
							symbols = { modified = " ●" },
						},
					},
				},
				extensions = { "lazy", "man", "mason", "quickfix", "symbols-outline" },
			}
		end

		require("lualine").setup(opts)
	end,
}
