setmetatable(_G,{__index=function(t,k)return k=="TIC"and rawget(t,"main")end})
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if not d then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end
System,Number,Math=setmetatable({},{__index=_G}),function(v)return tonumber(v)end,setmetatable({},{__index=math})
function System.pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end
String=setmetatable({},{__index=string,__call=function(t,v)return tostring(v)end})
function String.mask(a,b)if b then a=b:gsub("%$",a)end;return a end
function String.def(a,c,b)return a==nil and(c or"")or tostring(a):mask(b)end
function String.trim(...)local d={...}for e,f in ipairs(d)do d[e]=string.match(tostring(f),"^%s*(.-)%s*$")end;return unpack(d)end
function String.gsubc(a,b,c)local d,e={},1;a=a:gsub(b,function(f)local g=string.format("%s%03i",tostring(d):sub(-4),e)d[g],e=f,e+1;return g:mask(c)end)d.token,d.len=c,e;return a,d end
function String.gsubr(a,b,c)local d=b.len==nil and error("Replace table missing length value.",2)or b.len;local e=b.token==nil and error("Replace table missing token.",2)or b.token;for f=1,d do local g=string.format("%s%03i",tostring(b):sub(-4),f)a=a:gsub(g:mask(e),function()return string.def(b[g],"",c)end)end;return a end
Array=setmetatable({each=pairs,list=ipairs},{__index=table})
function Array.expand(a,b,c)local d=""for e=1,#a-1 do d=string.format("%s%s%s",d,a[e]:mask(c),b)end;return#a>0 and string.format("%s%s",d,a[#a]:mask(c))or nil end
function Array.define(a,b,c)local d=setmetatable({self=a,super=c},{__index=_G,__newindex=a})setfenv(b,d)()return a end
Object=Array.define({},function()
	local function hash(self) return tostring(self):match("^.-:%s+([%w%d]+)$")end
	local function get(self,a)return self[a]end
	local function set(self,a)for b,c in pairs(a)do self[b]=c end end
	local function catch(a,b,c)local d,e=type(c),a[b]or getmetatable(a).__index[b]if e and d~="function"and d~=type(e)then error(string.format("Type mismatch (%s expected, got %s).",type(e),d),2)end;rawset(a,b,c)end
	local function create(a,...)local b=setmetatable({},{__index=a})if a.constructor then a.constructor(b,...)end;return b end
	function prototype(a,b)local c,d=b and a,b or a;local e=setmetatable({get=get,hash=hash,set=set,super=c},{__index=c,__call=create})return setmetatable({},{__index=Array.define(e,d,c),__newindex=catch})end
	function struct(a)return Array.define({},a)end
end)

-- GEM

struct FontKit def
		
	var NORMAL = {address = 0, adjust = {[1] = "#*?%^mw", [-1] = "\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"}, width = 5}
	var BOLD = {address = 112, adjust={[3] = "mw", [2] = "#", [1] = "*?^~", [-1] = "%%+/<>\\{}IT", [-2] = "()1,;%[%]`jl", [-3] = "!'%.:|i"}, width = 6}
	var HEIGHT = 6
		
	function print(str, arg1, ...)
		local width, str, x, y, colour, style = 0, String.match(String(str), "(.-)\n") or String(str), arg1, ...
		colour, style = colour or 15, style or ((... and self.NORMAL) or arg1)
		System.pal(15, colour)
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjust, pattern in Array.each(style.adjust) do if char:match(String.format("[%s]", pattern)) then charWidth = charWidth + adjust end end
			if y then System.spr(style.address + char:byte() - 32, x + width, y, 0) end
			width = width + charWidth
		end
		System.pal()
		return width - 1, self.HEIGHT
	end
		
end

struct IOKit def

end

-- main function
		
function main()
	System.cls()
	FontKit.print("hello world!", 0, 0)
end