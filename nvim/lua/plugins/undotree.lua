return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undo tree" },
  },
  config = function()
    vim.g.undotree_WindowLayout = 3 -- right side
    vim.g.undotree_SplitWidth = 60
    vim.g.undotree_DiffpanelHeight = 20
  end,
}
