local jump = require("swipe.jump")
local api = vim.api

describe("jump", function()
  local window
  local buffers

  before_each(function()
    vim.cmd.clearjumps()
    buffers = {}
    for i = 1, 10, 1 do
      local buffer = api.nvim_create_buf(false, true)
      for _ = 1, 5, 1 do
        api.nvim_buf_set_lines(buffer, -1, -1, false, { tostring(i) })
      end
      vim.bo[buffer].modifiable = false
      table.insert(buffers, buffer)
    end
    window = api.nvim_open_win(buffers[1], true, {
      relative = "win",
      width = 4,
      height = 4,
      row = 0,
      col = 0,
    })
    api.nvim_win_call(window, function()
      vim.cmd.clearjumps()
      for _, buffer in ipairs(buffers) do
        vim.cmd.buffer(buffer)
        for j = 1, 5, 1 do
          api.nvim_feedkeys(tostring(j) .. "gg", "x", false)
        end
      end
    end)
  end)

  after_each(function()
    for _, buffer in ipairs(buffers) do
      api.nvim_buf_delete(buffer, { unload = true })
    end
    -- api.nvim_win_close(window, true)
  end)

  describe("perform", function()
    describe("invalid", function()
      it("window", function()
        assert.is.False(pcall(jump.perform, 1, window + 1))
      end)
      it("direction", function()
        assert.is.False(pcall(jump.perform, 0, window))
      end)
    end)

    it("not sufficient", function()
      jump.perform(-2, window)
      assert.are.equal(buffers[#buffers], api.nvim_win_get_buf(window))
    end)

    it("sufficient", function()
      jump.perform(-5, window)
      assert.are.equal(buffers[#buffers - 1], api.nvim_win_get_buf(window))
    end)

    it("forward", function()
      jump.to_different_buffer(-9, window)
      jump.perform(1, window)
      assert.are.equal(buffers[2], api.nvim_win_get_buf(window))
    end)
  end)

  describe("count", function()
    describe("invalid", function()
      it("window", function()
        assert.is.False(pcall(jump.count, 1, window + 1))
      end)
      it("direction", function()
        assert.is.False(pcall(jump.count, 0, window))
      end)
    end)

    it("backward", function()
      assert.are.equal(-5, jump.count(-1, window))
    end)

    it("forward", function()
      jump.to_different_buffer(-9, window)
      assert.are.equal(1, jump.count(1, window))
    end)
  end)

  describe("to_different_buffer", function()
    describe("invalid", function()
      it("window", function()
        assert.is.False(pcall(jump.to_different_buffer, 1, window + 1))
      end)
      it("direction", function()
        assert.is.False(pcall(jump.to_different_buffer, 0, window))
      end)
    end)

    describe("backward", function()
      it("once", function()
        jump.to_different_buffer(-1, window)
        assert.are.equal(buffers[#buffers - 1], api.nvim_win_get_buf(window))
      end)

      it("multiple", function()
        jump.to_different_buffer(-3, window)
        assert.are.equal(buffers[#buffers - 3], api.nvim_win_get_buf(window))
      end)
    end)

    describe("forward", function()
      it("once", function()
        jump.to_different_buffer(-9, window)
        jump.to_different_buffer(1, window)
        assert.are.equal(buffers[2], api.nvim_win_get_buf(window))
      end)

      it("multiple", function()
        jump.to_different_buffer(-9, window)
        jump.to_different_buffer(3, window)
        assert.are.equal(buffers[4], api.nvim_win_get_buf(window))
      end)
    end)
  end)
end)
