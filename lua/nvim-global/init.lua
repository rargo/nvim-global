local sorters = require "telescope.sorters"
local state = require "telescope.actions.state"
local previewers = require "telescope.previewers"


-- TODO
-- 1. multiple tags support
-- 2. global tags as completion resource

local M = {}

M.extra_paths = {}

local function run_command(cmd)
	local handle = io.popen(cmd)
	local str = handle:read("*a")
	handle:close()

	return str
end

local function get_global_definitions()
	local str = run_command("global -c")
	local definitions = vim.split(str, "\n")
	local str = run_command("global -s -c")
	local t = vim.split(str, "\n")
	for _, v in ipairs(t) do
		table.insert(definitions, v)
	end
	
	return definitions
end

local function build_definition_preview(symbol, extra_paths)
	local preview_tbl = {}
	local str = run_command("global -xd " .. symbol)
	-- global -axd output quickfix format:
	--       symbol linenumber file
	local preview_tbl = vim.split(str, "\n")

	if (extra_paths ~= nil) then
		for _, path in ipairs(extra_paths) do
			local str = run_command("global -xd " .. symbol .. " -C " .. path)
			if (str ~= "") then
				local tbl = vim.split(str, "\n")
				for _,v in ipairs(tbl) do
					table.insert(preview_tbl, v)
				end
			end
		end
	end

	return preview_tbl
end

local function check_executable()
	if (vim.fn.executable("global") == 0 or vim.fn.executable("gtags") == 0) then
		print("Error, global not found, please install it first!")
		return false
	end

	return true
end

local function execute_global_cmd(global_cmd, extra_paths)
	vim.fn.setqflist({})
	vim.cmd("cclose")

	local errorformat = vim.o.errorformat
	vim.o.errorformat="%.%# %l %f %m"

	local cmd = "system(\"" .. global_cmd .. "\")"
	vim.cmd.cexpr(cmd)
	local qflist = vim.fn.getqflist()

	if (extra_paths ~= nil) then
		for _, path in ipairs(extra_paths) do
			local cmd = "system(\"" .. global_cmd .. " -C " .. path .. "\")"
			print("global_cmd:"  .. cmd)
			vim.cmd.cexpr(cmd)
			local path_qflist = vim.fn.getqflist()
			if (#path_qflist ~= 0) then
				for _, t in ipairs(path_qflist) do
					table.insert(qflist, t)
					-- for k,v in pairs(t) do
					-- 	print("k:" .. k .. " v:" .. v)
					-- end
				end
			end
		end
	end
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

local function find_definition(symbol)
	local global_cmd = "global -axd " .. symbol
	execute_global_cmd(global_cmd, M.extra_paths)
end

local function find_reference(symbol)
	local global_cmd = "global -axr " .. symbol
	execute_global_cmd(global_cmd)
end

M.setup = function(config)
  vim.api.nvim_create_user_command("GlobalGenerateTags", function(opt)
	M.updategtags()
  end, { nargs = 0, desc = "Generate gtags, if tags already exist, will update it incrementally" })

  vim.api.nvim_create_user_command("GlobalListDefinition", function(opt)
	M.listdefinitions()
  end, { nargs = 0, desc = "List symbol definition" })

  vim.api.nvim_create_user_command("GlobalFindDefinition", function(opt)
	M.finddefinition(opt.args)
  end, { nargs = 1, desc = "Find symbol definition" })

  vim.api.nvim_create_user_command("GlobalFindCwordDefinition", function(opt)
	M.findcworddefinition()
  end, { nargs = 0, desc = "Find cursor word definition" })

  vim.api.nvim_create_user_command("GlobalFindReference", function(opt)
	M.findreference(opt.args)
  end, { nargs = 1, desc = "Find symbol reference" })

  vim.api.nvim_create_user_command("GlobalShowInfo", function(opt)
	M.showinfo(opt.args)
  end, { nargs = 0, desc = "Show tag info" })

  vim.api.nvim_create_user_command("GlobalAddPath", function(opt)
	M.addextrapath(opt.args)
  end, { nargs = 1, desc = "Add extra tags", complete = "dir" })
end

M.listdefinitions = function(_)
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
      local lines = build_definition_preview(entry.value, M.extra_paths)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --require("telescope.previewers.utils").highlighter(self.state.bufnr, "sshconfig")
    end,
  }

  -- Build picker to run connect function when a host is selected
  pickers
    .new(_, {
      prompt_title = "global find definitions",
      previewer = previewer,
      finder = finders.new_table {
        results = get_global_definitions()
      },
      sorter = sorters.get_generic_fuzzy_sorter(),
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)

          local selection = state.get_selected_entry()
          --print("selection is: " .. selection[1])
          -- find symbol definition
          find_definition(selection[1])
        end)
        return true
      end,
    })
    :find()
end

M.updategtags = function()
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

M.finddefinition = function(symbol)
	if (check_executable() == false) then
		return
	end

	find_definition(symbol)
end

M.findreference = function(symbol)
	if (check_executable() == false) then
		return
	end

	find_reference(symbol)
end

M.showinfo = function()
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

M.findcworddefinition = function()
	local cword = vim.fn.expand("<cword>")

	M.finddefinition(cword)
end

M.addextrapath = function(path)
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

return M
