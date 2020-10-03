local acos = math.acos
local remove = table.remove
local sqrt = math.sqrt

local function sign(x)
  return x < 0 and -1 or 1
end

-- http://frederic-wang.fr/decomposition-of-2d-transform-matrices.html
local function decompose2(transform)
  local t11, t12, t13, t14,
    t21, t22, t23, t24,
    t31, t32, t33, t34,
    t41, t42, t43, t44 = transform:getMatrix()

  local x = t14
  local y = t24
  local angle = 0
  local scaleX = t11 * t11 + t21 * t21
  local scaleY = t12 * t12 + t22 * t22
  local shearX = 0
  local shearY = 0

  if scaleX + scaleY ~= 0 then
    local det = t11 * t22 - t12 * t21

    if scaleX >= scaleY then
      shearX = (t11 * t12 + t21 * t22) / scaleX
      scaleX = sqrt(scaleX)
      angle = sign(t21) * acos(t11 / scaleX)
      scaleY = det / scaleX
    else
      shearY = (t11 * t12 + t21 * t22) / scaleY
      scaleY = sqrt(scaleY)
      angle = 0.5 * pi - sign(t22) * acos(-t12 / scaleY)
      scaleX = det / scaleY
    end
  end

  return x, y, angle, scaleX, scaleY, 0, 0, shearX, shearY
end

local function removeLast(t, v)
  for i = #t, 1, -1 do
    if t[i] == v then
      remove(t, i)
      return i
    end
  end

  return nil
end

local function transformVector(transform, x, y)
  local x1, y1 = transform:transformPoint(0, 0)
  local x2, y2 = transform:transformPoint(x, y)
  return x2 - x1, y2 - y1
end

return {
  decompose2 = decompose2,
  removeLast = removeLast,
  sign = sign,
  transformVector = transformVector,
}
