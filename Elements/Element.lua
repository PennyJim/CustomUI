Vector2 = require("./CustomUI/Vector2")

---@class Element: Object
---@field __call fun(self:Element,x:integer,y:integer,bg:Color?,fg:Color?):Element
---@field pos Vector2 # Position (usually) relative to `parentWindow`
---@field type ElementType
---@field bg Color?
---@field fg Color?
---@field children Element[]
---@field parentWindow Window?
---@field isWithin fun(self:Element, pos:Vector2): boolean
---@field draw fun(self:Element,gpu:GPU):Color?,Color?,integer?
---@field down fun(self:Element,clickState:clickState,pos:Vector2,button:integer,player:string):boolean
---@field drag fun(self:Element,clickState:clickState,pos:Vector2,button:integer,player:string):boolean
---@field drop fun(self:Element,clickState:clickState,pos:Vector2,button:integer,player:string):boolean
local Element = Object:new{}
---Constructor.
---@protected
---@param x integer
---@param y integer
---@param bg Color?
---@param fg Color?
---@return Element
function Element:construct(x, y, bg, fg)
  return self:new{
    pos = Vector2{x,y},
    bg=bg,
    fg=fg,
    type = "element",
    children = {}
  }
end
---Makes sure an Element is valid with given parameters
---@param x integer
---@param y integer
---@param bg Color?
---@param fg Color?
function Element._sanitize(x, y, bg, fg)
  --Sanitize Input Types
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, bg, "number", "nil")
  checkArg(4, fg, "number", "nil")
end

---Returns position on screenspace
---@protected
---@return Vector2
function Element:_getAbsPos()
  return self.pos + self.parentWindow.pos - 1
end

function Element:__call(x, y, bg, fg)
  self._sanitize(x, y, bg, fg)
  return self:construct(x, y, bg, fg)
end

---Loop through children and call draw on them
---@private
---@param gpu GPU
function Element:_drawChildren(gpu)
  for i=#self.children,1,-1 do
    Artist.resetColors(gpu, self.children[i]:draw(gpu))
  end
end

---Any drawing to do before children
---@protected
---@param gpu GPU
function Element:_drawSelfBefore(gpu) end
---Any drawing to do after children
---@protected
---@param gpu GPU
function Element:_drawSelfAfter(gpu) end

---Draws itself and children when given a gpu.
-- Should not be overwritten.
---@param gpu GPU
---@return Color? #BG, if changed
---@return Color? #FG, if changed
function Element:draw(gpu)
  -- Switch colors while saving the old ones
  -- returns nil if colro is unchanged
  local oldBg, oldFg = Artist.switchColors(gpu, self.bg, self.fg)
  
  -- Draw items before children
  self:_drawSelfBefore(gpu)

  -- Draw children, if exist
  if #self.children > 0 then self:_drawChildren(gpu) end
  
  -- Draw items after children
  self:_drawSelfAfter(gpu)

  return oldBg, oldFg
end

---Might overwrite the drawing of the cursor
---@param gpu GPU
---@param clickState clickState
---@return Color? #BG, if changed
---@return Color? #FG, if changed
---@return boolean #Whether or not it was drawn
function Element:drawCursor(gpu, clickState) return nil, nil, false end

---Creates a parent-child relationship with given elements
---@param newElement Element
---@return Element
function Element:addChild(newElement)
  if newElement.parentWindow ~= nil
  then error("Given element is already parented", 2) end

  -- Add parentWindow field to newElement
  -- and set it to its own parent window
  -- or itself (because it is presumably
  -- a window if it has no parent)
  if self.parentWindow ~= nil then
    newElement.parentWindow = self.parentWindow
  else
    newElement.parentWindow = self
  end
  -- Because lua indexes at 1, subtract 1 less than parentWindow.pos
  newElement.parentWindow:markRedraw()
  table.insert(self.children, newElement)
  return newElement
end

---Whether or not `position` is found in the object.
---In this case, just returns if `position.x` and `position.y` overlap.
---@param position Vector2
---@return boolean
function Element:isWithin(position)
  return position == self:_getAbsPos()
end

---Calls click on any children
---@param clickState clickState
---@param event clickEvent
---@param pos Vector2
---@param button integer
---@param user string
---@return boolean #Whether or not it has been used
function Element:_clickChild(clickState, event, pos, button, user)
  local used = false
  for _, child in ipairs(self.children) do
    if (child:isWithin(pos)) then
      used = child:click(clickState, event, pos, button, user)
      return used
    end
  end
  return false
end

---Handle the click event on this element.
--- Should be overwritten to implement any clickable function.
---
--- You can return false if you want it to still send it to children 
---@protected
---@param clickState clickState
---@param pos Vector2
---@param button integer
---@param user string
---@return boolean #Whether or not it has been used
function Element:down(clickState, pos, button, user) return false end
function Element:drag(clickState, pos, button, user) return false end
function Element:drop(clickState, pos, button, user) return false end

---Either handles the click event or sends it to its children
---@param clickState clickState
---@param event clickEvent
---@param pos Vector2
---@param button integer
---@param user string
---@return boolean #Whether or not it has been used
function Element:click(clickState, event, pos, button, user)
  local used = self[event](self, clickState, pos, button, user)
  if not used then return self:_clickChild(clickState, event, pos, button, user)
  else return true end
end

---Handles the keyboard event if it can
---@param clickState clickState
---@param keyboard Keyboard
---@param event keyEvent
---@param input string?
---@param code integer?
---@param user string
---@return boolean # Whether or not the event has been used
function Element:key(clickState, keyboard, event, input, code, user)
return false end


Element = Element:new{}
return Element