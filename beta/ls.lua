local filename, arg1, arg2, arg3 = ...
local function args(b)return arg1==b or arg2==b or arg3==b end

local _name = "object"

unpack=table.unpack or unpack
function string.mask(a,b) if b then a=b:gsub("%$",a)end;return a end
function string.def(a,c,b) return a==nil and(c or"")or tostring(a):mask(b)end
function string.trim(...) local d={...}for e,f in ipairs(d)do d[e]=string.match(tostring(f),"^%s*(.-)%s*$")end;return unpack(d)end
function string.gsubc(a,b,c) local d,e={},1;a=a:gsub(b,function(f)local g=string.format("%s%03i",tostring(d):sub(-4),e)d[g],e=f,e+1;return g:mask(c)end)d.token,d.len=c,e;return a,d end
function string.gsubr(a,b,c) local d=b.len==nil and error("Replace table missing length value.",2)or b.len;local e=b.token==nil and error("Replace table missing token.",2)or b.token;for f=1,d do local g=string.format("%s%03i",tostring(b):sub(-4),f)a=a:gsub(g:mask(e),function()return string.def(b[g],"",c)end)end;return a end
function table.expand(a,b,c) local d=""for e=1,#a-1 do d=string.format("%s%s%s",d,a[e]:mask(c),b)end;return#a>0 and string.format("%s%s",d,a[#a]:mask(c))or nil end

local function process(f)
	local file, newlines, lines = io.open(f, "r"), {}, {}
	local il, is = 0, string.char(9)
	local showc, lsc, ilgs, isc = true, nil, nil, false
	local ost, ist, obi = 0, 0, 0
	local function downLevel(a) if a>2 then return a-1 else return 0 end end
	
	if file then
		for l in io.lines(f) do table.insert(lines, l) end
		file:close()
	end

	for ln, lf in ipairs(lines) do

		-- replace comments
		local line, comment = lf:match("^%s*(.-)%s*$"), ""

		if not lsc then

			-- line parts
			local l, k, r

			-- insert placeholders
			local slc, omlc, ss34, ss39, ss91, oss91
			line, slc = line:gsubc("%-%-%[%[.-%-%-%]%]", "<comment$/>")
			k = line:match("^.-(%-%-%[%[).-$") or line:match("^.-(%-%-).-$")
			if k then
				local l, r = line:match(string.format("^(.-)%s(.-)$", k:gsub("%-", "%%-"):gsub("%[", "%%[")))
				line, comment = string.format("%s%s", l:trim(), (k == "--[[" and "--[[" or "")), (#r > 0) and string.format("%s%s", (#l > 0) and " " or "", r:mask("--$")) or ""
			end
			line, omlc = line:gsubc("%-%-%[%[", "<comment>")
			line, ss91 = line:gsubc("(%[%[.-%]%])", "<str$/>")
			line, oss91 = line:gsubc("%[%[", "<str>")
			line, ss39 = line:gsubc([[%b'']], "<str$/>")
			line, ss34 = line:gsubc([[%b""]], "<str$/>")
			
			-- 1: structures
			l = line:match("^(local%s+)")
			k = line:match(string.format("^%sstruct%%s+([_%%w]+)%%s+def$", string.def(l)))
			if k then
				line, obi = string.format("%s%s = %s.struct(function()", string.def(l), k, _name), il + 1
			end
			
			-- 2: prototypes
			l = line:match("^(local%s+)")
			k = line:match(string.format("^%s(prototype)%%s+.-$", string.def(l)))
			r = line:match(string.format("^.-%s%%s+(.-)%%s+def$", string.def(k)))
			if k then
				local n, e = r:match("^([_%w]+).-$"), r:match("^.-%s+is%s+([_%w]+)$")
				line, obi = string.format("%s%s = %s.prototype(%sfunction()", string.def(l), string.def(n), _name, string.def(e, "", "$, ")), il + 1
			end
			
			-- 4: functions and constructor function
			k = line:match(string.format("^%s(func)%%s+.-$", string.def(l)))
			r = line:match(string.format("^.-%s%%s+(.-)$", string.def(k)))
			if k then
				local d, e = r:match("^([_%w]+%(.-%))%s*(.-)$")
				if not e:match("^.-(end)$") then e = string.format("%send", e) end
				line = string.format("%sfunction %s%s", string.def(l), d, string.def(e))
			end
			
			k = line:match("^constructor(%(.-%))$")
			if k then
				line = string.format("function constructor%s", k)
			end
			
			-- 4: instances
			l = line:match("^(local%s+)")
			k, r = line:match(string.format("^%s(.-)%%s+=%%s+new%%s+(.-)$", string.def(l)))
			if k then
				local p, a = r:match("^([_%w]+)%((.-)%)$")
				line = string.format("%s%s = %s.create(%s%s)", string.def(l), k, "object", p, string.def(#a > 0 and a or nil, "", ", $"))
			end
			
			-- 5: closings
			k, r = line:match("^(end)(.-)$")
			if k then
				if (newlines[#newlines]:sub(-1) == ",") then newlines[#newlines] = newlines[#newlines]:sub(1, -2) end
				if il == obi then line, obi = string.format("end)%s", r), obi - 1 end
			end

			-- redirect comments and long strings
			if (line:match("^.-(<comment>)$")) then lsc, isc = n, true end
			if (line:match("^.-(<str>).-$") and line:match("^.-(<str.-/>).-$") == nil) then lsc, isc = n, false end

			-- replace placeholders
			line = line:gsubr(ss34):gsubr(ss39):gsubr(ss91):gsubr(oss91)
			line = line:gsubr(slc, (showc) and "$" or ""):gsubr(omlc, (showc) and "$" or "")

			-- indentation
			local l, c = line:gsub("%b()", "<parenthesis/>"):gsub("(%[%[.-%]%])", "<p/>"):gsub([[%b'']], "<str/>"):gsub([[%b""]], "<str/>"), (showc) and comment or ""
			l = l:gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
			if (l:match("^(until).-$") or l:match("^(end).-$") or (l:match("^(elseif)%s+.-%s+(then)$") or l:match("^(else)$")) or l:match("^%s*(})%s*.-$")) then il = il - 1 end
			if ((#l > 0) or (#c > 0)) then table.insert(newlines, string.format("%s%s%s", is:rep(il), line, c)) end
			if (l:match("^(while).-$") or l:match("^(repeat)$") or (l:match("^.-%s*(function<parenthesis/>)$") or l:match("^.-%s*(function)%s+.-$")) or l:match("^.-%s+(then)$") or l:match("^(else)$") or (l:match("^.-(do)$") and l:match("^.-(end).-$") == nil) or l:match("^.-%s*({)%s*$")) then il = il + 1 end

		elseif (n > lsc) then

			local cmlc, css91
			line, cmlc = line:gsubc("%-%-%]%]", "</comment>")
			line, css91 = line:gsubc("%]%]", "</str>")

			if (line:match("^.-(</comment>)$") or line:match("^.-(</str>)$")) then lsc, isc = nil, false end

			-- replace comments
			line = line:gsubr(css91):gsubr(cmlc, (showc) and "$" or "")

			-- display comment or long string
			if (showc or (isc == false) and (#line > 0)) then output = string.format("%s%s\n", output, line) end

		end
	end

	-- return result
	return newlines, newlines[1]:match("^@compile%s+(.-)$")

end

if filename then
	local lines, outpath = process(filename)
	local dirbits, namebits, basepath, strip = {}, {}, filename, 1
	-- generate file content¡¡
	if outpath then table.remove(lines, 1) end
	-- create a lua file
	if not args("--display") then
		-- get basepath for new file
		if outpath then basepath, strip = string.gsub(debug.getinfo(1).short_src, "^(.+\\)[^\\]+$", "%1"), 2 end
		local i, _, l = 0, string.gsub(string.format("%s/", basepath), "/", "")
		string.gsub(string.format("%s/", basepath), "(.-)/", function(b) if (i < l - strip) then table.insert(dirbits, b) end i = i + 1 end)
		-- get the name of the new file from the og filename
		string.gsub(string.format("%s/", filename), "(.-)/", function(b) table.insert(namebits, b) end)
		local name = string.gsub(outpath or "/$", "%$", string.format("%s.lua", table.remove(namebits):sub(1, -4))):sub(2)
		table.insert(dirbits, name)
		-- write new lua file
		local file = io.open(table.expand(dirbits, "/"), "w")
		file:write(table.expand(lines, "\n"))
		file:close()
	end
	-- print contents to terminal
	if args("--display") or args("--verbose") then
		local f = string.format(" %%0%si %%s", math.max(2, #tostring(#lines)))
		for n, line in ipairs(lines) do print(string.format(f, n, line)) end
	end
else
	print("usage: lua ../lsc.lua path/to/file.lss [--minimal] [--display] [--verbose]")
end