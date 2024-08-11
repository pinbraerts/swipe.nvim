local api = vim.api

describe("swipe", function()
  it("forwards", function()
    local swipe = require("swipe")
    local config = {
      threshold = 10,
    }
    swipe.setup(config)
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    api.nvim_feedkeys("<c-o>", "x", true)
    for _ = 1, 10, 1 do
      swipe.scroll_right()
    end
    assert.are.same(second, api.nvim_get_current_buf())
  end)

  it("backwards", function()
    local swipe = require("swipe")
    local config = {
      threshold = 10,
    }
    swipe.setup(config)
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    for _ = 1, 10, 1 do
      swipe.scroll_left()
    end
    assert.are.same(buffer, api.nvim_get_current_buf())
  end)

  it("timeout", function()
    local swipe = require("swipe")
    local config = {
      threshold = 10,
      timeout = 1,
    }
    swipe.setup(config)
    local buffer = api.nvim_create_buf(true, true)
    local second = api.nvim_create_buf(true, true)
    api.nvim_set_current_buf(buffer)
    api.nvim_set_current_buf(second)
    local co = coroutine.running()
    for _ = 1, 10, 1 do
      vim.defer_fn(function()
        coroutine.resume(co)
      end, 10)
      swipe.scroll_left()
      coroutine.yield()
    end
    assert.are.same(second, api.nvim_get_current_buf())
  end)
end)
