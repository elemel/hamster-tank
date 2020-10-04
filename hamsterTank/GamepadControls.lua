local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(joystick)
  self.joystick = joystick

  self.minLength = 1 / 8
  self.maxLength = 1
end

function M:getJumpInput()
  return self.joystick:isGamepadDown("leftshoulder")
end

function M:getFireInput()
  return self.joystick:isGamepadDown("rightshoulder")
end

function M:getSpawnInput()
  return self.joystick:isGamepadDown("a")
end

function M:getRespawnInput()
  return self.joystick:isGamepadDown("y")
end

function M:getDespawnInput()
  return self.joystick:isGamepadDown("b")
end

function M:getMoveInput()
  local x = self.joystick:getGamepadAxis("leftx")
  local y = self.joystick:getGamepadAxis("lefty")

  local length = utils.length2(x, y)

  if length < self.minLength then
    return 0, 0
  end

  x, y = utils.normalize2(x, y)

  if length > self.maxLength then
    return x, y
  end

  length = (length - self.minLength) / (self.maxLength - self.minLength)
  return x * length, y * length
end

function M:getAimInput()
  local x = self.joystick:getGamepadAxis("rightx")
  local y = self.joystick:getGamepadAxis("righty")

  local length = utils.length2(x, y)

  if length < self.minLength then
    return 0, 0
  end

  x, y = utils.normalize2(x, y)

  if length > self.maxLength then
    return x, y
  end

  length = (length - self.minLength) / (self.maxLength - self.minLength)
  return x * length, y * length
end

return M
