local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, config)
  self.game = game

  local noiseOriginX = config.noise.originX
  local noiseOriginY = config.noise.originY

  local pointCount = 1024
  local points = {}

  for i = 1, pointCount do
    local fraction = (i - 1) / pointCount
    local angle = fraction * 2 * math.pi

    local directionX = math.cos(angle)
    local directionY = math.sin(angle)

    local x = directionX * config.radius
    local y = directionY * config.radius

    local noiseFrequency = config.noise.frequency
    local noiseAmplitude = config.noise.amplitude

    local noiseValue = 0

    for noiseOctave = 1, 3 do
      noiseValue = noiseValue + noiseAmplitude * love.math.noise(
        noiseOriginX + noiseFrequency * x, noiseOriginY + noiseFrequency * y)

      noiseAmplitude = 0.5 * noiseAmplitude
      noiseFrequency = 2 * noiseFrequency
    end

    x = x + directionX * noiseValue
    y = y + directionY * noiseValue

    points[#points + 1] = x
    points[#points + 1] = y
  end

  if not config.background then
    self.body = love.physics.newBody(self.game.world)
    local shape = love.physics.newChainShape(true, points)

    self.fixture = love.physics.newFixture(self.body, shape)
    self.fixture:setFriction(1)
  end

  local r, g, b, a = unpack(config.color)
  local vertices = {}

  for i = 1, #points, 2 do
    local x = points[i]
    local y = points[i + 1]

    local directionX, directionY = utils.normalize2(x, y)

    vertices[#vertices + 1] = {x, y, 0, 0, r, g, b, a}
    vertices[#vertices + 1] = {directionX * 256, directionY * 256, 0, 0, r, g, b, a}
  end

  vertices[#vertices + 1] = vertices[1]
  vertices[#vertices + 1] = vertices[2]

  self.mesh = love.graphics.newMesh(vertices, "strip")
  self.game.terrains[#self.game.terrains + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.terrains, self)

  self.mesh:release()
  self.mesh = nil

  if self.fixture then
    self.fixture:destroy()
    self.fixture = nil
  end

  if self.body then
    self.body:destroy()
    self.body = nil
  end
end

return M
