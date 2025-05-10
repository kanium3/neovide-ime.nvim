rockspec_format = '3.0'
-- TODO: Rename this file and set the package
package = "neovide-ime.nvim"
version = "scm-1"
source = {
  -- TODO: Update this URL
  url = "git+https://github.com/kanium3/neovide-ime.nvim"
}
dependencies = {
  -- Add runtime dependencies here
  -- e.g. "plenary.nvim",
}
build = {
  type = "builtin",
  copy_directories = {
    -- Add runtimepath directories, like
    -- 'plugin', 'ftplugin', 'doc'
    -- here. DO NOT add 'lua' or 'lib'.
  },
}
