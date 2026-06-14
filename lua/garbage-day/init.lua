--- Plugin to stop LSP clients when inactive.

-- HOW IT WORKS
-- This plugin has 3 autocmds:
-- ----------------------------------------------------------------------------
-- FocusLost:   When the mouse leaves neovim, stop all LSP clients
--              after a grace period.
--
-- FocusGained: When the mouse enters neovim, start all LSP
--              for the current buffer.
--
-- BufEnter:    Manages the feature aggressive_mode.
--              When the mouse enters a buffer, stop all LSP clients
--              If the new buffer filetype is different from the previous one.
--              Always try to start LSP. Even if aggressive_mode is disabled.
-- ----------------------------------------------------------------------------


local M = {}
local utils = require("garbage-day.utils")

local timer = vim.uv.new_timer()
local lsp_has_been_stopped = false
local wakeup_delay_counting = false

--- Entry point of the program
function M.setup(opts)
  require("garbage-day.config").set(opts)

  -- Focus lost?
  vim.api.nvim_create_autocmd("FocusLost", {
    callback = function()
      local config = vim.g.garbage_day_config
      wakeup_delay_counting = false -- reset wakeup_delay state

      -- Start counting
      timer:start(config.grace_period * 1000, 0, vim.schedule_wrap(function()
        if not lsp_has_been_stopped then
          timer:stop()
          utils.stop_lsp()
          if config.notifications then utils.notify("lsp_has_stopped") end
          lsp_has_been_stopped = true
        end
      end))
    end
  })

  -- Focus gained?
  vim.api.nvim_create_autocmd("FocusGained", {
    callback = function()
      local config = vim.g.garbage_day_config
      wakeup_delay_counting = true

      vim.defer_fn(function()
        -- if the mouse leave nvim before wakeup_delay ends, don't awake.
        if wakeup_delay_counting then
          -- Start LSP
          if lsp_has_been_stopped then
            utils.start_lsp()
            if config.notifications then utils.notify("lsp_has_started") end
          else
            timer:stop()
          end

          -- Reset state
          lsp_has_been_stopped = false
        end
      end, config.wakeup_delay)
    end
  })

  -- Buffer entered?
  local current_filetype = vim.bo.filetype
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
      local config = vim.g.garbage_day_config
      local new_filetype = vim.bo[args.buf].filetype
      local new_buftype = vim.bo[args.buf].buftype

      -- Guard clauses
      if vim.tbl_contains(config.aggresive_mode_ignore.filetype, new_filetype) then return end
      if vim.tbl_contains(config.aggresive_mode_ignore.buftype, new_buftype) then return end

      local ft_changed = new_filetype ~= current_filetype
      current_filetype = new_filetype
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
