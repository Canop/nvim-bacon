" Bacon companion
" Last Change:  2022 Apr 01
" Maintainer:   Denys Séguret <dys@dystroy.org>
" License:      GNU General Public License v3.0

if exists('g:loaded_bacon') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

hi def link BaconHeader      Number
hi def link BaconSubHeader   Identifier
" hi WhidCursorLine ctermbg=238 cterm=none

command! BaconList lua require'bacon'.bacon_list()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_bacon = 1
