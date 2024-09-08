# swipe.nvim

A simple plugin for jumping between buffers on horizontal swipes in
[NeoVim](https://github.com/neovim/neovim)

## Installation

Use your favorite plugin manager

## Configuration

```lua
require('swipe').setup {
  -- how many MouseScroll keypresses trigger jump
  threshold = 20,
  -- how fast the arrow window moves (characters per keypress)
  speed = 1,
  -- how fast the arrow window disappears (ms till backwards motion)
  timeout = 50,
  -- custom mappings
  keymap = {
    left = "1gg", -- custom keys
    right = function() end, -- custom function
    up = { "n", "<ScrollWheelUp>", "1gg", { silent = true } }, -- custom spec
    down = true, -- default mapping
    -- down = false, -- disable default mapping
  },
  -- keymap = false, -- to disable all default mappings
  -- actions on swipes
  action = {
    horizontal = require("swipe.jump").to_different_buffer,
    vertical = function(direction) end, -- custom function
  },
}
```

## Demonstration

[![demonstration](https://asciinema.org/a/XppWVRGAc3lT9LD1xznzdEA9r.svg)](https://asciinema.org/a/XppWVRGAc3lT9LD1xznzdEA9r)
