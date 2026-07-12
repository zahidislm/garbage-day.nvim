---@class GarbageDay.Config
---@field aggressive_mode        boolean
---@field aggressive_mode_ignore { filetype: string[], buftype: string[] }
---@field excluded_lsp_clients   string[]
---@field grace_period           integer                                   seconds
---@field notifications          boolean
---@field wakeup_delay           integer                                   milliseconds

---@type GarbageDay.Config
vim.g.GarbageDay = {
  config = {
    aggressive_mode = false,
    aggressive_mode_ignore = {
      filetype = { "", "markdown", "text", "org", "tex", "asciidoc", "rst" },
      buftype = { "nofile" },
    },
    excluded_lsp_clients = { "null-ls", "jdtls", "marksman", "lua_ls", "copilot" },
    grace_period = 60 * 15,
    notifications = false,
    wakeup_delay = 0,
  },
}

local aucmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("GarbageDayEvents", { clear = true })

aucmd("FocusLost", { group = augroup, callback = require("garbage-day").on_focus_lost })
aucmd("FocusGained", { group = augroup, callback = require("garbage-day").on_focus_gained })
aucmd("BufEnter", { group = augroup, callback = require("garbage-day").on_buf_enter })
aucmd("VimLeavePre", { group = augroup, callback = require("garbage-day").on_vim_leave })
