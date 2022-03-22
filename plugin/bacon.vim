" Bacon companion - https://dystroy.org/bacon
" Last Change:  2022 Apr 01
" Maintainer:   Denys Séguret <dys@dystroy.org>
" License:      GNU General Public License v3.0

if exists('g:loaded_bacon') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo
set cpo&vim

hi def link BaconHeader      Number

command! BaconLoad lua require'bacon'.bacon_load()
command! BaconList lua require'bacon'.bacon_list()
command! BaconShow lua require'bacon'.bacon_show()
command! BaconNext lua require'bacon'.bacon_next()
command! BaconPrevious lua require'bacon'.bacon_previous()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_bacon = 1
