-- This is a part of program for monitoring of player visiting
-- Required HoverHelm platform 
-- https://computercraft.ru/topic/3771-hoverhelm-operatsionnaya-sistema-dlya-dronov-mikrokontrollerov-i-drugih-ustroystv-bez-sobstvennogo-zhestkogo-diska/

--WARNING! This program must be placed to device folder instead of core folder! Need for self-destroy `githubToken`

--configuration
local gistId = "" -- create new secret gist and insert id here
local githubToken = "" -- visit https://github.com/settings/tokens for create and copy OAuth token for Gist
local programLocation = "/programs/rserver.lua" -- it file vill be removed when otusiderplayer will closer to main device
local screenWidth,screenHeight = 100,50
local playersWhitelist = {hohserg=true, ["^^Cheburek^^"]=true}
local radarModemsWhitelist = {}

local modem = component.modem
local filesystem = component.filesystem
local internet = component.internet
local gpu = component.gpu
local detector = component.os_entdetector


local function isValidModem(address)
    --return radarModemsWhitelist[address]
    return address ~= bios.serverAddress
end

local function playerColor(nickname)
    return playersWhitelist[nickname] and 0x00ff00 or 0xff0000
end


--local h = filesystem.open("radarLog.txt","w")

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

gpu.bind(component.screen.address)
gpu.setResolution(screenWidth,screenHeight)
local function printLog(msg, color)
    gpu.copy(1, 2,screenWidth, screenHeight, 0,-1)
    gpu.fill(1, screenHeight, screenWidth, 1, " ")
    gpu.setForeground(color)
    gpu.set(1, screenHeight, msg)
    
    table.insert(gistSendingCache, msg)
end


while true do
    local event_name,_, remoteAddress, port, _, deviceName, nicknames = computer.pullSignal(math.huge)
    if event_name=="modem_message" and port==bios.port and isValidModem(remoteAddress) then
        printLog("["..timeMark().."] Radar "..deviceName.." found next players:",0x0000ff)
        local foundOutsider = false
        local dangerousOutsider = false
        
        local internalScan = mapSeq(detector.scanPlayers(20), function(v) return v.name end) 
        
        for _, nickname in ipairs(internalScan) do
            if not playersWhitelist[nickname] then
                foundOutsider = true
                dangerousOutsider = true
            end
        end
        
        for _, nickname in ipairs({split(nicknames, "|")}) do
            printLog("    "..nickname, playerColor(nickname))
            
            if not playersWhitelist[nickname] then
                foundOutsider = true
            end
        end
        
        if foundOutsider then
            gistFlush()
        end
        
        if dangerousOutsider then
            filesystem.remove(programLocation)
        
        end
        
    end
end
