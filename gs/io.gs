$IOKit:
	' mouse routines
	$mouse:
		let buffer, cur = 0, 0
		LEFT, MIDDLE, RIGHT = 1, -1, 4
		DEFAULT, WAIT, CROSSHAIR, FORBIDDEN, POINTER, TEXT, MOVE = 0, 1, 2, 3, 4, 5, 6
		func check(...):
			let m, button, isRepeat = System.peek(0x00FF86), ...
			if select("#", ...) == 0 then return m == 0 end
			if not isRepeat then return m == button and buffer == 1 else return m == button end
		func clear():
			System.poke(0x0FF86, 0)
		func cursor(address):
			cur = address or 0
		func inside(x1, y1, x2, y2):
			let x, y = System.peek(0x0FF84), System.peek(0x0FF85)
			return x >= Math.min(x1, x2) and x < Math.max(x1, x2) and y >= Math.min(y1, y2) and y < Math.max(y1, y2)
		func update():
			let x, y, m = System.peek(0x0FF84), System.peek(0x0FF85), System.peek(0x0FF86)
			buffer = (m > 0 and Math.min(buffer + 1, 2)) or 0
			System.poke(0x03FFB, 0)
			System.pal(1, 0)
			System.spr(224 + cur * 2, x - 5, y - 5, 0, 1, 0, 0, 2, 2)
			System.pal()
	' keyboard methods
	$keyboard:
		func check(key, isRepeat):
			return ((isRepeat and System.key) or System.keyp)(key)