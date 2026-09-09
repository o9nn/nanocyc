-- a9nn/activations.lua
-- Collection of element-wise activation modules: Tanh, Sigmoid, ReLU, etc.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

-- ─── Helper: build a simple pointwise activation ─────────────────────────────

local function makeActivation(name, fwd, bwd)
   local Act, parent = Class.class('nn.' .. name, 'nn.Module')

   function Act:__init()
      parent.__init(self)
   end

   function Act:updateOutput(input)
      self.output = input:apply(fwd)
      return self.output
   end

   function Act:updateGradInput(input, gradOutput)
      local dydx = input:apply(bwd)
      self.gradInput = gradOutput:cmul(dydx)
      return self.gradInput
   end

   function Act:__tostring__() return 'nn.' .. name end

   return Act
end

-- ─── Activation definitions ──────────────────────────────────────────────────

-- Tanh: y = tanh(x),  dy/dx = 1 - tanh(x)^2
local Tanh = makeActivation('Tanh',
   function(x) return math.tanh(x) end,
   function(x) local t = math.tanh(x); return 1 - t*t end)

-- Sigmoid: y = 1/(1+e^-x),  dy/dx = y*(1-y)
local Sigmoid = makeActivation('Sigmoid',
   function(x) return 1 / (1 + math.exp(-x)) end,
   function(x)
      local s = 1 / (1 + math.exp(-x))
      return s * (1 - s)
   end)

-- ReLU: y = max(0, x),  dy/dx = (x > 0) ? 1 : 0
local ReLU = makeActivation('ReLU',
   function(x) return math.max(0, x) end,
   function(x) return x > 0 and 1 or 0 end)

-- LeakyReLU: y = x if x>0 else 0.01*x
local LeakyReLU, parentLR = Class.class('nn.LeakyReLU', 'nn.Module')
function LeakyReLU:__init(negSlope)
   parentLR.__init(self)
   self.negSlope = negSlope or 0.01
end
function LeakyReLU:updateOutput(input)
   local ns = self.negSlope
   self.output = input:apply(function(x)
      return x >= 0 and x or ns * x
   end)
   return self.output
end
function LeakyReLU:updateGradInput(input, gradOutput)
   local ns = self.negSlope
   local dydx = input:apply(function(x) return x >= 0 and 1 or ns end)
   self.gradInput = gradOutput:cmul(dydx)
   return self.gradInput
end
function LeakyReLU:__tostring__()
   return string.format("nn.LeakyReLU(%.4f)", self.negSlope)
end

-- ELU: y = x if x>0 else alpha*(e^x - 1)
local ELU, parentELU = Class.class('nn.ELU', 'nn.Module')
function ELU:__init(alpha)
   parentELU.__init(self)
   self.alpha = alpha or 1.0
end
function ELU:updateOutput(input)
   local a = self.alpha
   self.output = input:apply(function(x)
      return x >= 0 and x or a * (math.exp(x) - 1)
   end)
   return self.output
end
function ELU:updateGradInput(input, gradOutput)
   local a = self.alpha
   local dydx = input:apply(function(x)
      return x >= 0 and 1 or a * math.exp(x)
   end)
   self.gradInput = gradOutput:cmul(dydx)
   return self.gradInput
end
function ELU:__tostring__()
   return string.format("nn.ELU(%.4f)", self.alpha)
end

-- SoftMax (1-D)
local SoftMax, parentSM = Class.class('nn.SoftMax', 'nn.Module')
function SoftMax:__init()
   parentSM.__init(self)
end
function SoftMax:updateOutput(input)
   local maxVal = input:max()
   local shifted = input:add(-maxVal)
   local expData = shifted:apply(math.exp)
   local s = expData:sum()
   self.output = expData:mul(1/s)
   return self.output
end
function SoftMax:updateGradInput(input, gradOutput)
   -- d(softmax)/dx_i = s_i * (delta_ij - s_j)
   local s  = self.output
   local dot = gradOutput:cmul(s):sum()
   self.gradInput = s:cmul(gradOutput:add(-dot))
   return self.gradInput
end
function SoftMax:__tostring__() return 'nn.SoftMax' end

-- LogSoftMax
local LogSoftMax, parentLSM = Class.class('nn.LogSoftMax', 'nn.Module')
function LogSoftMax:__init()
   parentLSM.__init(self)
end
function LogSoftMax:updateOutput(input)
   local maxVal = input:max()
   local shifted = input:add(-maxVal)
   local expData = shifted:apply(math.exp)
   local logSum  = math.log(expData:sum())
   self.output   = shifted:add(-logSum)
   return self.output
end
function LogSoftMax:updateGradInput(input, gradOutput)
   local sm  = self.output:apply(math.exp)
   local sum = gradOutput:sum()
   self.gradInput = gradOutput:sub(sm:mul(sum))
   return self.gradInput
end
function LogSoftMax:__tostring__() return 'nn.LogSoftMax' end

return {
   Tanh       = Tanh,
   Sigmoid    = Sigmoid,
   ReLU       = ReLU,
   LeakyReLU  = LeakyReLU,
   ELU        = ELU,
   SoftMax    = SoftMax,
   LogSoftMax = LogSoftMax,
}
