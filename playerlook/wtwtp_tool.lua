local component=require("component")
local gps=require("gps")
local serialization=require("serialization")
cos=math.cos
sin=math.sin

local cx,cy,cz = -1408,0,512

local yaw=component.tablet.getYaw()
local pitch=component.tablet.getPitch()

local function getPlayerPos()
	local x,y,z = component.navigation.getPosition()
	return x+cx,y+cy,z+cz
end

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

local function getChinkPos()
	local x,y,z = component.navigation.getPosition()
	return math.floor(x/4),math.floor(y/4),math.floor(z/4)
end

print("player position is",getPlayerPos())
print("player chink pos is",getChinkPos())
print("player look vec is",getLookVec(yaw,pitch))
print("player yaw pitch is",yaw,pitch)

local px,py,pz=getPlayerPos()
local lx,ly,lz=getLookVec(yaw,pitch)

component.tunnel.send("getLookAtBlockPos",px,py,pz,yaw,pitch)
