return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },
    completion = {
      list = {
        selection = { preselect = false, auto_insert = true },
      },
      documentation = {
        auto_show = true,
      },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
  },
}
