local mock = require("luassert.mock")
local match = require("luassert.match")
local threshold = 10

describe("swipe", function()
  local vk
  local swipe

  before_each(function()
    vk = mock(vim.keymap, true)
    swipe = require("swipe")
  end)

  after_each(function()
    mock.revert(vk)
    package.loaded["swipe"] = nil
  end)

  it("no", function()
    swipe.setup({
      threshold = threshold,
      keymap = false,
    })
    assert.stub(vk.set).is_not.called()
  end)

  it("only-right", function()
    swipe.setup({
      threshold = threshold,
      keymap = {
        right = true,
        left = false,
      },
    })
    assert.stub(vk.set).was.called_with(
      { "n", "v" },
      "<ScrollWheelRight>",
      swipe.scroll_right,
      { silent = true, nowait = true }
    )
    assert.stub(vk.set).was_not.called_with(
      match.is_table(),
      "<ScrollWheelLeft>",
      match.is_function(),
      match.is_table(),
    })
  end)

  it("only-left", function()
    swipe.setup({
      threshold = threshold,
      keymap = {
        right = false,
        left = true,
      },
    })
    assert.stub(vk.set).was.called_with(
      { "n", "v" },
      "<ScrollWheelLeft>",
      swipe.scroll_left,
      { silent = true, nowait = true }
    )
    assert.stub(vk.set).was_not.called_with(
      match.is_table(),
      "<ScrollWheelRight>",
      match.is_function(),
      match.is_table(),
    })
  end)

  it("both", function()
    swipe.setup({
      threshold = threshold,
      keymap = {
        right = true,
        left = true,
      },
    })
    assert.stub(vk.set).was.called_with(
      { "n", "v" },
      "<ScrollWheelLeft>",
      swipe.scroll_left,
      { silent = true, nowait = true }
    )
    assert.stub(vk.set).was.called_with(
      { "n", "v" },
      "<ScrollWheelRight>",
      swipe.scroll_right,
      { silent = true, nowait = true }
    )
  end)

  it("custom-function", function()
    local function custom() end
    swipe.setup({
      threshold = threshold,
      keymap = {
        right = custom,
        left = false,
      },
    })
    assert.stub(vk.set).was.called_with(
      { "n", "v" },
      "<ScrollWheelRight>",
      custom,
      { silent = true, nowait = true }
    )
    assert.stub(vk.set).was_not.called_with(
      match.is_table(),
      "<ScrollWheelLeft>",
      match.is_function(),
      match.is_table()
    )
  end)

  it("custom-description", function()
    local function cf() end
    local custom = {
      "n",
      "<ScrollWheelRight>",
      cf,
    }
    swipe.setup({
      threshold = threshold,
      keymap = {
        right = custom,
        left = false,
      },
    })
    assert.stub(vk.set).was.called_with(unpack(custom))
    assert.stub(vk.set).was_not.called_with(
      match.is_table(),
      "<ScrollWheelLeft>",
      match.is_function(),
      match.is_table()
    )
  end)
end)
