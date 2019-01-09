function tprint(tbl) for key,value in pairs(tbl) do print(key..': '..tostring(value)) end end
function fprint(tbl) for key,value in pairs(tbl) do if type(value) ~= 'function' then print(key..': '..tostring(value)) end end end
function iprint(tbl) for key,value in ipairs(tbl) do print(key..': '..tostring(value)) end end
Class = require 'class.class'
Queue = require 'class.queue'
Stack = require 'class.stack'
Emiter = require 'class.emiter'
Chain = require 'class.chain'