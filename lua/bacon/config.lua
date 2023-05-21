local M = {}

local defaults = {
	quickfix = {
		enabled = true,
		event_trigger = true,
	},
}

M.options = {}

function M.setup(options)
	M.options = vim.tbl_deep_extend("force", {}, defaults, options or {})
end

M.setup()

return M
