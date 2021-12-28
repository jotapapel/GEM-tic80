--[[
	GEM-tic80
	FontKit - Text printing methods.
	by @jotapapel, Dec. 2021
--]]

struct FontKit def

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

end