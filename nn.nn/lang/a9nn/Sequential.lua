-- a9nn/Sequential.lua
-- Feed-forward container: passes output of module i as input to module i+1.

local nn    = require('a9nn.nn_ns')
local Class = nn.Class

local Sequential, parent = Class.class('nn.Sequential', 'nn.Container')

function Sequential:__init()
   parent.__init(self)
end

function Sequential:updateOutput(input)
   local out = input
   for _, m in ipairs(self.modules) do
      out = m:forward(out)
   end
   self.output = out
   return out
end

function Sequential:backward(input, gradOutput, scale)
   scale = scale or 1
   local currentGrad = gradOutput
   for i = #self.modules, 2, -1 do
      local prevOut = self.modules[i-1].output
      currentGrad   = self.modules[i]:backward(prevOut, currentGrad, scale)
   end
   currentGrad   = self.modules[1]:backward(input, currentGrad, scale)
   self.gradInput = currentGrad
   return currentGrad
end

function Sequential:__tostring__()
   local lines = {"nn.Sequential {"}
   for i, m in ipairs(self.modules) do
      lines[#lines+1] = string.format("  (%d): %s", i, tostring(m))
   end
   lines[#lines+1] = "}"
   return table.concat(lines, "\n")
end

return Sequential
