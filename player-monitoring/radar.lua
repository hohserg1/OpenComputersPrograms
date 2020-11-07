-- This is a part of program for monitoring of player visiting
-- Required HoverHelm platform 
-- https://computercraft.ru/topic/3771-hoverhelm-operatsionnaya-sistema-dlya-dronov-mikrokontrollerov-i-drugih-ustroystv-bez-sobstvennogo-zhestkogo-diska/

--WARNING! This program must be placed to device folder instead of core folder! Need for self-destroy `githubToken`

--configuration
local sleepTime = 1 --seconds scanning interval
local gistId = "" -- create new secret gist and insert id here
local githubToken = "" -- visit https://github.com/settings/tokens for create and copy OAuth token for Gist
local programLocation = "/programs/radar.lua" -- it file vill be removed when otusiderplayer will closer to main device
local screenWidth,screenHeight = 100,50
local playersWhitelist = {["^^Cheburek^^"]=true}
local radarModemsWhitelist = {}

local detectors = map(component.list("os_entdetector"), component.proxy)
local radars = map(component.list("radar"), component.proxy)
local filesystem = component.filesystem
local internet = component.internet


local scanFunctions = {}
do
    local function detectorScan(detector)
        return function(relativeRadius) 
            return map(detector.scanPlayers(relativeRadius*64), function(_, v) return v.name, v.range end)
        end
    end

    local function radarScan(radar)
        return function(relativeRadius)
            return map(radar.getPlayers(relativeRadius*8), function(_, v) return v.name, v.distance end)
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


local gistSendingCache = {}

local function gistFlush()
    internet.request(
        "https://api.github.com/gists/"..gistId.."/comments", 
        '{"body":"'..table.concat(gistSendingCache,"\\n")..'"}', 
        {Authorization="token "..githubToken, Accept="application/vnd.github.v3+json"},
        "POST"
    )
    gistSendingCache = {}
end

local function table2string(t)
    local r="{"
    
    for k,v in pairs(t) do
        r=r..tostring(k).."->"..tostring(v)..", "
    end
    r=r.."}"
    
    return r
end


while true do
    local scanned = {}
    local foundAny=false
    for _, scan in pairs(scanFunctions) do
        --log.print("test1",table2string(scan(1)))
        for name, range in pairs(scan(1)) do
            scanned[name]=range
            foundAny=true
        end
    end
        --log.print("test2",foundAny)
    
    
    if foundAny then
    
        log.warn("Radar "..bios.name.." found next players:")
        table.insert(gistSendingCache, "["..timeMark().."] Radar "..bios.name.." found next players:")
        
        local foundOutsider = false
        local dangerousOutsider = false
        
        for name, range in pairs(scanned) do
            local msg = "    "..name.." [ "..range.." ]"
            if playersWhitelist[name] then
                log.print(msg)
            else
                foundOutsider=true
                dangerousOutsider = dangerousOutsider or range<=20
                log.error(msg)
            end
            table.insert(gistSendingCache, msg)
        end
        
        if foundOutsider then
            gistFlush()
        end
        
        if dangerousOutsider then
            filesystem.remove(programLocation)
        end
        
    end
    
    
    sleep(sleepTime)
end
    
    
