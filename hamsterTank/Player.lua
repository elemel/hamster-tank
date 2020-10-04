local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, tank, camera, config)
  self.game = game
  self.tank = tank
  self.camera = camera

  self.leftKey = config.leftKey or "a"
  self.rightKey = config.rightKey or "d"

  self.jumpKey = config.jumpKey or "space"
  self.game.players[#self.game.players + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.players, self)
end

function M:fixedUpdateInput(dt)
  local leftInput = love.keyboard.isDown(self.leftKey)
  local rightInput = love.keyboard.isDown(self.rightKey)

  self.tank.inputX = (rightInput and 1 or 0) - (leftInput and 1 or 0)

  self.tank.previousJumpInput = self.tank.jumpInput
  self.tank.jumpInput = love.keyboard.isDown(self.jumpKey)

  local dx = self.game.accumulatedMouseDx
  local dy = self.game.accumulatedMouseDy

  self.game.accumulatedMouseDx = 0
  self.game.accumulatedMouseDy = 0

  dx, dy = utils.transformVector(self.camera.localToWorld, dx, dy)
  dx, dy = self.tank.body:getLocalVector(dx, dy)

  local sensitivity = 1 / 32

  self.tank.aimInputX = self.tank.aimInputX + dx * sensitivity
  self.tank.aimInputY = self.tank.aimInputY + dy * sensitivity

  local aimInputLength = utils.length2(self.tank.aimInputX, self.tank.aimInputY)

  if aimInputLength > 1 then
    self.tank.aimInputX = self.tank.aimInputX / aimInputLength
    self.tank.aimInputY = self.tank.aimInputY / aimInputLength
  end
end

function M:fixedUpdateCamera(dt)
  local x, y = self.tank.body:getPosition()
  local downX, downY = utils.normalize2(x, y)
  local angle = math.atan2(y, x) - 0.5 * math.pi
  local scale = self.camera.scale
  self.camera:setLocalToWorld(x - 0.125 / scale * downX, y - 0.125 / scale * downY, angle)
end

return M
