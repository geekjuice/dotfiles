return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  init = function()
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "*",
      callback = function()
        local buf = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("claude") then
          local opts = { buffer = buf, silent = true }
          vim.keymap.set("t", "<C-h>", "<C-\\><C-n><cmd>TmuxNavigateLeft<cr>", opts)
          vim.keymap.set("t", "<C-j>", "<C-\\><C-n><cmd>TmuxNavigateDown<cr>", opts)
          vim.keymap.set("t", "<C-k>", "<C-\\><C-n><cmd>TmuxNavigateUp<cr>", opts)
          vim.keymap.set("t", "<C-l>", "<C-\\><C-n><cmd>TmuxNavigateRight<cr>", opts)
        end
      end,
    })
  end,
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.4,
    },
  },
  keys = {
    { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>cC", "<cmd>ClaudeCode --dangerously-skip-permissions<cr>", desc = "Toggle Claude Code (danger mode)" },
    { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>ca", ":ClaudeCodeAdd ", desc = "Add file to Claude context" },
  },
}
