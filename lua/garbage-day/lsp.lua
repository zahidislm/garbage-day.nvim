local M = {}

---@type table<string, true>
local disabled_clients = {}

---@param client vim.lsp.Client
---@return boolean
local function is_visible(client)
  for bufnr in pairs(client.attached_buffers or {}) do
    if #vim.fn.win_findbuf(bufnr) > 0 then
      return true
    end
  end
  return false
end

---@param kind "stopped" | "started"
local function notify(kind)
  if not vim.g.garbage_day_config.notifications then
    return
  end
  local msg = kind == "stopped" and "Inactive LSP clients have been stopped to save resources."
    or "Focus recovered. Starting LSP clients."
  vim.notify(msg, vim.log.levels.INFO, { title = "garbage-day.nvim" })
end

--- Stop LSP clients, including ones in other tabs and windows.
---@param opts? { only_hidden?: boolean } skip clients still visible in some
---   window (used by aggressive_mode, so switching between splits with
---   different filetypes doesn't tear down the one you're not looking at)
function M.stop(opts)
  opts = opts or {}
  local cfg = vim.g.garbage_day_config
  local handled = {} ---@type table<string, true>

  for _, client in ipairs(vim.lsp.get_clients()) do
    local name = client.name
    if not handled[name] and not vim.tbl_contains(cfg.excluded_lsp_clients, name)
      and not (opts.only_hidden and is_visible(client)) then
      handled[name] = true
      disabled_clients[name] = true
      pcall(vim.lsp.enable, name, false)
    end
  end

  if next(handled) then
    notify("stopped")
  end
end

--- Re-enable LSP configs previously stopped by `M.stop()`.
function M.start()
  if next(disabled_clients) == nil then
    return
  end
  pcall(vim.lsp.enable, vim.tbl_keys(disabled_clients))
  disabled_clients = {}
  notify("started")
end

return M
