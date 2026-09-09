-- a9nn/examples/multi_agent_example.lua
-- Demonstrates a 9-instance parallel LLaMA orchestration with a hierarchy
-- of CognitiveAgents solving tasks collaboratively.
-- Run with:  lua examples/multi_agent_example.lua  (from lang/a9nn/)

local function addPath(p)
   package.path = p .. "/?.lua;" .. p .. "/?/init.lua;" .. package.path
end
local base = arg and arg[0] and arg[0]:match("(.+)/examples/") or "."
addPath(base .. "/..")
addPath(base)

local nn = require('a9nn')

math.randomseed(99)
local Tensor = nn.Tensor

print()
print("╔══════════════════════════════════════════════════════════════╗")
print("║   a9nn  Multi-Agent Orchestration (9 LLaMA instances)       ║")
print("╚══════════════════════════════════════════════════════════════╝")
print()

-- ─── Orchestrator: 9 parallel LLaMA instances ────────────────────────────────

print("┌─ Setting up 9-instance LLaMA orchestrator ───────────────────")
local orch = nn.LLaMAOrchestrator({
   numInstances = 9,
   basePort     = 8080,
   stubMode     = true,
})
orch:initialize()

local status = orch:getStatus()
print(string.format("│  Instances: %d  Available: %d  Stub: %s",
   status.numInstances, status.available, tostring(status.stubMode)))
print("└───────────────────────────────────────────────────────────────")
print()

-- ─── Agent hierarchy ─────────────────────────────────────────────────────────

print("┌─ Building agent hierarchy ─────────────────────────────────── ")

-- Root orchestrator agent
local root = nn.CognitiveAgent({
   stateSize  = 16,
   actionSize = 4,
   role       = "orchestrator",
   maxSubordinates = 8,
})

-- Spawn 4 domain-specialist sub-agents
local roles = {
   "perception_specialist",
   "reasoning_specialist",
   "planning_specialist",
   "memory_specialist",
}

local subs = {}
for _, role in ipairs(roles) do
   local sub = root:spawnSubordinate({
      role       = role,
      stateSize  = 16,
      actionSize = 4,
   })
   subs[#subs+1] = sub
   print(string.format("│  + Sub-agent id=%-3d  role=%s", sub.id, role))
end

-- Each specialist can spawn its own sub-agent
for _, sub in ipairs(subs) do
   sub:spawnSubordinate({role = sub.role .. "_assistant", stateSize=16, actionSize=4})
end

print(string.format("│  Total agents in tree: %d", 1 + #subs + #subs))
print("└───────────────────────────────────────────────────────────────")
print()

-- ─── Simulate a multi-round decision task ────────────────────────────────────

print("┌─ Multi-round decision simulation ────────────────────────────")

local states = {}
for i = 1, 8 do
   local s = Tensor.zeros(16)
   for j = 1, 16 do s.data[j] = math.random() - 0.5 end
   states[i] = s
end

for round = 1, 4 do
   local state = states[round]
   print(string.format("│  Round %d:", round))

   -- Broadcast to all sub-agents
   local results = root:broadcast({type="infer", input=state})
   local votes = {}
   for a = 1, 4 do votes[a] = 0 end
   for _, r in ipairs(results) do
      if r.action and votes[r.action] then
         votes[r.action] = votes[r.action] + 1
      end
   end

   -- Find consensus action
   local bestA, bestV = 1, 0
   for a, v in ipairs(votes) do
      if v > bestV then bestV = v; bestA = a end
   end

   -- Also run root's own inference
   local rootAction = root:act(state)

   -- LLaMA reasoning (distributed across 9 instances)
   local prompt = string.format(
      "[Round %d] State norm=%.3f  Subagent consensus=action_%d  Root=action_%d  Decide:",
      round, state:norm(), bestA, rootAction)
   local llamaResp = orch:generate(prompt, {max_tokens=48})

   print(string.format("│    Sub-agent votes: %s",
      table.concat(
         (function()
            local t={}
            for a,v in ipairs(votes) do t[#t+1]=string.format("a%d=%d",a,v) end
            return t
         end)(), " "
      )
   ))
   print(string.format("│    Root action  : %d", rootAction))
   print(string.format("│    LLaMA (inst %d): %s",
      llamaResp.instance_id, llamaResp.text:sub(1,55)))
   print(string.format("│    Final decision: action_%d (consensus)", bestA))
   print("│")
end

print("└───────────────────────────────────────────────────────────────")
print()

-- ─── Parallel batch generation ───────────────────────────────────────────────

print("┌─ Parallel batch inference (9 prompts → 9 instances) ─────────")

local prompts = {}
for i = 1, 9 do
   prompts[i] = string.format("Cognitive query %d: analyse pattern %d", i, i*7%11)
end

local t0 = os.clock()
local results = orch:batchGenerate(prompts, {max_tokens=32})
local elapsed = math.floor((os.clock() - t0) * 1000)

for i, r in ipairs(results) do
   print(string.format("│  [%d] inst=%-2d  %s",
      i, r.instance_id or 0, r.text:sub(1, 50)))
end

local finalStatus = orch:getStatus()
print("│")
print(string.format("│  Total requests per instance:"))
for _, inst in ipairs(finalStatus.instances) do
   print(string.format("│    inst %d  port=%d  req=%-4d  tokens=%d",
      inst.id, inst.port, inst.requests, inst.tokensServed))
end
print(string.format("│  Batch completed in %d ms (simulated)", elapsed))
print("└───────────────────────────────────────────────────────────────")
print()

print("╔══════════════════════════════════════════════════════════════╗")
print("║  Multi-agent example complete.                              ║")
print("╚══════════════════════════════════════════════════════════════╝")
print()
