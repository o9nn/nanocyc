-- a9nn/Agent.lua
-- Base reinforcement-learning agent.
-- Mirrors the nn.Module interface so agents can be composed and trained
-- using the same machinery as neural network modules.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

local Agent, parent = Class.class('nn.Agent', 'nn.Module')

--- @param opts  table:
--   stateSize    dimensionality of environment state
--   actionSize   number of discrete actions (or continuous action dim)
--   gamma        discount factor (default 0.99)
--   epsilon      ε-greedy exploration rate (default 0.1)
function Agent:__init(opts)
   parent.__init(self)
   opts = opts or {}

   self.stateSize   = opts.stateSize  or 4
   self.actionSize  = opts.actionSize or 2
   self.gamma       = opts.gamma      or 0.99
   self.epsilon     = opts.epsilon    or 0.1
   self.epsilonMin  = opts.epsilonMin or 0.01
   self.epsilonDecay = opts.epsilonDecay or 0.995

   -- Policy network: a simple MLP
   local Sequential = Class.get('nn.Sequential')
   local Linear     = Class.get('nn.Linear')
   local ReLU       = Class.get('nn.ReLU')
   local hidden     = opts.hiddenSize or 64

   self.policy = Sequential()
   self.policy:add(Linear(self.stateSize, hidden))
   self.policy:add(ReLU())
   self.policy:add(Linear(hidden, hidden))
   self.policy:add(ReLU())
   self.policy:add(Linear(hidden, self.actionSize))

   -- Experience replay memory
   local EpisodicMemory = Class.get('nn.EpisodicMemory')
   self.memory     = EpisodicMemory(opts.memoryCapacity or 10000)
   self.batchSize  = opts.batchSize  or 32
   self.learningRate = opts.learningRate or 1e-3

   -- Criterion for Q-learning
   local MSE = Class.get('nn.MSECriterion')
   self.criterion = MSE()

   self.stepCount = 0
   self.episodeCount = 0
end

--- Select an action given a state using ε-greedy policy.
-- @param state  Tensor of shape (stateSize,)
-- @return       integer action index (1-indexed)
function Agent:act(state)
   if math.random() < self.epsilon then
      return math.random(self.actionSize)
   end
   local qvals = self.policy:forward(state)
   -- argmax
   local bestA, bestQ = 1, -math.huge
   for a = 1, self.actionSize do
      if qvals.data[a] > bestQ then bestQ = qvals.data[a]; bestA = a end
   end
   return bestA
end

--- Store a transition in memory.
function Agent:remember(state, action, reward, nextState, done)
   self.memory:push({
      state     = state,
      action    = action,
      reward    = reward,
      nextState = nextState,
      done      = done and true or false,
   })
end

--- Sample a mini-batch and perform one Q-learning update.
-- @return  loss value (number) or nil if memory too small
function Agent:learn()
   if self.memory:size() < self.batchSize then return nil end

   local exps, _, _ = self.memory:sample(self.batchSize)

   local totalLoss = 0
   for _, exp in ipairs(exps) do
      -- Compute target Q value
      local targetQ
      if exp.done then
         targetQ = exp.reward
      else
         local nextQ = self.policy:forward(exp.nextState)
         local maxNQ = nextQ:max()
         targetQ = exp.reward + self.gamma * maxNQ
      end

      -- Compute current Q values and update only the taken action
      local qvals  = self.policy:forward(exp.state)
      local target = qvals:clone()
      target.data[exp.action] = targetQ

      local loss = self.criterion:forward(qvals, target)
      totalLoss  = totalLoss + loss

      local grad = self.criterion:backward(qvals, target)
      self.policy:zeroGradParameters()
      self.policy:backward(exp.state, grad)
      self.policy:updateParameters(self.learningRate)
   end

   -- Decay epsilon
   if self.epsilon > self.epsilonMin then
      self.epsilon = self.epsilon * self.epsilonDecay
   end

   self.stepCount = self.stepCount + 1
   return totalLoss / self.batchSize
end

--- Run one full episode on an environment.
-- @param env     table with :reset() → state, :step(action) → state,reward,done
-- @param maxSteps  maximum steps per episode (default 1000)
-- @return          total episode reward
function Agent:runEpisode(env, maxSteps)
   maxSteps = maxSteps or 1000
   local state      = env:reset()
   local totalReward = 0
   local done        = false
   local step        = 0

   while not done and step < maxSteps do
      local action        = self:act(state)
      local nextState, reward, d = env:step(action)
      self:remember(state, action, reward, nextState, d)
      self:learn()
      state       = nextState
      totalReward = totalReward + reward
      done        = d
      step        = step + 1
   end

   self.episodeCount = self.episodeCount + 1
   return totalReward
end

function Agent:__tostring__()
   return string.format(
      "nn.Agent(state=%d, actions=%d, ε=%.4f)",
      self.stateSize, self.actionSize, self.epsilon)
end

return Agent
