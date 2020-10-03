local Class = require("sial.Class")
local utils = require("sial.utils")

local M = Class.new()

function M:init()
  self.fixedDt = 1 / 60
  self.accumulatedDt = 0
  self.cameraTransform = love.math.newTransform():translate(400, 300):scale(600 / 16)
  self.world = love.physics.newWorld()
  self.body = love.physics.newBody(self.world)
  local shape = love.physics.newCircleShape(0.5)
  self.fixture = love.physics.newFixture(self.body, shape)
end

function M:update(dt)
  self.accumulatedDt = self.accumulatedDt + dt

  while self.accumulatedDt >= self.fixedDt do
    self.accumulatedDt = self.accumulatedDt - self.fixedDt
    self:fixedUpdate(self.fixedDt)
  end
end

function M:fixedUpdate(dt)
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
    for _, fixture in ipairs(body:getFixtures()) do
      local shape = fixture:getShape()
      local shapeType = shape:getType()

      if shapeType == "circle" then
        local x, y = shape:getPoint()
        local radius = shape:getRadius()
        love.graphics.circle("line", x, y, radius)
      end
    end
  end
end

function M:resize(w, h)
  self.cameraTransform:reset():translate(0.5 * w, 0.5 * h):scale(h / 16)
end

return M
