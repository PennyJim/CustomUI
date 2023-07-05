---@module "./Syntax.lua.meta"
Vector2 = require("./CustomUI/Vector2")
Object = require("./CustomUI/Object")
Cursor = require("./CustomUI/Cursor")
Window = require("./CustomUI/Window")
---@diagnostic disable: lowercase-global
thread = require("thread")
event = require("event")
component = require("component")
---@diagnostic enable: lowercase-global

---Moves the item at an index to another position
---@generic T
---@param array T[]
---@param oldIndex integer
---@param newIndex integer
---@return T
function table.moveToIndex(array, oldIndex, newIndex)
  local movedItem = table.remove(array, oldIndex)
  table.insert(array, newIndex, movedItem)
  return movedItem
end

---@class WindowManager: Object
---@field windows Window[]
---@field bg Color
---@field fg Color
---@field gpu GPU
---@field drawBuffer integer
---@field frameThread thread?
---@field eventThread thread?
---@field background Cursor #Stop using a Cursor?
---@field redrawWindows boolean
---@field clickState clickState
---@field eventHandler fun(...)
local WindowManager = Object:new{}

--#region Functional Functions

---Moves window to the front of the array
---@param activeWindow Window | integer
function WindowManager:setActiveWindow(activeWindow)
  --Sanitize Type
  checkArg(1, activeWindow, "number", "table")

  --Find the index of given window
  --TODO: Improve
  if (type(activeWindow) == "table") then
    for i, window in ipairs(self.windows) do
      if activeWindow == window then
        activeWindow = i
        break
      end
    end
    if (type(activeWindow) ~= "number") then
      error("Given table is not a known window object", 2)
    end
  end
  ---@cast activeWindow integer

  if (activeWindow > #self.windows)
  then error("Given index is out of bounds", 2) end

  self.redrawWindows = true
  self.clickState.activeWindow =
    table.moveToIndex(self.windows, activeWindow, 1)
end

---Sets the character in background buffer.
---Changes active buffer and doesn't revert
---@param bg Color
---@param fg Color
---@param character string?
---@return boolean # True if set. False if otherwise unable to
function WindowManager:setBackground(bg, fg, character)
  bg = bg or self.background.bg
  fg = fg or self.background.fg
  character = character or self.background.cursor
  self.background = Cursor(nil, bg, fg, character)
  return true
end
function WindowManager:markRedraw()
  WindowManager.redrawWindows = true;
  return true end
--#endregion

--#region Element Functions

---Adds a Window to the UI
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param bg Color
---@param fg Color
---@param title string?
---@param doDecorate boolean?
---@return Window
function WindowManager:newWindow(x, y, w, h, bg, fg, title, doDecorate)
  local newWindow = Window(self, x, y, w, h, bg, fg, title, doDecorate)
  table.insert(self.windows, 1, newWindow)
  return newWindow
end

--#endregion

--#region Drawing Functions

---Draws the background
---@return Color? #BG, if changed
---@return Color? #FG, if changed
---@return boolean # Whether or not it was filled
function WindowManager:drawBackground()
  local w, h = self.gpu.getBufferSize()
  local oldBg, oldFg =
    Artist.switchColors(self.gpu, self.background.bg, self.background.fg)
  return oldBg, oldFg, self.gpu.fill(1, 1, w, h, self.background.cursor)
end

---Draw the windows to their buffer, if requested
function WindowManager:drawWindows()
  for i=#self.windows, 1, -1 do
    local window = self.windows[i]
    if self.windows[i].redraw then
      self.gpu.setActiveBuffer(window.drawBuffer)
      Artist.resetColors(self.gpu, self.windows[i]:draw(self.gpu))
    end
    self.gpu.bitblt(self.drawBuffer, window.pos.x, window.pos.y, 
      nil, nil, window.drawBuffer)
  end
end

---Draws the cursor
---@return Color? #BG, if changed
---@return Color? #FG, if changed
---@return boolean # Whether or not it was drawn
function WindowManager:drawCursor()
  local oldBg, oldFg = nil, nil
  local clickState = self.clickState
  local cursor = clickState.cursor

-- Let the selectedElement try drawing it
  local hasDrawn = false
  if clickState.selectedElement then
    oldBg, oldFg, hasDrawn =
    clickState.selectedElement:drawCursor(self.gpu, clickState)
  end
  -- Not necessary(?) as Window only cares when
  -- it already should be selectedElement
  if not hasDrawn and clickState.activeWindow then
    oldBg, oldFg, hasDrawn =
    clickState.activeWindow:drawCursor(self.gpu, clickState)
  end
  -- Return if drawn
  if hasDrawn then return oldBg, oldFg, true end

-- Now draw it ourselves:
  -- If cursor is at origin, then don't draw
  if cursor.pos == Vector2{0,0} then return oldBg, oldFg, false end

  -- Grab background of cursor position and set it and its inverse
  -- as the background and foreground
  local _, _, bg = self.gpu.get(cursor.pos.x, cursor.pos.y)
  bg = cursor.bg or bg
  local fg = cursor.fg or bg ~ 0xffffff
  oldBg, oldFg = Artist.switchColors(self.gpu, bg, fg)

  -- Finally draw the basic cursor
  return oldBg, oldFg, self.gpu.set(cursor.pos.x, cursor.pos.y, cursor.cursor)
end

---Draws a frame to the screen
function WindowManager:drawFrame()
  if self.redrawWindows then
    -- Draw background, then revert back to default colors
    self.gpu.setActiveBuffer(self.drawBuffer)
    Artist.resetColors(self.gpu, self:drawBackground())

    -- Draw windows
    self:drawWindows()
    self.redrawWindows = false
  end
  -- Only useful when debugging in the lua shell
  local _, h = self.gpu.getResolution()
  -- Copy drawbuffer to screen
  --  the `h-2` is for debugging
  self.gpu.bitblt(0, 1, 1, nil, h-2, self.drawBuffer)
  -- Draw the cursor onto the screen
  self.gpu.setActiveBuffer(0)
  self:drawCursor()
end

--#endregion

--#region Event Functions

---@private
---@class clickState
---@field isDrag boolean
---@field dragType string? # TODO: turn into a syntax enum
---@field dragOffset Vector2
---@field activeWindow Window?
---@field selectedElement Element?
---@field cursor Cursor
---@field reset fun()

---Handles any click event and sends it to the clicked element
---@param event string
---@param pos Vector2
---@param button integer
---@param user string
---@return boolean #Whether or not it has been used
function WindowManager:click(event, pos, button, user)
  local used = false
  -- Move cursor if not lifted
  if event ~= "drop" then self.clickState.cursor.pos = pos end
  -- Update isDrag if dragged
  if not self.clickState.isDrag and event == "drag" then
    self.clickState.isDrag = true
  end
  -- Find element to click on down
  if event == "down" then
    for i, window in ipairs(self.windows) do
      if (window:isWithin(pos)) then
        self.clickState.activeWindow = window
        self:setActiveWindow(i)
        used = window:click(self.clickState, event, pos, button, user)
        break
      end
    end
  else
    -- Click selectedElement or activeWindow if exists
    local selectedElement = self.clickState.selectedElement
    local activeWindow = self.clickState.activeWindow
    if selectedElement then
      used = selectedElement:click(self.clickState, event, pos, button, user)
    end
    -- Not useful(?) as window sets selectedElement to itself
    -- if it has something to do with further events
    if not used and activeWindow then
      used = activeWindow:click(self.clickState, event, pos, button, user)
    end
  end
  -- Reset clickState if lifted
  if event == "drop" then
    self.clickState:reset()
  end
  return used
end

---Handles any key event and sends it to the selected element
---@param event keyEvent
---@param input string?
---@param code integer?
---@param user string
---@return boolean #Whether or not it has been used
function WindowManager:key(keyboard, event, input, code, user)
  local selectedElement = self.clickState.selectedElement
  local activeWindow = self.clickState.activeWindow
  local used = false

  -- TODO: add macros like alt-tab

  if not used and activeWindow then
    used = activeWindow:key(self.clickState, keyboard, event, input, code, user)
  end
  if not used and selectedElement then
    used = selectedElement:key(self.clickState, keyboard, event, input, code, user)
  end
  return used
end

---Handles events
---@param event clickEvent | keyEvent
---@param addr any
---@param ... unknown
function WindowManager:_eventHandler(event, addr, ...)
  if (event == "drag" or event == "touch" or event == "drop")
    and addr == self.gpu.getScreen()
  then
    if event == "touch" then event = "down" end
    local x, y, button, user = ...
    self:click(event, Vector2{x, y}, button, user)
  elseif event == "key_down" or event == "key_up" or event == "clipboard" then
    local keyboard = component.get(addr)
    -- Either that or pass the addr and have `self:key()` handle it
    ---@cast event keyEvent
    local input, code, user
    if event ~= "clipboard" then
      input, code, user = ...
      if keyboard.isControl(input) then input = nil
      else input = string.char(input) end
    else input, user = ... end
    self:key(keyboard, event, input, code, user)
  end
end

--#endregion

--#region Setup

---Construct a new Window Manager
---@param gpu GPU
---@param bg Color?
---@param fg Color?
---@return WindowManager
function WindowManager:construct(gpu, bg, fg)
  local newManager = self:new{
    windows = {},
    bg = bg or 0x0,
    fg = fg or 0xffffff,
    gpu = gpu,
    drawBuffer = gpu.allocateBuffer(),
    background = Cursor(nil, bg or 0x0, fg or 0xffffff, " "),
    redrawWindows = true,
    clickState = {
      cursor = Cursor(),
      isDrag = false,
      dragType = nil,
      dragOffset = Vector2{0,0},
      activeWindow = nil,
      selectedElement = nil,
      reset = function(self)
        self.cursor = Cursor()
        self.isDrag = false
        self.dragType = nil
        self.dragOffset = Vector2{0,0}
      end
    },
  }
  newManager.eventHandler = function(...)
    self._eventHandler(newManager, ...)
  end
  return newManager
end
function WindowManager._sanitize(gpu, bg, fg)
  checkArg(1, gpu, "table")
  checkArg(2, bg, "number", "nil")
  checkArg(3, fg, "number", "nil")

  assert(getmetatable(gpu.bitblt) and gpu.bitblt(0,0,0,0,0,0),
    "bad argument #1 (GPU expected, got unknown table)", 3)
end
function WindowManager:__call(...)
  self._sanitize(...)
  return self:construct(...)
end

function WindowManager:start()
  self.events = { --TODO: turn into separate thread?
    event.listen("touch", self.eventHandler),
    event.listen("drag", self.eventHandler),
    event.listen("drop", self.eventHandler)
  }
  --TODO: move the xpcall inside the while loop
  self.frameThread = thread.create(function(Screen)
    local _, err = xpcall(function (Screen)
      while true do
        Screen:drawFrame()
---@diagnostic disable-next-line: undefined-field
        os.sleep(0.015)
      end
    end, debug.traceback, Screen)
    if err then
      Screen.gpu.setActiveBuffer(0)
      Screen.gpu.set(160-#err, 50, err)
    end
  end, self) --[[@as thread]]
end

function WindowManager:stop()
  ---@diagnostic disable-next-line: undefined-field
  self.frameThread:kill()
  event.cancel(self.events[1])
  event.cancel(self.events[2])
  event.cancel(self.events[3])
  self.events = {}
end

function WindowManager:__gc()
  --Stop if not stopped
  if #self.events > 0 then self:stop() end
  --Free the memory attatched to the buffer
  self.gpu.freeBuffer(self.drawBuffer)
end

--#endregion


WindowManager = WindowManager:new{}
return WindowManager