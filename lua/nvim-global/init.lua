local sorters = require "telescope.sorters"
local state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

-- TODO
-- 1. global tags as completion resource

local M = {}

M.extra_paths = {}

local function run_command(cmd)
  local handle = io.popen(cmd)
  local str = handle:read("*a")
  handle:close()

  return str
end

local function global_command(global_cmd)
  local str = run_command(global_cmd)
  local tbl = vim.split(str, "\n")

  return tbl
end

local function global_command_extra_paths(tbl, global_cmd)
  for _, path in ipairs(M.extra_paths) do
    local str = run_command(global_cmd .. " -C " .. path)
    if (str ~= "") then
      local temp_tbl = vim.split(str, "\n")
      for _,v in ipairs(temp_tbl) do
        table.insert(tbl, v)
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

-- stop_if_current_project_found only has to be pass when both current_project and extra_paths are true
-- TODO, errorformat how to match:
-- usleep_range      230 /home/ye/mf/v2/kmd_for_sim_test/src/moffett/src/model_test.c  usleep_range(9 * 1000, 11 * 1000);
local function global_execute_quickfix(global_cmd, current_project, extra_paths, stop_if_current_project_found)
  local qflist = {}
  local errorformat = vim.o.errorformat
  -- NOTE at least two space between %.%# and %l
  -- I don't know if someday will print one space
  vim.o.errorformat="%.%#  %l %f %m"
  vim.cmd("cclose")

  if (current_project == true) then
    vim.fn.setqflist({})
    local cmd = "system(\"" .. global_cmd .. "\")"
    print("global_cmd:"  .. cmd)
    vim.cmd.cexpr(cmd)
    local tmp_qflist = vim.fn.getqflist()
    for _, t in ipairs(tmp_qflist) do
      table.insert(qflist, t)
    end

    --format_select_qflist(qflist)

    if (extra_paths == false) then
      goto done
    end

    if (#qflist > 0 and stop_if_current_project_found == true) then
      goto done
    end
  end


  if (extra_paths == true) then
    for _, path in ipairs(M.extra_paths) do
      vim.fn.setqflist({})
      local cmd = "system(\"" .. global_cmd .. " -C " .. path .. "\")"
      print("global_cmd:"  .. cmd)
      vim.cmd.cexpr(cmd)
      vim.o.errorformat = errorformat
      local tmp_qflist = vim.fn.getqflist()
      if (#tmp_qflist ~= 0) then
        for _, t in ipairs(tmp_qflist) do
          table.insert(qflist, t)
        end
      end
    end
  end

::done::

  if (#qflist == 0) then
    return
  end

  vim.fn.setqflist(qflist)

  if (#qflist >= 2) then
    vim.cmd("rightbelow cw")
    vim.cmd("cc! 1", { mods = { slient = true, emsg_silent = true }})
  end
  vim.cmd("redraw!")

  --restore errorformat
  vim.o.errorformat = errorformat
end


local function find_definition(symbol, extra_paths, stop_if_current_project_found)
  local global_cmd = "global -axd " .. symbol
  global_execute_quickfix(global_cmd, extra_paths, stop_if_current_project_found)
end

local function find_reference(symbol, extra_paths, stop_if_current_project_found)
  local global_cmd = "global -s -axr " .. symbol
  global_execute_quickfix(global_cmd, extra_paths, stop_if_current_project_found)
end

local function telescope_symbols(option)
  local symbols
  local str
  local cmd = ""

  cmd = "global -c"
  str = run_command(cmd)
  symbols = vim.split(str, "\n")

  if (option.definition == false or #M.extra_paths > 0) then
    --下面的情况下列出当前工程的其他symbol:
    --1. 查找references
    --2. 查找definition但有其他tag被加入了,因为这种情况很可能是用户想从其他文件查找当前工程没有的定义
    cmd = "global -s -c"
    str = run_command(cmd)
    local t = vim.split(str, "\n")
    for _, v in ipairs(t) do
      table.insert(symbols, v)
    end
  end

  if (option.current_project == true) then
    return symbols
  end

  for _, path in ipairs(M.extra_paths) do
    cmd = "global -c -C " .. path
    str = run_command(cmd)
    local t = vim.split(str, "\n")
    for _, v in ipairs(t) do
      table.insert(symbols, v)
    end

    cmd = "global -s -c -C " .. path
    str = run_command(cmd)
    local t = vim.split(str, "\n")
    for _, v in ipairs(t) do
      table.insert(symbols, v)
    end
  end

  return symbols
end

local function format_preview(t)
  local format_preview_tbl = {}
  local preview_lines = 0
  for _, line in ipairs(t) do
    local line_tbl = vim.split(line, "%s+")
    if (#line_tbl >= 3) then
      -- line_tbl[3]: file location
      table.insert(format_preview_tbl, line_tbl[3] .. ":")
      local source_code = table.concat(line_tbl, " ", 4)
      source_code = "    " .. source_code
      table.insert(format_preview_tbl, source_code)
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

-- 查找函数定义
-- 从当前工程查找定义，如果找到则返回
-- 从其他的tag查找定义，如果找到则返回
-- 从其他的tag查找引用，返回
--
-- 查找引用
-- 从当前工程查找引用, 返回
local function telescope_preview(option, symbol)
  local cmd = ""

  if (option.definition == false) then
    -- find references
    cmd = "global -s -xr " .. symbol
    local tbl = global_command(cmd)

    if (option.current_project == false) then
      cmd = "global -s -axr " .. symbol
      global_command_extra_paths(tbl, cmd)
    end

    return format_preview(tbl)
  else
    if (option.current_project == true) then
      -- find current_project definitions
      -- 先在当前的工程里查找定义
      cmd = "global -xd " .. symbol
      local tbl = global_command(cmd)
      tbl = format_preview(tbl)
      if (#tbl > 0) then
        option.definitions_found = "definiton_current_project"
        return tbl
      end

      -- 在其他的tag文件中查找定义
      cmd = "global -axd " .. symbol
      global_command_extra_paths(tbl, cmd)
      tbl = format_preview(tbl)
      if (#tbl > 0) then
        option.definitions_found = "definiton_extra_paths"
        return tbl
      end

      -- 函数在头文件中的声明使用-xd不能查找出来，只能使用-s -xr找到，
      -- 所以需要再加上这里的查找
      cmd = "global -s -axr " .. symbol
      global_command_extra_paths(tbl, cmd)
      option.definitions_found = "reference_extra_paths"

      return format_preview(tbl)
    else
      -- find all definitions
      cmd = "global -axd " .. symbol
      local tbl = global_command(cmd)
      global_command_extra_paths(tbl, cmd)

      return format_preview(tbl)
    end
  end
end

local function telescope_on_selection(option, symbol)
  local global_cmd = ""
  if (option.definition == true) then
    if (option.current_project == true) then 
      print("@@@@@@@ " .. option.definitions_found .. "@@@@@")
      if (option.definitions_found == "definiton_current_project") then
        global_cmd = "global -axd " .. symbol
        global_execute_quickfix(global_cmd, true, false)
      else
        if (option.definitions_found == "definiton_extra_paths") then
          global_cmd = "global -axd " .. symbol
          global_execute_quickfix(global_cmd, false, true)
        else
          global_cmd = "global -s -axr " .. symbol
          global_execute_quickfix(global_cmd, false, true)
        end
      end
    else
      global_cmd = "global -axd " .. symbol
      global_execute_quickfix(global_cmd, true, true, false)
    end
  else
    global_cmd = "global -s -axr " .. symbol
    if (option.current_project == true) then
      global_execute_quickfix(global_cmd, true, false)
    else
      global_execute_quickfix(global_cmd, true, true, false)
    end
  end
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
      local lines = telescope_preview(option, entry.value)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --require("telescope.previewers.utils").highlighter(self.state.bufnr, "sshconfig")
    end,
  }

  local _prompt_title = "find symbol **Definitions**"
  if (option.definition == false) then
    _prompt_title = "find symbol **References**"
  end

  -- Build picker to run connect function when a host is selected
  pickers
    .new(_, {
      prompt_title = _prompt_title,
      previewer = previewer,
      finder = finders.new_table {
        results = telescope_symbols(option)
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = state.get_selected_entry()
          --print("selection is: " .. selection[1])
          -- find symbol definition
          telescope_on_selection(option, selection[1])
        end)
        return true
      end,
    })
    :find()
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

M.show_info = function()
  if (check_executable() == false) then
    return
  end

  local root = run_command("global --print root")
  local dbpath = run_command("global --print dbpath")
  print("Current directory:")
  print("   root: " .. root)
  print("   dbpath: " .. dbpath)

  if (M.extra_paths ~= nil) then
    for _, path in ipairs(M.extra_paths) do
      local root = run_command("global --print root -C " .. path)
      local dbpath = run_command("global --print dbpath -C " .. path)
      print(path .. ":")
      print("   root: " .. root)
      print("   dbpath: " .. dbpath)
    end
  end
end

M.find_cword_definitions = function()
    local cword = vim.fn.expand("<cword>")

    find_definition(cword, true, true)
end

M.find_cword_references = function()
    local cword = vim.fn.expand("<cword>")

    find_reference(cword, false, true)
end

M.add_extra_path = function(path)
  if (check_executable() == false) then
    return
  end

  local absolute_path = vim.fn.expand(path)
  local tag_file = absolute_path .. "/GTAGS"
  if (vim.fn.filereadable(tag_file) == 0) then
    print("Error, GTAGS file not found in \"" .. path .. "\". Please generate it first")
    return
  end

  for _,v in ipairs(M.extra_paths) do
    if (v == absolute_path) then
      print("path: \"" .. path .. "\" already added")
      return
    end
  end

  table.insert(M.extra_paths, absolute_path)
  print("\"" .. path .. "\" added")
end

M.setup = function(config)
  vim.api.nvim_create_user_command("GlobalUpdateTags", function(opt)
    M.update_gtags()
  end, { nargs = 0, desc = "Update tags, if tags not exist, will generate tags" })

  vim.api.nvim_create_user_command("GlobalListDefinitions", function(opt)
    local option = {}
    option.definition = true
    option.current_project = true
    telescope_global_picker(option)
  end, { nargs = 0, desc = "List symbol definitions" })

  vim.api.nvim_create_user_command("GlobalListReferences", function(opt)
    local option = {}
    option.definition = false
    option.current_project = true
    telescope_global_picker(option)
  end, { nargs = 0, desc = "List symbol references" })

  vim.api.nvim_create_user_command("GlobalListAllDefinitions", function(opt)
    local option = {}
    option.definition = true
    option.current_project = false
    telescope_global_picker(option)
  end, { nargs = 0, desc = "List all symbol definitions" })

  vim.api.nvim_create_user_command("GlobalListAllReferences", function(opt)
    local option = {}
    option.definition = false
    option.current_project = false
    telescope_global_picker(option)
  end, { nargs = 0, desc = "List all symbol references" })

  vim.api.nvim_create_user_command("GlobalFindCwordDefinitions", function(opt)
    M.find_cword_definitions()
  end, { nargs = 0, desc = "Find cursor word definitions" })

  vim.api.nvim_create_user_command("GlobalFindCwordReferences", function(opt)
    M.find_cword_references()
  end, { nargs = 0, desc = "Find cursor word references" })

  vim.api.nvim_create_user_command("GlobalShowInfo", function(opt)
    M.show_info(opt.args)
  end, { nargs = 0, desc = "Show tag info" })

  vim.api.nvim_create_user_command("GlobalAddPath", function(opt)
    M.add_extra_path(opt.args)
  end, { nargs = 1, desc = "Add extra tag file path", complete = "dir" })
end

return M
