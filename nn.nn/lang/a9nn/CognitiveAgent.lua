-- a9nn/CognitiveAgent.lua
-- Multi-agent cognitive orchestrator.
-- A CognitiveAgent can spawn subordinate agents, delegate tasks to them,
-- and aggregate their outputs using a learned aggregation policy.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

local CognitiveAgent, parent = Class.class('nn.CognitiveAgent', 'nn.Agent')

local _agentRegistry = {}   -- id → agent
local _nextID        = 1

local function allocID()
   local id = _nextID
   _nextID  = _nextID + 1
   return id
end

--- Constructor.
-- @param opts  same as nn.Agent plus:
--   maxSubordinates  maximum number of sub-agents to spawn (default 4)
--   role             string descriptor of this agent's role
--   personalityOpts  table passed to nn.Personality constructor
function CognitiveAgent:__init(opts)
   parent.__init(self, opts)
   opts = opts or {}

   self.id              = allocID()
   self.role            = opts.role or "generalist"
   self.maxSubordinates = opts.maxSubordinates or 4
   self.subordinates    = {}  -- id → CognitiveAgent
   self.parentID        = nil

   -- Personality
   local Personality = Class.get('nn.Personality')
   if Personality then
      self.personality = Personality(nil, opts.personalityOpts)
   end

   -- AtomSpace knowledge store
   local AtomSpace = Class.get('nn.AtomSpace')
   if AtomSpace then
      self.knowledge = AtomSpace()
   end

   -- Task queue and results
   self.taskQueue   = {}
   self.taskResults = {}

   -- Register self
   _agentRegistry[self.id] = self

   self.verbose = opts.verbose or false
end

--- Spawn a new subordinate agent.
-- @param opts   constructor options for the sub-agent
-- @return       the new CognitiveAgent
function CognitiveAgent:spawnSubordinate(opts)
   assert(self:_countSubs() < self.maxSubordinates,
      string.format("CognitiveAgent %d: max subordinates (%d) reached",
         self.id, self.maxSubordinates))

   opts = opts or {}
   -- Inherit state / action sizes by default
   opts.stateSize  = opts.stateSize  or self.stateSize
   opts.actionSize = opts.actionSize or self.actionSize

   -- Optionally inherit / mutate personality
   if self.personality and opts.personalityOverrides then
      local Personality = Class.get('nn.Personality')
      local p = self.personality:clone()
      for k, v in pairs(opts.personalityOverrides) do
         p:set(k, v)
      end
      opts.personalityOpts = nil  -- already built
   end

   local sub = CognitiveAgent(opts)
   sub.parentID = self.id

   self.subordinates[sub.id] = sub
   _agentRegistry[sub.id]    = sub

   if self.verbose then
      print(string.format(
         "[CognitiveAgent %d] Spawned subordinate %d (role=%s)",
         self.id, sub.id, sub.role))
   end

   return sub
end

--- Delegate a task to a subordinate (or self if no suitable sub found).
-- @param task       table: {type, input, priority}
-- @param targetID   id of target sub-agent (optional; auto-selects if nil)
-- @return           task result table
function CognitiveAgent:delegate(task, targetID)
   local agent
   if targetID then
      agent = self.subordinates[targetID]
      assert(agent, "CognitiveAgent:delegate: unknown subordinate " .. tostring(targetID))
   else
      -- Pick least busy subordinate
      local best, bestLoad = nil, math.huge
      for _, sub in pairs(self.subordinates) do
         local load = #sub.taskQueue
         if load < bestLoad then best = sub; bestLoad = load end
      end
      agent = best or self
   end

   return agent:handleTask(task)
end

--- Handle an incoming task.
-- @param task  table: {type, input, priority}
-- @return      result table
function CognitiveAgent:handleTask(task)
   task = task or {}
   local taskType = task.type or "generic"
   local input    = task.input

   local result = {
      agentID  = self.id,
      role     = self.role,
      taskType = taskType,
      success  = true,
   }

   if taskType == "infer" and input then
      -- Run forward pass through policy network
      local qvals = self.policy:forward(input)
      result.output  = qvals
      result.action  = self:act(input)

   elseif taskType == "remember" and input then
      local exp = input
      self:remember(exp.state, exp.action, exp.reward,
                    exp.nextState, exp.done)
      result.stored = true

   elseif taskType == "learn" then
      local loss = self:learn()
      result.loss = loss

   elseif taskType == "knowledge_query" and self.knowledge and input then
      local atoms = self.knowledge:getAtomsOfType(input.atomType or "ConceptNode")
      result.atoms = atoms

   elseif taskType == "knowledge_add" and self.knowledge and input then
      if input.nodeType then
         result.atom = self.knowledge:addNode(input.nodeType, input.name, input.tv)
      elseif input.linkType then
         result.atom = self.knowledge:addLink(input.linkType, input.outgoing, input.tv)
      end

   else
      result.output  = nil
      result.message = string.format("Agent %d: unhandled task type '%s'",
         self.id, taskType)
   end

   self.taskResults[#self.taskResults+1] = result
   return result
end

--- Broadcast a task to ALL subordinates and collect results.
function CognitiveAgent:broadcast(task)
   local results = {}
   for _, sub in pairs(self.subordinates) do
      results[#results+1] = sub:handleTask(task)
   end
   return results
end

--- Aggregate Q-values from all subordinates (majority vote).
-- @param state  Tensor
-- @return       integer action index
function CognitiveAgent:aggregateVote(state)
   local votes = {}
   for a = 1, self.actionSize do votes[a] = 0 end

   -- Self vote
   local selfAction = self:act(state)
   votes[selfAction] = votes[selfAction] + 1

   for _, sub in pairs(self.subordinates) do
      local a = sub:act(state)
      votes[a] = votes[a] + 1
   end

   local bestA, bestV = 1, 0
   for a, v in ipairs(votes) do
      if v > bestV then bestV = v; bestA = a end
   end
   return bestA
end

--- Return summary of agent and subordinates.
function CognitiveAgent:summary()
   local lines = {
      string.format("CognitiveAgent id=%d role=%s subs=%d eps=%.3f",
         self.id, self.role, self:_countSubs(), self.epsilon),
   }
   for _, sub in pairs(self.subordinates) do
      lines[#lines+1] = string.format(
         "  └─ sub id=%d role=%s eps=%.3f",
         sub.id, sub.role, sub.epsilon)
   end
   return table.concat(lines, "\n")
end

--- Look up a registered agent by id.
function CognitiveAgent.getById(id)
   return _agentRegistry[id]
end

function CognitiveAgent:__tostring__()
   return string.format("nn.CognitiveAgent(id=%d, role=%s, subs=%d)",
      self.id, self.role, self:_countSubs())
end

function CognitiveAgent:_countSubs()
   local n = 0
   for _ in pairs(self.subordinates) do n = n + 1 end
   return n
end

return CognitiveAgent
