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
:GlobalGenerateTags
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

A telescope picker window will show up, select the symbol from telescope dialog,
It will jump to the symbol definition file and location,
if multiple definitions found, a quickfix window will be shown under current buffer, you can select
specify definition in the quickfix window

You can map list symbol definitions to some key, below use key \<F8\>

```
vim.api.nvim_set_keymap('n', '<F8>', '<cmd>GlobalListDefinitions<CR>', {noremap = true, silent = true})
```

### List symbol references

```
:GlobalListReferences
```

A telescope picker window will show up, select the symbol from telescope dialog,
It will jump to the symbol reference file and location,
if multiple references found, a quickfix window will be shown under current buffer, you can select
specify reference in the quickfix window

You can map list symbol references to some key, below use key \<C-F8\>

```
vim.api.nvim_set_keymap('n', '<C-F8>', '<cmd>GlobalListReferences<CR>', {noremap = true, silent = true})
```

### Find cursor word definition

```
:GlobalFindCwordDefinitions
```

Find the symbol definitions under cursor, if multiple definitions found, a quickfix window will be shown, 
You can map this to some key.

### Find cursor word references

```
:GlobalFindCwordReferences
```

Find the symbol references under cursor, if multiple references found, a quickfix window will be shown, 
You can map this to some key.

### List all symbol definitions

```
:GlobalListAllDefinitions
```

This command work like 'GlobalListDefinitions', with the only difference:
It will search for symbol definitions not only in current project but also in all tag file that add by 'GlobalAddPath'

### List all symbol reference

```
:GlobalListAllReferences
```

This command work like 'GlobalListReferences', with the only difference:
It will search for symbol references not only in current project but also in all tag file that add by 'GlobalAddPath'


