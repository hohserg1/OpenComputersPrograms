local serialization=require("serialization")
local geohelp=require("geohelp")
local component = require('component')
local geolyzer = component.geolyzer
local event = require('event')
cos=math.cos
sin=math.sin
max=math.max
sqrt=math.sqrt
abs=math.abs

local geolyzerAbsolutePos = {-1408,5,512}
local glassesAbsolutePos = {-1408,4,512}
local glasses = loadfile("glasses.lua")(glassesAbsolutePos)

glasses.removeAll()

local function absoluteToLocal(absolute,x,y,z)
	return x-absolute[1],y-absolute[2],z-absolute[3]
end
local function localToAbsolute(absolute,x,y,z)
	return x+absolute[1],y+absolute[2],z+absolute[3]
end

local function roundChink(...)
	local seq={...}
	for i=1,#seq do
		seq[i]=math.floor(seq[i]/4)
	end
	return table.unpack(seq)
end

local x1,y1,z1,x2,y2,z2 = roundChink(...)
print(x1,y1,z1,x2,y2,z2)




local function key(x,y,z)
	if type(x)=="table" then
		return key(x.x,x.y,x.z)
	else
		return x .. "," .. y .. "," ..z
	end
end

local area={}

for x=x1,x2 do
	for y=y1,y2 do
		for z=z1,z2 do
			local chink = geolyzer.scan(x*4,z*4,y*4,4,4,4)
			area[key(x,y,z)]=chink
			--[[
			for i=x*4,x*4+3 do
				for j=y*4,y*4+3 do
					for k=z*4,z*4+3 do
						local val=chink[geohelp.tblpos(x*4,z*4,y*4,4,4,4,i,k,j)]
						if val and val>0 then
							local c=glasses.addCube3D()
							c.set3DPos(localToAbsolute(geolyzerAbsolutePos,i,j,k))
							c.setVisibleThroughObjects(true)
						end
						os.sleep(0)
					end
				end
			end]]
		end
	end
end

local function getBlockDensityAt(x,y,z)
	x,y,z=absoluteToLocal(geolyzerAbsolutePos,x,y,z)
	local chinkX,Y,Z=math.floor(x/4),math.floor(y/4),math.floor(z/4)
	local r = area[key(chinkX,Y,Z)][geohelp.tblpos(chinkX*4,Z*4,Y*4,4,4,4,x,z,y)]
	return r or 0
end

local function add(v1,v2)
	return {x=v1.x+v2.x, y=v1.y+v2.y, z=v1.z+v2.z}
end

local function scale(v,m)
	return {x=v.x*m,y=v.y*m,z=v.z*m}
end

local function sq(v)
	return v*v
end

local function distanceSq(px,py,pz,curx,cury,curz)
	return sq(px-curx) + sq(py-cury) + sq(pz-curz)
end

local maxDistance=distanceSq(x1*4,y1*4,z1*4,x2*4,y2*4,z2*4)




local function getLookVec(yaw,pitch)
	if(pitch==90)then
		return 0,-1,0
	elseif(pitch==-90)then
		return 0,1,0
	else
		local f = cos(-yaw * 0.017453292 - math.pi);
		local f1 = sin(-yaw * 0.017453292 - math.pi);
		local f2 = -cos(-pitch * 0.017453292);
		local f3 = sin(-pitch * 0.017453292);
		return f1 * f2, f3, f * f2;
	end
end

local function tryprintWrapper(f)
	return function(...)
		local success,err=pcall(f,...)
		if not success then print(err) end
	end
end

pcall(event.cancel,modem_message_handle)
modem_message_handle = event.listen("modem_message",tryprintWrapper(function(_,_,_,_,_, msg,...)
	if msg=="getLookAtBlockPos" then
		local px,py,pz,yaw,pitch=...
		local lx,ly,lz=getLookVec(yaw,pitch)
		
		--[[local minScale,maxScale=0.2,0.8
		local a=sqrt(2)/2
		local len2,len1=(maxScale-minScale),(1-a)
		
		local coef=(max(abs(sin(pitch)),abs(cos(pitch)))-a)/len1
		
		local scale=abs(coef*len2-a*len2+minScale*len1)/len1]]
		
		local scale = 0.5
		
		local result=nil
		local curx,cury,curz = px,py,pz
		
		glasses.removeAll()
		
		local r,g,b=255,0,0
		
		local line1 = glasses.addLine3D()
		line1.setVertex(2,px,py,pz)
		line1.setColor(r,g,b)
		
		local line2
		
		while not result and distanceSq(px,py,pz,curx,cury,curz)<maxDistance do
			curx,cury,curz = curx+lx*scale,cury+ly*scale,curz+lz*scale
			
			line2 = glasses.addLine3D()
			line2.setColor(r,g,b)
			
			line1.setVertex(2,curx,cury,curz)
			line2.setVertex(1,curx,cury,curz)
			line2.setVertex(2,curx,cury,curz)
			
			line1=line2
			r,b=b,r
			
			local x,y,z=math.floor(curx),math.floor(cury),math.floor(curz)
			
			if getBlockDensityAt(x,y,z) > 0 then
				result={x,y,z}
				local target = glasses.addCube3D()
				target.set3DPos(x,y,z)
				target.setColor(0,250,250)
				target.setVisibleThroughObjects(true)
			end
			os.sleep(0)
		end
		
		print("player are look at",serialization.serialize(result))
		
	end
end))


