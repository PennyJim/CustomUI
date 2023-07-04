Vector2 = require("./CustomUI/Vector2")
Element = require("./CustomUI/Elements/Element")
Artist = require("./CustomUI/Artist")

---@class BoxElement: Element
---@field __call fun(self:BoxElement,x:integer,y:integer,w:integer,h:integer,bg:Color?,fg:Color?):BoxElement
---@field size Vector2
local BoxElement = Element:new{}
---Constructor
---@protected
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param bg Color?
---@param fg Color?
---@return BoxElement
function BoxElement:construct(x, y, w, h, bg, fg)
  local newObj = Element.construct(self, x, y, bg, fg)
  newObj.size = Vector2{w,h}
  newObj.type = "box"
  return newObj
end
---Makes sure a BoxElement is valid with given parameters
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param bg Color?
---@param fg Color?
function BoxElement._sanitize(x, y, w, h, bg, fg)
  --Sanitize Input Types
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, w, "number")
  checkArg(4, h, "number")
  checkArg(5, bg, "number", "nil")
  checkArg(6, fg, "number", "nil")
  --Sanitize Inputs
  assert(w>=2, "#3 is too small (Expected at least 2, got "..w..")")
  assert(h>=2, "#4 is too small (Expected at least 2, got "..h..")")
end

function BoxElement:__call(x, y, w, h, bg, fg)
  self._sanitize(x, y, w, h, bg, fg)
  return self:construct(x, y, w, h, bg, fg)
end

---Whether or not the `Position` is found in the object.
---@see Element
---@param pos Vector2
---@return boolean
function BoxElement:isWithin(pos)
  local absPos = self:_getAbsPos()
  return pos >= absPos and pos < absPos + self.size
end

function BoxElement:_drawSelfBefore(gpu)
  gpu.fill(self.pos.x,self.pos.y,self.size.x,self.size.y, " ")
  Artist.border(gpu, self.pos, self.size)
end


BoxElement = BoxElement:new{}
return BoxElement