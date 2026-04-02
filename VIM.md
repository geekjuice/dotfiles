# Neovim

Lua-native Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Prerequisites

- Neovim >= 0.10
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for Telescope live grep)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)
- Node.js (for LSP servers installed via Mason)
- A C compiler (for telescope-fzf-native and treesitter parsers)

## Install

`symlink.sh` symlinks the `nvim/` directory to `~/.config/nvim/`.

On first launch, lazy.nvim bootstraps itself and installs all plugins automatically. Then run:

```
:Mason          " install/manage LSP servers
:TSUpdate       " install treesitter parsers
```

## Structure

```
nvim/
├── init.lua                          # Entry point (loads all modules)
├── lua/
│   ├── config/
│   │   ├── options.lua               # vim.opt settings
│   │   ├── keymaps.lua               # Non-plugin keymaps
│   │   ├── autocmds.lua              # Autocommands
│   │   └── functions.lua             # Custom functions + theme toggle
│   └── plugins/
│       ├── init.lua                  # lazy.nvim bootstrap
│       ├── autopairs.lua             # Auto-pairing
│       ├── bqf.lua                   # Quickfix enhancements
│       ├── colorizer.lua             # Color preview in code
│       ├── colorscheme.lua           # Nord + Embark themes
│       ├── comment.lua               # Code commenting
│       ├── completion.lua            # blink.cmp completion engine
│       ├── conform.lua               # Formatting (prettier, biome)
│       ├── gitsigns.lua              # Git gutter signs
│       ├── lint.lua                  # nvim-lint (eslint)
│       ├── lsp.lua                   # LSP + Mason
│       ├── lualine.lua               # Statusline
│       ├── nvim-tree.lua             # File tree sidebar
│       ├── session.lua               # Session management
│       ├── surround.lua              # Surround operations
│       ├── telescope.lua             # Fuzzy finder
│       ├── tmux-navigator.lua        # Tmux pane navigation
│       ├── tpope.lua                 # tpope plugin suite
│       ├── treesitter.lua            # Syntax highlighting/parsing
│       ├── undotree.lua              # Undo history tree
│       ├── zen-mode.lua              # Distraction-free writing
│       ├── avante.lua                # AI sidebar chat + agentic diffs
│       └── claudecode.lua            # Claude Code CLI integration
├── after/ftplugin/                   # Filetype-specific settings
│   ├── gitcommit.lua                 # spell, formatoptions
│   ├── javascript.lua                # projectionist alternates
│   ├── markdown.lua                  # spell, indent
│   ├── qf.lua                       # no relativenumber, no wrap
│   ├── sql.lua                      # omni key remap
│   ├── typescript.lua                # projectionist alternates
│   └── typescriptreact.lua           # projectionist alternates
├── ftdetect/
│   └── env.lua                       # .env* -> sh filetype
└── skeletons/
    └── bash.sh                       # Template for new .sh files
```

## Plugins

### Plugin Manager

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager with lazy loading | vim-plug |

### LSP & Completion

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP client configuration | coc.nvim |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP server installer | coc extensions |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | Bridge between mason and lspconfig | coc extensions |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Autocompletion engine | coc.nvim completion |

### Formatting & Linting

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Format on save (biome, prettier) | coc-prettier, coc-biome |
| [nvim-lint](https://github.com/mfussenegger/nvim-lint) | Async linting (eslint) | ALE |

### Fuzzy Finder

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, diagnostics | ctrlp, fzf.vim, vim-grepper |
| [telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | FZF sorter for telescope | fzf |

### Syntax & Treesitter

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting and parsing | vim-polyglot |

### File Management

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File tree sidebar | NERDTree |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File type icons | vim-devicons |

### UI

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline | vim-airline |
| [nvim-colorizer.lua](https://github.com/NvChad/nvim-colorizer.lua) | Inline color preview | vim-css-color |
| [zen-mode.nvim](https://github.com/folke/zen-mode.nvim) | Distraction-free mode | goyo.vim |
| [undotree](https://github.com/mbbill/undotree) | Undo history visualizer | vim-mundo |
| [nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) | Better quickfix window | QFEnter |
| [quickfix-reflector.vim](https://github.com/stefandtw/quickfix-reflector.vim) | Editable quickfix | quickfix-reflector (kept) |

### Git

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git signs in gutter | vim-gitgutter |
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git commands | (kept) |

### Editing

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | Toggle comments (`gc`/`gcc`) | NERDCommenter |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-close brackets/quotes | pear-tree |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Surround operations (`ys`/`ds`/`cs`) | vim-sandwich |

### Sessions

| Plugin | Purpose | Replaces |
|--------|---------|----------|
| [auto-session](https://github.com/rmagatti/auto-session) | Manual session save/restore | vim-workspace |

### Themes

| Plugin | Purpose |
|--------|---------|
| [nord.nvim](https://github.com/shaunsingh/nord.nvim) | Nord colorscheme (default) |
| [embark](https://github.com/embark-theme/vim) | Embark colorscheme (toggle) |

### tpope Suite (kept as-is)

| Plugin | Purpose |
|--------|---------|
| [vim-abolish](https://github.com/tpope/vim-abolish) | Case-coercion and smart substitution |
| [vim-dispatch](https://github.com/tpope/vim-dispatch) | Async build/test commands |
| [vim-eunuch](https://github.com/tpope/vim-eunuch) | Unix shell commands |
| [vim-projectionist](https://github.com/tpope/vim-projectionist) | Alternate file navigation |
| [vim-unimpaired](https://github.com/tpope/vim-unimpaired) | Bracket mappings for pairs of commands |

### AI

| Plugin | Purpose |
|--------|---------|
| [avante.nvim](https://github.com/yetone/avante.nvim) | Cursor-like AI sidebar with agentic diffs (Claude backend) |
| [claudecode.nvim](https://github.com/coder/claudecode.nvim) | Claude Code CLI integration with IDE context sharing |

avante.nvim opens a sidebar where you chat with Claude about your code. It produces diffs you accept/reject with a keypress. In agentic mode (default), Claude autonomously runs tools until the task is done. Requires `ANTHROPIC_API_KEY` env var.

claudecode.nvim connects to Claude Code CLI over WebSocket, sharing your open buffers, selections, and file tree. It gives the same experience as the VS Code extension.

### Navigation

| Plugin | Purpose |
|--------|---------|
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless tmux/vim pane switching (`C-h/j/k/l`) |

## LSP Servers

Auto-installed via Mason:

| Server | Language |
|--------|----------|
| `ts_ls` | TypeScript / JavaScript |
| `cssls` | CSS |
| `html` | HTML |
| `jsonls` | JSON |
| `eslint` | JS/TS linting via LSP |
| `lua_ls` | Lua |

Formatting is handled by conform.nvim with `biome` (preferred) and `prettier` (fallback) for JS/TS/JSON/CSS/HTML.

## Keybindings

Leader key is `Space`. `;` is mapped to `:` in normal and visual mode.

### General

| Mapping | Action |
|---------|--------|
| `<leader>w` | Save file |
| `<leader>e` | Save without formatting |
| `<leader>q` | Quit |
| `<leader>n` | New vertical split |
| `<leader>m` | New horizontal split |
| `<leader>w=` | Equalize split sizes |
| `<leader>tn` | New tab |
| `<leader>;` | Last buffer |
| `<leader>r` | Force redraw |
| `<leader>ve` | Edit config |
| `<leader>vs` | Source config |
| `<leader>jj` | Format buffer as JSON via jq |
| `Q` | Disabled (no ex mode) |

### Cleaning

| Mapping | Action |
|---------|--------|
| `<leader><BS><BS>` | Strip trailing whitespace |
| `<leader><BS>=` | Delete empty lines |
| `<leader><CR>` | Fix carriage returns |
| `<leader>jp` | Join wrapped paragraphs |

### Search (Telescope)

| Mapping | Action |
|---------|--------|
| `<C-p>` | Find files |
| `<C-\><C-o>` | Find files |
| `<C-\><C-i>` | Fuzzy find in current buffer |
| `<C-\><C-r>` | Live grep (with prompt) |
| `<C-\><C-f>` | Find files in directory |
| `<C-\><C-\>` | Live grep |
| `<leader>\` | Grep word under cursor |
| `<leader>td` | Search TODOs/FIXMEs |

Inside Telescope: `<C-t>` open in tab, `<C-s>` open in split, `<C-v>` open in vsplit.

### File Tree (nvim-tree)

| Mapping | Action |
|---------|--------|
| `<leader>o` | Toggle file tree |
| `<leader>i` | Focus file tree |
| `<leader>ff` | Find current file in tree |

### LSP

| Mapping | Action |
|---------|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `gm` | Definition in horizontal split |
| `gn` | Definition in vertical split |
| `K` | Hover documentation |
| `[g` / `]g` | Previous / next diagnostic |
| `<C-Space><C-r>` | Rename symbol |
| `<C-Space><C-f>` | Code action (quickfix) |
| `<C-Space><C-x>` | Code action (cursor) |
| `<C-Space><C-s>` | Code action (source) |
| `<C-Space><C-d>` | List diagnostics |
| `<C-Space><C-c>` | List document symbols |
| `<C-Space><C-Space>` | Resume last Telescope picker |

### Completion (blink.cmp)

| Mapping | Action |
|---------|--------|
| `<Tab>` | Next completion item |
| `<S-Tab>` | Previous completion item |
| `<CR>` | Accept completion |

### AI

| Mapping | Action |
|---------|--------|
| `<leader>cc` | Toggle Claude Code terminal |
| `<leader>cs` (visual) | Send selection to Claude Code |
| `<leader>ca` | Add file to Claude Code context |

avante.nvim uses its own keybindings (set via `auto_set_keymaps`): `<leader>aa` to toggle sidebar, `<leader>ae` to edit selection, etc. Run `:help avante` for the full list.

### Git

| Mapping | Action |
|---------|--------|
| `<leader>gh` | Toggle git line highlights |
| `[c` / `]c` | Previous / next hunk (gitsigns default) |

### Commenting (Comment.nvim)

| Mapping | Action |
|---------|--------|
| `gcc` | Toggle line comment |
| `gc` (visual) | Toggle comment on selection |

### Surround (nvim-surround)

| Mapping | Action |
|---------|--------|
| `ys{motion}{char}` | Add surround |
| `ds{char}` | Delete surround |
| `cs{old}{new}` | Change surround |

### Clipboard

| Mapping | Action |
|---------|--------|
| `[cc` (visual) | Yank to system clipboard |
| `[cp` | Paste from system clipboard |
| `[cf` | Copy file path to clipboard |

### Toggles

| Mapping | Action |
|---------|--------|
| `` <leader>` `` | Toggle theme (Nord / Embark) |
| `<leader>z` | Toggle zen mode |
| `<leader>u` | Toggle undo tree |
| `yoq` | Toggle quickfix window |
| `yoa` | Toggle linting |

### Sessions

| Mapping | Action |
|---------|--------|
| `<leader>ss` | Toggle session save/restore |
| `<leader>sc` | Close hidden buffers |

### Projectionist

| Mapping | Action |
|---------|--------|
| `<leader>aa` | Open alternate file |
| `<leader>as` | Open alternate in split |
| `<leader>av` | Open alternate in vsplit |

Alternates are configured for JS/TS/TSX: source <-> test <-> stories.

### Dispatch

| Mapping | Action |
|---------|--------|
| `<leader>ds` | Dispatch command (with prompt) |
| `<leader>dla` | ESLint all files |
| `<leader>dle` | ESLint all files (quiet) |

### Merge Tool

| Mapping | Action |
|---------|--------|
| `<leader>1` | diffget LOCAL |
| `<leader>2` | diffget BASE |
| `<leader>3` | diffget REMOTE |

### Visual Mode

| Mapping | Action |
|---------|--------|
| `<C-j>` | Move block down |
| `<C-k>` | Move block up |
| `*` | Search visual selection |

### Misc

| Mapping | Action |
|---------|--------|
| `[oe` / `]oe` | Decrement / increment number |
| `*` | Highlight word (no jump) |
| `g*` | Highlight partial word (no jump) |

## Filetype Settings

| Filetype | Settings |
|----------|----------|
| `gitcommit` | Spell check, adjusted formatoptions |
| `markdown` | Spell check, 2-space indent |
| `qf` | Absolute line numbers, no wrap |
| `sql` | Omni completion on `<C-s>` |
| `javascript` | Projectionist alternates (source/test/stories) |
| `typescript` | Projectionist alternates (source/test/stories) |
| `typescriptreact` | Projectionist alternates (source/test/stories) |
| `.env*` | Detected as `sh` filetype |
| `*.sh` (new file) | Populated with bash skeleton template |

## Notes

- The old `vimrc` and `vim/` directory are kept intact for regular Vim usage.
- Format on save is enabled by default. Use `<leader>e` to save without formatting.
- Linting (nvim-lint) starts disabled. Toggle with `yoa`.
- Window navigation (`<C-h/j/k/l>`) is handled by vim-tmux-navigator and works across both Vim splits and tmux panes.
- Lazy.nvim UI: `:Lazy` to manage plugins, check updates, view profiles.
