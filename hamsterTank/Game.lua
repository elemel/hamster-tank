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

  self.camera = Camera.new()
  self:resize(love.graphics.getDimensions())

  self.world = love.physics.newWorld()
  self.nextGroupIndex = 1

  self.players = {}
  self.tanks = {}
  self.terrains = {}

  self.wheelRadius = 32
  self.wheelGravity = 32

  Terrain.new(self, {
    radius = self.wheelRadius,
  })

  local tank = Tank.new(self, {
    transform = love.math.newTransform(0, 16),
  })

  Player.new(self, tank, {})
end

function M:update(dt)
  self.accumulatedDt = self.accumulatedDt + dt

  while self.accumulatedDt >= self.fixedDt do
    self.accumulatedDt = self.accumulatedDt - self.fixedDt
    self:fixedUpdate(self.fixedDt)
  end
end

function M:fixedUpdate(dt)
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

  for _, player in ipairs(self.players) do
    player:fixedUpdateCamera(dt)
  end
end

function M:draw()
  love.graphics.push("all")
  love.graphics.replaceTransform(self.camera.transform)
  local _, _, _, scale = utils.decompose2(self.camera.transform)
  love.graphics.setLineWidth(1 / scale)
  self:debugDrawPhysics()
  love.graphics.pop()
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
  self.camera:setViewport(0, 0, w, h)
end

function M:generateGroupIndex()
  local result = self.nextGroupIndex
  self.nextGroupIndex = self.nextGroupIndex + 1
  return result
end

return M
