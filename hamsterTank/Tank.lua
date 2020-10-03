local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")
local Wheel = require("hamsterTank.Wheel")

local M = Class.new()

function M:init(game, config)
  self.game = game
  self.groupIndex = self.game:generateGroupIndex()
  self.inputX = 0

  self.jumpInput = false
  self.previousJumpInput = false

  local x, y, angle = utils.decompose2(config.transform)

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)

  local shape = love.physics.newRectangleShape(3, 1.5)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setGroupIndex(-self.groupIndex)

  self.wheels = {}

  self.game.tanks[#self.game.tanks + 1] = self

  Wheel.new(self, {
    transform = config.transform * love.math.newTransform(-1.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = config.transform * love.math.newTransform(-0.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = config.transform * love.math.newTransform(0.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = config.transform * love.math.newTransform(1.5, 0.75),
    radius = 0.375,
  })
end

function M:destroy()
  for i = #self.wheels, 1, -1 do
    self.wheels[i]:destroy()
  end

  utils.removeLast(self.game.tanks, self)

  self.fixture:destroy()
  self.body:destroy()
end

function M:fixedUpdateControl(dt)
  if self.jumpInput and not self.previousJumpInput then
    local downX, downY = self.body:getWorldVector(0, 1)
    local jumpImpulse = 64

    for _, wheel in ipairs(self.wheels) do
      local wheelX, wheelY = wheel.body:getWorldCenter()
      wheel.body:applyLinearImpulse(downX * jumpImpulse, downY * jumpImpulse, wheelX, wheelY)
      self.body:applyLinearImpulse(-downX * jumpImpulse, -downY * jumpImpulse, wheelX, wheelY)
    end
  end

  for _, wheel in ipairs(self.wheels) do
    wheel.joint:setMotorSpeed(self.inputX * 64)
  end
end

return M