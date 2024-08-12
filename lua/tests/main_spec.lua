local api = vim.api
local threshold = 10
local swipe = require("swipe")

describe("swipe", function()
  it("forwards", function()
    swipe.setup({
      threshold = threshold,
    })
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    api.nvim_feedkeys("<c-o>", "x", true)
    for _ = 1, threshold, 1 do
      swipe.scroll_right()
    end
    assert.are.same(second, api.nvim_get_current_buf())
  end)

  it("backwards", function()
    local config = {
      threshold = threshold,
    }
    swipe.setup(config)
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    for _ = 1, threshold, 1 do
      swipe.scroll_left()
    end
    assert.are.same(buffer, api.nvim_get_current_buf())
  end)

  it("timeout", function()
    swipe.setup({
      threshold = threshold,
      timeout = 1,
    })
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    local co = coroutine.running()
    for _ = 1, threshold, 1 do
      vim.defer_fn(function()
        coroutine.resume(co)
      end, threshold)
      swipe.scroll_left()
      coroutine.yield()
    end
    assert.are.same(second, api.nvim_get_current_buf())
  end)
end)
