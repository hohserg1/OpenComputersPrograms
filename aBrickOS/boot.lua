local up = 200
local down = 208
local right = 205
local enter = 28
local left = 203
local menu = 221
local backspace = 14
local delete = 211

local gpu = component.proxy(component.list("gpu")())
gpu.bind(({component.list("screen")()})[1])
local w,h = 50,16--gpu.getResolution()

local invoke = component.invoke
local fs
local fsList
local function refreshFSList()
    fs = {}
    fsList = {}
    local fsComponentList = component.list("file") 
    for a in fsComponentList do
        local name = invoke(a,"getLabel")
        if not name or #name==0 then
            name = a
        end
        name = name.."/"
        fsList[#fsList+1]=name
        fs[#fs+1]=a
    end
end
refreshFSList()

local function prettyError(failureMsg, err)
    err = tostring(err):sub(-w+1)
    gpu.setForeground(0)
    gpu.setBackground(0xffffff)
    local ww = math.max(13,math.max(#failureMsg,#err))+4
    gpu.fill(w/2-ww/2,h/2-3,ww,7,"")
    
    gpu.setForeground(0xffffff)
    gpu.setBackground(0)        
    gpu.set(w/2-#failureMsg/2-1, h/2-2, " "..failureMsg.." ")
    gpu.set(w/2-#err/2-1, h/2, " "..err.." ")
    gpu.set(w/2-15/2, h/2+2, " press any key ")
    while true do
        local event = computer.pullSignal()
        if event=="key_down" then
            return
        end
    end
end

local function prettyErrorPCall(failureMsg, f, ...)
    local ok,err = pcall(f,...)
    if not ok then
        prettyError(failureMsg, err)
    end
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

local function fsPrefix(path)
    return "/"..fsList[currentFilesystem]:sub(1,-2)..path
end

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
            gpu.set(1,1,fsPrefix(currentPath))
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
                refreshFSList()
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
            refreshFSList()
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
    gpu.set(w/2+1,h-2,("⠤"):rep(w/2))
    gpu.set(w/2,h-2,"⢠⢸⢸",true)
    gpu.set(w/2+1,h-1,request)
    gpu.set(w/2+1,h,">")
    while true do
        gpu.set(w/2+2+#r,h,"█")
        local event,_,value,code,_ = computer.pullSignal()
        if event=="key_down" then
            if code==enter then
                break
            elseif code==backspace then
                r=r:sub(1,-2)
            elseif value >= 32 and value <= 126 then
                r=r..unicode.char(value)
            end
        elseif event=="clipboard" then
            r=r..value
        end
        gpu.set(w/2+2,h,r..(" "):rep(w/2))     
    end
    gpu.fill(w/2,h-2,w/2+1,3, " ")
    return r
end

local stateFiles=1
local stateMenuFiles=2
local stateEditor=3
local stateMenuEditor=4
local stateLua=5
local state = stateFiles

local function openEditor(fileName)
    state = stateEditor
    local cursorX,cursorY=1,1
    local contentLines={""}
    local currentLine=1
    local currentCol=1
    
    local function splitByLines(chunk)
        local endOfLine = chunk:find("\n")
        if endOfLine then
            contentLines[#contentLines] = contentLines[#contentLines]..chunk:sub(1,endOfLine-1)
            contentLines[#contentLines+1] = ""
            splitByLines(chunk:sub(endOfLine+1))
        else
            contentLines[#contentLines] = contentLines[#contentLines]..chunk        
        end    
    end
    
    local file = fsInvoke("open", fileName)
    if file then
        while true do
            local chunk = fsInvoke("read", file, math.huge)
            if chunk then
                splitByLines(chunk)
            else
                break
            end
        end
    end
    
    local function drawText()
        gpu.setForeground(0xffffff)
        gpu.setBackground(0)
        
        gpu.fill(1,2,w,h," ")
        local topLine = currentLine-cursorY+1
        local bottomLine = math.min(#contentLines, topLine+14)
        local y=2
        for i=topLine,bottomLine do
            gpu.set(1,y,contentLines[i]:sub(currentCol-cursorX+1))
            y=y+1
        end
        
        gpu.setForeground(0)
        gpu.setBackground(0xffffff)
        
        local selectedChar = contentLines[currentLine]:sub(currentCol,currentCol)
        gpu.set(cursorX,cursorY+1, #selectedChar==0 and " " or selectedChar)
        
        gpu.set(#fileName+2,1,"  Ln:"..currentLine.." Col:"..currentCol..(" "):rep(50))
    end
    
    local function normalizeX()
        local shift = currentCol-math.min(currentCol,#contentLines[currentLine]+1)
        currentCol=currentCol-shift
        cursorX=cursorX-shift
        cursorX = math.max(1,math.min(cursorX,w))
    end
    
    local function moveUp()
        cursorY = math.max(1, cursorY-1)
        currentLine = math.max(1, currentLine-1)
        normalizeX()
    end
    
    local function moveDown()
        cursorY = math.min(h-1, cursorY+1)
        currentLine = math.min(#contentLines, currentLine+1)
        normalizeX()
    end
    
    local function moveLeft()
        if currentCol==1 and currentLine>1 then
            currentCol=#contentLines[currentLine-1]+1
            cursorX=math.min(w, currentCol)
            moveUp()
        else
            cursorX = math.max(1, cursorX-1)
            currentCol = math.max(1, currentCol-1)
        end
    end
    
    local function moveRight()
        if currentCol==#contentLines[currentLine]+1 and currentLine<#contentLines then
            cursorX=1
            currentCol=1
            moveDown()
        else
            cursorX = math.min(w, cursorX+1)
            currentCol = math.min(#contentLines[currentLine]+1, currentCol+1)
        end
    end
    
    local editorMenuList = {
        x=50-14-1,y=5,w=9,h=4, 
        fontColor=0,backColor=0xffffff,
        content={"save","close"},
        selected = 1,
        scrollShift = 0,
        drawAddition = function(self)
            gpu.set(self.x,self.y, ("▀"):rep(self.w))
            gpu.set(self.x,self.y+self.h-1, ("▄"):rep(self.w))
        end,
        
        choose = function(self)
            if self.selected==1 then
                local file = fsInvoke("open", fileName, "w")
                if file then
                    for _,line in pairs(contentLines) do
                        fsInvoke("write", file, line)
                        fsInvoke("write", file, "\n")
                    end
                    fsInvoke("close", file)      
                else
                    prettyError("unable to save file","kinda disk is readonly")
                end
                state = stateEditor
            else
                state = stateFiles
            end
        end,
        
        close = function(self)
            self.selected = 1
            state=stateEditor
        end
    }
    
    
    gpu.setForeground(0)
    gpu.setBackground(0xffffff)
    gpu.set(1,1," "..fileName)
    
    while true do
        if state == stateEditor then
            drawText()
        elseif state==stateMenuEditor then
            drawList(editorMenuList) 
        else
            return
        end
        local event,_,value,code,_ = computer.pullSignal()
        if event=="key_down" then
            if state == stateEditor then
                if code==up then
                    moveUp()
                
                elseif  code==down then
                    moveDown()
                
                elseif  code==left then
                    moveLeft()
                
                elseif  code==right then
                    moveRight()
                    
                elseif code==enter then
                    table.insert(contentLines,currentLine+1,contentLines[currentLine]:sub(currentCol))
                    contentLines[currentLine]=contentLines[currentLine]:sub(1,currentCol-1)
                    cursorX=1
                    currentCol=1
                    moveDown()
                    
                elseif code==backspace then
                    if currentCol==1 and currentLine>1 then
                        currentCol = #contentLines[currentLine-1]+1
                        cursorX = currentCol>w and math.max(1,w-math.min(w/2,#contentLines[currentLine])) or currentCol
                        contentLines[currentLine-1]=contentLines[currentLine-1]..contentLines[currentLine]
                        table.remove(contentLines, currentLine)
                        moveUp()
                    else
                        contentLines[currentLine]=contentLines[currentLine]:sub(1,currentCol-2)..contentLines[currentLine]:sub(currentCol)
                        moveLeft()
                    end
                    
                elseif code==delete then
                    if currentCol==#contentLines[currentLine]+1 and currentLine<#contentLines then
                        cursorX = math.min(w/2,currentCol)
                        contentLines[currentLine+1]=contentLines[currentLine]..contentLines[currentLine+1]
                        table.remove(contentLines, currentLine)
                        
                    else
                        contentLines[currentLine]=contentLines[currentLine]:sub(1,currentCol-1)..contentLines[currentLine]:sub(currentCol+1)
                    end
                    
                elseif code==menu then
                    state = stateMenuEditor
                    
                elseif value >= 32 and value <= 126 then
                    contentLines[currentLine] = contentLines[currentLine]:sub(1,currentCol-1)..unicode.char(value)..contentLines[currentLine]:sub(currentCol)
                    cursorX = math.min(w, cursorX+1)
                    currentCol = math.min(#contentLines[currentLine]+1, currentCol+1)
                end
            elseif state==stateMenuEditor then
                handleKeysList(editorMenuList,code)
                if code==menu then
                    state=stateEditor
                end
            end
        end
    end
end

local picked = nil
local pickedTypeCopy = 1
local pickedTypeCut = 2
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
        fsInvoke(pickedType==pickedTypeCut and "rename" or "copy", picked[1]..picked[2], currentPath..picked[2])
        picked=nil
        filesList:updateContent()
    end,
    
    edit = function()
        local fileName = currentPath..filesList.content[filesList.selected]
        openEditor(fileName)        
    end,
    
    execute = function()
        local fileName = currentPath..filesList.content[filesList.selected]
        local file = fsInvoke("open", fileName)
        local code = ""
        while true do
            local chunk = fsInvoke("read", file, math.huge)
            if chunk then
                code=code..chunk
            else
                break
            end
        end
        local func, compileErr = load(code,fsPrefix(fileName))
        if func then
            local ok, execErr = pcall(func)
            if not ok then
                prettyError("Execution error:", execErr)
            end
        else
            prettyError("Compilation error:", compileErr)
        end
    end,
    
    delete = function()
        fsInvoke("remove",currentPath..filesList.content[filesList.selected])
        filesList:updateContent()
    end,
    
    rename = function()
        local newName = input("new name:")
        if currentFilesystem ~= -1 then
            if not fsInvoke("rename", currentPath..filesList.content[filesList.selected], currentPath..newName) then
                prettyErrorPCall("unable to rename file", error, "filesystem is readonly")
            end
        else
            prettyErrorPCall("unable to rename disk", invoke,fs[filesList.selected],"setLabel", newName)
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
    end,
    
    lua = function()
        state = stateLua
        gpu.setForeground(0xffffff)
        gpu.setBackground(0)
        gpu.fill(1,1,w,h," ")
        
        while true do
            local r=""
            gpu.set(1,h,"lua>")
            while true do
                gpu.set(6+#r,h,"█")
                local event,_,value,code,_ = computer.pullSignal()
                if event=="key_down" then
                    if code==enter then
                        break
                    elseif code==backspace then
                        r=r:sub(1,-2)
                    elseif value >= 32 and value <= 126 then
                        r=r..unicode.char(value)
                    end
                elseif event=="clipboard" then
                    r=r..value
                end
                gpu.set(6,h,r..(" "):rep(w))
            end
            
            if r==":q" then
                state = stateFiles
                return
            end
            
            local func, out = load("return "..r)
            if not func then
                func, out = load(r)
            end
            if func then
                _, out = pcall(func)
            end
        
            gpu.set(6+#r,h," ")
            gpu.copy(1,1,w,h, 0, out and -2 or -1)
            if out then
                out = tostring(out)
                gpu.set(1,h-1, out)
                while #out>w do
                    gpu.copy(1,1,w,h, 0, -1)
                    out = out:sub(w+1)
                    gpu.set(1,h-1, out)
                end
            end
        end
    end
}

local filesMenuList = {
    x=50-14-1,y=5,w=14,h=10, 
    fontColor=0,backColor=0xffffff,
    content={},
    selected = 1,
    scrollShift = 0,
    drawAddition = function(self)
        gpu.set(self.x,self.y, ("▀"):rep(self.w))
        gpu.set(self.x,self.y+self.h-1, ("▄"):rep(self.w))
    end,
    
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
        menuContent = {"new file", "new folder","paste", "lua"}
        filesMenuList.w = 14
        
    else
        if e:sub(-1,-1) ~= "/" then
            menuContent = {"edit","execute"}
            filesMenuList.w = 11
        else
            filesMenuList.w = 10        
        end
        menuContent[#menuContent+1] = "rename"
        if currentFilesystem ~= -1 then
            menuContent[#menuContent+1] = "delete"
            menuContent[#menuContent+1] = "copy"
            menuContent[#menuContent+1] = "cut"
        end
        menuContent[#menuContent+1] = "lua"
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

