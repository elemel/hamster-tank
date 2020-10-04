local Class = require("hamsterTank.Class")

local M = Class.new()

function M:init()
  self.splash = love.graphics.newImage("resources/images/splash.png")
end

function M:update(dt)
end

function M:draw()
  local windowWidth, windowHeight = love.graphics.getDimensions()
  local splashWidth, splashHeight = self.splash:getDimensions()

  local x = 0.5 * windowWidth
  local y = 0.5 * windowHeight
  local scale = windowHeight / splashHeight

  love.graphics.draw(self.splash, x, y, 0, scale, scale, 0.5 * splashWidth, 0.5 * splashHeight)
end

function M:keypressed(key, scancode, isrepeat)
  if key == "return" then
    local GameScreen = require("hamsterTank.GameScreen")
    screen = GameScreen.new()
  elseif key == "escape" then
    love.event.quit()
  end
end

function M:resize(w, h)
end

function M:mousemoved(x, y, dx, dy, istouch)
end

function M:joystickadded(joystick)
end

function M:joystickremoved(joystick)
end

function M:gamepadpressed(joystick, button)
  if button == "a" then
    local GameScreen = require("hamsterTank.GameScreen")
    screen = GameScreen.new(joystick)
  elseif button == "b" then
    love.event.quit()
  end
end

return M
