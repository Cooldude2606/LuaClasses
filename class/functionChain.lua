--- A controler for middleware and function chains
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

function FunctionChain._prototype:trigger(data)
    self:emit('trigger',{data=data,functions=functions,functionCount=self.size})
    local functions = self.functions
    for idnex,callback in ipairs(functions) do
        local success, err = pcall(callback,data)
        if not success then 
            self:emit('error',{message=err}) 
            return false
        end
    end
    self:emit('success',{data=data,functions=functions,functionCount=self.size})
    return true
end

