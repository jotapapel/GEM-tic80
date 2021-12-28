setmetatable(_G,{__index=function(t,k) return k=="TIC" and rawget(t,"main") end})
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end;function table.define(a,b,c)setfenv(b,setmetatable(c or{self=a},{__index=_G,__newindex=a}))()return a end;local object=table.define({},function()local function f(self,g)return self[g]end;local function h(self,i)for g,j in pairs(i)do self[g]=j end end;local function k(self)return tostring(self):match("^.-%s(.-)$")end;function struct(l)return table.define({},l)end;function prototype(m,n)local o,p=n and m,n or m;local prototype=setmetatable({super=o,get=f,set=h,hash=k},{__index=o})return table.define(prototype,p,{self=prototype,super=o})end;function create(prototype,...)local e=setmetatable({prototype=prototype},{__index=prototype})if type(prototype.constructor)=="function"then prototype.constructor(e,...)end;return e end end)
function pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end
FontKit=object.struct(function()
NORMAL={address=0,adjust={[1]="#*?%^mw",[-1]="\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"},width=5}
BOLD={address=112,adjust={[3]="mw",[2]="#",[1]="*?^~",[-1]="%%+/<>\\{}IT",[-2]="()1,;%[%]`jl",[-3]="!'%.:|i"},width=6}
HEIGHT=6
function print(str,arg1,...)
local width,str,x,y,colour,style=0,string.match(tostring(str),"(.-)\n") or tostring(str),arg1,...
colour,style=colour or 0,style or ((... and self.NORMAL) or arg1)
pal(15,colour)
for position=1,#str do
local char,charWidth=str:sub(position,position),style.width
for adjust,pattern in pairs(style.adjust) do if char:match(string.format("[%s]",pattern)) then charWidth=charWidth+adjust end end
if y then spr(style.address+char:byte()-32,x+width,y,0) end
width=width+charWidth
end
pal()
return width-1,self.HEIGHT
end
end)
function main()
cls(1)
FontKit.print("Hello World!",0,0,15,FontKit.BOLD)
end