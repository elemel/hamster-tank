local Class = require("sial.Class")
local utils = require("sial.utils")

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
  self.fixture:setFriction(1)

  local axisX, axisY = utils.transformVector(config.transform, 0, -1)
  self.joint = love.physics.newWheelJoint(self.tank.body, self.body, x, y, axisX, axisY)

  self.joint:setSpringFrequency(8)
  self.joint:setSpringDampingRatio(1)

  self.joint:setMotorEnabled(true)
  self.joint:setMaxMotorTorque(16)

  self.tank.wheels[#self.tank.wheels + 1] = self
end

function M:destroy()
  utils.removeLast(self.tank.wheels, self)

  self.joint:destroy()
  self.fixture:destroy()
  self.body:destroy()
end

return M
