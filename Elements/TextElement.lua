Vector2 = require("./CustomUI/Vector2")
Element = require("./CustomUI/Elements/Element")

---@class TextElement : Element
---@field __call fun(self:TextElement,x:integer,y:integer,text:string,bg:Color?,fg:Color?):TextElement
---@field text string
local TextElement = Element:new{}
---Constructor
---@protected
---@param x integer
---@param y integer
---@param text string
---@param bg Color?
---@param fg Color?
---@return TextElement
function TextElement:construct(x, y, text, bg, fg)
  local newObj = Element.construct(self, x, y, bg, fg)
  newObj.text = text
  return newObj
end
---Makes sure a TextElement is valid with given parameters
---@param x integer
---@param y integer
---@param text string
---@param bg Color?
---@param fg Color?
function TextElement._sanitize(x, y, text, bg, fg)
  --Sanitize Input Types
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, text, "string")
  checkArg(4, bg, "number", "nil")
  checkArg(5, fg, "number", "nil")
end

function TextElement:__call(x, y, text, bg, fg)
  self._sanitize(x, y, text, bg, fg)
  return self:construct(x, y, text, bg, fg)
end

function TextElement:isWithin(position)
  error("Not Implemented")
end

function TextElement:_drawSelfBefore(gpu)
    gpu.set(self.pos.x, self.pos.y, self.text)
end


TextElement = TextElement:new{}
return TextElement