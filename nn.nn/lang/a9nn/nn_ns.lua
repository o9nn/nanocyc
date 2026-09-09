-- a9nn/nn_ns.lua
-- Namespace bootstrap: provides the shared `nn` table, Class system, and
-- Tensor abstraction to all a9nn sub-modules.
-- This file is required FIRST by every sub-module via:
--   local nn = require('a9nn.nn_ns')

-- Avoid re-running if already loaded
if _G._a9nn_ns then return _G._a9nn_ns end

-- Detect whether we are running under Torch
local hasTorch = pcall(require, 'torch')

local ns = {}

-- ── Class system ──────────────────────────────────────────────────────────────
ns.Class = require('a9nn.class')

-- ── Tensor ────────────────────────────────────────────────────────────────────
if hasTorch then
   -- Thin wrapper so the rest of the code can always call nn.Tensor.zeros etc.
   local T = {}
   function T.zeros(...)  return torch.Tensor(...):zero() end
   function T.ones(...)   return torch.Tensor(...):fill(1) end
   function T.rand(...)   return torch.rand(...) end
   function T.randn(...)  return torch.randn(...) end
   function T.new(data)
      local t = torch.Tensor(#data)
      for i, v in ipairs(data) do t[i] = v end
      return t
   end
   ns.Tensor = T
   ns.hasTorch = true
else
   ns.Tensor   = require('a9nn.tensor')
   ns.hasTorch = false
end

-- ── Global nn table (populated by init.lua) ───────────────────────────────────
ns.nn = ns.nn or {}

-- Store in global so sub-modules share the same instance
_G._a9nn_ns = ns
return ns
