local stemChannel = "test"
local serverName = "Test"
local greetingTime = 10 --seconds
local onlineCheckPeriod = 10 --seconds

local component = require("component")
local computer = require("computer")
local stem = require("stem")
local event = require("event")
local serialization = require("serialization")

local debug = computer.addUser
local bug = computer.removeUser
local gpu = component.gpu
local internet = component.internet
xresolution=60
gpu.setResolution(xresolution,52)
gpu.setBackground(0x202020)
gpu.setForeground(0xFFDD00)
gpu.fill(1,1,xresolution,75," ")
gpu.set((30-(string.len("DeviceCraft Managment"))/2),2,"DeviceCraft Managment")
gpu.set((30-(string.len("By Durex77 and hohserg"))/2),3,"By Durex77 and hohserg")
status1=" [Online at "
status2=" [Offline]"

local emptyTable = {}

local function copy(t)
    local r = {}
    for k,v in pairs(t) do
        r[k]=v
    end
    return r
end

local server = stem.connect('stem.fomalhaut.me')
server:subscribe(stemChannel)

local function send(name, t)
    t.name=name
    server:send(stemChannel,serialization.serialize(t))
end

send("start_session", {serverName=serverName})

local knownServers = {}
local knownPlayers = {}--{hohserg="admin"}
local groupColors = setmetatable({["admin"]=0xff0000, moder=0x0000ff},{__index=function()return 0xffffff end})
local groupOrder = {"admin","moder"}

do
    local endTime = computer.uptime()+greetingTime
    while computer.uptime()<endTime do
        local message = select(3, event.pull(endTime-computer.uptime(), 'stem_message',stemChannel))
        if message then
            message = serialization.unserialize(message)
            if message.name=="greet" then
                knownServers[message.serverName]=true
            end
        end
    end
end

local prevOnline = {}
local lastOnline = {}

local lastServersInfoRequired = {count=#knownServers, names=copy(knownServers)}

local function removeRequiredServer(name)
    if lastServersInfoRequired.names[name] then
        lastServersInfoRequired.names[name]=nil
        lastServersInfoRequired.count=lastServersInfoRequired.count-1
    end
end

local function drawCenteredString(y,line)
    gpu.set(xresolution/2-string.len(line)/2,y,line)
end

local function drawList(info, group, d)
    d=d+2
    gpu.setForeground(groupColors[group])
    gpu.set((xresolution/2-(string.len("["..group.."]"))/2),d,"["..group.."]")
    d=d+1

    for playerName,serverName in pairs(info) do
        d=d+1
        if serverName~="offline" then gpu.setForeground(0x00FF00) drawCenteredString(d, playerName..status1..serverName.."]") else gpu.setForeground(0xFF0000) drawCenteredString(d, playerName..status2) end
    end
    
    return d
end

local function flushOnline()
    prevOnline = {}
    for serverName, info in pairs(lastOnline) do
        for _, playerName in ipairs(info) do
            prevOnline[playerName]=serverName
        end
    end
    
    local grouped = {}
    
    for playerName,group in pairs(knownPlayers) do
        grouped[group]=grouped[group] or {}
        grouped[group][playerName]=prevOnline[playerName] or "offline"
        prevOnline[playerName]=nil
    end
    
    for playerName, serverName in pairs(prevOnline) do
        local group
        send("unknow_player",{playerName=playerName})
        print("not fine")
        while not group do
            local message = select(3, event.pull('stem_message',stemChannel))
            if message then
                message = serialization.unserialize(message)
                if message.name=="update_player" then
                    group=message.group
                    knownPlayers[playerName]=group
                    print("fine")
                end
            end
        end
        grouped[group]=grouped[group] or {}
        grouped[group][playerName]=serverName
    end
    
    gpu.fill(1,4,xresolution,52," ")
    
    local d=4    
    for _, group in pairs(groupOrder) do
        d = drawList(grouped[group] or emptyTable,group, d)
    end
end

local function handleOnlineInfo(message)
    removeRequiredServer(message.serverName)
    lastOnline[message.serverName]=message.info
    if lastServersInfoRequired.count==0 then
        flushOnline()
        lastOnline = {}
        lastServersInfoRequired = {count=#knownServers, names=copy(knownServers)}            
    end
end

event.listen('stem_message', function(_, _, message)
    local message = serialization.unserialize(message)
    if message.name=="online_info" then
        handleOnlineInfo(message)
    elseif message.name=="start_session" then
        knownServers[message.serverName]=true
        send("greet",{serverName=serverName})
    elseif message.name=="add_player" then
        knownPlayers[message.playerName]=message.group
    elseif message.name=="remove_player" then
        knownPlayers[message.playerName]=nil
    elseif message.name=="unknow_player" then
        local foundGroup = knownPlayers[message.playerName]
        if foundGroup then
            send("update_player",{playerName=message.playerName,group=foundGroup})
        end  
    end
end)

local function split(str, separator)
    local r = {}
    for ri in string.gmatch(str, "([^" .. separator .. "]+)") do
        table.insert(r, ri)
    end
    return r
end

local function isPermited(playerName)
    return knownPlayers[playerName]=="admin" or true
end

event.listen('chat_message', function(_, _, playerName, message)
    if isPermited(playerName) then
        if message:sub(1,2)=="##" then
            local cmd = split(message:sub(3)," ")
            if cmd[1]=="adduser" then
                knownPlayers[cmd[2]]=cmd[3]
                send("add_player",{playerName=cmd[2],group=cmd[3]})
            
            elseif cmd[1]=="deluser" then
                knownPlayers[cmd[2]]=nil
                send("remove_player",{playerName=cmd[2]})        
            end
            
        end
    end
end)


local function chechOnline(playerName)
    if debug(playerName) then
        bug(playerName)
        return true
    else
        return false
    end
end

while true do
    local info = {}
    for playerName, group in pairs(knownPlayers) do
        if chechOnline(playerName) then
            table.insert(info, playerName)
        end
    end
    local msg = {serverName=serverName, info=info}
    send("online_info",msg)
    handleOnlineInfo(msg)
    os.sleep(onlineCheckPeriod)
end

