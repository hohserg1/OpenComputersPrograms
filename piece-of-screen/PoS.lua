--Graphic library for MineOS
--provide virtual gpu for window
local PoS = {}

local realGpu = component.gpu
local system = require('system')
local GUI = require("GUI")

local max,min = math.max,math.min

local startX,startY = 2,3

local function cutContent(content, left, top, w,h)
    local nContent = {}
    for i=top+1, min(#content-top,h) do
        table.insert(nContent, content[i]:sub(left+1, min(#content[i]-left, w)+left))
    end
    return nContent
end

local function fillContent(char,width, height)
    local line = char:rep(width)
    local r={}
    for y=1,height do
        r[y]=line
    end
    return r
end
    
function PoS.createGPUWindow(x, y, width, height)
    local screenW,screenH = width,height

    local workspace, window = system.addWindow(GUI.filledWindow(x, y, screenW+2, screenH+3, 0xffffff))
    local mainPanel = window:addChild(GUI.panel(startX,startY,screenW,screenH,0x000000))
    local debugText = window:addChild(GUI.text(10,10,0xffffff,""))

    local foregroundColor, backgroundColor = 0xffffff,0x000000

    local function cutByScreen(x,y,w,h, content)
        local nx,ny = max(1,x),max(1,y)
        local nw,nh = min(x+w,screenW+1)-nx, min(y+h,screenH+1)-ny
        
        local nContent = cutContent(content,nx-x,ny-y,nw,nh)
        
        local text = GUI.textBox(startX+nx-1,startY+ny-1,nw,nh, backgroundColor,foregroundColor,nContent,1,0,0,false,false)
        
        return {e=text, count=nw*nh, type="set", x=nx,y=ny,w=nw,h=nh}
    end

    local actualMatrix = {}
    local rootElementEntry = {e=mainPanel,count=screenW*screenH, type = "fill", fillChar = " ", x=1, y=1, w=screenW, h=screenH}
    for x=1,screenW do
        actualMatrix[x]={}
        for y=1,screenH do
            actualMatrix[x][y]=rootElementEntry
        end
    end

    local function updateMatrix(newElementEntry)
        for x = newElementEntry.x, newElementEntry.x + newElementEntry.w-1 do
            for y = newElementEntry.y,newElementEntry.y + newElementEntry.h-1 do
                --GUI.alert("updateMatrix",x,y)
                local prevEntry = actualMatrix[x][y]
                prevEntry.count = prevEntry.count-1
                if prevEntry.count==0 then
                    prevEntry.e:remove()
                end
                actualMatrix[x][y]=newElementEntry
            end
        end
    end
    
    local function addElement(newElementEntry)
        if newElementEntry then
            window:addChild(newElementEntry.e)
            updateMatrix(newElementEntry)
            return newElementEntry.e
        end
    end

    local vgpu = {
        debugText = debugText,
        set = function(x,y,text)
            return addElement(cutByScreen(x, y, #text, 1, {text}))
        end,
        get = function(x,y)
            local entry = actualMatrix[x][y]
            if entry.type=="fill" then
                GUI.alert("fill",x,y)
                return entry.fillChar
            elseif entry.type=="set" then
                local e = entry.e
                local rx,ry = x-(e.x-startX), y-(e.y-startY)
                return e.lines[ry]:sub(rx,rx)          
            end
        end,
        fill = function(x, y, width, height, char)
            if #char==1 then
                return addElement(cutByScreen(x, y, width, height, fillContent(char,width, height)))
            else
                return false
            end
        end,
        copy = function(x, y, width, height, tx, ty)
            error("unsupported operation: copy")
        end,
        getResolution = function()
            return screenW,screenH
        end,
        maxResolution = function()
            return screenW,screenH
        end,
        setResolution = function()
            return false
        end,
        setBackground = function(color, isPaletteIndex)
            if isPaletteIndex then
                error("unsupported operation: setBackground(_, isPaletteIndex)")            
            end
            local prev = backgroundColor
            backgroundColor = color
            return prev
        end,
        setForeground = function(color, isPaletteIndex)
            if isPaletteIndex then
                error("unsupported operation: setForeground(_, isPaletteIndex)")
            end
            local prev = foregroundColor
            foregroundColor = color  
            return prev      
        end,
        getBackground = function()
            return backgroundColor
        end,
        getForeground = function()
            return foregroundColor
        end,
        getScreen = function()
            return realGpu.getScreen()
        end,
        getDepth = function()
            return realGpu.getDepth()
        end,
        setDepth = function()
            return false        
        end,
        bind = function()
            error("unsupported operation: bind")
        end,
        getPaletteColor = function()
            error("unsupported operation: getPaletteColor")
        end,
        setPaletteColor = function()
            error("unsupported operation: setPaletteColor")
        end,
        getViewport = function()
            error("unsupported operation: setPaletteColor")
        end,
        setViewport = function()
            error("unsupported operation: setPaletteColor")
        end,
        
        close = function()
            window:close()
        end
    }
    
    return vgpu

end

return PoS
