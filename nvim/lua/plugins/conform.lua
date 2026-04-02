return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo", "Prettier" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier", stop_after_first = true },
        typescript = { "prettier", stop_after_first = true },
        typescriptreact = { "prettier", stop_after_first = true },
        json = { "prettier", stop_after_first = true },
        lua = { "stylua" },
        css = { "prettier" },
        html = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
      },
    })

    vim.api.nvim_create_user_command("Prettier", function()
      conform.format({ formatters = { "prettier" } })
    end, {})
  end,
}
