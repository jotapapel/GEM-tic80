local lib, filename, arg1, arg2, arg3 = "obj", ...
local function args(b)return arg1==b or arg2==b or arg3==b end

unpack=table.unpack or unpack
function string.mask(a,b) if b then a=b:gsub("%$",a)end;return a end
function string.def(a,c,b) return a==nil and(c or"")or tostring(a):mask(b)end
function string.trim(...) local d={...}for e,f in ipairs(d)do d[e]=string.match(tostring(f),"^%s*(.-)%s*$")end;return unpack(d)end
function string.gsubc(a,b,c) local d,e={},1;a=a:gsub(b,function(f)local g=string.format("%s%03i",tostring(d):sub(-4),e)d[g],e=f,e+1;return g:mask(c)end)d.token,d.len=c,e;return a,d end
function string.gsubr(a,b,c) local d=b.len==nil and error("Replace table missing length value.",2)or b.len;local e=b.token==nil and error("Replace table missing token.",2)or b.token;for f=1,d do local g=string.format("%s%03i",tostring(b):sub(-4),f)a=a:gsub(g:mask(e),function()return string.def(b[g],"",c)end)end;return a end
function table.expand(a,b,c) local d=""for e=1,#a-1 do d=string.format("%s%s%s",d,a[e]:mask(c),b)end;return#a>0 and string.format("%s%s",d,a[#a]:mask(c))or nil end

local parser = {}

function parser.values(str)
	return string.gsub(string.format("%s,", str), "%b[]", function(array)
		return string.format("{%s}", parser.values(array:match("^%[(.-)%]$")))
	end):gsub("(.-):%s+(.-),%s*", function(k, v)
		if type(tonumber(k)) == "number" or k:match("^(<str.-/>)$") then k = string.format("[%s]", k:match("^(<str.-/>)$") or tostring(k)) end
		return string.format("%s = %s, ", k, v)
	end):match("^(.-),%s*$")
end
function parser.process(f)
	local minimal, file, newlines, lines = args("--min"), io.open(f, "r"), {}, {}
	local il, is, im = 0, (minimal and "") or string.char(9)
	local isc, lsc, ilgs, ient, lco
	if file then
		for l in io.lines(f) do table.insert(lines, l) end
		file:close()
	end

	for ln, lf in ipairs(lines) do

		-- trim line
		local level = #lf:match("^(%s*).-$")
		local line, comment = lf:match("^%s*(.-)%s*$"), ""

		if not lsc then

			-- parsing parts
			local l, m, r
			
			-- comments
			l, m, r = line:match("^(.-)(%s*\')%s*(.-)$")
			if l and m and r then
				local s = #l > 0 and string.char(32) or nil
				line, comment = l, string.format("%s-- %s", string.def(s, ""), r)
			end
						-- placeholders for sensitive information
			local ccss, ss34, oss91, ss34, aass
			line, ccss = line:gsubc("\\.", "<char/>")
			line, ss91 = line:gsubc("(%[%[.-%]%])", "<str$/>")
			line, oss91 = line:gsubc("%[%[", "<str>")
			line, ss34 = line:gsubc([[%b""]], "<str$/>")
			line, aass = line:gsubc("([%w%d_%.]+%[.-%])", "<array$/>")
			
			-- closures
			l = line:match("^(elseif)%s.-:$") or line:match("^(else):$")
			if level < (lco or 0) and not l then
				line, comment, lco = "end", "", (lco > 1 and lco - 1)
				table.insert(lines, ln + 1, lf)
			end

			-- ternary operator
			line = line:gsub("(.-)%s:%s(.-)%s%?%s(.-)", "%1 and %2 or %3")
			
			-- negation
			line = line:gsub("!([%w%d%._]+)", "not(%1)")
			
			-- prototypes and structures (header)
			l, m, r = line:match("^(@)[%w%d%._]+.-:$") or line:match("^($)[%w%d%._]+.-:$"), line:match("^.([%w%d%._]+).-:$"), line:match("^@[%w%d%._]+%((.-)%):$")
			if l and m then
				line, lco, ient = string.format("%s = object.%s(%sfunction()", m, l == "@" and "prototype" or "struct", string.def(r, "", "$, ")), level + 1, level
			end
			
			-- prototypes and structures (closings)
			if il - 1 == ient and line == "end" then 
				line, ient = "end)", nil
			end
			
			-- for loop (one line)
			l, m, r = line:match("^(for)%s+(.-):%s(.-)$")
			if l and m then
				line = string.format("for %s do %s end", m, r)
			end
			
			-- for loop (header)
			l, m = line:match("^(for)%s+(.-):$")
			if l and m then 
				line, lco = string.format("for %s do", m), level + 1
			end
			
			-- while conditional
			l, m = line:match("^(while)%s+(.-):$")
			if l and m then 
				line, lco = string.format("while %s do", m), level + 1
			end
			
			-- if statement (one line)
			l, m, r = line:match("^(if)%s+(.-):%s(.-)$")
			if l and m then
				r = string.def(r):gsub("%?%s(.-):%s+", "elseif %1 then "):gsub("%?", "else")
				line = string.format("if %s then %s end", m, r)
			end
			
			-- if statement (if and elseif header)
			l, m = line:match("^([%w]+)%s+(.-):$")
			if l == "if" or l == "elseif" and m then
				line, lco = string.format("%s %s then", l, m), level + 1
			end
			
			-- if statement (else header)
			l = line:match("^(else):$")
			if l then
				line, lco = l, level + 1
			end
			
			-- function declaration
			l = line:match("^(let%s+).-$")
			m, r = line:match(string.format("^%s(func)%%s+(.-):$", string.def(l)))
			if m and r then 
				line, lco = string.format("%sfunction %s", string.def(l, "", "local "), r), level + 1
			end
			
			-- return function
			l, r = line:match("(return)%s+(func%(.-%)):$")
			if l and r then 
				line, lco = string.format("%s function(%s)", l, r:match("^func%((.-)%)$")), level + 1
			end
			
			-- constructor function
			l, m = line:match("^(constructor)(.-):$")
			if l and m then
				line, lco = string.format("function constructor(self, %s)", m:match("^%((.-)%)$")), level + 1
			end
			
			-- variable declaration
			l = line:match("^(let%s+).-$")
			m, r = line:match(string.format("^%s(.-)%%s*=%%s*(.-)$", string.def(l)))
			if m and r and not(m:match("^.-(if).-$")) then
				m = m:match("^(.-)%s*$")
				line = string.format("%s%s = %s", string.def(l, "", "local "), m, parser.values(r))
			end
			
			-- arrays
			line = line:gsub("%b[]", function(array) return string.format("{%s}", parser.values(array:match("^%[(.-)%]$"))) end)
			
			-- minifier
			if minimal then line = line:gsub("%s*([,=+-])%s*", "%1") end

			-- redirect comments and long strings
			if (line:match("^.-(<comment>)$")) then lsc, isc = ln, true end
			if (line:match("^.-(<str>).-$") and line:match("^.-(<str.-/>).-$") == nil) then lsc, isc = ln, false end

			-- replace string placeholders
			line = line:gsubr(ss34):gsubr(ss91):gsubr(oss91)
			
			-- replace array access placeholders
			line = line:gsubr(vass)
			
			-- replace special character placeholders
			line = line:gsubr(scc)

			-- indentation
			l = line:gsub("%b()", "<parenthesis/>"):gsub("\\.", "<char/>"):gsub("(%[%[.-%]%])", "<p/>"):gsub([[%b'']], "<str/>"):gsub([[%b""]], "<str/>"):gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
			if (l:match("^(until).-$") or l:match("^(end).-$") or (l:match("^(elseif)%s+.-%s+(then)$") or l:match("^(else)$")) or l:match("^%s*(})%s*.-$")) then il = il - 1 end
			if #l > 0 or #comment > 0 then table.insert(newlines, string.format("%s%s%s", is:rep(il), line, (minimal and "") or comment)) end
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
			if not minimal and not isc and #line > 0 then table.insert(newlines, string.format("%s%s%s", lf:match("^(%s*).-$"), is:rep(il), line)) end

		end
		
		-- final closures
		
		while lco and ln == #lines and #lf > 0 do
			table.insert(lines, ln + 1, string.format("%send", is:rep(lco - 1)))
			lco = (lco > 1 and lco - 1)
		end

	end
	
	-- return result
	return newlines, newlines[1]:match("^@compile%s*(.-)$")

end

if filename then
	local lines, outpath = parser.process(filename)
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
	
		-- only print contents to console
		for ln, lf in ipairs(lines) do print(lf) end
		
	end
	
else
	
	-- wrong arguments
	print("usage: lua ../ls.lua ../file.ls [--min] [--echo]\n--min     Minifies the result.\n--echo    Raw printing of the result.\n--verbose Formatted printing of the result.")

end
