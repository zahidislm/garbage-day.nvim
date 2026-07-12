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

local lsp = require("garbage-day.lsp")

local grace_timer = assert(vim.uv.new_timer())
local debounce_timer = assert(vim.uv.new_timer())

local state = { stopped = false, waking_up = false }

---@type string
local current_filetype

---@return GarbageDay.Config
local function cfg()
  return vim.g.garbage_day_config
end

function M.on_focus_lost()
  state.waking_up = false

  grace_timer:start(
    cfg().grace_period * 1000, 0,
    vim.schedule_wrap(function ()
      if not state.stopped then
        lsp.stop()
        state.stopped = true
      end
    end)
  )
end

function M.on_focus_gained()
  state.waking_up = true

  vim.defer_fn(function ()
    if not state.waking_up then
      return -- focus was lost again before the delay elapsed
    end

    if state.stopped then
      lsp.start()
    else
      grace_timer:stop() -- grace period was still running; cancel it
    end

    state.stopped = false
  end, cfg().wakeup_delay)
end

function M.on_buf_enter(args)
  local c = cfg()
  if not c.aggressive_mode then
    return
  end

  local ft = vim.bo[args.buf].filetype
  local buftype = vim.bo[args.buf].buftype
  local changed = current_filetype and ft ~= current_filetype
  current_filetype = ft

  if vim.tbl_contains(c.aggressive_mode_ignore.filetype, ft) then
    return
  end

  if vim.tbl_contains(c.aggressive_mode_ignore.buftype, buftype) then
    return
  end

  if not changed then
    return
  end

  -- Debounced: rapid buffer cycling (`:bn` held down, fuzzy-finder
  -- previews) should purge once, not once per intermediate buffer.
  debounce_timer:start(
    100, 0,
    vim.schedule_wrap(function ()
      lsp.stop({ only_hidden = true })
      lsp.start()
    end)
  )
end

function M.on_vim_leave()
  for _, timer in ipairs({ grace_timer, debounce_timer }) do
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
end

---@param opts? table
function M.setup(opts)
  require("garbage-day.config").set(opts)
end

return M
