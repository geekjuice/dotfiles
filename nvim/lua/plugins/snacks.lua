return {
  "folke/snacks.nvim",
  lazy = false,
  keys = {
    -- stylua: ignore start
    { "<leader>z", function() Snacks.zen() end, desc = "Toggle zen mode" },
    { "<leader>lzg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>ghi", function() Snacks.picker.gh_issue() end, desc = "GitHub issues" },
    { "<leader>ghp", function() Snacks.picker.gh_pr() end, desc = "GitHub PRs" },
    -- stylua: ignore end
  },
  ---@type snacks.Config
  opts = {
    zen = {
      width = 120,
      on_open = function()
        vim.g.lint_enabled = false
      end,
    },
    lazygit = { enabled = true },
    gh = { enabled = true },
    picker = { enabled = true },
  },
}
