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
    local data = data or {}
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
--[[ Tests
local funChain = FunctionChain{
    function(data) print('call one') end,
    function(data) print('call two') end,
    function(data) print('call end') end,
}

funChain:on('trigger',function() print('trigger') end)
funChain:on('error',function(event) print(event.message) end)
funChain:on('success',function() print('success') end)

funChain:trigger()
Result:
> trigger
> call one
> call two
> call end
> success

funChain:insert(function(data) print('after end') end)
funChain:setSegment(2,2)
funChain:insert(function(data) print('call three') end)
funChain:insert(function(data) if data.error then error(data.error) end end)
funChain:insert(function(data) print('call four') end)

funChain:trigger()
Result:
> trigger
> call one
> call two
> call three
> call four
> call end
> after end
> success

funChain:trigger{error='Very Important Error'}
Result:
> trigger
> call one
> call two
> call three
> Very Important Error
]]