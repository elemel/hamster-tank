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

local function normalize2(x, y)
  local length = sqrt(x * x + y * y)
  return x / length, y / length, length
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

local function mixTransforms(a, b, t, c)
  local a11, a12, a13, a14,
    a21, a22, a23, a24,
    a31, a32, a33, a34,
    a41, a42, a43, a44 = a:getMatrix()

  local b11, b12, b13, b14,
    b21, b22, b23, b24,
    b31, b32, b33, b34,
    b41, b42, b43, b44 = b:getMatrix()

  local s = 1 - t

  local c11 = s * a11 + t * b11
  local c12 = s * a12 + t * b12
  local c13 = s * a13 + t * b13
  local c14 = s * a14 + t * b14

  local c21 = s * a21 + t * b21
  local c22 = s * a22 + t * b22
  local c23 = s * a23 + t * b23
  local c24 = s * a24 + t * b24

  local c31 = s * a31 + t * b31
  local c32 = s * a32 + t * b32
  local c33 = s * a33 + t * b33
  local c34 = s * a34 + t * b34

  local c41 = s * a41 + t * b41
  local c42 = s * a42 + t * b42
  local c43 = s * a43 + t * b43
  local c44 = s * a44 + t * b44

  c = c or love.math.newTransform()

  c:setMatrix(
    c11, c12, c13, c14,
    c21, c22, c23, c24,
    c31, c32, c33, c34,
    c41, c42, c43, c44)

  return c, c34
end

return {
  decompose2 = decompose2,
  mixTransforms = mixTransforms,
  normalize2 = normalize2,
  removeLast = removeLast,
  sign = sign,
  transformVector = transformVector,
}
