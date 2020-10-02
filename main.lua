local TitleScreen = require("game.TitleScreen")

function love.load()
  screen = TitleScreen.new()
end

function love.draw()
  screen:draw()
end
