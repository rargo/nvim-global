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

local function check_executable()
  if (vim.fn.executable("global") == 0 or vim.fn.executable("gtags") == 0) then
    print("Error, global not found, please install it first!")
    return false
  end

  return true
end

local function execute_global_cmd(global_cmd, extra_paths, stop_if_current_project_found)
  vim.fn.setqflist({})
  vim.cmd("cclose")

  local errorformat = vim.o.errorformat
  vim.o.errorformat="%.%# %l %f %m"

  local cmd = "system(\"" .. global_cmd .. "\")"
  print("global_cmd:"  .. cmd)
  vim.cmd.cexpr(cmd)
  local qflist = vim.fn.getqflist()

  if (#qflist == 0 or stop_if_current_project_found == false) then
    if (extra_paths ~= false) then
      for _, path in ipairs(M.extra_paths) do
        local cmd = "system(\"" .. global_cmd .. " -C " .. path .. "\")"
        print("global_cmd:"  .. cmd)
        vim.cmd.cexpr(cmd)
        local path_qflist = vim.fn.getqflist()
        if (#path_qflist ~= 0) then
          for _, t in ipairs(path_qflist) do
            table.insert(qflist, t)
            -- for k,v in pairs(t) do
            --   print("k:" .. k .. " v:" .. v)
            -- end
          end
        end
      end
    end
  end

  if (#qflist == 0) then
    vim.o.errorformat = errorformat
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
  execute_global_cmd(global_cmd, extra_paths, stop_if_current_project_found)
end

local function find_reference(symbol, extra_paths, stop_if_current_project_found)
  local global_cmd = "global -s -axr " .. symbol
  execute_global_cmd(global_cmd, extra_paths, stop_if_current_project_found)
end

local function telescope_symbols(definition, current_project)
  local symbols
  local str
  local cmd = ""

  cmd = "global -c"
  str = run_command(cmd)
  symbols = vim.split(str, "\n")

  --if (definition == false) then
    cmd = "global -s -c"
	  str = run_command(cmd)
	  local t = vim.split(str, "\n")
	  for _, v in ipairs(t) do
      table.insert(symbols, v)
	  end
  --end

  if (current_project == true) then
    return symbols
  end

  for _, path in ipairs(M.extra_paths) do
    cmd = "global -c -C " .. path
    str = run_command(cmd)
    local t = vim.split(str, "\n")
    for _, v in ipairs(t) do
      table.insert(symbols, v)
    end

    --if (definition == false) then
      cmd = "global -s -c -C " .. path
      str = run_command(cmd)
      local t = vim.split(str, "\n")
      for _, v in ipairs(t) do
        table.insert(symbols, v)
      end
    --end
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

local function telescope_preview(definition, current_project, symbol)
  local preview_tbl = {}
  local cmd = ""
  if (definition) then
    cmd = "global -xd "
  else
    cmd = "global -s -xr "
  end

  local str = run_command(cmd .. symbol)
  -- global -axd output quickfix format:
  --       symbol linenumber file
  local preview_tbl = vim.split(str, "\n")

  if (definition == false and current_project == true) then
    return format_preview(preview_tbl)
  end

  -- definitions will include extra tag files result
  for _, path in ipairs(M.extra_paths) do
    local str = run_command(cmd .. symbol .. " -C " .. path)
    if (str ~= "") then
      local tbl = vim.split(str, "\n")
      for _,v in ipairs(tbl) do
        table.insert(preview_tbl, v)
      end
    end
  end

  return format_preview(preview_tbl)
end

local function telescope_on_selection(definition, current_project, symbol)
  local global_cmd = ""
  if (definition) then
    global_cmd = "global -axd " .. symbol
    execute_global_cmd(global_cmd, true, true)
  else
    global_cmd = "global -s -axr " .. symbol
    if (current_project == true) then
      execute_global_cmd(global_cmd, false, true)
    else
      execute_global_cmd(global_cmd, true, true)
    end
  end
end

local function telescope_global_picker(definition, current_project)
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
      local lines = telescope_preview(definition, current_project, entry.value)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --require("telescope.previewers.utils").highlighter(self.state.bufnr, "sshconfig")
    end,
  }

  local _prompt_title = "find symbol **Definitions**"
  if (definition == false) then
    _prompt_title = "find symbol **References**"
  end

  -- Build picker to run connect function when a host is selected
  pickers
    .new(_, {
      prompt_title = _prompt_title,
      previewer = previewer,
      finder = finders.new_table {
        results = telescope_symbols(definition, current_project)
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = state.get_selected_entry()
          --print("selection is: " .. selection[1])
          -- find symbol definition
          telescope_on_selection(definition, current_project, selection[1])
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
  vim.api.nvim_create_user_command("GlobalGenerateTags", function(opt)
    M.update_gtags()
  end, { nargs = 0, desc = "Generate gtags, if tags already exist, will update it incrementally" })

  vim.api.nvim_create_user_command("GlobalListDefinitions", function(opt)
    telescope_global_picker(true, true)
  end, { nargs = 0, desc = "List symbol definitions" })

  vim.api.nvim_create_user_command("GlobalListReferences", function(opt)
    telescope_global_picker(false, true)
  end, { nargs = 0, desc = "List symbol references" })

  vim.api.nvim_create_user_command("GlobalListAllDefinitions", function(opt)
    telescope_global_picker(true, false)
  end, { nargs = 0, desc = "List all symbol definitions" })

  vim.api.nvim_create_user_command("GlobalListAllReferences", function(opt)
    telescope_global_picker(false, false)
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
