Vector2 = require("./CustomUI/Vector2")
BoxElement = require("./CustomUI/Elements/BoxElement")
Artist = require("./CustomUI/Artist")

---@class Window: BoxElement
---@field __call fun(self:Window,root:WindowManager,x:integer,y:integer,w:integer,h:integer,bg:Color,fg:Color,title:string,doDecorate:boolean):Window
---@field root WindowManager
---@field gpu GPU
---@field title string
---@field drawBuffer integer
---@field doDecorate boolean
---@field redraw boolean
---@field markRedraw fun(self:Window)
local Window = BoxElement:new{}
---Creates a new window. Does not sanatize inputs, use __call()
---@protected
---@param self Window
---@param root WindowManager
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param bg Color
---@param fg Color
---@param title string
---@param doDecorate boolean
---@return Window
function Window:construct(root, x, y, w, h, bg, fg, title, doDecorate)
  local newWindow = BoxElement.construct(self, x, y, w, h, bg, fg)
  newWindow.absPos = newWindow.pos
  newWindow.type = "window"
  newWindow.title = title
  newWindow.doDecorate = doDecorate
  newWindow.drawBuffer = root.gpu.allocateBuffer(w, h)
  newWindow.doBubble = false
  newWindow.redraw = true
  newWindow.root = root
  newWindow.gpu = root.gpu
  return newWindow
end
---Makes sure a BoxElement is valid with given parameters
---@param root WindowManager
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param bg Color?
---@param fg Color?
---@param title string?
---@param doDecorate boolean?
function Window._sanitize(root, x, y, w, h, bg, fg, title, doDecorate)
  --Sanitize Input Types
  checkArg(1, root, "table")
  checkArg(2, x, "number")
  checkArg(3, y, "number")
  checkArg(4, w, "number")
  checkArg(5, h, "number")
  checkArg(6, bg, "number", "nil")
  checkArg(7, fg, "number", "nil")
  checkArg(8, title, "string", "nil")
  checkArg(9, doDecorate, "boolean", "nil")
  --Sanitize Inputs
  if (doDecorate) then
    assert(title, "#8 expected (Needs a title if decorated)")
    assert(w>=6, "#4 is too small (Expected at least 6, got "..w..")")
    assert(h>=5, "#5 is too small (Expected at least 5, got "..h..")")
  end
end

function Window:__call(...)
  self._sanitize(...)
  return self:construct(...)
end

function Window:__gc()
  self.root.gpu.freeBuffer(self.drawBuffer)
end

---Returns position on screenspace
---@protected
---@return Vector2
function Window:_getAbsPos()
  return self.pos
end

---Makes sure the given gpu matches `self.gpu`
---@param gpu GPU
function Window:_checkGpu(gpu)
  assert(self.gpu.address == gpu.address, "Given gpu does not match known gpu")
end

---Marks the Window for redrawing
function Window:markRedraw()
  self.redraw = true
  self.root.redrawWindows = true
end

---Moves the window to the given position
---@param newPos Vector2
---@param newGpu GPU? # if position is on another screen
function Window:move(newPos, newGpu)
  if newGpu then
    assert(self.gpu.freeBuffer(self.drawBuffer), "Wrong gpu or invalid buffer!")
    self.drawBuffer = self.gpu.allocateBuffer(self.size.x, self.size.y)
  end
  self.pos = newPos
  self.root.redrawWindows = true
end

---Resizes the window
---@param newSize Vector2
function Window:resize(newSize)
  if newSize == self.size then return end
  --TODO: add math.max for window minimum size.
  -- Also add a minimum size field
  -- gpu.bitblt(newBuffer, nil, nil, nil, nil, self.drawBuffer) --Not *needed*
  assert(self.gpu.freeBuffer(self.drawBuffer), "Wrong gpu or invalid buffer!")
  self.drawBuffer = self.gpu.allocateBuffer(newSize.x, newSize.y)
  self.size = newSize
  self:markRedraw()
end

function Window:_drawSelfBefore(gpu)
  self:_checkGpu(gpu)
  -- Draw background of window
  local origin = Vector2{1,1}
  gpu.fill(1,1,self.size.x,self.size.y, " ")
  Artist.border(gpu, origin, self.size)
end
function Window:_drawSelfAfter(gpu)
  -- Draw title bar if decorated
  if self.doDecorate then
    local origin = Vector2{1,1}
    Artist.border(gpu, origin, Vector2{self.size.x, 3})
    Artist.text(gpu, origin+1, self.size.x-3, self.title)
    gpu.set(self.size.x-1, 2, "╳") --❌?
  end
  self.redraw = false
end

function Window:drawCursor(gpu, clickState)
  -- Unecessary as it doesn't use self.drawBuffer
  -- self:_checkGpu(gpu)
  local cursor = clickState.cursor

  -- Don't override if cursor is at origin
  if cursor.pos == Vector2{0,0} then return nil, nil, false end
  -- Don't override if not dragging
  if not clickState.isDrag then return nil, nil, false end
  local dragType = clickState.dragType
  -- Don't override if not "window" or "resize"
  if dragType ~= "window" and dragType ~= "resize" then return nil, nil, false end
  local dragOffset = clickState.dragOffset

  -- Set colors while saving the old ones (if changed)
  local oldBg, oldFg = Artist.switchColors(gpu, self.bg, self.fg)

  -- Finally draw the box to indicate either dragging the window or resizing
  if dragType == "window" then
    return oldBg, oldFg, Artist.border(gpu, cursor.pos + dragOffset, self.size)
  else
    local newSize = cursor.pos - self.pos + 1
    newSize = Vector2{
      math.max(newSize.x, 7),
      math.max(newSize.y, 5)
    }
    return oldBg, oldFg, Artist.border(gpu, self.pos, newSize)
  end
end

function Window:down(clickState, pos, button, user)
  if self.doDecorate then
    -- Set dragType to "window" if titlebar clicked
    if pos.y - self.pos.y < 3 then
      clickState.dragType = "window"
      clickState.dragOffset = self.pos - pos
      clickState.selectedElement = self
      return true

    -- Set dragType to "resize" if bottom right corner clicked
    elseif pos == self.pos+self.size-1 then
      clickState.cursor:setCursor("⇲") --Too large: "⤡"
      clickState.dragType = "resize"
      clickState.dragOffset = pos
      clickState.selectedElement = self
      return true
    end
  end
  -- Otherwise, pass event to children
  return false
end
function Window:drop(clickState, pos, button, user)
    -- Move window if titlebar was dragged
    if clickState.dragType == "window" then
      self:move(pos+clickState.dragOffset)

    -- Resize window if corner was dragged
    elseif clickState.dragType == "resize" then
      local newSize = pos - clickState.activeWindow.pos + 1
      newSize = Vector2{
        math.max(newSize.x, 7),
        math.max(newSize.y, 5)
      }
      self:resize(newSize)
    end

    -- Complete event
    return true
end


Window = Window:new{}
return Window