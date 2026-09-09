-- a9nn/init.lua
-- Main entry point for the a9nn framework.
-- Loads all sub-modules and populates the global `nn` table.
--
-- Usage:
--   local nn = require('a9nn')
--
-- All classes are accessible via nn.Module, nn.Linear, nn.NNECCOAgent, etc.

-- ── 1. Bootstrap namespace (must come first) ──────────────────────────────────
local ns = require('a9nn.nn_ns')

-- ── 2. Core nn infrastructure ─────────────────────────────────────────────────
require('a9nn.Module')
require('a9nn.Container')
require('a9nn.Sequential')
require('a9nn.Linear')
local acts  = require('a9nn.activations')
local crits = require('a9nn.criterions')
require('a9nn.StochasticGradient')

-- ── 3. Cognitive modules ──────────────────────────────────────────────────────
require('a9nn.EchoReservoir')
local atomMod = require('a9nn.AtomSpace')
require('a9nn.Personality')
require('a9nn.EpisodicMemory')
require('a9nn.LLaMAOrchestrator')

-- ── 4. Agents ─────────────────────────────────────────────────────────────────
require('a9nn.Agent')
require('a9nn.CognitiveAgent')
require('a9nn.NNECCOAgent')

-- ── 5. Build the public nn table ─────────────────────────────────────────────
local Class = ns.Class

local nn = {
   -- ── Tensors ────────────────────────────────────────────────────────────────
   Tensor   = ns.Tensor,
   hasTorch = ns.hasTorch,

   -- ── Core modules ───────────────────────────────────────────────────────────
   Module          = Class.get('nn.Module'),
   Container       = Class.get('nn.Container'),
   Sequential      = Class.get('nn.Sequential'),
   Linear          = Class.get('nn.Linear'),

   -- ── Activations ────────────────────────────────────────────────────────────
   Tanh            = Class.get('nn.Tanh'),
   Sigmoid         = Class.get('nn.Sigmoid'),
   ReLU            = Class.get('nn.ReLU'),
   LeakyReLU       = Class.get('nn.LeakyReLU'),
   ELU             = Class.get('nn.ELU'),
   SoftMax         = Class.get('nn.SoftMax'),
   LogSoftMax      = Class.get('nn.LogSoftMax'),

   -- ── Criterions ─────────────────────────────────────────────────────────────
   Criterion             = Class.get('nn.Criterion'),
   MSECriterion          = Class.get('nn.MSECriterion'),
   BCECriterion          = Class.get('nn.BCECriterion'),
   ClassNLLCriterion     = Class.get('nn.ClassNLLCriterion'),
   CrossEntropyCriterion = Class.get('nn.CrossEntropyCriterion'),
   SmoothL1Criterion     = Class.get('nn.SmoothL1Criterion'),

   -- ── Training ───────────────────────────────────────────────────────────────
   StochasticGradient = Class.get('nn.StochasticGradient'),

   -- ── Cognitive modules ──────────────────────────────────────────────────────
   EchoReservoir    = Class.get('nn.EchoReservoir'),
   AtomSpace        = Class.get('nn.AtomSpace'),
   TruthValue       = atomMod.TruthValue,
   AttentionValue   = atomMod.AttentionValue,
   Personality      = Class.get('nn.Personality'),
   EpisodicMemory   = Class.get('nn.EpisodicMemory'),
   LLaMAOrchestrator = Class.get('nn.LLaMAOrchestrator'),

   -- ── Agents ─────────────────────────────────────────────────────────────────
   Agent            = Class.get('nn.Agent'),
   CognitiveAgent   = Class.get('nn.CognitiveAgent'),
   NNECCOAgent      = Class.get('nn.NNECCOAgent'),

   -- ── Version info ───────────────────────────────────────────────────────────
   _VERSION = "1.0.0",
   _NAME    = "a9nn",
   _DESCRIPTION = "Lua/Torch neural network framework with cognitive agent architecture",
}

-- Convenience: also expose Class so users can extend
nn.Class = Class

return nn
