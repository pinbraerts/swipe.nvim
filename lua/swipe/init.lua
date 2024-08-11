local M = {}

M.config = {
  threshold = 25,
  speed = 1,
}

M.indicators = {}

local function jump(direction)
  local key
  if direction == 0 then
    return
  elseif direction > 0 then
    key = vim.api.nvim_replace_termcodes(tostring(direction) .. "<c-i>", true, false, true)
  else
    key = vim.api.nvim_replace_termcodes(tostring(-direction) .. "<c-o>", true, false, true)
  end
  vim.api.nvim_feedkeys(key, "n", false)
end

local function get_next_jump(direction)
  local jumplist, index = unpack(vim.fn.getjumplist())
  if not jumplist or #jumplist == 0 then
    return 0
  end
  local count = #jumplist
  local buffer = jumplist[index].bufnr
  local next_index = index + direction
  while next_index > 0 and next_index < count do
    if buffer ~= jumplist[next_index].bufnr then
      return next_index - index
    end
    next_index = next_index + direction
  end
  return 0
end

local function get_max_width(window)
  local buffer = vim.api.nvim_win_get_buf(window)
  local lines = vim.api.nvim_buf_line_count(buffer)
  local max_width = 0
  for i = 1, lines do
    local line_width = vim.fn.col({ i, "$" }, window)
    if max_width < line_width then
      max_width = line_width
    end
  end
  return max_width
end

local function scroll(direction)
  local key
  if direction == 0 then
    return
  elseif direction < 0 then
    key = vim.api.nvim_replace_termcodes("<ScrollWheelLeft>", true, false, true)
  else
    key = vim.api.nvim_replace_termcodes("<ScrollWheelRight>", true, false, true)
  end
  vim.api.nvim_feedkeys(key, "n", false)
end

local function check_scroll(window, direction)
  local left_column = vim.fn.winsaveview()["leftcol"]
  if direction < 0 then
    return left_column > 0
  end
  local width = vim.api.nvim_win_get_width(window)
  local right_column = left_column + width
  return right_column < get_max_width(window)
end

local function adjust(indicator)
  -- stylua: ignore
  vim.api.nvim_win_set_config(indicator.window, {
    relative = "win",
    height = 1,
    width = 3,
    row = vim.api.nvim_win_get_height(indicator.parent_window) / 2,
    col = indicator.direction < 0
      and indicator.progress
      or (vim.api.nvim_win_get_width(indicator.parent_window)
        - vim.api.nvim_win_get_width(indicator.window)
        - indicator.progress),
  })
end

local function create(parent_window, direction)
  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, {
    (direction < 0 and "  " or "  "),
  })
  vim.bo[buffer].modifiable = false
  local height = vim.api.nvim_win_get_height(parent_window)
  local window = vim.api.nvim_open_win(buffer, false, {
    border = "rounded",
    relative = "win",
    row = height / 2,
    col = 0,
    style = "minimal",
    height = 1,
    width = 3,
  })
  local indicator = {
    buffer = buffer,
    window = window,
    parent_window = parent_window,
    direction = direction,
    progress = 0,
  }
  adjust(indicator)
  return indicator
end

local function delete(indicator)
  vim.api.nvim_buf_delete(indicator.buffer, { force = true, unload = true })
  -- vim.api.nvim_win_close(indicator.window, true)
  M.indicators[indicator.parent_window] = nil
end

local function handle_internal(indicator, direction)
  direction = indicator.direction * direction * M.config.speed
  indicator.progress = indicator.progress + direction
  adjust(indicator)
  if indicator.progress <= 0 then
    return true
  end
  if indicator.progress < M.config.threshold then
    return false
  end
  jump(get_next_jump(indicator.direction))
  return true
end

local function handle(indicator, direction)
  if handle_internal(indicator, direction) then
    delete(indicator)
  end
end

local function handle_scroll(direction)
  local window = vim.api.nvim_get_current_win()
  local indicator = M.indicators[window]
  if not indicator then
    if check_scroll(window, direction) then
      return scroll(direction)
    end
    if get_next_jump(direction) == 0 then
      return
    end
    indicator = create(window, direction)
    M.indicators[window] = indicator
  end
  handle(indicator, direction)
end

function M.scroll_left()
  return handle_scroll(-1)
end

function M.scroll_right()
  return handle_scroll(1)
end

function M.setup(_)
  vim.keymap.set({ "n", "v" }, "<ScrollWheelRight>", M.scroll_right)
  vim.keymap.set({ "n", "v" }, "<ScrollWheelLeft>", M.scroll_left)
end

return M
