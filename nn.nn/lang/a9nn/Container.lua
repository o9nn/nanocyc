-- a9nn/Container.lua
-- Base class for modules that contain other modules.

local nn    = require('a9nn.nn_ns')
local Class = nn.Class

local Container, parent = Class.class('nn.Container', 'nn.Module')

function Container:__init()
   parent.__init(self)
   self.modules = {}
end

function Container:add(module)
   table.insert(self.modules, module)
   return self
end

function Container:get(index)
   return self.modules[index]
end

function Container:size()
   return #self.modules
end

function Container:parameters()
   local params, gradParams = {}, {}
   for _, m in ipairs(self.modules) do
      local p, gp = m:parameters()
      if p then
         for _, v in ipairs(p)  do table.insert(params,     v) end
         for _, v in ipairs(gp) do table.insert(gradParams, v) end
      end
   end
   return params, gradParams
end

function Container:training()
   self.train = true
   for _, m in ipairs(self.modules) do m:training() end
end

function Container:evaluate()
   self.train = false
   for _, m in ipairs(self.modules) do m:evaluate() end
end

function Container:zeroGradParameters()
   for _, m in ipairs(self.modules) do m:zeroGradParameters() end
end

function Container:updateParameters(lr)
   for _, m in ipairs(self.modules) do m:updateParameters(lr) end
end

return Container
