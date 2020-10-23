local Class = require("hamsterTank.Class")

local M = Class.new()

function M:init(game, config)
  self.game = assert(game)
  self.groupIndex = self.game:generateGroupIndex()

  local r, g, b = self.game:generateTeamColor()
  self.color = {r, g, b}
  self.tintColor = {0.5 + 0.5 * r, 0.5 + 0.5 * g, 0.5 + 0.5 * b}

  self.fireColors = {}

  for f = 0, 1, 0.25 do
    table.insert(self.fireColors, math.max(0, r - f))
    table.insert(self.fireColors, math.max(0, g - f))
    table.insert(self.fireColors, math.max(0, b - f))

    table.insert(self.fireColors, 0.5)
  end
end

return M
