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
  -- how fast the arrow window disappears (ms)
  timeout = 200,
}
```

## Demonstration

[![demonstration](https://asciinema.org/a/XppWVRGAc3lT9LD1xznzdEA9r.svg)](https://asciinema.org/a/XppWVRGAc3lT9LD1xznzdEA9r)
