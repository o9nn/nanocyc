-- a9nn/examples/mlp_example.lua
-- Demonstrates a classic MLP trained on a simple regression task.
-- Run with:  lua examples/mlp_example.lua  (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
local base = arg and arg[0] and arg[0]:match("(.+)/examples/") or "."
addPath(base .. "/..")
addPath(base)

local nn = require('a9nn')

math.randomseed(42)
local Tensor = nn.Tensor

print("════════════════════════════════════════════════════")
print("  a9nn MLP Regression Example")
print("════════════════════════════════════════════════════")
print()

-- ── Dataset: learn y = sin(x) ─────────────────────────────────────────────────
local N      = 200
local X_all, Y_all = {}, {}
for i = 1, N do
   local x = (i / N) * 2 * math.pi
   X_all[i] = Tensor.new({x / (2*math.pi)})  -- normalised to [0,1]
   Y_all[i] = Tensor.new({math.sin(x)})
end

-- ── Model ─────────────────────────────────────────────────────────────────────
local model = nn.Sequential()
model:add(nn.Linear(1, 32))
model:add(nn.Tanh())
model:add(nn.Linear(32, 32))
model:add(nn.Tanh())
model:add(nn.Linear(32, 1))

local criterion = nn.MSECriterion()

print(string.format("Model: %s", tostring(model)))
print()

-- ── Training loop ─────────────────────────────────────────────────────────────
local lr     = 0.05
local epochs = 200
local logEvery = 20

print(string.format("Training: %d epochs, lr=%.4f, N=%d", epochs, lr, N))
print()

for epoch = 1, epochs do
   local totalLoss = 0
   -- Shuffle
   local idx = {}
   for i = 1, N do idx[i] = i end
   for i = N, 2, -1 do
      local j = math.random(i)
      idx[i], idx[j] = idx[j], idx[i]
   end

   for _, i in ipairs(idx) do
      local x    = X_all[i]
      local y    = Y_all[i]
      local pred = model:forward(x)
      local loss = criterion:forward(pred, y)
      totalLoss  = totalLoss + loss

      local grad = criterion:backward(pred, y)
      model:zeroGradParameters()
      model:backward(x, grad)
      model:updateParameters(lr)
   end

   if epoch % logEvery == 0 then
      print(string.format("  Epoch %3d/%d  |  mean loss = %.6f",
         epoch, epochs, totalLoss / N))
   end
end

-- ── Evaluation ────────────────────────────────────────────────────────────────
print()
print("Sample predictions (x → predicted vs actual):")
print(string.format("  %-12s  %-12s  %-12s  %-10s", "x", "sin(x)", "predicted", "error"))
print("  " .. string.rep("-", 50))

local totalErr = 0
local checkPoints = {0.0, 0.25, 0.5, 0.75, 1.0}
for _, t in ipairs(checkPoints) do
   local x     = Tensor.new({t})
   local xReal = t * 2 * math.pi
   local pred  = model:forward(x).data[1]
   local actual = math.sin(xReal)
   local err   = math.abs(pred - actual)
   totalErr    = totalErr + err
   print(string.format("  %-12.4f  %-12.6f  %-12.6f  %-10.6f",
      xReal, actual, pred, err))
end
print()
print(string.format("  Mean absolute error: %.6f", totalErr / #checkPoints))
print()
print("Done.")
