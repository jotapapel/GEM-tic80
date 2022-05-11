local function all(...)
	local arguments = {...}
	local argument, index = table.remove(arguments), 0
	return function()
		while argument do
			if index < #argument then
				index = index + 1
				return argument, index
			else
				argument, index = table.remove(arguments), 0
			end
		end
	end
end

local function _all(...)
	local arguments = {...}
	local index, position = table.remove(arguments), 0
	while index do
		if position < index.size then
			position = position + 1
			print(index, index[position])
		else
			index, position = table.remove(arguments), 0
		end
	end
end

--[[for t, i in all({size = 4, 1, 3, 9, 5}, {size = 2, "hello", "world"}, {size = 1, true}) do
	print(i, t[i])
end--]]

_all({size = 4, 1, 3, 9, 5}, {size = 2, "hello", "world"}, {size = 1, true})