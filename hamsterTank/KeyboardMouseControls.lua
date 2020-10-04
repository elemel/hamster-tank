local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(config)
  self.leftKey = config.leftKey or "a"
  self.rightKey = config.rightKey or "d"

  self.upKey = config.upKey or "w"
  self.downKey = config.downKey or "s"

  self.jumpKey = config.jumpKey or "space"

  self.spawnKey = config.spawnKey or "enter"
  self.respawnKey = config.respawnKey or "backspace"
  self.despawnKey = config.despawnKey or "escape"

  self.aimInputX = 0
  self.aimInputY = 0

  self.accumulatedMouseDx = 0
  self.accumulatedMouseDy = 0

  self.mouseSensitivity = config.mouseSensitivity or 1 / 32
end

function M:getJumpInput()
  return love.keyboard.isDown(self.jumpKey)
end

function M:getFireInput()
  return love.mouse.isDown(1)
end

function M:getSpawnInput()
  return love.keyboard.isDown(self.spawnKey)
end

function M:getRespawnInput()
  return love.keyboard.isDown(self.respawnKey)
end

function M:getDespawnInput()
  return love.keyboard.isDown(self.despawnKey)
end

function M:getMoveInput()
  local leftInput = love.keyboard.isDown(self.leftKey)
  local rightInput = love.keyboard.isDown(self.rightKey)

  local upInput = love.keyboard.isDown(self.upKey)
  local downInput = love.keyboard.isDown(self.downKey)

  local inputX = (rightInput and 1 or 0) - (leftInput and 1 or 0)
  local inputY = (downInput and 1 or 0) - (upInput and 1 or 0)

  if utils.length2(inputX, inputY) > 1 then
    inputX, inputY = utils.normalize2(inputX, inputY)
  end

  return inputX, inputY
end

function M:getAimInput()
  if self.accumulatedMouseDx ~= 0 or self.accumulatedMouseDy ~= 0 then
    self.aimInputX = self.aimInputX + self.accumulatedMouseDx * self.mouseSensitivity
    self.aimInputY = self.aimInputY + self.accumulatedMouseDy * self.mouseSensitivity

    self.accumulatedMouseDx = 0
    self.accumulatedMouseDy = 0

    if utils.length2(self.aimInputX, self.aimInputY) > 1 then
      self.aimInputX, self.aimInputY = utils.normalize2(self.aimInputX, self.aimInputY)
    end
  end

  return self.aimInputX, self.aimInputY
end

function M:mousemoved(x, y, dx, dy, istouch)
  self.accumulatedMouseDx = self.accumulatedMouseDx + dx
  self.accumulatedMouseDy = self.accumulatedMouseDy + dy
end

return M
