--[[
  User Interface Kit (requires object.lua)
  created by @jotapapel, 2021
]]--

UIKit = {}
UIKit.LEFT, UIKit.CENTRE, UIKit.RIGHT = 0, .5, 1
UIKit.RELATIVE, UIKit.ABSOLUTE = 0xD1, 0xD2

UIKit.Text = object.prototype(function()
	width, height = 0, 0
	style, lineHeight = coreKit.font.REGULAR, 1
	lines = {}

	function setWidth(self, width) self.width = math.max(0, width) end
	function setHeight(self, height) self.height = math.max(0, height) end

	function setContent(self, content)
		self.lines = {}
		string.gsub(string.format("%s\n", tostring(content)), "(.-)\n", function(line)
			local width, height = coreKit.font.print(line, self.style)
			table.insert(self.lines, {line, width, height})
			self.width = math.max(self.width, width)
		end);
		self.height = (coreKit.font.HEIGHT * self.lineHeight) * #self.lines
	end

	function constructor(self, content, style, lineHeight)
		self.style, self.lineHeight = style or self.style, lineHeight or self.lineHeight
		self:setContent(content)
	end

	local function adjust(width, str, style)
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
		coreKit.graphics.rect(coreKit.graphics.FILL, x, y, self.width, self.height, 7)
		for position, line in ipairs(self.lines) do
			local align, text, width, height = align or UIKit.LEFT, table.unpack(line)
			local lineh = math.floor((height * (self.lineHeight - 1)) / 2)
			if totalHeight + height + lineh * 2 <= self.height then totalHeight = totalHeight + height + (lineh * 2) else break end
			if width > self.width then text, width = adjust(self.width, text, self.style) end
			coreKit.graphics.rect(coreKit.graphics.FILL, x, y + (position - 1) * (height * self.lineHeight), self.width, height + lineh * 2, 7 + position % 8)
			coreKit.font.print(text, x + math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh, colour or 15, self.style)
		end
	end
end);

UIKit.Object = object.prototype(function()
	timestamp, parent = nil, nil
	x, y, width, height = 0, 0, 0, 0
	position = UIKit.RELATIVE
	enabled, active, hover = true, false, false
	onHover, onActive = nil, nil

	function disable(self) self.enabled = false end
	function enable(self) self.enabled = true end
	function getWidth(self) return self.width end
	function getHeight(self) return self.height end

	function constructor(self, properties)
		self.timestamp = time()
		if properties then self:set(properties) end
	end

	function update(self)
		if not self.parent and self.active and coreKit.mouse.check() and self.onActive then self:onActive() end
		if self.enabled then
			self.hover = coreKit.mouse.inside(self.x, self.y, self.x + self:getWidth(), self.y + self:getHeight())
			self.active = self.hover and coreKit.mouse.check(coreKit.mouse.LEFT, true)
		end
	end
end);

UIKit.Panel = object.prototype(function()
	timestamp, parent = nil, nil
	width, height = 0, 0
	display, padding, separation = UIKit.RELATIVE, {horizontal = 0, vertical = 0}, 0
	enabled, overflow, elements = true, false, {}

	function getWidth(self) return self.width + self.padding.horizontal end
	function getHeight(self) return self.height + self.padding.vertical end
	function setWidth(self, width) self.width = width - self.padding.horizontal end
	function setHeight(self, height) self.height = height - self.padding.vertical end
	function setSize(self, width, height) self.width, self.height = width - self.padding.horizontal, height - self.padding.vertical end
	function size(self) return #self.elements end
	function disable(self) for _, element in self:iterator() do element:disable() end end
	function enable(self) for _, element in self:iterator() do element:enable() end end

	function append(self, element)
		element.parent = self
		table.insert(self.elements, element)
		return element
	end

	function remove(self, element)
		for position, elem in ipairs(self.elements) do
			if element == elem then table.remove(self.elements, position) end
		end
	end

	function constructor(self, ...)
		local width, height = ...
		self:set({elements = {}, width = width or self.width, height = height or self.height})
	end

	function iterator(self, start)
		local position = (start and start - 1) or 0
		return function()
			position = position + 1
			if position <= #self.elements then return position, self.elements[position] end
		end
	end

	function draw(self, x, y, start)
		local x, y, margin, spacing = x or 0, y or 0, {horizontal = 0, vertical = 0}, 0
		for position, element in self:iterator(start) do
			if self.display == UIKit.RELATIVE and element.position == UIKit.RELATIVE then
				if margin.horizontal + element:getWidth() > self.width - self.padding.horizontal then margin.horizontal, margin.vertical = 0, margin.vertical + spacing + self.separation end
				if not self.overflow and (margin.vertical + element:getHeight() > self.height - self.padding.vertical or element:getWidth() > self.width - self.padding.horizontal) then break end
				element.x, element.y, spacing = x + self.padding.horizontal + margin.horizontal, y + self.padding.vertical + margin.vertical, element:getHeight()
				margin.horizontal = margin.horizontal + element:getWidth() + self.separation
			end
			if self.onActive and element.active and coreKit.mouse.check() then self:onActive(element) end
			if element.update and element.enabled and self.enabled then element:update() end
			if element.draw and coreKit.graphics.isLoaded(element) then element:draw() end
		end
	end
end);

UIKit.Label = object.prototype(UIKit.Object, function()
	padding, border = {right = 0, top = 0, left = 0, bottom = 0}, 0
	style, align = coreKit.font.REGULAR, {horizontal = UIKit.CENTRE, vertical = UIKit.MIDDLE}
	colour, background = 0, 15

	function setWidth(self, width) self.width = width - self.border * 2 - self.padding.left - self.padding.right; self.label.width = self.width end
	function setHeight(self, height) self.height = height - self.border * 2 - self.padding.top - self.padding.bottom; self.label.height = self.height end
	function getWidth(self) return self.border * 2 + self.padding.left + self.width + self.padding.right end
	function getHeight(self) return self.border * 2 + self.padding.top + self.height + self.padding.bottom end

	function constructor(self, label, properties)
		if properties then self:set(properties) end
		local label = UIKit.Text(label, self.style, self.separation)
		super.constructor(self, {label = label, width = label.width, height = label.height})
	end

	function draw(self)
		if self.background > -1 then coreKit.graphics.rect(coreKit.graphics.FILL, self.x, self.y, self:getWidth(), self:getHeight(), self.background) end
		local marginh, marginv = math.floor((self.width - self.label.width) * self.align.horizontal), math.floor((self.height - self.label.height) * self.align.horizontal)
		self.label:draw(self.x + self.border + self.padding.left + marginh, self.y + self.border + self.padding.top + marginh, self.colour, self.align.horizontal)
		for i = 0, self.border - 1 do coreKit.graphics.rect(coreKit.graphics.BOX, self.x + i, self.y + i, self:getWidth() - (i * 2), self:getHeight() - (i * 2), 0) end
	end
end);

UIKit.Button = object.prototype(UIKit.Label, function()
	padding, border = {right = 12, top = 2, left = 12, bottom = 2}, 2
	style = coreKit.font.BOLD

	function constructor(self, arg1, arg2)
		if arg2 then self:set(arg2) end
		super.constructor(self, arg1)
	end

	function draw(self)
		if self.active then self.colour, self.background = 15, 0 else self.colour, self.background = 0, 15 end
		super.draw(self)
	end
end);

UIKit.Command = object.prototype(UIKit.Label, function()
	NAME, SEPARATOR, OPTION = 0xF1, 0xF2, 0xF3

	padding = {right = 5, top = 2, left = 5, bottom = 2}
	style, align = coreKit.font.REGULAR, {horizontal = UIKit.LEFT, vertical = UIKit.MIDDLE}
	menu, flag = nil, nil

	function isActiveCommand(self)
		return self.parent.activeCommand == self
	end

	function hideCommandMenu(self)
		self.parent.activeCommand = nil
	end

	function append(self, arg1, ...)
		local command, flag, option = UIKit.Command(arg1, {padding = {right = 20, top = 2, left = 12, bottom = 2}}), ...
		if arg1 == self.SEPARATOR then command.label, command.flag, command.height = UIKit.Text(""), arg1, 1 end
		if flag == self.OPTION then command.selected, command.flag = option, flag end
		self.commandView:setSize(math.max(self.menu:getWidth(), command:getWidth()), self.menu:getHeight() + command:getHeight())
		return self.menu:append(command)
	end

	function update(self)
		if self.hover and self.commandView:size() > 0 then self.parent.activeCommand = self end
		if self.flag ~= self.SEPARATOR then super.update(self) end
	end

	function draw(self)
		if self.hover or self.active or self:isActiveCommand() then self.colour, self.background = 15, 0 else self.colour, self.background = 0, 15 end
		super.draw(self)
		if self.flag == self.SEPARATOR then coreKit.graphics.line(self.x, self.y + self.padding.top, self.x + self:getWidth(), self.y + self.padding.top, 0) end
		if self.flag == self.OPTION and self.selected then coreKit.font.print(string.char(32 - 7), self.x + 2, self.y + self.padding.top, self.colour, coreKit.font.BOLD) end
		if self.commandView:size() > 0 and self:isActiveCommand() then self.menu:draw(self.x, self.y + self:getHeight()) end
	end
end);

UIKit.CommandView = object.prototype(UIKit.Panel, function()
	activeCommand = nil

	function onActive(self, command)
		self.activeCommand = command
	end

	function append(self, label, properties)
		local command = UIKit.Command(name, properties)
		command.commandView = UIKit.CommandView()
		return super.append(self, command)
	end

	function draw(self)
		coreKit.graphics.rect(coreKit.graphics.FILL, 0, 0, self:getWidth(), self:getHeight(), 15)
		coreKit.graphics.line(0, self:getHeight(), self:getWidth(), self:getHeight(), 0)
		super.draw(self, 0, 0)
	end
end);

--[[UIKit.CommandMenu = object.prototype(UIKit.Panel, function()
	function onActive(self, command)
		if command.onActive then command.onActive() elseif self.parent.onActive then self.parent:onActive(command) end
		if command.flag ~= UIKit.Command.OPTION then self.parent:hideCommandMenu() end
	end

	function constructor(self, parent)
		self.parent = parent
		super.constructor(self)
	end

	function iterator(self, start)
		local position = (start and start - 1) or 0
		return function()
			position = position + 1
			if position <= #self.elements then self.elements[position]:setWidth(self:getWidth()) return position, self.elements[position] end
		end
	end

	function draw(self, x, y)
		if x + self:getWidth() > coreKit.graphics.WIDTH then x = coreKit.graphics.WIDTH - self:getWidth() - 7 end
		super.draw(self, x + 1, y + 1)
		coreKit.graphics.rect(coreKit.graphics.BOX, x, y, self:getWidth() + 2, self:getHeight() + 2, 0)
		if coreKit.mouse.check(coreKit.mouse.LEFT) and self.parent:isActiveCommand() and not coreKit.mouse.inside(x, y, x + self:getWidth(), y+ self:getHeight()) then self.parent:hideCommandMenu() end
	end
end);--]]

UIKit.MenuBar = object.prototype(UIKit.Panel, function()
	width, height = coreKit.graphics.WIDTH - 5, 10
	padding = {horizontal = 5, vertical = 0}
	activeCommand = nil

	function onActive(self, command)
		self.activeCommand = command
	end

	function appendName(self, name)
		local command = UIKit.Command(name)
		command.menu = UIKit.CommandMenu(command)
		return self:append(command)
	end

	function appendTitle(self, title)
		local command = UIKit.Command(title, {style = coreKit.font.BOLD, position = UIKit.ABSOLUTE})
		command.x, command.y , command.menu = coreKit.graphics.WIDTH - self.padding.horizontal - command:getWidth(), self.padding.vertical, UIKit.CommandMenu(command)
		return self:append(command)
	end

	function constructor(self)
		super.constructor(self)
		local command = UIKit.Label("00:00", {style = coreKit.font.BOLD, position = UIKit.ABSOLUTE, padding = {right = 5, top = 2, left = 5, bottom = 2}})
		command.x, command.y = coreKit.graphics.WIDTH - command:getWidth(), self.padding.vertical
		--self:append(command)
	end

	function draw(self)
		coreKit.graphics.rect(coreKit.graphics.FILL, 0, 0, self:getWidth(), self:getHeight(), 15)
		coreKit.graphics.line(0, self:getHeight(), self:getWidth(), self:getHeight(), 0)
		super.draw(self, 0, 0)
	end
end);

UIKit.AlertBox = object.prototype(UIKit.Panel, function()
	width, height = coreKit.graphics.WIDTH - 40, coreKit.graphics.HEIGHT - 40
	padding = {horizontal = 5, vertical = 5}
	separation = 2

	function onActive(self, element)
		self.parent:dismissAlert()
	end

	function iterator(self, start)
		local position = (start and start - 1) or 0
		return function()
			position = position + 1
			if position <= #self.elements then
				local element = self.elements[position]
				if element.prototype ~= UIKit.Button then element:setWidth(self:getWidth() - 20) end
				return position, element
			end
		end
	end

	function constructor(self, primary, secondary)
		super.constructor(self)
		self.okButton = self:append(UIKit.Button("OK"))
		self.okButton.position = UIKit.ABSOLUTE
		self:append(UIKit.Label(primary, {padding = {right = 6, top = 6, left = 6, bottom = 0}, style = coreKit.font.BOLD, separation = 1.5}))
		self:append(UIKit.Label(secondary, {padding = {right = 6, top = 0, left = 6, bottom = 0}, separation = 1.5}))
	end

	function draw(self)
		local x, y = (coreKit.graphics.WIDTH - self:getWidth()) / 2, (coreKit.graphics.HEIGHT - self:getHeight()) / 2
		self.okButton.x, self.okButton.y = (coreKit.graphics.WIDTH - self.okButton:getWidth()) / 2, y + self:getHeight() - (self.padding.vertical * 2) - self.okButton:getHeight()
		coreKit.graphics.rect(coreKit.graphics.FILL, x, y, self:getWidth(), self:getHeight(), 15)
		super.draw(self, x + 5, y + 5)
		coreKit.graphics.rect(coreKit.graphics.BOX, x, y, self:getWidth(), self:getHeight(), 0)
		for i = 0, 1 do coreKit.graphics.rect(coreKit.graphics.BOX, x + 3 + i, y + 3 + i, self:getWidth() - (i * 2) - 6, self:getHeight() - (i * 2) - 6, 0) end
	end
end);

UIKit.Icon = object.prototype(UIKit.Object, function()
	colour = 0
	icon, label = 256, UIKit.Text("DUMMY", coreKit.font.REGULAR)

	function constructor(self, icon, label, drive)
		self.icon, self.label, self.drive = icon, UIKit.Text(label, coreKit.font.REGULAR),  drive or 0
		self.width, self.height = 40, self.label.height + 16
	end

	function draw(self)
		local marginh = math.floor((self:getWidth() - self.label.width) * UIKit.CENTRE)
		coreKit.graphics.rect(coreKit.graphics.FILL, self.x, self.y, self:getWidth(), self:getHeight(), 8)
		pal(3, 15)
		spr(self.icon, self.x + math.ceil((self:getWidth() - 16) / 2), self.y, 1, 1, 0, 0, 2, 2)
		pal()
		coreKit.graphics.rect(coreKit.graphics.FILL, self.x, self.y + 14, self:getWidth(), 8, 15)
		spr(288 + self.drive, self.x + math.ceil((self:getWidth() - 16) / 2) + 3, self.y + 3, 1)
		self.label:draw(self.x + marginh, self.y + 15, self.colour, UIKit.CENTRE)
	end
end);

UIKit.Window = object.prototype(UIKit.Panel, function()

	function constructor(self)
		super.constructor(self)
		self.width, self.height = 240 - 16, 126 - 16
		self.closeButton = UIKit.Button(string.char(32 - 12), {border = 1, padding = {right = 2, top = 2, left = 2, bottom = 2}})
		self:append(self.closeButton)
		self.titleBar = UIKit.Label("C:\\GEMAPPS\\*.*", {style = coreKit.font.BOLD, padding = {right = 5, top = 3, left = 5, bottom = 3}, background = -1, colour = 0})
		self.titleBar:setWidth(self.width - 24)
		self:append(self.titleBar)
		self.maximizeButton = UIKit.Button(string.char(32 - 11), {border = 1, padding = {right = 2, top = 2, left = 2, bottom = 2}})
		self:append(self.maximizeButton)
	end

	function draw(self, x, y)
		coreKit.graphics.rect(coreKit.graphics.FILL, x + 1, y + 1, self:getWidth(), self:getHeight(), 0)
		coreKit.graphics.rect(coreKit.graphics.FILL, x, y, self:getWidth(), self:getHeight(), 15)
		super.draw(self, x, y)
		coreKit.graphics.line(x, y + 11, x + self:getWidth(), y + 11, 0)
		coreKit.graphics.line(x, y + 11 + 12, x + self:getWidth(), y + 11 + 12, 0)
		coreKit.graphics.line(x + self:getWidth() - 12, y + 11 + 12, x + self:getWidth() - 12, y + self:getHeight(), 0)
		coreKit.graphics.rect(coreKit.graphics.BOX, x, y, self:getWidth(), self:getHeight(), 0)
	end
end);
