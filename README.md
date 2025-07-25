# qfpreview.nvim

Just a preview for Neovim's quickfix list.

| Fill                                | Fixed height                                 |
| ----------------------------------- | -------------------------------------------- |
| ![Fill](assets/screenshot_fill.png) | ![Fixed height](assets/screenshot_fixed.png) |

> The pretty quickfix list is by the awesome [`stevearc/quicker.nvim`](https://github.com/stevearc/quicker.nvim).

## Installation

Install `qfpreview.nvim` using your favorite plugin manager.

**[lazy.nvim](https://github.com/folke/lazy.nvim)**:

```lua
{
  'r0nsha/qfpreview.nvim',
  opts = {
    -- Your custom configuration goes here
  }
}
```

**[packer.nvim](https://github.com/wbthomason/packer.nvim)**:

```lua
use({
  'r0nsha/qfpreview.nvim',
  config = function()
    require('qfpreview').setup({
      -- Your custom configuration goes here
    })
  end
})
```

## Configuration

Here are the default configuration options:

```lua
require('qfpreview').setup({
    ui = {
      -- number | "fill"
      -- number will set the window to a fixed height
      -- "fill" will make the window fill the editor's remaining space
      height = "fill",
      -- whether to show the buffer's name
      show_name = true,
      -- additinonal window configuration
      win = {}
    },
    opts = {
      -- the window's throttle time in milliseconds
      throttle = 100,
      -- whether to enable lsp clients
      lsp = true,
      -- whether to enable diagnostics
      diagnostics = true
    }
})
```

## Contributing

Contributions are always welcome! If you find any bugs or have a feature request, you're welcome to open an issue or submit a pull request.
