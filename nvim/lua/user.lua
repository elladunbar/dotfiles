-- Global Variables
LSP_SERVERS = {}

-- Settings
vim.filetype.add({ extension = { hy = "hy" } })
vim.filetype.add({ extension = { dj = "djot", djot = "djot" } })
vim.diagnostic.config({ virtual_lines = true })

-- Functions
function REGISTER_SERVER(server_name)
	return function(_, bufnr)
		LSP_SERVERS[bufnr] = LSP_SERVERS[bufnr] or {}
		LSP_SERVERS[bufnr][server_name] = true
	end
end

function P(v)
	print(vim.inspect(v))
	return v
end
