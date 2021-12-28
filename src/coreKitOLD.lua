--[[
	GEM-tic80
	CoreKit - Core utilities, both IO and graphics.
	by @jotapapel, Dec. 2021
--]]
setmetatable(_G, {__index = function(t, k) return k == "TIC" and rawget(t, "main") end})
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end;function table.define(a,b,c)setfenv(b,setmetatable(c or{self=a},{__index=_G,__newindex=a}))()return a end;local object=table.define({},function()local function f(self,g)return self[g]end;local function h(self,i)for g,j in pairs(i)do self[g]=j end end;local function k(self)return tostring(self):match("^.-%s(.-)$")end;function struct(l)return table.define({},l)end;function prototype(m,n)local o,p=n and m,n or m;local prototype=setmetatable({super=o,get=f,set=h,hash=k},{__index=o})return table.define(prototype,p,{self=prototype,super=o})end;function create(prototype,...)local e=setmetatable({prototype=prototype},{__index=prototype})if type(prototype.constructor)=="function"then prototype.constructor(e,...)end;return e end end)
function pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end
local CoreKit = {}
getmetatable(_G).__newindex = CoreKit
mouse = object.struct(function()
	local buffer, cur = 0, 0
	LEFT, MIDDLE, RIGHT = 1, -1, 4
	DEFAULT, WAIT, CROSSHAIR, FORBIDDEN, POINTER, TEXT, MOVE = 0, 1, 2, 3, 4, 5, 6
	function check(...)
		local m, button, isRepeat = peek(0x00FF86), ...
		if select("#", ...) == 0 then return m == 0 end
		if not isRepeat then return m == button and buffer == 1 else return m == button end
	end
	function clear()
		poke(0x0FF86, 0)
	end
	function cursor(address)
		cur = address or 0
	end
	function inside(x1, y1, x2, y2)
		local x, y = peek(0x0FF84), peek(0x0FF85)
		return x >= math.min(x1, x2) and x < math.max(x1,x2) and y >= math.min(y1, y2) and y < math.min(y1, y2)
	end
	function update()
		local x, y, m = peek(0x0FF84), peek(0x0FF85), peek(0x0FF86)
		buffer = (m > 0 and math.min(buffer + 1, 2)) or 0
		pal(1, 0)
		spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
		pal()
		poke(0x03FFB, 0)
	end
end)
getmetatable(_G).__newindex = nil
function main()
	cls(1)
	CoreKit.mouse.update()
end