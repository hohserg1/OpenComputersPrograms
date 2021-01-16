--[[
    Usage:
    local bit_array = require("bit_array")

    --create new bite array with size 100 and filled with ones
    local a = bit_array.create{sizeInBits = 100, fill = 1}
    --also
    local a = bit_array.create(100, 1)
    --also
    local a = bit_array.create(100, true)

    --create new bite array with size 100 and filled with zeros
    local a = bit_array.create{sizeInBits = 100, fill = 0}
    --also
    local a = bit_array.create{sizeInBits = 100}
    --also
    local a = bit_array.create(100)
    --also
    local a = bit_array.create(100, false)

    --set first bit to 1
    a:set(1, true)
    --also
    a:set(1, 1)

    --set first bit to 0
    a:set(1, false)
    --also
    a:set(1, 0)

    --get second bit
    a:get(2)

    --get out of bound error
    a:set(101, true)
    --also
    a:get(101)

    --get count of ones
    a:countOf(true)
    --also
    a:countOf(1)

    --get count of zeros
    a:countOf(false)
    --also
    a:countOf(0)
    
    --to string
    local stringRepr = a:toString()

    --from string
    local b = bit_array.fromString(stringRepr)

]]--

local bit_array={}

local bits_in_integer = 64
local bytesPerInt = bits_in_integer//8

local function checkIndexBounds(f)
    return function(self,i,...)
        if i<=self.size then
            return f(self,i,...)
        else
            error("index out of bounds: expected "..self.size.." and less, got "..i)
        end
    end
end

local function prepareDataIndex(f)
    return function(self,i,...)
        local int_i = (i-1)//bits_in_integer+1
        local local_i = (i-1)%bits_in_integer
        return f(self,int_i,local_i,...)
    end
end

local function countOf(returnOneIfHereFine)
    return function(n, size)
        local r = 0
        for i=0, size-1 do
            r = r + returnOneIfHereFine(n,i)
        end
        return r
    end
end

local countOfOnes = countOf(function(n,i) return (n>>i)&1 end)

local countOfZeros = countOf(function(n,i) return ~(n>>i)&1 end)

local function countOfInArray(countOf)
    return function(array)
        local count = 0
        local data = array.data
        for i=1,#data-1 do
            count = count + countOf(data[i], bits_in_integer) 
        end
        return count + countOf(data[#data], array.size%bits_in_integer)
    end
end

local countOfOnesInArray = countOfInArray(countOfOnes)
local countOfZerosInArray = countOfInArray(countOfZeros)

local function choice10(v, oneRelated, zeroRelated)
    if v==true or v==1 then
        return oneRelated
    elseif v==false or v==0 then
        return zeroRelated
    end
end


local baseBitArray = {
    __index = {
        set = checkIndexBounds(prepareDataIndex(function(self, int_i, local_i, v)
            self.data[int_i] = choice10(v, 
                                            self.data[int_i] | (1<<local_i), 
                                            self.data[int_i] & ~(1<<local_i))
        end)),
        
        get = checkIndexBounds(prepareDataIndex(function(self, int_i, local_i)
            return (self.data[int_i]>>local_i)&1
        end)),
        
        countOf =  function(self,v)
            return choice10(v, countOfOnesInArray,countOfZerosInArray)(self)
        end,
        
        setArray = checkIndexBounds(function(target, targetFromIndex, source, sourceFromIndex, sourceToIndex)
            sourceFromIndex = sourceFromIndex or 1
            sourceToIndex = sourceToIndex or source.size
            
            local dir = sourceFromIndex<sourceToIndex and 1 or -1            
            local len = math.abs(sourceToIndex-sourceFromIndex)+1            
            local targetToIndex = math.min(targetFromIndex+len-1, target.size)
            
            local i=targetFromIndex
            local j=sourceFromIndex
            repeat
                print(source:get(j))
                --target:set(i,source:get(j))
                
                i=i+1
                j=j+dir
            until j==sourceToIndex or i==targetToIndex
        end),
        
        toString = function(self)
            local r = {}
            
            for i=1, #self.data do
                local int = self.data[i]
                for j=0,bytesPerInt-1 do
                    table.insert(r,string.char(int>>(j*8) & 0xff))
                end
            end
            
            return table.concat(r)
        end,
        
        getInt = checkIndexBounds(function(self, fromIndex, toIndex)
            local dir = fromIndex<toIndex and -1 or 1   
            local r = 0
            for i=toIndex,fromIndex,dir do
                r = r << 1
                r = r | self:get(i)
            end
            return r
        end)
    }
}

local allOnes = -1
local allZeros = 0

local function create(sizeInBits, fill)
    fill = choice10(fill or false, allOnes, allZeros)
    local countOfInts = math.ceil(sizeInBits/bits_in_integer)
    local data = {}
    for i=1, countOfInts do
        data[i] = fill
    end
    return setmetatable({data = data, size=sizeInBits},baseBitArray)
end

function bit_array.create(sizeInBits, fill)
    if type(sizeInBits)=="table" then
        return create(sizeInBits.sizeInBits, sizeInBits.fill)
    else
        return create(sizeInBits,fill)
    end
end

local function createBasedOn(array,fromIndex,toIndex)
    local len = math.abs(toIndex-fromIndex)+1
    local r = create(len)
    r:setArray(array,1,fromIndex,toIndex)
    return r
end

function bit_array.createBasedOn(array,fromIndex,toIndex)
    if type(array)=="table" then
        return createBasedOn(array.array, array.fromIndex, array.toIndex)
    else
        return createBasedOn(array,fromIndex,toIndex)
    end
end

function bit_array.fromString(str)
    local countOfInts = #str//bytesPerInt
    local r = create(countOfInts*bits_in_integer)
    
    for i=1,countOfInts do
        for j=0,bytesPerInt-1 do
            r.data[i] = r.data[i] | (str:byte((i-1)*bytesPerInt+1+j)<<(8*j))
        end
    end
    
    return r
end

return bit_array
