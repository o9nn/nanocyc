-- a9nn/criterions.lua
-- Loss functions (criterions): MSE, BCE, NLL, CrossEntropy.

local nn     = require('a9nn.nn_ns')
local Tensor = nn.Tensor
local Class  = nn.Class

-- ─── Base Criterion ───────────────────────────────────────────────────────────

local Criterion, _ = Class.class('nn.Criterion')

function Criterion:__init()
   self.output    = 0
   self.gradInput = Tensor.zeros(1)
end

function Criterion:forward(input, target)
   return self:updateOutput(input, target)
end

function Criterion:backward(input, target)
   return self:updateGradInput(input, target)
end

function Criterion:updateOutput(input, target) return 0 end
function Criterion:updateGradInput(input, target) return self.gradInput end

-- ─── MSE ─────────────────────────────────────────────────────────────────────

local MSECriterion, parentMSE = Class.class('nn.MSECriterion', 'nn.Criterion')

function MSECriterion:__init(sizeAverage)
   parentMSE.__init(self)
   self.sizeAverage = (sizeAverage == nil) and true or sizeAverage
end

function MSECriterion:updateOutput(input, target)
   assert(#input.data == #target.data, "MSE: input/target size mismatch")
   local diff = input:sub(target)
   local n    = self.sizeAverage and #diff.data or 1
   self.output = diff:cmul(diff):sum() / n
   return self.output
end

function MSECriterion:updateGradInput(input, target)
   local n    = self.sizeAverage and #input.data or 1
   local diff = input:sub(target)
   self.gradInput = diff:mul(2 / n)
   return self.gradInput
end

function MSECriterion:__tostring__() return 'nn.MSECriterion' end

-- ─── Binary Cross-Entropy ─────────────────────────────────────────────────────

local BCECriterion, parentBCE = Class.class('nn.BCECriterion', 'nn.Criterion')

function BCECriterion:__init(sizeAverage)
   parentBCE.__init(self)
   self.sizeAverage = (sizeAverage == nil) and true or sizeAverage
end

function BCECriterion:updateOutput(input, target)
   assert(#input.data == #target.data, "BCE: input/target size mismatch")
   local eps = 1e-12
   local sum = 0
   for i = 1, #input.data do
      local x = math.min(math.max(input.data[i], eps), 1-eps)
      local y = target.data[i]
      sum = sum + (-y * math.log(x) - (1-y) * math.log(1-x))
   end
   local n = self.sizeAverage and #input.data or 1
   self.output = sum / n
   return self.output
end

function BCECriterion:updateGradInput(input, target)
   local eps = 1e-12
   local n   = self.sizeAverage and #input.data or 1
   self.gradInput = Tensor.zeros(#input.data)
   for i = 1, #input.data do
      local x = math.min(math.max(input.data[i], eps), 1-eps)
      local y = target.data[i]
      self.gradInput.data[i] = (-(y/x) + (1-y)/(1-x)) / n
   end
   return self.gradInput
end

function BCECriterion:__tostring__() return 'nn.BCECriterion' end

-- ─── Negative Log-Likelihood ──────────────────────────────────────────────────

--- Input must be log-probabilities (output of LogSoftMax).
local ClassNLLCriterion, parentNLL = Class.class('nn.ClassNLLCriterion', 'nn.Criterion')

function ClassNLLCriterion:__init(sizeAverage)
   parentNLL.__init(self)
   self.sizeAverage = (sizeAverage == nil) and true or sizeAverage
end

function ClassNLLCriterion:updateOutput(input, target)
   -- target: 1-indexed class label (integer)
   assert(type(target) == "number", "ClassNLL: target must be an integer class index")
   self.output = -input.data[target]
   return self.output
end

function ClassNLLCriterion:updateGradInput(input, target)
   self.gradInput = Tensor.zeros(#input.data)
   self.gradInput.data[target] = -1
   if self.sizeAverage then
      self.gradInput = self.gradInput:mul(1 / #input.data)
   end
   return self.gradInput
end

function ClassNLLCriterion:__tostring__() return 'nn.ClassNLLCriterion' end

-- ─── Cross-Entropy = LogSoftMax + NLL ────────────────────────────────────────

local CrossEntropyCriterion, parentCE = Class.class('nn.CrossEntropyCriterion', 'nn.Criterion')

function CrossEntropyCriterion:__init(sizeAverage)
   parentCE.__init(self)
   self.sizeAverage = (sizeAverage == nil) and true or sizeAverage
   -- Use internal modules
   local lsm = Class.get('nn.LogSoftMax')
   local nll = ClassNLLCriterion(sizeAverage)
   self._lsm = lsm and lsm() or nil
   self._nll = nll
end

function CrossEntropyCriterion:updateOutput(input, target)
   local logp = self._lsm and self._lsm:forward(input) or input
   self._logp  = logp
   self.output = self._nll:forward(logp, target)
   return self.output
end

function CrossEntropyCriterion:updateGradInput(input, target)
   local gradNLL = self._nll:backward(self._logp, target)
   if self._lsm then
      self.gradInput = self._lsm:backward(input, gradNLL)
   else
      self.gradInput = gradNLL
   end
   return self.gradInput
end

function CrossEntropyCriterion:__tostring__() return 'nn.CrossEntropyCriterion' end

-- ─── Smooth-L1 ────────────────────────────────────────────────────────────────

local SmoothL1Criterion, parentSL1 = Class.class('nn.SmoothL1Criterion', 'nn.Criterion')

function SmoothL1Criterion:__init(sizeAverage)
   parentSL1.__init(self)
   self.sizeAverage = (sizeAverage == nil) and true or sizeAverage
end

function SmoothL1Criterion:updateOutput(input, target)
   local n   = self.sizeAverage and #input.data or 1
   local sum = 0
   for i = 1, #input.data do
      local d = math.abs(input.data[i] - target.data[i])
      sum = sum + (d < 1 and 0.5*d*d or d - 0.5)
   end
   self.output = sum / n
   return self.output
end

function SmoothL1Criterion:updateGradInput(input, target)
   local n = self.sizeAverage and #input.data or 1
   self.gradInput = Tensor.zeros(#input.data)
   for i = 1, #input.data do
      local d = input.data[i] - target.data[i]
      local g = math.abs(d) < 1 and d or (d > 0 and 1 or -1)
      self.gradInput.data[i] = g / n
   end
   return self.gradInput
end

function SmoothL1Criterion:__tostring__() return 'nn.SmoothL1Criterion' end

return {
   Criterion            = Criterion,
   MSECriterion         = MSECriterion,
   BCECriterion         = BCECriterion,
   ClassNLLCriterion    = ClassNLLCriterion,
   CrossEntropyCriterion = CrossEntropyCriterion,
   SmoothL1Criterion    = SmoothL1Criterion,
}
