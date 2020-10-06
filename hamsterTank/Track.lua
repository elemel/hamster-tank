local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(wheel1, wheel2, config)
  self.wheel1 = wheel1
  self.wheel2 = wheel2
  self.tank = self.wheel1.tank
  self.game = self.tank.game

  local x1, y1 = self.wheel1.body:getPosition()
  local x2, y2 = self.wheel2.body:getPosition()

  self.joint = love.physics.newFrictionJoint(self.wheel1.body, self.wheel2.body, x1, y1, x2, y2)
  self.joint:setMaxTorque(config.maxTorque)

  self.tank.tracks[#self.tank.tracks + 1] = self
end

function M:destroy()
  utils.removeLast(self.tank.tracks, self)

  self.joint:destroy()
end

return M
