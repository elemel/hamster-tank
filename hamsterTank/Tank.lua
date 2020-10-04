local Class = require("hamsterTank.Class")
local Sprite = require("hamsterTank.Sprite")
local Turret = require("hamsterTank.Turret")
local utils = require("hamsterTank.utils")
local Wheel = require("hamsterTank.Wheel")

local M = Class.new()

function M:init(game, config)
  self.destroyed = false
  self.dead = false

  self.game = game
  self.groupIndex = self.game:generateGroupIndex()
  self.inputX = 0

  self.aimInputX = 0
  self.aimInputY = 0

  self.jumpInput = config.jumpInput or false
  self.previousJumpInput = self.jumpInput

  self.suicideInput = config.suicideInput or false
  self.previousSuicideInput = self.suicideInput

  local transform = love.math.newTransform(unpack(config.transform))
  local x, y, angle = utils.decompose2(transform)

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)

  local leftShape = love.physics.newCircleShape(-0.75, 0, 0.75)
  self.leftFixture = love.physics.newFixture(self.body, leftShape)
  self.leftFixture:setGroupIndex(-self.groupIndex)

  local centerShape = love.physics.newRectangleShape(1.5, 1.5)
  self.centerFixture = love.physics.newFixture(self.body, centerShape)
  self.centerFixture:setGroupIndex(-self.groupIndex)

  local rightShape = love.physics.newCircleShape(0.75, 0, 0.75)
  self.rightFixture = love.physics.newFixture(self.body, rightShape)
  self.rightFixture:setGroupIndex(-self.groupIndex)

  local image = self.game.resources.images.hamster.trunk
  local imageWidth, imageHeight = image:getDimensions()
  local scale = 2 / imageHeight

  self.sprite = Sprite.new(self.game, image, {
    localToWorld = {x, y, angle},
    imageToLocal = {0, 0, 0, scale, scale, 0.5 * imageWidth, 0.5 * imageHeight},
  })

  self.turrets = {}
  self.wheels = {}

  self.game.tanks[#self.game.tanks + 1] = self

  Turret.new(self, {
    transform = {0, -0.75, 0},
    radius = 0.5,
    maxDistance = 0.5,
  })

  Wheel.new(self, {
    transform = transform * love.math.newTransform(-1.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = transform * love.math.newTransform(-0.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = transform * love.math.newTransform(0.5, 0.75),
    radius = 0.375,
  })

  Wheel.new(self, {
    transform = transform * love.math.newTransform(1.5, 0.75),
    radius = 0.375,
  })
end

function M:destroy()
  self.destroyed = true

  for i = #self.wheels, 1, -1 do
    self.wheels[i]:destroy()
    self.wheels[i] = nil
  end

  for i = #self.turrets, 1, -1 do
    self.turrets[i]:destroy()
    self.turrets[i] = nil
  end

  utils.removeLast(self.game.tanks, self)

  self.sprite:destroy()
  self.sprite = nil

  self.rightFixture:destroy()
  self.rightFixture = nil

  self.centerFixture:destroy()
  self.centerFixture = nil

  self.leftFixture:destroy()
  self.leftFixture = nil

  self.body:destroy()
  self.body = nil
end

function M:fixedUpdateControl(dt)
  if self.dead then
    return
  end

  if self.suicideInput and not self.previousSuicideInput then
    self:setDead(true)

    local impulseSign = utils.sign(love.math.random() - 0.5)
    local impulseMagnitude = (0.5 + 0.5 * love.math.random()) * 32

    self.body:applyAngularImpulse(impulseSign * impulseMagnitude)
    return
  end

  if self.jumpInput and not self.previousJumpInput then
    local downX, downY = self.body:getWorldVector(0, 1)
    local jumpImpulse = 64

    for _, wheel in ipairs(self.wheels) do
      local wheelX, wheelY = wheel.body:getWorldCenter()
      wheel.body:applyLinearImpulse(downX * jumpImpulse, downY * jumpImpulse, wheelX, wheelY)
      self.body:applyLinearImpulse(-downX * jumpImpulse, -downY * jumpImpulse, wheelX, wheelY)
    end
  end

  for _, turret in ipairs(self.turrets) do
    turret:fixedUpdateControl(dt)
  end

  for _, wheel in ipairs(self.wheels) do
    wheel.joint:setMotorSpeed(self.inputX * 64)
  end
end

function M:fixedUpdateAnimation(dt)
  local x, y = self.body:getPosition()
  local angle = self.body:getAngle()
  self.sprite:setLocalToWorld(x, y, angle)

  for _, turret in ipairs(self.turrets) do
    turret:fixedUpdateAnimation(dt)
  end

  for _, wheel in ipairs(self.wheels) do
    wheel:fixedUpdateAnimation(dt)
  end
end

function M:setDead(dead)
  if dead ~= self.dead then
    self.dead = dead

    if self.dead then
      for _, turret in ipairs(self.turrets) do
        turret.fixture:setSensor(true)
      end

      for _, wheel in ipairs(self.wheels) do
        wheel.fixture:setSensor(true)
      end

      self.rightFixture:setSensor(true)
      self.centerFixture:setSensor(true)
      self.leftFixture:setSensor(true)
    end
  end
end

function M:fixedUpdateDespawn(dt)
  local x, y = self.body:getPosition()
  local distance = utils.length2(x, y)

  if distance > 256 then
    self:destroy()
  end
end

return M
