return {
  "rmagatti/auto-session",
  lazy = false,
  config = function()
    local session_dir = "/tmp/vim/sessions"
    vim.fn.mkdir(session_dir, "p")

    require("auto-session").setup({
      auto_session_root_dir = session_dir .. "/",
      auto_save = true,
      auto_restore = true,
      auto_create = true,
      session_lens = { load_on_setup = false },
      suppressed_dirs = { "~/", "/" },
      post_restore_cmds = { "edit" },
    })

    -- Delete current session
    vim.keymap.set("n", "<leader>sd", function()
      require("auto-session").delete_session()
      print("Session deleted")
    end, { desc = "Delete current session" })

    -- Close hidden buffers (replaces <leader>sc -> CloseHiddenBuffers)
    vim.keymap.set("n", "<leader>sc", function()
      local visible = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
      end
      local closed = 0
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and not visible[buf] then
          local bt = vim.bo[buf].buftype
          if bt == "" then
            vim.api.nvim_buf_delete(buf, {})
            closed = closed + 1
          end
        end
      end
      print("Closed " .. closed .. " hidden buffer(s)")
    end, { desc = "Close hidden buffers" })
  end,
}
