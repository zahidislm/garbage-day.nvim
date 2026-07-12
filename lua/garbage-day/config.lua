---@class GarbageDay.Config
---@field aggressive_mode        boolean
---@field aggressive_mode_ignore { filetype: string[], buftype: string[] }
---@field excluded_lsp_clients   string[]
---@field grace_period           integer seconds
---@field notifications          boolean
---@field wakeup_delay           integer milliseconds
local M = {}

---@type GarbageDay.Config
local defaults = {
  aggressive_mode = false,
  aggressive_mode_ignore = {
    filetype = { "", "markdown", "text", "org", "tex", "asciidoc", "rst" },
    buftype = { "nofile" },
  },
  excluded_lsp_clients = { "null-ls", "jdtls", "marksman", "lua_ls", "copilot" },
  grace_period = 60 * 15,
  notifications = false,
  wakeup_delay = 0,
}

--- Resolves `opts` against `defaults` and exposes the result as `vim.g.garbage_day_config`
---@param opts? table
function M.set(opts)
  vim.g.garbage_day_config = vim.tbl_extend("force", defaults, opts or {})
end

return M
