---@class Object: table
---@field new fun(self: Object, newObj: Object?): Object
local Object = {}
---@param newObj Object?
---@return Object
function Object:new(newObj)
  newObj = newObj or {}
  setmetatable(newObj, self)
  self.__index = self
  return newObj
end

---Constructs an element
---@generic T
---@param self T
---@param ... unknown
---@return T
function Object:construct(...) return Object:new(...) end
function Object._sanitize(...) end

---Useless due to Object being nothing's metatable
---@param ... any?
---@return Object
function Object:__call(...)
  self._sanitize(...)
  return self:construct(...)
end

return Object