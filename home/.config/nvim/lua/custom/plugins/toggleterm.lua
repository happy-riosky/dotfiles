-- Floating terminal (toggleterm.nvim)
-- https://github.com/akinsho/toggleterm.nvim
-- <leader>tt toggles a centered 0.8x0.8 floating terminal. Inside the
-- terminal, <Esc><Esc> (mapped in init.lua) returns to normal mode; the
-- dedicated lazygit float (<leader>gg) stays separate.

vim.pack.add { 'https://github.com/akinsho/toggleterm.nvim' }

local toggleterm = require 'toggleterm'

toggleterm.setup {
  direction = 'float',
  float_opts = {
    border = 'rounded',
    width = function() return math.floor(vim.o.columns * 0.8) end,
    height = function() return math.floor(vim.o.lines * 0.8) end,
  },
  shade_terminals = false,
  persist_size = true,
}

vim.keymap.set('n', '<leader>tt', '<Cmd>ToggleTerm<CR>', { desc = '[T]erminal [t]oggle (float)' })
