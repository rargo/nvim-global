## ✨ Features

nvim-global is a Neovim plugin that uses [Telescope](https://github.com/nvim-telescope/telescope.nvim) and GNU global to list symbol definitions and references.

Supports multiple tag files. Useful for finding symbols defined in other projects, for example, in libraries, kernel header files.

To use nvim-global, you need to install the GNU global package first. In Ubuntu or Debian systems, use "sudo apt-get install global".

Neovim has stopped supporting cscope. Despite there are treesitter and LSP, global is still useful in some scenarios, like developing kernel drivers.

## ⚡️ Requirements

- GNU global software package installed
- Neovim has [Neovim telescope plugin](https://github.com/nvim-telescope/telescope.nvim) installed
- Install [Trouble](https://github.com/folke/trouble.nvim) if you want to use it as quickfix window
- Recommand install [telescope fzf](https://github.com/nvim-telescope/telescope-fzf-native.nvim) plugin for neovim, it will speed up select symbol a lot

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

### show project

```
:GlobalShowProjects
```

Use it to show projects information, project number will be shown

### remove project

```
:GlobalRemoveProject <project number>
```

Use it remove project that had been added by 'GlobalAddProject', use "GlobalRemoveProject all" to remove all projects,  
Note current project cannot be removed

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

action can be empty or the followings:

- current_project_definitions
- current_project_references
- other_project_definitions
- other_project_references
- all_project_references
- all_project_definitions
- current_project_definitions_smart
- other_project_definitions_smart

If <action> is empty, a Telescope selector window will be displayed, you will be further asked which action to be taken.

#### current_project_definitions

Find symbol definitions in current project, if multiple definitions are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, Only current project's definition symbols will be shown.

#### current_project_references

Find symbol references in current project, if multiple references are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, current project's all symbols will be shown.

#### other_project_definitions

Find symbol definitions in other project which add via `GlobalAddProject`, if multiple definitions are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, Only other project's definition symbols will be shown.

#### other_project_references

Find symbol references in other project which add via `GlobalAddProject`, if multiple references are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, other project's all symbols will be shown.

#### all_project_definitions

Find symbol definitions in all projects(current project and other project which add via `GlobalAddProject`), if multiple definitions are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, all projects definition symbols will be shown.

#### all_project_references

Find symbol references in all projects(current project and other project which add via `GlobalAddProject`), if multiple references are found, a quick fix window will be displayed under the current buffer.  
In the telescope preview window, all projects all symbols will be shown.

#### current_project_definitions_smart

In the telescope preview window, current project's all symbols will be shown,  
This finds definitions in the follow step until one of them successfully find symbols

- find symbol definitions in current projects
- find symbol definitions in other projects
- find symbol references in other projects

#### other_project_definitions_smart

In the telescope preview window, other project's all symbols will be shown,  
This finds definitions in the follow step until one of them successfully find symbols

- find symbol definitions in other projects
- find symbol references in other projects

### find cursor word definition in current project 

```
:GlobalFindCursorWordDefinitionCurrentProject
```

### find cursor word references in current project 

```
:GlobalFindCursorWordReferenceCurrentProject
```

### find cursor word definition in all projects

```
:GlobalFindCursorWordDefinitionAllProject
```

### find cursor word references in all projects

```
:GlobalFindCursorWordReferenceAllProject
```

### Find tags

```
GlobalTag <symbol>
```

It will find definitions in all project, works like 'Global all_project_definitions'

## 🛠️ Keymaping 

Default has no keymappings, you can map commands to some key.  

map key "F11" and "Ctrl-F11"  

```
-- map F11 to find definitions in current project smartly
vim.api.nvim_set_keymap('n', '<F11>', '<cmd>Global current_project_definitions_smart<CR>', {noremap = true, silent = true})
-- map C-F11 to find definitions in other project smartly
vim.api.nvim_set_keymap('n', '<C-F11>', '<cmd>Global other_project_definitions_smart<CR>', {noremap = true, silent = true})
-- map C-F11 to find definitions in other project smartly
-- for some laptop computer C-F11 keymap
vim.api.nvim_set_keymap('n', '<F35>', '<cmd>Global other_project_definitions_smart<CR>', {noremap = true, silent = true})
```

map key "\d", "\D", "\s", "\S"  

```
--map \d to find definitions in current project
vim.api.nvim_set_keymap('n', '\\d', '<cmd>GlobalFindCursorWordDefinitionCurrentProject<CR>', {noremap = true, silent = true})
--map \s to find references in current project
vim.api.nvim_set_keymap('n', '\\s', '<cmd>GlobalFindCursorWordReferenceCurrentProject<CR>', {noremap = true, silent = true})
--map \D to find definitions in all projects
vim.api.nvim_set_keymap('n', '\\D', '<cmd>GlobalFindCursorWordDefinitionAllProject<CR>', {noremap = true, silent = true})
--map \S to find references in all projects
vim.api.nvim_set_keymap('n', '\\S', '<cmd>GlobalFindCursorWordReferenceAllProject<CR>', {noremap = true, silent = true})
```

