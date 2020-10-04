local Camera = require("hamsterTank.Camera")
local Class = require("hamsterTank.Class")
local Player = require("hamsterTank.Player")
local Tank = require("hamsterTank.Tank")
local Terrain = require("hamsterTank.Terrain")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(resources)
  self.resources = resources

  self.fixedDt = 1 / 60
  self.accumulatedDt = 0

  self.accumulatedMouseDx = 0
  self.accumulatedMouseDy = 0

  self.cameras = {}

  self.world = love.physics.newWorld()
  self.nextGroupIndex = 1

  self.fireballs = {}
  self.players = {}
  self.sprites = {}
  self.tanks = {}
  self.terrains = {}

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

  for i = 1, 1 do
    local camera = Camera.new(self)

    if i == 1 then
      Player.new(self, camera, {})
    else
      Player.new(self, camera, {
        leftKey = "left",
        rightKey = "right",
        jumpKey = "up",
      })
    end
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
    love.graphics.setBlendMode("add")

    for _, fireball in ipairs(self.fireballs) do
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
  self.accumulatedMouseDx = self.accumulatedMouseDx + dx
  self.accumulatedMouseDy = self.accumulatedMouseDy + dy
end

return M
