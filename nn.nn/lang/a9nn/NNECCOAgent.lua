-- a9nn/NNECCOAgent.lua
-- Neural Network Embodied Cognitive Coprocessor Orchestrator agent.
--
-- Integrates:
--   • Echo State Reservoir Network for temporal processing
--   • Multi-layer consciousness pipeline (L0-L3)
--   • Emotion Processing Unit
--   • OpenCog AtomSpace knowledge graph
--   • Personality system
--   • Parallel LLaMA.cpp orchestration (1-9 instances)
--   • EchoBeats 12-step cognitive loop
--   • Hardware-style register interface

local ns     = require('a9nn.nn_ns')
local Tensor = ns.Tensor
local Class  = ns.Class
local nn     = ns   -- alias; TruthValue resolved lazily below

local NNECCOAgent, parent = Class.class('nn.NNECCOAgent', 'nn.CognitiveAgent')

-- ─── EchoBeats step names ─────────────────────────────────────────────────────

local ECHO_BEATS = {
   "PERCEIVE",    -- 1  raw sensory input
   "FILTER",      -- 2  attentional filtering
   "RESONATE",    -- 3  reservoir echo
   "ENCODE",      -- 4  semantic encoding
   "RECALL",      -- 5  episodic memory lookup
   "REASON",      -- 6  LLaMA inference
   "EMOTE",       -- 7  emotion update
   "PLAN",        -- 8  action selection
   "LEARN",       -- 9  RL update
   "REFLECT",     -- 10 meta-cognition
   "EXPRESS",     -- 11 output generation
   "INTEGRATE",   -- 12 state integration
}

-- ─── Consciousness layers ─────────────────────────────────────────────────────

local CONSCIOUSNESS_LAYERS = {
   [0] = "DORMANT",
   [1] = "REACTIVE",
   [2] = "DELIBERATE",
   [3] = "META",
}

-- ─── Emotion channels ─────────────────────────────────────────────────────────

local EMOTIONS = {
   "curiosity", "joy", "surprise", "fear",
   "disgust",   "anger", "sadness", "anticipation",
}

-- ─── Constructor ─────────────────────────────────────────────────────────────

--- @param opts  table:
--   stateSize          input state dimensionality (default 64)
--   actionSize         number of actions (default 8)
--   reservoirSize      ESN neuron count (default 847)
--   llamaInstances     number of LLaMA.cpp instances (default 1)
--   basePort           first LLaMA server port (default 8080)
--   personalityArchetype  "NeuroSama" | "Analytical" | nil (default "NeuroSama")
--   consciousnessLayer    initial layer 0-3 (default 1)
--   verbose            enable diagnostic output (default false)
function NNECCOAgent:__init(opts)
   opts = opts or {}
   -- Set defaults before calling parent
   opts.stateSize  = opts.stateSize  or 64
   opts.actionSize = opts.actionSize or 8

   parent.__init(self, opts)

   -- ── Reservoir ─────────────────────────────────────────────────────────────
   local EchoReservoir = Class.get('nn.EchoReservoir')
   self.reservoir = EchoReservoir(
      opts.stateSize,
      opts.reservoirSize or 847,
      {
         spectralRadius = opts.spectralRadius or 0.9,
         leakRate       = opts.leakRate       or 0.7,
         sparsity       = opts.sparsity       or 0.85,
      }
   )

   -- ── Consciousness layer ────────────────────────────────────────────────────
   self.consciousnessLayer = opts.consciousnessLayer or 1
   self.consciousnessHistory = {}

   -- ── Emotion processing ────────────────────────────────────────────────────
   self.emotions = Tensor.zeros(#EMOTIONS)
   self.emotionNames = EMOTIONS
   -- Start with mild curiosity
   self.emotions.data[1] = 0.6

   -- ── Personality (override archetype) ──────────────────────────────────────
   local Personality = Class.get('nn.Personality')
   if Personality then
      local arch = opts.personalityArchetype or "NeuroSama"
      if arch == "NeuroSama" and Personality.NeuroSama then
         self.personality = Personality.NeuroSama()
      elseif arch == "Analytical" and Personality.Analytical then
         self.personality = Personality.Analytical()
      else
         self.personality = Personality(nil, opts.personalityOpts)
      end
   end

   -- ── LLaMA orchestrator ────────────────────────────────────────────────────
   local LLaMAOrchestrator = Class.get('nn.LLaMAOrchestrator')
   self.llama = LLaMAOrchestrator({
      numInstances = opts.llamaInstances or 1,
      basePort     = opts.basePort       or 8080,
      modelPath    = opts.modelPath      or "",
      stubMode     = opts.stubMode,      -- nil = auto-detect
      verbose      = opts.verbose or false,
   })
   self.llama:initialize()

   -- ── Cognitive pipeline (post-reservoir encoder) ───────────────────────────
   local reservoirN = self.reservoir.reservoirN
   local Sequential = Class.get('nn.Sequential')
   local Linear     = Class.get('nn.Linear')
   local Tanh       = Class.get('nn.Tanh')
   local ReLU       = Class.get('nn.ReLU')

   -- Encoder: reservoir state → compressed context
   self.encoder = Sequential()
   self.encoder:add(Linear(reservoirN, 256))
   self.encoder:add(Tanh())
   self.encoder:add(Linear(256, 128))
   self.encoder:add(ReLU())

   -- Emotion modulator: context + emotions → modulated context
   self.emotionModulator = Sequential()
   self.emotionModulator:add(Linear(128 + #EMOTIONS, 128))
   self.emotionModulator:add(Tanh())

   -- ── Hardware registers (virtual) ──────────────────────────────────────────
   self.registers = {
      R0  = Tensor.zeros(opts.stateSize),    -- current input
      R1  = Tensor.zeros(reservoirN),        -- reservoir state
      R2  = Tensor.zeros(128),              -- encoded context
      R3  = Tensor.zeros(#EMOTIONS),        -- emotion vector
      R4  = Tensor.zeros(opts.actionSize),  -- action Q-values
      PC  = 1,                              -- EchoBeats program counter
      STA = 0,                              -- status flags
   }

   -- ── Step metrics ──────────────────────────────────────────────────────────
   self.beatMetrics = {}
   for _, name in ipairs(ECHO_BEATS) do
      self.beatMetrics[name] = 0
   end

   self.cycleCount = 0
   self.verbose    = opts.verbose or false
end

-- ─── EchoBeats cognitive loop ─────────────────────────────────────────────────

--- Run one full 12-step EchoBeats cognitive cycle.
-- @param rawInput  Tensor or string
-- @return          result table with .output (text or action), .state, .emotions
function NNECCOAgent:process(rawInput)
   self.cycleCount = self.cycleCount + 1
   local ctx = {
      rawInput = rawInput,
      cycle    = self.cycleCount,
      log      = {},
   }

   -- Run all 12 beats sequentially
   self:_beat_PERCEIVE(ctx)
   self:_beat_FILTER(ctx)
   self:_beat_RESONATE(ctx)
   self:_beat_ENCODE(ctx)
   self:_beat_RECALL(ctx)
   self:_beat_REASON(ctx)
   self:_beat_EMOTE(ctx)
   self:_beat_PLAN(ctx)
   self:_beat_LEARN(ctx)
   self:_beat_REFLECT(ctx)
   self:_beat_EXPRESS(ctx)
   self:_beat_INTEGRATE(ctx)

   if self.verbose then
      print(string.format("[NNECCO cycle=%d] layer=%s emotions: curiosity=%.2f joy=%.2f",
         self.cycleCount,
         CONSCIOUSNESS_LAYERS[self.consciousnessLayer],
         self.emotions.data[1], self.emotions.data[2]))
   end

   return {
      output   = ctx.output,
      action   = ctx.action,
      state    = self.registers.R2:clone(),
      emotions = self.emotions:clone(),
      cycle    = self.cycleCount,
      layer    = CONSCIOUSNESS_LAYERS[self.consciousnessLayer],
      log      = ctx.log,
   }
end

-- ─── Individual beat implementations ─────────────────────────────────────────

function NNECCOAgent:_beat_PERCEIVE(ctx)
   self.beatMetrics["PERCEIVE"] = self.beatMetrics["PERCEIVE"] + 1
   local input = ctx.rawInput
   if type(input) == "string" then
      -- Convert string to bag-of-chars feature vector
      ctx.inputTensor = self:_encodeText(input)
   elseif type(input) == "table" and input.data then
      ctx.inputTensor = input  -- already a Tensor
   else
      ctx.inputTensor = Tensor.zeros(self.stateSize)
   end
   self.registers.R0 = ctx.inputTensor
   ctx.log[#ctx.log+1] = "PERCEIVE: input size=" .. (ctx.inputTensor.size_[1] or 0)
end

function NNECCOAgent:_beat_FILTER(ctx)
   self.beatMetrics["FILTER"] = self.beatMetrics["FILTER"] + 1
   -- Attentional gating: suppress low-amplitude features
   local inp = ctx.inputTensor
   local threshold = inp:norm() * 0.05
   local filtered = inp:apply(function(x)
      return math.abs(x) > threshold and x or 0
   end)
   ctx.filteredInput = filtered
   ctx.log[#ctx.log+1] = "FILTER: threshold=" .. string.format("%.4f", threshold)
end

function NNECCOAgent:_beat_RESONATE(ctx)
   self.beatMetrics["RESONATE"] = self.beatMetrics["RESONATE"] + 1
   local echoed = self.reservoir:forward(ctx.filteredInput)
   self.registers.R1 = echoed
   ctx.reservoirState = echoed
   ctx.log[#ctx.log+1] = string.format("RESONATE: reservoir norm=%.4f", echoed:norm())
end

function NNECCOAgent:_beat_ENCODE(ctx)
   self.beatMetrics["ENCODE"] = self.beatMetrics["ENCODE"] + 1
   local encoded = self.encoder:forward(ctx.reservoirState)
   self.registers.R2 = encoded
   ctx.encoded = encoded
   ctx.log[#ctx.log+1] = string.format("ENCODE: context norm=%.4f", encoded:norm())
end

function NNECCOAgent:_beat_RECALL(ctx)
   self.beatMetrics["RECALL"] = self.beatMetrics["RECALL"] + 1
   -- Retrieve top-3 similar past experiences
   if self.memory:size() > 0 then
      local similar = self.memory:retrieveSimilar(ctx.inputTensor, 3)
      ctx.recalled = similar
      ctx.log[#ctx.log+1] = string.format("RECALL: found %d similar memories", #similar)
   else
      ctx.recalled = {}
      ctx.log[#ctx.log+1] = "RECALL: memory empty"
   end
end

function NNECCOAgent:_beat_REASON(ctx)
   self.beatMetrics["REASON"] = self.beatMetrics["REASON"] + 1
   -- Build a prompt summarising current context for LLaMA
   local layerName = CONSCIOUSNESS_LAYERS[self.consciousnessLayer]
   local emotionStr = ""
   for i, name in ipairs(self.emotionNames) do
      if self.emotions.data[i] > 0.4 then
         emotionStr = emotionStr .. name .. "(" ..
            string.format("%.2f", self.emotions.data[i]) .. ") "
      end
   end
   local prompt = string.format(
      "[NNECCO L%d %s] Emotions: %s\nInput: %s\nRespond concisely:",
      self.consciousnessLayer, layerName, emotionStr,
      type(ctx.rawInput) == "string" and ctx.rawInput or "<tensor>")

   local resp = self.llama:generate(prompt, {
      max_tokens  = self.consciousnessLayer > 1 and 128 or 64,
      temperature = 0.7 + 0.05 * self.emotions.data[1],  -- curiosity modulates temp
   })
   ctx.llamaResponse = resp
   ctx.log[#ctx.log+1] = string.format("REASON: inst=%d latency=%dms",
      resp.instance_id or 0, resp.latency_ms or 0)
end

function NNECCOAgent:_beat_EMOTE(ctx)
   self.beatMetrics["EMOTE"] = self.beatMetrics["EMOTE"] + 1
   -- Heuristic emotion update based on reward signal (if present)
   local reward  = ctx.reward or 0
   local novelty = ctx.inputTensor:norm() - (self.registers.R0:norm() or 0)

   -- Curiosity rises with novelty, decays naturally
   self.emotions.data[1] = math.min(1, math.max(0,
      self.emotions.data[1] * 0.95 + math.abs(novelty) * 0.05))

   -- Joy rises with positive reward
   self.emotions.data[2] = math.min(1, math.max(0,
      self.emotions.data[2] * 0.9 + math.max(0, reward) * 0.1))

   -- Surprise from large input change
   self.emotions.data[3] = math.min(1, math.max(0,
      math.abs(novelty) * 0.5))

   self.registers.R3 = self.emotions:clone()
   ctx.log[#ctx.log+1] = string.format("EMOTE: curiosity=%.2f joy=%.2f",
      self.emotions.data[1], self.emotions.data[2])
end

function NNECCOAgent:_beat_PLAN(ctx)
   self.beatMetrics["PLAN"] = self.beatMetrics["PLAN"] + 1
   -- Emotion-modulated action selection
   local emotCtx = Tensor.cat(ctx.encoded, self.emotions)
   local modulated = self.emotionModulator:forward(emotCtx)

   -- Use the modulated context to produce Q-values via policy
   -- (policy takes stateSize input; we use original filtered input)
   local qvals = self.policy:forward(ctx.filteredInput)
   self.registers.R4 = qvals
   ctx.qvals = qvals

   -- Select action (with ε-greedy if in training mode)
   if self.train then
      ctx.action = self:act(ctx.filteredInput)
   else
      local bestA, bestQ = 1, -math.huge
      for a = 1, self.actionSize do
         if qvals.data[a] > bestQ then bestQ = qvals.data[a]; bestA = a end
      end
      ctx.action = bestA
   end

   ctx.log[#ctx.log+1] = string.format("PLAN: action=%d qmax=%.4f",
      ctx.action, qvals:max())
end

function NNECCOAgent:_beat_LEARN(ctx)
   self.beatMetrics["LEARN"] = self.beatMetrics["LEARN"] + 1
   -- Store experience if we have a complete transition
   if ctx.prevState and ctx.action and ctx.reward ~= nil then
      self:remember(ctx.prevState, ctx.action, ctx.reward,
                    ctx.filteredInput, ctx.done or false)
   end
   local loss = self:learn()
   ctx.loss   = loss
   ctx.log[#ctx.log+1] = loss
      and string.format("LEARN: loss=%.6f eps=%.4f", loss, self.epsilon)
      or  "LEARN: memory too small, skipped"
end

function NNECCOAgent:_beat_REFLECT(ctx)
   self.beatMetrics["REFLECT"] = self.beatMetrics["REFLECT"] + 1
   -- Meta-cognition: adjust consciousness layer
   local loss = ctx.loss or 0
   if loss > 0.5 then
      -- High error → increase deliberation
      self.consciousnessLayer = math.min(3, self.consciousnessLayer + 1)
   elseif loss < 0.01 and loss > 0 then
      -- Low error → can reduce to reactive
      self.consciousnessLayer = math.max(1, self.consciousnessLayer - 1)
   end
   self.consciousnessHistory[#self.consciousnessHistory+1] = self.consciousnessLayer
   ctx.log[#ctx.log+1] = string.format("REFLECT: layer=%d",
      self.consciousnessLayer)
end

function NNECCOAgent:_beat_EXPRESS(ctx)
   self.beatMetrics["EXPRESS"] = self.beatMetrics["EXPRESS"] + 1
   -- Primary output: use LLaMA response if available, else describe action
   if ctx.llamaResponse and ctx.llamaResponse.text and ctx.llamaResponse.text ~= "" then
      ctx.output = {
         text         = ctx.llamaResponse.text,
         action       = ctx.action,
         consciousness = CONSCIOUSNESS_LAYERS[self.consciousnessLayer],
      }
   else
      ctx.output = {
         text   = string.format("Action %d selected (Q=%.3f)",
            ctx.action, ctx.qvals and ctx.qvals.data[ctx.action] or 0),
         action = ctx.action,
         consciousness = CONSCIOUSNESS_LAYERS[self.consciousnessLayer],
      }
   end
   ctx.log[#ctx.log+1] = "EXPRESS: " .. ctx.output.text:sub(1, 60)
end

function NNECCOAgent:_beat_INTEGRATE(ctx)
   self.beatMetrics["INTEGRATE"] = self.beatMetrics["INTEGRATE"] + 1
   -- Store current state for next cycle's recall
   ctx.prevState = ctx.filteredInput

   -- Update knowledge base with current experience
   if self.knowledge then
      -- Resolve TruthValue from the AtomSpace module (already loaded)
      local atomMod = require('a9nn.AtomSpace')
      local tv = atomMod.TruthValue.new(math.max(0, 1 - (ctx.loss or 0)), 1)
      -- Add an episode node for this cycle with a proper TruthValue object
      self.knowledge:addNode("EpisodeNode", "cycle_" .. self.cycleCount, tv)
   end

   -- Advance registers
   self.registers.PC = (self.registers.PC % 12) + 1
   ctx.log[#ctx.log+1] = string.format("INTEGRATE: cycle=%d complete", self.cycleCount)
end

-- ─── Utility ─────────────────────────────────────────────────────────────────

--- Encode a text string as a fixed-size feature vector.
-- Uses character n-gram frequencies mapped to (stateSize,) Tensor.
function NNECCOAgent:_encodeText(text)
   local n   = self.stateSize
   local out = Tensor.zeros(n)
   -- Simple char-level hashing into bins
   for i = 1, #text do
      local c   = string.byte(text, i)
      local bin = ((c * 31 + i * 7) % n) + 1
      out.data[bin] = out.data[bin] + 1
   end
   -- L2-normalise
   local norm = out:norm()
   if norm > 1e-6 then
      for i = 1, n do out.data[i] = out.data[i] / norm end
   end
   return out
end

--- Return a hardware-style status dump.
function NNECCOAgent:getHardwareStatus()
   local llamaStatus = self.llama:getStatus()
   return {
      agentID     = self.id,
      cycle       = self.cycleCount,
      reservoir   = {
         size          = self.reservoir.reservoirN,
         spectralRadius = self.reservoir.spectralRadius,
         leakRate      = self.reservoir.leakRate,
         stateNorm     = self.registers.R1:norm(),
      },
      consciousness = {
         layer    = self.consciousnessLayer,
         name     = CONSCIOUSNESS_LAYERS[self.consciousnessLayer],
         history  = self.consciousnessHistory,
      },
      emotions = (function()
         local t = {}
         for i, name in ipairs(self.emotionNames) do
            t[name] = self.emotions.data[i]
         end
         return t
      end)(),
      llama       = llamaStatus,
      registers   = {
         PC  = self.registers.PC,
         STA = self.registers.STA,
      },
      beatMetrics = self.beatMetrics,
      memory      = {
         size     = self.memory:size(),
         capacity = self.memory.capacity,
      },
      policy = {
         epsilon = self.epsilon,
         steps   = self.stepCount,
      },
   }
end

function NNECCOAgent:__tostring__()
   return string.format(
      "nn.NNECCOAgent(id=%d, reservoir=%d, llama=%d, layer=%s)",
      self.id,
      self.reservoir.reservoirN,
      self.llama.numInstances,
      CONSCIOUSNESS_LAYERS[self.consciousnessLayer])
end

return NNECCOAgent
