-- This is a part of program for monitoring of player visiting
-- Required HoverHelm platform 
-- https://computercraft.ru/topic/3771-hoverhelm-operatsionnaya-sistema-dlya-dronov-mikrokontrollerov-i-drugih-ustroystv-bez-sobstvennogo-zhestkogo-diska/

--configuration
local sleepTime = 10 --seconds scanning interval
local mainServer = "8cbb2487-943b-41c4-a621-4e814b7088c6" -- main log server modem address

local detectors = map(component.list("os_entdetector"), component.proxy) --OpenSecurity
local radars = map(component.list("radar"), component.proxy) --Computronics
local modem = component.modem


local scanFunctions = {}
do
    local function detectorScan(detector)
        return function(relativeRadius) 
            return mapSeq(detector.scanPlayers(relativeRadius*64), function(v) return v.name end) 
        end
    end

    local function radarScan(radar)
        return function(relativeRadius)
            return mapSeq(radar.getPlayers(relativeRadius*8), function(v) return v.name end)
        end
    end
    
    local function insertScan(_, scan) table.insert(scanFunctions,scan) end
    foreach(mapSeq(detectors, detectorScan), insertScan)
    foreach(mapSeq(radars, radarScan), insertScan)
end

local function sleep(interval)
    local start = computer.uptime()
    while computer.uptime() - start < interval do
        computer.pullSignal(interval - (computer.uptime() - start))
    end
end

while true do
    local scanned = {}
    for _, scan in ipairs(scanFunctions) do
        for _, nickname in ipairs(scan(1)) do
            scanned[nickname]=true
        end
    end
    
    local r = {}
    for nickname in pairs(scanned) do
        table.insert(r,nickname)
    end
    modem.send(mainServer, bios.port, bios.name, table.concat(r,"|"))
    
    
    sleep(sleepTime)
end
    
    
