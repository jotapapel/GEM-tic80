--[[
  Core Utilities (requires object.lua and GEMASCII spritesheet)
  created by @jotapapel, 2021
]]--

coreKit = {}

coreKit.mouse = object.prototype(function()
	local buff,cur=0,0
	LEFT,MIDDLE,RIGHT=1,-1,4
	DEFAULT,WAIT,CROSSHAIR,FORBIDDEN,POINTER,TEXT,MOVE=0,1,2,3,4,5,6
	function check(...)local a,b,c=peek(0x0FF86),...if#{...}==0 then return a==0 end;if not(c)then return a==b and buff==1 else return a==b end end
	function clear()poke(0x0FF86,0)end
	function cursor(a)if a then cur=a else cur=(cur+1)%7 end end
	function inside(a,b,c,d)local e,f=peek(0x0FF84),peek(0x0FF85)return math.inside(e,f,a,b,c,d)end
	function update()local a,b,c=peek(0x0FF84),peek(0x0FF85),peek(0x0FF86)buff=c>0 and math.min(2,buff+1)or 0;poke(0x03FFB,0)pal(1,0)spr(224+cur*2,a-5,b-5,0,1,0,0,2,2)pal()end
end);

coreKit.font = {}
coreKit.font.HEIGHT = 6
coreKit.font.REGULAR = {address = 0, adjust = {[2] = "&", [1] = "#$*?@%^%dmw", [-1] = "\"%%+/<>\\{}", [-2] = "()1,;%[%]`jl", [-3] = "!'%.:|i"}, width = 5}
coreKit.font.BOLD = {address = 112, adjust = {[3] = "mw", [2] = "#&", [1] = "$*?@^%d~", [-1] = "%%+/<>\\{}", [-2] = "()1,;%[%]`jl", [-3] = "!'%.:|i"}, width = 6}

function coreKit.font.print(text, arg1, ...)
	local width, height, text, x, y, colour, style = 0, 6, string.match(tostring(text), "(.-)\n") or tostring(text), arg1, ...
	colour, style = colour or 0, style or ((... and coreKit.font.REGULAR) or arg1)
	pal(15, colour)
	for position = 1, #text do
		local char, charw = text:sub(position, position), style.width
		for w, adjust in pairs(style.adjust) do if char:match(string.format("[%s]", adjust)) then charw = charw + w end end
		if char:match("%u") then charw = charw + 1 elseif char:match("%s") and position > 1 then width = width - 1 end
		if y then spr(style.address + char:byte() - 32, x + width, y, 0) end
		width = width + charw
	end
	pal()
	return width - 1, coreKit.font.HEIGHT
end

coreKit.graphics = {}
coreKit.graphics.WIDTH, coreKit.graphics.HEIGHT = 240, 136
coreKit.graphics.FILL, coreKit.graphics.BOX = 0xF1, 0xF2

coreKit.graphics.border = function(colour)
	poke(0x03FF8, colour or 0)
end

coreKit.graphics.clear = function(colour)
	colour = colour or 0
	memset(0x0000, (colour<<4)+colour, 16320)
end

coreKit.graphics.tile = function(tile, colour)
	pal(15, colour)
	map(0, 0, 30, 17, 0, 0, 0, 1, function() return tile end)
	pal()
end

coreKit.graphics.rect = function(style, x, y, w, h, colour)
	((style == coreKit.graphics.BOX and rectb) or rect)(x, y, w, h, colour)
end

coreKit.graphics.line = line
