local M = {}
M.__index = M

function M.new(...)
  local instance = setmetatable({}, M)
  instance:init(...)
  return instance
end

function M:init()
  self.splash = love.graphics.newImage("resources/images/splash.png")
end

function M:draw()
  love.graphics.draw(self.splash)
end

return M
