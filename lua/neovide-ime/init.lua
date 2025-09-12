local M = {}

vim.api.nvim_set_hl(0, "ImePreedit", { link = "Pmenu", default = true })
vim.api.nvim_set_hl(0, "ImePreeditCursor", { link = "PmenuSel", default = true })

---@class ImeContext
---@field entered_preedit_block boolean
---@field is_commited boolean
---@field base_row integer The absolute bytes based position of the cursor's row within the window.
---@field base_col integer The absolute bytes based position of the cursor's column within the window.
---@field preedit_cursor_row integer The position added the cursor's row and the offset of IME cursor
---@field preedit_cursor_col integer The position added the cursor's colomn and the offset of IME cursor
---@field preedit_text_row integer The position added the cursor's row and the bytes offset of text
---@field preedit_text_col integer The position added the cursor's colomn and the bytes offset of text
---@field extmark_id? [integer, integer] The buffer id and the extmark id of the preedit text

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
  base_row = 0,
  base_col = 0,
  preedit_text_row = 0,
  preedit_text_col = 0,
  preedit_cursor_row = 0,
  preedit_cursor_col = 0,
  extmark_id = nil,
}

local ns_id = vim.api.nvim_create_namespace("neovide_ime_preedit_ns")

local function cleanup_extmark()
  if ime_context.extmark_id ~= nil then
    vim.api.nvim_buf_del_extmark(
      ime_context.extmark_id[1] or 0,
      ns_id,
      ime_context.extmark_id[2]
    )
  end
  ime_context.extmark_id = nil
end



ime_context.reset = function()
  ime_context.base_row, ime_context.base_col = 0, 0
  ime_context.preedit_cursor_row, ime_context.preedit_cursor_col = 0, 0
  ime_context.preedit_text_row, ime_context.preedit_text_col = 0, 0
  ime_context.entered_preedit_block = false
  ime_context.is_commited = false
  cleanup_extmark()
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
---@param cursor_offset? [integer, integer] (start_col, end_col) This values
local function preedit_handler_insert(preedit_raw_text, cursor_offset)
  if ime_context.is_commited then
    ime_context.reset()
  end
  if not ime_context.entered_preedit_block then
    -- Initialize the base position when entering a new preedit block
    local row, col = get_position_under_cursor()
    ime_context.base_row = row
    ime_context.base_col = col
    ime_context.preedit_text_row = ime_context.base_row
    ime_context.preedit_text_col = ime_context.base_col
    ime_context.preedit_cursor_row = ime_context.base_row
    ime_context.preedit_cursor_col = ime_context.base_col
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

local previous_guicursor = nil

local function hide_guicursor()
  if previous_guicursor ~= nil then
    return
  end
  previous_guicursor = vim.o.guicursor
  -- Make the cursor a thin vertical line to make it invisible.
  vim.o.guicursor = "a:ver1"
end
local function restore_guicursor()
  if previous_guicursor == nil then
    return
  end
  vim.o.guicursor = previous_guicursor
  previous_guicursor = nil
end

---@param preedit_raw_text string
---@param cursor_offset? [integer, integer] (start_col, end_col) This values
local function preedit_handler_extmark(preedit_raw_text, cursor_offset)
  if ime_context.is_commited then
    ime_context.reset()
  end

  -- Always update the base position because the cursor might move during preedit, especially in terminal mode.
  local row, col = get_position_under_cursor()
  ime_context.base_row = row
  ime_context.base_col = col
  ime_context.preedit_text_row = ime_context.base_row
  ime_context.preedit_text_col = ime_context.base_col
  ime_context.preedit_cursor_row = ime_context.base_row
  ime_context.preedit_cursor_col = ime_context.base_col
  ime_context.entered_preedit_block = true

  if preedit_raw_text ~= nil and preedit_raw_text ~= "" and cursor_offset ~= nil then
    -- Hide the original cursor because cursor will be drawn by the extmark
    hide_guicursor()

    -- Update the preedit text and cursor position if there is preedit text
    ime_context.preedit_cursor_col = ime_context.base_col + cursor_offset[2]
    ime_context.preedit_text_col = ime_context.base_col + string.len(preedit_raw_text)

    local buffer_id
    if ime_context.extmark_id ~= nil then
      buffer_id = ime_context.extmark_id[1]
    else
      buffer_id = vim.api.nvim_get_current_buf()
    end

    local selected_section
    if cursor_offset[1] == cursor_offset[2] then
      -- To get selected character when cursor_offset[1] == cursor_offset[2]:
      -- 1. Get the preedit text from the cursor end position to the last character.
      -- 2. Use vim.fn.slice to get the first character of the above text. (This handles multi-byte characters correctly)
      selected_section = vim.fn.slice(preedit_raw_text:sub(cursor_offset[2] + 1), 0, 1)
    else
      selected_section = preedit_raw_text:sub(cursor_offset[1] + 1, cursor_offset[2])
    end

    -- Set the highlight for the selected character
    -- If the cursor is at the end of the preedit text (selected_char is empty), append a space and highlight it.
    -- If not, highlight the selected character.
    local virt_text = {
      { preedit_raw_text:sub(1, cursor_offset[1]),                           "ImePreedit" },
      { selected_section ~= "" and selected_section or " ",                  "ImePreeditCursor" },
      { preedit_raw_text:sub(cursor_offset[1] + selected_section:len() + 1), "ImePreedit" },
    }

    ime_context.extmark_id = {
      buffer_id,
      vim.api.nvim_buf_set_extmark(
        buffer_id,
        ns_id,
        ime_context.base_row - 1, ime_context.base_col,
        {
          id = ime_context.extmark_id and ime_context.extmark_id[2] or nil,
          virt_text = virt_text,
          virt_text_pos = "overlay",
          hl_mode = "combine",
        }
      )
    }
  else
    -- Clear the preedit text and reset the cursor position if there is no preedit text
    ime_context.entered_preedit_block = false
    cleanup_extmark()
    restore_guicursor()
    vim.api.nvim_win_set_cursor(0, { ime_context.base_row, ime_context.base_col })
  end
end

---@param preedit_raw_text string
---@param cursor_offset? [integer, integer] (start_col, end_col) This values show the cursor begin position and end position. The position is byte-wise indexed.
M.preedit_handler = function(preedit_raw_text, cursor_offset)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" then
    preedit_handler_insert(preedit_raw_text, cursor_offset)
  else
    preedit_handler_extmark(preedit_raw_text, cursor_offset)
  end
end

---@param _commit_raw_text string
---@param commit_formatted_text string It's escaped.
local function commit_handler_insert(_commit_raw_text, commit_formatted_text)
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

local function commit_handler_extmark(_commit_raw_text, commit_formatted_text)
  cleanup_extmark()
  restore_guicursor()
  vim.api.nvim_input(commit_formatted_text)

  ime_context.is_commited = true
end

---@param _commit_raw_text string
---@param commit_formatted_text string It's escaped.
M.commit_handler = function(_commit_raw_text, commit_formatted_text)
  local mode = vim.api.nvim_get_mode().mode
  if mode == "i" then
    commit_handler_insert(_commit_raw_text, commit_formatted_text)
  else
    commit_handler_extmark(_commit_raw_text, commit_formatted_text)
  end
end

return M
