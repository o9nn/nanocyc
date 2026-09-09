-- a9nn/examples/nnecco_example.lua
-- Demonstrates the full NNECCO cognitive agent pipeline:
--   • Echo State Reservoir processing
--   • Multi-layer consciousness
--   • Parallel LLaMA orchestration (stub mode)
--   • Personality system
--   • Knowledge graph
--   • Multi-agent delegation
-- Run with:  lua examples/nnecco_example.lua  (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
local base = arg and arg[0] and arg[0]:match("(.+)/examples/") or "."
addPath(base .. "/..")
addPath(base)

local nn = require('a9nn')

math.randomseed(7)
local Tensor = nn.Tensor

print()
print("╔══════════════════════════════════════════════════════════════╗")
print("║       a9nn  NNECCO Cognitive Agent Demo                     ║")
print("╚══════════════════════════════════════════════════════════════╝")
print()

-- ─── 1. Create the NNECCO agent ───────────────────────────────────────────────

print("┌─ 1. Initialising NNECCOAgent ─────────────────────────────────")

local agent = nn.NNECCOAgent({
   stateSize            = 32,
   actionSize           = 6,
   reservoirSize        = 200,
   llamaInstances       = 3,      -- 3 parallel LLaMA instances (stub)
   stubMode             = true,   -- no real llama.cpp required
   personalityArchetype = "NeuroSama",
   verbose              = false,
})

print(string.format("│  Agent id=%d  reservoir=%d  instances=%d",
   agent.id, agent.reservoir.reservoirN, agent.llama.numInstances))

if agent.personality then
   print("│  Personality:")
   for _, t in ipairs({"curiosity","warmth","playfulness","intelligence"}) do
      print(string.format("│    %-18s = %.2f", t, agent.personality:get(t)))
   end
end
print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 2. Spawn subordinate agents ─────────────────────────────────────────────

print("┌─ 2. Spawning subordinate agents ──────────────────────────────")

local sub1 = agent:spawnSubordinate({
   role = "reasoning_specialist",
   personalityOverrides = {intelligence = 0.98, focus = 0.95},
})
local sub2 = agent:spawnSubordinate({
   role = "creative_writer",
   personalityOverrides = {creativity = 0.97, playfulness = 0.92},
})

print(string.format("│  Sub-agent 1: id=%d  role=%s", sub1.id, sub1.role))
print(string.format("│  Sub-agent 2: id=%d  role=%s", sub2.id, sub2.role))
print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 3. Run EchoBeats cognitive cycles ───────────────────────────────────────

print("┌─ 3. EchoBeats Cognitive Cycles ───────────────────────────────")

local inputs = {
   "What is the nature of consciousness?",
   "Explain gradient descent in neural networks.",
   "How does an Echo State Network achieve memory?",
   "Write a haiku about artificial intelligence.",
   "Describe the OpenCog AtomSpace data model.",
}

for i, prompt in ipairs(inputs) do
   local result = agent:process(prompt)
   print(string.format("│  [cycle %d] %-40s", i, prompt:sub(1, 40)))
   print(string.format("│    action=%d  layer=%-10s  llama=%d",
      result.action or 0,
      result.layer or "?",
      agent.llama:getStatus().instances[1].requests))
   if result.output and result.output.text then
      print(string.format("│    → %s", result.output.text:sub(1, 70)))
   end
   if i < #inputs then print("│") end
end

print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 4. Delegate to subordinates ─────────────────────────────────────────────

print("┌─ 4. Task Delegation ──────────────────────────────────────────")

local state = Tensor.zeros(32)
for i = 1, 32 do state.data[i] = math.random() - 0.5 end

local r1 = agent:delegate({type="infer", input=state}, sub1.id)
local r2 = agent:delegate({type="infer", input=state}, sub2.id)

print(string.format("│  Sub1 infer → action=%d", r1.action or 0))
print(string.format("│  Sub2 infer → action=%d", r2.action or 0))

-- Aggregate vote
local vote = agent:aggregateVote(state)
print(string.format("│  Aggregate vote → action=%d", vote))

print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 5. Knowledge graph operations ───────────────────────────────────────────

print("┌─ 5. AtomSpace Knowledge Graph ────────────────────────────────")

local as    = agent.knowledge
local nnConcept  = as:addNode("ConceptNode", "NeuralNetwork",
   nn.TruthValue.new(0.99, 100))
local esnConcept = as:addNode("ConceptNode", "EchoStateNetwork",
   nn.TruthValue.new(0.95, 50))
local aiConcept  = as:addNode("ConceptNode", "ArtificialIntelligence",
   nn.TruthValue.new(1.0, 200))

as:addLink("InheritanceLink", {nnConcept, aiConcept},
   nn.TruthValue.new(0.9, 80))
as:addLink("InheritanceLink", {esnConcept, nnConcept},
   nn.TruthValue.new(0.85, 60))
as:addLink("RelatedTo", {esnConcept, nnConcept})

print(string.format("│  AtomSpace size: %d atoms", as:size()))
print(string.format("│  ConceptNodes: %d",
   #as:getAtomsOfType("ConceptNode")))
print(string.format("│  InheritanceLinks: %d",
   #as:getAtomsOfType("InheritanceLink")))

local incoming = as:getIncoming(nnConcept)
print(string.format("│  Links referencing NeuralNetwork: %d", #incoming))

print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 6. Hardware status ───────────────────────────────────────────────────────

print("┌─ 6. Hardware Status Registers ────────────────────────────────")

local status = agent:getHardwareStatus()

print(string.format("│  Agent ID   : %d", status.agentID))
print(string.format("│  Cycles     : %d", status.cycle))
print(string.format("│  Reservoir  : %d neurons, sr=%.2f, leak=%.2f",
   status.reservoir.size,
   status.reservoir.spectralRadius,
   status.reservoir.leakRate))
print(string.format("│  Consciousness: L%d (%s)",
   status.consciousness.layer, status.consciousness.name))
print(string.format("│  Memory     : %d / %d",
   status.memory.size, status.memory.capacity))
print(string.format("│  Epsilon    : %.4f (steps=%d)",
   status.policy.epsilon, status.policy.steps))
print("│  Emotions:")
for name, v in pairs(status.emotions) do
   if v > 0.3 then
      print(string.format("│    %-18s = %.3f", name, v))
   end
end
print("│  LLaMA instances:")
for _, inst in ipairs(status.llama.instances) do
   print(string.format("│    inst %d  port=%d  req=%d  tokens=%d",
      inst.id, inst.port, inst.requests, inst.tokensServed))
end
print("│  EchoBeats metrics:")
for beat, count in pairs(status.beatMetrics) do
   if count > 0 then
      print(string.format("│    %-12s %d", beat, count))
   end
end

print("└───────────────────────────────────────────────────────────────")
print()

-- ─── 7. ESN temporal example ─────────────────────────────────────────────────

print("┌─ 7. Echo State Network – temporal XOR task ───────────────────")

local esn     = nn.EchoReservoir(1, 50, {spectralRadius=0.85, leakRate=0.8})
local readout = nn.Linear(50, 1)
local mse     = nn.MSECriterion()

-- Generate XOR-like sequence: output at t = input[t] XOR input[t-2]
local T     = 100
local seq   = {}
local labels = {}
local prev2 = 0
for t = 1, T do
   local bit  = math.random(0,1)
   seq[t]     = Tensor.new({bit * 2.0 - 1.0})  -- ±1
   if t > 2 then
      labels[t] = Tensor.new({(bit ~= prev2) and 1.0 or -1.0})
   else
      labels[t] = Tensor.new({0.0})
   end
   if t == 1 then prev2 = bit end
end

local losses = {}
local trainLR = 0.005
for epoch = 1, 30 do
   esn:resetState()
   local epochLoss = 0
   for t = 1, T do
      local res  = esn:forward(seq[t])
      local pred = readout:forward(res)
      local loss = mse:forward(pred, labels[t])
      epochLoss  = epochLoss + loss
      local grad = mse:backward(pred, labels[t])
      readout:zeroGradParameters()
      readout:backward(res, grad)
      readout:updateParameters(trainLR)
   end
   losses[epoch] = epochLoss / T
end

print(string.format("│  Initial loss: %.4f", losses[1]))
print(string.format("│  Final loss  : %.4f", losses[#losses]))
print(string.format("│  Improvement : %.1f%%",
   (losses[1] - losses[#losses]) / losses[1] * 100))
print("└───────────────────────────────────────────────────────────────")
print()

print("╔══════════════════════════════════════════════════════════════╗")
print("║  Demo complete.                                              ║")
print("╚══════════════════════════════════════════════════════════════╝")
print()
