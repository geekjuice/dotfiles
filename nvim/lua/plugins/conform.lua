return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "Prettier", "Oxfmt" },
  config = function()
    local conform = require("conform")
    local util = require("conform.util")

    -- oxfmt primary, prettier fallback. stop_after_first runs the first
    -- available formatter, so prettier only kicks in when oxfmt is missing.
    -- oxfmt only handles JS/TS/JSX/TSX/JSON; css/html stay prettier-only.
    local js_format = { "oxfmt", "prettier", stop_after_first = true }

    conform.setup({
      formatters_by_ft = {
        -- javascript = { "eslint", "prettier" },
        -- javascriptreact = { "eslint", "prettier" },
        -- typescript = { "eslint", "prettier" },
        -- typescriptreact = { "eslint", "prettier" },
        javascript = js_format,
        javascriptreact = js_format,
        typescript = js_format,
        typescriptreact = js_format,
        json = js_format,
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

    vim.api.nvim_create_user_command("Oxfmt", function()
      conform.format({ formatters = { "oxfmt" } })
    end, {})
  end,
}
