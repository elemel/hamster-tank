local Class = require("hamsterTank.Class")
local Tank = require("hamsterTank.Tank")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, camera, config)
  self.game = game
  self.camera = camera

  self.leftKey = config.leftKey or "a"
  self.rightKey = config.rightKey or "d"

  self.jumpKey = config.jumpKey or "space"
  self.suicideKey = config.suicideKey or "backspace"

  self.despawnDelay = 0
  self.game.players[#self.game.players + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.players, self)
end

function M:fixedUpdateSpawn(dt)
  if self.tank and (self.tank.dead or self.tank.destroyed) then
    self.despawnDelay = self.despawnDelay - dt

    if self.despawnDelay < 0 then
      self.tank = nil
    end
  end

  if not self.tank then
    self.despawnDelay = 2

    local rayAngle = love.math.random() * 2 * math.pi
    local rayLength = 256

    local rayDirectionX = math.cos(rayAngle)
    local rayDirectionY = math.sin(rayAngle)

    local rayX = rayDirectionX * rayLength
    local rayY = rayDirectionY * rayLength

    local intersectionFixture

    local intersectionX = 0
    local intersectionY = 0

    local intersectionNormalX = 0
    local intersectionNormalY = 0

    self.game.world:rayCast(0, 0, rayX, rayY, function(fixture, x, y, xn, yn, fraction)
      if fixture:getShape():getType() ~= "chain" then
        return 1
      end

      intersectionFixture = fixture

      intersectionX = x
      intersectionY = y

      intersectionNormalX = xn
      intersectionNormalY = yn

      return 0
    end)

    if intersectionFixture then
      local spawnDistance = 4

      local spawnX = intersectionX - rayDirectionX * spawnDistance
      local spawnY = intersectionY - rayDirectionY * spawnDistance

      local spawnAngle = math.atan2(intersectionNormalY, intersectionNormalX) + 0.5 * math.pi

      self.tank = Tank.new(self.game, {
        transform = {spawnX, spawnY, spawnAngle},

        jumpInput = love.keyboard.isDown(self.jumpKey),
        suicideInput = love.keyboard.isDown(self.suicideKey),
        fireInput = love.mouse.isDown(1)
      })

      local x, y = self.tank.body:getPosition()
      local angle = self.tank.body:getAngle()

      self:fixedUpdateCamera(dt)
      self.camera.previousWorldToScreen:reset():apply(self.camera.worldToScreen)
    end
  end
end

function M:fixedUpdateInput(dt)
  if not self.tank or self.tank.destroyed then
    return
  end

  self.tank.previousJumpInput = self.tank.jumpInput
  self.tank.previousSuicideInput = self.tank.suicideInput
  self.tank.previousFireInput = self.tank.fireInput

  self.tank.suicideInput = love.keyboard.isDown(self.suicideKey)
  self.tank.fireInput = love.mouse.isDown(1)

  local leftInput = love.keyboard.isDown(self.leftKey)
  local rightInput = love.keyboard.isDown(self.rightKey)

  self.tank.inputX = (rightInput and 1 or 0) - (leftInput and 1 or 0)
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
  if self.tank and not self.tank.destroyed then
    local x, y = self.tank.body:getPosition()
    local downX, downY = utils.normalize2(x, y)
    local angle = math.atan2(y, x) - 0.5 * math.pi
    local scale = self.camera.scale
    local offset = 0.125 / scale
    self.camera:setLocalToWorld(x - offset * downX, y - offset * downY, angle)
  end
end

return M
