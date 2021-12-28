--[[
	GEM-tic80
	UIKit - Simple user-interface components.
	by @jotapapel, Dec. 2021
--]]
setmetatable(_G, {__index = function(t, k) return k == "TIC" and rawget(t, "main") end})
setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end;function table.define(a,b,c)setfenv(b,setmetatable(c or{self=a},{__index=_G,__newindex=a}))()return a end;object=table.define({},function()local function f(self,g)return self[g]end;local function h(self,i)for g,j in pairs(i)do self[g]=j end end;local function k(self)return tostring(self):match("^.-%s(.-)$")end;function struct(l)return table.define({},l)end;function prototype(m,n)local o,p=n and m,n or m;local prototype=setmetatable({super=o,get=f,set=h,hash=k},{__index=o})return table.define(prototype,p,{self=prototype,super=o})end;function create(prototype,...)local e=setmetatable({prototype=prototype},{__index=prototype})if type(prototype.constructor)=="function"then prototype.constructor(e,...)end;return e end end)
function pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end
FontKit = object.struct(function()
	NORMAL = {address = 0, adjust = {[1] = "#*?%^mw", [-1] = "\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"}, width = 5}
	BOLD = {address = 112, adjust={[3] = "mw", [2] = "#", [1] = "*?^~", [-1] = "%%+/<>\\{}IT", [-2] = "()1,;%[%]`jl", [-3] = "!'%.:|i"}, width = 6}
	HEIGHT = 6
	function print(str, arg1, ...)
		local width, str, x, y, colour, style = 0, string.match(tostring(str), "(.-)\n") or tostring(str), arg1, ...
		colour, style = colour or 0, style or ((... and self.NORMAL) or arg1)
		pal(15, colour)
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjust, pattern in pairs(style.adjust) do if char:match(string.format("[%s]", pattern)) then charWidth = charWidth + adjust end end
			if y then spr(style.address + char:byte() - 32, x + width, y, 0) end
			width = width + charWidth
		end
		pal()
		return width - 1, self.HEIGHT
	end
end)
CoreKit = object.struct(function()
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
	keyboard = object.struct(function()
		function check(key, isRepeat)
			return ((isRepeat and key) or keyp)(key)
		end
	end)
	graphics = object.struct(function()
		WIDTH, HEIGHT = 240, 136
		FILL, BOX = 0xF1, 0xF2
		function isLoaded(self)
			return time() > (self.timestamp or 0) + 10
		end
		function tile(address, background)
			pal(15, background)
			map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
			pal()
		end
		function border(colour)
			poke(0x03FF8, colour or 0)
		end
		function clear(colour)
			colour = colour or 0
			memset(0x0000, (colour<<4) + colour, 16320)
		end
		function rect(style, x, y, width, height, colour)
			(style == self.BOX and rectb or rect)(x, y, width, height, colour)
		end
		line = line
	end)
end)
UIKit = object.struct(function()
	LEFT, CENTRE, RIGHT = 0, 0.5, 1
end)
UIKit.Text = object.prototype(function()
	width, height = 0, 0
	style, lineHeight = FontKit.NORMAL, 1
	lines = {}
	function set(self, content)
		self.lines = {}
		string.gsub(string.format("%s\n", tostring(content)), "(.-)\n", function(line)
			local width, _ = FontKit.print(line, self.style)
			self.lines[#self.lines + 1] = {line, width, 8}
			self.width, self.height = math.max(self.width, width), self.height + (8 * self.lineHeight)
		end)
	end
	function constructor(self, content, style, lineHeight)
		self.style, self.lineHeight = style or self.style, lineHeight or self.lineHeight
		self:set(content)
	end
	local function adjust(str, width, style)
		local newStr, newStrWidth = "", 0
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjustWidth, adjustPattern in pairs(style.adjust) do if char:match(string.format("[%s]", adjustPattern)) then charWidth = charWidth + adjustWidth end end
			if char:match("%u") then charWidth = charWidth + 1 elseif char:match("%s") then newStrWidth = newStrWidth - 1 end
			if newStrWidth + charWidth - 1 <= width then newStr, newStrWidth = newStr .. char, newStrWidth + charWidth else break end
		end
		return newStr, newStrWidth - 1
	end
	function draw(self, x, y, colour, align)
		local totalHeight = 0
		for position, line in ipairs(self.lines) do
			local align, text, width, height = align or UIKit.LEFT, table.unpack(line)
			local lineh = math.floor((height * (self.lineHeight - 1)) / 2)
			if totalHeight + height + lineh * 2 <= self.height then totalHeight = totalHeight + height + (lineh * 2) else break end
			if width > self.width then text, width = adjust(self.width, text, self.style) end
			CoreKit.graphics.rect(CoreKit.graphics.FILL, x + math.floor((self.width - width) * align), y + (position - 1) * (height * self.lineHeight) + lineh, width, height, 7 + position % 8)
			FontKit.print(text, x + math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh + 1, colour or 15, self.style)
		end
	end
end)
local text1 = object.create(UIKit.Text, "!\"#$%&\'()*+,-./0123456789\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz", FontKit.NORMAL, 2)
function main()
	CoreKit.graphics.clear(1)
	text1:draw(32, 32, 15, UIKit.CENTRE)
	CoreKit.mouse.update()
end