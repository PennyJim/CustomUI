Object = require("./CustomUI/Object")

---@class Artist
local Artist = Object:new{}

---Draw a Border.
---@param gpu GPU
---@param position Vector2
---@param size Vector2
---@return boolean #Whether it was succefully drawn
function Artist.border(gpu, position, size)
  local draw = gpu.fill(position.x+1, position.y+size.y-1, size.x-2, 1, "▁") --Bottom Line
  draw = draw and gpu.fill(position.x+1, position.y, size.x-2, 1, "▔") --Top Line -- ―
  draw = draw and gpu.fill(position.x, position.y+1, 1, size.y-2, "▎") --Left Line -- |
  draw = draw and gpu.fill(position.x+size.x-1, position.y+1, 1, size.y-2, "🮇") --Right Line

  draw = draw and gpu.set(position.x, position.y, "🭽") --Top Left Corner
  draw = draw and gpu.set(position.x+size.x-1, position.y, "🭾") --Top Right Corner -- ☐
  draw = draw and gpu.set(position.x, position.y+size.y-1, "🭼") --Bottom Left Corner
  return draw and gpu.set(position.x+size.x-1, position.y+size.y-1, "🭿") --Bottom Right Corner
end

---Draw width-limited text.
---@param gpu GPU
---@param position Vector2
---@param maxWidth integer
---@param givenString string
---@return boolean #Whether it was succefully drawn
function Artist.text(gpu, position, maxWidth, givenString)
    local string = givenString
    if #givenString > maxWidth then
      string = givenString.sub(string, 1, maxWidth-2)..".."
    end
    return gpu.set(position.x, position.y, string)
end

---Changes color and returns whether the color changed and what to
---@private
---@param gpu GPU
---@param newColor Color?
---@param gpuFunc "setForeground"|"setBackground" # which color to set
---@return Color?
function Artist._switchColor(gpu, newColor, gpuFunc)
  if newColor then
    ---@type Color?
    local oldColor = gpu[gpuFunc](newColor)
    if oldColor == newColor then oldColor = nil end
    return oldColor
  end
end

---Changes background color and returns whether the color changed and what to
---@see Artist._switchColor
---@param gpu GPU
---@param newColor Color?
---@return Color?
function Artist.switchBackground(gpu, newColor)
  return Artist._switchColor(gpu, newColor, "setBackground")
end
---Changes foreground color and returns whether the color changed and what to
---@see Artist._switchColor
---@param gpu GPU
---@param newColor Color?
---@return Color?
function Artist.switchForeground(gpu, newColor)
  return Artist._switchColor(gpu, newColor, "setForeground")
end
---Changes both background and foreground
---@see Artist._switchColor
---@param gpu GPU
---@param newBg Color?
---@param newFg Color?
---@return Color?
---@return Color?
function Artist.switchColors(gpu, newBg, newFg)
  return Artist._switchColor(gpu, newBg, "setBackground"),
    Artist._switchColor(gpu, newFg, "setForeground")
end

---Resets background and foreground. Meant to surround the
---returns of a function that uses `Artist.switchColors`
---(typically `draw()`)<br>
---Will return any additional parameters passed
---@param gpu GPU
---@param oldBg Color?
---@param oldFg Color?
---@param ... unknown
---@return boolean
---@return unknown
function Artist.resetColors(gpu, oldBg, oldFg, ...)
  if oldBg then gpu.setBackground(oldBg) end
  if oldFg then gpu.setForeground(oldFg) end
  return ...
end

return Artist