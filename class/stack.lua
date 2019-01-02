--- A LIFO stack implementation
-- @class Stack
-- @author Cooldude2606

local Class = require 'class.class'
local Stack = Class{name='Stack'}

function Stack.constructor(class,instance)
    instance.size=0
end

--- Adds an element to the top of the stack
-- @usage stack:push('foo') -- adds foo to the top of the stack
-- @param element any value to be added to the top of the stack
-- @treturn int the place it was inserted into the stack
function Stack._prototype:push(element)
    local index = self.size+1
    rawset(self,index,element)
    self.size = index
    return index
end

--- Returns top element in the stack without removing
-- @usage stack:peek() -- returns top element
-- @return the top element in the queue
function Stack._prototype:peek()
    return self[self.size]
end

--- Returns top element in the stack and removes it
-- @usage stack:pop() -- returns top element
-- @return the top element in the stack
function Stack._prototype:pop()
    if self.size == 0 then return end
    local index = self.size
    local element = self[index]
    self[index] = nil
    self.size = self.size-1
    return element
end

-- Module return
return Stack