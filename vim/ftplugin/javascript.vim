" javascript

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

