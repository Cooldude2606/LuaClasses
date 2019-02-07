Container = require 'class.container'
local container = Container()

container.debug = false
--[[container.debugEnv = { -- this can be used but will add a litle over head to debug functions

}]]

container.files = {
    'class.class',
    'class.queue',
    'class.stack',
    'class.emiter',
    'class.chain'
}

container.overrides = {
    vlog=function(...) container:vlog(...) end,
    require=function(...) container:require(...) end,
    test=function() print('Hello, World!') end,
    tprint=function(tbl) for key,value in pairs(tbl) do print(key..': '..tostring(value)) end end,
    fprint=function(tbl) for key,value in pairs(tbl) do if type(value) ~= 'function' then print(key..': '..tostring(value)) end end end,
    iprint=function(tbl) for key,value in ipairs(tbl) do print(key..': '..tostring(value)) end end
}

container.logs = {
    error=true,
    info=false,
    output=print
}

container:spawn()
container:load()