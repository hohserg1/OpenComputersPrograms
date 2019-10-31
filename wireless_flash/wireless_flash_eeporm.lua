setmetatable(
	component,
	{__index=function(t,key) return component.proxy(component.list(key)()) end}
)

local o_G=_G

local function safeLoad(code)
	local _g={}
	for k,v in pairs(o_G) do
		_g[k]=v
	end
	
	return load(code,"bios",_,_g)
end

local function print(msg)
	component.drone.setStatusText(msg)
end

local function receive(event_name,_,_,_,_, msg,code)
	if event_name and event_name=="modem_message" and msg=="eeprom_update" then
		
		local r,err=safeLoad(code)
		if r then
			local ok,err1=pcall(r)
			if not ok then
				error(err1)
			end
		else
			error(err)
		end
	end
end
component.modem.open(1)

local pullSignal=computer.pullSignal

computer.pullSignal=function(t)
	local e={pullSignal(t)}
	if #e > 0 then
		receive(table.unpack(e))
	end
	return table.unpack(e)
end

while true do 
	computer.pullSignal(10)
end
