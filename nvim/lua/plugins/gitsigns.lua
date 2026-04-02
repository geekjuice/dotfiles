return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      change = { text = "#" },
      changedelete = { text = "_" },
    },
  },
  keys = {
    { "<leader>gh", "<cmd>Gitsigns toggle_linehl<cr>", desc = "Toggle git line highlights" },
  },
}
