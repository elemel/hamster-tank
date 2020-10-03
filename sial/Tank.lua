local Class = require("sial.Class")
local utils = require("sial.utils")
local Wheel = require("sial.Wheel")

local M = Class.new()

function M:init(game, config)
  self.game = game
  self.groupIndex = self.game:generateGroupIndex()
  self.inputX = 0

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
  for _, wheel in ipairs(self.wheels) do
    wheel.joint:setMotorSpeed(self.inputX * 16)
  end
end

return M
