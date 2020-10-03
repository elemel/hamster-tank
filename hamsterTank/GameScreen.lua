local Class = require("hamsterTank.Class")
local Game = require("hamsterTank.Game")

local M = Class.new()

function M:init()
  self.game = Game.new()
end

function M:update(dt)
  self.game:update(dt)
end

function M:draw()
  self.game:draw()
end

function M:keypressed(key, scancode, isrepeat)
  if key == "escape" then
    local TitleScreen = require("hamsterTank.TitleScreen")
    screen = TitleScreen.new()
    return
  end
end

function M:resize(w, h)
  self.game:resize(w, h)
end

return M
