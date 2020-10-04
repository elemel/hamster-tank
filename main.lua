local TitleScreen = require("hamsterTank.TitleScreen")

function love.load()
  love.window.setTitle("Hamster Tank")

  love.window.setMode(800, 600, {
    highdpi = true,
    fullscreen = true,
    msaa = 8,
    resizable = true,
  })

  love.physics.setMeter(1)
  love.graphics.setBackgroundColor(0.25, 0.75, 1, 1)

  -- Work-around for game hanging while the mouse is pressed in relative mode
  -- in LÖVE 11.3
  love.event.pump()

  love.mouse.setRelativeMode(true)

  screen = TitleScreen.new()

  local music = love.audio.newSource("resources/hamsterTank.ogg", "stream")
  music:setLooping(true)
  -- music:play()
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

function love.mousemoved(x, y, dx, dy, istouch)
  screen:mousemoved(x, y, dx, dy, istouch)
end
