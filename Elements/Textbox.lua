Vector2 = require("./CustomUI/Vector2")
BoxElement = require("./CustomUI/Elements/BoxElement")
Artist = require("./CustomUI/Artist")

---@class Textbox: BoxElement
---@field __call fun(self:Textbox,x:integer,y:integer,w:integer,h:integer,bg:Color?,fg:Color?,defaultText:string?,defaultTextColor:Color?):Textbox
---@field defaultText string?
---@field defaultColor Color?
---@field text string
---@field cursorOffset integer
---@field textOffset integer
---@field flickerTime number
local Textbox = BoxElement:new{}
---Constructor
---@param x integer
---@param y integer
---@param w integer
---@param bg Color?
---@param fg Color?
---@param defaultText string?
---@param defaultColor Color?
---@return Textbox
function Textbox:construct(x, y, w, bg, fg, defaultText, defaultColor)
  local newObj = BoxElement.construct(self, x, y, w, 3, bg, fg)
  newObj.defaultText = defaultText
  newObj.defaultColor = defaultColor
  newObj.text = ""
  newObj.cursorOffset = 0
  newObj.textOffset = 0
  newObj.type = "textbox"
  newObj.flickerTime = math.maxinteger
  return newObj
end
function Textbox._sanitize(x, y, w, bg, fg, defaultText, defaultColor)
  --Sanitize Input Types
  checkArg(1, x, "number")
  checkArg(2, y, "number")
  checkArg(3, w, "number")
  checkArg(4, bg, "number", "nil")
  checkArg(5, fg, "number", "nil")
  checkArg(6, defaultText, "string", "nil")
  checkArg(7, defaultColor, "number", "nil")
  --Sanitize Inputs
  assert(w>=5, "#3 is too small (Expected at least 5, got"..w..")")
  if defaultText then
    assert(w>=#defaultText+2, "#3 is too small (Expected at least #6 + 2 ("..
      (#defaultText+2).."), got "..w..")")
  end
end

function Textbox:__call(...)
  self._sanitize(...)
  return self:construct(...)
end

function Textbox:_drawSelfBefore(gpu)
  -- Draw box
  gpu.fill(self.pos.x,self.pos.y,self.size.x,self.size.y, " ")
  Artist.border(gpu, self.pos, self.size)

  -- Draw internal text
  if #self.text > 0 then
    -- Draw text using textOffset
    local text = self.text:sub(1+self.textOffset, self.size.x-2+self.textOffset)
    gpu.set(self.pos.x+1, self.pos.y+1, text)

  -- Draw defaultText if exists
  elseif self.defaultText then
    -- Change color if defaultColor exists
    local oldColor = Artist.switchForeground(gpu, self.defaultColor)

    -- Draw defaultText
    gpu.set(self.pos.x+1, self.pos.y+1, self.defaultText)
    -- Revert color to not-break compatibility
    if oldColor then gpu.setForeground(oldColor) end
  end
end

---@param gpu GPU
function Textbox:drawCursor(gpu, clickState)
  -- Invert text cursor if flickerTime is 0-0.5 seconds
  -- os.time()/72 is seconds for some reason??
  local curFlicker = os.time() - self.flickerTime
  if curFlicker < 36 then
    local pos = self:_getAbsPos() + Vector2{self.cursorOffset+1, 1}
    -- Invert position
    local char, fg, bg = gpu.get(pos.x, pos.y)
    local oldBg, oldFg = Artist.switchColors(gpu, fg, bg)
    gpu.set(pos.x, pos.y, char)
    return oldBg, oldFg, false --I want it to still draw the normal cursor

  -- reset flickerTime if it's greater than 1 second
  -- Should result in toggling back and forth every second
  elseif curFlicker > 72 then self.flickerTime = os.time() end
end


---Move text window in that direction
---@param direction integer
function Textbox:_moveText(direction)
  local rightBound = #self.text - self.size.x + 3
  rightBound = math.max(rightBound, 0)
  -- Do nothing if nothing will be done
  if self.textOffset == 0 and direction < 0 or
  self.textOffset == rightBound and direction > 0 or
  direction == 0
  then return end

  -- If text window will exceed bounds, clamp it
  if self.textOffset + direction < 0 then
    self.textOffset = 0
  elseif self.textOffset + direction > rightBound then
    self.textOffset = rightBound
  else
    self.textOffset = self.textOffset+direction
  end
  self.parentWindow:markRedraw()
end
---Move cursor to position
---@param xPos integer
---@param isRelative boolean?
---@param maxScroll integer?
function Textbox:_moveCursor(xPos, isRelative, maxScroll)
  maxScroll = maxScroll or math.maxinteger
  if isRelative then xPos = self.cursorOffset + xPos end
  -- Bound to window and shift it left or right
  if xPos < 0 then
    self:_moveText(math.max(xPos, -maxScroll))
    xPos = 0
  elseif xPos > self.size.x-3 then
    self:_moveText(math.min(xPos-self.size.x+3,maxScroll))
    xPos = self.size.x-3
  end
  self.cursorOffset = xPos
  self.flickerTime = os.time()

  -- Shift cursorOffset to the left if after string
  local biggestOffset = #self.text:sub(self.textOffset, -1)
  if self.cursorOffset > biggestOffset then
    self.cursorOffset = biggestOffset
  end
end

function Textbox:down(clickState, pos, button, user)
  -- If within text window, set cursorOffset
  -- pos - self.pos = [1,1] --> [0,0]
  local localPos = pos - self:_getAbsPos()
  if localPos.y == 1 and localPos.x ~= 0 or localPos.x ~= self.size.x-1 then
    self:_moveCursor(localPos.x-1)
    --Make self active element
    clickState.selectedElement = self
    return true
  end
  return false
end
function Textbox:drag(clickState, pos, button, user)
  -- Set cursorOffset to x position, and limit
  -- Scrolling to 1 character at a time
  local xPos = pos.x-self:_getAbsPos().x-1
  self:_moveCursor(xPos, false, 1)
end
-- function TextBox:drop(clickState, pos, button, user)
-- end

--#region keyCode functions
Textbox._key = {}
-- [x]: Arrow Keys
-- [x]: Home/end
-- [x]: Pageup/Pagedown #Maybe remove and let window handle it?
-- [x]: Backspace/Del
-- [\]: Tab # this box does not handle these
-- [\]: Enter

-- TODO: add ctrl modifier behavior
-- [ ]: Arrow Keys
-- [ ]: Backspace/Del
Textbox._key["left"] = function(self, clickState, keyboard, user)
  self:_moveCursor(-1, true); return true end
Textbox._key["right"] = function(self, clickState, keyboard, user)
  self:_moveCursor(1, true); return true end

Textbox._key["back"] = function(self, clickState, keyboard, user)
  local offset = self.textOffset+self.cursorOffset
  if offset == 0 then return true end -- Nothing to delete
  self.text = self.text:sub(1, offset-1)..self.text:sub(offset+1,-1)
  self:_moveCursor(-1, true)
  if not self.parentWindow.redraw then self.parentWindow:markRedraw() end
  return true
end
Textbox._key["delete"] = function(self, clickState, keyboard, user)
  local offset = self.textOffset+self.cursorOffset
  self.text = self.text:sub(1, offset)..self.text:sub(offset+2,-1)
  self.parentWindow:markRedraw()
  return true
end

Textbox._key["home"] = function(self, clickState, keyboard, user)
  self:_moveCursor(-math.maxinteger); return true end
Textbox._key["up"] = function(self, clickState, keyboard, user)
  self:_moveCursor(-math.maxinteger); return true end
Textbox._key["pageUp"] = function(self, clickState, keyboard, user)
  self:_moveText(-self.size.x+2); return true end
Textbox._key["end"] = function(self, clickState, keyboard, user)
  self:_moveCursor(math.maxinteger); return true end
Textbox._key["down"] = function(self, clickState, keyboard, user)
  self:_moveCursor(math.maxinteger); return true end
Textbox._key["pageDown"] = function(self, clickState, keyboard, user)
  self:_moveText(self.size.x-2); return true end

--#endregion

function Textbox:key(clickState, keyboard, event, input, code, user)
  -- Don't handle key_up
  if event == "key_up" then return false end

  if input then
    local offset = self.textOffset+self.cursorOffset
    local newText = self.text:sub(1, offset)..input..self.text:sub(offset+1, -1)
    self.text = newText
    self:_moveCursor(#input, true)
    if not self.parentWindow.redraw then self.parentWindow:markRedraw() end
    return true
  elseif code then
    local keyCodeName = keyboard.keys[code]
    if self._key[keyCodeName] then
      return self._key[keyCodeName](self, clickState, keyboard, user)
    end
  end
  return false
end


Textbox = Textbox:new{}
return Textbox