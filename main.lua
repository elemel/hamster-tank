local TitleScreen = require("hamsterTank.TitleScreen")

function love.load()
  love.window.setTitle("Hamster Tank")

  love.window.setMode(800, 600, {
    highdpi = true,
    msaa = 8,
    resizable = true,
  })

  love.physics.setMeter(1)
  love.graphics.setBackgroundColor(0.25, 0.75, 1, 1)
  screen = TitleScreen.new()

  local music = love.audio.newSource("resources/hamsterTank.ogg", "stream")
  music:setLooping(true)
  music:play()
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
