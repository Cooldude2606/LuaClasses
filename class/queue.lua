--- A FIFO queue implementation
-- @class Queue
-- @author Cooldude2606

local Class = require 'class.class'
local Queue = Class{name='Queue',forceHardlink=true}

function Queue.constructor(class,instance)
    instance._head=0
    instance._tail=0
    instance.size=0
end

--- Adds an element to the end of the queue
-- @usage queue:push('foo') -- adds foo to the end of the queue
-- @param element any value to be added to the end of the queue
-- @treturn int the place it was inserted into the queue
function Queue._prototype:push(element)
    local index = self._head
    rawset(self,index,element)
    self._head = index+1
    self.size = self.size+1
    return self.size
end

--- Returns next element in the queue without removing
-- @usage queue:peek() -- returns next element
-- @return the next element in the queue
function Queue._prototype:peek()
    return self[self._tail]
end

--- Returns next element in the queue and removes it
-- @usage queue:pop() -- returns next element
-- @return the next element in the queue
function Queue._prototype:pop()
    if self.size == 0 then return end
    local index = self._tail
    local element = self[index]
    self[index] = nil
    self._tail = index+1
    self.size = self.size-1
    return element
end

return Queue