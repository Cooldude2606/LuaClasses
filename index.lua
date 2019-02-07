-- this creates a new container that will be later "spawned"
Container = require 'class.container'
local container = Container()

-- the debug settings can be set here and then run with Container.runInDebug(callback,...)
container.debug = false
--[[container.debugEnv = { 
    -- this can be used but will add a litle over head to debug functions
}]]

-- these are all the files that will be loaded by the container
-- if its not in the list it can still be loaded from a require within one of these files
container.files = {
    'class.class',
    'class.queue',
    'class.stack',
    'class.emiter',
    'class.chain',
    'class.functionChain'
}

-- these will be moved to _G when spawn is used, old ones will be moved to Container._overrides
-- these can be accessed in Container.sandbox however _G will be first in this case
container.overrides = {
    log=function(...) container:log(...) end,
    require=function(...) return container:require(...) end,
    test=function() print('Hello, World!') end,
    tprint=function(tbl) for key,value in pairs(tbl) do print(key..': '..tostring(value)) end end,
    fprint=function(tbl) for key,value in pairs(tbl) do if type(value) ~= 'function' then print(key..': '..tostring(value)) end end end,
    iprint=function(tbl) for key,value in ipairs(tbl) do print(key..': '..tostring(value)) end end
}

-- these will decide which log types get loged by Container.log seen above with log
-- output is any function and is called when a log of an allowed type if triggered
container.logs = {
    load=true,
    error=true,
    info=false,
    output=function(type,msg) print('['..type..'] '..msg) end
}

container:spawn() -- connects Container to container and creates overwrites
-- this spawn is imporant as it makes the container settings above apply to Container class
-- this can be accssed any where and allows "Container." rather than "container:"
container:load() -- loads all the files in the list above, best to do after spawn to avoid overhead of sandbox