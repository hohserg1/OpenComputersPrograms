local up = 200
local down = 208
local right = 205
local enter = 28
local left = 203
local menu = 221
local backspace = 14

local gpu = component.proxy(component.list("gpu")())
gpu.bind(({component.list("screen")()})[1])
local w,h = gpu.getResolution()

local invoke = component.invoke
local fs = {}
local fsList = {}
local fsComponentList = component.list("file") 
for a in fsComponentList do
    local name = invoke(a,"getLabel")
    if not name then
        name = a
    end
    name = name.."/"
    fsList[#fsList+1]=name
    fs[#fs+1]=a
end

local function drawList(self)
    gpu.setForeground(self.fontColor)
    gpu.setBackground(self.backColor)
    
    gpu.fill(self.x, self.y, self.w, self.h," ")
    
    local contentHeight = self.h-2
    
    for i = (self.scrollShift+1), (math.min(self.scrollShift + contentHeight, #self.content)) do
        local e = self.content[i]
        local yy = i-self.scrollShift
        gpu.set(self.x+2, self.y+yy, e)
    end
    
    self:drawAddition()
    
    gpu.setBackground(self.fontColor)
    gpu.setForeground(self.backColor)
    gpu.set(self.x + 1, self.y + self.selected - self.scrollShift, " "..self.content[self.selected].." ")

end

local function fixScroll(self)
    local scrollShift = self.scrollShift
    local contentHeight = self.h-2
    
    if scrollShift + contentHeight < self.selected+1 then
        if scrollShift==0 and self.selected==#self.content then
            self.scrollShift = #self.content-contentHeight
            
        elseif scrollShift + contentHeight < #self.content then
            self.scrollShift = scrollShift+1
        end
       
    elseif self.selected < scrollShift then
        if scrollShift==#self.content-contentHeight and self.selected==1 then
            self.scrollShift=0
        else
            self.scrollShift = scrollShift-1
        end
    end
end

local function handleKeysList(self, code)    
    if code==up then
        self.selected = (self.selected-1-1) % (#self.content) + 1
        fixScroll(self)
        
    elseif code==down then
        self.selected = (self.selected+1-1) % (#self.content) + 1
        fixScroll(self)
    
    elseif code==right or code==enter then
        self:choose()
    
    elseif code==left then
        self:close()
    end
end

local currentPath = "/"
local currentFilesystem = -1

local function fsInvoke(...)
    return invoke(fs[currentFilesystem], ...)
end

local filesList = {
    x=1,y=2,w=50,h=16,
    fontColor=0xffffff,backColor=0,
    content = fsList,
    selected = 1,
    scrollShift = 0,
    drawAddition = function()
        gpu.set(1,1,(" "):rep(50))
        if currentFilesystem == -1 then
            gpu.set(1,1,"/")
        else
            gpu.set(1,1,"/"..fsList[currentFilesystem]:sub(1,-2)..currentPath)
        end
        gpu.set(1,2,("⠤"):rep(50))
    end,
    choose = function(self)   
        if currentFilesystem == -1 then
            currentFilesystem = self.selected
        else
            local e = self.content[self.selected]
            if e=="⬅" then
                self:close()
            elseif e:sub(-1,-1)=="/" then
                currentPath=currentPath..e
            end
        end
        self:updateContent() 
    end,
    close = function(self)
        if currentPath=="/" then
            if currentFilesystem ~= -1 then
                currentFilesystem = -1
                self.content = fsList
            end
        else
            local lastSeparator = currentPath:sub(1,-2):match'^.*()/'
            currentPath = currentPath:sub(1,lastSeparator)
        end
        self:updateContent()
    end,
    updateContent = function(self)
        if currentFilesystem ~= -1 then
            self.content = fsInvoke("list", currentPath)
            table.insert(self.content, 1, "⬅")
        else
            fsList={}
            for a in fsComponentList do
                local name = invoke(a,"getLabel")
                if not name then
                    name = a
                end
                name = name.."/"
                fsList[#fsList+1]=name
            end
            self.content = fsList
        end
        self.selected = 1
        self.scrollShift = 0
    end
}

local function input(request)
    gpu.setForeground(0xffffff)
    gpu.setBackground(0)
    local r = ""
    gpu.set(26,14,("⠤"):rep(25))
    gpu.set(25,14,"⢠⢸⢸",true)
    gpu.set(26,15,request)
    gpu.set(26,16,">")
    while true do
        local event,_,value,code,_ = computer.pullSignal()
        if event=="key_down" or event=="clipboard" then
            if code==enter then
                break
            elseif code==backspace then
                r=r:sub(1,-2)
            else
                r=r..unicode.char(value)
            end
            gpu.set(27,16,r..(" "):rep(25))
        end        
    end
    gpu.fill(25,14,26,3, " ")
    return r
end

local stateFiles=1
local stateMenuFiles=2
local stateEditor=3
local stateMenuEditor=4
local stateLua=5
local state = stateFiles

local picked = nil
local pickedTypeCopy = 1
local pickedTypeCut = 1
local pickedType = pickedTypeCopy

local menuActions = {
    ["new file"]=function()
        local newName = input("name:")
        openEditor(currentPath..newName)
    end,
    
    ["new folder"]=function()
        local newName = input("name:")
        fsInvoke("makeDirectory", currentPath..newName)
        filesList:updateContent()
    end,
    
    paste = function()
        fsInvoke("rename", picked[1]..picked[2], currentPath..picked[2])
        picked=nil
        filesList:updateContent()
    end,
    
    edit = function()
        
    end,
    
    execute = function()
        local fileName = currentPath..filesList.content[filesList.selected]
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
    end,
    
    delete = function()
        fsInvoke("remove",currentPath..filesList.content[filesList.selected])
        filesList:updateContent()
    end,
    
    rename = function()
        local newName = input("new name:")
        if currentFilesystem ~= -1 then
            fsInvoke("rename", currentPath..filesList.content[filesList.selected], currentPath..newName)
        else
            invoke(fs[filesList.selected],"setLabel", newName)
        end
        filesList:updateContent()
    end,
    
    copy = function()
        picked={currentPath, filesList.content[filesList.selected]}
        pickedType = pickedTypeCopy
    end,
    
    cut = function()
        picked={currentPath, filesList.content[filesList.selected]}
        pickedType = pickedTypeCut
    end
}

local filesMenuList = {
    x=50-14-1,y=5,w=14,h=10, 
    fontColor=0,backColor=0xffffff,
    content={},
    selected = 1,
    scrollShift = 0,
    drawAddition = function()end,
    
    choose = function(self)
        menuActions[self.content[self.selected]]()
        state = state==stateMenuFiles and stateFiles or state
    end,
    
    close = function(self)
        state=stateFiles
    end
}

local function updateMenuFilesContent()
    local e = filesList.content[filesList.selected]
    
    local menuContent = {}
    
    if e=="⬅" then
        menuContent = {"new file", "new folder","paste"}
        
    else
        if e:sub(-1,-1) ~= "/" then
            menuContent = {"edit","execute"}
        end
        menuContent[#menuContent+1] = "rename"
        if currentFilesystem ~= -1 then
            menuContent[#menuContent+1] = "delete"
            menuContent[#menuContent+1] = "copy"
            menuContent[#menuContent+1] = "cut"
        end
    end
    
    filesMenuList.content = menuContent
    filesMenuList.selected = 1
    filesMenuList.scrollShift = 0
    filesMenuList.h = #menuContent+2
end

local function drawDebugBorder()
    gpu.setBackground(0xffffff)
    gpu.set(51,1,(" "):rep(16),true)
    gpu.set(1,17,(" "):rep(51))
end

local function draw()
    if state==stateFiles then
        drawList(filesList)
            
    elseif state==stateMenuFiles then
        drawList(filesMenuList)
    end
    drawDebugBorder()
end

draw()

while true do
    local event,_,value,code,_ = computer.pullSignal()
    if event=="key_down" then
        if state==stateFiles then
            handleKeysList(filesList,code)
            if code==menu then
                state=stateMenuFiles
                updateMenuFilesContent()
            end
            
        elseif state==stateMenuFiles then
            handleKeysList(filesMenuList,code)
            if code==menu then
                state=stateFiles
            end
        end
        draw()
    end
end

