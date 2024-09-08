local validate = require("swipe.validate")
local api = vim.api

describe("validate", function()
  describe("window", function()
    it("valid", function()
      local buffer = api.nvim_create_buf(false, true)
      local window = api.nvim_open_win(buffer, true, {
        split = "left",
        width = 1,
        height = 1,
      })
      assert.is.True(pcall(vim.validate, { window = validate.window(window) }))
    end)

    it("invalid", function()
      assert.is.False(pcall(vim.validate, { window = validate.window(-1) }))
    end)

    it("wrong type", function()
      assert.is.False(pcall(vim.validate, { window = validate.window(true) }))
    end)

    it("nil", function()
      assert.is.False(pcall(vim.validate, { window = validate.window(nil) }))
    end)
  end)

  describe("non_zero", function()
    it("valid", function()
      assert.is.True(pcall(vim.validate, { number = validate.non_zero(1) }))
    end)

    it("wrong type", function()
      assert.is.False(pcall(vim.validate, { number = validate.non_zero(true) }))
    end)

    it("zero", function()
      assert.is.False(pcall(vim.validate, { number = validate.non_zero(0) }))
    end)

    it("nil", function()
      assert.is.False(pcall(vim.validate, { number = validate.non_zero(nil) }))
    end)
  end)

  describe("enum", function()
    local enum = {
      one = "one",
      two = "two",
    }

    it("valid", function()
      assert.is.True(pcall(vim.validate, { item = validate.enum(enum.one, enum) }))
    end)

    it("custom", function()
      assert.is.True(pcall(vim.validate, { item = validate.enum("one", enum) }))
    end)

    it("invalid", function()
      assert.is.False(pcall(vim.validate, { item = validate.enum("no", enum) }))
    end)

    it("wrong type", function()
      assert.is.False(pcall(vim.validate, { item = validate.enum({}, enum) }))
    end)

    it("nil", function()
      assert.is.False(pcall(vim.validate, { item = validate.enum(nil, enum) }))
    end)
  end)
end)
