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
	function prototype(a,b)local c,d=b and a,b or a;local e=setmetatable({get=get,hash=hash,set=set,super=c},{__index=c})return setmetatable({},{__index=Array.define(e,d,c),__newindex=catch,__call=create})end
	function struct(a)return Array.define({},a)end
end)

-- GEM Kernel

struct FontKit def
	var NORMAL = {address = 0, adjust = {[1] = "#*?%^mw", [-1] = "\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"}, width = 4}
	var BOLD = {address = 112, adjust={[3] = "mw", [2] = "#", [1] = "*%?^~", [-1] = "1%%+/<>\\{}T", [-2] = "(),;%[%]`jl", [-3] = "!'%.:|i"}, width = 5}
	var HEIGHT = 6
	
	function print(str, arg1, ...)
		local width, str, x, y, colour, style = 0, String.match(String(str), "(.-)\n") or String(str), arg1, ...
		colour, style = colour or 0, style or ((... and self.NORMAL) or arg1)
		System.pal(15, colour)
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjust, pattern in Array.each(style.adjust) do if char:match(String.format("[%s]", pattern)) then charWidth = charWidth + adjust end end
			if y then System.spr(style.address + char:byte() - 32, x + width, y, 0) end
			width = width + charWidth + 1
		end
		System.pal()
		return width - 1, self.HEIGHT
	end
end

struct GraphicsKit def
	var WIDTH, HEIGHT = 240, 136
	var FILL, BOX = 0xF1, 0xF2
	
	var BLACK, WHITE = 0, 15
	var IRON, STEEL, GREY, SILVER = 1, 12, 13, 14
	var MAROON, RED = 2, 3
	var GREEN, LIME = 4, 5
	var NAVY, BLUE = 6, 7
	var TEAL, AQUA = 8, 9
	var GOLD, YELLOW = 10, 11
	
	function border(colour)
		System.poke(0x03FF8, colour or 0)
	end
	
	function clear(colour)
		colour = colour or 0
		System.memset(0x0000, (colour<<4) + colour, 16320)
	end
	
	function isLoaded(self)
		return System.time() > (self.timestamp or 0) + 10
	end
	
	function line(...)
		System.line(...)
	end
	
	function rect(style, x, y, width, height, colour)
		(style == self.BOX and System.rectb or System.rect)(x, y, width, height, colour)
	end
	
	function tile(address, background)
		System.pal(15, background)
		System.map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
		System.pal()
	end
end

struct IOKit def
	struct mouse def
		local buffer, cur = 0, 0
		LEFT, MIDDLE, RIGHT = 1, -1, 4
		DEFAULT, WAIT, CROSSHAIR, FORBIDDEN, POINTER, TEXT, MOVE = 0, 1, 2, 3, 4, 5, 6
		
		function check(...)
			local m, button, isRepeat = System.peek(0x00FF86), ...
			if select("#", ...) == 0 then return m == 0 end
			if not isRepeat then return m == button and buffer == 1 else return m == button end
		end
		
		function clear()
			System.poke(0x0FF86, 0)
		end
		
		function cursor(address)
			cur = address or 0
		end
		
		function inside(x1, y1, x2, y2)
			local x, y = System.peek(0x0FF84), System.peek(0x0FF85)
			return x >= Math.min(x1, x2) and x < Math.max(x1, x2) and y >= Math.min(y1, y2) and y < Math.max(y1, y2)
		end
		
		function update()
			local x, y, m = System.peek(0x0FF84), System.peek(0x0FF85), System.peek(0x0FF86)
			buffer = (m > 0 and Math.min(buffer + 1, 2)) or 0
			System.poke(0x03FFB, 0)
			System.pal(1, 0)
			System.spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
			System.pal()
		end
	end
	
	struct keyboard def
		function check(key, isRepeat)
			return ((isRepeat and System.key) or System.keyp)(key)
		end
	end
end

struct GEMUI def

	var LEFT, CENTRE, RIGHT = 0, 0.5, 1
	var TOP, MIDDLE, BOTTOM = 0, 0.5, 1
	var RELATIVE, ABSOLUTE = 0xD1, 0xD2
	
end

prototype GEMUI.Text def

	var width, height = 0, 0
	var style, lineHeight = FontKit.NORMAL, 1
	var lines = {}
	
	constructor(content, style, lineHeight)
		self.style, self.lineHeight = style or self.style, lineHeight or self.lineHeight
		self:setContent(content)
	end
	
	local function adjust(str, width, style)
		local newStr, newStrWidth = "", 0
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjustWidth, adjustPattern in Array.each(style.adjust) do if char:match(String.format("[%s]", adjustPattern)) then charWidth = charWidth + adjustWidth end end
			if char:match("%u") then charWidth = charWidth + 1 elseif char:match("%s") then newStrWidth = newStrWidth - 1 end
			if newStrWidth + charWidth - 1 <= width then newStr, newStrWidth = newStr .. char, newStrWidth + charWidth else break end
		end
		return newStr, newStrWidth - 1
	end
	
	function draw(self, x, y, colour, align)
		local totalHeight = 0
		for position, line in Array.list(self.lines) do
			local align, text, width, height = align or GEMUI.LEFT, Array.unpack(line)
			local lineh = Math.floor((height * (self.lineHeight - 1)) / 2)
			if totalHeight + height + lineh * 2 <= self.height then totalHeight = totalHeight + height + (lineh * 2) else break end
			if width > self.width then text, width = adjust(self.width, text, self.style) end
			if _DEBUG then GraphicsKit.rect(GraphicsKit.FILL, x + Math.floor((self.width - width) * align), y + (position - 1) * (height * self.lineHeight) + lineh, width, height, 7 + position % 8) end
			FontKit.print(text, x + Math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh + 1, colour or 15, self.style)
		end
	end
	
	function setContent(self, content)
		self.lines = {}
		String.gsub(String.format("%s\n", String(content)), "(.-)\n", function(line)
			local width, _ = FontKit.print(line, self.style)
			self.lines[#self.lines + 1] = {line, width, 8}
			self.width, self.height = Math.max(self.width, width), self.height + (8 * self.lineHeight)
		end)
	end
	
end
	
prototype GEMUI.Object def
	var x, y, width, height = 0, 0, 0, 0
	var background, colour = GraphicsKit.WHITE, GraphicsKit.BLACK
	var padding, border, align, style = {right = 0, top = 0, left = 0, bottom = 0}, {size = 0, colour = GraphicsKit.BLACK}, {horizontal = GEMUI.CENTRE, vertical = GEMUI.MIDDLE}, FontKit.NORMAL
	var position = GEMUI.RELATIVE
	var enabled, hover, active = true, false, false
	
	constructor(properties)
		self.timestamp = System.time()
		if type(properties) == "table" then self:set(properties) end
	end
	
	function draw(self, background, colour)
		GraphicsKit.rect(GraphicsKit.FILL, self.x, self.y, self:getWidth(), self:getHeight(), background or self.background)
		for border = 0, self.border.size - 1 do GraphicsKit.rect(GraphicsKit.BOX, self.x + border, self.y + border, self:getWidth() - border * 2, self:getHeight() - border * 2, self.border.colour) end
		if self.content then self.content:draw(self.x + self.border.size + self.padding.left, self.y + self.border.size + self.padding.top, colour or self.colour, self.align.horizontal) end
	end
	
	function getHeight(self)
		return (self.border.size * 2) + self.padding.top + self.height + self.padding.bottom
	end
	
	function getWidth(self)
		return (self.border.size * 2) + self.padding.left + self.width + self.padding.right
	end
	
	function setContent(self, content, style, lineHeight)
		local content = GEMUI.Text(content, style, lineHeight)
		self:set({content = content, width = content.width, height = content.height})
	end
	
	function setHeight(self, height)
		self.height = height - self.border.size * 2 - self.padding.top - self.padding.bottom
	end
	
	function setSize(self, width, height)
		local border = self.padding.border * 2
		self.width, self.height = width - border - self.padding.left - self.padding.right, height - border - self.padding.top - self.padding.bottom
	end
	
	function setWidth(self, width)
		self.width = width - self.border.size * 2 - self.padding.left - self.padding.right	
	end
	
	function update(self)
		if not self.parent and self.active and IOKit.mouse.check() and type(self.onActive) == "function" then self:onActive() end
		if self.enabled then
			self.hover = IOKit.mouse.inside(self.x, self.y, self.x + self:getWidth(), self.y + self:getHeight())
			self.active = self.hover and IOKit.mouse.check(IOKit.mouse.LEFT, true)
		end
	end
end

prototype GEMUI.Container def
	var width, height = 0, 0
	var display, padding, separation = GEMUI.RELATIVE, {horizontal = 0, vertical = 0}, 0
	var enabled, overflow = true, false
	var elements = {}
	
	constructor(width, height, properties)
		if properties then self:set(properties) end
		self:set({width = width, height = height, elements = {}})
	end
	
	function append(self, element)
		element.parent = self
		table.insert(self.elements, element)
		return element
	end
	
	function draw(self, x, y, start)
		local x, y, margin, spacing = x or 0, y or 0, {horizontal = 0, vertical = 0}, 0
		for position, element in self:iterator(start) do
			if self.display == GEMUI.RELATIVE and element.position == GEMUI.RELATIVE then
				if margin.horizontal + element:getWidth() > self.width - self.padding.horizontal then margin.horizontal, margin.vertical = 0, margin.vertical + spacing + self.separation end
				if not self.overflow and (margin.vertical + element:getHeight() > self.height - self.padding.vertical or element:getWidth() > self.width - self.padding.horizontal) then break end
				element.x, element.y, spacing = x + self.padding.horizontal + margin.horizontal, y + self.padding.vertical + margin.vertical, element:getHeight()
				margin.horizontal = margin.horizontal + element:getWidth() + self.separation
			end
			if self.onActive and element.active and IOKit.mouse.check() then self:onActive(element) end
			if element.update and element.enabled and self.enabled then element:update() end
			if element.draw and GraphicsKit.isLoaded(element) then element:draw() end
		end
	end
	
	function getWidth(self)
		return self.width + self.padding.horizontal
	end
	
	function getHeight(self)
		return self.height + self.padding.vertical
	end
	
	function iterator(self, start)
		local position = (start and start - 1) or 0
		return function()
			position = position + 1
			if position <= self:size() then return position, self.elements[position] end
		end
	end
	
	function remove(self, element)
		for position, elem in ipairs(self.elements) do
			if element == elem then table.remove(self.elements, position) end
		end
	end
	
	function setHeight(self, height)
		self.height = height - self.padding.vertical
	end
	
	function setSize(self, width, height)
		self.width, self.height = width - self.padding.horizontal, height - self.padding.vertical
	end
	
	function setState(self, state)
		for _, elements in self:iterator() do self.enabled = state end
	end
	
	function setWidth(self, width)
		self.width = width - self.padding.horizontal	
	end
	
	function size(self)
		return #self.elements
	end
	
end

prototype GEMUI.Button is GEMUI.Object def

	var padding, border = {right = 9, top = 2, left = 9, bottom = 2}, {size = 2, colour = GraphicsKit.BLACK}
	var style = FontKit.BOLD
	
	constructor(label, properties)
		super.constructor(self, properties)
		self:setContent(label, self.style)
	end
	
	function draw(self)
		super.draw(self, self.active and GraphicsKit.BLACK, self.active and GraphicsKit.WHITE)
	end
	
end

prototype GEMUI.Command is GEMUI.Object def

	var NAME, SEPARATOR, OPTION = 0xF1, 0xF2, 0xF3
	var padding = {right = 5, top = 1, left = 5, bottom = 1}
	var style, align = FontKit.NORMAL, {horizontal = GEMUI.LEFT, vertical = GEMUI.MIDDLE}
	
	local function iterator(self)
		local position = 0
		return function()
			position = position + 1
			if position <= #self.elements then 
				local element = self.elements[position]
				element:setWidth(self:getWidth())
				return position, element
			end
		end
	end
	
	constructor(label, properties, hasCommandView)
		super.constructor(self, properties)
		self:setContent(label, self.style)
		if hasCommandView then self.commandView = GEMUI.CommandView(0, 0, {parent = self, iterator = iterator}) end
	end
	
	function append(self, arg1, ...)
		local command, properties = self.commandView:append(arg1, {padding = {right = 1, top = 1, left = 1, bottom = 1}}), ...
		if arg1 == self.SEPARATOR then command.content, command.flag, command.height = nil, arg1, 1 end
		if type(properties) == "table" and properties.type == self.OPTION then command.selected, command.flag = properties.selected or false, properties.type end
		self.commandView:setSize(Math.max(self.commandView:getWidth(), command:getWidth()), self.commandView:getHeight() + command:getHeight())
		return command
	end
	
	function appendOLD(self, arg1, ...)
		local command, flag, option = self.commandView:append(arg1, {padding = {right = 1, top = 1, left = 1, bottom = 1}}), ...
		if arg1 == self.SEPARATOR then command.content, command.flag, command.height = nil, arg1, 1 end
		if flag == self.OPTION then command.selected, command.flag = option, flag end
		local hintWidth = command.hint and FontKit.print(command.hint, FontKit.BOLD) or 0
		self.commandView:setSize(Math.max(self.commandView:getWidth(), command:getWidth() + hintWidth), self.commandView:getHeight() + command:getHeight())
		return command
	end
	
	function hideCommandView(self)
		self.parent.activeCommand = nil
	end
	
	function isActiveCommand(self)
		return self.parent.activeCommand == self
	end
	
	function draw(self)
		local active = self.hover or self.active or self:isActiveCommand()
		super.draw(self, active and GraphicsKit.BLACK, active and GraphicsKit.WHITE)
		if self.flag == self.SEPARATOR then GraphicsKit.line(self.x, self.y + self.padding.top, self.x + self:getWidth(), self.y + self.padding.top, 0) end
		
		if self.flag == self.OPTION and self.selected then 
			if _DEBUG then GraphicsKit.rect(GraphicsKit.FILL, self.x + 2, self.y + self.padding.top, 8, 8, GraphicsKit.AQUA) end
			FontKit.print(String.char(32 - 8), self.x + 3, self.y + self.padding.top + 1, active and GraphicsKit.WHITE or GraphicsKit.BLACK, FontKit.BOLD)
		end
		
		if self.commandView and self:isActiveCommand() then self.commandView:draw(self.x + 1, self.y + self:getHeight() + 1) end
		
		if self.hint then
			local w, _ = FontKit.print(self.hint, FontKit.BOLD)
			if _DEBUG then GraphicsKit.rect(GraphicsKit.FILL, self.x + self:getWidth() - w - 2, self.y + self.padding.top, w, 8, GraphicsKit.AQUA) end
			FontKit.print(self.hint, self.x + self:getWidth() - w - 2, self.y + self.padding.top + 1, active and GraphicsKit.WHITE or GraphicsKit.BLACK, FontKit.BOLD)
		end
		
	end
	
	function shortcut(self, key)
		self.hint = String.format("^%s", key)
		return self
	end
	
	function update(self)
		if self.hover and self.commandView and self.commandView:size() > 0 then self.parent.activeCommand = self end
		if self.flag ~= self.SEPARATOR then super.update(self) end
	end
	
end

prototype GEMUI.CommandView is GEMUI.Container def

	var overflow = true
	
	function append(self, label, properties)
		local command = super.append(self, GEMUI.Command(label, properties, true))
		return command
	end
	
	function draw(self, x, y)
		x, y = x or 0, y or 0
		if x + self:getWidth() > GraphicsKit.WIDTH then x = GraphicsKit.WIDTH - self:getWidth() - 5 end
		if self.parent and IOKit.mouse.check(IOKit.mouse.LEFT) and self.parent:isActiveCommand() and not IOKit.mouse.inside(x, y, x + self:getWidth(), y + self:getHeight()) then self.parent:hideCommandView() end
		GraphicsKit.rect(GraphicsKit.FILL, x, y, self:getWidth(), self:getHeight(), GraphicsKit.WHITE)
		GraphicsKit.rect(GraphicsKit.BOX, x - 1, y - 1, self:getWidth() + 2, self:getHeight() + 2, GraphicsKit.BLACK)
		super.draw(self, x, y)
	end
	
	function onActive(self, command)
		if command.onActive then command.onActive() elseif self.parent.onActive then self.parent:onActive(command) end
		if command.flag ~= GEMUI.Command.OPTION then self.parent:hideCommandView() end
	end
	
end

--

_DEBUG = true

local container1 = GEMUI.CommandView(GraphicsKit.WIDTH - 4, 10, {padding = {horizontal = 4, vertical = 0}})

local titleCommand, titleCommandCommands = container1:append("Desktop", {style = FontKit.BOLD, position = GEMUI.ABSOLUTE, y = 0}), {}
titleCommand.x = GraphicsKit.WIDTH - titleCommand:getWidth() - 4
titleCommandCommands.about = titleCommand:append("About Desktop...")
titleCommandCommands.prefs = titleCommand:append("Preferences")
titleCommandCommands.help = titleCommand:append("Help")
titleCommand:append(GEMUI.Command.SEPARATOR)
titleCommandCommands.quit = titleCommand:append("Quit")

local fileCommand, fileCommandCommands = container1:append("File"), {}
fileCommandCommands.open = fileCommand:append("Open", {shortcut = "O"})
fileCommandCommands.info = fileCommand:append("Info/Rename")
fileCommandCommands.delete = fileCommand:append("Delete")
fileCommand:append(GEMUI.Command.SEPARATOR)
fileCommandCommands.newFolder = fileCommand:append("New folder")
fileCommandCommands.closeFolder = fileCommand:append("Close folder")
fileCommandCommands.closeWindow = fileCommand:append("Close window")

local viewCommand, viewCommandCommands = container1:append("View"), {}
viewCommandCommands.text = viewCommand:append("View as text", {type = GEMUI.Command.OPTION, selected = true, hint = "1"})
viewCommandCommands.icon = viewCommand:append("View as icons", {type = GEMUI.Command.OPTION, hint = "2"})
viewCommand:append(GEMUI.Command.SEPARATOR)
viewCommandCommands.name = viewCommand:append("Sort by name", {type = GEMUI.Command.OPTION, selected = true, hint = "3"})
viewCommandCommands.type = viewCommand:append("Sort by type", {type = GEMUI.Command.OPTION, hint = "4"})
viewCommandCommands.size = viewCommand:append("Sort by size", {type = GEMUI.Command.OPTION, hint = "5"})
viewCommandCommands.date = viewCommand:append("Sort by date", {type = GEMUI.Command.OPTION, hint = "6"})

function viewCommand:onActive(command)
	if command == viewCommandCommands.text then
		viewCommandCommands.icon.selected, viewCommandCommands.text.selected = false, true
	elseif command == viewCommandCommands.icon then
		viewCommandCommands.icon.selected, viewCommandCommands.text.selected = true, false
	end
end

local optionsCommand = container1:append("Options")
optionsCommand:append("Execute command")
optionsCommand:append(GEMUI.Command.SEPARATOR)
optionsCommand:append("Set background...")

--

GraphicsKit.border(GraphicsKit.TEAL)
function main()
	GraphicsKit.clear(GraphicsKit.AQUA)
	container1:draw(0, 0)
	IOKit.mouse.update()
end