local M = {}

---@class ImeContext
---@field entered_preedit_block boolean
---@field is_commited boolean
---@field base_row integer The absolute position of the cursor's row within the window.
---@field base_col integer The absolute position of the cursor's column within the window.
---@field preedit_col integer The position added the cursor's colomn and the offset of text
---@field preedit_row integer The position added the cursor's row and the offset of text

---@class ImePreeditData
---@field preedit_text string

---@class ImeCommitData
---@field commit_text string

---@type ImeContext
local ime_context = {
  entered_preedit_block = false,
  is_commited = false,
  base_col = 0,
  base_row = 0,
  preedit_col = 0,
  preedit_row = 0,
}

ime_context.reset = function()
  ime_context.preedit_row, ime_context.preedit_col = 0, 0
  ime_context.base_row, ime_context.base_col = 0, 0
  ime_context.entered_preedit_block = false
  ime_context.is_commited = false
end

---Getting cursor's row and colomn
---@param window_id? integer if not set, set current window id
---@return integer row
---@return integer colomn (started zero-colomn)
local function get_position_under_cursor(window_id)
  local win_id = window_id or vim.api.nvim_get_current_win()
  ---@type integer, integer
  local row, col = unpack(vim.api.nvim_win_get_cursor(win_id))
  return row, col
end

---@param preedit_text string
M.preedit_handler = function(preedit_text)
  if not vim.api.nvim_get_mode().mode == "i" then
    return
  end
  if ime_context.is_commited then
    ime_context.reset()
    return
  end
  if not ime_context.entered_preedit_block then
    local row, col = get_position_under_cursor()
    ime_context.base_row = row
    ime_context.base_col = col
    ime_context.preedit_col = ime_context.base_col
    ime_context.preedit_row = ime_context.base_row
    ime_context.entered_preedit_block = true
  end
  if preedit_text ~= nil and preedit_text ~= "" then
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.preedit_row - 1,
      ime_context.preedit_col,
      {}
    )
    ime_context.preedit_col = ime_context.base_col + string.len(preedit_text)
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.base_row - 1,
      ime_context.base_col,
      { preedit_text }
    )
    vim.api.nvim_win_set_cursor(0, { ime_context.preedit_row, ime_context.preedit_col })
  else
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.preedit_row - 1,
      ime_context.preedit_col,
      {}
    )
    vim.api.nvim_win_set_cursor(0, { ime_context.preedit_row, ime_context.preedit_col })
  end
end

---@param commit_text string
M.commit_handler = function(commit_text)
  if not vim.api.nvim_get_mode().mode == "i" then
    return
  end

  ime_context.preedit_col = ime_context.base_col + string.len(commit_text)
  vim.api.nvim_buf_set_text(
    0,
    ime_context.base_row - 1,
    ime_context.base_col,
    ime_context.base_row - 1,
    ime_context.base_col,
    { commit_text }
  )
  vim.api.nvim_win_set_cursor(0, { ime_context.preedit_row, ime_context.preedit_col })

  ime_context.is_commited = true
end

return M
