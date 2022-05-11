--[[
  Simple object-oriented library for lua.
  by @jotapapel, Dec. 2021
--]]
	
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end
function table.define(a,b,c)setfenv(b,setmetatable(c or{self=a},{__index=_G,__newindex=a}))()return a end

table.def = setmetatable({}, {__index = _G, __call = function(self, target, defn, super)
	rawset(self, "self", target)
	rawset(self, "super", super)
	getmetatable(self).__newindex = target
	setfenv(defn, self)()
	return target
end})

table.strongdef = setmetatable({["~"] = "string", ["#"] = "number", ["@"] = "table", ["&"] = "boolean"}, {__index = _G, __call = function(self, target, defn, super)
	rawset(self, "self", target)
	rawset(self, "super", super)
	getmetatable(self).__newindex = function(self, key, value)
		local valueType, varType, varKey = type(value), key:match("^([~#@&!]?)(.-)$")
		if super and super[varKey] and #varType == 0 then varType = type(super[varKey]) elseif #varType == 0 then varType = nil end
		if varType and valueType ~= "nil" and valueType ~= "function" and varType ~= "!" and (self[varType] or varType) ~= valueType then error(string.format("Type mismatch (%s expected, got %s).", this[varType] or varType, valueType), 2) end
		rawset(target, varKey, value)
	end
	setfenv(defn, self)()
	return target
end})

mud = table.define({}, function()
	local function get(self, key) return self[key] end
	local function set(self, properties) for key, value in pairs(properties) do self[key] = value end end
	local function hash(self) return tostring(self):match("^.-%s(.-)$") end

	local function create(prototype, ...)
		local object = setmetatable({prototype = prototype}, {__index = prototype})
		if type(prototype.constructor) == "function" then prototype.constructor(object, ...) end
		return object
	end

	function struct(defn)
		return table.define({}, defn)
	end

	function prototype(arg1, arg2)
		local super, fn = arg2 and arg1, arg2 or arg1
		local prototype = setmetatable({super = super, get = get, set = set, hash = hash}, {__index = super, __call = create})
		return table.define(prototype, fn, {self = prototype, super = super})
	end
end)