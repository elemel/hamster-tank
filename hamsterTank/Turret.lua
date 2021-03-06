local Class = require("hamsterTank.Class")
local Fireball = require("hamsterTank.Fireball")
local Sprite = require("hamsterTank.Sprite")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(tank, config)
  self.tank = tank
  self.game = self.tank.game

  self.minMuzzleVelocity = config.minMuzzleVelocity
  self.maxMuzzleVelocity = config.maxMuzzleVelocity

  local localX, localY, localAngle = unpack(config.transform)
  local x, y = self.tank.body:getWorldPoint(localX, localY)
  local angle = localAngle + self.tank.body:getAngle()

  self.localX = localX
  self.localY = localY

  self.maxDistance = config.maxDistance

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)

  local shape = love.physics.newCircleShape(config.radius)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setGroupIndex(-self.tank.groupIndex)

  self.fixture:setUserData({
    collisionType = "tank",
    tank = self.tank,
  })

  local x2, y2 = self.body:getPosition()

  self.ropeJoint = love.physics.newRopeJoint(self.tank.body, self.body, x, y, x, y, self.maxDistance)

  self.distanceJoints = {}

  for _, localAnchor in ipairs({{-0.75, 0}, {0, 0}, {0.75, 0}}) do
    local anchorX, anchorY = self.tank.body:getWorldPoint(unpack(localAnchor))
    local joint = love.physics.newDistanceJoint(self.tank.body, self.body, anchorX, anchorY, x, y)

    joint:setFrequency(4)
    joint:setDampingRatio(1)

    self.distanceJoints[#self.distanceJoints + 1] = joint
  end

  local image = self.game.resources.images.hamster.head
  local imageWidth, imageHeight = image:getDimensions()
  local scale = 1.5 / imageHeight

  self.sprite = Sprite.new(self.game, image, {
    localToWorld = {x, y, angle},
    imageToLocal = {0, 0, 0, scale, scale, 0.5 * imageWidth, 0.5 * imageHeight},
  })

  self.cooldown = 0

  self.tank.turrets[#self.tank.turrets + 1] = self
end

function M:destroy()
  utils.removeLast(self.tank.turrets, self)

  self.sprite:destroy()
  self.sprite = nil

  for i = #self.distanceJoints, 1, -1 do
    self.distanceJoints[i]:destroy()
    self.distanceJoints[i] = nil
  end

  self.ropeJoint:destroy()
  self.ropeJoint = nil

  self.fixture:destroy()
  self.fixture = nil

  self.body:destroy()
  self.body = nil
end

function M:fixedUpdateControl(dt)
  self.cooldown = self.cooldown - dt

  local x, y = self.body:getPosition()
  local angle = self.body:getAngle()

  local upX, upY = utils.normalize2(-x, -y)
  local rightAngle = math.atan2(upY, upX) + 0.5 * math.pi

  local worldAimInputX, worldAimInputY = utils.rotate2(
    self.tank.aimInputX, self.tank.aimInputY, rightAngle)

  for _, joint in ipairs(self.distanceJoints) do
    local x1, y1, x2, y2 = joint:getAnchors()

    local targetX, targetY = self.tank.body:getWorldPoint(self.localX, self.localY)

    targetX = targetX + worldAimInputX * self.maxDistance
    targetY = targetY + worldAimInputY * self.maxDistance

    local length = utils.distance2(x1, y1, targetX, targetY)

    joint:setLength(length)
  end

  if self.tank.fireInput and not self.tank.previousFireInput then
    if self.cooldown < 0 then
      self.cooldown = 0.5

      local linearVelocityX, linearVelocityY = self.body:getLinearVelocity()

      local fireball = Fireball.new(self.tank, {
        transform = {x, y, angle},

        linearVelocityX = linearVelocityX,
        linearVelocityY = linearVelocityY,
      })

      self.game.resources.sounds.fire:clone():play()

      local fireDirectionX = utils.clamp(self.tank.aimInputX, -1, 1)
      local fireDirectionY = -math.sqrt(1 - fireDirectionX * fireDirectionX)

      local worldFireDirectionX, worldFireDirectionY = utils.rotate2(
        fireDirectionX, fireDirectionY, rightAngle)

      local t = utils.clamp(0.5 - 0.5 * self.tank.aimInputY, 0, 1)
      local muzzleVelocity = utils.mix(self.minMuzzleVelocity, self.maxMuzzleVelocity, t)
      local impulse = muzzleVelocity * fireball.body:getMass()

      fireball.body:applyLinearImpulse(impulse * worldFireDirectionX, impulse * worldFireDirectionY)
      self.body:applyLinearImpulse(-impulse * worldFireDirectionX, -impulse * worldFireDirectionY)
    else
      self.game.resources.sounds.cooldown:clone():play()
    end
  end
end

function M:fixedUpdateAnimation(dt)
  local x, y = self.body:getPosition()
  local localX, localY = self.tank.body:getLocalPoint(x, y)
  local angle = math.atan2(localY, localX) + 0.5 * math.pi + self.tank.body:getAngle()
  self.sprite:setLocalToWorld(x, y, angle)
end

return M
