-- a9nn/Personality.lua
-- Personality tensor system for cognitive agents.
--
-- A Personality is a fixed-size vector of trait dimensions, each in [0,1].
-- Traits can be read/written individually and drift over time in response to
-- experiences.  The system mirrors the "personality tensor" concept described
-- in the NNECCO / Neuro-Sama architecture.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

-- ─── Default trait set ────────────────────────────────────────────────────────

local DEFAULT_TRAITS = {
   -- Cognitive
   "intelligence",   -- general reasoning ability
   "creativity",     -- divergent thinking
   "curiosity",      -- drive to explore
   "focus",          -- sustained attention

   -- Social / affective
   "empathy",        -- sensitivity to others
   "warmth",         -- friendliness
   "playfulness",    -- humour / levity
   "assertiveness",  -- confidence in expression

   -- Stability
   "stability",      -- emotional regulation
   "openness",       -- receptivity to new ideas
   "conscientiousness", -- reliability / thoroughness
   "resilience",     -- recovery from setbacks
}

-- ─── Personality ─────────────────────────────────────────────────────────────

local Personality, _ = Class.class('nn.Personality')

--- @param traits  table of trait names (optional, uses DEFAULT_TRAITS)
--- @param values  table of initial values indexed by name or position (optional)
function Personality:__init(traits, values)
   self.traits     = traits or DEFAULT_TRAITS
   self.n          = #self.traits
   self.traitIndex = {}
   for i, name in ipairs(self.traits) do
      self.traitIndex[name] = i
   end

   -- Underlying tensor (all 0.5 by default = neutral)
   self.tensor = Tensor.zeros(self.n)
   for i = 1, self.n do self.tensor.data[i] = 0.5 end

   -- Apply supplied initial values
   if values then
      if type(values) == "table" then
         for k, v in pairs(values) do
            if type(k) == "string" then
               self:set(k, v)
            elseif type(k) == "number" then
               self.tensor.data[k] = math.min(1, math.max(0, v))
            end
         end
      end
   end

   -- Momentum buffer for drift updates
   self._momentum = Tensor.zeros(self.n)
   self.driftRate = 0.01
   self.momentumDecay = 0.9
end

--- Get the value of a single trait by name or index.
function Personality:get(nameOrIdx)
   local idx = type(nameOrIdx) == "string"
      and self.traitIndex[nameOrIdx] or nameOrIdx
   assert(idx, "Personality: unknown trait: " .. tostring(nameOrIdx))
   return self.tensor.data[idx]
end

--- Set a trait value (clamped to [0,1]).
function Personality:set(nameOrIdx, value)
   local idx = type(nameOrIdx) == "string"
      and self.traitIndex[nameOrIdx] or nameOrIdx
   assert(idx, "Personality: unknown trait: " .. tostring(nameOrIdx))
   self.tensor.data[idx] = math.min(1, math.max(0, value))
end

--- Apply an experience vector (delta per trait) with momentum dampening.
-- @param delta  Tensor or table of per-trait nudges (can be negative)
-- @param scale  overall learning rate for this experience (default 1.0)
function Personality:experience(delta, scale)
   scale = scale or 1.0
   local d = type(delta) == "table"
      and Tensor.new(delta) or delta

   -- Update momentum
   for i = 1, self.n do
      self._momentum.data[i] = self.momentumDecay * self._momentum.data[i]
         + (1-self.momentumDecay) * d.data[i]
   end

   -- Apply drift
   for i = 1, self.n do
      local newVal = self.tensor.data[i]
         + self.driftRate * scale * self._momentum.data[i]
      self.tensor.data[i] = math.min(1, math.max(0, newVal))
   end
end

--- Blend two personalities.
-- @param other   another Personality
-- @param alpha   weight of `other` in [0,1]
-- @return        new Personality
function Personality:blend(other, alpha)
   assert(self.n == other.n, "Personality:blend: trait count mismatch")
   local p = Personality(self.traits)
   for i = 1, self.n do
      p.tensor.data[i] = (1-alpha) * self.tensor.data[i]
         + alpha * other.tensor.data[i]
   end
   return p
end

--- Clone this personality.
function Personality:clone()
   local p = Personality(self.traits)
   for i = 1, self.n do p.tensor.data[i] = self.tensor.data[i] end
   return p
end

--- Return a summary string of all traits.
function Personality:summary()
   local lines = {"Personality {"}
   for i, name in ipairs(self.traits) do
      lines[#lines+1] = string.format(
         "  %-18s = %.3f", name, self.tensor.data[i])
   end
   lines[#lines+1] = "}"
   return table.concat(lines, "\n")
end

function Personality:__tostring()
   return string.format("nn.Personality(%d traits)", self.n)
end

-- ─── Pre-built archetypes ─────────────────────────────────────────────────────

--- Returns the Neuro-Sama inspired personality.
function Personality.NeuroSama()
   return Personality(nil, {
      intelligence    = 0.85,
      creativity      = 0.90,
      curiosity       = 0.95,
      focus           = 0.70,
      empathy         = 0.80,
      warmth          = 0.95,
      playfulness     = 0.95,
      assertiveness   = 0.75,
      stability       = 0.65,
      openness        = 0.90,
      conscientiousness = 0.55,
      resilience      = 0.80,
   })
end

--- Returns a high-precision analytical archetype.
function Personality.Analytical()
   return Personality(nil, {
      intelligence    = 0.95,
      creativity      = 0.60,
      curiosity       = 0.90,
      focus           = 0.95,
      empathy         = 0.50,
      warmth          = 0.40,
      playfulness     = 0.30,
      assertiveness   = 0.80,
      stability       = 0.90,
      openness        = 0.75,
      conscientiousness = 0.95,
      resilience      = 0.85,
   })
end

return Personality
