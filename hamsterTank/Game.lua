local Camera = require("hamsterTank.Camera")
local Class = require("hamsterTank.Class")
local GamepadControls = require("hamsterTank.GamepadControls")
local KeyboardMouseControls = require("hamsterTank.KeyboardMouseControls")
local Player = require("hamsterTank.Player")
local Tank = require("hamsterTank.Tank")
local Terrain = require("hamsterTank.Terrain")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(resources, joystick)
  self.resources = resources

  self.font = love.graphics.newFont(24)

  self.fixedDt = 1 / 60
  self.accumulatedDt = 0

  self.keyboardMouseControls = KeyboardMouseControls.new({})
  self.cameras = {}

  self.world = love.physics.newWorld()
  self.collisions = {}

  self.collisionHandlers = {
    fireball = {
      tank = self.handleFireballTankCollision,
      terrain = self.handleFireballTerrainCollision,
    },
  }

  local function beginContact(fixture1, fixture2, contact)
    local userData1 = fixture1:getUserData()
    local userData2 = fixture2:getUserData()

    if not userData1 or not userData2 then
      return
    end

    self.collisions[#self.collisions + 1] = userData1
    self.collisions[#self.collisions + 1] = userData2
  end

  self.world:setCallbacks(beginContact, nil, nil, nil)

  self.nextGroupIndex = 1
  self.nextPlayerIndex = 1
  self.nextGamepadIndex = 1

  self.fireballs = {}
  self.players = {}
  self.sprites = {}
  self.tanks = {}
  self.terrains = {}

  self.gamepadPlayers = {}

  self.wheelRadius = 32
  self.wheelGravity = 32

  Terrain.new(self, {
    radius = 0.875 * 0.875 * self.wheelRadius,
    background = true,
    color = {0.25, 0.5, 0.75, 1},

    noise = {
      originX = love.math.random() * 256,
      originY = love.math.random() * 256,

      amplitude = 0.875 * 8,
      frequency = 1 / 0.875 / 0.875 * 1 / 32,
    },
  })

  Terrain.new(self, {
    radius = 0.875 * self.wheelRadius,
    background = true,
    color = {0.25, 0.375, 0.5, 1},

    noise = {
      originX = love.math.random() * 256,
      originY = love.math.random() * 256,

      amplitude = 0.875 * 8,
      frequency = 1 / 0.875 * 1 / 32,
    },
  })

  Terrain.new(self, {
    radius = self.wheelRadius,
    color = {0.625, 0.625, 0.375, 1},

    noise = {
      originX = love.math.random() * 256,
      originY = love.math.random() * 256,

      amplitude = 8,
      frequency = 1 / 32,
    },
  })

  local controls

  if joystick then
    local camera = Camera.new(self)
    local controls = GamepadControls.new(joystick)

    self.gamepadPlayers[joystick] = Player.new(self, camera, controls, {
      name = "Player #" .. self:generatePlayerIndex(),
      controlsDescription = "Gamepad #" .. self:generateGamepadIndex(),
    })
  else
    local camera = Camera.new(self)
    local controls = self.keyboardMouseControls

    self.keyboardMousePlayer = Player.new(self, camera, controls, {
      name = "Player #" .. self:generatePlayerIndex(),
      controlsDescription = "Keyboard & Mouse",
    })
  end

  self:resize(love.graphics.getDimensions())
end

function M:update(dt)
  self.accumulatedDt = self.accumulatedDt + dt

  while self.accumulatedDt >= self.fixedDt do
    self.accumulatedDt = self.accumulatedDt - self.fixedDt
    self:fixedUpdate(self.fixedDt)
  end

  for _, camera in ipairs(self.cameras) do
    camera:updateInterpolation(dt)
  end

  for _, sprite in ipairs(self.sprites) do
    sprite:updateInterpolation(dt)
  end

  for _, fireball in ipairs(self.fireballs) do
    fireball:updateParticles(dt)
  end
end

function M:fixedUpdate(dt)
  for _, camera in ipairs(self.cameras) do
    camera:fixedUpdateInterpolation(dt)
  end

  for _, sprite in ipairs(self.sprites) do
    sprite:fixedUpdateInterpolation(dt)
  end

  for _, player in ipairs(self.players) do
    player:fixedUpdateSpawn(dt)
  end

  for _, player in ipairs(self.players) do
    player:fixedUpdateInput(dt)
  end

  for _, tank in ipairs(self.tanks) do
    tank:fixedUpdateControl(dt)
  end

  -- Apply wheel gravity
  for _, body in ipairs(self.world:getBodies()) do
    if body:getType() == "dynamic" then
      local x, y = body:getWorldCenter()
      local downX, downY, distance = utils.normalize2(x, y)

      if distance > 0 then
        local mass = body:getMass()
        local gravity = self.wheelGravity * distance / self.wheelRadius
        body:applyForce(downX * mass * gravity, downY * mass * gravity)
      end
    end
  end

  self.world:update(dt)

  for i = 1, #self.collisions, 2 do
    local userData1 = self.collisions[i]
    local userData2 = self.collisions[i + 1]

    local collisionType1 = userData1.collisionType
    local collisionType2 = userData2.collisionType

    local collisionHandler1 = self.collisionHandlers[collisionType1] and
      self.collisionHandlers[collisionType1][collisionType2]

    local collisionHandler2 = self.collisionHandlers[collisionType2] and
      self.collisionHandlers[collisionType2][collisionType1]

    if collisionHandler1 then
      collisionHandler1(self, userData1, userData2)
    elseif collisionHandler2 then
      collisionHandler2(self, userData2, userData1)
    end
  end

  while #self.collisions >= 1 do
    self.collisions[#self.collisions] = nil
  end

  for _, tank in ipairs(self.tanks) do
    tank:fixedUpdateAnimation(dt)
  end

  for _, fireball in ipairs(self.fireballs) do
    fireball:fixedUpdateParticles(dt)
  end

  for _, player in ipairs(self.players) do
    player:fixedUpdateCamera(dt)
  end

  for i = #self.tanks, 1, -1 do
    self.tanks[i]:fixedUpdateDespawn(dt)
  end

  for i = #self.fireballs, 1, -1 do
    self.fireballs[i]:fixedUpdateDespawn(dt)
  end
end

function M:draw()
  for _, camera in ipairs(self.cameras) do
    love.graphics.push("all")

    love.graphics.setScissor(
      camera.viewportX, camera.viewportY, camera.viewportWidth, camera.viewportHeight)

    love.graphics.clear(0.25, 0.75, 1, 1)

    love.graphics.replaceTransform(camera.interpolatedWorldToScreen)
    local _, _, _, scale = utils.decompose2(camera.interpolatedWorldToScreen)
    love.graphics.setLineWidth(1 / scale)

    for _, terrain in ipairs(self.terrains) do
      love.graphics.draw(terrain.mesh)
    end

    for _, sprite in ipairs(self.sprites) do
      love.graphics.draw(sprite.image, sprite.interpolatedImageToWorld)
    end

    love.graphics.push("all")

    for _, fireball in ipairs(self.fireballs) do
      love.graphics.setBlendMode("alpha")
      love.graphics.draw(fireball.smokeParticles)

      love.graphics.setBlendMode("add")
      love.graphics.draw(fireball.fireParticles)
    end

    love.graphics.pop()
    love.graphics.pop()
    love.graphics.push("all")

    love.graphics.setScissor(
      camera.viewportX, camera.viewportY, camera.viewportWidth, camera.viewportHeight)

    love.graphics.replaceTransform(camera.worldToScreen)
    local _, _, _, scale = utils.decompose2(camera.worldToScreen)
    love.graphics.setLineWidth(1 / scale)
    -- self:debugDrawPhysics()

    love.graphics.pop()

    if camera.fade > 0 then
      love.graphics.push("all")
      love.graphics.setColor(0, 0, 0, camera.fade)

      love.graphics.rectangle("fill",
        camera.viewportX, camera.viewportY,
        camera.viewportWidth, camera.viewportHeight)

      love.graphics.pop()
    end

    local marginX = 0.5 * self.font:getHeight()
    local marginY = 0.25 * self.font:getHeight()

    for _, player in ipairs(self.players) do
      if player.camera == camera then
        love.graphics.draw(
          player.nameText,
          camera.viewportX + marginX,
          camera.viewportY + marginY)

        love.graphics.draw(
          player.controlsDescriptionText,
          camera.viewportX + camera.viewportWidth - player.controlsDescriptionText:getWidth() - marginX,
          camera.viewportY + marginY)

        love.graphics.draw(
          player.killCountText,
          camera.viewportX + marginX,
          camera.viewportY + camera.viewportHeight - player.killCountText:getHeight() - marginY)

        love.graphics.draw(
          player.deathCountText,
          camera.viewportX + camera.viewportWidth - player.deathCountText:getWidth() - marginX,
          camera.viewportY + camera.viewportHeight - player.deathCountText:getHeight() - marginY)
      end
    end

    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", camera.viewportX, camera.viewportY, camera.viewportWidth, camera.viewportHeight)

    love.graphics.pop()
  end
end

function M:debugDrawPhysics()
  love.graphics.push("all")
  love.graphics.setColor(0, 1, 0, 1)

  for _, body in ipairs(self.world:getBodies()) do
    local angle = body:getAngle()

    for _, fixture in ipairs(body:getFixtures()) do
      local shape = fixture:getShape()
      local shapeType = shape:getType()

      if shapeType == "chain" then
        love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))

        local vertexCount = shape:getVertexCount()

        local previousX, previousY = body:getWorldPoint(shape:getPreviousVertex())
        local firstX, firstY = body:getWorldPoint(shape:getPoint(1))

        local lastX, lastY = body:getWorldPoint(shape:getPoint(vertexCount))
        local nextX, nextY = body:getWorldPoint(shape:getNextVertex())

        love.graphics.line(previousX, previousY, firstX, firstY)
        love.graphics.line(lastX, lastY, nextX, nextY)
      elseif shapeType == "circle" then
        local x, y = body:getWorldPoint(shape:getPoint())
        local radius = shape:getRadius()
        love.graphics.circle("line", x, y, radius)
        local directionX, directionY = body:getWorldVector(1, 0)
        love.graphics.line(x, y, x + directionX * radius, y + directionY * radius)
      elseif shapeType == "polygon" then
        love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
      end
    end
  end

  love.graphics.pop()
end

function M:resize(w, h)
  self:updateLayout()
end

function M:generateGroupIndex()
  local result = self.nextGroupIndex
  self.nextGroupIndex = self.nextGroupIndex + 1
  return result
end

function M:generatePlayerIndex()
  local result = self.nextPlayerIndex
  self.nextPlayerIndex = self.nextPlayerIndex + 1
  return result
end

function M:generateGamepadIndex()
  local result = self.nextGamepadIndex
  self.nextGamepadIndex = self.nextGamepadIndex + 1
  return result
end

function M:updateLayout()
  local width, height = love.graphics.getDimensions()
  local scale = 1 / 24

  if #self.cameras == 1 then
    self.cameras[1]:setViewport(0, 0, width, height)
    self.cameras[1]:setScale(scale)
  elseif #self.cameras == 2 then
    self.cameras[1]:setViewport(0, 0, width, 0.5 * height)
    self.cameras[1]:setScale(scale)

    self.cameras[2]:setViewport(0, 0.5 * height, width, 0.5 * height)
    self.cameras[2]:setScale(scale)
  elseif #self.cameras == 3 then
    self.cameras[1]:setViewport(0.25 * width, 0, 0.5 * width, 0.5 * height)
    self.cameras[1]:setScale(scale)

    self.cameras[2]:setViewport(0, 0.5 * height, 0.5 * width, 0.5 * height)
    self.cameras[2]:setScale(scale)

    self.cameras[3]:setViewport(0.5 * width, 0.5 * height, 0.5 * width, 0.5 * height)
    self.cameras[3]:setScale(scale)
  elseif #self.cameras == 4 then
    self.cameras[1]:setViewport(0, 0, 0.5 * width, 0.5 * height)
    self.cameras[1]:setScale(scale)

    self.cameras[2]:setViewport(0.5 * width, 0, 0.5 * width, 0.5 * height)
    self.cameras[2]:setScale(scale)

    self.cameras[3]:setViewport(0, 0.5 * height, 0.5 * width, 0.5 * height)
    self.cameras[3]:setScale(scale)

    self.cameras[4]:setViewport(0.5 * width, 0.5 * height, 0.5 * width, 0.5 * height)
    self.cameras[4]:setScale(scale)
  end
end

function M:mousemoved(x, y, dx, dy, istouch)
  self.keyboardMouseControls:mousemoved(x, y, dx, dy, istouch)
end

function M:handleFireballTerrainCollision(fireballData, terrainData)
  local fireball = fireballData.fireball

  if not fireball.dead then
    fireball:setDead(true)
    self.resources.sounds.fireballTerrainCollision:clone():play()
  end
end

function M:handleFireballTankCollision(fireballData, tankData)
  local fireball = fireballData.fireball
  local tank = tankData.tank

  if not fireball.dead and not tank.dead then
    fireball:setDead(true)
    tank:setDead(true)

    for _, player in ipairs(self.players) do
      if player.tank == tank then
        player:incrementDeathCount()
      end

      if player.tank and player.tank.groupIndex == -fireball.fixture:getGroupIndex() then
        player:incrementKillCount()
      end
    end

    self.resources.sounds.fireballTankCollision:clone():play()
  end
end

function M:joystickadded(joystick)
  if joystick:isGamepad() and #self.players < 4 then
    local camera = Camera.new(self)
    local controls = GamepadControls.new(joystick)

    self.gamepadPlayers[joystick] = Player.new(self, camera, controls, {
      name = "Player #" .. self:generatePlayerIndex(),
      controlsDescription = "Gamepad #" .. self:generateGamepadIndex(),
    })

    self:updateLayout()
  end
end

function M:joystickremoved(joystick)
  if self.gamepadPlayers[joystick] then
    self.gamepadPlayers[joystick]:destroy()
    self.gamepadPlayers[joystick] = nil

    if #self.players == 0 then
      local TitleScreen = require("hamsterTank.TitleScreen")
      screen = TitleScreen.new()
    else
      self:updateLayout()
    end
  end
end

function M:keypressed(key, scancode, isrepeat)
  if key == "return" and not self.keyboardMousePlayer and #self.players < 4 then
    local camera = Camera.new(self)
    local controls = self.keyboardMouseControls

    self.keyboardMousePlayer = Player.new(self, camera, controls, {
      name = "Player #" .. self:generatePlayerIndex(),
      controlsDescription = "Keyboard & Mouse",
    })

    self:updateLayout()
  elseif key == "escape" then
    if self.keyboardMousePlayer then
      self.keyboardMousePlayer:destroy()
      self.keyboardMousePlayer = nil

      if #self.players == 0 then
        local TitleScreen = require("hamsterTank.TitleScreen")
        screen = TitleScreen.new()
      else
        self:updateLayout()
      end
    else
      local TitleScreen = require("hamsterTank.TitleScreen")
      screen = TitleScreen.new()
    end
  end
end

function M:gamepadpressed(joystick, button)
  if button == "a" and not self.gamepadPlayers[joystick] and #self.players < 4 then
    local camera = Camera.new(self)
    local controls = GamepadControls.new(joystick)

    self.gamepadPlayers[joystick] = Player.new(self, camera, controls, {
      name = "Player #" .. self:generatePlayerIndex(),
      controlsDescription = "Gamepad #" .. self:generateGamepadIndex(),
    })

    self:updateLayout()
  elseif button == "b" and self.gamepadPlayers[joystick] then
    self.gamepadPlayers[joystick]:destroy()
    self.gamepadPlayers[joystick] = nil

    if #self.players == 0 then
      local TitleScreen = require("hamsterTank.TitleScreen")
      screen = TitleScreen.new()
    else
      self:updateLayout()
    end
  end
end

return M
