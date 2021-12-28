--[[
  Simple object-oriented library for lua
  created by @jotapapel, 2021
--]]
	
@compile /object.min.lua

setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end
function table.define(a,b,c)setfenv(b,setmetatable(c or{self=a},{__index=_G,__newindex=a}))()return a end

local object = table.define({}, function()
	local function get(self, key) return self[key] end
	local function set(self, properties) for key, value in pairs(properties) do self[key] = value end end
	local function hash(self) return tostring(self):match("^.-%s(.-)$") end

	function struct(defn)
		return table.define({}, defn)
	end

	function prototype(arg1, arg2)
		local super, fn = arg2 and arg1, arg2 or arg1
		local prototype = setmetatable({super = super, get = get, set = set, hash = hash}, {__index = super})
		return table.define(prototype, fn, {self = prototype, super = super})
	end
	
	function create(prototype, ...)
		local object = setmetatable({prototype = prototype}, {__index = prototype})
		if type(prototype.constructor) == "function" then prototype.constructor(object, ...) end
		return object
	end
end)