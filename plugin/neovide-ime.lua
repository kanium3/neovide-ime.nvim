-- If you run neovim expect neovide, this plugin does nothing
if vim.g.neovide == nil or vim.g.neovide == false then
  return
end

local neovide_ime = require("neovide-ime")

neovide.preedit_handler = neovide_ime.preedit_handler
neovide.commit_handler = neovide_ime.commit_handler
