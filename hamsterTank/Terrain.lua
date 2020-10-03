local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, config)
  self.game = game
  self.body = love.physics.newBody(self.game.world)

  local pointCount = 256
  local points = {}

  for i = 1, pointCount do
    local fraction = (i - 1) / pointCount
    local angle = fraction * 2 * math.pi

    local directionX = math.cos(angle)
    local directionY = math.sin(angle)

    local x = directionX * config.radius
    local y = directionY * config.radius

    local noiseFrequency = 1 / 16
    local noiseAmplitude = 4

    local noiseValue = 0

    for noiseOctave = 1, 3 do
      noiseValue = noiseValue + noiseAmplitude * love.math.noise(noiseFrequency * x, noiseFrequency * y)

      noiseAmplitude = 0.5 * noiseAmplitude
      noiseFrequency = 2 * noiseFrequency
    end

    x = x + directionX * noiseValue
    y = y + directionY * noiseValue

    points[#points + 1] = x
    points[#points + 1] = y
  end

  local shape = love.physics.newChainShape(true, points)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setFriction(1)

  self.game.terrains[#self.game.terrains + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.terrains, self)

  self.fixture:destroy()
  self.body:destroy()
end

return M
