--- An array which can be mounted at a certain index to act as the "start" of the segment, custom functions act on this segment
-- @class Chain
-- @author Cooldude2606
-- @tparam[opt=Chain.lockType.mount] Chain.lockType segmentLock the type of lock that the segment has; decides what happens when an element is inserted, see lock types
-- @tparam[opt=#self] number segmentSize the size of the segment, the segment is the array starting from the segmentMount
-- @tparam[opt=1] number segmentMount the mnount point for the segment, segment is segmentSize elements long
-- @tparam[opt=false] boolean autoDrop if true then any actions which cause elemets to leave the segment will cause those elements to be removed
-- @tparam[opt=false] boolean returnTable if true functions will return tables rather than Chains, chains are tables with extra functions

local Class = require 'class.class'
local Chain = Class{name='Chain'}

function Chain.constructor(class,instance)
    instance.totalSize=#instance
    instance.segmentLock=instance.segmentLock or class.lockType.mount
    instance.segmentSize=instance.segmentSize or #instance
    instance.segmentMount=instance.segmentMount or 1
    instance.autoDrop=instance.autoDrop or false
    instance.returnTable=instance.returnTable or false
    if instance.segmentMount < 1 then instance.segmentMount = 1 end
    if instance.segmentSize < 0 then instance.segmentSize = 0
    elseif instance.segmentSize > instance.totalSize-instance.segmentMount+1 then instance.segmentSize = instance.totalSize-instance.segmentMount+1 end
end

--- Locks which decide what happens to the segment when elements are added
-- @table Chain.lockType
-- @value mount default lock type, the mount will not move unless set(jump)SegmentMount or setSegment is used segment acts as a normal array
-- @value tail the tail of the segment does not move, the mount is forced to move when there is a size change
-- @value size the size of the segment does not change so elements can be pushed or pulled into or out of the segment
Chain.lockType = {}
for index,value in ipairs{
    'mount',
    'tail',
    'size'
} do Chain.lockType[value] = index end

--- Sets the lock type of the chain
-- @usage chain:setLock('mount') -- sets the lock type to mount
-- @tparam string the name of the lock type that will be set
function Chain._prototype:setLock(type)
    if Chain.lockType[string.lower(type)] then
        self.segmentLock = Chain.lockType[string.lower(type)]
    else
        return error('Invalid lock type')
    end
end

--- Jumps the segment mount forward or backwards relative to its current location
-- @usage chain:jumpSegmentMount(2) -- moves the mount forward by 2
-- @tparam number amount the amount to move the mount by, can be negative
-- @treturn number the amount the mount was moved, may differ to input due to bounds checking
function Chain._prototype:jumpSegmentMount(amount)
    local index = self.segmentMount+amount
    if index < 1 then index = 1 end
    if index >= self.totalSize then index = self.totalSize-1 end
    return self:setSegmentMount(index)
end

--- Sets the segment mount to a certain interal index
-- @usage chain:setSegmentMount(2) -- sets the mount to index 2 of the array
-- @tparam number index the index to move the mount to, size may change depending on lock type
-- @treturn number the ammount of places that the mount moved, may differ to input due to bounds checking
function Chain._prototype:setSegmentMount(index)
    local delta = 0
    if index > 0 and index < self.totalSize then
        delta = index-self.segmentMount
        if self.segmentLock == Chain.lockType.tail or self.segmentLock == Chain.lockType.mount then
            -- the tail does not get moved when the mount moves, and the segment size changes
            self.segmentMount = index
            self.segmentSize = self.segmentSize-delta
        elseif self.segmentLock == Chain.lockType.size then
            -- the size is locked so the tail moves with the mount
            self.segmentMount = index
        else
            -- invalid lock so no change
            delta=0
        end
    end
    if delta > 0 and self.autoDrop then self:drop() end
    return delta
end

--- Sets the size of the segment
-- @usage chain:setSegmentSize(4) -- sets the size to 4 elements
-- @tparam number size the new size of the segment
-- @treturn number the change in size that occoured, may differ to input due to bounds checking
function Chain._prototype:setSegmentSize(size)
    local delta = 0
    if size >= 0 and size < self.totalSize-self.segmentMount-1 then
        delta = size-self.segmentSize
        if self.segmentLock == Chain.lockType.size or self.segmentLock == Chain.lockType.mount then
            -- the mount does not get moved so only the size changes
            self.segmentSize = size
        elseif self.segmentLock == Chain.lockType.tail then
            -- the tail does not move so the mount is moved to make up for the size change
            self.segmentSize = size
            self.segmentMount = self.segmentMount-delta
        else
            -- invalid lock so no change
            delta = 0
        end
    end
    if delta > 0 and self.autoDrop then self:drop() end
    return delta
end

--- Sets the segment to be between two indexs of the array
-- @usage chain:setSegment(2,5) -- sets mount to 2 and size to 3
-- @tparam number startIndex the starting index of the segment (inclusive)
-- @tparam number endIndex the ending index of the segment (inclusive)
-- @treturn number the change in position of the mount point
-- @treturn number the change in size of the segment
function Chain._prototype:setSegment(startIndex,endIndex)
    local mountDelta, sizeDelta = 0,0
    local endIndex = endIndex<0 and self.totalSize+endIndex+1 or endIndex
    if startIndex <= endIndex and startIndex > 0 and endIndex <= self.totalSize then
        mountDelta = startIndex-self.segmentMount
        sizeDelta = endIndex-startIndex-self.segmentSize
        -- lock type does not matter here unlike the above two cases
        self.segmentMount=startIndex
        self.segmentSize=endIndex-startIndex+1
    end
    if (mountDelta > 0 or sizeDelta > 0) and self.autoDrop then self:drop() end
    return mountDelta, sizeDelta
end

--- Returns the internal index for an index relative to the mount, mount is 1, last element is -1, 0 is index of element after segment
-- @usage chain:internalIndex(2) -- returns the internal index of the given index relative to the mount
-- @tparam number index the index in the segment
-- @treturn number the index relative to the internal array
function Chain._prototype:internalIndex(index)
    local offset = self.segmentMount-1
    local segmentIndex = index or 1
    if index <= 0 then
        segmentIndex = self.segmentSize+index+1
    end
    return offset+segmentIndex
end

--- Gets the element at this index in the segment
-- @usage chain:getElement(3) -- returns the third element in the segment
-- @tparam number index the index to get the element of
-- @return the element at that index in the segment
function Chain._prototype:getElement(index)
    local index = index and self:internalIndex(index) or 1
    return self[index]
end

--- Gets the current segment, or part of it
-- @usage chain:get() -- returns the current segment
-- @tparam[opt=mount] number fromIndex the index to start at in the segemnt, default is start of segment
-- @tparam[opt=all] number length the max number of elements to return from the segment
-- @treturn table the segment or part of that was found
function Chain._prototype:get(fromIndex,length)
    local fromIndex = fromIndex and self:internalIndex(fromIndex) or self.segmentMount
    local length = length or self.segmentSize
    if length > self.segmentSize then length = self.segmentSize end
    local toIndex = fromIndex+length-1
    local segment = {}
    for index = fromIndex,toIndex do
        table.insert(segment,self[index])
    end
    if self.returnTable then 
        return segment
    else 
        segment.segmentLock=self.segmentLock
        segment.autoRemount=self.autoRemount
        return Chain(segment)
    end
end

--- Gets the current segment, or part of it, and then removes it from the chain
-- @usage chain:cut() -- returns the current segment, and removes it from the chain
-- @tparam[opt=mount] number fromIndex the index to start at in the segemnt, default is start of segment
-- @tparam[opt=all] number length the max number of elements to return from the segment
-- @treturn table the segment or part of that was removed
function Chain._prototype:cut(fromIndex,length)
    local fromIndex = fromIndex or 1
    local length = length or self.segmentSize
    if length > self.segmentSize then length = self.segmentSize end
    local segment = {}
    local ctn = 0
    while true do
        local element = self:remove(fromIndex)
        if not element then break end
        table.insert(segment,element)
        ctn=ctn+1
        if ctn >= length then break end
    end
    if self.returnTable then 
        return segment
    else 
        segment.segmentLock=self.segmentLock
        segment.autoRemount=self.autoRemount
        return Chain(segment)
    end
end

--- Inserts an element into the segment, at the end or the given index
-- @usage chain:insert('foo') -- inserts foo at the end of the segment
-- @param element the element to be insetered into the segment
-- @tparam[opt=end] number index the index to insert the element at
-- @treturn number the index it was inserted at, may be different due to lock types chaing mount location
function Chain._prototype:insert(element,index)
    local index = index and self:internalIndex(index) or self:internalIndex(0)
    if self.segmentLock == Chain.lockType.mount then
        -- the mount is locked so element is inserted and size is incresed
        table.insert(self,index,element)
        self.segmentSize=self.segmentSize+1
        self.totalSize=self.totalSize+1
    elseif self.segmentLock == Chain.lockType.tail then
        -- the tail is locked so the element is inserted but the mount gets moved
        table.insert(self,index,element)
        self.segmentSize=self.segmentSize+1
        self.totalSize=self.totalSize+1
        self.segmentMount=self.segmentMount-1
        if self.segmentMount < 1 then self.segmentMount = 1 end
    elseif self.segmentLock == Chain.lockType.size then
        -- the size is locked so the element is inserted but there is no size change
        table.insert(self,index,element)
        self.totalSize=self.totalSize+1
    else
        -- invalid lock so an error is thorwn
        return error('Invalid lock type could not insert element')
    end
    if self.autoDrop then self:drop() end
    return index-self.segmentMount
end

--- Removes and returns an element of the segment, at the end or the given index
-- @usage chain:remove(3) -- removes the 3rd element from the segment and return its
-- @tparam number index the index that is to be removed from the array
-- @return the element at that index in the segment
function Chain._prototype:remove(index)
    local element
    local index = index and self:internalIndex(index) or self:internalIndex(-1)
    if self.segmentLock == Chain.lockType.mount then
        -- mount is locked so element is removed and size is reduced
        element = table.remove(self,index)
        self.segmentSize=self.segmentSize-1
        self.totalSize=self.totalSize-1
    elseif self.segmentLock == Chain.lockType.tail then
        -- tail is locked so element is removed and the mount gets moved
        element = table.remove(self,index)
        self.segmentSize=self.segmentSize-1
        self.totalSize=self.totalSize-1
        self.segmentMount=self.segmentMount+1
    elseif self.segmentLock == Chain.lockType.size then
        -- the size is locked so the element is inserted but there is no size change
        element = table.remove(self,index,element)
        self.totalSize=self.totalSize-1
    else 
        -- invalid lock so an error is thorwn
        return error('Invalid lock type could not insert element')
    end
    return element
end

--- Joins a chain or array onto the end or given index of the segment
-- @usage chainOne:join(chainTwo) -- adds chainTwo onto the end of the segment of chainOne
-- @tparam ?table|chain chain the elements that will be inserted into the segment
-- @tparam[opt=end] number index the index that the elements will be added from, default is end of the segment
function Chain._prototype:join(chain,index)
    local index = index and self:internalIndex(index)-1 or self:internalIndex(-1) 
    for chainIndex,element in ipairs(chain) do
        self:insert(element,chainIndex+index)
    end
    if self.autoDrop then self:drop() end
end

--- Removes all elements out side of the segment
-- @usage chain:drop()
function Chain._prototype:drop()
    local segment = self:get()
    for index in ipairs(self) do
        self[index] = segment[index]
    end
    self.totalSize=#self
    self.segmentSize=self.totalSize
    self.segmentMount=1
end

--- Allows interating over the segment
-- @usage for index,element in chain:pairs() do
-- @treturn interator a interator function
function Chain._prototype:pairs()
    local segment = self:get()
    return pairs(segment)
end

-- Module return
return Chain
--[[ Tests
local chain = Chain()
for i=1,10 do chain:insert('foo'..i) end -- init with 10 elements

chain:setSegment(2,-3) -- from 2 till 2 from the end
chain:get() -- {'foo2','foo3'...'foo7','foo8'}
chain:get(2,3) -- {'foo3','foo4','foo5'}

chain:jumpSegmentMount(1) -- moves mount by 1 index
chain:get() -- {'foo3','foo4'...'foo7','foo8'}

chain:insert('bar1',2) -- inserts bar at element two of segment
chain:get() -- {'foo3','bar1','foo4'...'foo7','foo8'}

chain:remove(3) -- removes foo4 at index 3 from the segment
chain:get() -- {'foo3','bar1','foo5'...'foo7','foo8'}

for k,v in ipairs(chain) do print(k..': '..v) end -- prints whole chain
-- {'foo1','foo2','foo3','bar1','foo5','foo6','foo7','foo8','foo9','foo10'}
chain:drop() -- removes all outside segment
for k,v in ipairs(chain) do print(k..': '..v) end -- prints whole chain
-- {'foo3','bar1','foo5','foo6','foo7','foo8'}
chain:get() -- should be the same as above

chain:setLock('size') -- locks the size
chain:setSegmentSize(2) -- forces the size to 2
chain:get() -- {'foo3','bar1'}
chain:jumpSegmentMount(1) -- moves mount by 1 index
chain:get() -- {'bar1','foo5'}
chain:cut() -- {'bar1','foo5'}
chain:get() -- {'foo6','foo7'}
for k,v in ipairs(chain) do print(k..': '..v) end -- prints whole chain
-- {'foo3','foo6','foo7','foo8'}
]]