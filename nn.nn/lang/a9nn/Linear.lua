-- a9nn/Linear.lua
-- Fully-connected (affine) layer: y = x·W^T + b

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

local Linear, parent = Class.class('nn.Linear', 'nn.Module')

--- @param inSize   number of input features
--- @param outSize  number of output features
--- @param bias     boolean, default true
function Linear:__init(inSize, outSize, bias)
   parent.__init(self)
   self.inSize  = inSize
   self.outSize = outSize
   self.hasBias = (bias == nil) and true or bias

   -- weight: outSize × inSize
   self.weight     = Tensor.zeros(outSize, inSize)
   self.gradWeight = Tensor.zeros(outSize, inSize)

   if self.hasBias then
      self.bias     = Tensor.zeros(outSize)
      self.gradBias = Tensor.zeros(outSize)
   end

   self:reset()
end

--- Xavier / He initialisation (uniform).
function Linear:reset(stdv)
   stdv = stdv or (1 / math.sqrt(self.inSize))
   self.weight:uniform(stdv)
   if self.hasBias then self.bias:uniform(stdv) end
   return self
end

--- Forward: y = W·x + b   (x can be 1-D vector of length inSize)
function Linear:updateOutput(input)
   -- input: Tensor of shape (inSize,)
   assert(#input.size_ == 1 and input.size_[1] == self.inSize,
      string.format("Linear: expected input of size %d, got %d",
         self.inSize, input.size_[1] or -1))

   -- W · x
   local out = self.weight:mv(input)

   if self.hasBias then
      out = out:add(self.bias)
   end

   self.output = out
   return self.output
end

--- Backward: compute gradInput and gradWeight.
function Linear:updateGradInput(input, gradOutput)
   -- gradInput = W^T · gradOutput
   self.gradInput = self.weight:t():mv(gradOutput)
   return self.gradInput
end

function Linear:accGradParameters(input, gradOutput, scale)
   scale = scale or 1
   -- gradWeight += scale * gradOutput ⊗ input  (outer product)
   for i = 1, self.outSize do
      for j = 1, self.inSize do
         local idx = (i-1)*self.inSize + j
         self.gradWeight.data[idx] = self.gradWeight.data[idx]
            + scale * gradOutput.data[i] * input.data[j]
      end
   end
   if self.hasBias then
      for i = 1, self.outSize do
         self.gradBias.data[i] = self.gradBias.data[i]
            + scale * gradOutput.data[i]
      end
   end
end

function Linear:__tostring__()
   return string.format("nn.Linear(%d -> %d%s)",
      self.inSize, self.outSize,
      self.hasBias and "" or " no bias")
end

return Linear
