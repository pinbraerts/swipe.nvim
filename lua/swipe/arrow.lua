--- @module "swipe.arrow"
--- @class swipe.IndicatorManager
local M = {}
local api = vim.api
local scroll = require("swipe.scroll")

--- @param indicator swipe.Indicator
--- @param window number window handle
function M.create(indicator, window)
  local buffer = api.nvim_create_buf(false, true)
  local text
  local row = 0
  local col = 0
  local height = api.nvim_win_get_height(window)
  local width = api.nvim_win_get_width(window)
  if indicator.orientation == scroll.orientation.horizontal then
    if indicator.direction > 0 then
      text = "  "
      col = width - 3
    else
      text = "  "
    end
    row = height / 2
  else
    if indicator.direction < 0 then
      text = "  "
      row = height - 1
    else
      text = "  "
    end
    col = width / 2
  end
  api.nvim_buf_set_lines(buffer, 0, -1, false, { text })
  vim.bo[buffer].modifiable = false
  local config = {
    relative = "win",
    border = "rounded",
    style = "minimal",
    win = window,
    row = row,
    col = col,
    height = 1,
    width = 3,
  }
  indicator.window = api.nvim_open_win(buffer, false, config)
end

--- @param indicator swipe.Indicator
--- @param direction number
function M.update(indicator, direction)
  local config = api.nvim_win_get_config(indicator.window)
  if indicator.orientation == scroll.orientation.horizontal then
    config.col = config.col - direction * indicator.direction
  else
    config.row = config.row + direction * indicator.direction
  end
  -- print(indicator.progress, indicator.direction, direction, config.col)
  api.nvim_win_set_config(indicator.window, config)
end

--- @param indicator swipe.Indicator
function M.delete(indicator)
  local buffer = api.nvim_win_get_buf(indicator.window)
  api.nvim_buf_delete(buffer, { unload = true })
end

return M
