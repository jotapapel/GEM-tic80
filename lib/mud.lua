--[[
	mud
  Simple object-oriented library for lua.
  by @jotapapel, Dec.2021 - Jan. 2022
	v 1.0 (7012022)
--]]
	
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end
object={new=function(a,...)local b=setmetatable({super=a},{__index=a})if type(a.constructor)=="function" then a.constructor(b,...) end;return b end,prototype=function(...)local a,b=...local c=b and a;local d=setmetatable({super=c},{__index=c})local e=setmetatable({self=d,super=c},{__index=_G,__newindex=d})setfenv(b or a,e)();return d end}

A = object.prototype(function()
	a, b, c = "string", 99, false
	function constructor(self, a, b, c)
		self.a, self.b, self.c = a, b, c
	end
end)

local a = object.new(A, 100, "top", true)

print(A.a, A.b, A.c)
print(a.a, a.b, a.c)