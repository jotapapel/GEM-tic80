@compile /bin/$

-- OOP implementation

setfenv=setfenv or function(a,b)for c=1,math.huge do local d=debug.getupvalue(a,c)if d==nil then break elseif d=="_ENV"then debug.upvaluejoin(a,c,function()return b end,1)break end end;return a end
function deftable(a,b,c)setfenv(b,setmetatable(c or{this=a},{__index=_G,__newindex=a}))()return a end
object=deftable({},function()
local function get(self,a)return self[a]end
	local function set(self,a)for b,c in pairs(a)do self[b]=c end end
	local function hash(self) return tostring(self):match("^.-%s(.-)$") end
	function struct(a)return deftable({},a)end
	function prototype(a,b)local c,d=b and a,a and b or a;local prototype=setmetatable({super=c,get=get,set=set,hash=hash},{__index=c,__call=this.create})return deftable(prototype,d,{this=prototype,super=c})end
	function create(a,...)local b=setmetatable({prototype=a},{__index=a})if a.constructor then a.constructor(b,...)end;return b end
end)

-- General utilities

function math.mid(a,b,c) return math.max(b,math.min(c,a)) end
function math.angle(a,b,c,d) return math.pi-math.atan2(b-d,a-c) end
function math.distance(a,b,c,d) return math.floor(math.sqrt((c-a)^2+(d-b)^2)) end
function math.round(a) return math.floor(a+.5) end
function math.inside(a,b,c,d,e,f) if a>=math.min(c,e)and a<math.max(c,e) and b>=math.min(d,f) and b<math.max(d,f)then return true end;return false end
function math.trunc(a,b) local c=10^b;return math.modf(a*c)/c end
function math.cycle(a,b) return time()%a>a*b end
function math.sway(a,b,c) return time()%a>a/2 and b or c end
function math.norm(a,...) local b={...}for c,d in ipairs(b)do b[c]=math.floor(d/a)*a end;return table.unpack(b)end
function math.lendir(a,b,c,d) return a+math.round(math.cos(c)*d),b-math.round(math.sin(c)*d)end

function pal(a,b)if a and b then poke4(0x3FF0*2+a,b)else for c=0,15 do poke4(0x3FF0*2+c,c)end end end

-- Core Utilities Kit

struct coreKit def
	
	function time(a)if a then return time()<a*1000 end;return time()end

	struct font def
		HEIGHT=6
		REGULAR={address=0,adjust={[2]="&",[1]="#$*?@%^%dmw",[-1]="\"%%+/<>\\{}",[-2]="()1,;%[%]`jl",[-3]="!'%.:|i"},width=5}
		BOLD={address=112,adjust={[3]="mw",[2]="#&",[1]="$*?@^%d~",[-1]="%%+/<>\\{}",[-2]="()1,;%[%]`jl",[-3]="!'%.:|i"},width=6}
		function print(a,b,...)local c,d,a,e,f,g,h=0,6,string.match(tostring(a),"(.-)\n")or tostring(a),b,...g,h=g or 0,h or(...and this.REGULAR or b)pal(15,g)for i=1,#a do local j,k=a:sub(i,i),h.width;for l,m in pairs(h.adjust)do if j:match(string.format("[%s]",m))then k=k+l end end;if j:match("%u")then k=k+1 elseif j:match("%s")and i>1 then c=c-1 end;if f then spr(h.address+j:byte()-32,e+c,f,0)end;c=c+k end;pal()return c-1,this.HEIGHT end
	end
	
	struct graphics def
		WIDTH,HEIGHT=240,136
		FILL,BOX=0xF1,0xF2
		function isLoaded(self)return time()>(self.timestamp or 0)+10 end
		function tile(a,b)pal(15,b)map(0,0,30,17,0,0,0,1,function()return a end)pal()end
		function border(a)poke(0x03FF8,a or 0)end
		function clear(a)a=a or 0;memset(0x0000,(a<<4)+a,16320)end
		function rect(a,b,c,d,e,f)(a==coreKit.graphics.BOX and rectb or rect)(b,c,d,e,f)end
		line = line
	end
	
	struct mouse def
		local buff,cur=0,0
		LEFT,MIDDLE,RIGHT=1,-1,4
		DEFAULT,WAIT,CROSSHAIR,FORBIDDEN,POINTER,TEXT,MOVE=0,1,2,3,4,5,6
		function check(...)local a,b,c=peek(0x0FF86),...if#{...}==0 then return a==0 end;if not(c)then return a==b and buff==1 else return a==b end end
		function clear()poke(0x0FF86,0)end
		function cursor(a)if a then cur=a else cur=(cur+1)%7 end end
		function inside(a,b,c,d)local e,f=peek(0x0FF84),peek(0x0FF85)return math.inside(e,f,a,b,c,d)end
		function update()local a,b,c=peek(0x0FF84),peek(0x0FF85),peek(0x0FF86)buff=c>0 and math.min(2,buff+1)or 0;poke(0x03FFB,0)pal(1,0)spr(224+cur*2,a-5,b-5,0,1,0,0,2,2)pal()end
	end
	
	struct keyboard def
		function check(a, b)return (a and keyp or key)(b)end
	end
	
end

struct UIKit def
	RELATIVE,ABSOLUTE=0xD1,0xD2
	LEFT,CENTRE,RIGHT=0,0.5,1
	TOP,MIDDLE,BOTTOM=0,0.5,1
end

prototype UIKit.Text def
	width,height=0,0
	style,lineHeight=coreKit.font.REGULAR,1
	lines={}
	function getWidth(self)return self.width end
	function getHeight(self)return self.height end
	function setWidth(self,a)self.width=math.max(0,a)end
	function setHeight(self,a)self.height=math.max(0,a)end
	function setContent(self,a)self.lines={}string.gsub(string.format("%s\n",tostring(a)),"(.-)\n",function(b)local c,d=coreKit.font.print(b,self.style)table.insert(self.lines,{b,c,d})self.width=math.max(self.width,c)end)self.height=coreKit.font.HEIGHT*self.lineHeight*#self.lines end
	constructor(self,a,b,c)self.style,self.lineHeight=b or self.style,c or self.lineHeight;self:setContent(a)end
	local function adjust(a,b,c)local d,e="",0;for f=1,#b do local g,h=b:sub(f,f),c.width;for i,j in pairs(c.adjust)do if g:match(string.format("[%s]",j))then h=h+i end end;if g:match("%u")then h=h+1 elseif g:match("%s")then e=e-1 end;if e+h-1<=a then d,e=d..g,e+h else break end end;return d,e-1 end
	function draw(self,a,b,c,d)
		local e=0
		for f,g in ipairs(self.lines) do
			local d,h,i,j=d or UIKit.LEFT,table.unpack(g)
			local k=math.floor(j*(self.lineHeight-1)/2)
			if e+j+k*2<=self.height then e=e+j+k*2 else break end
			if i>self.width then h,i=adjust(self.width,h,self.style)end
			coreKit.graphics.rect(coreKit.graphics.FILL,a+math.floor((self.width-i)*d),b+(f-1)*j*self.lineHeight+k,i,j,6)
			coreKit.font.print(h,a+math.floor((self.width-i)*d),b+(f-1)*j*self.lineHeight+k,c or 15,self.style)
		end
	end
end

prototype UIKit.Object def
	timestamp,parent=nil,nil
	x,y,width,height=0,0,0,0
	position=UIKit.RELATIVE
	enabled,active,hover=true,false,false
	onHover,onActive=nil,nil
	function getWidth(self)return self.width end
	function getHeight(self)return self.height end
	function disable(self)self.enabled=false end
	function enable(self)self.enabled=true end
	constructor(self,a)self.timestamp=time()if a then self:set(a)end end
	function update(self)if not self.parent and self.active and coreKit.mouse.check()and self.onActive then self:onActive()end;if self.enabled then self.hover=coreKit.mouse.inside(self.x,self.y,self.x+self:getWidth(),self.y+self:getHeight())self.active=self.hover and coreKit.mouse.check(coreKit.mouse.LEFT,true)end end
end

prototype UIKit.Panel def
	timestamp,parent=nil,nil
	width,height=0,0
	display,padding,separation=UIKit.RELATIVE,{horizontal=0,vertical=0},0
	enabled,overflow,elements=true,false,{}
	function getWidth(self)return self.width+self.padding.horizontal end
	function getHeight(self)return self.height+self.padding.vertical end
	function setWidth(self,a)self.width=a-self.padding.horizontal end
	function setHeight(self,b)self.height=b-self.padding.vertical end
	function setSize(self,a,b)self.width,self.height=a-self.padding.horizontal,b-self.padding.vertical end
	function size(self)return #self.elements end
	function element(self,a)return self.elements[a]end
	function disable(self)for a,b in self:iterator()do b:disable()end end
	function enable(self)for a,b in self:iterator()do b:enable()end end
	function append(self,a)a.parent=self;table.insert(self.elements,a)return a end
	function remove(self,a)for b,c in ipairs(self.elements)do if a==c then table.remove(self.elements,b)end end end
	function iterator(self,a)local b=a and a-1 or 0;return function()b=b+1;if b<=#self.elements then return b,self.elements[b]end end end
	constructor(self,a,b,c)self.elements,self.width,self.height={},a or self.width,b or self.height;if c then self:set(c)end end
	function draw(self,a,b,c)local a,b,d,e=a or 0,b or 0,{horizontal=0,vertical=0},0;for f,g in self:iterator(c)do if self.display==UIKit.RELATIVE and g.position==UIKit.RELATIVE then if d.horizontal+g:getWidth()>self.width-self.padding.horizontal then d.horizontal,d.vertical=0,d.vertical+e+self.separation end;if not self.overflow and(d.vertical+g:getHeight()>self.height-self.padding.vertical or g:getWidth()>self.width-self.padding.horizontal)then break end;g.x,g.y,e=a+self.padding.horizontal+d.horizontal,b+self.padding.vertical+d.vertical,g:getHeight()d.horizontal=d.horizontal+g:getWidth()+self.separation end;if self.onActive and g.active and coreKit.mouse.check()then self:onActive(g)end;if g.update and g.enabled and self.enabled then g:update()end;if g.draw and coreKit.graphics.isLoaded(g)then g:draw()end end end
end

prototype UIKit.Label is UIKit.Object def
	padding,border={right=0,top=0,left=0,bottom=0},0
	style,align,separation=coreKit.font.REGULAR,{horizontal=UIKit.CENTRE,vertical=UIKit.MIDDLE},1
	colour,background = 0, 15
	function setWidth(self,a)self.width=a-self.border*2-self.padding.left-self.padding.right;self.label.width=self.width end
	function setHeight(self,a)self.height=a-self.border*2-self.padding.top-self.padding.bottom;self.label.height=self.height end
	function getWidth(self)return self.border*2+self.padding.left+self.width+self.padding.right end
	function getHeight(self)return self.border*2+self.padding.top+self.height+self.padding.bottom end
	constructor(self,a,b)if b then self:set(b) end;local a=UIKit.Text(a,self.style,self.separation)super.constructor(self,{label=a,width=a.width,height=a.height})end
	function draw(self)
		if self.background>-1 then coreKit.graphics.rect(coreKit.graphics.FILL,self.x,self.y,self:getWidth(),self:getHeight(),self.background)end
		local a,b=math.round((self.width-self.label.width)*self.align.horizontal),math.round((self.height-self.label.height)*self.align.vertical)
		coreKit.graphics.rect(coreKit.graphics.FILL,self.x+self.border+self.padding.left+a,self.y+self.border+self.padding.top+a,self.label:getWidth(),self.label:getHeight(),3)
		self.label:draw(self.x+self.border+self.padding.left+a,self.y+self.border+self.padding.top+a,self.colour,self.align.horizontal)for c=0,self.border-1 do coreKit.graphics.rect(coreKit.graphics.BOX,self.x+c,self.y+c,self:getWidth()-c*2,self:getHeight()-c*2,0)end
	end
end

prototype UIKit.Button is UIKit.Label def
	padding,border={right=12,top=2,left=12,bottom=2},2
	style=coreKit.font.BOLD
	constructor(self,a,b)if b then self:set(b)end;super.constructor(self,a)end
	function draw(self)if self.active then self.colour,self.background=15,0 else self.colour,self.background=0,15 end;super.draw(self)end
end

prototype UIKit.Command is UIKit.Label def
	NAME,SEPARATOR,OPTION=0xF1,0xF2,0xF3
	padding={right=5,top=2,left=5,bottom=2}
	style,align= coreKit.font.REGULAR,{horizontal=UIKit.LEFT,vertical=UIKit.MIDDLE}
	commandView,flag=nil,nil
	
	function isActiveCommand(self)return self.parent.activeCommand==self end
	function hideCommandView(self)self.parent.activeCommand=nil end
	function append(self,a,...)local b,c,d=self.commandView:append(a,{padding={right=19,top=2,left=12,bottom=2}},true),...if a==self.SEPARATOR then b.label,b.flag,b.height=UIKit.Text(""),a,1 end;if c==self.OPTION then b.selected,b.flag=d,c end;self.commandView:setSize(math.max(self.commandView:getWidth(),b:getWidth()),self.commandView:getHeight()+b:getHeight())return b end
	function commandViewOnActive(self,a)if a.onActive then a:onActive()elseif self.parent.onActive then self.parent:onActive(a)end;if a.flag~=UIKit.Command.OPTION then self.parent:hideCommandView()end end
	function commandViewIterator(self)local a=0;return function()a=a+1;if a<=#self.elements then self:element(a):setWidth(self:getWidth())return a,self:element(a)end end end
	function update(self)if self.hover and self.commandView then self.parent.activeCommand=self end;if self.flag~=self.SEPARATOR then super.update(self)end end
	
	function draw(self)
		if self.hover or self.active or self:isActiveCommand()then self.colour,self.background=15,0 else self.colour,self.background=0,15 end
		super.draw(self)
		if self.flag==self.SEPARATOR then coreKit.graphics.line(self.x,self.y+self.padding.top,self.x+self:getWidth(),self.y+self.padding.top,0)end
		if self.flag==self.OPTION and self.selected then coreKit.font.print(string.char(32-9),self.x+2,self.y+self.padding.top,self.colour,coreKit.font.BOLD)end
		if self.shortcut and self.flag ~= self.SEPARATOR then 
			coreKit.graphics.rect(coreKit.graphics.FILL, self.x + self:getWidth() - 4 - self.shortcut:getWidth(), self.y + self.padding.top, self.shortcut:getWidth(), self.shortcut:getHeight(), 2)
			self.shortcut:draw(self.x + self:getWidth() - 4 - self.shortcut:getWidth(), self.y + self.padding.top, self.colour)
		end
		if self.commandView and self:isActiveCommand() then 
			local a,b=self.x,self.y
			if a+self.commandView:getWidth()+6>coreKit.graphics.WIDTH then a=coreKit.graphics.WIDTH-self.commandView:getWidth()-7 end
			self.commandView:draw(a,b+self:getHeight()+1)
		end 
	end
	
end

prototype UIKit.CommandView is UIKit.Panel def
	padding={horizontal=6,vertical=0}
	activeCommand=nil
	shortcutList={}
	function addShortcut(self,a,b,c)
		--if b.onActive then 
			self.shortcutList[a]=b
			b.shortcut = UIKit.Text(c, coreKit.font.BOLD)
			b.width = b.width + b.shortcut:getWidth()
		--end
	end	
	function onActive(self,a)if a.onActive then a.onActive()elseif self.parent.onActive then self.parent:onActive(a)end;if a.flag~=UIKit.Command.OPTION then self.parent:hideCommandMenu()end end
	function append(self,b,c,d)local a=UIKit.Command(b,c)if not d then a.commandView=UIKit.CommandView(0,0,{parent=a,padding={horizontal=0,vertical=0},iterator=UIKit.Command.commandViewIterator,onActive=UIKit.Command.commandViewOnActive})end;return super.append(self,a)end	
	constructor(self,...)self.shortcutList={}super.constructor(self,...)end
	function draw(self,a,b)a,b=a or 0,b or 0;for c,d in pairs(self.shortcutList)do if d.onActive and peek(0x0FF89)==65 and peek(0x0FF88)==c then d:onActive()end end;if self.parent and coreKit.mouse.check(coreKit.mouse.LEFT)and self.parent:isActiveCommand()and not coreKit.mouse.inside(a,b,a+self:getWidth(),b+self:getHeight())then self.parent:hideCommandView()end;coreKit.graphics.rect(coreKit.graphics.FILL,a,b,self:getWidth(),self:getHeight(),15)coreKit.graphics.rect(coreKit.graphics.BOX,a-1,b-1,self:getWidth()+2,self:getHeight()+2,0)super.draw(self,a,b)end
end

prototype UIKit.AlertBox is UIKit.Panel def
	width,height=coreKit.graphics.WIDTH-40,coreKit.graphics.HEIGHT-40
	padding={horizontal=5,vertical=5}
	separation=2
	function onActive(self,a)if a==self.okButton then self.parent:dismissAlert()end end
	function iterator(self,a)local b=a and a-1 or 0;return function()b=b+1;if b<=#self.elements then local c=self.elements[b]if c.prototype~=UIKit.Button then c:setWidth(self:getWidth()-20)end;return b,c end end end
	constructor(self,a,b,c)super.constructor(self,_,_,c)self.okButton=self:append(UIKit.Button("OK"))self.okButton.position=UIKit.ABSOLUTE;self:append(UIKit.Label(a,{padding={right=6,top=3,left=6,bottom=0},style=coreKit.font.BOLD,separation=1.5}))self:append(UIKit.Label(b,{padding={right=6,top=0,left=6,bottom=0},separation=1.5}))end
	function draw(self)local a,b=(coreKit.graphics.WIDTH-self:getWidth())/2,(coreKit.graphics.HEIGHT-self:getHeight())/2;self.okButton.x,self.okButton.y=(coreKit.graphics.WIDTH-self.okButton:getWidth())/2,b+self:getHeight()-self.padding.vertical*2-self.okButton:getHeight()coreKit.graphics.rect(coreKit.graphics.FILL,a,b,self:getWidth(),self:getHeight(),15)super.draw(self,a+5,b+5)coreKit.graphics.rect(coreKit.graphics.BOX,a,b,self:getWidth(),self:getHeight(),0)for c=0,1 do coreKit.graphics.rect(coreKit.graphics.BOX,a+3+c,b+3+c,self:getWidth()-c*2-6,self:getHeight()-c*2-6,0)end end
end

prototype UIKit.Icon is UIKit.Object def
	colour=0
	icon,label=256,UIKit.Text("dummy",coreKit.font.REGULAR)
	constructor(self,a,b,c)self.icon,self.label,self.drive=a,UIKit.Text(b,coreKit.font.REGULAR),c or 0;self.width,self.height=40,self.label.height+16 end
	function draw(self)local a=math.floor((self:getWidth()-self.label.width)*UIKit.CENTRE)pal(3,15)spr(self.icon,self.x+math.ceil((self:getWidth()-16)/2),self.y,1,1,0,0,2,2)pal()coreKit.graphics.rect(coreKit.graphics.FILL,self.x,self.y+14,self:getWidth(),8,15)spr(288+self.drive,self.x+math.ceil((self:getWidth()-16)/2)+3,self.y+3,1)self.label:draw(self.x+a,self.y+15,self.colour,UIKit.CENTRE)end
end	

-- Desktop Program

struct _PROGRAM def

	foreground, background, tile = 8, 7, 209
	loadTime = 1
	
	-- TitleBar/MenuBar
	
	titleBar = UIKit.Label("DESKTOP.PRG", {padding = {right = 0, top = 2, left = 0, bottom = 2}, style = coreKit.font.BOLD, border = 1, x = -1, y = -1})
	this.titleBar:setWidth(coreKit.graphics.WIDTH + 4)
	
	menuBar = UIKit.CommandView(coreKit.graphics.WIDTH, 10)
	
	local titleName, titleNameCommands = this.menuBar:append("Desktop", {style = coreKit.font.BOLD, position = UIKit.ABSOLUTE}), {}
	titleName.x, titleName.y = coreKit.graphics.WIDTH - titleName:getWidth() - 6, 0
	titleNameCommands.info = titleName:append("About Desktop... ")
	titleNameCommands.pref = titleName:append("Preferences")
	titleNameCommands.help = titleName:append("Help")
	titleName:append(UIKit.Command.SEPARATOR)
	titleNameCommands.exit = titleName:append("Quit")
	
	function titleNameCommands.info:onActive()
		this:showAlert("GEM/1 Desktop, Dec. 2021\ntic80", "Graphics Environment Manager\nhttp://github.com/jotapapel/GEM-tic80\nCopyleft (l) 2021")
	end
	
	function titleNameCommands.exit:onActive()
		exit()
	end
	
	this.menuBar:addShortcut(9, titleNameCommands.info, "^I")
	this.menuBar:addShortcut(17, titleNameCommands.exit, "^Q")
	
	local fileName, fileNameCommands = this.menuBar:append("File"), {}
	fileNameCommands.open = fileName:append("Open")
	fileNameCommands.info = fileName:append("Info/Rename")
	fileNameCommands.delt = fileName:append("Delete")
	fileName:append(UIKit.Command.SEPARATOR)
	fileNameCommands.newf = fileName:append("New folder")
	fileNameCommands.clsf = fileName:append("Close folder")
	fileNameCommands.clsw = fileName:append("Close window")
	
	local viewName, viewNameOptions = this.menuBar:append("View"), {}
	viewNameOptions.icon = viewName:append("View as icons", UIKit.Command.OPTION, true)
	viewNameOptions.text = viewName:append("View as text", UIKit.Command.OPTION)
	viewName:append(UIKit.Command.SEPARATOR)
	viewNameOptions.name = viewName:append("Sort by name", UIKit.Command.OPTION, true)
	viewNameOptions.type = viewName:append("Sort by type", UIKit.Command.OPTION)
	viewNameOptions.size = viewName:append("Sort by size", UIKit.Command.OPTION)
	viewNameOptions.date = viewName:append("Sort by date", UIKit.Command.OPTION)
	
	function viewName:onActive(command)
		if command == viewNameOptions.text then
			viewNameOptions.icon.selected, viewNameOptions.text.selected = false, true
		elseif command == viewNameOptions.icon then
			viewNameOptions.icon.selected, viewNameOptions.text.selected = true, false
		end
	end
	
	this.menuBar:addShortcut(28, viewNameOptions.icon, "^M")
	this.menuBar:addShortcut(29, viewNameOptions.text, "^T")
	
	local optionsName, optionsNameCommands = this.menuBar:append("Options"), {}
	optionsNameCommands.idrv = optionsName:append("Format drive")
	optionsNameCommands.exec = optionsName:append("Execute command")
	optionsName:append(UIKit.Command.SEPARATOR)
	optionsNameCommands.sbkg = optionsName:append("Set background... ")
	
	-- IconView
	
	iconView = UIKit.Panel(40, coreKit.graphics.HEIGHT - 10)
	this.iconView.separation = 7
	this.iconView:append(UIKit.Icon(258, "floppy d.", 1))
	this.iconView:append(UIKit.Icon(260, "h. drive", 3))
	this.iconView:append(UIKit.Icon(264, "trash"))
	
	-- AlertView
	
	alertView = nil
	
	function showAlert(self, title, subtitle, icon)
		if not self.alertBox then
			self.menuBar:disable()
			self.alertBox = UIKit.AlertBox(title, subtitle, {parent = self})
		end
	end
	
	function dismissAlert(self)
		self.menuBar:enable()
		self.alertBox = nil
	end
	
	-- TIC function
	
	function _G.TIC()
		coreKit.graphics.clear(this.background)
		coreKit.graphics.tile(this.tile, this.foreground)
		if coreKit.time(this.loadTime) then
			coreKit.mouse.cursor(coreKit.mouse.WAIT)
			this.titleBar:draw()
		else
			coreKit.mouse.cursor(coreKit.mouse.DEFAULT)
			this.iconView:draw(coreKit.graphics.WIDTH - this.iconView:getWidth() - 8, 19)
			this.menuBar:draw()
			if this.alertBox then this.alertBox:draw() end
		end
		coreKit.mouse.update()
	end

end