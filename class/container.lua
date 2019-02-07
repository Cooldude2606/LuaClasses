--- Creates a lua container which is just to control what files are loaded and some base functions
-- @class Container
-- @author Cooldude2606

local Class = require 'class.class'
local Container = Class{name='Container'}

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
        -- added for this class
        if rawget(self,'default') and self.default[key] then
            if type(self._prototype[key]) == 'function' then
                return function(...) return self.default[key](self.default,...) end
            else
                return self.default[key]
            end
        end
        -- if key is not present it will return the value which the prototype has
        if self._prototype[key] then
            return self._prototype[key]
        end
    end
}

function Container.constructor(class,instance)
    instance.debug = false
    instance.files = {}
    instance.shared = {}
    instance.fileState = 'NOT_LOADED'
    instance.spawned = false
    instance.logs = {
        error=true,
        output=print
    }
    instance._overrides = {}
    instance.overrides = {
        vlog=function(...) return class.default and class.default:vlog(...) end
    }
end

--- Tests if the current env is protected by pcall, if so returns the stack level it is protected upto
-- @usage Container.protected() -- returns stack level of first pcall
-- @tparam[opt=2] level number the stack level which you want to start checking from
-- @treturn boolean|number false if no pcall else a number that the pcall is on
function Container.protected(level)
    local level = level and level+1 or 2
    while true do
        if not debug.getinfo(level) then return false end
        if debug.getinfo(level).name == 'pcall' then return level end
        level=level+1
    end
end

--- Triggers the logging within the container, will only trigger output when type is true
-- @usage container:vlog('error','this is an error')
-- @tparam type string the type of log this is, will log if value is true in container.logs
-- @tparam msg string the message that will be outputed
function Container._prototype:log(type,msg)
    if self.logs[type] then
        self.logs.output(type,msg)
    end
end

--- Sets a shared value within the container that can be accessed any where with get
-- @usage container:set('foo','here be foo')
-- @tparam name string the key of this value
-- @tparam value any the value that will be set
function Container._prototype:set(name,value)
    self.shared[name] = value
end

--- Gets a shared value that has been set else where
-- @usage container:get('foo') -- 'here be foo'
-- @tparam name string the key of the item to get
-- @return the value stored under this name
function Container._prototype:get(name)
    return self.shared[name]
end

--- Tests if a file is loaded by its path
-- @usage container:fileLoaded('class.queue') -- either true or false
-- @tparam path string the path to the file to check
-- @treturn boolean is the file loaded
function Container._prototype:fileLoaded(path)
    return self.files[path] and true or false
end

--- Gets the loaded contents of a file if it is loaded, nil other wise
-- @usage container:file('class.queue') -- return the Queue class if loaded
-- @tparam path string the path to the file to get
-- @return the file returns
function Container._prototype:file(path)
    return self.files[path]
end

--- Runs a function if defug is set to true, will place the function into the debugEnv if present
-- @usage container:runInDebug(print,'Debug is active')
-- @tparam callback function the function that will be run if debug is active
-- @param[opt] any args you want to pass to the function
function Container._prototype:runInDebug(callback,...)
    if self.debug then 
        if self.debugEnv then
            self:sandbox(callback,self.debugEnv,...)
        else
            pcall(callback,...)
        end
    end
end

--- An alterative require that tryies to load its version before the base require
-- @usage container:require('class.queue') -- returns file contents
-- @tparam path string the path to the file to load
-- @return the file returns
function Container._prototype:require(path)
    -- self._overrides.require is checked as it may have been over writen with this function
    if self:file(path) then
        return self:file(path)
    elseif self._overrides.require then
        return self._overrides.require(path)
    else
        return require(path)
    end
end

--- Sandboxs a function into the container and the given env, will load upvalues if provied in the given env
-- @usage container:sandbox(print,{},'hello from the sandbox')
-- @tparam callback function the function that will be run in the sandbox
-- @tparam env table the env which the function will run in, place upvalues in this table
-- @param[opt] any args you want to pass to the function
-- @treturn boolean did the function run without error
-- @treturn string|table returns error message or the returns from the function
-- @treturn table returns back the env as new values may have been saved
function Container._prototype:sandbox(callback,env,...)
    -- creates a sandbox env which will later be loaded onto _G
    local sandbox_env = setmetatable(env,{
        __index=function(tbl,key)
            return self.overrides[key]
                or self.shared[key]
                or rawget(_G,key)
        end
    })
    sandbox_env._ENV = sandbox_env
    sandbox_env._MT_G = getmetatable(_G)
    -- sets any upvalues on the callback
    local i = 1
    while true do
        local name, value = debug.getupvalue(callback,i)
        if not name then break end
        if not value and sandbox_env[name] then
            debug.setupvalue(callback,i,sandbox_env[name])
        end
        i=i+1
    end
    -- adds the sandbox to _G
    setmetatable(_G,{__index=sandbox_env,__newindex=sandbox_env})
    local rtn = {pcall(callback,...)}
    local success = table.remove(rtn,1)
    setmetatable(_G,_MT_G)
    -- returns values from the callback, if error then it returns the error
    if success then return success, rtn, sandbox_env
    else return success, rtn[1], sandbox_env end
end

--- "Spawns" the container into the _G env and acts as a container for the whole programe, this is the main init function
-- using this will cause Container to gain the values of the container spawn was acted on, meaning that you will be able to
-- call all above function from Container ie Container.get and Container.runInDebug ( notice how it is now . not : )
-- this will also cause overrides to come into effect by replacing those in _G and moving them to Container._overrides
-- @usage container:spawn()
function Container._prototype:spawn()
    Container.default = self
    self.spawned = true
    -- creates a sandbox env which will later be loaded onto _G
    local sandbox_env = setmetatable({},{
        __index=function(tbl,key)
            return self.overrides[key]
                or self.shared[key]
                or rawget(_G,key)
        end
    })
    sandbox_env._ENV = sandbox_env
    -- overrides any _G values in the overrides
    for key,value in pairs(self.overrides) do
        self._overrides[key]=rawget(_G,key)
        rawset(_G,key,value)
    end
    -- adds the sandbox to _G
    setmetatable(_G,sandbox_env)
end

--- This will load all file paths given and store them in the container for later use, this is the second stage of init
-- @usage conatiner:load()
function Container._prototype:load()
    self.fileState = 'LOADING'
    for _,filePath in ipairs(self.files) do
        vlog('load','Loading '..filePath)
        if self.spawned then
            self.files[filePath] = require(filePath)
        else
            local success, rtn = self:sandbox(require,{},filePath)
            if not success then error(rtn) end
            self.files[filePath] = rtn
        end
    end
    self.fileState = 'LOADED'
end

return setmetatable(Container,_mt_class)
--[[

Container = require 'class.container'
local container = Container()

container.debug = false
container.debugEnv = { 
    -- this can be used but will add a litle over head to debug functions
}

container.files = {
    'class.class',
    'class.queue',
    'class.stack',
    'class.emiter',
    'class.chain'
}

container.overrides = {
    vlog=function(...) container:log(...) end,
    require=function(...) return container:require(...) end,
    test=function() print('Hello, World!') end,
    tprint=function(tbl) for key,value in pairs(tbl) do print(key..': '..tostring(value)) end end,
    fprint=function(tbl) for key,value in pairs(tbl) do if type(value) ~= 'function' then print(key..': '..tostring(value)) end end end,
    iprint=function(tbl) for key,value in ipairs(tbl) do print(key..': '..tostring(value)) end end
}

container.logs = {
    error=true,
    info=false,
    output=output=function(type,msg) print('['..type..'] '..msg) end
}

container:spawn()
container:load()

Container.set('foo','here be foo')
Container.set('bar','here be bar')
Conatiner.file('class.queue')
Container.get('bar')

]]