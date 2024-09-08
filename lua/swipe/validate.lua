--- @module "swipe.validate"
local M = {}

--- Check if window is valid
--- @param window number
--- @return vim.validate.Spec
function M.window(window)
  return { window, vim.api.nvim_win_is_valid, "valid handle" }
end

--- Check if number is not zero
--- @param number number
--- @return vim.validate.Spec
function M.non_zero(number)
  return {
    number,
    function()
      return type(number) == "number" and number ~= 0
    end,
    "non-zero number",
  }
end

--- Check if item is in enum
--- @param item string
--- @param enum table
--- @param name? string
--- @return vim.validate.Spec
function M.enum(item, enum, name)
  name = name or "enum"
  return {
    item,
    function()
      return vim.tbl_contains(enum, item)
    end,
    name,
  }
end

--- Check common arguments
--- @param orientation swipe.scroll.Orientation
--- @param number number
--- @param window number window handle
function M.common(orientation, number, name, window)
  local scroll = require("swipe.scroll")
  vim.validate({
    window = M.window(window),
    orientation = M.enum(orientation, scroll.orientation, "swipe.scroll.Orientation"),
    [name] = M.non_zero(number),
  })
end

return M
