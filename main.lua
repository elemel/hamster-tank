local TitleScreen = require("sial.TitleScreen")

function love.load()
  love.window.setTitle("Stuck in a Loop")

  love.window.setMode(800, 600, {
    resizable = true,
  })

  love.physics.setMeter(1)
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

function love.resize(w, h)
  screen:resize(w, h)
end
