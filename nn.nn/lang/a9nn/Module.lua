-- a9nn/Module.lua
-- Base class for all a9nn neural network modules.
-- Mirrors the interface of torch/nn Module.lua, but works without Torch.

local nn     = require('a9nn.nn_ns')   -- namespace holder
local Tensor = nn.Tensor
local Class  = nn.Class

local Module, _ = Class.class('nn.Module')

function Module:__init()
   self.output    = Tensor.zeros(1)
   self.gradInput = Tensor.zeros(1)
   self.train     = true
end

-- ─── Core forward / backward ──────────────────────────────────────────────────

--- Compute output from input (override in subclasses).
function Module:updateOutput(input)
   return self.output
end

function Module:forward(input)
   return self:updateOutput(input)
end

--- Compute gradient w.r.t. inputs (override in subclasses).
function Module:updateGradInput(input, gradOutput)
   return self.gradInput
end

--- Accumulate gradients w.r.t. parameters (override if module has params).
function Module:accGradParameters(input, gradOutput, scale)
   -- default: no-op
end

function Module:backward(input, gradOutput, scale)
   scale = scale or 1
   self:updateGradInput(input, gradOutput)
   self:accGradParameters(input, gradOutput, scale)
   return self.gradInput
end

-- ─── Parameter management ─────────────────────────────────────────────────────

--- Return {params}, {gradParams} tables or nil.
function Module:parameters()
   if self.weight and self.bias then
      return {self.weight, self.bias}, {self.gradWeight, self.gradBias}
   elseif self.weight then
      return {self.weight}, {self.gradWeight}
   elseif self.bias then
      return {self.bias}, {self.gradBias}
   end
   return nil, nil
end

function Module:zeroGradParameters()
   local _, gradParams = self:parameters()
   if gradParams then
      for _, gp in ipairs(gradParams) do gp:zero() end
   end
end

function Module:updateParameters(lr)
   local params, gradParams = self:parameters()
   if params then
      for i = 1, #params do
         -- params[i] -= lr * gradParams[i]
         local gp = gradParams[i]:mul(lr)
         local p  = params[i]
         for j = 1, #p.data do
            p.data[j] = p.data[j] - gp.data[j]
         end
      end
   end
end

-- ─── Mode switches ────────────────────────────────────────────────────────────

function Module:training()  self.train = true  end
function Module:evaluate()  self.train = false end

-- ─── Utility ──────────────────────────────────────────────────────────────────

--- Recursively apply callback to this module and all children.
function Module:apply(callback)
   callback(self)
   if self.modules then
      for _, m in ipairs(self.modules) do m:apply(callback) end
   end
end

--- Deep clone.
function Module:clone()
   -- Simple deep copy via serialisation of the Lua table
   local function deepcopy(orig)
      local t = type(orig)
      if t ~= "table" then return orig end
      local copy = {}
      for k, v in pairs(orig) do copy[deepcopy(k)] = deepcopy(v) end
      return setmetatable(copy, getmetatable(orig))
   end
   return deepcopy(self)
end

function Module:clearState()
   self.output    = Tensor.zeros(1)
   self.gradInput = Tensor.zeros(1)
end

--- Returns a human-readable description of this module.
-- Override this in subclasses to customise how the module prints.
-- This follows the torch/nn convention (see lang/lua/Sequential.lua et al.):
-- subclasses override __tostring__() while __tostring() is the raw Lua hook.
function Module:__tostring__()
   return Class.typename(self) or 'nn.Module'
end

-- Lua's __tostring metamethod hook.  Calls the user-overridable __tostring__
-- method (note: these are *distinct* names — __tostring__ has underscores on
-- both sides and is the subclass-overridable API, matching the torch/nn
-- convention used throughout lang/lua/).
function Module:__tostring()
   return Module.__tostring__(self)
end

return Module
