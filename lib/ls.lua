--[[
	GEM-tic80
	Script Preprocessor - For ease of scripting.
	by @jotapapel, Dec. 2021
	v. 1.1
--]]

local lib, filename, arg1, arg2, arg3 = "object", ...
local function args(b)return arg1==b or arg2==b or arg3==b end

unpack=table.unpack or unpack
function string.mask(a,b) if b then a=b:gsub("%$",a)end;return a end
function string.def(a,c,b) return a==nil and(c or"")or tostring(a):mask(b)end
function string.trim(...) local d={...}for e,f in ipairs(d)do d[e]=string.match(tostring(f),"^%s*(.-)%s*$")end;return unpack(d)end
function string.gsubc(a,b,c) local d,e={},1;a=a:gsub(b,function(f)local g=string.format("%s%03i",tostring(d):sub(-4),e)d[g],e=f,e+1;return g:mask(c)end)d.token,d.len=c,e;return a,d end
function string.gsubr(a,b,c) local d=b.len==nil and error("Replace table missing length value.",2)or b.len;local e=b.token==nil and error("Replace table missing token.",2)or b.token;for f=1,d do local g=string.format("%s%03i",tostring(b):sub(-4),f)a=a:gsub(g:mask(e),function()return string.def(b[g],"",c)end)end;return a end
function table.expand(a,b,c) local d=""for e=1,#a-1 do d=string.format("%s%s%s",d,a[e]:mask(c),b)end;return#a>0 and string.format("%s%s",d,a[#a]:mask(c))or nil end
local function process(f)
	local minimal, file, newlines, lines = args("--min"), io.open(f, "r"), {}, {}
	local il, is, im = 0, (minimal and "") or string.char(9)
	local showc, lsc, ilgs, isc = not minimal, nil, nil, false
	if file then
		for l in io.lines(f) do table.insert(lines, l) end
		file:close()
	end

	for ln, lf in ipairs(lines) do

		-- trim line
		local line, comment = lf:match("^%s*(.-)%s*$"), ""

		if not lsc then

			-- line parts
			local l, k, r

			-- insert placeholders
			local slc, omlc, ss34, ss39, ss91, oss91
			line, slc = line:gsubc("%-%-%[%[.-%-%-%]%]", "<comment$/>")
			--k = line:match("^.-(%-%-%[%[).-$") or line:match("^.-(%-%-).-$")
			if k then
				local l, r = line:match(string.format("^(.-)%s(.-)$", k:gsub("%-", "%%-"):gsub("%[", "%%[")))
				line, comment = string.format("%s%s", l:trim(), (k == "--[[" and "--[[" or "")), (#r > 0) and string.format("%s%s", (#l > 0) and " " or "", r:mask("--$")) or ""
			end
			line, omlc = line:gsubc("%-%-%[%[", "<comment>")
			line, ss91 = line:gsubc("(%[%[.-%]%])", "<str$/>")
			line, oss91 = line:gsubc("%[%[", "<str>")
			line, ss39 = line:gsubc([[%b'']], "<str$/>")
			line, ss34 = line:gsubc([[%b""]], "<str$/>")

			-- 1: local keyword
			l = line:match("^(local%s+)")
			
			-- 2: structures
			k = line:match(string.format("^%sstruct%%s+([_%%.%%w]+)%%s+def$", string.def(l)))
			if k then line, im = string.format("%s%s = %s.struct(function()", string.def(l), k, lib), il + 1 end
			
			-- 3: prototypes
			k, r = line:match(string.format("^%sprototype%%s+([_%%.%%w]+)%%s+(.-)%%s*def$", string.def(l)))
			if k then
				local s = r:match("^is%s+([_%.%w]+)$")
				line, im = string.format("%s%s = %s.prototype(%sfunction()", string.def(l), k, lib, string.def(s, "", "$, ")), il + 1
			end
			
			-- 4: constructor function
			k, r = line:match("^constructor(%(.-%))(.-)$")
			if k then line = string.format("function constructor%s%s", k, string.def(r)) end
					
			-- 5: package emulation
			k = line:match("^package%s+([_%w]+)%s+def$")
			if k then 
				line, im = string.format("%s = {}", k), il + 1
				table.insert(lines, ln + 1, "do")
			end
			
			-- 6: main function
			k = line:match("^@main%s+([_%w]+)$")
			if k then line = string.format("(getmetatable(_G) or getmetatable(setmetatable(_G, {}))).__index = function(t, k) if k == \"%s\" then return rawget(t, \"main\") end end", k) end
					
			-- 7: closings
			k, r = line:match("^(end)(.-)$")
			if k then
				if (newlines[#newlines]:sub(-1) == ",") then newlines[#newlines] = newlines[#newlines]:sub(1, -2) end
				if il == im then line, im = string.format("end)%s", r), im - 1 end
			end

			-- minifier
			if minimal then line = line:gsub("%s*([,=+-])%s*", "%1") end

			-- redirect comments and long strings
			if (line:match("^.-(<comment>)$")) then lsc, isc = ln, true end
			if (line:match("^.-(<str>).-$") and line:match("^.-(<str.-/>).-$") == nil) then lsc, isc = ln, false end

			-- replace placeholders
			line = line:gsubr(ss34):gsubr(ss39):gsubr(ss91):gsubr(oss91)
			line = line:gsubr(slc, (showc) and "$" or ""):gsubr(omlc, (showc) and "$" or "")

			-- indentation
			local l, c = line:gsub("%b()", "<parenthesis/>"):gsub("(%[%[.-%]%])", "<p/>"):gsub([[%b'']], "<str/>"):gsub([[%b""]], "<str/>"), (showc and comment) or ""
			l = l:gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
			if (l:match("^(until).-$") or l:match("^(end).-$") or (l:match("^(elseif)%s+.-%s+(then)$") or l:match("^(else)$")) or l:match("^%s*(})%s*.-$")) then il = il - 1 end
			if #l > 0 or #c > 0 then table.insert(newlines, string.format("%s%s%s", is:rep(il), line, c)) end
			if (l:match("^(while).-$") or l:match("^(repeat)$") or (l:match("^.-%s*(function<parenthesis/>)$") or l:match("^.-%s*(function)%s+.-$")) or l:match("^.-%s+(then)$") or l:match("^(else)$") or (l:match("^.-(do)$") and not l:match("^.-(end).-$")) or l:match("^.-%s*({)%s*$")) then il = il + 1 end

		else
		
			-- insert placeholders
			local cmlc, css91
			line, cmlc = line:gsubc("%-%-%]%]", "</comment>")
			line, css91 = line:gsubc("%]%]", "</str>")

			-- exit comments
			if line:match("^.-(</comment>)$") or line:match("^.-(</str>)$") then lsc, isc = nil, false end

			-- replace comments
			line = line:gsubr(css91):gsubr(cmlc, (showc) and "$" or "")

			-- display comment or long string
			if showc or not isc and #line > 0 then table.insert(newlines, string.format("%s%s%s", lf:match("^(%s*).-$"), is:rep(il), line)) end

		end
	end

	-- return result
	return newlines, newlines[1]:match("^@compile%s*(.-)$")

end

if filename then
	local lines, outpath = process(filename)
	local dirbits, namebits, basepath, strip = {}, {}, filename, 1
	
	-- generate file content
	if outpath then table.remove(lines, 1) end
	
	-- if not display, create a lua file
	if not args("--echo") then
		
		-- get basepath for new file
		if outpath then basepath, strip = string.gsub(debug.getinfo(1).short_src, "^(.+\\)[^\\]+$", "%1"), 2 end
		local i, _, l = 0, string.gsub(string.format("%s/", basepath), "/", "")
		string.gsub(string.format("%s/", basepath), "(.-)/", function(b) if i < l - strip then table.insert(dirbits, b) end i = i + 1 end)
		
		-- get the name of the new file from the og filename
		string.gsub(string.format("%s/", filename), "(.-)/", function(b) table.insert(namebits, b) end)
		local name = string.gsub(outpath or "/$", "%$", string.format("%s.lua", table.remove(namebits):sub(1, -4))):sub(2)
		table.insert(dirbits, name)
		
		-- write new lua file
		local file = io.open(table.expand(dirbits, "/"), "w")
		file:write(table.expand(lines, "\n"))
		file:close()

		-- print success
		print(string.format("file created: %s", table.expand(dirbits, "/")))
		
		-- verbose
		if args("--verbose") then
			local f = string.format(" %%0%si %%s", math.max(2, #tostring(#lines)))
			for ln, lf in ipairs(lines) do print(lf) end
		end
		
	elseif args("--echo") then
	
		-- only prints contents to console
		for ln, lf in ipairs(lines) do print(lf) end
		
	end
	
else
	
	-- wrong arguments
	print("usage: lua ../ls.lua ../file.ls [--min] [--echo]\n--min     Minifies the result.\n--echo    Raw printing of the result.\n--verbose Formatted printing of the result.")

end
