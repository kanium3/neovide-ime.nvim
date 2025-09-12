# Neovide-ime.nvim

> [!IMPORTANT]
> If you use main branch neovide(especially with `cmdheight=0`), this plugin doesn't work.
> So, this plugin works between neovide/neovide@68fefed0b9cc1d56107de24218284df7109c12a1 and neovide/neovide@75ae946835b56a31c54d18c0cd228aa9d2a50991
> Ref: https://github.com/neovide/neovide/pull/3218 and https://github.com/kanium3/neovide-ime.nvim/issues/12

Better-support for IME handling in Neovide.

https://github.com/user-attachments/assets/15f24fbb-98d3-4865-b2b1-f6eacb42243d

## Usage

**First**, You must use [main branch neovide](https://github.com/neovide/neovide)!
Second, Install by any plugin manager. For example, `Lazy.nvim`

```lua
{
    "kanium3/neovide-ime.nvim",
    event = { "UIEnter" } -- Any timing:)
}
```

## License

This plugin is licensed under MIT.
