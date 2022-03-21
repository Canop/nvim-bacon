# nvim-bacon

This plugin adds the `:BaconList` function which opens a floating window with the list of locations found in a `.bacon-locations` file.

This makes sense when this file is created by the [bacon](https://dystroy.org/bacon) program running in the same directory with `bacon -e`.

For a more convenient use, you should map the `:BaconList` function to an easily accessible key, for example with this line in your init.vim file:

```vimscript
nnoremap , :BaconList<CR>
```

Warnings:

* this is an unannounced early work in progress
* the `-e` option of bacon isn't in the main branch yet
