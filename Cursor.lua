Vector2 = require("./CustomUI/Vector2")
Object = require("./CustomUI/Object")

---@class Cursor: Object
---@field pos Vector2
---@field bg Color?
---@field fg Color?
---@field cursor string
--Does not support multiple paramaters?
--@operator call(Vector2,Color?,Color?,string):Cursor
local Cursor = Object:new{}
---Creates a new Cursor object
---@param pos Vector2?
---@param bg Color?
---@param fg Color?
---@param cursor string
---@return Cursor
function Cursor:construct(pos, bg, fg, cursor)
  return Cursor:new{
    pos=pos or Vector2{0,0},
    bg=bg,
    fg=fg,
    cursor=cursor or "🮰"
  }
end
function Cursor._sanitize(pos, bg, fg, cursor)
  checkArg(1, pos, "table", "nil")
  checkArg(2, bg, "number", "nil")
  checkArg(3, fg, "number", "nil")
  checkArg(4, cursor, "string", "nil")

  if pos then
    assert(type(pos.x) == "number" and
      type(pos.y) == "number",
      "bad argument #1 (Vector2 expected, got unknown table)", 3)
  end
end
function Cursor:__call(...)
  self._sanitize(...)
  return self:construct(...)
end
---sets the cursor value. Sets it to `🮰` when given nil
---@param newCursor string?
function Cursor:setCursor(newCursor)
  self.cursor = newCursor or "🮰"
end


Cursor = Cursor:new{}
return Cursor