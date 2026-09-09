-- a9nn/StochasticGradient.lua
-- Stochastic-gradient trainer (mirrors torch/nn StochasticGradient).

local nn    = require('a9nn.nn_ns')
local Class = nn.Class

local SGD, _ = Class.class('nn.StochasticGradient')

function SGD:__init(module, criterion)
   self.module    = module
   self.criterion = criterion
   self.learningRate     = 0.01
   self.learningRateDecay = 0
   self.maxIteration     = 25
   self.shuffleIndices   = true
   self.hookIteration    = nil
   self.verbose          = true
end

--- Train on a dataset.
-- dataset must expose:
--   dataset:size()           → number of samples
--   dataset[i]               → {input, target}
function SGD:train(dataset)
   local iteration = 1
   local currentLearningRate = self.learningRate

   -- Build index list
   local indices = {}
   for i = 1, dataset:size() do indices[i] = i end

   while true do
      local currentError = 0

      -- Optional shuffle
      if self.shuffleIndices then
         for i = #indices, 2, -1 do
            local j = math.random(i)
            indices[i], indices[j] = indices[j], indices[i]
         end
      end

      for k = 1, dataset:size() do
         local idx    = indices[k]
         local sample = dataset[idx]
         local input, target = sample[1], sample[2]

         -- Forward
         local output = self.module:forward(input)
         local err    = self.criterion:forward(output, target)
         currentError = currentError + err

         -- Backward
         local gradOutput = self.criterion:backward(output, target)
         self.module:zeroGradParameters()
         self.module:backward(input, gradOutput)
         self.module:updateParameters(currentLearningRate)
      end

      currentError = currentError / dataset:size()

      if self.hookIteration then
         self.hookIteration(self, iteration, currentError)
      end

      if self.verbose then
         print(string.format("# SGD iteration %d, mean loss = %.6f", iteration, currentError))
      end

      iteration = iteration + 1
      currentLearningRate = self.learningRate / (1 + (iteration-1) * self.learningRateDecay)

      if self.maxIteration > 0 and iteration > self.maxIteration then
         if self.verbose then print("# SGD: reached maximum number of iterations") end
         break
      end
   end
end

return SGD
