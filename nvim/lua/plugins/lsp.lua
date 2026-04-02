return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "cssls",
          "html",
          "jsonls",
          "eslint",
          "lua_ls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Configure servers using vim.lsp.config (Neovim 0.11+)
      local servers = { "ts_ls", "cssls", "html", "jsonls", "eslint" }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
      end

      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      })

      -- Enable all servers
      vim.lsp.enable(servers)
      vim.lsp.enable("lua_ls")

      -- Keymaps on LspAttach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf, silent = true }
          local map = vim.keymap.set

          map("n", "[g", vim.diagnostic.goto_prev, opts)
          map("n", "]g", vim.diagnostic.goto_next, opts)
          map("n", "gd", vim.lsp.buf.definition, opts)
          map("n", "gy", vim.lsp.buf.type_definition, opts)
          map("n", "gi", vim.lsp.buf.implementation, opts)
          map("n", "gr", vim.lsp.buf.references, opts)
          map("n", "K", vim.lsp.buf.hover, opts)

          -- Definition in split/vsplit
          map("n", "gm", function()
            vim.cmd("split")
            vim.lsp.buf.definition()
          end, opts)
          map("n", "gn", function()
            vim.cmd("vsplit")
            vim.lsp.buf.definition()
          end, opts)

          -- <C-Space> prefix bindings (C-@ in terminal = C-Space)
          map("n", "<C-Space><C-r>", vim.lsp.buf.rename, opts)
          map("n", "<C-Space><C-f>", function()
            vim.lsp.buf.code_action({ context = { only = { "quickfix" } } })
          end, opts)
          map("n", "<C-Space><C-x>", vim.lsp.buf.code_action, opts)
          map("n", "<C-Space><C-s>", function()
            vim.lsp.buf.code_action({ context = { only = { "source" } } })
          end, opts)
          map("n", "<C-Space><C-d>", "<cmd>Telescope diagnostics<cr>", opts)
          map("n", "<C-Space><C-c>", "<cmd>Telescope lsp_document_symbols<cr>", opts)
          map("n", "<C-Space><C-Space>", "<cmd>Telescope resume<cr>", opts)

          -- Document highlight on CursorHold
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            local hl_group = vim.api.nvim_create_augroup("LspHighlight", { clear = false })
            vim.api.nvim_create_autocmd("CursorHold", {
              group = hl_group,
              buffer = ev.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd("CursorMoved", {
              group = hl_group,
              buffer = ev.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
}
