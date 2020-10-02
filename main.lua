local TitleScreen = require("sial.TitleScreen")

function love.load()
  love.window.setTitle("Stuck in a Loop")
  screen = TitleScreen.new()
end

function love.update(dt)
  screen:update(dt)
end

function love.draw()
  screen:draw()
end

function love.keypressed(key, scancode, isrepeat)
  screen:keypressed(key, scancode, isrepeat)
end
