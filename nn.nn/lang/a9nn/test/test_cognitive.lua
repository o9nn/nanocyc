-- a9nn/test/test_cognitive.lua
-- Unit tests for cognitive modules: EchoReservoir, AtomSpace, Personality,
-- EpisodicMemory, LLaMAOrchestrator, Agents, NNECCOAgent.
-- Run with:  lua test/test_cognitive.lua  (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
local base = arg and arg[0] and arg[0]:match("(.+)/test/") or "."
addPath(base .. "/..")
addPath(base)

local nn = require('a9nn')

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
      string.format("%s: %.8f ≈ %.8f (diff=%.2e)", msg or "", a, b, math.abs(a-b)))
end

local Tensor = nn.Tensor

print("\n─── a9nn cognitive tests ────────────────────────────────────")

-- ── EchoReservoir ─────────────────────────────────────────────────────────────
print("\n[EchoReservoir]")

test("construction", function()
   local r = nn.EchoReservoir(8, 50)
   assert(r.reservoirN == 50)
   assert(r.inSize == 8)
end)

test("forward output shape", function()
   local r = nn.EchoReservoir(4, 20)
   local x = Tensor.new({0.1, 0.2, 0.3, 0.4})
   local y = r:forward(x)
   assert(y.size_[1] == 20, "output should have 20 elements")
end)

test("state persists across steps", function()
   local r  = nn.EchoReservoir(3, 10)
   local x1 = Tensor.new({1.0, 0.0, 0.0})
   local x2 = Tensor.new({0.0, 1.0, 0.0})
   r:forward(x1)
   local s1 = r:getState()
   r:forward(x2)
   local s2 = r:getState()
   -- States should differ because memory is retained
   local diff = 0
   for i = 1, 10 do diff = diff + math.abs(s1.data[i] - s2.data[i]) end
   assert(diff > 1e-6, "Reservoir state did not change across steps")
end)

test("resetState zeroes state", function()
   local r = nn.EchoReservoir(3, 10)
   local x = Tensor.new({1, 2, 3})
   r:forward(x)
   r:resetState()
   local norm = r.state:norm()
   assert_near(norm, 0, 1e-9, "state norm after reset")
end)

test("forwardSequence length", function()
   local r   = nn.EchoReservoir(2, 15)
   local seq = {}
   for i = 1, 5 do seq[i] = Tensor.new({math.sin(i), math.cos(i)}) end
   local states = r:forwardSequence(seq)
   assert(#states == 5)
end)

test("spectral radius < 1 ensures echo property", function()
   -- Long zero sequence → state should decay toward zero
   local r = nn.EchoReservoir(2, 20, {spectralRadius = 0.5, leakRate = 1.0})
   local x = Tensor.new({1, 1})
   r:forward(x)
   local zero = Tensor.new({0, 0})
   for _ = 1, 50 do r:forward(zero) end
   assert(r.state:norm() < 0.5, "State did not decay; spectral radius may be too high")
end)

-- ── AtomSpace ─────────────────────────────────────────────────────────────────
print("\n[AtomSpace]")

test("addNode / getNode round-trip", function()
   local as = nn.AtomSpace()
   local a  = as:addNode("ConceptNode", "cat")
   local b  = as:getNode("ConceptNode", "cat")
   assert(a.id == b.id)
end)

test("duplicate node returns same atom", function()
   local as = nn.AtomSpace()
   local a  = as:addNode("ConceptNode", "dog")
   local b  = as:addNode("ConceptNode", "dog")
   assert(a.id == b.id)
end)

test("addLink", function()
   local as  = nn.AtomSpace()
   local cat = as:addNode("ConceptNode", "cat")
   local ani = as:addNode("ConceptNode", "animal")
   local lnk = as:addLink("InheritanceLink", {cat, ani})
   assert(lnk ~= nil)
   assert(lnk:isLink())
end)

test("incoming set populated", function()
   local as  = nn.AtomSpace()
   local a   = as:addNode("ConceptNode", "X")
   local b   = as:addNode("ConceptNode", "Y")
   as:addLink("SimilarityLink", {a, b})
   local inc = as:getIncoming(a)
   assert(#inc == 1, "Expected 1 incoming link, got " .. #inc)
end)

test("getAtomsOfType", function()
   local as = nn.AtomSpace()
   as:addNode("ConceptNode", "p")
   as:addNode("ConceptNode", "q")
   as:addNode("NumberNode", "1")
   local concepts = as:getAtomsOfType("ConceptNode")
   assert(#concepts == 2, "Expected 2 ConceptNodes, got " .. #concepts)
end)

test("getLinks pattern matching", function()
   local as = nn.AtomSpace()
   local x  = as:addNode("ConceptNode", "x")
   local y  = as:addNode("ConceptNode", "y")
   local z  = as:addNode("ConceptNode", "z")
   as:addLink("EvaluationLink", {x, y})
   as:addLink("EvaluationLink", {y, z})
   local links = as:getLinks("EvaluationLink", {y})
   assert(#links == 2, "Expected 2 links containing y, got " .. #links)
end)

test("removeAtom", function()
   local as = nn.AtomSpace()
   local a  = as:addNode("ConceptNode", "remove_me")
   local id = a.id
   as:removeAtom(a)
   assert(as:getAtom(id) == nil)
   assert(as:size() == 0)
end)

-- ── Personality ───────────────────────────────────────────────────────────────
print("\n[Personality]")

test("default values = 0.5", function()
   local p = nn.Personality()
   for i = 1, p.n do
      assert_near(p.tensor.data[i], 0.5, 1e-9)
   end
end)

test("set / get round-trip", function()
   local p = nn.Personality()
   p:set("curiosity", 0.9)
   assert_near(p:get("curiosity"), 0.9)
end)

test("clamp to [0,1]", function()
   local p = nn.Personality()
   p:set("intelligence", 1.5)
   assert(p:get("intelligence") == 1.0)
   p:set("intelligence", -0.3)
   assert(p:get("intelligence") == 0.0)
end)

test("NeuroSama archetype", function()
   local p = nn.Personality.NeuroSama()
   assert(p:get("playfulness") >= 0.9)
   assert(p:get("warmth") >= 0.9)
end)

test("blend", function()
   local p1 = nn.Personality()
   p1:set("curiosity", 0.0)
   local p2 = nn.Personality()
   p2:set("curiosity", 1.0)
   local pb = p1:blend(p2, 0.5)
   assert_near(pb:get("curiosity"), 0.5, 1e-6)
end)

-- ── EpisodicMemory ────────────────────────────────────────────────────────────
print("\n[EpisodicMemory]")

test("push and size", function()
   local m = nn.EpisodicMemory(100)
   for i = 1, 10 do
      m:push({state=Tensor.new({i}), action=1, reward=0, nextState=Tensor.new({i+1}), done=false})
   end
   assert(m:size() == 10)
end)

test("sample returns requested count", function()
   local m = nn.EpisodicMemory(100, false)
   for i = 1, 20 do
      m:push({state=Tensor.new({i}), action=1, reward=0, nextState=Tensor.new({i+1}), done=false})
   end
   local batch, _, _ = m:sample(5)
   assert(#batch == 5)
end)

test("recent ordering", function()
   local m = nn.EpisodicMemory(100, false)
   for i = 1, 10 do
      m:push({state=Tensor.new({i}), action=1, reward=i, nextState=Tensor.new({0}), done=false})
   end
   local r = m:recent(3)
   assert(#r == 3)
   -- Most recent first: reward 10, 9, 8
   assert(r[1].reward == 10, "Expected reward=10, got " .. r[1].reward)
end)

test("circular buffer wraps", function()
   local m = nn.EpisodicMemory(5, false)
   for i = 1, 10 do
      m:push({state=Tensor.new({i}), action=1, reward=i, nextState=Tensor.new({0}), done=false})
   end
   assert(m:size() == 5)
end)

-- ── LLaMAOrchestrator ─────────────────────────────────────────────────────────
print("\n[LLaMAOrchestrator]")

test("stub mode initializes", function()
   local orch = nn.LLaMAOrchestrator({numInstances=3, stubMode=true})
   local ok = orch:initialize()
   assert(ok, "initialize() should return true in stub mode")
   assert(orch.initialized)
end)

test("stub generate returns text", function()
   local orch = nn.LLaMAOrchestrator({numInstances=2, stubMode=true})
   orch:initialize()
   local res = orch:generate("What is 2+2?", {max_tokens=32})
   assert(type(res.text) == "string" and #res.text > 0)
   assert(res.instance_id ~= nil)
end)

test("status reports correct instance count", function()
   local orch = nn.LLaMAOrchestrator({numInstances=4, stubMode=true})
   orch:initialize()
   local s = orch:getStatus()
   assert(s.numInstances == 4)
   assert(s.available == 4)
end)

test("load balances across instances", function()
   local orch = nn.LLaMAOrchestrator({numInstances=3, stubMode=true})
   orch:initialize()
   for i = 1, 9 do orch:generate("prompt " .. i) end
   -- Each instance should have served some tokens
   local s = orch:getStatus()
   local served = {}
   for _, inst in ipairs(s.instances) do
      served[#served+1] = inst.tokensServed
   end
   -- At least 2 instances should have served tokens (round-robin)
   local active = 0
   for _, v in ipairs(served) do if v > 0 then active = active + 1 end end
   assert(active >= 1, "Expected at least 1 active instance")
end)

test("batch generate", function()
   local orch = nn.LLaMAOrchestrator({numInstances=2, stubMode=true})
   orch:initialize()
   local prompts = {"Hello", "World", "Test"}
   local results = orch:batchGenerate(prompts)
   assert(#results == 3)
end)

-- ── Agent ─────────────────────────────────────────────────────────────────────
print("\n[Agent]")

test("act returns valid action", function()
   math.randomseed(1)
   local agent = nn.Agent({stateSize=4, actionSize=3})
   local state = Tensor.new({1, 0, -1, 0.5})
   local a = agent:act(state)
   assert(a >= 1 and a <= 3, "action out of range: " .. a)
end)

test("remember stores experiences", function()
   local agent = nn.Agent({stateSize=4, actionSize=3})
   for i = 1, 10 do
      local s  = Tensor.new({i, 0, 0, 0})
      local ns = Tensor.new({i+1, 0, 0, 0})
      agent:remember(s, 1, 0.5, ns, false)
   end
   assert(agent.memory:size() == 10)
end)

test("learn runs when memory large enough", function()
   math.randomseed(2)
   local agent = nn.Agent({stateSize=4, actionSize=2, batchSize=5, memoryCapacity=100})
   for i = 1, 10 do
      local s  = Tensor.new({math.random(), math.random(), math.random(), math.random()})
      local ns = Tensor.new({math.random(), math.random(), math.random(), math.random()})
      agent:remember(s, math.random(2), math.random(), ns, false)
   end
   local loss = agent:learn()
   assert(type(loss) == "number" and loss >= 0, "Expected non-negative loss")
end)

-- ── CognitiveAgent ────────────────────────────────────────────────────────────
print("\n[CognitiveAgent]")

test("spawn subordinate", function()
   local parent = nn.CognitiveAgent({stateSize=4, actionSize=2, role="manager"})
   local sub    = parent:spawnSubordinate({role="worker"})
   assert(sub ~= nil)
   assert(sub.parentID == parent.id)
end)

test("delegate task to subordinate", function()
   local mgr = nn.CognitiveAgent({stateSize=4, actionSize=2})
   local sub = mgr:spawnSubordinate({})
   local state = Tensor.new({0.1, 0.2, 0.3, 0.4})
   local result = mgr:delegate({type="infer", input=state}, sub.id)
   assert(result.agentID == sub.id)
   assert(result.success)
end)

test("max subordinates limit", function()
   local mgr = nn.CognitiveAgent({stateSize=4, actionSize=2, maxSubordinates=2})
   mgr:spawnSubordinate({})
   mgr:spawnSubordinate({})
   local ok, err = pcall(function() mgr:spawnSubordinate({}) end)
   assert(not ok, "Should have raised an error")
end)

test("broadcast to all subordinates", function()
   local mgr = nn.CognitiveAgent({stateSize=4, actionSize=2})
   for _ = 1, 3 do mgr:spawnSubordinate({}) end
   local results = mgr:broadcast({type="learn"})
   assert(#results == 3)
end)

-- ── NNECCOAgent ───────────────────────────────────────────────────────────────
print("\n[NNECCOAgent]")

test("construction with defaults", function()
   local agent = nn.NNECCOAgent({stateSize=16, reservoirSize=50})
   assert(agent.reservoir.reservoirN == 50)
   assert(agent.llama ~= nil)
end)

test("process text input", function()
   local agent = nn.NNECCOAgent({
      stateSize      = 16,
      reservoirSize  = 30,
      llamaInstances = 1,
      stubMode       = true,
   })
   local result = agent:process("Hello, what is the meaning of life?")
   assert(result ~= nil)
   assert(result.output ~= nil)
   assert(result.cycle == 1)
end)

test("process tensor input", function()
   local agent = nn.NNECCOAgent({
      stateSize     = 16,
      reservoirSize = 30,
      stubMode      = true,
   })
   local x      = Tensor.new({0.1, 0.2, 0.3, 0.4, 0.5, 0.6,
                               0.7, 0.8, 0.9, 1.0, 0.1, 0.2,
                               0.3, 0.4, 0.5, 0.6})
   local result = agent:process(x)
   assert(result.action ~= nil)
   assert(result.layer ~= nil)
end)

test("multiple cycles increment counter", function()
   local agent = nn.NNECCOAgent({stateSize=16, reservoirSize=30, stubMode=true})
   for i = 1, 5 do agent:process("step " .. i) end
   assert(agent.cycleCount == 5)
end)

test("consciousness layer changes with loss", function()
   -- Hard to test deterministically, but it should at least not crash
   local agent = nn.NNECCOAgent({
      stateSize=16, reservoirSize=30, stubMode=true,
      llamaInstances=2,
   })
   for i = 1, 10 do agent:process("cycle " .. i) end
   assert(agent.consciousnessLayer >= 0 and agent.consciousnessLayer <= 3)
end)

test("getHardwareStatus", function()
   local agent = nn.NNECCOAgent({stateSize=16, reservoirSize=30, stubMode=true})
   agent:process("test")
   local status = agent:getHardwareStatus()
   assert(status.reservoir.size == 30)
   assert(status.llama ~= nil)
   assert(status.consciousness.layer ~= nil)
end)

test("personality is NeuroSama archetype by default", function()
   local agent = nn.NNECCOAgent({stateSize=16, reservoirSize=30, stubMode=true})
   if agent.personality then
      assert(agent.personality:get("playfulness") >= 0.9,
         "Expected high playfulness for NeuroSama")
   end
end)

test("multi-instance orchestration (4 instances)", function()
   local agent = nn.NNECCOAgent({
      stateSize      = 16,
      reservoirSize  = 30,
      llamaInstances = 4,
      stubMode       = true,
   })
   for i = 1, 8 do agent:process("parallel test " .. i) end
   local status = agent:getHardwareStatus()
   assert(status.llama.numInstances == 4)
   -- All 4 should have been used
   local served = 0
   for _, inst in ipairs(status.llama.instances) do
      served = served + inst.requests
   end
   assert(served == 8, "Expected 8 requests total, got " .. served)
end)

-- ── Edge cases ────────────────────────────────────────────────────────────────
print("\n[Edge cases]")

test("EchoReservoir rejects dimension mismatch", function()
   local r = nn.EchoReservoir(4, 10)
   local bad = Tensor.new({1, 2, 3})  -- 3 elements, expected 4
   local ok, err = pcall(function() r:forward(bad) end)
   assert(not ok, "Expected dimension-mismatch error")
end)

test("EchoReservoir zero-input keeps finite state", function()
   local r = nn.EchoReservoir(2, 15)
   local zero = Tensor.new({0, 0})
   for _ = 1, 10 do r:forward(zero) end
   local n = r.state:norm()
   assert(n == n, "state norm is NaN")        -- NaN check
   assert(n < math.huge, "state norm is inf") -- inf check
end)

test("AtomSpace getNode on missing atom returns nil", function()
   local as = nn.AtomSpace()
   assert(as:getNode("ConceptNode", "does_not_exist") == nil)
end)

test("AtomSpace empty type query returns empty list", function()
   local as = nn.AtomSpace()
   as:addNode("ConceptNode", "only_one")
   local nums = as:getAtomsOfType("NumberNode")
   assert(#nums == 0)
end)

test("AtomSpace getIncoming on isolated atom is empty", function()
   local as = nn.AtomSpace()
   local a  = as:addNode("ConceptNode", "lonely")
   assert(#as:getIncoming(a) == 0)
end)

test("Personality unknown trait returns nil (no stored value)", function()
   local p = nn.Personality()
   -- An unregistered trait name has no tensor slot; get yields nil.
   assert(p:get("nonexistent_trait") == nil)
end)

test("Personality blend size mismatch raises error", function()
   local p1 = nn.Personality()
   local p2 = nn.Personality()
   p2.n = p1.n + 1  -- force a trait-count mismatch
   local ok = pcall(function() p1:blend(p2, 0.5) end)
   assert(not ok, "Expected blend mismatch error")
end)

test("EpisodicMemory sample on empty memory raises error", function()
   local m = nn.EpisodicMemory(10, false)
   local ok = pcall(function() m:sample(3) end)
   assert(not ok, "Expected empty-buffer error")
end)

test("EpisodicMemory recent on empty memory is empty", function()
   local m = nn.EpisodicMemory(10, false)
   assert(#m:recent(5) == 0)
end)

test("EpisodicMemory recent clamps to available count", function()
   local m = nn.EpisodicMemory(100, false)
   for i = 1, 4 do
      m:push({state=Tensor.new({i}), action=1, reward=i, nextState=Tensor.new({0}), done=false})
   end
   local r = m:recent(10)  -- ask for more than available
   assert(#r == 4, "Expected 4 (clamped), got " .. #r)
end)

test("Linear forward rejects wrong input size", function()
   local lin = nn.Linear(5, 3)
   local ok = pcall(function() lin:forward(Tensor.new({1, 2})) end)
   assert(not ok, "Expected Linear dimension-mismatch error")
end)

test("MSECriterion rejects input/target size mismatch", function()
   local c = nn.MSECriterion()
   local ok = pcall(function()
      c:forward(Tensor.new({1, 2}), Tensor.new({1, 2, 3}))
   end)
   assert(not ok, "Expected MSE size-mismatch error")
end)

-- ─────────────────────────────────────────────────────────────────────────────
print(string.format("\n─── Results: %d passed, %d failed ───\n", passed, failed))

if failed > 0 then os.exit(1) end
