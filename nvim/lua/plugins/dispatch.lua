return {
  "tpope/vim-dispatch",
  event = "VeryLazy",
  config = function()
    vim.g.dispatch_no_maps = 0

    vim.keymap.set("n", "<leader>ds", ":Dispatch<space>")

    local eslint_cmd = "-compiler=eslint npm exec eslint -- -f compact"
    vim.keymap.set("n", "<leader>dla", "<cmd>Dispatch " .. eslint_cmd .. " .<cr>")
    vim.keymap.set("n", "<leader>dle", "<cmd>Dispatch " .. eslint_cmd .. " --quiet .<cr>")
  end,
}
