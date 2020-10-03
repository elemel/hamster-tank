local Class = require("hamsterTank.Class")
local Sprite = require("hamsterTank.Sprite")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(tank, config)
  self.tank = tank
  self.game = self.tank.game

  local localX, localY, localAngle = unpack(config.transform)
  local x, y = self.tank.body:getWorldPoint(localX, localY)
  local angle = localAngle + self.tank.body:getAngle()

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)

  local shape = love.physics.newCircleShape(config.radius)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setGroupIndex(-self.tank.groupIndex)

  local x1, y1 = self.tank.body:getWorldPoint(0, -0.75)
  local x2, y2 = self.body:getPosition()

  self.ropeJoint = love.physics.newRopeJoint(self.tank.body, self.body, x1, y1, x2, y2, 0.5)

  self.motorJoint = love.physics.newMotorJoint(self.tank.body, self.body)
  self.motorJoint:setLinearOffset(0, -0.75)
  self.motorJoint:setMaxForce(256)
  self.motorJoint:setMaxTorque(64)

  local image = self.game.resources.images.hamster.head
  local imageWidth, imageHeight = image:getDimensions()
  local scale = 1.5 / imageHeight

  self.sprite = Sprite.new(self.game, image, {
    localToWorld = {x, y, angle},
    imageToLocal = {0, 0, 0, scale, scale, 0.5 * imageWidth, 0.5 * imageHeight},
  })

  self.tank.turrets[#self.tank.turrets + 1] = self
end

function M:destroy()
  utils.removeLast(self.tank.turrets, self)

  self.sprite:destroy()
  self.sprite = nil

  self.ropeJoint:destroy()
  self.ropeJoint = nil

  self.motorJoint:destroy()
  self.motorJoint = nil

  self.fixture:destroy()
  self.fixture = nil

  self.body:destroy()
  self.body = nil
end

function M:fixedUpdateAnimation(dt)
  local x, y = self.body:getPosition()
  local angle = self.body:getAngle()
  self.sprite:setLocalToWorld(x, y, angle)
end

return M
