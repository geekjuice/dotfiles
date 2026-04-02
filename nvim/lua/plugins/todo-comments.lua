return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "Search TODOs" },
  },
  opts = {},
}
