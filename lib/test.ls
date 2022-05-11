prototype Object def
	numb x, y, width, height
	numb background, colour = GraphicsKit.WHITE, GraphicsKit.BLACK
	tbl padding, border, align = {right = 0, top = 0, left = 0, bottom = 0}, {size = 0, colour = GraphicsKit.BLACK}, 
	any position, align, style = GEMUI.RELATIVE, {horizontal = GEMUI.CENTRE, vertical = GEMUI.MIDDLE}, FontKit.NORMAL
	bool enabled, hover, active = true, false, false

	constructor(properties)
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
end