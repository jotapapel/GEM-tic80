Object = prototype(nil, function()
	x, y = 0, 0
	constructor = function(self, x, y)
		self.x, self.y = x, y
	end
	locate = function(self)
		print(self.x, self.y)
	end
end)
local objectIndex = {}
for index = 1, 10 do
	objectIndex[index] = Object(math.random(0, 240), math.random(0, 136))
end
function main()
	for index, object in pairs(objectIndex) do
		object:locate()
	end
end