return {
  {
    "shaunsingh/nord.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("nord")
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#3b4252" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#3b4252" })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#4c566a", bg = "#3b4252" })
    end,
  },
  {
    "embark-theme/vim",
    name = "embark",
    lazy = true,
  },
}
