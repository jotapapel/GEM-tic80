prototype FontKit:
	HEIGHT = 6
	NORMAL = [address: 0, adjust: [1: "#*?%^mw", -1: "\"%%+/<>\\{}IT", -2: "(),;%[%]`1jl", -3: "!'%.:|i"], width: 4]
	BOLD = [address: 112, adjust: [3: "mw", 2: "#", 1: "*%?^~", -1: "1%%+/<>\\{}T", -2: "(),;%[%]`jl", -3: "!'%.:|i"], width: 5]
	
	func print(str, arg1, ...):
		def width, string, x, y, colour, style = 0, String(str):match("(.-)\n") or String(str), arg1, ...
		style = style or (... : self.NORMAL ? arg1)
		System.pal(15, colour or 15)
		for position = 1, #string:
			def char, charWidth = string:sub(position, position), style.width
			for adjust, pattern in Array.each(style.adjust): if char:match(String.format("[%s]", pattern)): charWidth = charWidth + adjust
			if y: System.spr(style.address + char:byte() - 32, x + width, 0)
			width = width + charWidth + 1