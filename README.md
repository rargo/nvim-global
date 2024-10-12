## ✨ Features

nvim-global is a Neovim plugin that uses GNU global to generate tags, find symbol definitions, and find symbol references.

Supports multiple tag files. Useful for finding symbols defined in other projects, for example, in libraries, kernel header files.

To use nvim-global, you need to install the GNU global package first. In Ubuntu or Debian systems, use "sudo apt-get install global".

Neovim has stopped supporting cscope. Despite treesitter and LSP, I still prefer to use global in my work scenarios.

## ⚡️ Requirements

- GNU global software package installed
- Neovim has [Neovim telescope plugin](https://github.com/nvim-telescope/telescope.nvim) installed

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'rargo/nvim-global' }
```

### Setup

```lua
require("nvim-global").setup()
```

## 💻 Commands

### Generate tag files in current directory

```
:GlobalUpdateTags
```

Generate tags in current directory, if tags already generated, global will update it incrementally

### Add extra tag files

```
:GlobalAddPath <dir>
```

You can add more than one tag files, it's useful for find symbol definition that defined in other projects.

For example, when you developing kernel drivers, you can add kernel header path:
(below command is examples, the exact kernel header file path is base on your own system)

First generate tag file in the kernel headers directory
```
cd /usr/src/linux-headers-6.8.0-45-generic
sudo gtags
```

Then add it in Neovim
```
:GlobalAddPath /usr/src/linux-headers-6.8.0-40-generic
```
Now you can find function or macro definitions that defines in the kernel headers.

### List symbol definitions

```
:GlobalListDefinitions
```

A Telescope selector window will be displayed, select the symbol from the dialog,
it will jump to the symbol definition file and location,
if multiple definitions are found, a quick fix window will be displayed under the current buffer,
you can select a specific definition in the quick fix window

You can map list symbol definitions to some key, below use key \<F8\>

```
vim.api.nvim_set_keymap('n', '<F8>', '<cmd>GlobalListDefinitions<CR>', {noremap = true, silent = true})
```

### List symbol references

```
:GlobalListReferences
```

A Telescope selector window will be displayed, select the symbol from the dialog,
it will jump to the symbol reference file and location,
if multiple references are found, a quick fix window will be displayed under the current buffer,
you can select a specific reference in the quick fix window

You can map list symbol references to some key, below use key \<C-F8\>

```
vim.api.nvim_set_keymap('n', '<C-F8>', '<cmd>GlobalListReferences<CR>', {noremap = true, silent = true})
```

### Find cursor word definition

```
:GlobalFindCwordDefinitions
```

Finds the definition of the symbol under the cursor, if multiple definitions found, a quickfix window will be shown

### Find cursor word references

```
:GlobalFindCwordReferences
```

Finds the references of the symbol under the cursor, if multiple references found, a quickfix window will be shown

### List all symbol definitions

```
:GlobalListAllDefinitions
```

This command works just like "GlobalListDefinitions", the only difference is:  
it searches for symbol definitions not only in the current project, but also in all tag files added via "GlobalAddPath"

### List all symbol reference

```
:GlobalListAllReferences
```

This command works just like "GlobalListReferences", the only difference is:  
it searches for symbol references not only in the current project, but also in all tag files added via "GlobalAddPath"


