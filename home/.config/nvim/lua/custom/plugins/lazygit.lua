-- Floating lazygit terminal
-- <leader>gg toggles lazygit in a floating window rooted at the current
-- file's repository; q (or lazygit's own quit) closes it. With the shared
-- lazygit config's `nvim-remote` editPreset, pressing e inside lazygit opens
-- files in a new tab of this Neovim instance.

local float_win = nil

local function close_float()
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    vim.api.nvim_win_close(float_win, true)
  end
  float_win = nil
end

vim.api.nvim_create_user_command('LazyGit', function(opts)
  if float_win and vim.api.nvim_win_is_valid(float_win) then
    close_float()
    return
  end
  if vim.fn.executable 'lazygit' == 0 then
    vim.notify('lazygit is not on PATH', vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  float_win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
  })

  vim.bo[buf].bufhidden = 'wipe'
  vim.keymap.set('n', 'q', close_float, { buffer = buf })
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    callback = function()
      vim.schedule(close_float)
    end,
  })

  local cmd = { 'lazygit' }
  local args = vim.trim(opts.args or '')
  if args ~= '' then
    vim.list_extend(cmd, vim.split(args, '%s+'))
  end
  local job = { cwd = vim.fs.root(0, '.git') or vim.uv.cwd() }
  local config_dir = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')
  local base_config = vim.env.LG_CONFIG_FILE or (config_dir .. '/lazygit/config.yml')
  local dark_theme = config_dir .. '/lazygit/frappe.yml'
  if vim.uv.fs_stat(base_config) and vim.uv.fs_stat(dark_theme) then
    job.env = { LG_CONFIG_FILE = base_config .. ',' .. dark_theme }
  end
  vim.fn.termopen(cmd, job)
  vim.cmd 'startinsert'
end, { nargs = '*', desc = 'Toggle lazygit floating window' })

vim.api.nvim_create_user_command('LazyGitConfig', function()
  local config = vim.env.LG_CONFIG_FILE
    or (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. '/.config')) .. '/lazygit/config.yml'
  vim.cmd('edit ' .. vim.fn.fnameescape(config))
end, { desc = 'Edit the managed lazygit config' })

vim.keymap.set('n', '<leader>gg', '<Cmd>LazyGit<CR>', { desc = '[G]it [G] lazygit', silent = true })
