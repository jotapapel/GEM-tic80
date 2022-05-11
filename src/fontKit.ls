--[[
	GEM-tic80
	FontKit - Text printing methods.
	by @jotapapel, Dec. 2021
--]]

local struct FontKit def

	var NORMAL = {address = 0, adjust = {[1] = "#*?%^mw", [-1] = "\"%%+/<>\\{}IT", [-2] = "(),;%[%]`1jl", [-3] = "!'%.:|i"}, width = 5}
	var BOLD = {address = 112, adjust={[3] = "mw", [2] = "#", [1] = "*?^~", [-1] = "%%+/<>\\{}IT", [-2] = "()1,;%[%]`jl", [-3] = "!'%.:|i"}, width = 6}
	var HEIGHT = 6
	
	function print(str, arg1, ...)
		local width, str, x, y, colour, style = 0, String.match(String(str), "(.-)\n") or String(str), arg1, ...
		colour, style = colour or 0, style or ((... and self.NORMAL) or arg1)
		System.pal(15, colour)
		for position = 1, #str do
			local char, charWidth = str:sub(position, position), style.width
			for adjust, pattern in Array.each(style.adjust) do if char:match(String.format("[%s]", pattern)) then charWidth = charWidth + adjust end end
			if y then System.spr(style.address + char:byte() - 32, x + width, y, 0) end
			width = width + charWidth
		end
		System.pal()
		return width - 1, self.HEIGHT
	end

end