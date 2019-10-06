--return function(glassesAbsolutePos,componentAddress)
	local glassesAbsolutePos = ...
	local component = require('component')
	--componentAddress=componentAddress or component.list("glasses")()
	--local oglasses=component.proxy(componentAddress)
	local oglasses=component.glasses

	local function absoluteToLocal(x,y,z)
		return x-glassesAbsolutePos[1],y-glassesAbsolutePos[2],z-glassesAbsolutePos[3]
	end

	local aglasses=setmetatable({},{__index=function(_,key)
		if(string.match(key,"add") and string.match(key,"3D"))then
			return function(...)
				local wrapper={}
				local original=oglasses[key](...)
				return setmetatable(wrapper,{__index=function(_,key)
					if key=="set3DPos" then
						return function(x,y,z)
							return original.set3DPos(absoluteToLocal(x,y,z))					
						end
					elseif key=="setVertex" then
						return function(v,x,y,z)
							return original.setVertex(v,absoluteToLocal(x,y,z))					
						end
					else
						return original[key]
					end
				end})
			end
		else
			return oglasses[key]
		end
	end})

	return aglasses
--end
