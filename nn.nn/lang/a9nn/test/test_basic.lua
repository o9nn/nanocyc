-- a9nn/test/test_basic.lua
-- Unit tests for core nn modules: Linear, Sequential, activations, criterions.
-- Run with:  lua test/test_basic.lua  (from lang/a9nn/)

-- ── Path setup ────────────────────────────────────────────────────────────────
local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end

-- Support running from lang/a9nn/ or from the repo root
local base = arg and arg[0] and arg[0]:match("(.+)/test/") or "."
addPath(base .. "/..")  -- so 'a9nn.xxx' resolves
addPath(base)

-- ── Load framework ────────────────────────────────────────────────────────────
local nn = require('a9nn')

-- ── Tiny test harness ─────────────────────────────────────────────────────────
local passed, failed = 0, 0
local function test(name, fn)
   local ok, err = pcall(fn)
   if ok then
      print(string.format("  ✓  %s", name))
      passed = passed + 1
   else
      print(string.format("  ✗  %s\n     %s", name, tostring(err)))
      failed = failed + 1
   end
end

local function assert_near(a, b, tol, msg)
   tol = tol or 1e-5
   assert(math.abs(a - b) < tol,
      string.format("%s: expected %.8f ≈ %.8f (diff=%.2e)", msg or "", a, b, math.abs(a-b)))
end

local Tensor = nn.Tensor

print("\n─── a9nn basic tests ───────────────────────────────────────")

-- ── Tensor tests ──────────────────────────────────────────────────────────────
print("\n[Tensor]")

test("zeros", function()
   local t = Tensor.zeros(4)
   assert(t.size_[1] == 4)
   for _, v in ipairs(t.data) do assert(v == 0) end
end)

test("ones", function()
   local t = Tensor.ones(3)
   for _, v in ipairs(t.data) do assert(v == 1) end
end)

test("add scalar", function()
   local t  = Tensor.new({1,2,3})
   local t2 = t:add(10)
   assert_near(t2.data[1], 11, 1e-9, "add[1]")
   assert_near(t2.data[3], 13, 1e-9, "add[3]")
end)

test("add tensor", function()
   local a = Tensor.new({1,2,3})
   local b = Tensor.new({4,5,6})
   local c = a:add(b)
   assert_near(c.data[2], 7, 1e-9, "add elem 2")
end)

test("cmul", function()
   local a = Tensor.new({2,3,4})
   local b = Tensor.new({1,2,3})
   local c = a:cmul(b)
   assert_near(c.data[1], 2)
   assert_near(c.data[2], 6)
   assert_near(c.data[3], 12)
end)

test("mm (2x3 × 3x2)", function()
   local A = Tensor.zeros(2, 3)
   -- [[1,2,3],[4,5,6]]
   A.data = {1,2,3,4,5,6}
   local B = Tensor.zeros(3, 2)
   -- [[7,8],[9,10],[11,12]]
   B.data = {7,8,9,10,11,12}
   local C = A:mm(B)
   assert(C.size_[1] == 2 and C.size_[2] == 2)
   -- C[1,1] = 1*7+2*9+3*11 = 58
   assert_near(C.data[1], 58, 1e-6, "C[1,1]")
   -- C[1,2] = 1*8+2*10+3*12 = 64
   assert_near(C.data[2], 64, 1e-6, "C[1,2]")
end)

test("mv", function()
   local A = Tensor.zeros(2, 3)
   A.data = {1,0,0, 0,1,0}
   local v = Tensor.new({5,6,7})
   local w = A:mv(v)
   assert_near(w.data[1], 5)
   assert_near(w.data[2], 6)
end)

test("norm", function()
   local t = Tensor.new({3, 4})
   assert_near(t:norm(), 5)
end)

-- ── Linear layer ──────────────────────────────────────────────────────────────
print("\n[Linear]")

test("forward shape", function()
   local L = nn.Linear(3, 2)
   local x = Tensor.new({1.0, 2.0, 3.0})
   local y = L:forward(x)
   assert(#y.data == 2, "output should have 2 elements, got " .. #y.data)
end)

test("forward + backward shape", function()
   local L  = nn.Linear(4, 3)
   local x  = Tensor.new({0.5, -0.3, 1.2, 0.7})
   local y  = L:forward(x)
   local dL = Tensor.ones(3)
   L:backward(x, dL)
   assert(#L.gradInput.data == 4)
   assert(#L.gradWeight.data == 12)
end)

test("weight update reduces loss", function()
   math.randomseed(42)
   local L   = nn.Linear(2, 1)
   local crit = nn.MSECriterion()
   -- Fit y = 2*x1 + 3*x2
   local x = Tensor.new({1.0, 1.0})
   local y = Tensor.new({5.0})

   local losses = {}
   for _ = 1, 50 do
      local out  = L:forward(x)
      local loss = crit:forward(out, y)
      losses[#losses+1] = loss
      local gOut = crit:backward(out, y)
      L:zeroGradParameters()
      L:backward(x, gOut)
      L:updateParameters(0.1)
   end
   -- Loss should decrease
   assert(losses[#losses] < losses[1],
      string.format("Loss did not decrease: %.4f → %.4f", losses[1], losses[#losses]))
end)

-- ── Sequential ────────────────────────────────────────────────────────────────
print("\n[Sequential]")

test("forward through MLP", function()
   local mlp = nn.Sequential()
   mlp:add(nn.Linear(2, 4))
   mlp:add(nn.Tanh())
   mlp:add(nn.Linear(4, 1))
   local x = Tensor.new({0.5, -0.5})
   local y = mlp:forward(x)
   assert(#y.data == 1)
end)

test("backward through MLP", function()
   local mlp = nn.Sequential()
   mlp:add(nn.Linear(2, 4))
   mlp:add(nn.Tanh())
   mlp:add(nn.Linear(4, 2))
   local x  = Tensor.new({1.0, 0.5})
   mlp:forward(x)
   local dL = Tensor.new({1.0, -1.0})
   local gx = mlp:backward(x, dL)
   assert(#gx.data == 2)
end)

-- ── Activations ───────────────────────────────────────────────────────────────
print("\n[Activations]")

test("Tanh(0) = 0", function()
   local t = nn.Tanh()
   local y = t:forward(Tensor.new({0}))
   assert_near(y.data[1], 0)
end)

test("Sigmoid(0) = 0.5", function()
   local s = nn.Sigmoid()
   local y = s:forward(Tensor.new({0}))
   assert_near(y.data[1], 0.5)
end)

test("ReLU negative → 0", function()
   local r = nn.ReLU()
   local y = r:forward(Tensor.new({-3, 0, 2}))
   assert_near(y.data[1], 0)
   assert_near(y.data[2], 0)
   assert_near(y.data[3], 2)
end)

test("SoftMax sums to 1", function()
   local sm = nn.SoftMax()
   local y  = sm:forward(Tensor.new({1, 2, 3}))
   assert_near(y:sum(), 1.0, 1e-6, "SoftMax sum")
end)

-- ── Criterions ────────────────────────────────────────────────────────────────
print("\n[Criterions]")

test("MSE: identical inputs → 0", function()
   local c = nn.MSECriterion()
   local v = Tensor.new({1,2,3})
   local l = c:forward(v, v)
   assert_near(l, 0, 1e-9, "MSE(v,v)")
end)

test("MSE loss value", function()
   local c    = nn.MSECriterion()
   local pred = Tensor.new({0, 0})
   local tgt  = Tensor.new({1, 1})
   local loss = c:forward(pred, tgt)
   assert_near(loss, 1.0, 1e-6, "MSE loss = 1")
end)

test("MSE backward shape", function()
   local c = nn.MSECriterion()
   local p = Tensor.new({0.5, 0.5})
   local t = Tensor.new({1.0, 1.0})
   c:forward(p, t)
   local g = c:backward(p, t)
   assert(#g.data == 2)
end)

test("SmoothL1 zero at identity", function()
   local c = nn.SmoothL1Criterion()
   local v = Tensor.new({1,2,3})
   assert_near(c:forward(v, v), 0, 1e-9)
end)

-- ─────────────────────────────────────────────────────────────────────────────
print(string.format("\n─── Results: %d passed, %d failed ───\n", passed, failed))

if failed > 0 then os.exit(1) end
