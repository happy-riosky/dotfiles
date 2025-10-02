return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",  -- 选择 Mocha 变体（其他选项：latte, frappe, macchiato）
        background = {      -- 可选：设置背景
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,  -- 可选：是否透明背景
        show_end_of_buffer = false,      -- 可选：是否显示缓冲区末尾
        term_colors = true,              -- 可选：终端颜色支持
        dim_inactive = {
          enabled = false,               -- 可选：非活动窗口变暗
          shade = "dark",
          percentage = 0.15,
        },
        integrations = {                  -- 可选：集成其他插件
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = false,
          mini = {
            enabled = true,
            indentscope_color = "",
          },
        },
      })
      -- 应用主题
      vim.cmd.colorscheme "catppuccin"
    end,
  },
}

