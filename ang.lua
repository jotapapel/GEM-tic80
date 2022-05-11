prototype_name = gs.prototype(prototype_parent, function()
	local prototype_variable = value
	local function prototype_method()
		return self.instance_variable
	end
	-- comment
	instance_variable = value
	function instance_method(self, arg1, arg2, ...)
		local a = 2
		print(arg1 + arg2 + a)
	end
	function constructor(self, arg1)
		self.a = arg1
	end
end)
local object = gs.new(prototype_name, arg1)
if a == 2 then
	return "generics"
elseif a >= 32 then
	return a + 20
else
	print("hello world!")
end
while condition do
	print("looping...")
end
for i = 1, 2 do
	print(var)
end
for key, value in iterator do
	print(array[key])
end
function testing(...)
	return 99
end
_GS = "GOSCRIPT"