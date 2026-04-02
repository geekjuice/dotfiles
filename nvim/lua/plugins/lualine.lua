return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "nord",
        section_separators = { left = "\u{e0b0}", right = "\u{e0b2}" },
        component_separators = { left = "\u{e0b1}", right = "\u{e0b3}" },
      },
    })
  end,
}
