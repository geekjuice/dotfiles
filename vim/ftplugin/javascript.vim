" javascript

let b:ale_linter_aliases = ['javascript', 'css']
let b:ale_linters = ['eslint', 'stylelint']

nnoremap <leader>fn :call FindNamedImportUsage()<cr>
function! FindNamedImportUsage()
  let l:word = expand('<cword>')
  let l:file = expand('%:t:r')
  let l:path = l:file == 'index' ? expand('%:p:h:t') : l:file
  let l:import = '^import \{.+' . l:word . '.+\} from .+' . l:path . '.;?$'
  execute 'Grepper -noprompt -query "' . l:import . '"'
endfunction

nnoremap <leader>fd :call FindDefaultImportUsage()<cr>
function! FindDefaultImportUsage()
  let l:file = expand('%:t:r')
  let l:path = l:file == 'index' ? expand('%:p:h:t') : l:file
  let l:import = '^import .+ from .+' . l:path . '.;?$'
  execute 'Grepper -noprompt -query "' . l:import . '"'
endfunction

nnoremap <leader>ee :Esource<cr>
nnoremap <leader>et :Etest<cr>
nnoremap <leader>es :Estory<cr>

autocmd User ProjectionistDetect
  \ call projectionist#append(getcwd(), {
  \    '*.js': {
  \      'alternate': ['{}.test.js', '{}.stories.js']
  \    },
  \    '*.test.js': {
  \      'alternate': ['{}.stories.js', '{}.js']
  \    },
  \    '*.stories.js': {
  \      'alternate': ['{}.js', '{}.test.js']
  \    },
  \ })

nnoremap <leader>vta :call VimuxRunCommand("npm exec jest -- --bail")<CR>
nnoremap <leader>vwa :call VimuxRunCommand("npm exec jest -- --bail --watch")<CR>
nnoremap <leader>vtf :call VimuxRunCommand("npm exec jest -- --bail " . expand("%:r"))<CR>
nnoremap <leader>vwf :call VimuxRunCommand("npm exec jest -- --bail --watch " . expand("%:r"))<CR>
