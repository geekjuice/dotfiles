return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    { "<C-\\><C-o>", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files" },
    { "<C-p>", "<cmd>Telescope find_files hidden=true<cr>", desc = "Find files" },
    { "<C-\\><C-i>", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer lines" },
    { "<C-\\><C-r>", ":Telescope live_grep<space>", desc = "Live grep (with prompt)" },
    { "<C-\\><C-f>", ":Telescope find_files hidden=true cwd=", desc = "Find files in dir" },
    { "<C-\\><C-\\>", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
    { "<leader>\\", "<cmd>Telescope grep_string<cr>", desc = "Grep word under cursor" },
    { "<leader>dq", "<cmd>Telescope quickfix<cr>", desc = "Dispatch results (quickfix)" },
    { "<leader>dh", "<cmd>Telescope quickfixhistory<cr>", desc = "Dispatch history" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        layout_config = {
          width = 0.9,
          height = 0.9,
        },
        mappings = {
          i = {
            ["<C-t>"] = actions.select_tab,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
          },
          n = {
            ["<C-t>"] = actions.select_tab,
            ["<C-s>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
      },
    })

    telescope.load_extension("fzf")
  end,
}
