local scroll = require("swipe.scroll")
local api = vim.api

describe("scroll", function()
  local window
  local buffer

  before_each(function()
    buffer = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buffer, -1, -1, false, {
      "11111111111111111111",
      "2222222222",
      "3333333333",
      "4444444444",
      "5555555555",
      "6666666666",
      "7777777777",
      "8888888888",
      "9999999999",
      "0000000000",
    })
    vim.bo[buffer].modifiable = false
    window = api.nvim_open_win(buffer, true, {
      relative = "win",
      width = 4,
      height = 4,
      row = 0,
      col = 0,
    })
    vim.wo[window].wrap = false
    scroll.perform("vertical", -2)
    scroll.perform("horizontal", 2)
  end)

  after_each(function()
    api.nvim_buf_delete(buffer, { unload = true })
    -- api.nvim_win_close(window, true)
  end)

  describe("perform", function()
    describe("invalid", function()
      it("window", function()
        assert.is.False(pcall(scroll.perform, "vertical", 1, window + 1))
      end)
      it("orientation", function()
        assert.is.False(pcall(scroll.perform, "invalid", 1, window))
      end)
      it("amount", function()
        assert.is.False(pcall(scroll.perform, "horizontal", 0, window))
      end)
    end)

    describe("vertical", function()
      local orientation = scroll.orientation.vertical
      it("down", function()
        scroll.perform(orientation, -2, window)
        assert.are.equal(5, vim.fn.line("w0", window))
      end)
      it("up", function()
        scroll.perform(orientation, 2, window)
        assert.are.equal(1, vim.fn.line("w0", window))
      end)
    end)

    describe("horizontal", function()
      local orientation = scroll.orientation.horizontal
      it("right", function()
        scroll.perform(orientation, 2, window)
        assert.are.equal(4, scroll.save_view(window)["leftcol"])
      end)
      it("left", function()
        scroll.perform(orientation, -2, window)
        assert.are.equal(0, scroll.save_view(window)["leftcol"])
      end)
    end)
  end)

  describe("possible", function()
    describe("invalid", function()
      it("window", function()
        assert.is.False(pcall(scroll.possible, "vertical", 1, window + 1))
      end)
      it("orientation", function()
        assert.is.False(pcall(scroll.possible, "invalid", -1, window))
      end)
      it("direction", function()
        assert.is.False(pcall(scroll.possible, "horizontal", 0, window))
      end)
      it("visible", function()
        assert.is.False(pcall(scroll.possible, "horizontal", 1, window, 23))
      end)
    end)

    describe("horizontal", function()
      local orientation = scroll.orientation.horizontal
      it("only visible", function()
        assert.are.equal(4, scroll.possible(orientation, 1, window))
      end)
      it("full buffer", function()
        assert.are.equal(14, scroll.possible(orientation, 1, window, false))
      end)
      it("left", function()
        assert.are.equal(2, scroll.possible(orientation, -1, window))
      end)
    end)

    describe("vertical", function()
      local orientation = scroll.orientation.vertical
      it("up", function()
        assert.are.equal(2, scroll.possible(orientation, 1, window))
      end)
      it("down", function()
        assert.are.equal(4, scroll.possible(orientation, -1, window))
      end)
    end)
  end)
end)
