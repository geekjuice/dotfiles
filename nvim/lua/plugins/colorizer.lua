return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    filetypes = { "css", "html", "javascript", "typescript", "typescriptreact" },
    user_default_options = {
      css = true,
      tailwind = false,
    },
  },
}
