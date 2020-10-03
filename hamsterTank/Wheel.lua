local Class = require("hamsterTank.Class")
local Sprite = require("hamsterTank.Sprite")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(tank, config)
  self.tank = tank
  self.game = self.tank.game

  local x, y, angle = utils.decompose2(config.transform)

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)

  local shape = love.physics.newCircleShape(config.radius)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setGroupIndex(-self.tank.groupIndex)
  self.fixture:setFriction(2)

  local axisX, axisY = self.body:getWorldVector(0, -1)
  self.joint = love.physics.newWheelJoint(self.tank.body, self.body, x, y, axisX, axisY)

  self.joint:setSpringFrequency(8)
  self.joint:setSpringDampingRatio(1)

  self.joint:setMotorEnabled(true)
  self.joint:setMaxMotorTorque(32)

  local image = love.graphics.newImage("resources/images/hamster/paw.png")
  local imageWidth, imageHeight = image:getDimensions()
  local scale = 1.125 / imageHeight

  self.sprite = Sprite.new(self.game, image, {
    localToWorld = {x, y, angle},
    imageToLocal = {0, 0, 0, scale, scale, 0.5 * imageWidth, 0.5 * imageHeight},
  })

  self.tank.wheels[#self.tank.wheels + 1] = self
end

function M:destroy()
  utils.removeLast(self.tank.wheels, self)
  self.sprite:destroy()

  self.joint:destroy()
  self.fixture:destroy()
  self.body:destroy()
end

function M:fixedUpdateAnimation(dt)
  local x, y = self.body:getPosition()
  local angle = self.body:getAngle()
  self.sprite:setLocalToWorld(x, y, angle)
end

return M
