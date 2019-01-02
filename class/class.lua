--- Addds a class system to lua to make an use classes and instances
-- @class Class
-- @author Cooldude2606

-- mt that is loaded onto all tables
local _mt_class = {
    -- Class can be called as a function to create a new instance
    __call=function(self,...) return self:new(...) end,
    __index=function(self,key)
        -- if key is _classConstructor then alternative names are tried
        if key == '_classConstructor' then
            return self.classConstructor
                or self.constructor
                or self.define
                or self.create
        end
        -- if key is not present it will return the value which the prototype has
        if self._prototype[key] then
            return self._prototype[key]
        end
    end
}

-- creates a new class called called Class, without the use of Class.new
local Class = setmetatable({
    className='Class',
    useMetatable=false,
    _classExtends={},
    _prototype={},
    _classes={}
},_mt_class)

--- The constructor for a class
-- this case is the constructor for making a new class 
-- @usage Class{name='car'} -- returns new class named car
-- @usage Class{name='car',hardlink=true} -- returns new class named car, all instances will be hardlinked
-- @tparam Class class the class which the constructor is apart of (in this case Class)
-- @tparam Instance instance the insatnce that is to be modified by the constructor (in this case the new class)
-- this function does not need to return
function Class.constructor(class,instance)
    -- adds the class to the list of classes
    if not instance.name then return error('Class without name',2) end
    if class._classes[instance.name] then return error('Class name already used',2) end
    class._classes[instance.name]=instance
    instance._className=instance.name
    instance.name=nil
    -- addes a prototype table
    instance._prototype=instance._prototype or {}
    instance.useMetatable=instance.useMetatable or false
    -- makes extends a table of class names
    local extends = 
        type(extends) == 'table' and not extends.className and extends
        or type(extends) == 'table' and extends.className and {extends.className}
        or extends and {extends}
        or nil
    instance.extends=nil
    instance._classExtends=extends
    setmetatable(instance,_mt_class)
end

--- Links an instance to its class if the link was lost
-- @usage Class.autolink(instance) -- does not return
-- @tparam Instance instance the instance that is to be relinked to its class
function Class.autolink(instance)
    local class = Class._classes[instance._className]
    if not class then return error('Instance of undefined type <'+instance._className+'>') end
    if instance._hardlinkToClass then class:hardlink(instance)
    else class:link(instance) end
end

--- Returns the type that an instance is
-- @usage Class.type(instance) -- return the name of the class which it is an instance of
-- @tparam Instance instance the instance to get the type of
-- @treturn string the type that the instance is
function Class.type(instance)
    local _type = type(instance)
    if _type == 'table' and instance._className then
        return instance._className
    else return _type end
end

--- Creates a new class
-- @usage class{foo=1,bar=2} -- returns a new instance of a class
-- @usage class{_hardlinkToClass=true,foo=1,bar=2} -- returns a new instance of a class with all functions saved to the instance
-- @tparam table instance a table of details which describs the new instance of the class, is passed to constructor
-- @tparam boolean hardlink if a hardlink should be created with the class alis instance._hardlinkToClass=true
-- @treturn Instance the new instance of the class that was created
function Class._prototype:new(instance,hardlink)
    -- allow undefined instance
    local instance = instance or {}
    -- will this instance be hardlinked
    local hardlink = hardlink or instance._hardlinkToClass or not self.useMetatable or false
    instance._hardlinkToClass = hardlink
    -- links the instance to this class
    if hardlink then self:hardlink(instance)
    else self:link(instance) end
    -- links the instance to all extents if present
    if self._classExtends then
        for _,className in pairs(self._classExtends) do
            Class._classes[className]:new(instance,hardlink)
        end
    end
    -- defines the type of the instance
    instance._className = self._className
    -- calls the constructor
    if self.constructor then self:constructor(instance) end
    -- returns back the new instance
    return instance
end

--- Creates a link between a class and an instance of the class
-- @usage class:link(instance) -- links instance to be of type class
-- @tparam Instance instance the instance that is to be linked with the class
-- @treturn Instance the instance that has now been linked
function Class._prototype:link(instance)
    -- index link via metatable
    return setmetatable(instance,{__index=self})
end

--- Creates a hard link bettween a class and an instance of the class by copying all functions into the instance
-- @usage class:hardlink(instance) -- links instance to be of type class
-- @tparam Instance instance the instance that is to be linked with the class
-- @treturn Instance the instance that has now been linked
function Class._prototype:hardlink(instance)
    -- saves all values of self into instance, index without metatable
    for key,value in pairs(self._prototype) do
        instance[key]=value
    end
    return instance
end

-- Module return
return Class

--[[ Tests
local Class = require ('lib/Class')
local Car = Class{name='Car'}
function Car.constructor(class,instance) instance.isOpen = false end
function Car._prototype:open() self.isOpen = true end
function Car._prototype:close() self.isOpen = false end
local carOne = Car{owner='bob'}
local carTwo = Car{owner='john'}
]]