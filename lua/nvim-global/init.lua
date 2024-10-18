local sorters = require "telescope.sorters"
local state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

-- TODO
-- 1. global tags as completion resource

local M = {}

M.extra_paths = {}

M.default_options = {
  Trouble = false,
}

M.options = {}

local commands_tbl = {
  current_project_definitions_smart = 
    {
      desc = "smartly find definitions in current project",
      opt = {
        picker_prompt = "Smartly find **Definitions** in **Current** project",
        definitions = true,
        current_project = true,
        other_project = false,
        definition_smart = true,
      },
    },

  current_project_definitions = 
    {
      desc = "find definitions in current project",
      opt = {
        picker_prompt = "find **Definitions** in **Current** project",
        definitions = true,
        current_project = true,
        other_project = false,
      },
    },

  current_project_references = 
    {
      desc = "find references in current project",
      opt = {
        picker_prompt = "find **References** in **Current** project",
        definitions = false,
        current_project = true,
        other_project = false,
      },
    },

  other_project_definitions = 
    {
      desc = "find definitions in other project",
      opt = {
        picker_prompt = "find **Definitions** in **Other** projects",
        definitions = true,
        current_project = false,
        other_project = true,
      },
    },

  other_project_references = 
    {
      desc = "find references in other project",
      opt = {
        picker_prompt = "find **References** in **Other** projects",
        definitions = false,
        current_project = false,
        other_project = true,
      },
    },

  all_project_definitions = 
    {
      desc = "find definitions in all project",
      opt = {
        picker_prompt = "find **Definitions** in **All** projects",
        definitions = true,
        current_project = true,
        other_project = true,
      },
    },

  all_project_references = 
    {
      desc = "find references in all project",
      opt = {
        picker_prompt = "find **References** in **All** projects",
        definitions = false,
        current_project = true,
        other_project = true,
      },
    },
}

local function run_command(cmd)
  local handle = io.popen(cmd)
  local str = handle:read("*a")
  handle:close()

  return str
end

local function global_command_current_project(tbl, global_cmd)
  local str = run_command(global_cmd)
  local temp_tbl = vim.split(str, "\n")
  for _,v in ipairs(temp_tbl) do
    -- filter out dumplicate entrys
    if (tbl[v] == nil) then
      table.insert(tbl, v)
      tbl[v] = true
    end
  end

  return tbl
end

local function global_command_other_project(tbl, global_cmd)
  for _, path in ipairs(M.extra_paths) do
    local str = run_command(global_cmd .. " -C " .. path)
    if (str ~= "") then
      local temp_tbl = vim.split(str, "\n")
      for _,v in ipairs(temp_tbl) do
        -- filter out dumplicate entrys
        if (tbl[v] == nil) then
          table.insert(tbl, v)
          tbl[v] = true
        end
      end
    end
  end

  return tbl
end

local function check_executable()
  if (vim.fn.executable("global") == 0 or vim.fn.executable("gtags") == 0) then
    print("Error, global not found, please install it first!")
    return false
  end

  return true
end

local function format_select_qflist(qflist)
  local format_tbl = {}
  local preview_lines = 0
  for _, qf in ipairs(qflist) do
    for k, v in pairs(qf) do
      print("k: " .. k .. " v: " .. v)
    end
  end

  return format_tbl
end


local function global_qflist_current_project(qflist, global_cmd)
  local errorformat = vim.o.errorformat
  vim.o.errorformat="%f:%l:%m"

  vim.fn.setqflist({})
  vim.cmd("cclose")

  local cmd = "system(\"" .. global_cmd .. "\")"
  print("global_cmd:"  .. cmd)
  vim.cmd.cexpr(cmd)
  local tmp_qflist = vim.fn.getqflist()
  for _, t in ipairs(tmp_qflist) do
    table.insert(qflist, t)
  end

  vim.o.errorformat = errorformat

  return qflist
end

local function global_qflist_other_project(qflist, global_cmd)
  local errorformat = vim.o.errorformat
  vim.o.errorformat="%f:%l:%m"

  vim.cmd("cclose")

  for _, path in ipairs(M.extra_paths) do
    vim.fn.setqflist({})
    local cmd = "system(\"" .. global_cmd .. " -C " .. path .. "\")"
    print("global_cmd:"  .. cmd)
    vim.cmd.cexpr(cmd)
    local tmp_qflist = vim.fn.getqflist()
    if (#tmp_qflist ~= 0) then
      for _, t in ipairs(tmp_qflist) do
        table.insert(qflist, t)
      end
    end
  end

  vim.o.errorformat = errorformat

  return qflist
end

local function telescope_global_symbols(option)
  local cmd = ""
  local tbl = {}

  if (option.definitions == false) then
    -- find references
    if (option.current_project == true) then
      cmd = "global -c "
      global_command_current_project(tbl, cmd)

      cmd = "global -s -c "
      global_command_current_project(tbl, cmd)
    end

    if (option.other_project == true) then
      cmd = "global -c "
      global_command_other_project(tbl, cmd)

      cmd = "global -s -c "
      global_command_other_project(tbl, cmd)
    end

    return tbl
  else
    -- find definitions
    if (option.definition_smart == true) then
      cmd = "global -c "
      global_command_current_project(tbl, cmd)

      -- 如果有其他工程，则也列出本工程的其他符号，因为很可能在其他工程中找到
      if (#M.extra_paths > 0) then
        cmd = "global -s -c "
        global_command_current_project(tbl, cmd)
      end
      return tbl
    else
      if (option.current_project == true) then
        cmd = "global -c "
        global_command_current_project(tbl, cmd)
      end

      if (option.other_project == true) then
        cmd = "global -c "
        global_command_other_project(tbl, cmd)
      end
      return tbl
    end
  end
end

local function format_preview(t)
  local format_preview_tbl = {}
  local preview_lines = 0
  for _, line in ipairs(t) do
    local line_tbl = vim.split(line, ":")
    if (#line_tbl == 3) then
      -- line_tbl[3]: file location
      table.insert(format_preview_tbl, line_tbl[1] .. " " .. line_tbl[2] .. ":")
      table.insert(format_preview_tbl, "    " .. line_tbl[3])
      --print("table len:" .. #line_parts .. " " .. new_line)
      preview_lines = preview_lines + 1
      -- TODO confirm max preview_lines
      if (preview_lines >= 100) then
        return format_preview_tbl
      end
    end
  end

  return format_preview_tbl
end

local function telescope_global_preview(option, symbol)
  local cmd = ""
  local tbl = {}

  if (option.definitions == false) then
    -- find references
    if (option.current_project == true) then
      cmd = "global --result grep -s -xr " .. symbol
      global_command_current_project(tbl, cmd)
    end

    if (option.other_project == true) then
      cmd = "global --result grep -s -axr " .. symbol
      global_command_other_project(tbl, cmd)
    end

    return format_preview(tbl)
  else
    -- find definitions
    if (option.definition_smart == true) then
      -- find current_project definitions
      -- 先在当前的工程里查找定义
      cmd = "global --result grep -xd " .. symbol
      global_command_current_project(tbl, cmd)
      tbl = format_preview(tbl)
      if (#tbl > 0) then
        return tbl
      end

      -- 在其他的tag文件中查找定义
      cmd = "global --result grep -axd " .. symbol
      global_command_other_project(tbl, cmd)
      tbl = format_preview(tbl)
      if (#tbl > 0) then
        return tbl
      end

      -- 函数在头文件中的声明使用-xd不能查找出来，只能使用-s -xr找到，
      -- 所以需要再加上这里的查找
      cmd = "global --result grep -s -axr " .. symbol
      global_command_other_project(tbl, cmd)
      option.definitions_found = "reference_extra_paths"

      return format_preview(tbl)
    else
      if (option.current_project == true) then
        cmd = "global --result grep -axd " .. symbol
        global_command_current_project(tbl, cmd)
      end

      if (option.other_project == true) then
        cmd = "global --result grep -axd " .. symbol
        global_command_other_project(tbl, cmd)
      end
      return format_preview(tbl)
    end
  end
end

local function telescope_global_on_selection(option, symbol)
  local global_cmd = ""
  local qflist = {}
  if (option.definitions == false) then
    -- find references
    if (option.current_project == true) then
      cmd = "global --result grep -s -xr " .. symbol
      global_qflist_current_project(qflist, cmd)
    end

    if (option.other_project == true) then
      cmd = "global --result grep -s -axr " .. symbol
      global_qflist_other_project(qflist, cmd)
    end
  else
    -- find definitions
    if (option.definition_smart == true) then
      -- find current_project definitions
      -- 先在当前的工程里查找定义
      cmd = "global --result grep -xd " .. symbol
      global_qflist_current_project(qflist, cmd)
      if (#qflist > 0) then
        goto done
      end

      -- 在其他的tag文件中查找定义
      cmd = "global --result grep -axd " .. symbol
      global_qflist_other_project(qflist, cmd)
      if (#qflist > 0) then
        goto done
      end

      -- 函数在头文件中的声明使用-xd不能查找出来，只能使用-s -xr找到，
      -- 所以需要再加上这里的查找
      cmd = "global --result grep -s -axr " .. symbol
      global_qflist_other_project(qflist, cmd)
    else
      if (option.current_project == true) then
        cmd = "global --result grep -axd " .. symbol
        global_qflist_current_project(qflist, cmd)
      end

      if (option.other_project == true) then
        cmd = "global --result grep -axd " .. symbol
        global_qflist_other_project(qflist, cmd)
      end
    end
  end

::done::

  vim.fn.setqflist(qflist)

  if (#qflist >= 2) then
    if (M.options.Trouble == true and vim.fn.exists(":Trouble")) then
      vim.cmd("Trouble qflist")
    else
      vim.cmd("rightbelow cw")
      vim.cmd("cc! 1", { mods = { slient = true, emsg_silent = true }})
    end
  end
  vim.cmd("redraw!")
end

local function telescope_global_picker(option)
  if (check_executable() == false) then
    return
  end

  local pickers, finders, actions
  if pcall(require, "telescope") then
    pickers = require "telescope.pickers"
    finders = require "telescope.finders"
    actions = require "telescope.actions"
  else
    error "Cannot find telescope!"
  end

  -- local connections = require "remote-sshfs.connections"
  -- local hosts = connections.list_hosts()

  -- Build preivewer and set highlighting for each to "sshconfig"
  local previewer = previewers.new_buffer_previewer {
    define_preview = function(self, entry)
      local lines = telescope_global_preview(option, entry.value)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --require("telescope.previewers.utils").highlighter(self.state.bufnr, "sshconfig")
    end,
  }

  -- Build picker to run connect function when a host is selected
  pickers
    .new(_, {
      prompt_title = option.picker_prompt,
      previewer = previewer,
      finder = finders.new_table {
        results = telescope_global_symbols(option)
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = state.get_selected_entry()
          --print("selection is: " .. selection[1])
          -- find symbol definition
          telescope_global_on_selection(option, selection[1])
        end)
        return true
      end,
    })
    :find()
end

local function update_dir_gtags(dir)
  if (check_executable() == false) then
    return
  end

  print("generating new tags in dir " .. dir .. "...")
  run_command("cd " .. dir .. ";gtags")
  print("Done")
end

M.update_gtags = function()
  if (check_executable() == false) then
    return
  end

  local str = run_command("global -p")
  -- if no gtag files found, global -p will output error message to stderr, io.popen cannot capture it 
  -- so the str will be empty string
  if (str == "") then 
    print("generating new tags ...")
    run_command("gtags")
    print("Done")
  else
    print("updating exists tags ...")
    run_command("global -u")
    print("Done")
  end
end

M.show_projects = function()
  if (check_executable() == false) then
    return
  end

  local current_root = run_command("global --print root")
  local current_dbpath = run_command("global --print dbpath")
  print("Current project:")
  print("   " .. current_root)
  --print("   dbpath: " .. dbpath)

  if (#M.extra_paths > 0) then
    print("\n")
    print("Other projects:")
    for _, path in ipairs(M.extra_paths) do
      local root = run_command("global --print root -C " .. path)
      local dbpath = run_command("global --print dbpath -C " .. path)
      if (root ~= current_root) then
        print("   " .. path)
      end
      --print("   dbpath: " .. dbpath)
    end
  end
end

M.find_cword_definitions = function()
    local cword = vim.fn.expand("<cword>")
end

M.find_cword_references = function()
    local cword = vim.fn.expand("<cword>")
end

local function add_other_project_path(path)
  for _,v in ipairs(M.extra_paths) do
    if (v == path) then
      print("path: \"" .. path .. "\" already added")
      return
    end
  end

  table.insert(M.extra_paths, path)
  print("nvim-global: project \"" .. path .. "\" added")
end

M.add_other_project = function(path)
  if (check_executable() == false) then
    return
  end

  local current_root = run_command("global --print root")
  current_root = string.gsub(current_root, "\n", "")
  --print("@" .. current_root .. "@")

  local absolute_path = vim.fn.expand(path)

  if (current_root ~= "" and absolute_path == current_root) then
    print("project path " .. absolute_path .. " is current project")
    return
  end

  local tag_file = absolute_path .. "/GTAGS"
  if (vim.fn.filereadable(tag_file) == 0) then
    vim.ui.select({ 'y', 'n' }, {
      prompt = "Generate tag files in path " .. absolute_path .. "? (y/n)",
      format_item = function(item)
        return "" .. item
      end,
    }, function(choice)
        if (choice == 'y') then
          update_dir_gtags(absolute_path)
          if (vim.fn.filereadable(tag_file) == 1) then
            add_other_project_path(absolute_path)
          else
            print("Error, GTAGS file generate fail in path " .. absolute_path)
          end
        else
          print("Error, GTAGS file not found in \"" .. path .. "\". Please generate it first")
        end
      end)
  else
    add_other_project_path(absolute_path)
  end
end

M.add_kernel_header = function()
  local handle = io.popen("uname -r")
  local kernel_version = handle:read("*a")
  local kernel_header_path = "/usr/src/linux-headers-" .. kernel_version
  kernel_header_path = string.gsub(kernel_header_path, "%s","")
  kernel_header_path = string.gsub(kernel_header_path, "\n","")
  handle:close()

  M.add_other_project(kernel_header_path)
end

local function telescope_commands_preview(key)
  local tbl = {}
  for k, v in pairs(commands_tbl) do
    if (k == key) then
      table.insert(tbl, v.desc)
      return tbl
    end
  end

  return tbl
end

local function telescope_commands_select()
  local tbl = {}
  for k, v in pairs(commands_tbl) do
    table.insert(tbl, k)
  end

  return tbl
end

local function telescope_commands_on_selection(selection)
  for k, v in pairs(commands_tbl) do
    if (k == selection) then
      local option = v.opt
      telescope_global_picker(option)
      return
    end
  end
end

local function telescope_commands_picker(input)
  if (check_executable() == false) then
    return
  end

  if (input ~= nil and input.args ~= "") then
    for k, v in pairs(commands_tbl) do
      if (k == input.args) then
        telescope_global_picker(v.opt)
        return
      end
    end
    
    print("Invalid command:" .. input.args)
    return
  end

  local pickers, finders, actions
  if pcall(require, "telescope") then
    pickers = require "telescope.pickers"
    finders = require "telescope.finders"
    actions = require "telescope.actions"
  else
    error "Cannot find telescope!"
  end

  -- local connections = require "remote-sshfs.connections"
  -- local hosts = connections.list_hosts()

  -- Build preivewer and set highlighting for each to "sshconfig"
  local previewer = previewers.new_buffer_previewer {
    define_preview = function(self, entry)
      local lines = telescope_commands_preview(entry.value)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --require("telescope.previewers.utils").highlighter(self.state.bufnr, "sshconfig")
    end,
  }

  local _prompt_title = "select which ways"

  -- Build picker to run connect function when a host is selected
  pickers
    .new(_, {
      prompt_title = _prompt_title,
      previewer = previewer,
      finder = finders.new_table {
        results = telescope_commands_select()
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = state.get_selected_entry()
          --print("selection is: " .. selection[1])
          -- find symbol definition
          telescope_commands_on_selection(selection[1])
        end)
        return true
      end,
    })
    :find()
end

M.setup = function(options)
  M.options = vim.tbl_deep_extend("force", M.default_options, options or {})

  vim.api.nvim_create_user_command("GlobalAddProject", function(opt)
    M.add_other_project(opt.args)
  end, { nargs = 1, desc = "Add other project tag file", complete = "dir" })

  vim.api.nvim_create_user_command("GlobalAddKernelHeaders", function(opt)
    M.add_kernel_header(opt.args)
  end, { nargs = 0, desc = "Add kernel header files in /usr/src/linux-headers-`uname -r`"})

  vim.api.nvim_create_user_command("GlobalUpdateTags", function(opt)
    M.update_gtags()
  end, { nargs = 0, desc = "Update tags, if tags not exist, will generate tags" })

  vim.api.nvim_create_user_command("Global", function(input)
    telescope_commands_picker(input)
  end, { nargs = '?', desc = "Global" })

  -- vim.api.nvim_create_user_command("GlobalFindCwordDefinitions", function(opt)
  --   M.find_cword_definitions()
  -- end, { nargs = 0, desc = "Find cursor word definitions" })
  --
  -- vim.api.nvim_create_user_command("GlobalFindCwordReferences", function(opt)
  --   M.find_cword_references()
  -- end, { nargs = 0, desc = "Find cursor word references" })
  --
  vim.api.nvim_create_user_command("GlobalShowProjects", function(opt)
    M.show_projects(opt.args)
  end, { nargs = 0, desc = "Show tag info" })

end

return M
