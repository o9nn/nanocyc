-- a9nn/EchoReservoir.lua
-- Echo State Network (ESN / Liquid State Machine) reservoir layer.
--
-- An ESN consists of:
--   • A fixed (untrained) recurrent reservoir of N neurons
--   • An input weight matrix W_in  (N × inSize)
--   • A reservoir weight matrix W_res (N × N)  with spectral radius < 1
--   • An optional output layer (trained separately or via nn.Linear)
--
-- The reservoir maps a sequence of inputs to a high-dimensional state
-- trajectory, enabling rich temporal feature extraction.
--
-- Reference: Jaeger (2001) "The echo state approach to analysing and training
-- recurrent neural networks"

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

local EchoReservoir, parent = Class.class('nn.EchoReservoir', 'nn.Module')

--- Constructor.
-- @param inSize      dimensionality of each input step
-- @param reservoirN  number of reservoir neurons (default 100)
-- @param opts        table of optional parameters:
--   spectralRadius   target spectral radius  (default 0.9)
--   sparsity         fraction of zero weights (default 0.8)
--   leakRate         leaking rate α ∈ (0,1]  (default 1.0)
--   inputScaling     scaling for W_in         (default 1.0)
function EchoReservoir:__init(inSize, reservoirN, opts)
   parent.__init(self)
   opts = opts or {}

   self.inSize        = inSize
   self.reservoirN    = reservoirN or 100
   self.spectralRadius = opts.spectralRadius or 0.9
   self.sparsity       = opts.sparsity       or 0.8
   self.leakRate       = opts.leakRate       or 1.0
   self.inputScaling   = opts.inputScaling   or 1.0

   -- Initialise fixed weight matrices
   self:_initWeights()

   -- Current hidden state
   self.state = Tensor.zeros(self.reservoirN)

   -- Output = concatenation of state (and optionally input)
   self.output = Tensor.zeros(self.reservoirN)
end

function EchoReservoir:_initWeights()
   local N   = self.reservoirN
   local M   = self.inSize

   -- W_in: (N × M) scaled uniform
   self.W_in = Tensor.zeros(N, M)
   self.W_in:uniform(self.inputScaling)

   -- W_res: (N × N) sparse, rescaled to desired spectral radius
   self.W_res = Tensor.zeros(N, N)
   for i = 1, N do
      for j = 1, N do
         if math.random() > self.sparsity then
            self.W_res.data[(i-1)*N+j] = (math.random() * 2 - 1)
         end
      end
   end

   -- Approximate spectral radius by power iteration
   local rho = self:_powerIteration(self.W_res, 20)
   if rho > 1e-6 then
      local scale = self.spectralRadius / rho
      for i = 1, N*N do
         self.W_res.data[i] = self.W_res.data[i] * scale
      end
   end
end

--- Approximate largest eigenvalue magnitude via power iteration.
function EchoReservoir:_powerIteration(W, iters)
   local N = W.size_[1]
   local v = Tensor.zeros(N)
   -- Random start
   for i = 1, N do v.data[i] = math.random() * 2 - 1 end

   local norm = v:norm()
   if norm < 1e-10 then return 0 end
   for i = 1, N do v.data[i] = v.data[i] / norm end

   local rho = 0
   for _ = 1, iters do
      local Wv = W:mv(v)
      rho = Wv:norm()
      if rho < 1e-10 then break end
      for i = 1, N do v.data[i] = Wv.data[i] / rho end
   end
   return rho
end

--- Reset the reservoir state to zeros.
function EchoReservoir:resetState()
   self.state:zero()
end

--- Forward pass for a SINGLE time step.
-- @param input  Tensor of shape (inSize,)
-- @return       Tensor of shape (reservoirN,) — reservoir state
function EchoReservoir:updateOutput(input)
   assert(input.size_[1] == self.inSize,
      string.format("EchoReservoir: expected input size %d, got %d",
         self.inSize, input.size_[1]))

   -- pre-activation = W_in · u + W_res · x(t-1)
   local u  = self.W_in:mv(input)
   local Wx = self.W_res:mv(self.state)
   local pre = u:add(Wx)

   -- activation with tanh
   local newState = pre:apply(math.tanh)

   -- leaky integration: x(t) = (1-α)·x(t-1) + α·f(pre)
   local alpha = self.leakRate
   if alpha < 1.0 then
      for i = 1, self.reservoirN do
         newState.data[i] = (1-alpha) * self.state.data[i]
            + alpha * newState.data[i]
      end
   end

   self.state  = newState
   self.output = newState:clone()
   return self.output
end

--- Forward pass over a SEQUENCE of inputs.
-- @param sequence  table of Tensors, each of shape (inSize,)
-- @return          table of state Tensors, one per time step
function EchoReservoir:forwardSequence(sequence)
   self:resetState()
   local states = {}
   for t, u in ipairs(sequence) do
      states[t] = self:forward(u)
   end
   return states
end

--- State accessor.
function EchoReservoir:getState()
   return self.state:clone()
end

--- Collect reservoir states for a sequence (washout first `warmup` steps).
-- @param sequence  table of input Tensors
-- @param warmup    number of initial steps to discard (default 10)
-- @return          matrix-like table of states after warmup
function EchoReservoir:collectStates(sequence, warmup)
   warmup = warmup or math.min(10, math.floor(#sequence / 5))
   self:resetState()
   local collected = {}
   for t, u in ipairs(sequence) do
      local s = self:forward(u)
      if t > warmup then
         collected[#collected+1] = s
      end
   end
   return collected
end

function EchoReservoir:__tostring__()
   return string.format(
      "nn.EchoReservoir(in=%d, N=%d, sr=%.2f, leak=%.2f)",
      self.inSize, self.reservoirN, self.spectralRadius, self.leakRate)
end

return EchoReservoir
