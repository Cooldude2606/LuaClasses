--- A FIFO queue implementation
-- @class Emiter
-- @author Cooldude2606
-- @tparam[opt=nil] string name a name that can be used during error and verbose
-- @tparam[opt={}] table events contains names of events for the emiter
-- @tparam[opt=false] boolean protect should pcall be used on the callbacks
-- @tparam[opt=false] boolean explicit should all events be registered before being able to register callbacks

local Class = require 'class.class'
local Emiter = Class{name='Emiter'}

function Emiter.constructor(class,instance)
    instance.events = instance.events or {}
    -- converts strings into keys of the table
    for key,value in ipairs(instance.events) do
        if type(value == 'string') then
            instance.events[key] = nil
            instance.events[value] = {}
        end
    end
    instance.protect = instance.protect or false
    instance.explicit = instance.explicit or false
end

--- Registers a new event for the emiter
-- @usage emiter:register('log') -- no return
-- @tparam string event the name of the new event
-- @treturn Emiter the emiter instrance for chain calling
function Emiter._prototype:register(event)
    if self.events[event] then 
        -- checks if the event is already registered, if it is then either do nothing or error
        if self.explicit then 
            local name = self.name and ' for <'..self.name..'>' or ''
            return error('Event <'..event..'> already registered'..name)
        else return end
    end
    self.events[event] = {}
    return self
end

--- Unregisters an event and all its callbacks
-- @usage emiter:unregister('log') -- no return
-- @tparam string event the name of the event to be unregistered
-- @treturn Emiter the emiter instrance for chain calling
function Emiter._prototype:unregister(event)
    self.events[event] = nil
    return self
end

--- Listens for an event to be called then runs callback, if event not registered then it is registered (unless explicit enabled)
-- @usage emiter:on('log',function(event) print(event.message) end) -- adds the callback to the log event
-- @tparam string event the name of the event that the callback will be called on
-- @tparam function callback the callback that will be called
-- @treturn Emiter the emiter instrance for chain calling
function Emiter._prototype:on(event,callback)
    if not self.events[event] then
        -- checks if the event is registered if not it is either registered or throws an error
        if self.explicit then 
            local name = self.name and ' for <'..self.name..'>' or ''
            return error('Event <'..event..'> is not registered'..name) 
        else self:register(event) end
    end
    table.insert(self.events[event],callback)
    return self
end

--- Emits an event with data to sent to each callback, event must be registered
-- @usage emiter:emit('log',{message='foo'}) -- emits log event
-- @tparam string event the name of the event to be emited
-- @tparam table data a table of data that is passed to each event, includes event.name by default
function Emiter._prototype:emit(event,data)
    if not self.events[event] then
        if self.explicit then  
            local name = self.name and ' for emiter <'..self.name..'>' or ''
            return error('Event <'..event..'> is not registered'..name)
        end
    end
    data.name=data.name or event
    data.emiter=data.emiter or self
    for source,callback in pairs(self.events[event]) do
        if self.protect then pcall(callback,data)
        else callback(data) end
    end
end

-- Module return
return Emiter

--[[ Tests
local emiter = Emiter()
:on('log',function(data) print('One: '..data.message) end)
:on('log',function(data) print('Two: '..data.message) end)

local emiterTwo = Emiter{
    name= 'Logger',
    events={'log'},
    explicit=true
}
emiterTwo:on('log',function(data) print('One: '..data.message) end)
emiterTwo:on('error',function(data) print('Error: '..data.message) end) -- this should error as explicit is true and error is not registered

emiter:emit('log',{message='Hello, World!'})
emiterTwo:emit('log',{message='Hello, World!'})
]]