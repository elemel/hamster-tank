local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(game, tank, config)
  self.game = game
  self.tank = tank

  self.leftKey = config.leftKey or "a"
  self.rightKey = config.rightKey or "d"

  self.jumpKey = config.jumpKey or "space"
  self.game.players[#self.game.players + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.players, self)
end

function M:fixedUpdateInput(dt)
  local leftInput = love.keyboard.isDown(self.leftKey)
  local rightInput = love.keyboard.isDown(self.rightKey)

  self.tank.inputX = (rightInput and 1 or 0) - (leftInput and 1 or 0)

  self.tank.previousJumpInput = self.tank.jumpInput
  self.tank.jumpInput = love.keyboard.isDown(self.jumpKey)
end

return M
