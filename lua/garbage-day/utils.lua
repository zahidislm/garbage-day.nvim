local M = {}

local config = vim.g.garbage_day_config
local stopped_clients_cache = {}
local start_timer = vim.uv.new_timer()

-- CORE UTILS
-- ----------------------------------------------------------------------------

---Stop all LSP clients, including the ones in other tabs.
function M.stop_lsp()
  for _, client in pairs(vim.lsp.get_clients()) do
    local is_lsp_client_excluded = vim.tbl_contains(config.excluded_lsp_clients, client.name)

    if not is_lsp_client_excluded then
      stopped_clients_cache[client.name] = true
      client:stop(true)
    end
  end
end

---Start LSP clients for the current buffer.
---It will retry for a configurable amount of times.
function M.start_lsp()
  local elapsed_retries = 0

  if start_timer:is_active() then
    start_timer:stop()
  end

  local timer_callback
  timer_callback = vim.schedule_wrap(function()
    if elapsed_retries >= config.retries then
      start_timer:stop()
      return
    end

    -- Re-enable the specific clients that were halted
    for client_name, _ in pairs(stopped_clients_cache) do
      vim.lsp.enable(client_name)
    end

    elapsed_retries = elapsed_retries + 1
  end)

  start_timer:start(config.timeout, config.timeout, timer_callback)
end

-- MISC UTILS
-- ----------------------------------------------------------------------------

---Sends a notification.
---@param kind string Accepted values are:
---{ "lsp_has_started", "lsp_has_stopped" }
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
