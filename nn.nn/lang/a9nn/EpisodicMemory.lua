-- a9nn/EpisodicMemory.lua
-- Episodic memory store with importance-weighted retrieval.
--
-- Memories are stored as {state, action, reward, nextState, info} tuples
-- (standard RL experience tuples) plus optional free-form metadata.
-- Retrieval can be by recency, importance, or similarity.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

local EpisodicMemory, _ = Class.class('nn.EpisodicMemory')

--- @param capacity   maximum number of memories (default 1000)
--- @param prioritised  use priority-weighted sampling (default true)
function EpisodicMemory:__init(capacity, prioritised)
   self.capacity    = capacity or 1000
   self.prioritised = (prioritised == nil) and true or prioritised
   self.buffer      = {}       -- circular buffer of experience tables
   self.priorities  = {}       -- parallel priority array
   self.head        = 1        -- write pointer
   self.count       = 0        -- current fill level
   self.alpha       = 0.6      -- priority exponent
   self.beta        = 0.4      -- importance-sampling exponent
   self.eps         = 1e-6     -- small constant to avoid zero priority
   self.maxPriority = 1.0
end

--- Store a new experience.
-- @param experience  table with fields: state, action, reward, next_state, done
-- @param priority    optional initial priority (defaults to max seen so far)
function EpisodicMemory:push(experience, priority)
   priority = priority or self.maxPriority
   self.buffer[self.head]     = experience
   self.priorities[self.head] = priority
   self.maxPriority = math.max(self.maxPriority, priority)
   self.head  = (self.head % self.capacity) + 1
   self.count = math.min(self.count + 1, self.capacity)
end

--- Sample a batch of `n` experiences.
-- @param n    batch size
-- @return     table of experience tables, table of indices, table of IS-weights
function EpisodicMemory:sample(n)
   n = math.min(n, self.count)
   assert(n > 0, "EpisodicMemory: empty buffer")

   local experiences = {}
   local indices     = {}
   local weights     = {}

   if self.prioritised then
      -- Compute probability distribution
      local prioSum = 0
      for i = 1, self.count do
         prioSum = prioSum + (self.priorities[i]^self.alpha)
      end

      local minProb = (self.eps^self.alpha) / prioSum
      local maxW    = (minProb * self.count)^(-self.beta)

      -- Sample without replacement using a simple alias-free approach
      local chosen = {}
      local chosenSet = {}
      while #chosen < n do
         local r    = math.random() * prioSum
         local cum  = 0
         local added = false
         for i = 1, self.count do
            cum = cum + (self.priorities[i]^self.alpha)
            if cum >= r and not chosenSet[i] then
               chosen[#chosen+1] = i
               chosenSet[i]      = true
               added = true
               break
            end
         end
         -- safety: if weighted-random walk found no unchosen item
         -- (can happen when all items are already chosen), pick a random one
         if not added then
            for _ = 1, self.count do
               local idx = math.random(self.count)
               if not chosenSet[idx] then
                  chosen[#chosen+1] = idx
                  chosenSet[idx]    = true
                  added = true
                  break
               end
            end
            -- If still not added (all items exhausted), break to avoid infinite loop
            if not added then break end
         end
      end

      for k, idx in ipairs(chosen) do
         local prob = (self.priorities[idx]^self.alpha) / prioSum
         local w    = ((prob * self.count)^(-self.beta)) / maxW
         experiences[k] = self.buffer[idx]
         indices[k]     = idx
         weights[k]     = w
      end
   else
      -- Uniform random sampling
      local pool = {}
      for i = 1, self.count do pool[i] = i end
      -- Fisher-Yates shuffle first n
      for i = 1, n do
         local j = math.random(i, #pool)
         pool[i], pool[j] = pool[j], pool[i]
      end
      for k = 1, n do
         experiences[k] = self.buffer[pool[k]]
         indices[k]     = pool[k]
         weights[k]     = 1.0
      end
   end

   return experiences, indices, weights
end

--- Update priorities for a batch (after computing TD errors, for example).
function EpisodicMemory:updatePriorities(indices, priorities)
   for k, idx in ipairs(indices) do
      self.priorities[idx] = math.abs(priorities[k]) + self.eps
      self.maxPriority = math.max(self.maxPriority, self.priorities[idx])
   end
end

--- Return the most recent `n` experiences in order.
function EpisodicMemory:recent(n)
   n = math.min(n, self.count)
   local out = {}
   -- head points one past the last write
   local start = self.head - 1
   for i = 0, n-1 do
      local idx = ((start - i - 1) % self.capacity) + 1
      table.insert(out, self.buffer[idx])
   end
   return out
end

--- Retrieve memories similar to a query state (cosine similarity).
-- @param queryState  Tensor
-- @param n           number of results
-- @return            table of {similarity, experience} sorted descending
function EpisodicMemory:retrieveSimilar(queryState, n)
   n = math.min(n, self.count)
   local scored = {}
   local qnorm  = queryState:norm()
   if qnorm < 1e-10 then qnorm = 1 end

   for i = 1, self.count do
      local exp = self.buffer[i]
      if exp and exp.state then
         local s    = exp.state
         local snorm = s:norm()
         if snorm < 1e-10 then snorm = 1 end
         local dot  = queryState:cmul(s):sum()
         local sim  = dot / (qnorm * snorm)
         scored[#scored+1] = {sim = sim, exp = exp, idx = i}
      end
   end

   table.sort(scored, function(a,b) return a.sim > b.sim end)

   local out = {}
   for i = 1, n do out[i] = scored[i] end
   return out
end

function EpisodicMemory:size()  return self.count end
function EpisodicMemory:isFull() return self.count >= self.capacity end

function EpisodicMemory:__tostring()
   return string.format("nn.EpisodicMemory(cap=%d, used=%d)",
      self.capacity, self.count)
end

return EpisodicMemory
