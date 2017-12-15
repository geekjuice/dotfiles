" vim-plug
call plug#begin('$HOME/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'ajh17/VimCompletesMe'
Plug 'ap/vim-css-color'
Plug 'arcticicestudio/nord-vim'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'dense-analysis/ale'
Plug 'diepm/vim-rest-console'
Plug 'embark-theme/vim', { 'as': 'embark' }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim', { 'on': 'Goyo' }
Plug 'junegunn/vim-peekaboo'
Plug 'machakann/vim-sandwich'
Plug 'mhinz/vim-grepper'
Plug 'preservim/nerdcommenter'
Plug 'preservim/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'preservim/vimux'
Plug 'prettier/vim-prettier'
Plug 'rizzatti/dash.vim'
Plug 'ryanoasis/vim-devicons'
Plug 'sheerun/vim-polyglot'
Plug 'simnalamburt/vim-mundo', { 'on': 'MundoToggle' }
Plug 'stefandtw/quickfix-reflector.vim'
Plug 'thaerkh/vim-workspace'
Plug 'tmsvg/pear-tree'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'vim-airline/vim-airline'

call plug#end()

" vim-airline
let g:airline_theme = 'nord'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tmuxline#enabled = 0
let g:airline#extensions#tabline#enabled = 0
let g:tmuxline_preset = 'powerline'

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.dirty='*'

" force <c-c> to behave exactly like <esc>
noremap <c-c> <esc>

" colon -> semicolon
nnoremap ; :
vnoremap ; :

" leader commands
let mapleader = " "

" read/write
nnoremap <leader>q <esc>:q
nnoremap <leader>w <esc>:w<cr>:echo "file saved"<cr>

" splits
nnoremap <leader>n :vnew<cr>
nnoremap <leader>m :new<cr>
nnoremap <leader>w= <c-w>=

" tabs
nnoremap <leader>tn :tabnew<cr>

" last buffer
nnoremap <leader>; <c-^><cr>

" whitespace cleaner
nnoremap <leader><BS><BS> mz:ret<cr>:%s/\s\+$//e<cr>`z

" empty line cleaner
nnoremap <leader><BS>= :%g/^$/d<cr>

" newline cleaner
nnoremap <leader><cr> mz:ret<cr>:%s//\r/ge<cr>`z

" move visual blocks
vnoremap <c-j> :m '>+1<cr>gv=gv
vnoremap <c-k> :m '<-2<cr>gv=gv

" search visual selection
vnoremap * y/<c-r>"<cr>

" clipboard
vnoremap [cc "*y
nnoremap [cp "*p
nnoremap [cf :let @+=expand("%:p")<cr>

" vimrc
nnoremap <leader>ve :e $MYVIMRC<cr>
nnoremap <leader>vs :so $MYVIMRC<cr>

" screw ex mode
nnoremap Q <Nop>

" force redraw
nnoremap <leader>r :redraw!<cr>

" get off my lawn
nnoremap <Left> :echo "Use h"<cr>
nnoremap <Right> :echo "Use l"<cr>
nnoremap <Up> :echo "Use k"<cr>
nnoremap <Down> :echo "Use j"<cr>

" switch ctrl-movement keys to window switching
nmap <c-k> <c-w><Up>
nmap <c-j> <c-w><Down>
nmap <c-l> <c-w><Right>
nmap <c-h> <c-w><Left>

" decrement/increment
nnoremap [oe <c-x>
nnoremap ]oe <c-a>
vnoremap [oe <c-x>
vnoremap ]oe <c-a>

" merge tool
nnoremap <leader>1 :diffget LOCAL<cr>
nnoremap <leader>2 :diffget BASE<cr>
nnoremap <leader>3 :diffget REMOTE<cr>

" plug updater
nnoremap <leader>pi :PlugInstall<cr>
nnoremap <leader>pc :PlugClean<cr>
nnoremap <leader>pd :PlugDiff<cr>
nnoremap <leader>pu :PlugUpgrade<cr>:PlugUpdate<cr>

" settings
syntax on
filetype plugin indent on
set rtp+=/usr/local/opt/fzf

set cole=0                              "concealing characters
set complete=.,t                        "keep tab complete within file
set concealcursor=nvic                  "conceal modes
set cursorline                          "highlight current cursor line
set encoding=utf-8                      "utf8 encoding
set fillchars=vert:\|,fold:-            "fill chars for status line
set hlsearch                            "highlight searches
set ignorecase                          "ignore case during search
set incsearch                           "do incremental searching
set laststatus=2                        "always display status line
set lazyredraw                          "redraw only when we need to.
set list listchars=tab:»·,trail:·       "tab and space chars (optional eol:¬)
set nocompatible                        "use vim over vi settings
set nofoldenable                        "disable code folding
set nomodeline                          "no modeline
set number                              "show current line
set numberwidth=4                       "number gutter width
set redrawtime=5000                     "syntax time applies per window
set relativenumber                      "use relative line numbers
set ruler                               "row and column info
set scrolloff=999                       "keep cursor at the center
set sessionoptions-=blank               "ignore blank buffer in sessions
set showcmd                             "display incomplete commands
set showmatch                           "jump to first match
set smartcase                           "search uppercase if given
set synmaxcol=250                       "prevent syntax on long lines
set t_ut=                               "screen refresh issue with Tmux
set textwidth=80                        "Text width 80 for formatting
set ttyfast                             "faster screen refresh(?)
set updatetime=100                      "update time

" tmp file settings
set noswapfile
set nobackup
set nowritebackup

" backup settings
set backup
set backupdir=/var/tmp,/tmp
set directory=/var/tmp,/tmp
set writebackup

" tmp directory
let s:tmpdir="/tmp/vim/"

" persistent undo
set undofile
let s:undodir=s:tmpdir . "undo"
execute "set undodir=" . s:undodir
if !isdirectory(s:undodir)
  silent call mkdir (s:undodir, 'p')
endif

" whitespace settings
set smarttab
set expandtab
set smartindent
set tabstop=2
set softtabstop=2
set shiftwidth=2
set shiftround
set nojoinspaces

" new split settings
set splitbelow
set splitright

" join wrapped paragraphs
nnoremap <leader>jp :call JoinParagraphs()<cr>
function! JoinParagraphs()
  let l:cursor = winsaveview()
  silent %s/\(\s*\S\s*\)\n\(\s*\S\s*\)/\1 \2/e
  silent %s/\v\s+/ /ge
  call winrestview(l:cursor)
endfunction

" workspace
let g:workspace_undodir = s:tmpdir . '.undodir'
let g:workspace_session_directory = s:tmpdir . 'sessions'
let g:workspace_session_disable_on_args = 1
let g:workspace_autocreate = 1
let g:workspace_autosave = 0
let g:workspace_autosave_ignore = ['gitcommit', 'Mundo', 'nerdtree', 'qf']

nnoremap <leader>ss :ToggleWorkspace<cr>
nnoremap <leader>sc :CloseHiddenBuffers<cr>

" ctrl-p
let g:ctrlp_show_hidden = 1
let g:ctrlp_match_window_reversed = 1
let g:ctrlp_switch_buffer = 1
let g:ctrlp_by_filename = 0
let g:ctrlp_clear_cache_on_exit = 1
let g:ctrlp_working_path_mode = 0
let g:ctrlp_lazy_update = 200

" tab completion
set wildmode=list:longest,list:full
set complete=.,w,t

" ripgrep
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
  let g:ctrlp_user_command = 'rg --files --hidden %s'
endif

" grepper
runtime plugin/grepper.vim

if exists('g:grepper')
  let g:grepper.tools = ['rg', 'git']
  let g:grepper.quickfix = 1
  let g:grepper.switch = 1
  let g:grepper.rg.grepprg .= ' --smart-case --hidden'
endif

nnoremap <c-\><c-\> :Grepper<cr>
nnoremap <leader>\ :Grepper -cword -noprompt<cr>

" todo
command! Todo Grepper -noprompt -tool rg -query -e '(TODO|FIXME|XXX|NOTE):'
nnoremap <leader>td :Todo<cr>

" git-gutter
let g:gitgutter_realtime = 1
let g:gitgutter_sign_modified = '#'
let g:gitgutter_sign_modified_removed = '_'

nnoremap <leader>gh :GitGutterLineHighlightsToggle<cr>

" nerd{tree|commenter}
let g:NERDTreeIgnore=['node_modules[[dir]]']
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeShowHidden = 1
let g:NERDSpaceDelims = 1

nnoremap <leader>o :NERDTreeToggle<cr><c-w>=
nnoremap <leader>i :NERDTreeFocus<cr><c-w>=
nnoremap <leader>ff :NERDTreeFind<cr><c-w>=

" fzf
let g:fzf_command_prefix = 'Fzf'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }
let g:fzf_layout = { 'down': '25%' }
let g:fzf_preview_window = ''

nnoremap <c-\><c-f> :FzfFiles<space>
nnoremap <c-\><c-o> :FzfFiles<cr>
nnoremap <c-\><c-i> :FzfBLines<cr>
nnoremap <c-\><c-r> :FzfRg<space>

" ale
let g:ale_linters_explicit = 0
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_delay = 1000

nnoremap yoa :ALEToggle<cr>

" goyo
let g:goyo_width = 120

nnoremap <leader>z :Goyo<cr>

function! s:EnterGoyo()
  ALEDisable
endfunction

function! s:LeaveGoyo()
  ALEEnable
endfunction

autocmd! User GoyoEnter nested call <SID>EnterGoyo()
autocmd! User GoyoLeave nested call <SID>LeaveGoyo()

" prettier
let g:prettier#onsave = 0
let g:prettier#autoformat = 0
let g:prettier#quickfix_enabled = 0
let g:prettier#config#config_precedence = 'prefer-file'

nnoremap <leader>pp :call ToggleAutoPrettier()<cr>
function! ToggleAutoPrettier(...)
  let l:filetypes = '*.js,*.jsx,*.json,*.ts,*.tsx,*.css,*.scss,*.graphql,*.md,*.mdx,*.yml,*.yaml'
  let l:autocmd = 'autocmd BufWritePre ' . l:filetypes . ' Prettier'

  if g:prettier#onsave
    let g:prettier#onsave = 0
    augroup AutoPrettier
      autocmd!
    augroup END
  else
    let g:prettier#onsave = 1
    augroup AutoPrettier
      autocmd!
      execute l:autocmd
    augroup END
  endif

  if trim(get(a:000, 0)) !=? "start"
    if g:prettier#onsave
      echo "prettier enabled"
    else
      echo "prettier disabled"
    endif
  endif
endfunction
call ToggleAutoPrettier('start')

" jq
nnoremap <leader>jj :set ft=json<cr>:%!jq .<cr>

" mundo
let g:mundo_right = 1
let g:mundo_width = 60
let g:mundo_preview_height = 20

nnoremap <leader>u :MundoToggle<cr>

" pear tree
let g:pear_tree_repeatable_expand = 0
let g:pear_tree_map_special_keys = 0

" dash
nmap <silent> <leader>d <Plug>DashSearch

" peekaboo
let g:peekaboo_window = "vertical botright 64new"

" projectionist
nnoremap <leader>aa :A<cr>
nnoremap <leader>as :AS<cr>
nnoremap <leader>av :AV<cr>

" vimux
nnoremap <leader>vp :VimuxPromptCommand<CR>
nnoremap <leader>vl :VimuxRunLastCommand<CR>
nnoremap <leader>vx :VimuxInterruptRunner<CR>

" set color depending on terminal color support
if $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal"
  set t_Co=256
endif

" use true color is avaialble
if has("termguicolors")
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" colorscheme
nnoremap <leader>` :call ToggleTheme()<cr>
function! ToggleTheme()
  let l:color = trim(execute(":color"))
  if l:color ==? "nord"
    execute "colorscheme embark"
    let g:airline_theme = "embark"
  else
    execute "colorscheme nord"
    let g:airline_theme = "nord"
  endif
endfunction

set background=dark
try
  colorscheme nord
catch
endtry

