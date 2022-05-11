string.mask = function(a, b) return b:gsub("%$", a) end
string.concat = function(...) return table.concat({...}) end

-- PARSER COMPONENTS
-- true false nil not and or let if elseif else while for break return def

local parser = {}

function parser.patch(str, match, mask)
	local index, position = {}, 0
	str = str:gsub(match, function(blob)
		local hash = string.format("%s%02i", tostring(index):sub(-5), position)
		index[hash], position = blob, position + 1
		return hash:mask(mask)
	end)
	index.mask, index.size = mask, position
	return str, index
end

function parser.reform(str, ...)
	local arguments = {...}
	local index, position = table.remove(arguments), 0
	while index do
		if position < index.size then
			local hash = string.format("%s%02i", tostring(index):sub(-5), position)
			local before, after = str:match("^(.-)" .. hash:mask(index.mask) .. "(.-)$")
			position, str = position + 1, string.concat(before, index[hash], after)
		else
			index, position = table.remove(arguments), 0
		end
	end
	return str
end

function parser.array(line)
	return line:gsub("%b[]", function(array)
		array = array:match("^%[(.-)%]$")
		return parser.array(array):mask("$,"):gsub("(.-):%s+(.-),%s*", function(key, value)
			if tonumber(key) or key:match("^(<str%x+/>)$") then key = key:mask("[$]") end
			return string.concat(key, " =", value, ", ")
		end):match("^(.-),%s*$"):mask("{$}")
	end)
end

local structures = {["if"] = " $ then", ["elseif"] = " $ then", ["while"] = " $ do", ["else"] = "$", ["do"] = "$", ["for"] = " $ do"}
function parser.components(blob, closing_level, closing_tag)
	local function parse(blob) if #blob == 0 then closing_level = closing_level + 1 else blob = parser.components(blob, closing_level, closing_tag):mask(" $ end") end return blob end
	local content = parser.array(blob):gsub("^let(%s+.-)$", "local%1")
	local main, aside = content:match("^(.-):%s+.-$") or content:match("^(.-):%s*$") or "", content:match("^.-:%s+(.-)$") or ""
	-- control structures
	head, body = main:match("^(%l+)%s+.-$") or main:match("^(%l+)$"), main:match("^%l+%s+(.-)$") or ""
	if structures[head] then
		return string.concat(head, body:mask(structures[head]), parse(aside)), closing_level, closing_tag
	end
	-- prototypes
	head, body = main:match("^def%s+([_%a][%w%.]+){(.-)}$")
	if head then
		body, closing_tag[closing_level] = string.mask(#body > 0 and body or "nil", "$, "), "prototype"
		return string.concat(head, " = prototype(", body, "function()"), closing_level + 1, closing_tag
	end
	-- functions
	head, body = main:match("^(.-)def%(.-%)$") or main:match("^(.-)%(.-%)$"), main:match("^.-def(%(.-%))$") or main:match("^.-(%(.-%))$")
	if head and body then
		local key = head:match("^def%s+([_%a][_%w%.]+)$")
		if head:match("^([_%a][_%w%.]+)$") and closing_tag[closing_level - 1] == "prototype" then head, body = head:mask("$ = "), "(self" .. (#body > 2 and body:match("^%((.-)$"):mask(", $") or ")") end
		return string.concat(string.mask(key or head, key and "function $" or "$function"), body, parse(aside)), closing_level, closing_tag 
	end
	-- arrays
	head, body = main:match("^(.-)({})$")
	if head and body then 
		head, closing_tag[closing_level] = head:mask("${"), "array"
		return head, closing_level + 1, closing_tag
	end
	return content, closing_level, closing_tag
end

-- MAIN FUNCTION

local lib = "setfenv=function(a,b)local c,d=1,true;while d do d=debug.getupvalue(a,c) if d==\"_ENV\"then debug.upvaluejoin(a,c,function()return b end,1)break end c=c+1 end return a end\nprototype=setmetatable({},{__index=_G,__newindex=function(a,b,c)rawset(a.self,b,c)end,__call=function(a,b,c)rawset(a,\"self\",setmetatable({super=b},{__index=b,__call=function(a,...)local b=setmetatable({prototype=a},{__index=a});if a.constructor then a.constructor(b,...)end return b end}));rawset(a,\"super\",b);setfenv(c,a)()return a.self end})"

local lines = (function(filename)
	local file, oglines, newlines = io.open(filename, "r"), {}, {}
	local indent_level, indent_string, closing_level, closing_tag = 0, string.char(9), -1, {}
	local closings = {["prototype"] = "end)", ["array"] = "}", ["default"] = "end"}
	-- get lines from file
	if file then
		table.insert(oglines, lib)
		for line in io.lines(filename) do table.insert(oglines, line) end
		table.insert(oglines, "")
		file:close()
	end
	-- iterate thru every line
	for n, rawline in ipairs(oglines) do
		local indent, main = rawline:match("^(%s*)(.-)%s*$")
		-- insert placeholders
		local rrss, ccss, ss34, aass
		main, ccss = parser.patch(main, "\\.", "<char$/>")
		main, ss34 = parser.patch(main, [[%b""]], "<str$/>")
		main, aass = parser.patch(main, "([_%a][_%w%.]+%b[])", "<array$/>")
		main, rrss = parser.patch(main, "(%s*\'.-)$", "<comment$/>")
		-- separate main content from inline comments
		local content, comment = main:match("^(.-)<comment%x+/>$") or main, main:match("^.-(<comment%x+/>)$") or ""
		-- generate closings according to indentation
		if #indent <= closing_level then
			local non_indentable_key = content:match("^elseif%s+.-:.-$") or content:match("^else:.-$")
			content, comment, closing_level, closing_tag[closing_level - 1] = (non_indentable_key and content) or closings[closing_tag[closing_level - 1] or "default"], "", closing_level - 1, nil
			if not non_indentable_key then table.insert(oglines, n + 1, rawline) end
		end
		-- main parsing
		content, closing_level, closing_tag = parser.components(content, closing_level, closing_tag)
		-- final structuring
		local line, scafold = string.concat(parser.reform(content, ccss, ss34, aass), parser.reform(comment, rrss)):gsub("\'(.-)$", "--%1"), content:gsub("%b{}", "<table/>"):gsub("%b()", "<parenthesis/>"):gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
		if scafold:match("^until.-$") or scafold:match("^end.-$") or scafold:match("^elseif%s+.-%s+then$") or scafold:match("^else$") or scafold:match("^%s*}%s*.-$") then indent_level = indent_level - 1 end
		if #line > 0 then table.insert(newlines, string.concat(indent_string:rep(indent_level), line)) end
		if scafold:match("^while%s+.-%s+do$") or scafold:match("^repeat$") or scafold:match("^.-%s*function<parenthesis/>$") or scafold:match("^.-%s*function%s+.-$") or scafold:match("^.-%s+then$") or scafold:match("^else$") or (scafold:match("^.-do$") and not scafold:match("^.-end.-$")) or scafold:match("^.-%s*{%s*$") then indent_level = indent_level + 1 end
	end
	return newlines
end)("test.gs")

print(table.concat(lines, "\n"))