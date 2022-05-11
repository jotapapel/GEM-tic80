local filename, arg1, arg2, arg3 = ...
local function args(b)return arg1==b or arg2==b or arg3==b end

unpack=table.unpack or unpack
function string.mask(a,b) if b then a=b:gsub("%$",a)end;return a end
function string.def(a,c,b) return a==nil and(c or"")or tostring(a):mask(b)end
function string.trim(...) local d={...}for e,f in ipairs(d)do d[e]=string.match(tostring(f),"^%s*(.-)%s*$")end;return unpack(d)end
function string.gsubc(a,b,c) local d,e={},1;a=a:gsub(b,function(f)local g=string.format("%s%03i",tostring(d):sub(-4),e)d[g],e=f,e+1;return g:mask(c)end)d.token,d.len=c,e;return a,d end
function string.gsubr(a,b,c) local d=b.len==nil and error("Replace table missing length value.",2)or b.len;local e=b.token==nil and error("Replace table missing token.",2)or b.token;for f=1,d do local g=string.format("%s%03i",tostring(b):sub(-4),f)a=a:gsub(g:mask(e),function()return string.def(b[g],"",c)end)end;return a end
function table.expand(a,b,c) local d=""for e=1,#a-1 do d=string.format("%s%s%s",d,a[e]:mask(c),b)end;return#a>0 and string.format("%s%s",d,a[#a]:mask(c))or nil end

local lib = {
	"setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d==\"_ENV\"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end",
	"object={new=function(a,...)local b=setmetatable({super=a},{__index=a})if type(a.constructor)==\"function\" then a.constructor(b,...) end;return b end,prototype=function(...)local a,b=...local c=b and a;local d=setmetatable({super=c},{__index=c})local e=setmetatable({self=d,super=c},{__index=_G,__newindex=d})setfenv(b or a,e)();return d end}"
}

local parser = {}

function parser.values(str)
	return str:gsub("([%w%d%.%(%)]+)%s+%?%s+(.-)%s+:%s+(.-)", "(%1 and %2) or %3"):gsub("%b[]", function(array)
		array = string.format("%s,", array:match("^%[(.-)%]$"))
		return string.format("{%s}", parser.values(array):gsub("(.-):%s+(.-),%s*", function(k, v)
			if type(tonumber(k)) == "number" or k:match("^(<str.-/>)$") then k = string.format("[%s]", k:match("^(<str.-/>)$") or tostring(k)) end
			return string.format("%s = %s, ", k, v)
		end):match("^(.-),%s*$"))
	end)
end


local keywords = {["if"] = "%s+%((.-)%)", ["elseif"] = "%s+%((.-)%)", ["else"] = "", ["while"] = "%s+%((.-)%)", ["for"] = "%s+%(let ([%w%d_]+%s+=%s+%d,%s+%d)%)", ["foreach"] = "%s+%((%{.-%}%s+in%s+.-)%)"}
local keyword_closings = {["if"] = "then", ["elseif"] = "then", ["while"] = "do", ["for"] = "do"}
function parser.structures(str, il, lco, iptp, ifnc)
	for key, pattern in pairs(keywords) do
		local l, m, r = str:match(string.format("^(%s)%s:%%s*(.-)$", key, pattern))
		if (l and m) then
			l, m, r = l:gsub("foreach", "for"), (l == "foreach" and m:gsub("%{(.-)%}", "%1")) or m, #(r or "") > 0 and string.format(" %s end", parser.parse(r, il, lco, iptp, ifnc)) or ""
			return string.format("%s %s %s", l, m, keyword_closings[l] or "", r):match("^%s*(.-)%s*$") .. r, ((#r == 0 and (keyword_closings[l] == "do" or l == "else")) and il + 1) or lco
		end
	end
	return str, lco
end

function parser.parse(str, il, lco, iptp, ifnc)

	local l, m, r
	local s = str:match("^(let%s+).-$")
	
	-- negation
	str = str:gsub("!([%w%d%._]+)", "not(%1)")

	-- arrays
	str = parser.values(str)

	-- multiline arrays
	l, r = str:match("^(.-%s+=%s+.-)(%[)$")
	if l and r then
		str, lco, iarr = string.format("%s{", l), il + 1, il + 1
	end

	if iarr == il then
		str = "hall"
	end

	-- local variables
	l, m, r = str:match(string.format("^%s(.-)%%s+(=)%%s+(.-)$", string.def(s)))
	if l and m and r then
		str = string.format("%s%s = %s", string.def(ifnc and "let" or s, "", "local "), l, r)
	end
	
	-- prototypes
	l, r = str:match("^prototype%s+([%w%d%._]+)(.-):$")
	if l then
		local r = r:match("^%s+is%s+(.-)$")
		str, lco, iptp = string.format("%s = object.prototype(%sfunction()", l, string.def(r, "", "$, ")), il + 1, il + 1
	end
	
	-- new
	str = str:gsub("new%s+([%w%d%._]+)%((.-)%)", "object.new(%1, %2)")
	
	-- control structures
	str, lco = parser.structures(str, il, lco, iptp, ifnc)
	
	-- functions
	l, m, r = str:match(string.format("^%sfunc%%s+([%%w%%d_]+)%%((.-)%%):%%s*(.-)$", string.def(s)))
	if l and m then
		if #r > 0 then r = string.format(" %s end", parser.parse(r, il, lco, iptp, ifnc)) end
		if (iptp or 0) > 0 and not(s) then m = #m > 0 and m:mask("self, $") or "self" end
		str, lco, ifnc = string.format("%sfunction %s(%s)%s", string.def(s, "", "local "), l, m, r), (#r == 0 and il + 1) or lco, il + 1
	end
	
	-- return function
	l, m, r = str:match("^return%s+(func)(.-):%s*(.-)$")
	if l and m then
		if #r > 0 then r = string.format(" %s end", parser.parse(r)) end
		str, lco = string.format("return function%s%s", m, r), (#r == 0 and il + 1) or lco
	end

	-- constructor
	l, m, r = str:match(string.format("^%s(constructor%%()(.-)%%):%%s*(.-)$", string.def(s)))
	if l and m then
		if #r > 0 then r = string.format(" %s end", parser.parse(r)) end
		if #m > 0 then m = string.format(", %s", m) end
		str, lco = string.format("%sfunction constructor(self%s)%s", string.def(s, "", "local "), m, r), (#r == 0 and il + 1) or lco
	end

	return str, lco, iptp, ifnc, iarr
	
end
function parser.process(f)
	local minimal, file, newlines, lines = args("--min"), io.open(f, "r"), {}, {}
	local il, is, im = 0, (minimal and "") or string.char(9)
	local isc, lsc, ilgs, lco, iptp, ifnc, iarr
	if file then
		for l in io.lines(f) do table.insert(lines, l) end
		file:close()
	end

	if args("--lib") then
		for _, line in ipairs(lib) do
			table.insert(newlines, line)
		end
	end

	for ln, lf in ipairs(lines) do

		-- trim line
		local level = #lf:match("^(%s*).-$")
		local line, comment = lf:match("^%s*(.-)%s*$"), ""

		if not lsc then

			-- generate comments, delete if minimal
			line = line:gsub("^(.-)(%s*)\'%s*(.-)$", minimal and "%1%2" or "%1%2-- %3")
						-- insert placeholders
			local ccss, ss34, oss91, ss34, aass
			line, ccss = line:gsubc("\\.", "<char/>")
			line, ss91 = line:gsubc("(%[%[.-%]%])", "<str$/>")
			line, oss91 = line:gsubc("%[%[", "<str>")
			line, ss34 = line:gsubc([[%b""]], "<str$/>")
			line, aass = line:gsubc("([%w%d_%.]+%[.-%])", "<array$/>")

			-- redirect long strings
			if (line:match("^.-(<str>).-$") and line:match("^.-(<str.-/>).-$") == nil) then lsc, isc = ln, false end
			
			-- append closings
			local l = line:match("^(elseif)%s+.-:.-$") or line:match("^(else):.-$")
			if level < (lco or 0) and not(l) then
				line, comment, lco, iptp, ifnc = string.format("end%s", iptp == il and ")" or ""), "", (lco > 1 and lco - 1), (iptp == il and iptp - 1) or iptp, (ifnc ~= il and ifnc)
				if lf:match("^%s*(%])%s*$") == "]" and iarr == il + 1 then line, iarr = "}", nil else table.insert(lines, ln + 1, lf) end
			end

			-- do parsing
			line, lco, iptp, ifnc, iarr = parser.parse(line, level, lco, iptp, ifnc)

			-- replace placeholders
			line = line:gsubr(aass):gsubr(ss34):gsubr(oss91):gsubr(ss91):gsubr(ccss)
			
			-- reduce spacing if minimal
			if minimal then line = line:gsub("%s*([=%+%-%*%/,><])%s*", "%1") end

			-- generate the correct indentation
			l = line:gsub("%b()", "<parenthesis/>"):gsub("\\.", "<char/>"):gsub("(%[%[.-%]%])", "<p/>"):gsub([[%b""]], "<str/>"):gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
			if (l:match("^(until).-$") or l:match("^(end).-$") or (l:match("^(elseif)%s+.-%s+(then)$") or l:match("^(else)$")) or l:match("^%s*(})%s*.-$")) then il = il - 1 end
			if #l > 0 or #comment > 0 then table.insert(newlines, string.format("%s%s%s", is:rep(il), line, (minimal and "") or comment)) end
			if (l:match("^(while%s+.-%s+do)$") or l:match("^(repeat)$") or (l:match("^.-%s*(function<parenthesis/>)$") or l:match("^.-%s*(function)%s+.-$")) or l:match("^.-%s+(then)$") or l:match("^(else)$") or (l:match("^.-(do)$") and not l:match("^.-(end).-$")) or l:match("^.-%s*({)%s*$")) then il = il + 1 end

		else
		
			-- insert placeholders
			local cmlc, css91
			line, cmlc = line:gsubc("%-%-%]%]", "</comment>")
			line, css91 = line:gsubc("%]%]", "</str>")

			-- redirect closings
			if line:match("^.-(</comment>)$") or line:match("^.-(</str>)$") then lsc, isc = nil, false end

			-- replace comments
			line = line:gsubr(css91):gsubr(cmlc, (not(minimal) and "$") or "")

			-- display comments or long strings
			if not minimal and not isc and #line > 0 then table.insert(newlines, string.format("%s%s%s", lf:match("^(%s*).-$"), is:rep(il), line)) end

		end
		
		-- final closures
		while lco and ln == #lines and #lf > 0 do
			table.insert(lines, ln + 1, string.format("%send%s", is:rep(lco - 1), iptp == il and ")" or ""))
			lco, iptp = (lco > 1 and lco - 1), (iptp == il and iptp - 1) or iptp
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
	
	-- if not echo, create a lua file
	if not(args("--echo")) then
		
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
		
		-- verbose
		if args("--verbose") then
			local f = string.format(" %%0%si %%s", math.max(2, #tostring(#lines)))
			for ln, lf in ipairs(lines) do print(lf) end
		end
		
		-- print success
		print(string.format("\n[file created at %s]", table.expand(dirbits, "/")))
		
	elseif args("--echo") then
	
		-- only print contents to console
		for ln, lf in ipairs(lines) do print(lf) end
		
	end
	
else
	
	-- wrong arguments
	print("usage: lua ../ls.lua ../file.ls [--min] [--echo|--verbose] [--lib]\n--min     Minifies the result.\n--echo    Raw printing of the result.\n--verbose Formatted printing of the result.\n--lib     Include the goscript library when generating the lua file.")

end
