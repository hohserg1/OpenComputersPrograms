local gpu = component.proxy(component.list("gpu")())
gpu.bind(({component.list("screen")()})[1])
local w,h = gpu.getResolution()

local invoke = component.invoke
local fs = {}
local fsList = {}
local fsCounter = 0
for a in component.list("file") do
    local name = invoke(a,"getLabel")
    if not name then
        name = a
    end
    name = name.."/"
    fsList[fsCounter]=name
    fs[fsCounter]=a
    fsCounter=fsCounter+1
end



local stateFiles=1
local stateMenuFiles=2
local stateEditor=3
local stateMenuEditor=4
local stateLua=5
local state = stateFiles

local currentPath = "/"
local currentFilesystem = -1
local selected = 0
local currentContent = fsList
local scrollShift = 0

local function fsInvoke(...)
    return invoke(fs[currentFilesystem], ...)
end

local function drawFileManager()
    gpu.setForeground(0xffffff)
    gpu.setBackground(0)
    
    gpu.fill(1,1,50,16," ")
    
    if currentFilesystem == -1 then
        gpu.set(1,1,"/")
    else
        gpu.set(1,1,"/"..fsList[currentFilesystem]:sub(1,-2)..currentPath)
    end
    gpu.set(1,2,("="):rep(50))
    
    for i = scrollShift,(math.min(scrollShift+13,#currentContent)) do
        local e = currentContent[i]
        local y = i-scrollShift
        gpu.set(3,3+y, e)
    end
    gpu.setBackground(0xffffff)
    gpu.setForeground(0)
    gpu.set(2,3+selected-scrollShift, " "..currentContent[selected].." ")
end

local function updateContent()
    if currentFilesystem ~= -1 then
        currentContent = fsInvoke("list",currentPath)
        currentContent[0] = "⬅"
    end
    selected = 0
    scrollShift = 0
end

local function moveBack()
    if currentPath=="/" then
        if currentFilesystem ~= -1 then
            currentFilesystem = -1
            currentContent = fsList
        end
    else
        local lastSeparator = currentPath:sub(1,-2):match'^.*()/'
        currentPath = currentPath:sub(1,lastSeparator)
    end
    updateContent()
end

local function moveForward()
    if currentFilesystem == -1 then
        currentFilesystem=selected
    else
        local e = currentContent[selected]
        if e=="⬅" then
            moveBack()
        elseif e:sub(-1,-1)=="/" then
            currentPath=currentPath..e
        end
    end
    updateContent()
end

local function fixScroll()
    if selected>scrollShift+12 then
        if scrollShift==0 and selected==#currentContent then
            scrollShift = #currentContent-13
        elseif scrollShift+13<#currentContent then
            scrollShift = scrollShift+1
        end
       
    elseif selected<scrollShift then
        if scrollShift==#currentContent-13 and selected==0 then
            scrollShift=0
        else
            scrollShift = scrollShift-1
        end
    end
end

local picked = nil
local pickedTypeCopy = 1
local pickedTypeCut = 1
local pickedType = pickedTypeCopy

local menuContent = {}
local menuSelected = 0
local menuActions = {
    ["new file"]=function()
        local newName = input()
        openEditor(currentPath..newName)
    end,
    
    ["new folder"]=function()
        local newName = input()
        fsInvoke("makeDirectory", currentPath..newName)
    end,
    
    paste = function()
        fsInvoke("rename", picked[1]..picked[2], currentPath..picked[2])
        picked=nil
    end,
    
    edit = function()
        
    end,
    
    execute = function()
        local fileName = currentPath..currentContent[selected]
        local h = fsInvoke("open", fileName)
        local code = ""
        while true do
            local chunk = fsInvoke("read", h, math.huge)
            if chunk then
                code=code..chunk
            else
                break
            end
        end
        local func, compileErr = load(code,fileName)
        if func then
            local ok, execErr = pcall(func)
            if not ok then
                message("Execution error:", execErr)
            end
        else
            message("Compilation error:", compileErr)
        end
        state=stateFiles
    end,
    
    delete = function()
        fsInvoke("remove",currentPath..currentContent[selected])
        state=stateFiles
        updateContent()
        prn("delete", state)
    end,
    
    rename = function()
        local newName = input()
        fsInvoke("rename", currentPath..currentContent[selected], currentPath..newName)
    end,
    
    copy = function()
        picked={currentPath, currentContent[selected]}
        pickedType = pickedTypeCopy
    end,
    
    cut = function()
        picked={currentPath, currentContent[selected]}
        pickedType = pickedTypeCut
    end
}

local function updateMenuFilesContent()
    local e = currentContent[selected]
    
    menuContent = {}
    
    if e=="⬅" then
        menuContent = {[0]="new file", "new folder","paste"}
        
    else
        if e:sub(-1,-1) ~= "/" then
            menuContent = {[0]="edit","execute"}
        end
        menuContent[#menuContent+1] = "delete"
        menuContent[#menuContent+1] = "rename"
        menuContent[#menuContent+1] = "copy"
        menuContent[#menuContent+1] = "cut"
    end
    
    --[[
    if e:sub(-1,-1)=="/" then
            delete
            rename
            copy
            cut
           
        
    elseif e=="⬅" then
            new file
            new folder
            paste
            
    else
            edit
            execute
            delete
            rename
            copy
            cut
    end
    ]]
end

local function drawMenuFiles()
    gpu.setBackground(0xffffff)
    gpu.setForeground(0)
    gpu.fill(7,3,36,10," ")
    
    for i=0,#menuContent do
        local me = menuContent[i]
        gpu.set(9,4+i,me)
    end
    
    gpu.setForeground(0xffffff)
    gpu.setBackground(0)
    gpu.set(8,4+menuSelected, " "..menuContent[menuSelected].." ")
end

local function applyMenuFiles()
    menuActions[menuContent[menuSelected]]()
end

local function draw()
    prn("draw",state)
    if state==stateFiles then
        drawFileManager()
            
    elseif state==stateMenuFiles then
        drawMenuFiles()
    end
end

draw()

local up = 200
local down = 208
local right = 205
local enter = 28
local left = 203
local menu = 221

while true do
    local event,_,chat,code,_ = computer.pullSignal()
    if event=="key_down" then
        if state==stateFiles then
            if code==up then
                selected=(selected-1) % (#currentContent+1)
                fixScroll()
                
            elseif code==down then
                selected=(selected+1) % (#currentContent+1)
                fixScroll()
            
            elseif code==right or code==enter then
                moveForward()
            
            elseif code==left then
                moveBack()
            
            elseif code==menu then
                state=stateMenuFiles
                updateMenuFilesContent()
            end
            
        elseif state==stateMenuFiles then
            if code==up then
                menuSelected=(menuSelected-1) % (#menuContent+1)
                
            elseif code==down then
                menuSelected=(menuSelected+1) % (#menuContent+1)
            
            elseif code==right or code==enter then
                applyMenuFiles()
            
            elseif code==left or code==menu then
                state=stateFiles
            end
        end
        draw()
    end
end

