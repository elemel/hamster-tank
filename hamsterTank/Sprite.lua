local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, image, config)
  self.game = game
  self.image = image

  self.imageToLocal = love.math.newTransform(unpack(config.imageToLocal))
  self.localToWorld = love.math.newTransform(unpack(config.localToWorld))
  self.imageToWorld = self.localToWorld * self.imageToLocal

  self.previousImageToWorld = love.math.newTransform():apply(self.imageToWorld)
  self.interpolatedImageToWorld = love.math.newTransform():apply(self.imageToWorld)

  self.game.sprites[#self.game.sprites + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.sprites, self)
end

function M:updatePreviousImageToWorld()
  self.previousImageToWorld:reset():apply(self.imageToWorld)
end

function M:updateInterpolatedImageToWorld(t)
  utils.mixTransforms(
    self.previousImageToWorld, self.imageToWorld, t, self.interpolatedImageToWorld)
end

function M:setLocalToWorld(x, y, angle)
  self.localToWorld:setTransformation(x, y, angle)
  self.imageToWorld:reset():apply(self.localToWorld):apply(self.imageToLocal)
end

return M
