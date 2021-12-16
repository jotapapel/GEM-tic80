-- Core Utilities Kit

struct coreKit def

	struct font def
		HEIGHT=6
		REGULAR={address=0,adjust={[2]="&",[1]="#$*?@%^%dmw",[-1]="\"%%+/<>\\{}",[-2]="()1,;%[%]`jl",[-3]="!'%.:|i"},width=5}
		BOLD={address=112,adjust={[3]="mw",[2]="#&",[1]="$*?@^%dMW~",[-1]="%%+/<>\\{}",[-2]="()1,;%[%]`jl",[-3]="!'%.:|i"},width=6}
		func print(a,b,...)local c,d,a,e,f,g,h=0,6,string.match(tostring(a),"(.-)\n")or tostring(a),b,...g,h=g or 0,h or(...and coreKit.font.REGULAR or b)pal(15,g)for i=1,#a do local j,k=a:sub(i,i),h.width;for l,m in pairs(h.adjust)do if j:match(string.format("[%s]",m))then k=k+l end end;if j:match("%u")then k=k+1 elseif j:match("%s")and i>1 then c=c-1 end;if f then spr(h.address+j:byte()-32,e+c,f,0)end;c=c+k end;pal()return c-1,coreKit.font.HEIGHT end
	end
	
	struct graphics def
		WIDTH,HEIGHT=240,136
		FILL,BOX=0xF1,0xF2
		func isLoaded(self)return time()>(self.timestamp or 0)+10 end
		func border(a)poke(0x03FF8,a or 0)end
		func clear(a)a=a or 0;memset(0x0000,(a<<4)+a,16320)end
		func rect(a,b,c,d,e,f)(a==coreKit.graphics.BOX and rectb or rect)(b,c,d,e,f)end
	end
	
	struct mouse def	
		local buff,cur=0,0
		LEFT,MIDDLE,RIGHT=1,-1,4
		DEFAULT,WAIT,CROSSHAIR,FORBIDDEN,POINTER,TEXT,MOVE=0,1,2,3,4,5,6
		func check(...)local a,b,c=peek(0x0FF86),...if#{...}==0 then return a==0 end;if not(c)then return a==b and buff==1 else return a==b end end
		func clear()poke(0x0FF86,0)end
		func cursor(a)if a then cur=a else cur=(cur+1)%7 end end
		func inside(a,b,c,d)local e,f=peek(0x0FF84),peek(0x0FF85)return math.inside(e,f,a,b,c,d)end
		func update()local a,b,c=peek(0x0FF84),peek(0x0FF85),peek(0x0FF86)buff=c>0 and math.min(2,buff+1)or 0;poke(0x03FFB,0)pal(1,0)spr(224+cur*2,a-5,b-5,0,1,0,0,2,2)pal()end
	end
	
end