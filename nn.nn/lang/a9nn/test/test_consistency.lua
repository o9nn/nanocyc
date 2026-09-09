-- a9nn/test/test_consistency.lua
-- Cross-implementation consistency test.
--
-- Builds the fixed 2-2-1 sigmoid MLP from docs/fixtures/xor_fixture.json and
-- asserts the forward output and MSE loss to a tight tolerance. The identical
-- check is implemented by every other port (scm, rkt, raku, pl) and by the
-- Isabelle/HOL theories (lang/isa/NN_Consistency.thy), guaranteeing that all
-- implementations agree numerically on a single deterministic fixture.
--
-- Run with:  lua test/test_consistency.lua   (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
local base = arg and arg[0] and arg[0]:match("(.+)/test/") or "."
addPath(base .. "/..")
addPath(base)

local nn = require('a9nn')
local Tensor = nn.Tensor

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
   tol = tol or 1e-6
   assert(math.abs(a - b) <= tol,
      string.format("%s: expected %.10f ≈ %.10f (diff=%.2e)",
         msg or "", b, a, math.abs(a - b)))
end

-- ── Fixture (mirrors docs/fixtures/xor_fixture.json) ─────────────────────────
-- weights[layer][neuron] = { w = {...}, b = number }
local FIXTURE = {
   tol = 1e-6,
   layers = {
      { { w = {0.5, -0.5},  b = 0.1  },
        { w = {-0.25, 0.75}, b = -0.2 } },
      { { w = {0.6, -0.4},  b = 0.05 } },
   },
   cases = {
      { input = {0, 0}, target = {0}, output = 0.5460989866, loss = 0.2982241032 },
      { input = {0, 1}, target = {1}, output = 0.5092822253, loss = 0.2408039344 },
      { input = {1, 0}, target = {1}, output = 0.5699505688, loss = 0.1849425133 },
      { input = {1, 1}, target = {0}, output = 0.5337512224, loss = 0.2848903675 },
   },
}

-- Build an a9nn Sequential (Linear → Sigmoid)* from the fixture weights.
local function buildNetwork(fx)
   local function fillWeight(inS, outS, neurons)
      local w = Tensor.zeros(outS, inS)
      local b = Tensor.zeros(outS)
      for o, neuron in ipairs(neurons) do
         for i = 1, inS do
            w.data[(o - 1) * inS + i] = neuron.w[i]
         end
         b.data[o] = neuron.b
      end
      return w, b
   end

   local net = nn.Sequential()
   local sizes = { 2, 2, 1 }
   for li, neurons in ipairs(fx.layers) do
      local inS, outS = sizes[li], sizes[li + 1]
      local lin = nn.Linear(inS, outS)
      lin.weight, lin.bias = fillWeight(inS, outS, neurons)
      net:add(lin)
      net:add(nn.Sigmoid())
   end
   return net
end

print("\n─── a9nn cross-implementation consistency tests ─────────────")

test("fixture forward outputs match reference", function()
   local net = buildNetwork(FIXTURE)
   for ci, case in ipairs(FIXTURE.cases) do
      local out = net:forward(Tensor.new(case.input))
      assert_near(out.data[1], case.output, FIXTURE.tol,
         string.format("case %d output", ci))
   end
end)

test("fixture MSE losses match reference", function()
   local net = buildNetwork(FIXTURE)
   local crit = nn.MSECriterion()
   for ci, case in ipairs(FIXTURE.cases) do
      local out = net:forward(Tensor.new(case.input))
      local loss = crit:forward(out, Tensor.new(case.target))
      assert_near(loss, case.loss, FIXTURE.tol,
         string.format("case %d loss", ci))
   end
end)

test("fixture outputs are deterministic across runs", function()
   local a = buildNetwork(FIXTURE):forward(Tensor.new({1, 0}))
   local b = buildNetwork(FIXTURE):forward(Tensor.new({1, 0}))
   assert_near(a.data[1], b.data[1], 0, "deterministic")
end)

print(string.format("\n─── Results: %d passed, %d failed ───\n", passed, failed))
if failed > 0 then os.exit(1) end
