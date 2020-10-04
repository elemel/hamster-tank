local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game)
  self.game = game

  self.x = 0
  self.y = 0

  self.angle = 0
  self.scale = 1

  self.viewportX = 0
  self.viewportY = 0

  self.viewportWidth = 1
  self.viewportHeight = 1

  self.localToWorld = love.math.newTransform()
  self.worldToLocal = love.math.newTransform()

  self.localToScreen = love.math.newTransform()

  self.worldToScreen = love.math.newTransform()

  self:setLocalToWorld(0, 0, 0)
  self:setScale(1 / 32)
  self:setViewport(0, 0, 800, 600)

  self.previousWorldToScreen = love.math.newTransform():apply(self.worldToScreen)
  self.interpolatedWorldToScreen = love.math.newTransform():apply(self.worldToScreen)

  self.fade = 0.5

  self.game.cameras[#self.game.cameras + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.cameras, self)
end

function M:setLocalToWorld(x, y, angle)
  self.x = x
  self.y = y

  self.angle = angle

  self.localToWorld:setTransformation(x, y, angle)
  self.worldToLocal:reset():rotate(-angle):translate(-x, -y)

  self.worldToScreen:reset():apply(self.localToScreen):scale(self.scale):apply(self.worldToLocal)
end

function M:setScale(scale)
  self.scale = scale
  self.worldToScreen:reset():apply(self.localToScreen):scale(self.scale):apply(self.worldToLocal)
end

function M:setViewport(x, y, width, height)
  self.viewportX = x
  self.viewportY = y

  self.viewportWidth = width
  self.viewportHeight = height

  local x = self.viewportX + 0.5 * self.viewportWidth
  local y = self.viewportY + 0.5 * self.viewportHeight

  local scale = self.viewportHeight
  self.localToScreen:setTransformation(x, y, 0, scale)

  self.worldToScreen:reset():apply(self.localToScreen):scale(self.scale):apply(self.worldToLocal)
end

function M:fixedUpdateInterpolation(dt)
  self.previousWorldToScreen:reset():apply(self.worldToScreen)
end

function M:updateInterpolation(dt)
  local t = self.game.accumulatedDt / self.game.fixedDt

  utils.mixTransforms(
    self.previousWorldToScreen, self.worldToScreen, t, self.interpolatedWorldToScreen)
end

return M
