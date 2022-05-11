--[[
	GEM-tic80
	DeviceKit - Input routines.
	by @jotapapel, Dec. 2021 - Jan. 2022
--]]

struct DeviceKit def

	struct mouse def
		
		local buffer, cur = 0, 0
		var LEFT, MIDDLE, RIGHT = 1, -1, 4
		var DEFAULT, WAIT, CROSSHAIR, FORBIDDEN, POINTER, TEXT, MOVE = 0, 1, 2, 3, 4, 5, 6
		
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
			System.pal(1, 0)
			System.spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
			System.pal()
			System.poke(0x03FFB, 0)
		end
		
	end
	
	struct keyboard def
	
		function check(key, isRepeat)
			return ((isRepeat and key) or keyp)(key)
		end
	
	end
	
end

--[[
	GEM-tic80
	DeviceKit - Input routines.
	by @jotapapel, Dec. 2021 - Jan. 2022
--]]

struct GraphicsKit def

	WIDTH, HEIGHT = 240, 136
	FILL, BOX = 0xF1, 0xF2
	
	function isLoaded(self)
		return time() > (self.timestamp or 0) + 10
	end
	
	function tile(address, background)
		System.pal(15, background)
		System.map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
		System.pal()
	end
	
	function border(colour)
		System.poke(0x03FF8, colour or 0)
	end
	
	function clear(colour)
		colour = colour or 0
		System.memset(0x0000, (colour<<4) + colour, 16320)
	end
	
	function rect(style, x, y, width, height, colour)
		(style == self.BOX and System.rectb or System.rect)(x, y, width, height, colour)
	end
	
	line = line
	
end