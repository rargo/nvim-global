## ✨ Features

nvim-global is a Neovim plugin that uses [Telescope](https://github.com/nvim-telescope/telescope.nvim) and GNU global to list symbol definitions and references.

Supports multiple tag files. Useful for finding symbols defined in other projects, for example, in libraries, kernel header files.

To use nvim-global, you need to install the GNU global package first. In Ubuntu or Debian systems, use "sudo apt-get install global".

Neovim has stopped supporting cscope. Despite there are treesitter and LSP, global is still useful in some scenarios, like developing kernel drivers.

## ⚡️ Requirements

- GNU global software package installed
- Neovim has [Neovim telescope plugin](https://github.com/nvim-telescope/telescope.nvim) installed
- Install [Trouble](https://github.com/folke/trouble.nvim) if you want to use it as quickfix window

## 📦 Installation

Install the plugin with your preferred package manager:

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'rargo/nvim-global' }
```

### Setup

Use default quickfix window

```lua
require("nvim-global").setup()
```

Use [Trouble](https://github.com/folke/trouble.nvim) as quickfix window, you need to install Trouble first

```lua
require("nvim-global").setup({ Trouble = true })
```

## 💻 Commands

### Update tag files in current project

```
:GlobalUpdateTags
```

Update tags in current project, if tags already generated, global will update it incrementally.
If tag files not exist, will call gtags to generate tag files


### Add other project

```
:GlobalAddProject <project directory>
```

Use it to add other projects like header files, library source.
it's useful for find symbols that defined in other projects.

If tag files not exist for that project, you will be prompt if want to generate it in that \<project directory\> 

### Add kernel headers

```
:GlobalAddKernelHeaders
```

If you have already generate tags file in the kernel header directory("/usr/src/linux-headers-\`uname -r\`), you can use this command to add the kernel header files directly.
Note you need root privilege to generate tag files for the kernel header directory


### Show all projects

```
:GlobalShowProjects
```

It will show path information for all the projects

### List symbols

```
Global <action>
```

action can be empty or one of the following:

- current_project_definitions
- current_project_references
- other_project_definitions
- other_project_references
- all_project_references
- all_project_definitions
- current_project_definitions_smart

If <action> is empty, a Telescope selector window will be displayed, you will be further asked which action to be taken.

#### current_project_definitions

Find symbol definitions in current project, if multiple definitions are found, a quick fix window will be displayed under the current buffer.

#### current_project_references

Find symbol references in current project, if multiple references are found, a quick fix window will be displayed under the current buffer.

#### other_project_definitions

Find symbol definitions in other project which add via `GlobalAddProject`, if multiple definitions are found, a quick fix window will be displayed under the current buffer.

#### other_project_references

Find symbol references in other project which add via `GlobalAddProject`, if multiple references are found, a quick fix window will be displayed under the current buffer.

#### all_project_definitions

Find symbol definitions in all projects(current project and other project which add via `GlobalAddProject`), if multiple definitions are found, a quick fix window will be displayed under the current buffer.

#### all_project_references

Find symbol references in all projects(current project and other project which add via `GlobalAddProject`), if multiple references are found, a quick fix window will be displayed under the current buffer.

#### current_project_definitions_smart

This finds definitions in the follow step until one of them successfully find symbols

- find symbol definitions in current projects
- find symbol definitions in other projects
- find symbol references in other projects

This behavior is because global doesn't treate function declaration as symbols definition

## Keymaping 🛠️

Default has no keymappings, you can map commands to some key, below use key "F8" and "Ctrl-F8"

```
vim.api.nvim_set_keymap('n', '<F8>', '<cmd>Global current_project_definitions_smart<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-F8>', '<cmd>Global<CR>', {noremap = true, silent = true})
```

