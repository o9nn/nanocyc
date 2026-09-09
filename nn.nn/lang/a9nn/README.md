# a9nn — Lua Neural Network Framework with Cognitive Agent Architecture

**a9nn** is a self-contained Lua neural network framework that extends the
classic `torch/nn` API with a full **cognitive agent architecture**:
Echo State Reservoir Networks, OpenCog AtomSpace, personality-driven
multi-agent systems, and parallel LLaMA.cpp orchestration.

It runs without Torch (pure Lua 5.1+) and automatically upgrades to Torch
tensors when Torch is present.

---

## Quick Start

```lua
-- From the repo root:
package.path = "lang/a9nn/?.lua;" .. package.path

local nn = require('a9nn')

-- ── Classic MLP ───────────────────────────────────────────────
local mlp = nn.Sequential()
mlp:add(nn.Linear(2, 8))
mlp:add(nn.Tanh())
mlp:add(nn.Linear(8, 1))

local criterion = nn.MSECriterion()
local x = nn.Tensor.new({0.5, -0.3})
local y = nn.Tensor.new({1.0})
mlp:forward(x)
mlp:backward(x, criterion:backward(mlp.output, y))
mlp:updateParameters(0.01)

-- ── Full NNECCO cognitive agent ───────────────────────────────
local agent = nn.NNECCOAgent({
   stateSize      = 64,
   reservoirSize  = 847,
   llamaInstances = 4,    -- 4 parallel LLaMA.cpp instances
   stubMode       = true, -- set false when llama.cpp servers are running
})

local result = agent:process("Explain gradient descent")
print(result.output.text)
print("Action:", result.action, "Layer:", result.layer)
```

---

## Architecture

```
nn.Module
├── Standard NN Modules
│   ├── nn.Linear            Fully-connected layer
│   ├── nn.Sequential        Feed-forward container
│   ├── nn.Tanh / Sigmoid    Activation functions
│   ├── nn.ReLU / LeakyReLU  Rectified activations
│   ├── nn.ELU               Exponential linear unit
│   ├── nn.SoftMax           Probability normalisation
│   └── nn.LogSoftMax        Log-probability normalisation
│
├── Criterions
│   ├── nn.MSECriterion           Mean squared error
│   ├── nn.BCECriterion           Binary cross-entropy
│   ├── nn.ClassNLLCriterion      Negative log-likelihood
│   ├── nn.CrossEntropyCriterion  Softmax + NLL combined
│   └── nn.SmoothL1Criterion      Huber / smooth-L1
│
├── Cognitive Modules
│   ├── nn.EchoReservoir     Echo State Network reservoir
│   ├── nn.AtomSpace         OpenCog hypergraph knowledge base
│   ├── nn.Personality       Mutable personality trait tensor
│   ├── nn.EpisodicMemory    Priority-weighted experience replay
│   └── nn.LLaMAOrchestrator 1-9 parallel LLaMA.cpp instances
│
└── Agents
    ├── nn.Agent             Base RL agent (DQN-style)
    ├── nn.CognitiveAgent    Multi-agent orchestrator with delegation
    └── nn.NNECCOAgent       Full NNECCO pipeline (12-step EchoBeats)
```

---

## Module Reference

### Standard NN Modules

#### `nn.Linear(inSize, outSize [, bias])`
Fully-connected affine layer: **y = Wx + b**

```lua
local L = nn.Linear(10, 5)
local y = L:forward(input)    -- input: Tensor(10)
L:backward(input, gradOutput) -- gradOutput: Tensor(5)
L:updateParameters(lr)
```

#### `nn.Sequential()`
Chains modules in sequence.

```lua
local model = nn.Sequential()
model:add(nn.Linear(4, 16))
model:add(nn.ReLU())
model:add(nn.Linear(16, 2))
```

#### Activations
| Class | Formula |
|-------|---------|
| `nn.Tanh()` | tanh(x) |
| `nn.Sigmoid()` | 1/(1+e^−x) |
| `nn.ReLU()` | max(0, x) |
| `nn.LeakyReLU(α)` | x if x>0 else αx |
| `nn.ELU(α)` | x if x>0 else α(eˣ−1) |
| `nn.SoftMax()` | softmax(x) |
| `nn.LogSoftMax()` | log(softmax(x)) |

#### Criterions
| Class | Use case |
|-------|----------|
| `nn.MSECriterion()` | Regression |
| `nn.BCECriterion()` | Binary classification |
| `nn.CrossEntropyCriterion()` | Multi-class classification |
| `nn.SmoothL1Criterion()` | Robust regression |

---

### Cognitive Modules

#### `nn.EchoReservoir(inSize, N [, opts])`
Echo State Network (reservoir computing) layer.

```lua
local esn = nn.EchoReservoir(8, 200, {
   spectralRadius = 0.9,   -- controls memory length
   leakRate       = 0.7,   -- leaky integration
   sparsity       = 0.85,  -- fraction of zero connections
})

-- Single step
local state = esn:forward(inputTensor)

-- Full sequence
local states = esn:forwardSequence(sequenceTable)

-- Collect states after warmup
local collected = esn:collectStates(sequence, warmupSteps)
```

The spectral radius controls the *echo property*: values < 1 ensure
fading memory while remaining sensitive to temporal patterns.

#### `nn.AtomSpace()`
OpenCog-inspired hypergraph knowledge base.

```lua
local as  = nn.AtomSpace()
local cat = as:addNode("ConceptNode", "cat")
local ani = as:addNode("ConceptNode", "animal")
local lnk = as:addLink("InheritanceLink", {cat, ani},
                nn.TruthValue.new(0.9, 50))

-- Query
local concepts = as:getAtomsOfType("ConceptNode")
local links     = as:getLinks("InheritanceLink", {cat})
local incoming  = as:getIncoming(cat)
```

Atoms carry **TruthValues** (strength + count → confidence) and
**AttentionValues** (STI + LTI for importance scheduling).

#### `nn.Personality([traits, values])`
Mutable personality trait tensor with momentum-based drift.

```lua
local p = nn.Personality.NeuroSama()  -- Neuro-Sama archetype
print(p:get("curiosity"))             -- → 0.95
p:set("focus", 0.8)

-- Apply an experience (nudge traits)
p:experience(nn.Tensor.new({0.1, -0.05, ...}), 1.0)

-- Blend two personalities
local hybrid = p:blend(nn.Personality.Analytical(), 0.3)
```

Built-in archetypes: `NeuroSama()`, `Analytical()`.

#### `nn.EpisodicMemory([capacity, prioritised])`
Priority-weighted experience replay with similarity-based retrieval.

```lua
local mem = nn.EpisodicMemory(10000)
mem:push({state=s, action=a, reward=r, nextState=s2, done=false})

local batch, indices, weights = mem:sample(32)
mem:updatePriorities(indices, tdErrors)

local recent = mem:recent(5)
local similar = mem:retrieveSimilar(queryState, 3)
```

#### `nn.LLaMAOrchestrator(opts)`
Manages 1-9 parallel LLaMA.cpp server instances.

```lua
local orch = nn.LLaMAOrchestrator({
   numInstances = 4,
   basePort     = 8080,    -- ports 8080-8083
   modelPath    = "models/llama-7b.gguf",
   stubMode     = false,   -- true = echo stub (no server needed)
})
orch:initialize()

-- Single request (auto load-balances)
local res = orch:generate("Explain attention mechanisms", {
   temperature = 0.7,
   max_tokens  = 256,
})
print(res.text, "instance:", res.instance_id)

-- Batch request
local results = orch:batchGenerate({"prompt1", "prompt2"})

-- Status
local status = orch:getStatus()
print("Active instances:", status.available)
```

**Running real LLaMA.cpp servers:**
```bash
# Start 4 instances (one per terminal or use & background)
./llama-server -m models/llama-7b.gguf --port 8080 &
./llama-server -m models/llama-7b.gguf --port 8081 &
./llama-server -m models/llama-7b.gguf --port 8082 &
./llama-server -m models/llama-7b.gguf --port 8083 &
```

---

### Agents

#### `nn.Agent(opts)`
Base DQN-style reinforcement learning agent.

```lua
local agent = nn.Agent({
   stateSize    = 8,
   actionSize   = 4,
   gamma        = 0.99,
   epsilon      = 0.1,
   batchSize    = 32,
   learningRate = 1e-3,
})

local action = agent:act(state)
agent:remember(state, action, reward, nextState, done)
local loss = agent:learn()
```

#### `nn.CognitiveAgent(opts)`
Multi-agent orchestrator with hierarchical task delegation.

```lua
local manager = nn.CognitiveAgent({
   role           = "orchestrator",
   maxSubordinates = 4,
   stateSize      = 16,
   actionSize     = 4,
})

local worker = manager:spawnSubordinate({role = "worker"})

-- Delegate a task
local result = manager:delegate({type="infer", input=state}, worker.id)

-- Broadcast to all subordinates
local results = manager:broadcast({type="learn"})

-- Majority-vote aggregation
local action = manager:aggregateVote(state)
```

#### `nn.NNECCOAgent(opts)`
The full **Neural Network Embodied Cognitive Coprocessor Orchestrator**.

Implements the 12-step **EchoBeats** cognitive loop per processing cycle:

| Step | Name | Description |
|------|------|-------------|
| 1 | PERCEIVE | Raw sensory / text input ingestion |
| 2 | FILTER | Attentional filtering (suppress noise) |
| 3 | RESONATE | Echo State Reservoir processing |
| 4 | ENCODE | Semantic encoding (MLP) |
| 5 | RECALL | Episodic memory similarity search |
| 6 | REASON | LLaMA.cpp language model inference |
| 7 | EMOTE | Emotion vector update |
| 8 | PLAN | Action selection (ε-greedy + emotion modulation) |
| 9 | LEARN | RL experience replay update |
| 10 | REFLECT | Meta-cognition / consciousness layer adjustment |
| 11 | EXPRESS | Output generation (text + action) |
| 12 | INTEGRATE | State integration + knowledge graph update |

**Consciousness layers:**
- L0 DORMANT — suspended
- L1 REACTIVE — fast reflex responses
- L2 DELIBERATE — slower, reasoned responses
- L3 META — self-reflective reasoning

```lua
local agent = nn.NNECCOAgent({
   stateSize            = 64,
   actionSize           = 8,
   reservoirSize        = 847,
   llamaInstances       = 4,
   basePort             = 8080,
   personalityArchetype = "NeuroSama",  -- or "Analytical"
   stubMode             = true,         -- false = real llama.cpp
   verbose              = true,
})

-- Process a text query
local result = agent:process("How do echo state networks work?")
print(result.output.text)
print("Action:", result.action)
print("Layer:", result.layer)
print("Emotions:", result.emotions)

-- Hardware diagnostic
local hw = agent:getHardwareStatus()
print("Reservoir state norm:", hw.reservoir.stateNorm)
print("Active LLaMA instances:", hw.llama.available)
```

---

## Running the Tests

```bash
cd lang/a9nn
lua run_tests.lua           # all suites

lua test/test_basic.lua        # core NN modules only
lua test/test_cognitive.lua    # cognitive agent tests only
lua test/test_consistency.lua  # cross-implementation consistency fixture
```

Expected output: all tests pass with `✓`. The consistency suite checks the
shared fixture in `docs/fixtures/xor_fixture.json`, which every other port
(scm, rkt, raku, pl, isa) checks identically.

---

## Running the Examples

```bash
cd lang/a9nn
lua examples/mlp_example.lua         # MLP regression (sin curve)
lua examples/nnecco_example.lua      # Full NNECCO pipeline demo
lua examples/multi_agent_example.lua # 9-instance multi-agent demo
```

---

## File Layout

```
lang/a9nn/
├── init.lua               Main entry point (require 'a9nn')
├── nn_ns.lua              Namespace bootstrap (Class + Tensor)
├── class.lua              Lightweight OOP class system
├── tensor.lua             Pure-Lua N-D tensor (Torch fallback)
│
├── Module.lua             Base nn.Module
├── Container.lua          nn.Container base
├── Sequential.lua         nn.Sequential
├── Linear.lua             nn.Linear
├── activations.lua        Tanh, Sigmoid, ReLU, ELU, SoftMax, …
├── criterions.lua         MSE, BCE, NLL, CrossEntropy, SmoothL1
├── StochasticGradient.lua SGD trainer
│
├── EchoReservoir.lua      Echo State Network reservoir
├── AtomSpace.lua          OpenCog-style hypergraph KB
├── Personality.lua        Personality trait tensor
├── EpisodicMemory.lua     Priority experience replay
├── LLaMAOrchestrator.lua  1-9 parallel LLaMA.cpp instances
│
├── Agent.lua              Base RL agent
├── CognitiveAgent.lua     Multi-agent orchestrator
├── NNECCOAgent.lua        Full NNECCO pipeline
│
├── run_tests.lua          Test runner
├── test/
│   ├── test_basic.lua        Core NN tests
│   ├── test_cognitive.lua    Cognitive module tests
│   └── test_consistency.lua  Cross-implementation consistency fixture
└── examples/
    ├── mlp_example.lua          MLP sin regression
    ├── nnecco_example.lua       NNECCO full demo
    └── multi_agent_example.lua  9-instance multi-agent
```

---

## Design Principles

1. **Torch-compatible API** — same method signatures as `torch/nn` so
   existing Torch code can migrate incrementally.

2. **Pure-Lua fallback** — runs without Torch using a built-in N-D tensor
   implementation.  Performance-critical code benefits from Torch tensors.

3. **Privacy-first inference** — all LLaMA.cpp instances run locally;
   no data leaves the machine.

4. **Composable cognition** — every cognitive component is a
   `nn.Module` subclass and can be dropped into any `nn.Sequential`
   pipeline or composed with standard layers.

5. **Mutable personality** — agents drift over time in response to
   experiences, controlled by a momentum-based trait update rule.

---

## Related

- `lang/lua/` — original `torch/nn` Lua modules this extends
- [doc/overview.md](../../doc/overview.md) — neural network basics
- NNECCO architecture description in the agent system prompt

---

## License

BSD (inherited from `torch/nn`)
