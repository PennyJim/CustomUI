---@class Vector2
---@field x integer
---@field y integer
local Vector2 = {}
--#region Copy/Construct
---easily create `Position` objects
---@param badVector table | Vector2 | integer
---@param y integer?
---@return Vector2
Vector2.new = function(badVector, y)
  checkArg(1, badVector, "table", "number")
  if type(badVector) == "table" then
    if badVector.x then
      assert(type(badVector.x) == "number",
        "bad argument #1.x (number expected, got " .. type(badVector.x))
      assert(type(badVector.y) == "number",
        "bad argument #1.y (number expected, got " .. type(badVector.y))
    elseif badVector[1] then
      assert(type(badVector[1]) == "number",
        "bad argument #1[1] (number expected, got " .. type(badVector[1]))
      assert(type(badVector[2]) == "number",
        "bad argument #1[2] (number expected, got " .. type(badVector[2]))
    else
      assert(false, "bad argument #1 (array or Vector2 or number expected, got unknown table")
    end
  else
    checkArg(2, y, "number")
  end

  local newVector
  if type(badVector) == "number" then newVector = {x=badVector, y=y}
  elseif badVector.x then newVector = {x=badVector.x,y=badVector.y}
  else newVector = {x=badVector[1], y=badVector[2]} end
  setmetatable(newVector, Vector2)
  return newVector
end
function Vector2:copy()
  return self:new()
end
function Vector2:__call(newObj)
  return self.new(newObj)
end
---Returns x and y
---@return integer
---@return integer
function Vector2:expand()
  return self.x, self.y
end
Vector2.__index = Vector2
Vector2 = setmetatable({}, Vector2)
Vector2.__index = Vector2
--#endregion
--#region Calculation
function Vector2.__add(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only add an Integer or Position")
    return Vector2.new{vec1+vec2.x, vec1+vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only add an Integer or Position")
    return Vector2.new{vec1.x+vec2, vec1.y+vec2}
  else
    return Vector2.new{vec1.x+vec2.x, vec1.y+vec2.y}
  end
end
function Vector2.__sub(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only subtract an Integer or Position")
    return Vector2.new{vec1-vec2.x, vec1-vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only subtract an Integer or Position")
    return Vector2.new{vec1.x-vec2, vec1.y-vec2}
  else
    return Vector2.new{vec1.x-vec2.x, vec1.y-vec2.y}
  end
end
function Vector2.__mul(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only multply an Integer or Position")
    return Vector2.new{vec1*vec2.x, vec1*vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only multply an Integer or Position")
    return Vector2.new{vec1.x*vec2, vec1.y*vec2}
  else
    return Vector2.new{vec1.x*vec2.x, vec1.y*vec2.y}
  end
end
function Vector2.__div(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only divide an Integer or Position")
    return Vector2.new{vec1/vec2.x, vec1/vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only divide an Integer or Position")
    return Vector2.new{vec1.x/vec2, vec1.y/vec2}
  else
    return Vector2.new{vec1.x/vec2.x, vec1.y/vec2.y}
  end
end
function Vector2.__mod(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only modulo an Integer or Position")
    return Vector2.new{vec1%vec2.x, vec1%vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only modulo an Integer or Position")
    return Vector2.new{vec1.x%vec2, vec1.y%vec2}
  else
    return Vector2.new{vec1.x%vec2.x, vec1.y%vec2.y}
  end
end
function Vector2.__pow(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only floor divide an Integer or Position")
    return Vector2.new{vec1^vec2.x, vec1^vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only floor divide an Integer or Position")
    return Vector2.new{vec1.x^vec2, vec1.y^vec2}
  else
    return Vector2.new{vec1.x^vec2.x, vec1.y^vec2.y}
  end
end
function Vector2.__idiv(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only exponentiate an Integer or Position")
    return Vector2.new{vec1//vec2.x, vec1//vec2.y}
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only exponentiate an Integer or Position")
    return Vector2.new{vec1.x//vec2, vec1.y//vec2}
  else
    return Vector2.new{vec1.x//vec2.x, vec1.y//vec2.y}
  end
end
function Vector2.__unm(vec)
  return Vector2.new{-vec.x, -vec.y}
end
--#endregion
--#region Comparison
function Vector2.__eq(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only compare an Integer or Position")
    return vec1==vec2.x and vec1==vec2.y
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only compare an Integer or Position")
    return vec1.x==vec2 and vec1.y==vec2
  else
    return vec1.x==vec2.x and vec1.y==vec2.y
  end
end
function Vector2.__lt(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only compare an Integer or Position")
    return vec1<vec2.x and vec1<vec2.y
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only compare an Integer or Position")
    return vec1.x<vec2 and vec1.y<vec2
  else
    return vec1.x<vec2.x and vec1.y<vec2.y
  end
end
function Vector2.__le(vec1, vec2)
  if getmetatable(vec1) ~= Vector2 then
    assert(type(vec1)=="number", "Can only compare an Integer or Position")
    return vec1<=vec2.x and vec1<=vec2.y
  elseif getmetatable(vec2) ~= Vector2 then
    assert(type(vec2)=="number", "Can only compare an Integer or Position")
    return vec1.x<=vec2 and vec1.y<=vec2
  else
    return vec1.x<=vec2.x and vec1.y<=vec2.y
  end
end
--#endregion
function Vector2.__tostring(vec)
  return "[" .. vec.x .. ", " .. vec.y .. "]"
end

return Vector2