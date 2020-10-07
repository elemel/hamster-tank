local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game)
  self.game = game

  self.jumpSeed = love.math.random() * 1024
  self.fireSeed = love.math.random() * 1024

  self.moveXNoiseSeed = love.math.random() * 1024
  self.moveYNoiseSeed = love.math.random() * 1024

  self.aimXNoiseSeed = love.math.random() * 1024
  self.aimYNoiseSeed = love.math.random() * 1024
end

function M:getJumpInput()
  local frequency = 0.125
  return self:generateNoise(frequency * (self.jumpSeed + self.game.fixedTime)) > 0.5
end

function M:getFireInput()
  local frequency = 0.125
  return self:generateNoise(frequency * (self.fireSeed + self.game.fixedTime)) > 0.5
end

function M:getSpawnInput()
  return false
end

function M:getRespawnInput()
  return false
end

function M:getDespawnInput()
  return false
end

function M:getMoveInput()
  local frequency = 0.25

  return self:generateStickInput(
    frequency * (self.moveXNoiseSeed + self.game.fixedTime),
    frequency * (self.moveYNoiseSeed + self.game.fixedTime))
end

function M:getAimInput()
  local frequency = 1

  return self:generateStickInput(
    frequency * (self.moveXNoiseSeed + self.game.fixedTime),
    frequency * (self.moveYNoiseSeed + self.game.fixedTime))
end

function M:generateNoise(seed)
  local result = 0

  local frequency = 1
  local amplitude = 1
  local maxAmplitude = 0

  for octave = 1, 3 do
    result = result + amplitude * love.math.noise(frequency * seed)
    maxAmplitude = maxAmplitude + amplitude

    frequency = 2 * frequency
    amplitude = 0.5 * amplitude
  end

  return result / maxAmplitude
end

function M:generateStickInput(seedX, seedY)
  local amplitude = 2

  local x = amplitude * (2 * self:generateNoise(seedX) - 1)
  local y = amplitude * (2 * self:generateNoise(seedY) - 1)

  local length = utils.length2(x, y)

  if length > 1 then
    x = x / length
    y = y / length
  end

  return x, y
end

return M
