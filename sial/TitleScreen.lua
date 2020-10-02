local Class = require("sial.Class")

local M = Class.new()

function M:init()
  self.splash = love.graphics.newImage("resources/images/splash.png")
end

function M:update(dt)
end

function M:draw()
  love.graphics.draw(self.splash)
end

function M:keypressed(key, scancode, isrepeat)
  if key == "return" then
    local GameScreen = require("sial.GameScreen")
    screen = GameScreen.new()
    return
  end
end

return M
