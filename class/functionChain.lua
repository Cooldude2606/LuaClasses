--- A controler for middleware and function chains
-- @class FunctionChain
-- @author Cooldude2606

local Class = require 'class.class'
local FunctionChain = Class{name='FunctionChain',extends={'Emiter'}}

function FunctionChain.constructor(class,instance)
    instance:register('error')
    instance:register('trigger')
    instance:register('success')
    instance.functions=instance.functions or {}
    instance.size=#instance.functions
    -- allows settings as static or varible during creation; default varible at end of array
    if instance.static then
        instance:setStaticInsert(instance.static)
        instance.static=nil
    else
        local index = instance.varible or instance.size+1
        instance:setVaribleInsert(index)
        instace.varible=nil
    end
end

function FunctionChain._prototype:setVaribleInsert(index)
    self.staticInsert=false
    self.insertIndexBase=index
    self.insertIndex=index
end

function FunctionChain._prototype:setStaticInsert(index)
    self.staticInsert=true
    self.insertIndexBase=index
    self.insertIndex=index
end

function FunctionChain._prototype:insert(callback)
    local index = self.insertIndex
    table.insert(self.functions,index,callback)
    self.size=self.size+1
    -- a insert will always insert in the same location
    if not self.staticInsert then self.insertIndex=index+1 end
    return index-self.insertIndexBase
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

