" vim-plug
call plug#begin('$HOME/.vim/plugged')

Plug 'airblade/vim-gitgutter'
Plug 'ambv/black', { 'do': ':BlackUpgrade' }
Plug 'christoomey/vim-tmux-navigator'
Plug 'cohama/lexima.vim'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'geekjuice/vim-studio'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'mhinz/vim-grepper'
" Plug 'neoclide/coc.nvim', { 'do': './install.sh nightly' }
Plug 'prettier/vim-prettier'
Plug 'rakr/vim-one'
Plug 'ryanoasis/vim-devicons'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'vim-airline/vim-airline'
Plug 'w0rp/ale'

call plug#end()

" vim-airline
let g:airline_theme = 'bubblegum'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tmuxline#enabled = 0
let g:airline#extensions#tabline#enabled = 0
let g:tmuxline_preset = 'powerline'

" force <c-c> to behave exactly like <esc>
noremap <c-c> <esc>

" colon -> semicolon
nnoremap ; :
vnoremap ; :

" leader commands
let mapleader = " "

" read/write
nnoremap <leader>q <esc>:q
nnoremap <leader>w <esc>:w<cr>:echo "File saved"<cr>
nnoremap <leader>W :w !sudo tee > /dev/null %<cr>

" splits
nnoremap <leader>n :vnew<cr>
nnoremap <leader>m :new<cr>
nnoremap <leader>w= <c-w>=

" tabs
nnoremap <leader>t :tabnew<cr>

" last buffer
nnoremap <leader>; <c-^><cr>

" whitespace cleaner
nnoremap <leader><BS> mz:ret<cr>:%s/\v\s+$//ge<cr>:echo "Whitespace cleaned"<cr>`z

" move visual blocks
vnoremap <c-j> :m '>+1<cr>gv=gv
vnoremap <c-k> :m '<-2<cr>gv=gv

" search visual selection
vnoremap * y/<C-R>"<CR>

" clipboard
vnoremap <leader>c "*y
nnoremap <leader>v "*p

" vimrc
nnoremap <silent> <leader>ve :e $MYVIMRC<cr>
nnoremap <silent> <leader>vs :so $MYVIMRC<cr>:echo "VIMRC reloaded"<cr>

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

" plug updater
nnoremap <leader>pi :PlugInstall<cr>
nnoremap <leader>pc :PlugClean<cr>
nnoremap <leader>pd :PlugDiff<cr>
nnoremap <leader>pu :PlugUpgrade<cr>:PlugUpdate<cr>

" settings
syntax on
filetype plugin indent on
set rtp+=/usr/share/fzf

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
set showcmd                             "display incomplete commands
set showmatch                           "jump to first match
set smartcase                           "search uppercase if given
set synmaxcol=100                       "prevent syntax on long lines
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

" tab settings
function! Tabline()
  let s = ''
  for i in range(tabpagenr('$'))
    let tab = i + 1
    let winnr = tabpagewinnr(tab)
    let buflist = tabpagebuflist(tab)
    let bufnr = buflist[winnr - 1]
    let bufname = bufname(bufnr)
    let bufmodified = getbufvar(bufnr, "&mod")
    let selected = tab == tabpagenr()

    let s .= '%' . tab . 'T'
    let s .= (selected ? '%#TabLineSel#' : '%#TabLine#')
    let s .= (selected ? '[ ' : ' ')
    let s .= tab .':'
    let s .= (bufname != '' ? fnamemodify(bufname, ':t') : 'No Name')
    let s .= (selected ? ' ] ' : ' ')

    if bufmodified
      let s .= '[+] '
    endif
  endfor

  let s .= '%#TabLineFill#'
  return s
endfunction
set tabline=%!Tabline()

" join wrapped paragraphs
nnoremap <leader>jp :call JoinParagraphs()<cr>
function! JoinParagraphs()
  let l:cursor = winsaveview()
  silent %s/\(\s*\S\s*\)\n\(\s*\S\s*\)/\1 \2/e
  silent %s/\v\s+/ /ge
  call winrestview(l:cursor)
endfunction

" sessions
nnoremap <leader>ss :SaveSession<space>
nnoremap <leader>so :LoadSession<space>
nnoremap <leader>sd :DeleteSession<space>
nnoremap <leader>sa :LastSession<cr>
nnoremap <leader>sx :ClearSessions<cr>
nnoremap <leader>sl :ListSessions<cr>

" ctrl-p
let g:ctrlp_show_hidden = 1             "start with ctrlp showing dotfiles
let g:ctrlp_match_window_reversed = 1   "show matched starting frm bottom
let g:ctrlp_switch_buffer = 0           "open new instances regardless if open
let g:ctrlp_by_filename = 0             "default filename search
let g:ctrlp_clear_cache_on_exit = 1     "keep cross session cache
let g:ctrlp_working_path_mode = 0       "don't set local dir on every invoke
let g:ctrlp_lazy_update = 200           "debounce search once typing has stopped

" tab completion
set wildmode=list:longest,list:full
set complete=.,w,t

inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
function! InsertTabWrapper()
  if pumvisible()
    return "\<c-n>"
  else
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
      return "\<tab>"
    else
      return coc#refresh()
    endif
  endif
endfunction

" rip grep
if executable('rg')
  set grepprg=rg\ --vimgrep\ --no-heading
  set grepformat=%f:%l:%c:%m,%f:%l:%m
  let g:ctrlp_user_command = 'rg --files --hidden %s'
endif

" grepper
runtime plugin/grepper.vim

let g:grepper.tools = ['rg', 'git']
let g:grepper.quickfix = 1
let g:grepper.switch = 1
let g:grepper.rg.grepprg .= ' --smart-case --hidden'

nnoremap <c-\><c-\> :Grepper<cr>
nnoremap <leader>\ :Grepper -cword -noprompt<cr>

" git-gutter
let g:gitgutter_realtime = 1
let g:gitgutter_sign_modified = '#'
let g:gitgutter_sign_modified_removed = '_'

nnoremap <leader>ht :GitGutterLineHighlightsToggle<cr>

" fugitive
nnoremap <leader>gs :Gstatus<cr>

" nerd{tree|commenter}
let NERDTreeIgnore=['node_modules[[dir]]']  "adds space between comments
let NERDTreeQuitOnOpen = 1                  "closes nerdtree after open file
let NERDTreeShowHidden = 1                  "show hidden files
let NERDSpaceDelims = 1                     "adds space between comments

nnoremap <leader>o :NERDTreeToggle<cr><c-w>=
nnoremap <leader>O :NERDTreeFocus<cr><c-w>=
nnoremap <leader>ff :NERDTreeFind<cr><c-w>=

" fzf
let g:fzf_command_prefix = 'Fzf'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }
let g:fzf_layout = { 'down': '20%' }

nnoremap <c-\><c-f> :FzfFiles<cr>
nnoremap <c-\><c-r> :FzfRg<space>

" ale
let g:ale_linters_explicit = 1
let g:ale_lint_on_text_changed = 'normal'
let g:ale_lint_delay = 250
let g:ale_linters = {
  \ 'javascript': [],
  \ 'typescript': [] }

nnoremap <leader>? :ALEResetBuffer<cr>:ALELint<cr>

" goyo
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
let g:prettier#autoformat = 0
let g:prettier#quickfix_enabled = 0

let g:prettier#config#print_width = 80
let g:prettier#config#tab_width = 2
let g:prettier#config#use_tabs = 'false'
let g:prettier#config#semi = 'true'
let g:prettier#config#single_quote = 'true'
let g:prettier#config#bracket_spacing = 'true'
let g:prettier#config#jsx_bracket_same_line = 'false'
let g:prettier#config#arrow_parens = 'avoid'
let g:prettier#config#trailing_comma = 'es5'
let g:prettier#config#parser = 'babylon'

nnoremap <leader>pp :call ToggleAutoPrettier()<cr>
function! ToggleAutoPrettier(...)
  let l:filetypes = '*.js,*.json,*.ts,*.tsx,*.css,*.scss,*.graphql,*.md'
  let l:autocmd = 'autocmd BufWritePre ' . l:filetypes . ' Prettier'
  if a:0 > 0
    if a:000[0]
      let g:prettier#onsave = 1
      augroup AutoPrettier
        autocmd!
        execute l:autocmd
      augroup END
    else
      let g:prettier#onsave = 0
        augroup AutoPrettier
          autocmd!
        augroup END
    endif
  else
    if !exists("g:prettier#onsave")
      let g:prettier#onsave = 1
      augroup AutoPrettier
        autocmd!
        execute l:autocmd
      augroup END
    else
      if g:prettier#onsave
        let g:prettier#onsave = 0
        echo "prettier disabled"
        augroup AutoPrettier
          autocmd!
        augroup END
      else
        let g:prettier#onsave = 1
        echo "prettier enabled"
        augroup AutoPrettier
          autocmd!
          execute l:autocmd
        augroup END
      endif
    endif
  endif
endfunction
call ToggleAutoPrettier(1)

" coc.nvim
let g:coc_global_extensions = [
  \ 'coc-eslint',
  \ 'coc-json',
  \ 'coc-python',
  \ 'coc-marketplace',
  \ 'coc-tsserver'
  \ ]

nmap <silent> <leader>dd <Plug>(coc-definition)
nmap <silent> <leader>dr <Plug>(coc-references)
nmap <silent> <leader>dj <Plug>(coc-implementation)

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
set background=dark
try
  colorscheme one
catch
endtry

