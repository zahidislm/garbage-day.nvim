local M = {}

local stopped_clients_cache = {}
local start_timer = vim.uv.new_timer()

-- CORE UTILS
-- ---------------------------------------------------------------------------

--- Stop all LSP clients, including ones in other tabs and windows.
function M.stop_lsp()
  local config = vim.g.garbage_day_config
  for _, client in pairs(vim.lsp.get_clients()) do
    if not vim.tbl_contains(config.excluded_lsp_clients, client.name) then
      stopped_clients_cache[client.name] = true
      client:stop()
    end
  end
end

--- Start LSP clients that were previously stopped.
--- Retries up to config.retries times, spaced config.timeout ms apart.
function M.start_lsp()
  local config = vim.g.garbage_day_config
  local elapsed_retries = 0

  if start_timer:is_active() then
    start_timer:stop()
  end

  local timer_callback = vim.schedule_wrap(function()
    if elapsed_retries >= config.retries then
      start_timer:stop()
      stopped_clients_cache = {}
      return
    end

    for client_name in pairs(stopped_clients_cache) do
      pcall(vim.lsp.enable, client_name)
    end

    elapsed_retries = elapsed_retries + 1
  end)

  start_timer:start(0, config.timeout, timer_callback)
end

-- MISC UTILS
-- ---------------------------------------------------------------------------

--- Send a notification.
--- @param kind string  "lsp_has_started" | "lsp_has_stopped"
function M.notify(kind)
  if kind == "lsp_has_started" then
    vim.notify(
      "Focus recovered. Starting LSP clients.",
      vim.log.levels.INFO,
      { title = "garbage-day.nvim" }
    )
  elseif kind == "lsp_has_stopped" then
    vim.notify(
      "Inactive LSP clients have been stopped to save resources.",
      vim.log.levels.INFO,
      { title = "garbage-day.nvim" }
    )
  end
end

return M
