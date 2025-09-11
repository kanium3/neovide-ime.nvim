local M = {}

---@class ImeContext
---@field entered_preedit_block boolean
---@field is_commited boolean
---@field base_col integer The absolute bytes based position of the cursor's column within the window.
---@field base_row integer The absolute bytes based position of the cursor's row within the window.
---@field preedit_cursor_col integer The position added the cursor's colomn and the offset of IME cursor
---@field preedit_cursor_row integer The position added the cursor's row and the offset of IME cursor
---@field preedit_text_col integer The position added the cursor's colomn and the bytes offset of text
---@field preedit_text_row integer The position added the cursor's row and the bytes offset of text

---@class ImePreeditData
---@field preedit_raw_text string
---@field cursor_offset? [integer, integer] (start_col, end_col) This values show the cursor begin position and end position. The position is byte-wise indexed.

---@class ImeCommitData
---@field commit_raw_text string
---@field commit_formatted_text string It's escaped.

---@type ImeContext
local ime_context = {
  entered_preedit_block = false,
  is_commited = false,
  base_col = 0,
  base_row = 0,
  preedit_text_col = 0,
  preedit_text_row = 0,
  preedit_cursor_col = 0,
  preedit_cursor_row = 0,
}

ime_context.reset = function()
  ime_context.preedit_text_row, ime_context.preedit_text_col = 0, 0
  ime_context.base_row, ime_context.base_col = 0, 0
  ime_context.preedit_cursor_row, ime_context.preedit_cursor_col = 0, 0
  ime_context.entered_preedit_block = false
  ime_context.is_commited = false
end

---Getting cursor's row and colomn in bytes
---@param window_id? integer if not set, set current window id
---@return integer row
---@return integer colomn (started zero-colomn)
local function get_position_under_cursor(window_id)
  local win_id = window_id or vim.api.nvim_get_current_win()
  ---@type integer, integer
  local row, col = unpack(vim.api.nvim_win_get_cursor(win_id))
  return row, col
end

---@param preedit_raw_text string
---@param cursor_offset? [integer, integer] (start_col, end_col) This values show the cursor begin position and end position. The position is byte-wise indexed.
M.preedit_handler = function(preedit_raw_text, cursor_offset)
  if not vim.api.nvim_get_mode().mode == "i" then
    return
  end
  if ime_context.is_commited then
    ime_context.reset()
    return
  end
  if not ime_context.entered_preedit_block then
    -- Initialize the base position when entering a new preedit block
    local row, col = get_position_under_cursor()
    ime_context.base_row = row
    ime_context.base_col = col
    ime_context.preedit_text_col = ime_context.base_col
    ime_context.preedit_text_row = ime_context.base_row
    ime_context.preedit_cursor_col = ime_context.base_col
    ime_context.preedit_cursor_row = ime_context.base_row
    ime_context.entered_preedit_block = true
  end
  if preedit_raw_text ~= nil and preedit_raw_text ~= "" and cursor_offset ~= nil then
    -- Update the preedit text and cursor position if there is preedit text
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.preedit_text_row - 1,
      ime_context.preedit_text_col,
      {}
    )
    ime_context.preedit_cursor_col = ime_context.base_col + cursor_offset[2]
    ime_context.preedit_text_col = ime_context.base_col + string.len(preedit_raw_text)
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.base_row - 1,
      ime_context.base_col,
      { preedit_raw_text }
    )
    vim.api.nvim_win_set_cursor(0, { ime_context.preedit_cursor_row, ime_context.preedit_cursor_col })
  else
    -- Clear the preedit text and reset the cursor position if there is no preedit text
    ime_context.entered_preedit_block = false
    vim.api.nvim_buf_set_text(
      0,
      ime_context.base_row - 1,
      ime_context.base_col,
      ime_context.preedit_text_row - 1,
      ime_context.preedit_text_col,
      {}
    )
    vim.api.nvim_win_set_cursor(0, { ime_context.base_row, ime_context.base_col })
  end
end

---@param _commit_raw_text string
---@param commit_formatted_text string It's escaped.
M.commit_handler = function(_commit_raw_text, commit_formatted_text)
  if not vim.api.nvim_get_mode().mode == "i" then
    return
  end

  ime_context.preedit_text_col = ime_context.base_col + string.len(commit_formatted_text)
  vim.api.nvim_buf_set_text(
    0,
    ime_context.base_row - 1,
    ime_context.base_col,
    ime_context.base_row - 1,
    ime_context.base_col,
    { commit_formatted_text }
  )
  vim.api.nvim_win_set_cursor(0, { ime_context.preedit_text_row, ime_context.preedit_text_col })

  ime_context.is_commited = true
end

return M
