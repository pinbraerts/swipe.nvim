--- @module "swipe.scroll"
local M = {}

--- @enum swipe.scroll.Orientation
M.orientation = {
  horizontal = "horizontal",
  vertical = "vertical",
}

local function validate(orientation, number, name, window)
  vim.validate({
    window = { window, vim.api.nvim_win_is_valid, "valid handle" },
    orientation = {
      orientation,
      function()
        return M.orientation[orientation] ~= nil
      end,
      "swipe.scroll.Orientation",
    },
    [name] = {
      number,
      function()
        return number ~= 0
      end,
      "non-zero number",
    },
  })
end

--- `nvim_win_call(window, vim.fn.winsaveview)`
--- @param window number window handle
--- @return vim.fn.winsaveview.ret
function M.save_view(window)
  return vim.api.nvim_win_call(window, vim.fn.winsaveview)
end

--- Perform scroll in `orientation`
--- @param orientation swipe.scroll.Orientation orientation of the scroll
--- @param amount number lines to scroll (negative for opposite direction)
--- @param window? number window handle (current window if nil)
function M.perform(orientation, amount, window)
  window = window or vim.api.nvim_get_current_win()
  validate(orientation, amount, "amount", window)
  local key
  if orientation == M.orientation.horizontal then
    if amount > 0 then
      key = "zl"
    else
      amount = -amount
      key = "zh"
    end
  elseif orientation == M.orientation.vertical then
    if amount > 0 then
      key = "<c-y>"
    else
      amount = -amount
      key = "<c-e>"
    end
  else
    return
  end
  key = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_win_call(window, function()
    vim.cmd.normal({ bang = true, tostring(amount) .. key })
  end)
end

--- Check now many lines is possible to scroll in the given direction
--- @param orientation swipe.scroll.Orientation orientation of the scroll
--- @param direction number direction of the scroll (negative for opposite)
--- @param window? number window handle (current window if nil)
--- @param visible? boolean check only visible lines in the window (only horizontal)
--- @return number amount lines possible to scroll
function M.possible(orientation, direction, window, visible)
  window = window or vim.api.nvim_get_current_win()
  validate(orientation, direction, "direction", window)
  vim.validate({ visible = { visible, "boolean", true } })
  if visible == nil then
    visible = true
  end
  local buffer = vim.api.nvim_win_get_buf(window)
  local first_line = vim.fn.line("w0", window)
  local last_line = vim.fn.line("w$", window)
  local lines = vim.api.nvim_buf_line_count(buffer)
  if orientation == M.orientation.vertical then
    if direction < 0 then
      return first_line - 1
    elseif last_line < lines then
      return lines - last_line - 1
    else
      return 0
    end
  end
  local view = M.save_view(window)
  local left_column = view["leftcol"]
  if direction < 0 then
    return left_column
  end
  local width = vim.api.nvim_win_get_width(window)
  local max_length = 0
  if not visible then
    first_line = 1
    last_line = lines
  end
  for line = first_line, last_line, 1 do
    local length = vim.fn.col({ line, "$" }, window) - 1
    if max_length < length then
      max_length = length
    end
  end
  local right_column = left_column + width
  if right_column < max_length then
    return max_length - right_column
  end
  return 0
end

return M
