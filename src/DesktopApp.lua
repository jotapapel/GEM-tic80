setmetatable(_G, {__index = function(t, k) return k == "TIC" and rawget(t, "main") end})
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
	super = setmetatable(super or {}, {__index = _G, __newindex = function(_, key, value)
		local valueType, varType, varKey = type(value), key:match("^([~#@&!]?)(.-)$")
		if super and super[varKey] and #varType == 0 then varType = type(super[varKey]) elseif #varType == 0 then varType = nil end
		if varType and valueType ~= "nil" and (varType or self[varType]) ~= "function" and varType ~= "!" and (varType or self[varType]) ~= valueType then error(string.format("Type mismatch (%s expected, got %s).", varType or self[varType], valueType), 2) end
		rawset(target, varKey, value)
	end})
	setfenv(defn, super)()
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
		return table.strongdef({}, defn)
	end
	function prototype(arg1, arg2)
		local super, fn = arg2 and arg1, arg2 or arg1
		local prototype = setmetatable({super = super, get = get, set = set, hash = hash}, {__index = super, __call = create})
		return table.strongdef(prototype, fn, {self = prototype, super = super})
	end
end)
function pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end
FontKit = mud.struct(function()
	NORMAL = {address = 0, adjust = {[1] = "#*?%^mw", [-1] = "\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"}, width = 5}
	BOLD = {address = 112, adjust={[3] = "mw", [2] = "#", [1] = "*?^~", [-1] = "1%%+/<>\\{}IT", [-2] = "(),;%[%]`jl", [-3] = "!'%.:|i"}, width = 6}
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
GraphicsKit = mud.struct(function()
	WIDTH, HEIGHT = 240, 136
	FILL, BOX = 0xF1, 0xF2
	BLACK, WHITE = 0, 15
	IRON, STEEL, GREY, SILVER = 1, 12, 13, 14
	MAROON, RED = 2, 3
	GREEN, LIME = 4, 5
	NAVY, BLUE = 6, 7
	TEAL, AQUA = 8, 9
	GOLD, YELLOW = 10, 11
	function border(colour)
		poke(0x03FF8, colour or 0)
	end
	function clear(colour)
		colour = colour or 0
		memset(0x0000, (colour<<4) + colour, 16320)
	end
	function isLoaded(self)
		return time() > (self.timestamp or 0) + 10
	end
	function line(...)
		line(...)
	end
	function rect(style, x, y, width, height, colour)
		(style == self.BOX and rectb or rect)(x, y, width, height, colour)
	end
	function tile(address, background)
		pal(15, background)
		map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
		pal()
	end
end)
IOKit = mud.struct(function()
	mouse = mud.struct(function()
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
			return x >= math.min(x1, x2) and x < math.max(x1, x2) and y >= math.min(y1, y2) and y < math.max(y1, y2)
		end
		function update()
			local x, y, m = peek(0x0FF84), peek(0x0FF85), peek(0x0FF86)
			buffer = (m > 0 and math.min(buffer + 1, 2)) or 0
			poke(0x03FFB, 0)
			pal(1, 0)
			spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
			pal()
		end
	end)
	keyboard = mud.struct(function()
		function check(key, isRepeat)
			return ((isRepeat and key) or keyp)(key)
		end
	end)
end)
GEMUI = mud.struct(function()
	LEFT, CENTRE, RIGHT = 0, 0.5, 1
	TOP, MIDDLE, BOTTOM = 0, 0.5, 1
	RELATIVE, ABSOLUTE = 0xD1, 0xD2
end)
GEMUI.Text = mud.prototype(function()
	width, height = 0, 0
	style, lineHeight = FontKit.NORMAL, 1
	lines = {}
	function constructor(self, content, style, lineHeight)
		self.style, self.lineHeight = style or self.style, lineHeight or self.lineHeight
		self:setContent(content)
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
			local align, text, width, height = align or GEMUI.LEFT, table.unpack(line)
			local lineh = math.floor((height * (self.lineHeight - 1)) / 2)
			if totalHeight + height + lineh * 2 <= self.height then totalHeight = totalHeight + height + (lineh * 2) else break end
			if width > self.width then text, width = adjust(self.width, text, self.style) end
			if _DEBUG then GraphicsKit.rect(GraphicsKit.FILL, x + math.floor((self.width - width) * align), y + (position - 1) * (height * self.lineHeight) + lineh, width, height, 7 + position % 8) end
			FontKit.print(text, x + math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh + 1, colour or 15, self.style)
		end
	end
	function setContent(self, content)
		self.lines = {}
		string.gsub(string.format("%s\n", tostring(content)), "(.-)\n", function(line)
			local width, _ = FontKit.print(line, self.style)
			self.lines[#self.lines + 1] = {line, width, 8}
			self.width, self.height = math.max(self.width, width), self.height + (8 * self.lineHeight)
		end)
	end
end)
GEMUI.Object = mud.prototype(function()
	x, y, width, height = 0, 0, 0, 0
	background, colour = GraphicsKit.WHITE, GraphicsKit.BLACK
	padding, border, align, style = {right = 0, top = 0, left = 0, bottom = 0}, {size = 0, colour = GraphicsKit.BLACK}, {horizontal = GEMUI.CENTRE, vertical = GEMUI.MIDDLE}, FontKit.NORMAL
	position = GEMUI.RELATIVE
	enabled, hover, active = true, false, false
	function constructor(self, properties)
		self.timestamp = time()
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
end)
GEMUI.Container = mud.prototype(function()
	width, height = 0, 0
	display, padding, separation = GEMUI.RELATIVE, {horizontal = 0, vertical = 0}, 0
	enabled, overflow = true, false
	elements = {}
	function constructor(self, width, height, properties)
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
end)
GEMUI.Button = mud.prototype(GEMUI.Object, function()
	padding, border = {right = 9, top = 2, left = 9, bottom = 2}, {size = 2, colour = GraphicsKit.BLACK}
	style = FontKit.BOLD
	function constructor(self, label, properties)
		super.constructor(self, properties)
		self:setContent(label, self.style)
	end
	function draw(self)
		super.draw(self, self.active and GraphicsKit.BLACK, self.active and GraphicsKit.WHITE)
	end
end)
GEMUI.Command = mud.prototype(GEMUI.Object, function()
	NAME, SEPARATOR ,OPTION = 0xF1, 0xF2, 0xF3
	padding = {right = 5, top = 1, left = 5, bottom = 1}
	style, align = FontKit.NORMAL, {horizontal = GEMUI.LEFT, vertical = GEMUI.MIDDLE}
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
	function constructor(self, label, properties, hasCommandView)
		super.constructor(self, properties)
		self:setContent(label, self.style)
		if hasCommandView then self.commandView = GEMUI.CommandView(0, 0, {parent = self, iterator = iterator}) end
	end
	function append(self, arg1, ...)
		local command, flag, option = self.commandView:append(arg1, {padding = {right = 10, top = 1, left = 10, bottom = 1}}), ...
		if arg1 == self.SEPARATOR then command.content, command.flag, command.height = nil, arg1, 1 end
		if flag == self.OPTION then command.selected, command.flag = option, flag end
		self.commandView:setSize(math.max(self.commandView:getWidth(), command:getWidth()), self.commandView:getHeight() + command:getHeight())
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
			FontKit.print(string.char(32 - 8), self.x + 3, self.y + self.padding.top + 1, active and GraphicsKit.WHITE or GraphicsKit.BLACK, FontKit.BOLD)
		end
		if self.commandView and self:isActiveCommand() then self.commandView:draw(self.x + 1, self.y + self:getHeight() + 1) end
		if self.hint then
			local w = FontKit.print(self.hint, FontKit.BOLD) + 4
			if _DEBUG then GraphicsKit.rect(GraphicsKit.FILL, self.x + self:getWidth() - w, self.y + self.padding.top, 11, 8, GraphicsKit.AQUA) end
			FontKit.print(self.hint, self.x + self:getWidth() - w, self.y + self.padding.top + 1, active and GraphicsKit.WHITE or GraphicsKit.BLACK, FontKit.BOLD)
		end
	end
	function shortcut(self, key)
		self.hint = string.format("^%s", key)
		return self
	end
	function update(self)
		if self.hover and self.commandView and self.commandView:size() > 0 then self.parent.activeCommand = self end
		if self.flag ~= self.SEPARATOR then super.update(self) end
	end
end)
GEMUI.CommandView = mud.prototype(GEMUI.Container, function()
	overflow = true
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
end)
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
fileCommandCommands.open = fileCommand:append("Open"):shortcut("A")
fileCommandCommands.info = fileCommand:append("Info/Rename")
fileCommandCommands.delete = fileCommand:append("Delete")
fileCommand:append(GEMUI.Command.SEPARATOR)
fileCommandCommands.newFolder = fileCommand:append("New folder")
fileCommandCommands.closeFolder = fileCommand:append("Close folder")
fileCommandCommands.closeWindow = fileCommand:append("Close window")
local viewCommand, viewCommandCommands = container1:append("View"), {}
viewCommandCommands.text = viewCommand:append("View as text", GEMUI.Command.OPTION, true)
viewCommandCommands.icon = viewCommand:append("View as icons", GEMUI.Command.OPTION)
viewCommand:append(GEMUI.Command.SEPARATOR)
viewCommandCommands.name = viewCommand:append("Sort by name", GEMUI.Command.OPTION, true)
viewCommandCommands.type = viewCommand:append("Sort by type", GEMUI.Command.OPTION)
viewCommandCommands.size = viewCommand:append("Sort by size", GEMUI.Command.OPTION)
viewCommandCommands.date = viewCommand:append("Sort by date", GEMUI.Command.OPTION)
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
GraphicsKit.border(GraphicsKit.NAVY)
function main()
	GraphicsKit.clear(GraphicsKit.BLUE)
	container1:draw(0, 0)
	IOKit.mouse.update()
end