local Camera = require("hamsterTank.Camera")
local Class = require("hamsterTank.Class")
local Player = require("hamsterTank.Player")
local Tank = require("hamsterTank.Tank")
local Terrain = require("hamsterTank.Terrain")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init()
  self.fixedDt = 1 / 60
  self.accumulatedDt = 0

  self.cameras = {}

  self.world = love.physics.newWorld()
  self.nextGroupIndex = 1

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

  local tank = Tank.new(self, {
    transform = {0, 16},
  })

  local camera = Camera.new(self)
  Player.new(self, tank, camera, {})
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
end

function M:fixedUpdate(dt)
  for _, camera in ipairs(self.cameras) do
    camera:fixedUpdateInterpolation(dt)
  end

  for _, sprite in ipairs(self.sprites) do
    sprite:fixedUpdateInterpolation(dt)
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

  for _, player in ipairs(self.players) do
    player:fixedUpdateCamera(dt)
  end
end

function M:draw()
  for _, camera in ipairs(self.cameras) do
    love.graphics.push("all")

    love.graphics.setScissor(
      camera.viewportX, camera.viewportY, camera.viewportWidth, camera.viewportHeight)

    love.graphics.replaceTransform(camera.interpolatedWorldToScreen)
    local _, _, _, scale = utils.decompose2(camera.interpolatedWorldToScreen)
    love.graphics.setLineWidth(1 / scale)

    for _, terrain in ipairs(self.terrains) do
      love.graphics.draw(terrain.mesh)
    end

    for _, sprite in ipairs(self.sprites) do
      love.graphics.draw(sprite.image, sprite.interpolatedImageToWorld)
    end

    love.graphics.pop()
    love.graphics.push("all")

    love.graphics.setScissor(
      camera.viewportX, camera.viewportY, camera.viewportWidth, camera.viewportHeight)

    love.graphics.replaceTransform(camera.worldToScreen)
    local _, _, _, scale = utils.decompose2(camera.worldToScreen)
    love.graphics.setLineWidth(1 / scale)
    -- self:debugDrawPhysics()

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
  for _, camera in ipairs(self.cameras) do
    camera:setViewport(0, 0, w, h)
  end
end

function M:generateGroupIndex()
  local result = self.nextGroupIndex
  self.nextGroupIndex = self.nextGroupIndex + 1
  return result
end

return M
