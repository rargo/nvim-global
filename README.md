# nvim-global

nvim-global is a Neovim plugin that use GNU global to generate tags, find symbol definitions, find symbol reference.

In order to use nvim-global, you need to install GNU global software package first,
In Ubuntu or Debian system, use 'sudo apt-get install global'

Neovim has been cancel the support for cscope, despite there's treesitter and LSP, I still 
think global suits my work more.

### generate tag files in current directory

```
:GlobalGenerateTags
```

Generate tags in current directory, if tags already generated, global will update it incrementally

### list symbol definitions

```
:GlobalListDefinition
```

Select the symbol from telescope dialog, it will jump to the symbol definition file and location,
if multiple definitions found, a quickfix window will be shown under current buffer, you can select
specify definition in the quickfix window

### find symbol definitions

```
:GlobalFindDefinition <symbol>
```

Find symbol definitions, if multiple definitions found, a quickfix window will be shown

### find symbol reference

```
:GlobalFindReference <symbol>
```
Find symbol reference, if multiple references found, a quickfix window will be shown

### keymaping

You can map list symbol definitions to some key, below use key <F8>

```
vim.api.nvim_set_keymap('n', '<F8>', '<cmd>lua require("nvim-global").listdefinitions()<CR>')
```
