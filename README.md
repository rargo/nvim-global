# nvim-global

nvim-global is a Neovim plugin that use GNU global to generate tags, find symbol definitions, find symbol reference.

In order to use nvim-global, you need to install GNU global software package first,
In Ubuntu or Debian system, use 'sudo apt-get install global'

Neovim has been stop the support for cscope, despite there's treesitter and LSP, I still 
think global suits my work more.

### Generate tag files in current directory

```
:GlobalGenerateTags
```

Generate tags in current directory, if tags already generated, global will update it incrementally

### List all symbol definitions

```
:GlobalListDefinition
```

Select the symbol from telescope dialog, it will jump to the symbol definition file and location,
if multiple definitions found, a quickfix window will be shown under current buffer, you can select
specify definition in the quickfix window

You can map list symbol definitions to some key, below use key \<F8\>

```
vim.api.nvim_set_keymap('n', '<F8>', '<cmd>lua require("nvim-global").listdefinitions()<CR>', {noremap = true, silent = true})
```

### Find symbol definition

```
:GlobalFindDefinition <symbol>
```

Find symbol definitions, if multiple definitions found, a quickfix window will be shown

### Find cursor word definition

```
:GlobalFindCwordDefinition <symbol>
```

Find the symbol under cursor definitions, if multiple definitions found, a quickfix window will be shown, 
You can map this to some key.

### Find symbol reference

```
:GlobalFindReference <symbol>
```
Find symbol reference, if multiple references found, a quickfix window will be shown

