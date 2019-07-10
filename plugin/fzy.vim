"=============================================================================
" Plugin: fzy.nvim
" Author: Sinésio Neto (sinetoami) <https://github.com/sinetoami>
" Version: 0.0.1 - 2019 Jul 10
" License: MIT license
" Description: Fzy integrated with Neovim.
"=============================================================================
" TODO:
" - enhance fzy layout settings: *left* and *right* options
" - allow `:Fzy` to use `!` for fullscreen layout
" - fzy statusline customizable
" - multi files selection like :FZF with `TAB`
"
" FIXME:
" - line 304: find a better way to generate the number of lines to fzy command
" - line 319: 's:define_lines()+5' don't get a number to satisfy layout '~100%'
"
" QUESTION:
" - line 162: has_key(file, 'lnum') case is it really necessary?
" - line 189: see TODO in line 8 too
" ----------------------------------------------------------------------------------
if exists('g:loaded_fzy') || &cp || !has('nvim')
  finish
endif
let g:loaded_fzy = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists("g:fzy_layout")
  let g:fzy_layout = { 'below': '~40%' } " { 'orientation': 'size in percent' }
endif

function! s:fcall(fn, ...)
  return call(a:fn, a:000)
endfunction

function! s:wrap_cmds(cmds)
  return a:cmds
endfunction

function! s:shellescape(arg, ...)
  return s:fcall('shellescape', a:arg)
endfunction

function! s:evaluate_options(options)
  return type(a:options) == type([]) ?
        \ join(map(copy(a:options), 's:shellescape(v:val)')) : a:options
endfunction

"" SOURCE WRAPPER: START -----------------------------------------------------------
let s:source = { 
\ 'path': 'rg', 
\ 'ignores': ['*.git'], 
\ 'options': [ 
\ '--files', '--hidden', '--smart-case',
\ '--color=never', '--fixed-strings' 
\ ] }

function! s:source.sub(dict) dict
  for gkey in keys(a:dict)
    if has_key(self, gkey)
      let self[gkey] = a:dict[gkey]
    endif
  endfor
endfunction

function! s:source.join() dict
  return type(self.options) == type([]) ? join(self.options, ' ') : self.options
endfunction

function! s:source.iadd(str) dict
  let ignores = []
  for item in self.ignores
    call add(ignores, printf(a:str, item))
  endfor
  return ignores
endfunction

let s:ag = {}
function! s:ag.find() dict
  let ignores = self.iadd('--ignore %s')
  return self.path . ' -g "" ' .  self.join() . ' ' . join(ignores, ' ')
endfunction

let s:rg = {}
function! s:rg.find() dict
  let ignores = self.iadd('--glob "!%s"')
  return self.path . ' ' . self.join() . ' ' . join(ignores, ' ')
endfunction

if exists("g:fzy_default_command")
  call s:source.sub(g:fzy_default_command)
endif

let s:source.find = funcref('s:'.s:source.path.'.find')
"" SOURCE WRAPPER: END -------------------------------------------------------------

"" EXECUTE TERMINAL: START ---------------------------------------------------------
function! s:define_size(max, val)
  let val = substitute(a:val, '^\~', '', '')
  if val =~ '%$'
    let size = a:max * str2nr(val[:-2]) / 100
  else
    let size = min([a:max, str2nr(val)])
  endif
 
  return size
endfunction

function! s:compose_window(dict)
  let directions = {
  \ 'above': ['topleft', 'resize', &lines],
  \ 'below': ['botright', 'resize', &lines]
  \}
 
  for [dirc, items] in items(directions)
    let val = get(a:dict, dirc, '')
    if !empty(val)
      let [cmd, resz, max] = items
      if (dirc == 'above' || dirc == 'below') && val[0] == '~'
        let size = s:define_size(max, val)
      endif
      return [cmd, size]
    endif
  endfor
endfunction

let s:job_id = 0
let s:vim_command = ''
let s:default_action = {
  \ 'vsplit': 'vsplit',
  \ 'split': 'split',
  \ 'tab': 'tabe'
  \ }

function! s:execute_split(action)
  let cmd = get(s:default_action, a:action, '')
  if !empty(cmd)
    let s:vim_command = cmd
    call chansend(s:job_id, "\r\n")
  endif
endfunction

function! s:execute_terminal(dict, command, temps) abort
  let fzy = { 'window_id': win_getid(), 'dict': a:dict, 'command': a:command, 
        \ 'temps': a:temps }
  
  function! fzy.on_exit(job_id, data, event)
    bdelete!
    call win_gotoid(self.window_id)
    let results = readfile(self.temps.result)
    if !empty(results)
      try
        for result in results
          let file = self.dict.handler([result])
          execute 'lcd' self.dict.path

          if empty(s:vim_command)
            let s:vim_command = 'edit'
          endif
          silent execute s:vim_command . ' ' . fnameescape(expand(file.name))

          "" QUESTION: this case is really necessary?
          if has_key(file, 'lnum')
            silent execute file.lnum
            normal! zz
          endif
          ""
        endfor
      finally
        lcd -
      endtry
    endif
  endfunction
  let [cmd, size] = s:compose_window(fzy.dict)
  execute cmd size . 'new'

  try
    execute 'lcd' fzy.dict.path
    let command = a:command
    if has('nvim')
      let s:vim_command = ''
      let s:job_id = termopen(command, fzy)
    endif
  finally
    lcd -
  endtry
 
  "" QUESTION: It's possible to put this 'fzy_statusline' out of this function?
  "" Try TODO something.
  augroup fzy_statusline
    highlight default fzy1 cterm=bold ctermfg=234 ctermbg=green gui=bold guifg=#19181a guibg=#A9dc76
    highlight default fzy2 cterm=bold ctermfg=234 ctermbg=green gui=bold guifg=#19181a guibg=#a9dc76
    highlight default fzy3 ctermfg=252 ctermbg=238 guifg=#ffe48f guibg=#19181a

    autocmd! FileType fzy
    autocmd  FileType fzy setlocal statusline=%#fzy1#\ >\./\ %#fzy2#fzy%#fzy2#\ %#fzy3#
  augroup END
  ""

  setlocal nospell nobuflisted bufhidden=wipe nonumber norelativenumber
  setfiletype fzy
  startinsert
  " return
endfunction
"" EXECUTE TERMINAL: END -----------------------------------------------------------

"" COMPOSE COMMAND: START ----------------------------------------------------------
function! s:fzy(...)
  let dict = exists('a:1')? a:1 : {}
  let temps = { 'result': tempname() }
  let optstr = s:evaluate_options(get(dict, 'options', '')) 

  if !has_key(dict, 'path')
    let dict.path = getcwd()
  endif

  if has('win32unix') && has_key(dict, 'path')
    let dict.path = fnamemodify(dict.path, ':p')  
  endif

  if !has_key(dict, 'source') && !empty(s:source)
    let temps.source = tempname()
    call writefile(s:wrap_cmds(split(s:source.find(), "\n")), temps.source)
    let dict.source = (empty($SHELL) ? &shell : $SHELL) . ' ' . s:shellescape(temps.source)
  endif

  if has_key(dict, 'source')
    let source = dict.source
    let type = type(source)
    if type == 1
      let prefix = '( '.source.' ) | '
    elseif type == 3
      let temps.input = tempname()
      call writefile(source, temps.input)
      let prefix = 'cat '.s:shellescape(temps.input).' | '
    else
      throw 'Invalid source type'
    endif
  else
    let prefix = ''
  endif
  let command = prefix.'fzy '.optstr.' > '.temps.result

  function! dict.handler(result)
    return { 'name': join(a:result) }
  endfunction

  " echo dict command temps readfile(temps.source)
  return s:execute_terminal(dict, command, temps)
endfunction
"" COMPOSE COMMAND: END ------------------------------------------------------------

let s:layout_keys = ['above', 'below']
let s:default_layout = { 'below': '~40%' }

function! s:has_any(dict, keys)
  for key in a:keys
    if has_key(a:dict, key)
      return 1
    endif
  endfor
  return 0
endfunction

function! s:validate_layout(layout)
  for key in keys(a:layout)
    if index(s:layout_keys, key) < 0
      throw printf('Invalid entry in g:fzy_layout: %s (allowed: %s)%s',
            \ key, join(s:layout_keys, ', '), 
            \ key == 'options' ? '. Use g:fzy_default_command.' : '')
    endif
  endfor
  return a:layout
endfunction

function! s:wrap(...)
  let args = [{}]
  let expects = map(copy(args), 'type(v:val)')
  let tidx = 0
  for arg in copy(a:000)
    let tidx = index(expects, type(arg), tidx)
    if tidx < 0
      throw 'Invalid arguments (expected: [opts dict] [fullscreen boolean])'
    endif
    let args[tidx] = arg
    let tidx += 1
    unlet arg
  endfor
  let [opts] = args
 
  if !s:has_any(opts, s:layout_keys)
    let opts = extend(opts, 
          \ s:validate_layout(get(g:, 'fzy_layout', s:default_layout))
          \ )
  endif

  return opts
endfunction

function! s:shortpath()
  let short = fnamemodify(getcwd(), ':~:.')
  let short = pathshorten(short)
  let slash = '/'
  return empty(short) ? '~'.slash : short 
        \ . (short =~ escape(slash, '\').'$' ? '' : slash)
endfunction

"" FIX: try to do something better than this to generate a number of lines
"" to pass to fzy command
function! s:define_lines()
  for key in s:layout_keys
    if has_key(s:default_layout, key)
      return s:define_size(&lines, s:default_layout[key])
    endif
  endfor
endfunction
""

function! s:cmd(...) abort  
  let args = copy(a:000)
 
  "" FIX: s:define_lines()+5 don't get a number 
  "" which satisfy fzy_layout equals '~100%'
  let opts = { 'options': ['--lines', s:define_lines()+5] }
  ""

  if len(args) && isdirectory(expand(args[-1]))
    let opts.path = substitute(substitute(remove(args, -1), 
          \ '\\\(["'']\)', '\1', 'g'), '[/\\]*$', '/', '')
    let prompt = opts.path
  else
    let prompt = s:shortpath()
  endif 
  let prompt = strwidth(prompt) < &columns - 20 ? prompt : '> '

  call extend(opts.options, args)
  call extend(opts.options, ['--prompt', prompt])
 
  " echo opts
  call s:fzy(s:wrap(opts))
endfunction

command! -nargs=* -complete=dir Fzy call s:cmd(<f-args>)
autocmd FileType fzy tnoremap <silent> <buffer> <C-T> <C-\><C-n>:call <sid>execute_split('tab')<cr>
autocmd FileType fzy tnoremap <silent> <buffer> <C-X> <C-\><C-n>:call <sid>execute_split('split')<cr>
autocmd FileType fzy tnoremap <silent> <buffer> <C-V> <C-\><C-n>:call <sid>execute_split('vsplit')<cr>

let &cpo = s:cpo_save
unlet s:cpo_save
