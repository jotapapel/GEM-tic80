string.mask=function(a,b)return b:gsub("%$",a)end

cheese = {}

cheese.patch = function(a, b, c, d)
	local e, f = {}, 0
	a = a:gsub(b, function(g)
		local h = string.format("%s%02i", tostring(e):sub(-5), f)
		e[h], f = type(d) == "function" and d(g) or g, f + 1
		return h:mask(c)
	end)
	e.a, e.b = c, f
	return a, e
end

cheese.reform = function(a, ...)
	local b = {...}
	local c, d = table.remove(b), 0
	while c do
		if d < c.b then
			local e = string.format("%s%02i", tostring(c):sub(-5), d)
			local f, g = a:match("^(.-)" .. e:mask(c.a) .. "(.-)$")
			d, a = d + 1, f .. c[e] .. g
		else
			c, d = table.remove(b), 0
		end
	end
	return a
end

cheese.array = function(a)
	return a:gsub("%b[]", function(b)
		local c, ca = cheese.patch(b:match("^%[(.-)%]$"), "%b[]", "<a$/>", function(d) return cheese.array(d) end)
		return cheese.reform(string.gsub(c:mask("$,"), "(.-):%s+(.-),%s*", function(e, f)
			if tonumber(e) or e:match("^<b%x+/>$") then e = e:mask("[$]") end
			if f:match("^%(.-%):%s+.-$") then f = "nil" end
			return e .. " = " .. f .. ", "
		end):match("^(.-),%s*$"), ca):mask("{$}")
	end)
end

cheese.inline = function(a)
	return a:gsub("%b()", function(b)
		local c, d = cheese.patch(b:match("^%((.-)%)$") .. ",", "%b()", "<a$/>")
		c = c:gsub("%s*(.-),%s*", function(e)
			local f, g = e:match("^(<a%x+/>):%s+(.-)$")
			if f and g then e = string.format("function%s %s end", f, g) end
			return string.format("%s, ", e)
		end):match("(.-),%s*$")
		return string.format("(%s)", cheese.reform(c, d))
	end)
end

local patterns = {["if"] = " $ then", ["elseif"] = " $ then", ["else"] = "$", ["while"] = " $ do", ["for"] = " $ do"}
cheese.parse = function(a, b)
	-- parse arrays and modify local variables
	a = cheese.array(a):gsub("^let%s+", "local ")
	-- inline functions
	a = cheese.inline(a)
	-- separate head from body
	local c, d = a:match("^(.-):%s+.-$") or a:match("^(.-):%s*$") or "", a:match("^.-:%s+(.-)$")
	--local e = function() if d then local p, q = d:match("^(.-);%s+(.-)$"); d = ((p and q) and string.format("%s %s", cheese.parse(p), cheese.parse(q)):gsub("end%s+else", "else") or cheese.parse(d)):mask(" $ end") else d, b.a, b.b[b.a] = "", b.a + 1, "end" end return d end
	local e = function() if d then d = cheese.parse(d):mask(" $ end") else d, b.a, b.b[b.a] = "", b.a + 1, "end" end return d end
	-- control structures
	local f, g = c:match("^(%l+)%s+.-$") or c:match("^(%l+)$"), c:match("^%l+%s+(.-)$") or ""
	if patterns[f] then
		return f .. g:mask(patterns[f]) .. e(), b
	end
	-- structs
	f = c:match("^<c%x+/>$")
	if f then
		b.a, b.b[b.a] = b.a + 1, "end)"
		return string.format("%s = struct(function()", f), b
	end
	-- prototypes
	f, g = c:match("^def%s+([_%a][%._%w]+){(.-)}$")
	if f and g then
		g, b.a, b.b[b.a] = string.mask(#g > 0 and g or "nil", "$, "), b.a + 1, "end)"
		return string.format("%s = prototype(%sfunction()", f, g), b
	end
	-- functions
	f, g = c:match("^(.-)def%(.-%)$") or c:match("^(.-)%(.-%)$"), c:match("^.-def(%(.-%))$") or c:match("^.-(%(.-%))$")
	if f and g then
		local h = f:match("^def%s+([_%a][_%w%.]+)$")
		if f:match("^([_%a][_%w%.]+)$") and b.b[b.a - 1] == "end)" then f, g = f:mask("$ = "), "(self" .. (#g > 2 and g:match("^%((.-)$"):mask(", $") or ")") end
		return string.mask(h or f, h and "function $" or "$function") .. g .. e(), b
	end
	return a, b
end

cheese.lines = function(a)
	local b, c, d = io.open(a, "r"), {}, 0 
	-- open the file and get it's contents
	if b then
		for z in io.lines(a) do table.insert(c, z) end
		b:close()
	end
	-- return the new iterator (first the indentation length and then the line itself)
	return function()
		while d < #c do
			d = d + 1
			return #c[d]:match("^(%s*).-$"), c[d]:match("^%s*(.-)%s*$")
		end
	end
end

cheese.file = function(a)
	local b, c, d = {}, {a = 0, b = string.char(9)}, {a = -1, b = {}}
	for e, f in cheese.lines(a) do
		-- insert placeholders
		local fa, fb, fc, fd, fe
		f, fa = cheese.patch(f, "\\.", "<a$/>")
		f, fb = cheese.patch(f, [[%b""]], "<b$/>")
		f, fc = cheese.patch(f, "def%s+([_%a][_%w%.]+)%b[]", "<c$/>")
		f, fd = cheese.patch(f, "([_%a][_%w%.]+%b[])", "<d$/>")
		f, fe = cheese.patch(f, "\'(.-)$", "<e$/>", function(a) return "--" .. a end)
		-- generate closings
		while e <= d.a do
			local z = f:match("^elseif%s+.-:.-$") or f:match("^else:.-$")
			c.a, d.a, d.b[d.a] = c.a - (z and 0 or 1), d.a - 1, ""
			if not z then table.insert(b, c.b:rep(c.a) .. d.b[d.a]) end
		end
		-- parse the line
		local g, h = f:match("^(.-)<e%x+/>$") or f, f:match("(<e%x+/>)$") or ""
		g, d = cheese.parse(g, d)
		-- repatch the line and generate the right indentation
		local i = g:gsub("%b{}", "<a/>"):gsub("%b()", "<b/>"):gsub("function<b/>.-end", "<c/>"):gsub("function%s+.-<b/>.-end", "<c/>")
		if i:match("^until.-$") or i:match("^end.-$") or i:match("^elseif%s+.-%s+then$") or i:match("^else$") or i:match("^%s*}%s*.-$") then c.a = c.a - 1 end
		if #f > 0 then b[#b + 1] = c.b:rep(c.a) .. cheese.reform(g .. h, fa, fb, fc, fd, fe) end
		if i:match("^while%s+.-%s+do$") or i:match("^repeat$") or i:match("^.-%s*function<b/>$") or i:match("^.-%s*function%s+.-$") or i:match("^.-%s+then$") or i:match("^else$") or (i:match("^.-do$") and not i:match("^.-end.-$")) or i:match("^.-%s*{%s*$") then c.a = c.a + 1 end
	end
	while d.a > -1 do
		c.a, d.a, d.b[d.a], b[#b + 1] = c.a - 1, d.a - 1, "", c.b:rep(c.a - 1) .. d.b[d.a - 1]
	end
	return b
end

local filename, arg1 = ...
if filename then
	local a = table.concat(cheese.file(filename), "\n")
	if arg1 ~= "--echo" then
		local ba, bb, bd, be = {}, {}, filename, 1
		local c, _, d = 0, bd:mask("$/"):gsub("/", "")
		for z in bd:mask("$/"):gmatch("(.-)/") do ba[#ba + 1], c = (c < d - be) and z or nil, c + 1 end
		for z in filename:mask("$/"):gmatch("(.-)/") do bb[#bb + 1] = z end
		ba[#ba + 1] = bb[#bb]:sub(1, -4) .. ".lua"
		io.open(table.concat(ba, "/"), "w"):write(a):close()
	end
	print(a)
else
	print("usage: lua ../chs.lua ../file.chs [--echo]\n--echo    Only prints the result.")
end