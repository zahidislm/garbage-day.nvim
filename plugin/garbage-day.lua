local aucmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup("GarbageDayEvents", { clear = true })

aucmd("FocusLost", { group = augroup, callback = require("garbage-day").on_focus_lost })
aucmd("FocusGained", { group = augroup, callback = require("garbage-day").on_focus_gained })
aucmd("BufEnter", { group = augroup, callback = require("garbage-day").on_buf_enter })
aucmd("VimLeavePre", { group = augroup, callback = require("garbage-day").on_vim_leave })
