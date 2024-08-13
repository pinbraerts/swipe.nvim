local api = vim.api
local M = {}

M.key = {
  left = "<ScrollWheelLeft>",
  right = "<ScrollWheelRight>",
  down = "<ScrollWheelDown>",
  up = "<ScrollWheelUp>",
  forward = "<c-i>",
  backward = "<c-o>",
}

M.symbol = {}

for k, v in pairs(M.key) do
  M.symbol[k] = api.nvim_replace_termcodes(v, true, false, true)
end

function M.jump(direction)
  local key
  if direction == 0 then
    return
  elseif direction > 0 then
    key = tostring(direction) .. M.symbol.forward
  else
    key = tostring(-direction) .. M.symbol.backward
  end
  vim.cmd.normal({ bang = true, key })
end

function M.get_buffer_jump(direction)
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

function M.get_buffer_size(buffer)
  local lines = api.nvim_buf_get_lines(buffer, 0, -1, true)
  local max_width = 0
  for _, line in ipairs(lines) do
    local line_width = vim.fn.strchars(line)
    if max_width < line_width then
      max_width = line_width
    end
  end
  return {
    width = max_width,
    height = #lines,
  }
end

function M.scroll(direction)
  local key
  if direction == 0 then
    return
  elseif type(direction) == "string" then
    key = M.symbol[direction]
  elseif direction < 0 then
    key = tostring(direction) .. M.symbol.left
  else
    key = tostring(-direction) .. M.symbol.right
  end
  vim.cmd.normal({ bang = true, key })
end

function M.get_window_scroll(window, direction)
  local left_column = vim.fn.winsaveview()["leftcol"]
  if direction < 0 then
    return left_column > 0
  end
  local width = api.nvim_win_get_width(window)
  local right_column = left_column + width
  local buffer = api.nvim_win_get_buf(window)
  return right_column < M.get_buffer_size(buffer).width
end

function M.get_window_config(indicator)
  local size = M.get_buffer_size(indicator.buffer)
  local progress = M.config.speed * indicator.progress
  -- stylua: ignore
  return {
    border = "rounded",
    relative = "win",
    style = "minimal",
    height = size.height,
    width = size.width,
    row = api.nvim_win_get_height(indicator.parent_window) / 2,
    col = indicator.direction < 0
      and progress
      or (api.nvim_win_get_width(indicator.parent_window)
        - api.nvim_win_get_width(indicator.window)
        - progress),
  }
end

local function adjust(indicator)
  api.nvim_win_set_config(indicator.window, M.get_window_config(indicator))
end

local function delete(indicator)
  indicator.timer:stop()
  indicator.timer:close()
  vim.schedule(function()
    api.nvim_buf_delete(indicator.buffer, { force = true, unload = true })
  end)
  -- api.nvim_win_close(indicator.window, true)
  M.indicator = nil
end

local function handle_internal(indicator, direction)
  direction = indicator.direction * direction
  indicator.progress = indicator.progress + direction
  adjust(indicator)
  if indicator.progress <= 0 then
    return true
  end
  if indicator.progress < M.config.threshold then
    return false
  end
  M.jump(M.get_buffer_jump(indicator.direction))
  return true
end

local function start_timer(indicator)
  indicator.timer:start(M.config.timeout, 0, function()
    delete(indicator)
  end)
end

local function handle(indicator, direction)
  indicator.timer:stop()
  if handle_internal(indicator, direction) then
    delete(indicator)
    return
  end
  start_timer(indicator)
end

local function create(parent_window, direction)
  local buffer = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buffer, 0, -1, false, {
    (direction < 0 and "  " or "  "),
  })
  vim.bo[buffer].modifiable = false
  local window = api.nvim_open_win(buffer, false, {
    relative = "win",
    row = 0,
    col = 0,
    height = 1,
    width = 1,
  })
  local indicator = {
    buffer = buffer,
    window = window,
    parent_window = parent_window,
    direction = direction,
    progress = 0,
    timer = vim.uv.new_timer(),
  }
  start_timer(indicator)
  adjust(indicator)
  return indicator
end

local function handle_scroll(direction)
  local window = api.nvim_get_current_win()
  if M.indicator and M.indicator.parent_window ~= window then
    delete(M.indicator)
  end
  if not M.indicator then
    if M.get_window_scroll(window, direction) then
      return M.scroll(direction)
    end
    if M.get_buffer_jump(direction) == 0 then
      return
    end
    M.indicator = create(window, direction)
  end
  handle(M.indicator, direction)
end

function M.disable_scroll(direction)
  if M.indicator and M.indicator.progress > M.config.disable_threshold then
    return
  end
  M.scroll(direction)
end

function M.disable_scroll_up()
  return M.disable_scroll("up")
end

function M.disable_scroll_down()
  return M.disable_scroll("down")
end

function M.scroll_left()
  return handle_scroll(-1)
end

function M.scroll_right()
  return handle_scroll(1)
end

M.default_config = {
  threshold = 20,
  disable_threshold = 5,
  speed = 1,
  timeout = 200,
  keymap = {
    left = M.scroll_left,
    right = M.scroll_right,
    up = M.disable_scroll_up,
    down = M.disable_scroll_down,
  },
}

function M.setup_keymaps(direction)
  local mapping = M.config.keymap[direction]
  if not mapping then
    return
  end
  if type(mapping) == "boolean" then
    mapping = M.default_config.keymap[direction]
  end
  if type(mapping) == "function" then
    mapping = {
      { "n", "v" },
      M.key[direction],
      mapping,
      {
        silent = true,
        nowait = true,
      },
    }
  end
  pcall(vim.keymap.set, unpack(mapping))
  M.config.keymap[direction] = mapping
end

function M.setup(config)
  M.config = vim.tbl_deep_extend("force", M.default_config, config)
  if M.config.keymap and type(M.config.keymap) == "boolean" then
    M.config.keymap = M.default_config.keymap
  end
  if M.config.keymap then
    M.setup_keymaps("left")
    M.setup_keymaps("right")
    M.setup_keymaps("up")
    M.setup_keymaps("down")
  end
end

return M
