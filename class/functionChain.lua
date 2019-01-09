--- A controler for middleware and function chains, all functions must be called in order and be successful
-- @class FunctionChain
-- @author Cooldude2606

local Class = require 'class.class'
local FunctionChain = Class{name='FunctionChain',extends={'Emiter','Chain'}}

function FunctionChain.constructor(class,instance)
    instance.explicit=true
    instance:register('error')
    instance:register('trigger')
    instance:register('success')
end

--- Starts exucution of all callbacks with the given data
-- @usage funChain:trigger{message='foo'} -- runs functions with data as {message='foo'}
-- @tparam table data a table of data which is passed to each function
-- @treturn boolean did the chain finish exucution
function FunctionChain._prototype:trigger(data)
    local functions = {}
    -- copies all number keys which are the call backs
    for i,v in ipairs(self) do table.insert(functions,v) end
    -- emits trigger event
    self:emit('trigger',{data=data,functions=functions,functionCount=self.totalSize})
    for idnex,callback in ipairs(functions) do
        local success, err = pcall(callback,data)
        if not success then 
            -- if it fails then it stops exicution
            self:emit('error',{message=err}) 
            return false
        end
    end
    self:emit('success',{data=data,functions=functions,functionCount=self.totalSize})
    return true
end

return FunctionChain