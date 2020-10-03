local Class = require("sial.Class")
local utils = require("sial.utils")

local M = Class.new()

function M:init(game, config)
  self.game = game

  local x, y, angle = utils.decompose2(config.transform)

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)
  self.body:setAngularVelocity(1)

  local shape = love.physics.newRectangleShape(2, 1)
  self.fixture = love.physics.newFixture(self.body, shape)

  self.game.tanks[#self.game.tanks + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.tanks, self)

  self.fixture:destroy()
  self.body:destroy()
end

return M
