-- Keymaps (non-plugin, translated from vimrc)

local map = vim.keymap.set

-- Force <C-c> to behave exactly like <Esc>
map({ "n", "i" }, "<C-c>", function()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd("stopinsert")
end)

-- Colon -> semicolon
map("n", ";", ":")
map("v", ";", ":")

-- Space is leader (nop to prevent movement)
map("n", "<Space>", "<Nop>")

-- Read/write
map("n", "<leader>q", "<Esc>:q")
map("n", "<leader>w", "<cmd>w<cr><cmd>echo 'file saved'<cr>")
map("n", "<leader>e", "<cmd>noa w<cr><cmd>echo 'file saved without formatting'<cr>")

-- Splits
map("n", "<leader>n", "<cmd>vsplit<cr>")
map("n", "<leader>N", "<cmd>vnew<cr>")
map("n", "<leader>m", "<cmd>split<cr>")
map("n", "<leader>M", "<cmd>new<cr>")
map("n", "<leader>w=", "<C-w>=")

-- Tabs
map("n", "<leader>tn", "<cmd>tabnew<cr>")

-- Last buffer
map("n", "<leader>;", "<C-^><cr>")

-- Whitespace cleaner
map("n", "<leader><BS><BS>", "mz:ret<cr>:%s/\\s\\+$//e<cr>`z")

-- Empty line cleaner
map("n", "<leader><BS>=", ":%g/^$/d<cr>")

-- Newline cleaner
map("n", "<leader><cr>", "mz:ret<cr>:%s/\r/\\r/ge<cr>`z")

-- Move visual blocks
map("v", "<C-j>", ":m '>+1<cr>gv=gv")
map("v", "<C-k>", ":m '<-2<cr>gv=gv")

-- Search visual selection
map("v", "*", 'y/<C-r>"<cr>')

-- Search without initial jump
map("n", "*", ":let @/ = '\\<'.expand('<cword>').'\\>'|set hlsearch<cr>", { silent = true })
map("n", "g*", ":let @/ = expand('<cword>')|set hlsearch<cr>", { silent = true })

-- Clipboard
map("v", "[cc", '"*y')
map("n", "[cp", '"*p')
map("n", "[cf", '<cmd>let @+=expand("%:p")<cr>')

-- Vimrc
map("n", "<leader>ve", "<cmd>e $MYVIMRC<cr>")
map("n", "<leader>vs", "<cmd>so $MYVIMRC<cr>")

-- Lazy
map("n", "<leader>ll", "<cmd>Lazy<cr>")

-- Screw ex mode
map("n", "Q", "<Nop>")

-- Force redraw
map("n", "<leader>r", "<cmd>redraw!<cr>")

-- Get off my lawn
map("n", "<Left>", '<cmd>echo "Use h"<cr>')
map("n", "<Right>", '<cmd>echo "Use l"<cr>')
map("n", "<Up>", '<cmd>echo "Use k"<cr>')
map("n", "<Down>", '<cmd>echo "Use j"<cr>')

-- Decrement/increment
map("n", "[oe", "<C-x>")
map("n", "]oe", "<C-a>")
map("v", "[oe", "<C-x>")
map("v", "]oe", "<C-a>")

-- Merge tool
map("n", "<leader>1", "<cmd>diffget LOCAL<cr>")
map("n", "<leader>2", "<cmd>diffget BASE<cr>")
map("n", "<leader>3", "<cmd>diffget REMOTE<cr>")

-- jq formatting
map("n", "<leader>jj", "<cmd>set ft=json<cr>:%!jq .<cr>")
