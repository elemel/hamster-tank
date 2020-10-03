local Class = require("sial.Class")
local Player = require("sial.Player")
local Tank = require("sial.Tank")
local utils = require("sial.utils")

local M = Class.new()

function M:init()
  self.fixedDt = 1 / 60
  self.accumulatedDt = 0

  self.cameraTransform = love.math.newTransform()
  self:resize(love.graphics.getDimensions())

  self.world = love.physics.newWorld()
  self.body = love.physics.newBody(self.world, 0, 8)

  local shape = love.physics.newRectangleShape(16, 1)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setFriction(1)

  self.nextGroupIndex = 1
  self.tanks = {}
  self.players = {}

  self.wheelRadius = 8
  self.wheelGravity = 16

  local tank = Tank.new(self, {
    transform = love.math.newTransform(0, 4),
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

  -- Gravity
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
end

function M:draw()
  love.graphics.push("all")
  love.graphics.replaceTransform(self.cameraTransform)
  local _, _, _, scale = utils.decompose2(self.cameraTransform)
  love.graphics.setLineWidth(1 / scale)
  self:debugDrawPhysics()
  love.graphics.pop()
end

function M:debugDrawPhysics()
  for _, body in ipairs(self.world:getBodies()) do
    local angle = body:getAngle()

    for _, fixture in ipairs(body:getFixtures()) do
      local shape = fixture:getShape()
      local shapeType = shape:getType()

      if shapeType == "circle" then
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
end

function M:resize(w, h)
  self.cameraTransform:reset():translate(0.5 * w, 0.5 * h):scale(h / 16)
end

function M:generateGroupIndex()
  local result = self.nextGroupIndex
  self.nextGroupIndex = self.nextGroupIndex + 1
  return result
end

return M
