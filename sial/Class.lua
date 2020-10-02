local M = {}

function M.new()
  local class = {}
  class.__index = class

  function class.new(...)
    local instance = setmetatable({}, class)
    instance:init(...)
    return instance
  end

  return class
end

return M
