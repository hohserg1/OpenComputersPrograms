local gistId=""
local githubToken = ""

local component = require("component")
local computer = require("computer")
local debug = computer.addUser
local gpu = component.gpu
local internet = component.internet
xresolution=60
gpu.setResolution(xresolution,52)
gpu.setBackground(0x202020)
gpu.setForeground(0xFFDD00)
gpu.fill(1,1,xresolution,75," ")
gpu.set((30-(string.len("DeviceCraft Managment"))/2),2,"DeviceCraft Managment")
gpu.set((30-(string.len("By Durex77 and hohserg"))/2),3,"By Durex77 and hohserg")
status1=" [Online] "
status2=" [Offline]"

local function request(...)
    local h = internet.request(...)
    local answer,chunk = "",""
    while chunk do
        chunk = h.read()
        answer = answer..(chunk or "")
    end
    return answer
end

local json = require and require"json" or load(request("https://raw.githubusercontent.com/rxi/json.lua/master/json.lua"))

local function requestJson(...)
    return json.decode(request(...))
end

local headers = {Authorization="token "..githubToken, Accept="application/vnd.github.v3+json"}

local  function readConfig()
    local configUrl = requestJson(
        "https://api.github.com/gists/"..gistId,
        nil, 
        headers,
        "GET"
    ).files["online-tracker-config.lua"].raw_url
        
    --return io.open("online-tracker-config.lua"):read("*a")
    
    return request(configUrl)
end

local function updateConfig()
    print(request(
        "https://api.github.com/gists/"..gistId,
        json.encode({description="test"}),
        {
            Authorization="token "..githubToken, 
            Accept="application/vnd.github.v3+json",
            ["X-HTTP-Method-Override"]="PATCH"
        },
        "PATCH"
    ))
    os.sleep(100)

end

updateConfig()
local lists = load(readConfig())()


local function drawList(list, name, color, d)
    d=d+2
    gpu.setForeground(color)
    gpu.set((xresolution/2-(string.len("["..name.."]"))/2),d,"["..name.."]")
    d=d+1

    for j = 1, #list do
        d=d+1
        name=list[j]
        prov=debug(name)
        if prov ~= nil then gpu.setForeground(0x00FF00) gpu.set(((xresolution/2)-4-(string.len(name))/2),d,name..status1) else gpu.setForeground(0xFF0000) gpu.set(((xresolution/2)-4-(string.len(name))/2),d,name..status2) end
        computer.removeUser(name)
    end
    
    return d
end

while true do
    d=4
    
    for _, list in pairs(lists) do
        d = drawList(list[2],list[1], list[3], d)
    end


    os.sleep(1.5)

end
