local component = require('component')
local event = require('event')
local component = require('component')
local bit_array = require('bit_array')
local glasses = component.glasses
--glasses.setRenderPosition("absolute")
glasses.setRenderPosition("relative")

local computer = require('computer')
if computer.getArchitecture()=="Lua 5.2" then
    print("Requied Lua 5.3")
    os.sleep(3)
    computer.setArchitecture("Lua 5.3")
end

local function addTriangle(w,
    x1,y1,z1,
    x2,y2,z2,
    x3,y3,z3)
    w.addVertex(x1,y1,z1)
    w.addVertex(x2,y2,z2)
    w.addVertex(x3,y3,z3)
end

function addInvertedCube(elevation, height, size,cx,cy,cz)
    local w = glasses.addCustom3D()
    w.setViewDistance(math.huge)
    w.setVisibleThroughObjects(true)
    local e = 0.1 --edge size
    --bottom
    addTriangle(w,
        cx-size+e, cy+elevation, cz+size-e,
        cx+size-e, cy+elevation, cz+size-e,
        cx+size-e, cy+elevation, cz-size+e
    )
    addTriangle(w,
        cx-size+e, cy+elevation, cz+size-e,
        cx+size-e, cy+elevation, cz-size+e,
        cx-size+e, cy+elevation, cz-size+e
    )
    --top
    addTriangle(w,
        cx-size+e, cy+elevation+height, cz-size+e,
        cx+size-e, cy+elevation+height, cz-size+e,
        cx+size-e, cy+elevation+height, cz+size-e
    )
    addTriangle(w,
        cx-size+e, cy+elevation+height, cz-size+e,
        cx+size-e, cy+elevation+height, cz+size-e,
        cx-size+e, cy+elevation+height, cz+size-e
    )
    --west
    addTriangle(w,
        cx-size, cy+elevation+e, cz+size-e,
        cx-size, cy+elevation+e, cz-size+e,
        cx-size, cy+elevation+height-e, cz-size+e
    )
    addTriangle(w,
        cx-size, cy+elevation+e, cz+size-e,
        cx-size, cy+elevation+height-e, cz-size+e,
        cx-size, cy+elevation+height-e, cz+size-e
    )
    --east
    addTriangle(w,
        cx+size, cy+elevation+e, cz-size+e,
        cx+size, cy+elevation+e, cz+size-e,
        cx+size, cy+elevation+height-e, cz+size-e
    )
    addTriangle(w,
        cx+size, cy+elevation+e, cz-size+e,
        cx+size, cy+elevation+height-e, cz+size-e,
        cx+size, cy+elevation+height-e, cz-size+e
    )
    --south
    addTriangle(w,
        cx+size-e, cy+elevation+e, cz+size,
        cx-size+e, cy+elevation+e, cz+size,
        cx-size+e, cy+elevation+height-e, cz+size
    )
    addTriangle(w,
        cx+size-e, cy+elevation+e, cz+size,
        cx-size+e, cy+elevation+height-e, cz+size,
        cx+size-e, cy+elevation+height-e, cz+size
    )
    --north
    addTriangle(w,
        cx-size+e, cy+elevation+e, cz-size,
        cx+size-e, cy+elevation+e, cz-size,
        cx+size-e, cy+elevation+height-e, cz-size
    )
    addTriangle(w,
        cx-size+e, cy+elevation+e, cz-size,
        cx+size-e, cy+elevation+height-e, cz-size,
        cx-size+e, cy+elevation+height-e, cz-size
    )
    
    
    
    w.addVertex(0,0,0)
    return w
    
end

local function decodeCoords(index)
    local y = index//(65*65)
    local x_z = index%(65*65)
    local x = x_z//65
    local z = x_z%65
    return x,y,z
end

local insert = table.insert

local function addCubeToObj(vertices,quads,x,y,z)
    local v1 = #vertices+1
    insert(vertices,"v "..x.." "..y.." "..z)            --0
    insert(vertices,"v "..x.." "..y.." "..(z+1))        --1
    insert(vertices,"v "..x.." "..(y+1).." "..z)        --2
    insert(vertices,"v "..(x+1).." "..y.." "..z)        --3
    insert(vertices,"v "..x.." "..(y+1).." "..(z+1))    --4
    insert(vertices,"v "..(x+1).." "..(y+1).." "..z)    --5
    insert(vertices,"v "..(x+1).." "..y.." "..(z+1))    --6
    insert(vertices,"v "..(x+1).." "..(y+1).." "..(z+1))--7
    
    insert(quads,"l "..tostring(v1+0).." "..tostring(v1+3).." "..tostring(v1+6).." "..tostring(v1+1))--bottom
    insert(quads,"l "..tostring(v1+2).." "..tostring(v1+4).." "..tostring(v1+7).." "..tostring(v1+5))--top
    insert(quads,"l "..tostring(v1+0).." "..tostring(v1+1).." "..tostring(v1+4).." "..tostring(v1+2))--west
    insert(quads,"l "..tostring(v1+3).." "..tostring(v1+5).." "..tostring(v1+7).." "..tostring(v1+6))--east
    insert(quads,"l "..tostring(v1+1).." "..tostring(v1+6).." "..tostring(v1+7).." "..tostring(v1+4))--south
    insert(quads,"l "..tostring(v1+0).." "..tostring(v1+2).." "..tostring(v1+5).." "..tostring(v1+3))--north
end

local hardness, size, cx,cy,cz, elevation, height

local function buildObjOreModel(array)
    local count = array:getInt(1,19)
    local vertices = {}
    local quads = {}
    for i=1, count*19,19 do
        local x,y,z = decodeCoords(array:getInt(i,i+18))
        addCubeToObj(vertices,quads,x-size,y+elevation,z-size)
    end
    os.sleep()
    return table.concat(vertices,"\n").."\n"..table.concat(quads,"\n")
end


local oreWidget
local function onModemMessage(msg, ...)
    if msg=="init" then
        hardness, size, elevation, height = ...
        local pos = glasses.getUserPosition()[1]
        cx,cy,cz = pos.x//1,pos.y//1+1,pos.z//1
        glasses.removeAll()
        print(elevation,height)
        addInvertedCube(elevation, height, size,cx,cy,cz)
        oreWidget = glasses.addOBJModel3D()
        oreWidget.setViewDistance(math.huge)
        oreWidget.setVisibleThroughObjects(true)
        oreWidget.addColor(1,0,0)
        oreWidget.addTranslation(cx,cy,cz)
    elseif msg=="scan" then
        local str = ...
        
        local data = bit_array.fromString(str)
        
        oreWidget.loadOBJ(buildObjOreModel(data))
    end
end

event.listen("modem_message",function(_,_, _, _, _, msg, ...)
    onModemMessage(msg, ...)
end)
