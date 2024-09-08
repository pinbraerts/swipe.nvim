local api = vim.api
local M = {}

M.jump = require("swipe.jump")
M.scroll = require("swipe.scroll")

--- @class swipe.IndicatorManager
--- @field create fun(indicator: swipe.Indicator, window: number)
--- @field update fun(indicator: swipe.Indicator, direction: number)
--- @field delete fun(indicator: swipe.Indicator)
M.arrow = require("swipe.arrow")
M.validate = require("swipe.validate")
M.default = {}

M.key = {
  left = "<ScrollWheelLeft>",
  right = "<ScrollWheelRight>",
  down = "<ScrollWheelDown>",
  up = "<ScrollWheelUp>",
}

--- @class swipe.Indicator
--- @field orientation swipe.scroll.Orientation orientation of swiping
--- @field direction number direction of swiping
--- @field progress number current progress
--- @field timer uv_timer_t deletion timer
--- @field window number indicator window
M.indicator = nil

--- @enum swipe.Direction
M.direction = {
  left = "left",
  right = "right",
  up = "up",
  down = "down",
}

--- Handle gesture
--- @param orientation swipe.scroll.Orientation
--- @param direction number
--- @param window number window handle
local function handle(orientation, direction, window)
  M.validate.common(orientation, direction, "direction", window)
  if not M.indicator then
    if M.scroll.possible(orientation, direction, window) ~= 0 then
      return M.scroll.perform(orientation, direction, window)
    end
    if orientation == M.scroll.orientation.horizontal and M.jump.count(direction, window) == 0 then
      return
    end
    --- @class swipe.Indicator
    M.indicator = {
      orientation = orientation,
      direction = direction,
      timer = vim.uv.new_timer(),
      progress = 0,
    }
    M.config.manager.create(M.indicator, window)
  end
  if M.indicator.orientation ~= orientation then
    return
  end
  local indicator = M.indicator
  indicator.timer:stop()
  direction = indicator.direction * direction
  indicator.progress = indicator.progress + direction
  M.config.manager.update(indicator, direction * M.config.speed)
  if 0 < indicator.progress and indicator.progress < M.config.threshold then
    indicator.timer:start(
      M.config.timeout,
      0,
      vim.schedule_wrap(function()
        handle(indicator.orientation, -indicator.direction, window)
      end)
    )
    return
  end
  if indicator.progress > 0 then
    M.config.action[indicator.orientation](indicator.direction, window)
  end
  indicator.timer:stop()
  indicator.timer:close()
  M.config.manager.delete(M.indicator)
  M.indicator = nil
end

function M.scroll_up()
  local window = api.nvim_get_current_win()
  return handle(M.scroll.orientation.vertical, 1, window)
end

function M.scroll_down()
  local window = api.nvim_get_current_win()
  return handle(M.scroll.orientation.vertical, -1, window)
end

function M.scroll_left()
  local window = api.nvim_get_current_win()
  return handle(M.scroll.orientation.horizontal, -1, window)
end

function M.scroll_right()
  local window = api.nvim_get_current_win()
  return handle(M.scroll.orientation.horizontal, 1, window)
end

--- Reload window
--- @param _ number
--- @param window? number window handle (current if nil)
function M.reload(_, window)
  window = window or vim.api.nvim_get_current_win()
  vim.api.nvim_win_call(window, function()
    vim.cmd.edit({ bang = true })
  end)
end

--- @alias swipe.Action function(direction: number, window?: number)

--- @class swipe.Actions
--- @field horizontal swipe.Action
--- @field vertical swipe.Action
M.default.action = { horizontal = M.jump.to_different_buffer, vertical = M.reload }

--- @class vim.keymap.set.Opts
M.default.options = { nowait = true, silent = true }
M.default.modes = { "n", "v" }

--- @alias swipe.Mapping { [1]:string|string[], [2]:string, [3]:string|function, [4?]:vim.keymap.set.Opts }

--- @class swipe.Mappings
--- @field left swipe.Mapping
--- @field right swipe.Mapping
--- @field up swipe.Mapping
--- @field down swipe.Mapping
M.default.keymap = {
  left = { M.default.modes, "<ScrollWheelLeft>", M.scroll_left, M.default.options },
  right = { M.default.modes, "<ScrollWheelRight>", M.scroll_right, M.default.options },
  down = { M.default.modes, "<ScrollWheelDown>", M.scroll_down, M.default.options },
  up = { M.default.modes, "<ScrollWheelUp>", M.scroll_up, M.default.options },
}

--- @class swipe.Configuration
--- @field threshold number
--- @field speed number
--- @field timeout number
--- @field manager swipe.IndicatorManager
--- @field keymap swipe.Mappings
--- @field action swipe.Actions
M.default.config = {
  threshold = 20,
  speed = 1,
  timeout = 50,
  manager = M.arrow,
  keymap = M.default.keymap,
  action = M.default.action,
}

--- @param direction swipe.Direction
local function setup_keymaps(direction)
  vim.validate({ direction = M.validate.enum(direction, M.direction, "swipe.Direction") })
  local mapping = M.config.keymap[direction]
  if not mapping then
    return
  end
  if type(mapping) == "boolean" then
    mapping = M.default.config.keymap[direction]
  end
  if type(mapping) == "function" then
    mapping = { M.default.modes, M.key[direction], mapping, M.default.options }
  end
  pcall(vim.keymap.set, unpack(mapping))
  M.config.keymap[direction] = mapping
end

--- @alias swipe.UserMapping
--- | boolean # use or disable default mapping
--- | string # map to some key chord
--- | function # use custom function
--- | swipe.Mapping # configure modes and options

--- @class swipe.UserMappings
--- @field left? swipe.UserMapping
--- @field right? swipe.UserMapping
--- @field up? swipe.UserMapping
--- @field down? swipe.UserMapping

--- @class swipe.UserActions
--- @field horizontal? swipe.Action
--- @field vertical? swipe.Action

--- @class swipe.UserConfiguration
--- @field threshold? number
--- @field speed? number
--- @field timeout? number
--- @field manager? swipe.IndicatorManager
--- @field keymap? swipe.UserMappings
--- @field action? swipe.UserActions

--- Configure the plugin
--- @param config? swipe.UserConfiguration
function M.setup(config)
  vim.validate({ config = { config, "table", true } })
  if type(config) == "table" then
    M.config = vim.tbl_deep_extend("force", M.default.config, config)
  end
  if M.config.keymap and type(M.config.keymap) == "boolean" then
    M.config.keymap = M.default.config.keymap
  end
  if M.config.keymap then
    setup_keymaps("left")
    setup_keymaps("right")
    setup_keymaps("up")
    setup_keymaps("down")
  end
end

return M
