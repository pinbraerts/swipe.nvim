--- @module "swipe.jump"
local M = {}
local validate = require("swipe.validate")

local function valid(direction, window)
  vim.validate({
    direction = validate.non_zero(direction),
    window = validate.window(window),
  })
end

--- Perform jumps in jumplist
--- @param direction number jumps to make (negative for going back)
--- @param window? number window handle (current window if nil)
function M.perform(direction, window)
  window = window or vim.api.nvim_get_current_win()
  valid(direction, window)
  local key
  if direction > 0 then
    key = "<c-i>"
  else
    key = "<c-o>"
    direction = -direction
  end
  key = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_win_call(window, function()
    vim.api.nvim_feedkeys(tostring(direction) .. key, "x", false)
  end)
end

--- Count number of jumps until different buffer
--- @param direction number direction of lookup, negative for backwards
--- @param window? number window handle (current window if nil)
--- @return number count of jumps to reach different buffer (signed)
function M.count(direction, window)
  window = window or vim.api.nvim_get_current_win()
  valid(direction, window)
  local jumplist, index = unpack(vim.fn.getjumplist(window))
  if not jumplist or #jumplist == 0 or not jumplist[index] then
    return 0
  end
  index = index + 1
  local times = vim.fn.abs(direction)
  direction = direction / times
  local count = #jumplist
  local buffer
  if index <= #jumplist then
    buffer = jumplist[index].bufnr
  else
    buffer = vim.api.nvim_get_current_buf()
  end
  local next_index = index + direction
  while next_index > 0 and next_index <= count do
    local next_buffer = jumplist[next_index].bufnr
    if vim.api.nvim_buf_is_valid(next_buffer) and buffer ~= next_buffer then
      times = times - 1
      buffer = next_buffer
    end
    if times == 0 then
      return next_index - index
    end
    next_index = next_index + direction
  end
  return 0
end

--- Perform jump in direction until different buffer
--- @param direction number direction of lookup, negative for backwards
--- @param window? number window handle (current window if nil)
function M.to_different_buffer(direction, window)
  window = window or vim.api.nvim_get_current_win()
  valid(direction, window)
  local count = M.count(direction, window)
  if count == 0 then
    return
  end
  M.perform(count, window)
end

return M
