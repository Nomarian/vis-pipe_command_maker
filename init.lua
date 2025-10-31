
--[[
Synopsis:
	Spits out closure for registering commands (,| COMMAND )
Use:
	local PipeCmdMaker = require"vis.pipe_command_maker"()
	vis:command_register("sort", PipeCmdMaker"sort", "Sorts file/range")
Warning:
	argv isn't handled
Bugs:
--]]

------------------------- ENV

local _G = _G
local env = {} for k,v in pairs(_G) do env[k] = v end
local mt = {
	__index = function (_,k)
		error(
			string.format("Missing Key[%s] in trailing whitespace module",k)
			, 2
		)
		return nil
	end
	,__newindex = function (t,k,v)
		error(string.format("ERROR: _G[%s]=%s",k,v),2)
	end
}
--- luacheck: variable _ENV
local _ENV = setmetatable(env, mt)

local vis = _G.vis
--------------------- MAIN

local function Maker(command)
	return function (argv, force, win, sel, range) -- ,|sort
		if #argv~=0 then
			command = command .. " " .. table.concat(argv, " ")
		end
		local file = win.file
		local size = file.size
		if size==0 then return end
		local code, stdout, stderr = vis:pipe(file, range, command)
		if code~=0 or stdout==file:content(range.start,range.finish) then
			vis:message(stderr)
			return nil
		end

		local line = sel.line
		if line then
			local col = sel.col
			file:delete(range) -- Should be range
			file:insert(range.start, stdout) -- Should be range
			sel:to(line, col)
		else local linesT = file.lines
			local Iterator = stdout:gmatch"[\r\n]*"
			for NR=1, #linesT do
				local changed_line = Iterator()
				if changed_line==nil then break end
				linesT[NR] = changed_line
			end
		end
		return true
	end
end


--------------------- RETURN

local Call = function () return Maker end

return setmetatable({ Maker = Maker },{
	__call = Call

	-- Bastardization of Nim's Style
	-- Case insensitive
	,__index = function (T,index)
		if type(index)=="string" then
			index = index:gsub("_",""):lower()
			for key, val in pairs(T) do
				if key:gsub("_",""):lower()==index then return val end
			end
		end
		return nil
	end

	, __newindex = function ()
		error"MODULE IS READ ONLY"
	end
})
