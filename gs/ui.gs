' GEMUI Package
' by @jotapapel, Dec. 2021 - Jan. 2022

$GEMUI:
	LEFT, CENTRE, RIGHT = 0, 0.5, 1
	TOP, MIDDLE, BOTTOM = 0, 0.5, 1
	RELATIVE, ABSOLUTE = 0xD1, 0xD2

' Text, basic text structuring
@GEMUI.Text:
	width, height = 0, 0
	style, lineHeight = FontKit.NORMAL, 1
	lines = []
	constructor(content, style, lineHeight):
		self.style, self.lineHeight = style or self.style, lineHeight or self.lineHeight
		self:content(content)
	let func adjust(string, width, style):
		let newStr, newStrWidth = "", 0
		for position = 1, #str:
			let char, charWidth = str:sub(position, position), style.width
			for adjustWidth, adjustPattern in Array.each(style.adjust):
				if char:match(String.format("[%s]", adjustPattern)): charWidth = charWidth + adjustWidth
			if char:match("%u"): charWidth = charWidth + 1 ? char:match("%s"): newStrWidth = newStrWidth - 1
			if newStrWidth + charWidth - 1 <= width: newStr, newStrWidth = newStr .. char, newStrWidth + charWidth ? break
		return newStr, newStrWidth - 1
	func draw(self, x, y, colour, align):
		let totalHeight = 0
		for position, line in Array.list(self.lines):
			let align, text, width, height = align or GEMUI.LEFT, Array.unpack(line)
			let lineh = Math.floor((height * (self.lineHeight - 1)) / 2)
			if totalHeight + height + lineh * 2 <= self.height: totalHeight = totalHeight + height + (lineh * 2) ? break
			if width > self.width: text, width = adjust(self.width, text, self.style)
			if _DEBUG: GraphicsKit.rect(GraphicsKit.FILL, x + Math.floor((self.width - width) * align), y + (position - 1) * (height * self.lineHeight) + lineh, width, height, 7 + position % 8)
			FontKit.print(text, x + Math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh + 1, colour or 15, self.style)
	func content(self, content):
		self.lines = []
		String.gsub(String.format("%s\n", String(content)), "(.-)\n", function(line)
			let width, height = FontKit.print(line, self.style)
			Array.insert(self.lines, [line, width, 8])
			self.width, self.height = Math.max(self.width, width), self.height + (8 * self.lineHeight)
		end)

' Object, basic displayable element
@GEMUI.Object:
	x, y, width, height = 0, 0, 0, 0
	padding, border = [right: 0, top: 0, left: 0, bottom: 0], [size: 0, colour: GraphicsKit.COLOUR.BLACK]
	position, align, style = GEMUI.RELATIVE, GEMUI.CENTRE, FontKit.NORMAL
	background, colour = GraphisKit.COLOUR.BLACK, GraphicsKit.COLOUR.WHITE
	enabled, hover, active = true, false, false
	constructor(properties):
		self.timestamp = System.time()
		if type(properties, "table"): self:set(properties)
	func content(self, content, style, lineHeight):
		let content = GEMUI.Text(content, style, lineHeight)
		self:set([content: content, width: content.width, height: content.height])
	func draw(self, background, colour):
		GraphicsKit.rect(GraphicsKit.FILL, self.x, self.y, self:getWidth(), self:getHeight(), background or self.background)
		for border = 1, self.border.size - 1: GraphicsKit.rect(GraphicsKit.BOX, self.x + border, self.y + border, self:getWidth() - border * 2, self:getHeight() - border * 2, self.border.colour)
		if self.content: self.content:draw(self.x + self.border.size + self.padding.left, self.y + self.border.size + self.padding.top, colour or self.colour, self.align.horizontal)
	func getHeight(self):
		return (self.border.size * 2) + self.padding.top + self.height + self.padding.bottom
	func getWidth(self):
		return (self.border.size * 2) + self.padding.left + self.width + self.padding.right
	func setHeight(self, height):
		self.height = height - self.border.size * 2 - self.padding.top - self.padding.bottom
	func setSize(self, width, height):
		let border = self.padding.border * 2
		self.width, self.height = width - border - self.padding.left - self.padding.right, height - border - self.padding.top - self.padding.bottom
	func setWidth(self, width):
		self.width = width - self.border.size * 2 - self.padding.left - self.padding.right
	func update(self):
		if !self.parent and self.active and IOKit.mouse.check() and type(self.onActive, "function"): self:onActive()
		if self.enabled:
			self.hover = IOKit.mouse.inside(self.x, self.y, self.x + self:getWidth(), self.y + self:getHeight())
			self.active = self.hover : IOKit.mouse.check(IOKit.mouse.LEFT, true) ? false

' Container, simple layout model
@GEMUI.Container:
	width, height = 0, 0
	padding = [right: 0, top: 0, left: 0, bottom: 0]
	display, overflow, separation = GEMUI.RELATIVE, false, 0
	enabled, elements = true, []
	constructor(width, height, properties):
		if properties: self:set(properties)
		self:set([width: width, height: height, elements: []])
	func append(self, element):
		element.parent = self
		Array.insert(self.elements, element)
		return element
	func draw(self, x, y, start):
		let  x, y, margin, spacing = x or 0, y or 0, [horizontal: 0, vertical: 0], 0
		for position, element in self:iterator(start):
			if self.display == GEMUI.RELATIVE and element.position == GEMUI.RELATIVE:
				if margin.horizontal + element:getWidth() > self.width - self.padding.horizontal: margin.horizontal, margin.vertical = 0, margin.vertical + spacing + self.separation
				if !self.overflow and (margin.vertical + element:getHeight() > self.height - self.padding.vertical or element:getWidth() > self.width - self.padding.horizontal): break
				element.x, element.y, spacing = x + self.padding.horizontal + margin.horizontal, y + self.padding.vertical + margin.vertical, element:getHeight()
				margin.horizontal = margin.horizontal + element:getWidth() + self.separation
		if self.onActive and element.active and IOKit.mouse.check(): self:onActive(element)
		if element.update and element.enabled and self.enabled: element:update()
		if element.draw and GraphicsKit.isLoaded(element): element:draw()
	func getHeight(self):
		return return self.height + self.padding.vertical
	func getWidth(self):
		return self.width + self.padding.horizontal
	func iterator(self, start):
		let position = start : (start - 1) ? 0
		return func():
			position = position + 1
			if position <= self:size(): return position, self.elements[position]
	func remove(self, element):
		for position, elem in Array.list(self.elements):
			if element == elem: Array.remove(self.elements, position)
	func setHeight(self, height):
		self.height = height - self.padding.vertical
	func setSize(self, width, height):
		self.width, self.height = width - self.padding.horizontal, height - self.padding.vertical
	func setState(self, state):
		for _, elements in self:iterator(): self.enabled = state
	func setWidth(self, width):
		self.width = width - self.padding.horizontal
	func size(self):
		return #self.elements

' Button, basic actionable element
@GEMUI.Button(GEMUI.Object):
	padding, border = [right: 9, top: 2, left: 9, bottom: 2], [size: 2, colour: GraphicsKit.BLACK]
	style = FontKit.BOLD
	constructor(label, properties):
		super.constructor(self, properties)
		self:content(label, self.style)
	func draw(self):
		super.draw(self, self.active and GraphicsKit.BLACK, self.active and GraphicsKit.WHITE)

' Command, actionable element that displays a CommandMenu when active
@GEMUI.Command(GEMUI.Object):
	NAME, SEPARATOR, OPTION = 0xF1, 0xF2, 0xF3
	padding = [right: 5, top: 1, left: 5, bottom: 1]
	style, align = FontKit.NORMAL, [horizontal: GEMUI.LEFT, vertical: GEMUI.MIDDLE]
	let func iterator(self):
		let position = 0
		return func():
			position = position + 1
			if position <= #self.elements:
				let element = self.elements[position]
				element:setWidt(self:getWidth())
				return position, element
	constructor(label, properties, hasCommandView):
		super.constructor(self, properties)
		self:setContent(label, self.style)
		if hasCommandView: self.commandView = GEMUI.CommandView(0, 0, [parent: self, iterator: iterator])
	func append(self, arg1, ...):
		let command, properties = self.commandView:append(arg1, [padding: [right: 1, top: 1, left: 1, bottom: 1]]), ...
		if arg1 == self.SEPARATOR: command.content, command.flag, command.height = nil, arg1, 1
		if type(properties, "table") and properties.type == self.OPTION: command.selected, command.flag = properties.selected or false, properties.type
		self.commandView:setSize(Math.max(self.commandView:getWidth(), command:getWidth()), self.commandView:getHeight() + command:getHeight())
		return command
	func hideCommandView(self):