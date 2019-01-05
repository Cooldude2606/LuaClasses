--- An array which can be mounted at a certain index to act as the "start" of the array, all normal array functions work, only custom ones act from the mount point
-- @class Chain
-- @author Cooldude2606
-- @tparam[opt=false] boolean autoRemount if true when changing mount points all elements before mount are lost

local Class = require 'class.class'
local Chain = Class{name='Chain'}

function Chain.constructor(class,instance)
    instance.size=0
    instance.totalSize=0
    instance._mount=1
    instance.autoRemount=instance.autoRemount or false
end

--- Sets the new mount point in the chain, all functions will treat this as the start of the array
-- @usage chain:setMount(3) -- sets mount to 3
-- @tparam number index the new index for the mount, this is absolute to the start of the internal array
-- @treturn number the number of places that the mount was moved
function Chain._prototype:setMount(index)
    if instance.autoRemount then
        return self:remount(index)
    else
        local dif = index-self._mount
        self._mount=index
        self.size=self.size-dif
        return self:jumpMount(amount)
    end
end

--- Sets the new mount point relative to the current mount point, mount is 0
-- @usage chain:jumpMount(3) -- mount moves forward 3 places
-- @tparam number amount the amount of places to move the mount relative to the current position, can be negative
-- @treturn number the number of places the mount was moved, error correction means the value may be different
function Chain._prototype:jumpMount(amount)
    if instance.autoRemount then
        return self:remount(self._mount+amount)
    else
        self._mount=self._mount+amount
        self.size=self.size-amount
        -- if the mount falls out of range then it is moved back
        if self._mount < 1 then
            local dif = 1-self._mount
            self._mount=1
            self.size=self.size-dif
            return dif
        elseif self._mount > self.totalSize then
            local dif = self.totalSize-self._mount
            self._mount=self.totalSize
            self.size=self.size-dif
            return dif
        else
            return amount
        end
    end
end

--- Resets the internal array to match the current (or new) mount point; all elements before the mount are lost
-- @usage chain:remount() -- removes all elements before the current mount
-- @tparam[opt=mount] number the index that the internal array is set to
-- @treturn number the ammount of elements removed
function Chain._prototype:remount(index)
    local amount = index and index-1 or self._mount-1
    local ctn = amount
    while ctn > 0 do
        ctn=ctn-1
        table.remove(self,1)
    end
    self.totalSize=self.totalSize-amount
    self.size=self.totalSize
    self._mount=1
    return amount
end

--- Returns the an index relative to the start of the internal array rather than the mount mount, can be negative to get elements at the end of the chain
-- @usage chain:internalIndex(2) -- returns 3 if mount is at 2
-- @usage chain:internalIndex(-2) -- returns 5 if mount is at 2 and size is 4
-- @tparam[opt=1] number index the index in the array, mount is 1, negative is relative to end of array
-- @treturn number the internal index of the element in the internal array
function Chain._prototype:internalIndex(index)
    local index = index or 1
    local internalIndex = index+self._mount-1
    if index < 0 then
        return self.size+index+1+self._mount
    end
    return internalIndex
end

--- Returns the element at this index in the array, mount is 1
-- @usage chain:get(2) -- gets the 2nd element of the array
-- @tparam number index the index of the array to get, can be negative, mount is 1
-- @return the element at that index
function Chain._prototype:get(index)
    return self[self:internalIndex(index)]
end

--- Inserts an element at the end of the array or the given index, mount is 1
-- @usage chain:insert('foo') -- inserts element at the end of the array
-- @usage chain:insert('foo',2) -- inserts element at the 2nd index of the array
-- @param element the element to be inserted into the array
-- @tparam[opt=end] number index the index to insert the element at, mount is 1, negative is relative to end of array
-- @treturn number the location relative to the mount where it was inserted
function Chain._prototype:insert(element,index)
    local internalIndex = index and self:internalIndex(index) or self.size+1
    table.insert(self,internalIndex,element)
    self.size=self.size+1
    self.totalSize=self.totalSize+1
    return internalIndex-self._mount+1
end

--- Removes an element from the end of the array or given index, mount is 1
-- @usage chain:remove() -- removes the element at the end of the array
-- @usage chain:remove(3) -- removes the 3rd element of the array
-- @tparam[opt=end] number index the index to be removed, mount is 1, negative is relative to end of array
-- @return the element that was removed
function Chain._prototype:remove(index)
    local internalIndex = index and self:internalIndex(index) or self.size
    self.size=self.size-1
    self.totalSize=self.totalSize-1
    return table.remove(self,internalIndex)
end

--- Returns part of the chain as a array
-- @usage chain:cut() -- returns an array from the mount to the end
-- @usage chain:cut(2) -- returns an array from the 2nd index relative to the mount to the end
-- @usage chain:cut(2,2) -- returns first two elements from the 2nd index relative to the mount
-- @tparam[opt=mount] number index the start index, mount is 1, negative is relative to end
-- @tparam[opt=all] number length the number of elements to return, returns all if not given
-- @treturn table an array of the elements that were found
function Chain._prototype:cut(index,length)
    local fromIndex = index and self:internalIndex(index) or self._mount
    local ctn = 0
    local array = {}
    for index, value in ipairs(self) do
        if index >= fromIndex then
            table.insert(array,value)
            ctn=ctn+1
        end
        if length and ctn == length then break end
    end
    return array
end

--- Similar to chain:cut but is destructive and always removes till the end of the array
-- @usage chain:drop() -- returns all elements from the mount to the end
-- @usage chain:drop(2) -- returns all elements from the 2nd index relative to the mount to the end
-- @tparam[opt=mount] number index the index to start the drop from, mount is 1, negative is relative to end of array
-- @treturn table an array of all the elements that were removed from the array
function Chain._prototype:drop(index)
    local fromIndex = index and self:internalIndex(index) or self._mount
    local array = {}
    while true do
        local element = table.remove(self,fromIndex)
        if not element then break end
        self.size=self.size-1
        self.totalSize=self.totalSize-1
        table.insert(array,element)
    end
    return array
end

--- Returns an interator that can used to interate from the mount to the end
-- @usage for key,value in chain:interate() do -- loops over all elements from the mount till the end
-- @usage for key,value in chain:interate(2) do -- loops over all elements from the 2nd index relative to the mount till the end
-- @usage for key,value in chain:interate(2,3) do -- loops over the first 3 elements from the 2nd index relative to the mount
-- @tparam[opt=mount] number index the starting index of the loop, mount is 1, negative is relative to the end
-- @tparam[opt=all] number length the number of elements to loop over, all if not given
-- @treturn function the interative function for use in a for loop
function Chain._prototype:interate(index,length)
    local array = self:cut(index,length)
    return pairs(array)
end

-- Module return
return Chain