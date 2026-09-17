-- Flash jump motions (vim-easymotion successor)
-- https://github.com/folke/flash.nvim
-- s: jump by search; <leader>f: Treesitter node select;
-- <leader>h/j/k/l: word-start/line-start jumps like easymotion's b/j/k/w,
-- labeled hop-style with two lowercase letters: the first picks the group,
-- the second jumps.

vim.pack.add { 'https://github.com/folke/flash.nvim' }

local Flash = require 'flash'

Flash.setup {
  label = {
    uppercase = false,
  },
}

-- Render both label characters at once: label1 narrows (FlashMatch color),
-- label2 jumps (FlashLabel color).
---@param opts Flash.Format
local function format(opts)
  return {
    { opts.match.label1, 'FlashMatch' },
    { opts.match.label2, 'FlashLabel' },
  }
end

-- Easymotion-style directional jump over word starts ([[\<]]) or line
-- starts ('^'), based on flash's documented two-char jump recipe.
local function easymotion(forward, pattern)
  return function()
    Flash.jump {
      search = { mode = 'search', forward = forward, wrap = false, multi_window = false },
      label = { after = false, before = { 0, 0 }, uppercase = false, format = format },
      pattern = pattern,
      action = function(match, state)
        state:hide()
        Flash.jump {
          search = { max_length = 0 },
          highlight = { matches = false },
          label = { uppercase = false, format = format },
          matcher = function(win)
            return vim.tbl_filter(function(m) return m.label == match.label and m.win == win end, state.results)
          end,
          labeler = function(matches)
            for _, m in ipairs(matches) do
              m.label = m.label2
            end
          end,
        }
      end,
      labeler = function(matches, state)
        local labels = state:labels()
        for m, match in ipairs(matches) do
          match.label1 = labels[math.floor((m - 1) / #labels) + 1]
          match.label2 = labels[(m - 1) % #labels + 1]
          match.label = match.label1
        end
      end,
    }
  end
end

vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>f', function() require('flash').treesitter() end, { desc = 'Flash [T]reesitter' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>h', easymotion(false, [[\<]]), { desc = 'Flash word starts up' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>j', easymotion(true, '^'), { desc = 'Flash line starts down' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>k', easymotion(false, '^'), { desc = 'Flash line starts up' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>l', easymotion(true, [[\<]]), { desc = 'Flash word starts down' })
