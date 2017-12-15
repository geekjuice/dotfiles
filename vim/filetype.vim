" filetype

if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  autocmd BufRead,BufNewFile .env* setfiletype sh
augroup END
