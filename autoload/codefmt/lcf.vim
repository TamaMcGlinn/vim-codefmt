" Copyright 2017 Google Inc. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.


let s:plugin = maktaba#plugin#Get('codefmt')


""
" @private
"
" Formatter provider for lua files using lcf.
function! codefmt#lcf#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'lcf',
      \ 'setup_instructions': 'Install lcf with luarocks. ' .
          \ '(https://github.com/martin-eden/lua_code_formatter).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('lcf_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return codefmt#formatterhelpers#FiletypeMatches(&filetype, 'lua')
  endfunction

  ""
  " Reformat the current buffer with lcf or the binary named in
  " @flag(lcf_executable)
  " @throws ShellError
  function l:formatter.Format() abort
    let l:cmd = [ s:plugin.Flag('lcf_executable')]
	" Specify we are sending input through stdin
    let l:cmd += ['-todo_add_option_to_pass_stdin!']

    try
      call codefmt#formatterhelpers#Format(l:cmd)
    catch
      " Parse all the errors and stick them in the quickfix list.
      let l:errors = []
      for line in split(v:exception, "\n")
        let l:fname_pattern = 'stdin'
        let l:tokens = matchlist(line,
            \ '\C\v^\[string "isCodeValid"\]:(\d+): (.*)')
        if !empty(l:tokens)
          call add(l:errors, {
              \ "filename": @%,
              \ "lnum": l:tokens[1],
              \ "text": l:tokens[2]})
        endif
      endfor

      if empty(l:errors)
        " Couldn't parse buildifier error format; display it all.
        call maktaba#error#Shout('Error formatting file: %s', v:exception)
      else
        call setqflist(l:errors, 'r')
        cc 1
      endif
    endtry
  endfunction

  return l:formatter
endfunction
