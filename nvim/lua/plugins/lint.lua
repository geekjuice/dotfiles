return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
      css = { "eslint" },
    }

    vim.g.lint_enabled = false

    vim.api.nvim_create_autocmd({ "TextChanged", "BufEnter", "InsertLeave" }, {
      callback = function()
        if vim.g.lint_enabled then
          lint.try_lint()
        end
      end,
    })

    vim.keymap.set("n", "yoa", function()
      vim.g.lint_enabled = not vim.g.lint_enabled
      if vim.g.lint_enabled then
        lint.try_lint()
        print("Lint enabled")
      else
        vim.diagnostic.reset()
        print("Lint disabled")
      end
    end)
  end,
}
