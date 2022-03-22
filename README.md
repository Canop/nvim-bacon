# nvim-bacon

This plugin enable viewing the locations found in a `.bacon-locations` file, and jumping to them.

This makes sense when this file is created by [bacon](https://dystroy.org/bacon) with `-e` option running in nvim's work directory or in a parent directory.

## Warnings:

* this is an unannounced early work in progress
* the `-e` option of bacon isn't in the main branch yet

## API:

The following functions are exposed by the plugin:

|Function|Usage|
|-|-|
|`:BaconLoad`| Silently load the locations of the `.bacon-locations` file|
|`:BaconShow`| Display the locations in a floating windoaw|
|`:BaconList`| Does `:BaconLoad` then `:BaconShow`|
|`:BaconPrevious`| Jump to the previous location in the current list |
|`:BaconNext`| Jump to the next location in the current list |

## Usage

You'll use this plugin in nvim while a bacon instance is running in another panel, probably side to it.


You probably want to define at least two shortcuts, for example like this:

```vimscript
nnoremap , :BaconList<CR>
nnoremap ! :BaconLoad<CR>:w<CR>:BaconNext<CR>
```

The first shorctut, which is mapped to the <kbd>,</kbd> key, opens the list of all bacon locations.

The second one navigates from location to location, without opening the window. You may notice it loads the list (`:BaconLoad`) then saves the current document (`:w`), to prevent both race conditions and having a bunch of unsaved buffers.

You may define other shortcuts using the various API functions.
