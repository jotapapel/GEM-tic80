struct UIKit def
	LEFT, CENTRE, RIGHT = 0, 0.5, 1
end

prototype UIKit.Text def

	width, height = 0, 0
	style, lineHeight = coreKit.font.REGULAR, 1
	lines = {}
	
	function set(self, content)
		self.lines = {}
		string.gsub(string.format("%s\n", tostring(content)), "(.-)\n", function(line)
			local width, _ = coreKit.font.print(line, self.style)
			self.lines[#self.lines + 1] = {line, width, 8}
			self.width, self.height = math.max(self.width, width), self.height + (8 * self.lineHeight)
		end)
	end
	
	constructor(self, content, style, lineHeight)
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
			coreKit.graphics.rect(coreKit.graphics.FILL, x + math.floor((self.width - width) * align), y + (position - 1) * (height * self.lineHeight) + lineh, width, height, 7 + position % 8)
			coreKit.font.print(text, x + math.floor((self.width - width) * align), y + ((position - 1) * (height * self.lineHeight)) + lineh + 1, colour or 15, self.style)
		end
	end

end

prototype UIKit.Object def

	timestamp, parent = 0, nil
	x, y, width, height = 0, 0, 0, 0
	padding, border = {right = 0, top = 0, left = 0, bottom = 0}, {size = 0, colour = -1}
	background, colour = 15, 0
	hover, active, enabled = false, false, true
	onHover, onActive = nil, nil

	function setWidth(self, newWidth)
		self.width = math.max(0, newWidth - (self.border.size * 2) - self.padding.right - self.padding.left)
	end

	function getWidth(self)
		return self.border.size + self.padding.left + self.width + self.padding.right + self.border.size
	end
	
	function setHeight(self, newHeight)
		self.height = math.max(0, newHeight - (self.border.size * 2) - self.padding.top - self.padding.bottom)
	end
	
	function getHeight(self)
		return self.border.size + self.padding.top + self.height + self.padding.bottom + self.border.size
	end
	
	constructor(self, parent, properties)
		self.parent = parent
		if properties then self:set(properties) end
	end

	function update(self)
		if not self.parent and self.active and self.onActive and coreKit.mouse.check() then self:onActive() end
		self.hover = coreKit.mouse.inside(self.x, self.y, self.x + self:getWidth(), self.y + self:getHeight())
		self.active = self.hover and coreKit.mouse.check(coreKit.mouse.LEFT, true)
	end

end