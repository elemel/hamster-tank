local Class = require("hamsterTank.Class")

local M = Class.new()

function M:init(image, config)
  self.image = image
  self.imageToLocal = love.math.newTransform(unpack(config.imageToLocal))
  self.localToWorld = love.math.newTransform(unpack(config.localToWorld))
  self.imageToWorld = self.localToWorld * self.imageToLocal
end

function M:draw()
  love.graphics.draw(self.image, self.imageToWorld)
end

return M
