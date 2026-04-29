return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "Prettier" },
  config = function()
    local conform = require("conform")
    local util = require("conform.util")

    conform.setup({
      formatters_by_ft = {
        -- javascript = { "eslint", "prettier" },
        -- javascriptreact = { "eslint", "prettier" },
        -- typescript = { "eslint", "prettier" },
        -- typescriptreact = { "eslint", "prettier" },
        javascript = { "prettier", stop_after_first = true },
        javascriptreact = { "prettier", stop_after_first = true },
        typescript = { "prettier", stop_after_first = true },
        typescriptreact = { "prettier", stop_after_first = true },
        json = { "prettier", stop_after_first = true },
        lua = { "stylua" },
        css = { "prettier" },
        html = { "prettier" },
      },
      formatters = {
        eslint = {
          command = util.from_node_modules("eslint"),
          args = { "--fix", "--no-warn-ignored", "$FILENAME" },
          stdin = false,
          tmpfile_format = "$FILENAME",
          cwd = util.root_file({
            "eslint.config.js",
            "eslint.config.cjs",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            "package.json",
          }),
          require_cwd = true,
        },
      },
      -- format_after_save = {
      --   lsp_format = "fallback",
      -- },
    })

    vim.api.nvim_create_user_command("Prettier", function()
      conform.format({ formatters = { "prettier" } })
    end, {})
  end,
}
