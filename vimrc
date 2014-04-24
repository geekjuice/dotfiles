"======================================
"   GLOBAL VARIABLES
"======================================
let g:vimtmp = "~/.dotfiles/vim/tmp/"


"======================================
"   PATHOGEN
"======================================
let g:pathogen_disabled=[]
execute pathogen#infect()
syntax on
filetype plugin indent on
set encoding=utf-8


"======================================
"   COLORSCHEME
"======================================
let g:molokai_original = 1
colorscheme molokai


"======================================
"   KEY MAPPINGS
"======================================
" Force <c-c> to behave exactly like <esc>
noremap <c-c> <esc>

" Leader Commands
let mapleader = " "

" Toggles
nnoremap <leader>p :set invpaste paste?<CR>
nnoremap <leader>h :nohlsearch<CR>

" Read/Write
nnoremap <leader>q <esc>:q
nnoremap <leader>w <esc>:w<CR>:echoe "File saved"<cr>
nnoremap <leader>s <esc>:mks!<cr>:echoe "Session saved"<cr>
nnoremap <leader>W :w !sudo tee > /dev/null %<cr>

" Splits
nnoremap <leader>n :vne<cr>
nnoremap <leader>m :sp<cr>
nnoremap <leader>w= <c-w>=

" Last buffer
nnoremap <leader>; <c-^><cr>

" Whitespace cleaner
nnoremap <leader><BS> mz:ret<cr>:%s/\v\s+$//g<cr>`z

" Tab Width Toggles
noremap <leader>2 :set ai et ts=2 sts=2 sw=2<cr>
noremap <leader>4 :set ai et ts=4 sts=4 sw=4<cr>

" Commands
nnoremap <leader>R @:<cr>
" Folding
nnoremap <leader><leader> za
vnoremap <leader><leader> zf

" Bracket jump
nnoremap <leader><tab> %
vnoremap <leader><tab> %

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Switch ctrl-movement keys to window switching
nmap <C-k> <C-w><Up>
nmap <C-j> <C-w><Down>
nmap <C-l> <C-w><Right>
nmap <C-h> <C-w><Left>


"======================================
"   SETTINGS
"======================================
set nocompatible                        "user vim over vi settings
set list listchars=tab:»·,trail:·       "tab and space chars (optional eol:¬)
set laststatus=2                        "always display status line
set fillchars=vert:\|,fold:-            "fill chars for status line
set t_ut=                               "screen refresh issue with Tmux
set ruler                               "row and column info
set numberwidth=4                       "number gutter width
set cursorline                          "highlight current cursor line
set incsearch                           "do incremental searching
set hlsearch                            "highlight searches
set showmatch                           "jump to first match
set ignorecase                          "ignore case during search
set smartcase                           "search uppercase if given
set scrolloff=999                       "keep cursor at the center
set showcmd                             "display incomplete commands
set complete=.,t                        "keep tab complete within file
set ttyfast                             "faster screen refresh(?)
set modelines=0                         "no modeline
set number                              "show current line
set relativenumber                      "use relative line numbers
set updatetime=750                      "update time

" Tmp file settings
set noswapfile
set nobackup
set nowritebackup

" Persistent Undo
set undofile
execute "set undodir=" . g:vimtmp . "vim_undo"

" Viminfo
execute "set viminfo+=n" . g:vimtmp . "viminfo"

" Tab settings
set smarttab
set expandtab
set smartindent
set tabstop=2
set softtabstop=2
set shiftwidth=2
set shiftround
set nojoinspaces

" New split settings
set splitbelow
set splitright


"======================================
"   PICOLINE
"======================================
let g:picoline_color = "default"        "Default colorscheme
let g:picoline_ctrlp = 1                "Use picoline theme for ctrlp
let g:picoline_limit = 80               "Color change on > 80 columns
let g:picoline_trunc = 0                "Truncate cols > 100
let g:picoline_nchar = 1                "Show cursor number (not char count)
let g:picoline_color = 1                "Colored modes

" Use less fancy for Chromebook or if fancy is false
if match(system('uname -i'), 'armv7l') >= 0
  let g:picoline_fsyms = [ "»", "«", "!!", "← " ]
elseif match(system('echo $FANCY_SYMBOLS'), 'false') >= 0
  let g:picoline_fancy = 0
endif


"======================================
"   CTRL-P
"======================================
" Settings
let g:ctrlp_show_hidden = 1             "Start with CtrlP not working dotfiles
let g:ctrlp_match_window_reversed = 1   "Show matched starting frm bottom
let g:ctrlp_switch_buffer = 0           "Open new instances regardless if open
let g:ctrlp_by_filename = 0             "Default filename search
let g:ctrlp_clear_cache_on_exit = 0     "Keep corss session cache
let g:ctrlp_working_path_mode = 0       "Don't set local dir on every invoke


"======================================
"   TAB COMPLETION
"======================================
inoremap <Tab> <c-r>=InsertTabWrapper()<cr>
set wildmode=list:longest,list:full
set complete=.,w,t
func! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction


"======================================
"   THE SILVER SEARCHER
"======================================
if executable('ag')
" Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor
" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
endif

let g:agprg = 'ag --column -i'


"======================================
"   TSLIME
"======================================
nmap <leader>rs <Plug>SetTmuxVars
nnoremap <leader>: :Tmux<space>


"======================================
"   VIM-SPEC
"======================================
" NOTE: Consider Different mappings for TSlime and no TSlime (same mapping?)
let g:rspec_command = 'call Send_to_Tmux("arspec {spec}\n")'
let g:mocha_coffee_command = 'call Send_to_Tmux("cortado {spec}\n")'
let g:mocha_js_command = 'call Send_to_Tmux("cortado {spec}\n")'

" Vim-spec mappings
nnoremap <leader>ta :call RunAllSpecs()<CR>
nnoremap <leader>tt :call RunCurrentSpecFile()<CR>
nnoremap <leader>ts :call RunNearestSpec()<CR>
nnoremap <leader>tl :call RunLastSpec()<CR>


"======================================
"   CTAGS/TAGBAR
"======================================
" Tagbar
let g:tagbar_autofocus = 1

" CoffeeTags
if executable('coffeetags')
  let g:tagbar_type_coffee = {
        \ 'ctagsbin' : 'coffeetags',
        \ 'ctagsargs' : '',
        \ 'kinds' : [
        \ 'f:functions',
        \ 'o:object',
        \ ],
        \ 'sro' : ".",
        \ 'kind2scope' : {
        \ 'f' : 'object',
        \ 'o' : 'object',
        \ }
        \ }
endif

" Index ctags and open tagbar
nnoremap <Leader>ct :!ctags -R .<CR>
nnoremap <leader>] :TagbarToggle<CR><c-w>=


"======================================
"   GIT-GUTTER
"======================================
let g:gitgutter_escape_grep = 1         "Use raw grep
let g:gitgutter_realtime = 1
let g:gitgutter_sign_modified = '#'
let g:gitgutter_sign_modified_removed = '_'

" Linehightlight Toggle
nnoremap <leader>g :GitGutterLineHighlightsToggle<cr>


"======================================
"   SYNTASTIC
"======================================
let g:syntastic_check_on_open=1         "Check on open
let g:syntastic_javascript_checkers = ['jsl']

" Syntastic Toggle
nnoremap <leader>e :SyntasticToggleMode<cr>


"======================================
"   NERD{TREE|COMMENTER}
"======================================
let NERDTreeQuitOnOpen = 1              "Closes NerdTree after open file
let NERDSpaceDelims = 1                 "Adds space between comments

" NERDtree toggle
nnoremap <leader>[ :NERDTreeToggle<CR><c-w>=


"======================================
"   GOYO
"======================================
let g:goyo_width = 100

" Goyo toggle
nnoremap <leader>z :Goyo<cr>

" Before/After callbacks
function! s:goyo_before()
  silent !tmux set status off
  set noshowmode
  set noshowcmd
endfunction

function! s:goyo_after()
  silent !tmux set status on
  set showmode
  set showcmd
endfunction

let g:goyo_callbacks = [ function('s:goyo_before'), function('s:goyo_after') ]


"======================================
"   SYNTAX/FILETYPE/HIGHLIGHT
"======================================
" Auto save last session on close
execute "autocmd VimLeave * mksession! " . g:vimtmp . "last-session.vim"

" Git
autocmd Filetype gitcommit setlocal spell textwidth=72

" Markdown
autocmd BufRead,BufNewFile *.md setlocal spell textwidth=80 filetype=markdown

" Shell
autocmd Filetype conf setlocal syntax=sh
autocmd Filetype conf,sh,zsh setlocal ai ts=4 sts=4 et sw=4

" HTML/Jade
autocmd BufRead,BufNewFile *.handlebars setlocal filetype=html

" Python
autocmd Filetype python setlocal ai ts=4 sts=4 et sw=4

" Ruby
autocmd BufRead,BufNewFile *.ru set filetype=ruby
autocmd BufRead,BufNewFile Gemfile* set filetype=ruby

" Set color depending on terminal color support
if $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal"
  set t_Co=256
endif
