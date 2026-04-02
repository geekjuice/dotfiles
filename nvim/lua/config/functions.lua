-- Custom functions (translated from vimrc)

-- Join wrapped paragraphs
function JoinParagraphs()
  local cursor = vim.fn.winsaveview()
  vim.cmd([[silent %s/\(\s*\S\s*\)\n\(\s*\S\s*\)/\1 \2/e]])
  vim.cmd([[silent %s/\v\s+/ /ge]])
  vim.fn.winrestview(cursor)
end

vim.keymap.set("n", "<leader>jp", JoinParagraphs)

-- Toggle quickfix
function ToggleQuickFix()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end

vim.api.nvim_create_user_command("ToggleQuickFix", ToggleQuickFix, {})
vim.keymap.set("n", "yoq", "<cmd>ToggleQuickFix<cr>")

-- Toggle theme (colorscheme + lualine)
function ToggleTheme()
  local current = vim.g.colors_name
  if current == "nord" then
    vim.cmd.colorscheme("embark")
    local ok, lualine = pcall(require, "lualine")
    if ok then
      lualine.setup({ options = { theme = "embark" } })
    end
  else
    vim.cmd.colorscheme("nord")
    local ok, lualine = pcall(require, "lualine")
    if ok then
      lualine.setup({ options = { theme = "nord" } })
    end
  end
end

vim.keymap.set("n", "<leader>`", ToggleTheme)

-- Skeleton files
local skeletons_dir = vim.fn.stdpath("config") .. "/skeletons/"
local skeletons = {
  ["*.sh"] = "bash.sh",
}

for pattern, skeleton in pairs(skeletons) do
  vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = pattern,
    command = "0r " .. skeletons_dir .. skeleton,
  })
end
