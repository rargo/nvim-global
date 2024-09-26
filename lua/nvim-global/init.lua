local sorters = require "telescope.sorters"
local state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local M = {}

local function run_command(cmd)
	local handle = io.popen(cmd)
	local str = handle:read("*a")
	handle:close()

	return str
end

local function get_global_definitions()
	local str = run_command("global -c")
	local t = vim.split(str, "\n")
	return t
end

local function build_definition_preview(symbol)
	local preview_tbl = {}
	local str = run_command("global -xd " .. symbol)
	-- global -axd output quickfix format:
	--       symbol linenumber file
	local tbl = vim.split(str, "\n")

	return tbl
	--for n, line in ipairs(tbl) do
	--	--print(type(line))
	--	local info = vim.split(line, " ")
	--	-- -- symbol name: info[1], line number: info[2], file location: info[3]
	--	table.insert(preview_tbl, info[1])
	--	table.insert(preview_tbl, info[2])
	--	table.insert(preview_tbl, info[3])
	--end
	--return preview_tbl
end

local function check_executable()
	if (vim.fn.executable("global") == 0 or vim.fn.executable("gtags") == 0) then
		print("Error, global not found, please install it first!")
		return false
	end

	return true
end

local function find_definition(symbol)
	vim.fn.setqflist({})
	vim.cmd("cclose")

	local errorformat = vim.o.errorformat
	vim.o.errorformat="%.%# %l %f %m"

	vim.cmd.cexpr("system(\"global -axd " .. symbol .. "\")")
	local qflist = vim.fn.getqflist()
	if (#qflist == 0) then
		return
	end

	if (#qflist >= 2) then
		vim.cmd("rightbelow cw")
		vim.cmd("cc! 1", { mods = { slient = true, emsg_silent = true }})
	end
	vim.cmd("redraw!")

	--restore errorformat
	vim.o.errorformat = errorformat
end

local function find_reference(symbol)
	vim.fn.setqflist({})
	vim.cmd("cclose")

	local errorformat = vim.o.errorformat
	vim.o.errorformat="%.%# %l %f %m"

	vim.cmd.cexpr("system(\"global -axr " .. symbol .. "\")")
	local qflist = vim.fn.getqflist()
	if (#qflist == 0) then
		return
	end

	if (#qflist >= 2) then
		vim.cmd("rightbelow cw")
		vim.cmd("cc! 1", { mods = { slient = true, emsg_silent = true }})
	end
	vim.cmd("redraw!")

	vim.o.errorformat = errorformat
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
      local lines = build_definition_preview(entry.value)
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
	print("root: " .. root .. "dbpath: " .. dbpath)
end

M.findcworddefinition = function()
	local cword = vim.fn.expand("<cword>")

	M.finddefinition(cword)
end

return M
