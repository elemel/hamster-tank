local Class = require("hamsterTank.Class")
local Game = require("hamsterTank.Game")

local M = Class.new()

function M:init(joystick)
  local resources = {
    images = {
      hamster = {
        head = love.graphics.newImage("resources/images/hamster/head.png"),
        paw = love.graphics.newImage("resources/images/hamster/paw.png"),
        trunk = love.graphics.newImage("resources/images/hamster/trunk.png"),
      },

      particles = {
        fire = love.graphics.newImage("resources/images/particles/fire.png"),
        smoke = love.graphics.newImage("resources/images/particles/smoke.png"),
      },
    },

    sounds = {
      fire = love.audio.newSource("resources/sounds/fire.ogg", "static"),
      fireballTankCollision = love.audio.newSource("resources/sounds/fireballTankCollision.ogg", "static"),
      fireballTerrainCollision = love.audio.newSource("resources/sounds/fireballTerrainCollision.ogg", "static"),
    },
  }

  self.game = Game.new(resources, joystick)
end

function M:update(dt)
  self.game:update(dt)
end

function M:draw()
  self.game:draw()
end

function M:keypressed(key, scancode, isrepeat)
  self.game:keypressed(key, scancode, isrepeat)
end

function M:resize(w, h)
  self.game:resize(w, h)
end

function M:mousemoved(x, y, dx, dy, istouch)
  self.game:mousemoved(x, y, dx, dy, istouch)
end

function M:joystickadded(joystick)
  self.game:joystickadded(joystick)
end

function M:joystickremoved(joystick)
  self.game:joystickremoved(joystick)
end

function M:gamepadpressed(joystick, button)
  self.game:gamepadpressed(joystick, button)
end

return M
