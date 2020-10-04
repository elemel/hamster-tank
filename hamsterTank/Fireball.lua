local Class = require("hamsterTank.Class")
local utils = require("hamsterTank.utils")

local M = Class.new()

function M:init(tank, config)
  self.game = tank.game
  self.dead = false
  self.despawnDelay = 8

  local x, y, angle = unpack(config.transform)

  self.body = love.physics.newBody(self.game.world, x, y, "dynamic")
  self.body:setAngle(angle)
  self.body:setBullet(true)
  self.body:setLinearVelocity(config.linearVelocityX, config.linearVelocityY)

  local shape = love.physics.newCircleShape(0, 0, 0.25)
  self.fixture = love.physics.newFixture(self.body, shape)
  self.fixture:setGroupIndex(-tank.groupIndex)

  self.fixture:setUserData({
    collisionType = "fireball",
    fireball = self,
  })

  local fireImage = self.game.resources.images.particles.fire
  local fireImageWidth, fireImageHeight = fireImage:getDimensions()

  self.fireParticles = love.graphics.newParticleSystem(fireImage, 64)

  self.fireParticles:setParticleLifetime(0.25)
  self.fireParticles:setEmissionRate(256)
  self.fireParticles:setEmitterLifetime(4)
  self.fireParticles:setLinearDamping(1)

  self.fireParticles:setColors(
    1, 0.75, 0.5, 0.5,
    0.75, 0.5, 0.25, 0.5,
    0.5, 0.25, 0, 0.5,
    0.25, 0, 0, 0.5,
    0, 0, 0, 0.5)

  self.fireParticles:setEmissionArea("ellipse", 0.25, 0.25)
  self.fireParticles:setSizes(0.75 / fireImageHeight)

  local smokeImage = self.game.resources.images.particles.smoke
  local smokeImageWidth, smokeImageHeight = smokeImage:getDimensions()

  self.smokeParticles = love.graphics.newParticleSystem(smokeImage, 16)

  self.smokeParticles:setParticleLifetime(0.5)
  self.smokeParticles:setEmissionRate(32)
  self.smokeParticles:setEmitterLifetime(4)
  self.smokeParticles:setLinearDamping(4)

  self.smokeParticles:setColors(
    0, 0, 0, 0,
    0, 0, 0, 0.25,
    0, 0, 0, 0.125,
    0, 0, 0, 0)

  self.smokeParticles:setEmissionArea("ellipse", 0.25, 0.25)
  self.smokeParticles:setSizes(1.5 / smokeImageHeight)

  self:controlFireParticles()
  self:controlSmokeParticles()

  self.game.fireballs[#self.game.fireballs + 1] = self
end

function M:destroy()
  utils.removeLast(self.game.fireballs, self)

  self.fixture:destroy()
  self.fixture = nil

  self.body:destroy()
  self.body = nil
end

function M:fixedUpdateParticles(dt)
  self:controlFireParticles()
  self:controlSmokeParticles()
end

function M:controlFireParticles()
  local x, y = self.body:getPosition()
  local linearVelocityX, linearVelocityY = self.body:getLinearVelocity()

  local downX, downY = utils.normalize2(x, y)
  local linearAcceleration = 32

  self.fireParticles:setPosition(x, y)
  self.fireParticles:setDirection(math.atan2(linearVelocityY, linearVelocityX))
  self.fireParticles:setSpeed(utils.length2(linearVelocityX, linearVelocityY))
  self.fireParticles:setLinearAcceleration(-downX * linearAcceleration, -downY * linearAcceleration)
end

function M:controlSmokeParticles()
  local x, y = self.body:getPosition()
  local linearVelocityX, linearVelocityY = self.body:getLinearVelocity()

  local downX, downY = utils.normalize2(x, y)
  local linearAcceleration = 8

  self.smokeParticles:setPosition(x, y)
  self.smokeParticles:setDirection(math.atan2(linearVelocityY, linearVelocityX))
  self.smokeParticles:setSpeed(utils.length2(linearVelocityX, linearVelocityY))
  self.smokeParticles:setLinearAcceleration(-downX * linearAcceleration, -downY * linearAcceleration)
end

function M:updateParticles(dt)
  self.fireParticles:update(dt)
  self.smokeParticles:update(dt)
end

function M:setDead(dead)
  if dead == self.dead then
    return
  end

  self.dead = dead

  if not self.dead then
    return
  end

  self.fixture:setSensor(true)
end

function M:fixedUpdateDespawn(dt)
  self.despawnDelay = self.despawnDelay - dt

  if self.despawnDelay < 0 then
    self:destroy()
  end
end

return M
