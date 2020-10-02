local Class = require("sial.Class")
local Game = require("sial.Game")

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
    local TitleScreen = require("sial.TitleScreen")
    screen = TitleScreen.new()
    return
  end
end

return M
