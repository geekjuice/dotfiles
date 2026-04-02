return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>o", "<cmd>NvimTreeToggle<cr><C-w>=", desc = "Toggle file tree" },
    { "<leader>i", "<cmd>NvimTreeFocus<cr><C-w>=", desc = "Focus file tree" },
    { "<leader>ff", "<cmd>NvimTreeFindFile<cr><C-w>=", desc = "Find file in tree" },
  },
  config = function()
    local default_width = 30

    require("nvim-tree").setup({
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "A", function()
          local win = vim.api.nvim_get_current_win()
          local cur = vim.api.nvim_win_get_width(win)
          if cur > default_width then
            vim.api.nvim_win_set_width(win, default_width)
          else
            local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
            local max = default_width
            for _, line in ipairs(lines) do
              max = math.max(max, vim.fn.strdisplaywidth(line) + 2)
            end
            vim.api.nvim_win_set_width(win, max)
          end
        end, { buffer = bufnr, desc = "Toggle tree width" })
      end,
      filters = {
        custom = { "node_modules" },
      },
      actions = {
        open_file = {
          quit_on_open = true,
          window_picker = { enable = false },
        },
      },
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
          },
        },
      },
      view = {
        width = 30,
      },
      git = {
        ignore = false,
      },
    })
  end,
}
