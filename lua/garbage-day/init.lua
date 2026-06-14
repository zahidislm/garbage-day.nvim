--- Plugin to stop LSP clients when inactive.

-- HOW IT WORKS
-- This plugin registers 3 autocmds:
-- --------------------------------------------------------------------------
-- FocusLost:   When Neovim loses focus, start a grace-period timer.
--              If focus is not regained before it expires, stop all LSP.
--
-- FocusGained: When Neovim regains focus, restart stopped LSP clients.
--              An optional wakeup_delay prevents accidental wake on mouse-over.
--
-- BufEnter:    When aggressive_mode is enabled, stop all LSP clients
--              whenever the buffer filetype changes, then let Neovim
--              restart only what the new buffer needs via FileType autocmds.
-- --------------------------------------------------------------------------

local M = {}
local utils = require("garbage-day.utils")

local timer = vim.uv.new_timer()
local lsp_has_been_stopped = false
local wakeup_delay_counting = false

--- Entry point
function M.setup(opts)
  require("garbage-day.config").set(opts)

  -- Focus lost
  vim.api.nvim_create_autocmd("FocusLost", {
    callback = function()
      local config = vim.g.garbage_day_config
      wakeup_delay_counting = false  -- reset wakeup guard

      timer:start(config.grace_period * 1000, 0, vim.schedule_wrap(function()
        if not lsp_has_been_stopped then
          timer:stop()
          utils.stop_lsp()
          if config.notifications then utils.notify("lsp_has_stopped") end
          lsp_has_been_stopped = true
        end
      end))
    end,
  })

  -- Focus gained
  vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
      local config = vim.g.garbage_day_config
      wakeup_delay_counting = true

      vim.defer_fn(function()
        if not wakeup_delay_counting then return end  -- user left before delay elapsed

        if lsp_has_been_stopped then
          utils.start_lsp()
          if config.notifications then utils.notify("lsp_has_started") end
        else
          timer:stop()  -- grace period still running; cancel it
        end

        lsp_has_been_stopped = false
      end, config.wakeup_delay)
    end,
  })

  -- Buffer entered (aggressive_mode)
  local current_filetype = vim.bo.filetype
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      local config = vim.g.garbage_day_config
      local new_ft = vim.bo[args.buf].filetype
      local new_buftype = vim.bo[args.buf].buftype

      if vim.tbl_contains(config.aggressive_mode_ignore.filetype, new_ft) then return end
      if vim.tbl_contains(config.aggressive_mode_ignore.buftype, new_buftype) then return end

      local ft_changed = new_ft ~= current_filetype
      current_filetype = new_ft

      -- In aggressive_mode, purge stale LSP clients on filetype change.
      -- Neovim's FileType autocmds will auto-start the right clients for the new buffer.
      if ft_changed and config.aggressive_mode then
        vim.defer_fn(function()
          utils.stop_lsp()
          utils.start_lsp()
          if config.notifications then utils.notify("lsp_has_stopped") end
        end, 100)
      end
    end,
  })
end

return M
