-- Options (translated from vimrc set commands)

local opt = vim.opt

-- Ensure mise shims are in PATH (needed by Mason for npm-based LSP servers)
local mise_shims = vim.fn.expand("$HOME/.local/share/mise/shims")
if vim.fn.isdirectory(mise_shims) == 1 and not vim.env.PATH:find(mise_shims, 1, true) then
  vim.env.PATH = mise_shims .. ":" .. vim.env.PATH
end

-- Appearance
opt.cursorline = true
opt.number = true
opt.numberwidth = 4
opt.relativenumber = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.background = "dark"
opt.showmatch = true
opt.showcmd = true
opt.ruler = true
opt.laststatus = 2
opt.fillchars = { vert = "│", fold = "-" }

-- Search
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true
opt.smartcase = true

-- Scrolling
opt.scrolloff = 999

-- Encoding
opt.encoding = "utf-8"

-- Concealing
opt.conceallevel = 0
opt.concealcursor = "nvic"

-- Folding
opt.foldenable = false

-- Modeline
opt.modeline = false

-- List characters
opt.list = true
opt.listchars = { tab = "»·", trail = "·" }

-- Text width
opt.textwidth = 80
opt.redrawtime = 5000

-- Update time
opt.updatetime = 250

-- Session options
opt.sessionoptions:remove("blank")

-- Tmp file settings
opt.swapfile = false
opt.backup = true
opt.backupdir = { "/var/tmp", "/tmp" }
opt.directory = { "/var/tmp", "/tmp" }
opt.writebackup = true

-- Persistent undo
opt.undofile = true
local undodir = "/tmp/vim/undo"
opt.undodir = undodir
vim.fn.mkdir(undodir, "p")

-- Whitespace
opt.smarttab = true
opt.expandtab = true
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.joinspaces = false

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Tab completion (command-line)
opt.wildmode = { "list:longest", "list:full" }
opt.complete = { ".", "w", "t" }

-- Grep program (ripgrep)
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --no-heading"
  opt.grepformat = { "%f:%l:%c:%m", "%f:%l:%m" }
end
