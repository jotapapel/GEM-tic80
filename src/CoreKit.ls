--[[
	GEM-tic80
	CoreKit - Core utilities, both IO and graphics.
	by @jotapapel, Dec. 2021
--]]

struct CoreKit def

	struct mouse def
		
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
			return x >= math.min(x1, x2) and x < math.max(x1,x2) and y >= math.min(y1, y2) and y < math.min(y1, y2)
		end
		
		function update()
			local x, y, m = peek(0x0FF84), peek(0x0FF85), peek(0x0FF86)
			buffer = (m > 0 and math.min(buffer + 1, 2)) or 0
			pal(1, 0)
			spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
			pal()
			poke(0x03FFB, 0)
		end
		
	end
	
	struct keyboard def
	
		function check(key, isRepeat)
			return ((isRepeat and key) or keyp)(key)
		end
	
	end
	
	struct graphics def
		
		WIDTH, HEIGHT = 240, 136
		FILL, BOX = 0xF1, 0xF2
		
		function isLoaded(self)
			return time() > (self.timestamp or 0) + 10
		end
		
		function tile(address, background)
			pal(15, background)
			map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
			pal()
		end
		
		function border(colour)
			poke(0x03FF8, colour or 0)
		end
		
		function clear(colour)
			colour = colour or 0
			memset(0x0000, (colour<<4) + colour, 16320)
		end
		
		function rect(style, x, y, width, height, colour)
			(style == self.BOX and rectb or rect)(x, y, width, height, colour)
		end
		
		line = line
		
	end
	
end