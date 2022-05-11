@GraphicsKit:
	COLOUR = [BLACK: 0, WHITE: 15, IRON: 1, STEEL: 12, GREY: 13, SILVER: 14, MAROON: 2, RED: 3, GREEN: 4, LIME: 5, NAVY: 6, BLUE: 7, TEAL: 8, AQUA: 9, GOLD: 10, YELLOW: 11]
	FILL, BOX = 0xF1, 0xF2
	WIDTH, HEIGHT = 240, 136
	func border(colour):
		System.poke(0x03FF8, colour or 0)
	func clear(colour):
		colour = colour or 0
		System.memset(0x0000, (colour<<4) + colour, 16320)
	func line(...):
		System.line(...)
	func ready(self):
		return System.time() > (self.timestamp or 0) + 10
	func rect(style, x, y, width, height, colour):
		(style == self.BOX and System.rectb or System.rect)(x, y, width, height, colour)
	func tile(address, background):
		System.pal(15, background)
		System.map(0, 0, 30, 17, 0, 0, 0, 1, function() return address end)
		System.pal()