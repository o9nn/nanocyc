# Neural Network Implementation in PLingua

A comprehensive P-Systems membrane computing implementation of feedforward neural networks with backpropagation training and modular architecture.

## Overview

This implementation demonstrates how neural network algorithms can be expressed using P-Systems and membrane computing principles. It provides a complete neural network library written in PLingua, the programming language for P-Systems.

## Features

### Core Functionality
- **Feedforward Neural Networks**: Arbitrary layer sizes and architectures
- **Backpropagation**: Complete training algorithm with gradient descent
- **Multiple Activation Functions**: Sigmoid, Tanh, ReLU
- **Softmax**: For multi-class classification with probability distributions
- **Loss Functions**: MSE (regression), NLL (classification), BCE (binary), Absolute Error
- **Modular Architecture**: Composable neural network components

### P-Systems Implementation
- **Membrane-Based Neurons**: Each neuron is a computational membrane
- **Rule-Based Computation**: Forward/backward passes implemented as evolution rules
- **Inter-Membrane Communication**: Data flows between layers via communication rules
- **Weight Evolution**: Training updates weights through rule application
- **Parallel Processing**: P-Systems natural parallelism models concurrent neural computation

### Modular Components
- **Container Modules**: Sequential, Concat, Parallel, ConcatTable, table ops (CAdd/CSub/CMul/CMax/CMin), Identity, Reshape
- **Transfer Modules**: Sigmoid, Tanh, ReLU, Softmax, LeakyReLU, PReLU, ELU, SELU, GELU, Softplus, HardTanh, HardSigmoid, LogSigmoid, LogSoftMax
- **Layer Modules**: Linear/Dense, LookupTable (embedding), Bilinear, SparseLinear
- **Criterion Modules**: MSE, NLL, BCE, Absolute Error, CrossEntropy, SmoothL1/Huber, Margin, KLDiv, weighted NLL
- **Initialization**: Xavier/Glorot and He/Kaiming schemes via `linear_layer_init`
- **Graph Neural Networks**: Message passing, GCN, graph attention (GAT), graph readout — membranes as graph nodes
- **Neuroevolution**: Genome membranes, mutation, crossover, division-based reproduction, tournament selection, NEAT-style topology evolution
- **Bayesian Layers**: Weight distributions, reparameterization trick, KL regularization, Monte-Carlo uncertainty estimates
- **Transformer Decoder**: Causal masking, masked self-attention, cross-attention, decoder stacks, positional encodings, greedy decoding
- **AtomSpace**: OpenCog-style hypergraph knowledge base — atoms as membranes, truth/attention values, ECAN attention spreading, Hebbian learning, pattern matching, attentional focus
- **a9nn NNECCO Agent**: full cognitive architecture — Echo State Reservoir, 12-step EchoBeats loop, emotion processing, consciousness layers (L0–L3), episodic memory, parallel LLaMA pool, hardware-style registers
- **PLN**: Probabilistic Logic Networks — deduction, induction, abduction, revision, conjunction, disjunction, negation, modus ponens over the AtomSpace (maximally-parallel forward chaining)
- **OpenPsi**: Dörner Psi motivational system — demands/drives, goal hierarchy, modulators, action selection, satisfaction feedback that drives the a9nn emotion unit
- **Unified Cognitive Cycle**: the a9nn EchoBeats spine with PLN (REASON), OpenPsi (EMOTE) and AtomSpace (RECALL/INTEGRATE) overlaid — an agent that *reasons, wants and remembers*
- **Arity Topologies**: mixed-radix membrane bases (`[2]^n` binary, `[3]^n` ternary, `[2|2]^n` quaternionic, `[5]^n` quinternary) executing heterogeneous ops in one parallel step; Matula/prime-power indexing of membrane trees; partition-function root selection; elementary differentials via product/chain rules
- **P-Systems ↔ B-Series Bridge**: rooted trees and membrane nests are the same combinatorial object, so evolution and gradient descent run in one parallel step; elementary differentials get exact integer (Matula) expressions as the gradient basis; RK order conditions as finite tree sums; orbifold quotient = "natural selection as root selection"
- **Closure Isomorphism**: `{circle ~ cycle ~ closure}` — one closure operator in spatial/temporal/causal frames, mapping `.mli`→CNN, `.gli`→RNN, `.nli`→GNN; the 3×3 ennead solves the frame problem; relevance flows like Ricci flow with the gauge field as the curvature lever

## Installation

No installation required! Simply ensure you have a PLingua simulator or interpreter.

### Requirements
- PLingua 5.0+ (recommended)
- P-Lingua Framework from [https://github.com/RGNC/plingua](https://github.com/RGNC/plingua)
- Java Runtime Environment (for P-Lingua simulator)

### Getting PLingua
```bash
# Clone P-Lingua repository
git clone https://github.com/RGNC/plingua.git
cd plingua

# Build (requires Java)
ant jar

# Or download pre-built from http://www.p-lingua.org
```

## Quick Start

### Basic Network Creation

```plingua
/* Create a simple feedforward network */
[network
    [layer1 linear_layer(2, 3)]'network
    [activation1 sigmoid_activation]'network
    [layer2 linear_layer(3, 1)]'network
    [activation2 sigmoid_activation]'network
]'main

/* Make prediction on input [0.5, 0.8] */
[input{1, 50}, input{2, 80}]'network  /* Values scaled by 100 */
```

### Training a Network

```plingua
/* Define training data */
training_data{
    sample{[0, 0], 0},
    sample{[0, 100], 100},
    sample{[100, 0], 100},
    sample{[100, 100], 0}
}

/* Train XOR network */
train_network(xor_network, training_data, 1000, 50)
```

### Using Pre-built Architectures

```plingua
/* XOR network (classic test) */
xor_network

/* Binary classifier */
binary_classifier(input_size: 2, hidden_size: 4)

/* Multi-class classifier */
multiclass_classifier(input_size: 4, hidden_size: 8, num_classes: 3)
```

## Architecture

### P-Systems Representation

#### Membranes as Neurons
```plingua
[neuron{1}
    weight{1, 20}    /* Weight for input 1 */
    weight{2, 30}    /* Weight for input 2 */
    bias{5}          /* Bias term */
]'layer
```

#### Objects as Data
```plingua
input{index, value}         /* Input activations */
output{index, value}        /* Output activations */
weight{index, value}        /* Network weights */
gradient{index, value}      /* Gradients for backprop */
```

#### Rules as Computations
```plingua
/* Forward pass: weighted sum */
[input{j, v}, weight{j, w}]'neuron{i} -> 
    [sum{i, v*w}]'neuron{i}

/* Activation: apply sigmoid */
[x{n}]'i -> [sig{round(100/(1+exp(-n/100)))}]'i

/* Backward pass: compute gradient */
[grad{i, g}, weight{j, w}]'neuron{i} ->
    []'neuron{i} (grad{j, g*w}, out)
```

### Data Flow

```
Input Layer          Hidden Layer         Output Layer
    [  ]  -------->      [  ]  -------->     [  ]
    [  ]  -------->      [  ]  -------->     [  ]
    [  ]  -------->      [  ]  
         (rules)         (rules)           (rules)
         
Forward:  Input → Weighted Sum → Activation → Next Layer
Backward: Gradient ← Weight × Gradient ← Loss
```

## API Reference

### Activation Functions

#### Sigmoid
```plingua
@module sigmoid_activation
/* Range: (0, 1) */
/* Use: Binary classification, output layer */
```

#### Tanh
```plingua
@module tanh_activation
/* Range: (-1, 1) */
/* Use: Hidden layers, zero-centered */
```

#### ReLU
```plingua
@module relu_activation
/* Range: [0, ∞) */
/* Use: Deep networks, fast training */
```

### Layer Modules

#### Linear Layer
```plingua
@module linear_layer(input_size, output_size)
/* Fully connected layer */
/* Computes: output = input × weights + bias */
```

### Loss Functions

#### Mean Squared Error
```plingua
@module mse_criterion
/* For regression tasks */
/* MSE = (1/n) × Σ(predicted - target)² */
```

#### Negative Log Likelihood
```plingua
@module nll_criterion
/* For classification tasks */
/* NLL = -log(P(true_class)) */
```

### Container Modules

#### Sequential Network
```plingua
@module sequential_network(layers)
/* Chains modules in sequence */
/* Example: [Linear, ReLU, Linear, Sigmoid] */
```

### Training

#### Train Network
```plingua
@module train_network(network, data, epochs, learning_rate)
/* Implements mini-batch gradient descent */
/* Updates weights via backpropagation */
```

### Graph Neural Networks (gnn.pli)

#### GCN Layer
```plingua
@module gcn_layer(num_nodes, in_dim, out_dim)
/* Degree-normalized graph convolution with shared projection */
/* Nodes are membranes; edges are edge{i, j, w} objects */
```

#### Graph Attention Layer
```plingua
@module graph_attention_layer(num_nodes, feat_dim)
/* GAT: per-edge attention coefficients with softmax normalization */
```

#### Graph Readout
```plingua
@module graph_readout(num_nodes, feat_dim)
/* Global sum/mean/max pooling into a graph-level embedding */
```

### Neuroevolution (neuroevolution.pli)

#### Divide and Mutate
```plingua
@module divide_and_mutate(fitness_threshold)
/* Fit genome membranes divide (elite + mutated offspring); */
/* unfit genomes dissolve - native P-Systems division/dissolution */
```

#### Neuroevolution Loop
```plingua
@module neuroevolution_loop(pop_size, generations, mutation_rate)
/* Orchestrates evaluate -> select -> divide/mutate phases */
```

### Bayesian Layers (bayesian.pli)

#### Bayesian Linear Layer
```plingua
@module bayes_linear_layer(input_size, output_size)
/* Weight distributions w_mu / w_rho; reparameterization trick */
/* w = mu + softplus(rho) * eps, eps ~ N(0, 1) */
```

#### Monte-Carlo Prediction
```plingua
@module mc_predict(num_samples)
/* Stochastic forward passes -> pred_mean / pred_var (uncertainty) */
```

### Transformer Decoder (transformer_decoder.pli)

#### Masked Self-Attention
```plingua
@module masked_self_attention(seq_len, d_k)
/* Causal `where j <= i` guard: no attention to future positions */
```

#### Decoder Block and Full Transformer
```plingua
@module transformer_decoder_block(tgt_len, src_len, d_model, num_heads, d_ff)
@module full_transformer(vocab_size, src_len, tgt_len, d_model, num_heads, d_ff, num_layers)
/* Masked self-attention -> cross-attention -> FFN, each add&norm */
```

#### Greedy Decoding
```plingua
@module greedy_decode(vocab_size, max_len, eos_token)
/* Autoregressive generation via argmax over last-position logits */
```

### AtomSpace (atomspace.pli)

The P-Systems counterpart of `lang/a9nn/AtomSpace.lua`: an OpenCog-style
hypergraph knowledge base where **atoms are membranes** and attention
spreading is native multiset rewriting.

#### Atoms (Nodes and Links)
```plingua
@module atom_node(id, type, name, s0, c0, sti0, lti0)
/* A typed, named leaf atom membrane carrying tv{s,c} and av{sti,lti} */

@module atom_link(id, type)
/* A link membrane that CONTAINS its endpoint atom membranes, */
/* so hypergraph nesting is structural; endpoints record incoming ids */
```

#### Truth-Value Revision
```plingua
@module tv_revision
/* Merging two observations weight-averages strength by count (k=1): */
/* s' = (s1*c1 + s2*c2)/(c1+c2);  c' = (c1+c2)*100/(c1+c2+100) */
```

#### ECAN Attention Spreading
```plingua
@module ecan_spread(wage)
/* STI is a conserved currency: focused atoms pay a wage that flows as  */
/* income to their link-neighbours via antiport exchange. One           */
/* maximally-parallel step diffuses STI across the whole focus.         */
```

#### Hebbian Learning
```plingua
@module hebbian_learning(strength0)
/* Co-focused atoms emit simultaneous pulses; a pulse pair wires a      */
/* symmetric HebbianLink ("fire together, wire together").              */
```

#### Pattern Matching and Attentional Focus
```plingua
@module atomspace_matcher            /* query_type{T} / query_link{T,X} */
@module attentional_focus(threshold) /* in_focus{} is derived, not stored */
```

### a9nn NNECCO Agent (a9nn.pli)

The P-Systems counterpart of `lang/a9nn/NNECCOAgent.lua`: the full NNECCO
cognitive architecture, layered on `atomspace.pli`. The 12-beat EchoBeats
cycle that Lua runs as a sequential method chain becomes a single
maximally-parallel rule system phase-locked by a program-counter register.

#### Subsystems
```plingua
@module echo_reservoir(in_size, reservoir_n, spectral_radius, leak_rate)
/* Echo State Network: leaky-integrator neurons, recurrent synapse objects */

@module emotion_unit          /* 8 channels: curiosity, joy, surprise, ...   */
@module consciousness(layer0) /* L0 DORMANT .. L3 META, loss-driven REFLECT  */
@module episodic_memory(capacity) /* prioritised experience replay          */
@module llama_pool(num_instances, base_port)  /* least-load dispatch, stub  */
@module planner(action_size)  /* emotion-modulated argmax action selection  */
```

#### The Agent and the EchoBeats Cycle
```plingua
@model nnecco_agent(state_size, action_size, reservoir_n,
                    num_llama, base_port, consciousness0)
/* Top-level composite with hardware registers R0..R4, PC, STA */

@module echobeats_driver
/* PC-gated 12-beat loop:                                  */
/* 1 PERCEIVE  2 FILTER  3 RESONATE  4 ENCODE              */
/* 5 RECALL    6 REASON  7 EMOTE     8 PLAN                */
/* 9 LEARN    10 REFLECT 11 EXPRESS  12 INTEGRATE          */
```

### PLN (pln.pli)

Probabilistic Logic Networks over `atomspace.pli`: OpenCog's inference engine
as membrane rules. Counterpart of ReZorg/plingua's `opencog_pln.pli`, in the
pure `@module`/`@rules` dialect. Forward chaining is a **single
maximally-parallel transition**, not a loop.

#### Inference Rules
```plingua
@module pln_deduction    /* A->B, B->C |- A->C : s = sAB*sBC/100          */
@module pln_induction    /* A->B, A->C |- B->C : s = sAB*sAC/100          */
@module pln_abduction    /* A->B, B    |- A    : tentative (c * 50/100)   */
@module pln_operators    /* AND/OR/NOT/modus-ponens truth-value formulas  */
@module pln_revision     /* merge duplicate conclusions (count-based TV)  */
@module pln_forward_chain(max_cycles)  /* bounded parallel forward chain  */
```

### OpenPsi (openpsi.pli)

Dörner Psi motivational system: demands (competence, integrity, exploration,
affiliation) accrue tension, become urgent, activate goals, and drive action
selection. **Closes the loop with a9nn**: modulators map onto the a9nn
`emotion_unit` channels, so motivation is *felt* and outcomes feed back as
reward.

#### Subsystems
```plingua
@module psi_demands           /* demand{id, tension, rate, threshold}     */
@module psi_goals             /* urgent demand -> active_goal             */
@module psi_action_selection  /* argmax expected relief -> action_token   */
@module psi_satisfaction      /* reward lowers demand tension (feedback)  */
@module psi_modulators        /* activation/resolution/... -> emotion     */
@model  openpsi_system        /* composite, psi_pc-phase-locked           */
```

### Unified Cognitive Cycle (unified.pli)

The integration layer: the a9nn EchoBeats spine with PLN, OpenPsi and the
AtomSpace overlaid so the agent *reasons, wants and remembers*. Counterpart of
ReZorg/plingua's `opencog_unified_agi.pli`. Each subsystem stays in its own
membrane; the PC register phase-locks them and objects flow across boundaries.

#### Beat overlays
```plingua
@module uni_recall(focus_threshold)  /* RECALL  <- AtomSpace ECAN focus   */
@module uni_reason                   /* REASON  <- PLN forward chain       */
@module uni_emote                    /* EMOTE   <- OpenPsi modulators      */
@module uni_learn                    /* LEARN   <- PLN revision + RL loss  */
@module uni_integrate                /* INTEGRATE-> persist learned atoms  */
@model  unified_agent(state_size, action_size, reservoir_n,
                      num_llama, base_port, consciousness0)
```

### Arity Topologies (topology.pli)

Makes concrete the observation that a membrane tree's *shape* is
simultaneously a rooted tree (Matula/prime-factorisation number), the arity of
a categorical logic, a mixed-radix parallel basis, and an evolutionary engine
whose partition function performs "natural selection as root selection".

#### Mixed-radix bases (heterogeneous parallel ops in one step)
```plingua
@module binary_basis(n)        /* [2]^n    -> 2^n boolean lanes           */
@module ternary_basis(n)       /* [3]^n    -> 3^n trit lanes              */
@module quaternionic_basis(n)  /* [2|2]^n  -> 4^n orthogonal pairs        */
@module quinternary_basis(n)   /* [5]^n    -> 5^n lanes                   */
```

#### Indexing, differentials, selection
```plingua
@module matula_index              /* rooted tree <-> prime factorisation   */
@module elementary_differentials  /* product (k*r+1) & chain (r+s) rules   */
@module partition_selection       /* Z over free hyper-multiset -> root    */
```

### P-Systems ↔ B-Series Bridge (bseries.pli)

The rooted trees of a B-series (Runge-Kutta elementary differentials) and
membrane nests are the *same* combinatorial object (nested parentheses ↔
ordered rooted trees). This module plants trees in their nests and threads
branches through complementary nests so P-System **evolution** and B-series
**gradient descent** run in the same maximally-parallel step — uniting the two
principal adaptation techniques of ML. Elementary differentials (and the
j-surfaces of the gradient basis) get exact integer expressions via Matula
numbers; the orbifold quotient makes "natural selection" act as *root*
selection.

#### Modules
```plingua
@module tree_nest_bridge            /* plant tree in nest; thread branches */
@module elementary_weights          /* order/density/symmetry -> b=1/(sg)  */
@module bseries_gradient_step(lr)   /* w <- w - lr*grad/(s*g): flow=update */
@module rk_order_conditions         /* order 1..3 as finite tree sums      */
@module orbifold_quotient           /* canonify (min Matula); root select  */
```

### Closure Isomorphism & the Frame Problem (closures.pli)

`{circle ~ cycle ~ closure}` — a single closure operator instantiated in three
frames, each a dialect of the platform *and* a neural architecture:

| Frame | Closure | Dialect | Architecture | Conserved (Noether) |
|-------|---------|---------|--------------|---------------------|
| **Spatial** | structural (receptive field) | `.mli` morphological | **CNN** | translation (weight sharing) |
| **Temporal** | procedural (recurrence) | `.gli` generational | **RNN** | time-translation (periodicity) |
| **Causal** | relational (message passing) | `.nli` nomological | **GNN** | symmetry currents (Lie algebra) |

The **ennead** (3 poles × 3 frames = 9 dimensions) solves the frame problem: a
balanced ennead is precisely the condition that no frame boundary needs
re-specifying as the situation changes. Relevance flows like **Ricci flow**;
the lever parameterizing curvature is the **gauge field** (connection), whose
parallel transport of n-forms has holonomy equal to the curvature; curvature
sign (convex/concave) drives the conserved currents, and gauge invariance is
itself the conserved quantity.

#### Modules
```plingua
@module closure_isomorphism   /* one closure, three frames, inter-mapped  */
@module spatial_cnn(k)        /* .mli: receptive field = spatial closure  */
@module temporal_rnn(period)  /* .gli: recurrence; periodic time loops    */
@module causal_gnn            /* .nli: message passing; Noether currents  */
@module ennead_frame          /* 3x3 balance resolves the frame problem   */
@module ricci_relevance       /* g'=g-2Ric*g; gauge field = curvature lever */
```

### Inference

#### Predict
```plingua
@module predict(network, input)
/* Use trained network for predictions */
/* Sets evaluation mode (no gradients) */
```

## Examples

### Example 1: Simple Linear Regression

Learn the function y = 2x₁ + 3x₂

```plingua
/* Network: 2 inputs -> 1 output (no hidden layer) */
[network linear_layer(2, 1)]'main

/* Training data */
training_data{
    sample{[10, 10], 50},   /* 2×10 + 3×10 = 50 */
    sample{[20, 10], 70},   /* 2×20 + 3×10 = 70 */
    sample{[10, 20], 80}    /* 2×10 + 3×20 = 80 */
}

/* Train for 100 epochs with learning rate 0.1 */
train_network(network, training_data, 100, 10)

/* Predict for new input [25, 15] */
[input{1, 25}, input{2, 15}]'network
/* Expected: 2×25 + 3×15 = 95 */
```

### Example 2: XOR Problem

The classic non-linear problem requiring a hidden layer.

```plingua
/* XOR needs hidden layer (not linearly separable) */
[xor_net
    [layer1 linear_layer(2, 4)]'xor_net
    [tanh1 tanh_activation]'xor_net
    [layer2 linear_layer(4, 1)]'xor_net
    [sigmoid1 sigmoid_activation]'xor_net
]'main

/* XOR truth table */
xor_data{
    sample{[0, 0], 0},
    sample{[0, 100], 100},
    sample{[100, 0], 100},
    sample{[100, 100], 0}
}

/* Train */
train_network(xor_net, xor_data, 1000, 50)

/* Results after training:
 * XOR(0,0) → 0
 * XOR(0,1) → 1
 * XOR(1,0) → 1
 * XOR(1,1) → 0
 */
```

### Example 3: Multi-Class Classification

Classify into 3 categories using softmax.

```plingua
/* 3-class classifier: 4 inputs -> 8 hidden -> 3 outputs */
[classifier
    [layer1 linear_layer(4, 8)]'classifier
    [relu1 relu_activation]'classifier
    [layer2 linear_layer(8, 3)]'classifier
    [softmax1 softmax]'classifier
]'main

/* Training data with 3 classes */
training_data{
    /* Class 0: low values */
    sample{[10, 15, 12, 18], 0},
    
    /* Class 1: medium values */
    sample{[40, 45, 50, 42], 1},
    
    /* Class 2: high values */
    sample{[80, 85, 90, 82], 2}
}

/* Train */
train_network(classifier, training_data, 300, 15)

/* Predict and get class probabilities */
[input{1, 12}, input{2, 18}, input{3, 15}, input{4, 20}]'classifier

/* Output: probabilities for each class summing to 1.0 */
[probability{1, p1}, probability{2, p2}, probability{3, p3}]'softmax
/* predicted_class = argmax([p1, p2, p3]) */
```

### Example 4: Binary Classification

Classify points above/below a diagonal line.

```plingua
/* 2 -> 4 -> 1 network with ReLU and Sigmoid */
[classifier
    [layer1 linear_layer(2, 4)]'classifier
    [relu1 relu_activation]'classifier
    [layer2 linear_layer(4, 1)]'classifier
    [sigmoid1 sigmoid_activation]'classifier
]'main

/* Data: classify if y > x */
training_data{
    /* Below diagonal (class 0) */
    sample{[50, 30], 0},
    sample{[70, 40], 0},
    
    /* Above diagonal (class 1) */
    sample{[30, 50], 1},
    sample{[40, 70], 1}
}

train_network(classifier, training_data, 200, 20)
```

## Running Tests

```bash
# Run core test suite
plingua test_nn.pli

# Expected output:
# Total Tests: 11
# Passed: 11
# Failed: 0
# Success Rate: 100%

# Run extension test suite
plingua test_extensions.pli

# Expected output:
# Total Tests: 78
# Passed: 78
# Failed: 0
# Success Rate: 100%
```

### Test Coverage (core: test_nn.pli)
- ✅ Sigmoid activation function
- ✅ Tanh activation function
- ✅ ReLU activation function
- ✅ Linear layer forward pass
- ✅ MSE loss computation
- ✅ NLL loss computation
- ✅ Softmax normalization
- ✅ XOR network structure
- ✅ Sequential composition
- ✅ Training loop execution
- ✅ Gradient computation

### Test Coverage (extensions: test_extensions.pli)
- ✅ SGD with momentum and Adam update rules
- ✅ Batch normalization statistics (train mode)
- ✅ Dropout masks and eval-mode identity
- ✅ Conv2D output shapes and max pooling
- ✅ LSTM cell-state gate evolution
- ✅ Gradient clipping by value
- ✅ LeakyReLU, ELU, LogSoftMax activations
- ✅ BCE, CrossEntropy, SmoothL1 criteria
- ✅ CAddTable, Identity, Reshape containers
- ✅ LookupTable embedding lookup
- ✅ Scaled dot-product attention scores
- ✅ SN P neuron firing and sub-threshold behavior
- ✅ Exporter save/load weight round-trip
- ✅ GCN degree-normalized aggregation and graph readout pooling
- ✅ Membrane-division reproduction and tournament selection
- ✅ Bayesian reparameterized weights and Monte-Carlo mean
- ✅ Causal mask and decoder-block residual connection
- ✅ Atom node/link membranes and hypergraph nesting
- ✅ Truth-value revision (count-weighted strength merge)
- ✅ ECAN attention spreading (STI conservation, wage→income)
- ✅ Hebbian link formation between co-focused atoms
- ✅ AtomSpace pattern matching and attentional focus
- ✅ a9nn reservoir leaky tick and EchoBeats PC cycling
- ✅ Emotion update and consciousness REFLECT transitions
- ✅ Episodic memory push/recall and LLaMA least-load dispatch
- ✅ PLAN argmax action selection and INTEGRATE episode logging
- ✅ PLN deduction, induction, modus ponens and negation truth values
- ✅ OpenPsi demand urgency, action selection, satisfaction and emotion bridge
- ✅ Unified cycle: RECALL premises, REASON conclusion, EMOTE bridge, LEARN revision, INTEGRATE persistence
- ✅ Mixed-radix lane counts, Matula leaf/chain/product indexing, differential orders, partition selection
- ✅ B-Series bridge: tree↔nest planting, elementary weights, gradient step, RK order-1, orbifold canonify
- ✅ Closure isomorphism (spatial/temporal/causal), CNN/RNN/GNN maps, ennead balance, Ricci/gauge lever

## Running Demos

```bash
# Run all demonstrations
plingua demo.pli

# Demos included:
# 1. Basic network creation and prediction
# 2. XOR problem (classic test)
# 3. Activation functions comparison
# 4. Loss functions demonstration
# 5. Multi-layer network
# 6. Training visualization
# 7. Binary classification
# 8. Optimizer comparison (SGD vs Adam)
# 9. LeNet-5 convolutional network
# 10. LSTM sequence prediction
# 11. Attention weights
# 12. Spiking Neural P System XOR
# 13. GNN node classification on a toy graph
# 14. Evolving XOR weights (membrane-division neuroevolution)
# 15. Bayesian Monte-Carlo uncertainty on a noisy regression point
# 16. Greedy decoding of a 4-token sequence
```

## Running Examples

```bash
# Run all practical examples
plingua example.pli

# Or run specific example
plingua example.pli --run xor_function

# Examples included:
# 1. simple_prediction
# 2. linear_regression
# 3. binary_classifier_example
# 4. multiclass_classification
# 5. xor_function
# 6. custom_architecture
# 7. incremental_training
# 8. loss_function_comparison
# 9. xavier_initialization
# 10. word_embedding_example
# 11. lstm_sequence_prediction
# 12. weighted_loss_example
# 13. snp_xor_example
```

## Validating Syntax

Because no PLingua interpreter ships with this repository, a lightweight
validation script is provided to check the `.pli` sources:

```bash
# Structural checks (comment/brace/bracket balance) - no dependencies
./validate.sh

# Full syntax check if the P-Lingua 5 compiler is on your PATH
# (see https://github.com/RGNC/plingua)
PLINGUA=plingua ./validate.sh
```

## Key Concepts

### P-Systems and Neural Networks

This implementation demonstrates the natural mapping between P-Systems and neural networks:

| Neural Network | P-System |
|----------------|----------|
| Neuron | Membrane |
| Weight | Object with multiplicity |
| Activation | Evolution rule |
| Forward pass | Rule application + communication |
| Layer | Membrane region |
| Network | Membrane structure |
| Backpropagation | Reverse communication |
| Training | Iterative rule application |

### Why P-Systems for Neural Networks?

1. **Natural Parallelism**: P-Systems model concurrent computation, matching neural networks' parallel nature
2. **Hierarchical Structure**: Nested membranes represent network layers elegantly
3. **Rule-Based**: Computations as rules are declarative and clear
4. **Communication**: Inter-membrane communication models data flow naturally
5. **Formal Semantics**: P-Systems have well-defined semantics for verification

### Membrane Computing Principles

- **Membranes**: Define computational compartments (neurons/layers)
- **Objects**: Represent data (activations, weights, gradients)
- **Evolution Rules**: Define computations (forward/backward passes)
- **Communication Rules**: Transfer objects between membranes
- **Maximally Parallel**: Rules apply concurrently when possible

## Implementation Details

### Numerical Encoding

Values are scaled by 100 for integer representation:
- `0.5` → `50`
- `1.0` → `100`
- `-0.3` → `-30`

This allows membrane computing (typically using discrete objects) to approximate continuous neural network computations.

### Gradient Descent

Weight updates follow standard gradient descent:
```
weight_new = weight_old - learning_rate × gradient
```

Implemented as rule:
```plingua
[weight{j, w}, weight_grad{j, g}, learning_rate{lr}]'neuron{i} ->
    [weight{j, w - lr*g}]'neuron{i}
```

### Forward Propagation

1. Input enters first layer
2. Each neuron computes weighted sum: Σ(input × weight) + bias
3. Apply activation function
4. Send output to next layer
5. Repeat until output layer

### Backpropagation

1. Compute loss gradient at output
2. For each layer (reverse order):
   - Receive gradient from next layer
   - Compute weight gradients: gradient × input
   - Compute input gradient: gradient × weight
   - Update weights
   - Send input gradient to previous layer

## Performance Characteristics

- **Training Speed**: Suitable for small networks and datasets
- **Memory Usage**: Minimal, scales with network size
- **Best For**:
  - Networks with < 100 neurons
  - Datasets with < 1000 samples  
  - Educational purposes
  - Demonstrating P-Systems capabilities
  - Conceptual implementations

- **Not Suitable For**:
  - Large-scale production systems
  - Deep learning (many layers)
  - Real-time high-throughput applications
  - GPU acceleration requirements

## Educational Value

This implementation is ideal for:
- **Learning Neural Networks**: Clear, declarative expression of algorithms
- **Understanding P-Systems**: Practical application of membrane computing
- **Teaching ML**: Seeing algorithms from a different perspective
- **Formal Methods**: Leveraging P-Systems' formal semantics
- **Interdisciplinary Study**: Connecting ML and theoretical computer science

## Comparison with Traditional Implementations

| Feature | Traditional (Python/C++) | PLingua (P-Systems) |
|---------|-------------------------|---------------------|
| Paradigm | Imperative/OOP | Declarative/Rule-based |
| Parallelism | Explicit (threading) | Implicit (maximal parallel) |
| Structure | Classes/Functions | Membranes/Rules |
| Data Flow | Variables/Pointers | Objects/Communication |
| Semantics | Operational | Formal (P-Systems) |
| Performance | Fast | Moderate |
| Clarity | Implementation-focused | Concept-focused |
| GPU Support | Yes | No |
| Best For | Production | Education/Research |

## Limitations

1. **Limited Precision**: Integer arithmetic (×100 scaling; some modules use ×10000) approximates continuous values
2. **Simplified Backprop**: Full computation graph not implemented
3. **No GPU**: P-Systems simulators run on CPU
4. **Small Scale**: Best for educational/proof-of-concept use
5. **No Interpreter Bundled**: Requires an external P-Lingua simulator to execute

## Future Enhancements

Completed extensions:
- [x] Momentum and adaptive learning rates (Adam, RMSprop) — `momentum_adam_rmsprop.pli`
- [x] Batch normalization — `batch_normalization.pli`
- [x] Dropout for regularization — `dropout.pli`
- [x] Convolutional layers (2D membrane regions) — `convolutional.pli`
- [x] Recurrent networks (temporal P-Systems) — `recurrent.pli`
- [x] More sophisticated backpropagation — `backpropagation.pli`
- [x] Visualization of membrane evolution — `visualization.pli`
- [x] Integration with existing P-Lingua tools — `integration.pli`
- [x] Extended activations, criteria, containers, layers — `activations.pli`, `criteria.pli`, `containers.pli`, `layers.pli`
- [x] Attention/transformer modules — `attention.pli`
- [x] Spiking Neural P Systems — `snp.pli`
- [x] Graph neural network modules (membranes as graph nodes) — `gnn.pli`
- [x] Neuroevolution via membrane division rules — `neuroevolution.pli`
- [x] Probabilistic P-Systems for Bayesian layers — `bayesian.pli`
- [x] Full transformer decoder with causal masking — `transformer_decoder.pli`
- [x] AtomSpace hypergraph knowledge base (ECAN, Hebbian, matcher) — `atomspace.pli`
- [x] a9nn NNECCO cognitive agent (reservoir, EchoBeats, emotion, LLaMA pool) — `a9nn.pli`
- [x] PLN probabilistic inference (deduction/induction/abduction/modus-ponens) — `pln.pli`
- [x] OpenPsi motivational system (demands, goals, action selection, emotion bridge) — `openpsi.pli`
- [x] Unified cognitive cycle (PLN + OpenPsi + AtomSpace over the EchoBeats spine) — `unified.pli`
- [x] Membrane arity topologies (mixed-radix bases, Matula indexing, partition selection) — `topology.pli`
- [x] P-Systems ↔ B-Series bridge (shared tree/nest topology, gradient descent as ODE flow, orbifold root selection) — `bseries.pli`
- [x] Closure isomorphism across spatial/temporal/causal frames (`.mli`→CNN, `.gli`→RNN, `.nli`→GNN) + ennead frame resolution + Ricci-flow relevance — `closures.pli`

## References

### P-Systems and PLingua
- [P-Lingua Official Site](http://www.p-lingua.org)
- [P-Lingua GitHub](https://github.com/RGNC/plingua)
- Păun, G. (2000). "Computing with Membranes"
- García-Quismondo, M., et al. (2009). "P-Lingua: A Programming Language for Membrane Computing"

### Neural Networks
- Rumelhart, D., et al. (1986). "Learning representations by back-propagating errors"
- Goodfellow, I., et al. (2016). "Deep Learning"
- Nielsen, M. (2015). "Neural Networks and Deep Learning"

### Membrane Computing and ML
- Song, T., et al. (2019). "Spiking Neural P Systems: Applications and Modeling"
- Păun, G., et al. (2010). "The Oxford Handbook of Membrane Computing"

## License

This implementation follows the license of the parent nn.nn repository.

## Extensions (v2.0)

The following modules extend the core implementation with advanced features:

| Module | Description |
|--------|-------------|
| `momentum_adam_rmsprop.pli` | SGD+Momentum, AdaGrad, RMSprop, Adam, AdamW, LR schedulers |
| `batch_normalization.pli` | Batch Normalization + Layer Normalization (train/eval modes) |
| `dropout.pli` | Standard, Spatial 2D, Alpha, and DropConnect dropout |
| `convolutional.pli` | Conv2D, DepthwiseSep, TransposedConv, MaxPool, AvgPool, GAP |
| `recurrent.pli` | Elman RNN, LSTM, GRU, Bidirectional, Stacked, Seq2Seq |
| `backpropagation.pli` | Grad clipping, accumulation, Newton, natural grad, TBPTT, GCP |
| `visualization.pli` | Topology snapshots, heatmaps, gradient flow, training curves |
| `integration.pli` | Module registry, data ingestion, export bridges, save/load weights, benchmarks |

## Extensions (v2.1)

| Module | Description |
|--------|-------------|
| `activations.pli` | LeakyReLU, PReLU, ELU, SELU, GELU, Softplus, HardTanh, HardSigmoid, LogSigmoid, LogSoftMax |
| `criteria.pli` | CrossEntropy (fused), SmoothL1/Huber, Margin, KLDiv, weighted NLL |
| `containers.pli` | Concat, Parallel, ConcatTable, CAdd/CSub/CMul/CMax/CMin tables, Identity, Reshape |
| `layers.pli` | LookupTable (embedding), Bilinear, SparseLinear, Xavier/He initialization |
| `attention.pli` | Scaled dot-product attention, multi-head attention, transformer encoder block, native batch processing |
| `snp.pli` | Spiking Neural P Systems: SN P neurons, synapses, spike-train encoding, rate-coded bridge, SN P XOR |
| `test_extensions.pli` | 78 tests covering all extension, v2.1, v2.2, v2.3, v2.4, v2.5, v2.6 and v2.7 modules |

## Extensions (v2.2)

| Module | Description |
|--------|-------------|
| `gnn.pli` | Graph neural networks with membranes as graph nodes: message passing (sum/mean/max), GCN layer with degree normalization and backward pass, graph attention (GAT), graph readout |
| `neuroevolution.pli` | Neuroevolution via membrane division: genome membranes, point mutation, antiport crossover, divide-and-mutate reproduction, tournament selection, NEAT-style structural mutation, evolution loop |
| `bayesian.pli` | Probabilistic P-Systems for Bayesian layers: Gaussian sampler (central-limit), Bayes-by-Backprop linear layer, KL divergence regularizer, Monte-Carlo predictive mean/variance |
| `transformer_decoder.pli` | Full transformer decoder with causal masking: masked self-attention, cross-attention, masked multi-head attention, decoder blocks/stacks, sinusoidal positional encoding, full encoder-decoder transformer, greedy decoding |

## Extensions (v2.3)

| Module | Description |
|--------|-------------|
| `atomspace.pli` | OpenCog-style hypergraph knowledge base: atom nodes/links as membranes (structural nesting), truth values with count-based revision, attention values (STI/LTI), ECAN attention spreading as conserved-currency antiport exchange, Hebbian learning, pattern matching, derived attentional focus. Mirrors `lang/a9nn/AtomSpace.lua`. |
| `a9nn.pli` | NNECCO cognitive agent: Echo State Reservoir membrane (leaky-integrator neurons, spectral radius), 12-beat EchoBeats loop phase-locked by a PC register, emotion processing unit (8 channels), consciousness layers L0–L3 with loss-driven meta-cognition, prioritised episodic memory, parallel LLaMA pool (least-load antiport dispatch, stub mode), hardware-style registers R0–R4/PC/STA. Mirrors `lang/a9nn/NNECCOAgent.lua`. |

## Extensions (v2.4)

| Module | Description |
|--------|-------------|
| `pln.pli` | Probabilistic Logic Networks over the AtomSpace: deduction, induction, abduction, revision, conjunction, disjunction, negation, modus ponens with SimpleTruthValue strength/confidence formulas; maximally-parallel forward chaining (`pln_forward_chain`). Counterpart of ReZorg/plingua `opencog_pln.pli`. |
| `openpsi.pli` | Dörner Psi motivational system: demands (competence/integrity/exploration/affiliation) with accrual→urgency, goal activation, argmax action selection, satisfaction feedback, and modulators that drive the a9nn `emotion_unit`. Counterpart of ReZorg/plingua `opencog_openpsi.pli`. |

## Extensions (v2.5)

| Module | Description |
|--------|-------------|
| `unified.pli` | Unified cognitive cycle: the a9nn EchoBeats spine with PLN (REASON), OpenPsi (EMOTE) and AtomSpace (RECALL/INTEGRATE) overlaid — the agent reasons, wants and remembers. `uni_recall`/`uni_reason`/`uni_emote`/`uni_learn`/`uni_integrate` beat overlays + `unified_agent` composite. Counterpart of ReZorg/plingua `opencog_unified_agi.pli`. |
| `topology.pli` | Membrane arity topologies: mixed-radix parallel bases (`binary/ternary/quaternionic/quinternary`, i.e. `[2]^n`/`[3]^n`/`[2|2]^n`/`[5]^n`) executing heterogeneous ops in one step; Matula/prime-power indexing of membrane trees (rooted-tree ↔ prime-factorisation); elementary differentials via product (`k*r+1`) and chain (`r+s`) rules; partition-function root selection over free hyper-multisets. |

## Extensions (v2.6)

| Module | Description |
|--------|-------------|
| `bseries.pli` | P-Systems ↔ B-Series bridge: rooted trees planted in membrane nests (shared topology), branches threaded through complementary nests so interfaces coincide. `tree_nest_bridge`, `elementary_weights` (order/density/symmetry → `b(t)=1/(σ·γ)` from Matula integers), `bseries_gradient_step` (gradient descent = ODE flow: `w ← w − lr·grad/(σ·γ)`), `rk_order_conditions` (order 1–3 as finite tree sums), `orbifold_quotient` (canonify to minimal Matula; natural selection as root selection). Unites P-System evolution with B-series gradient descent in one maximally-parallel step. |

## Extensions (v2.7)

| Module | Description |
|--------|-------------|
| `closures.pli` | Closure isomorphism across frames: `{circle ~ cycle ~ closure}` — one closure operator in spatial/temporal/causal frames, mapping `.mli`→CNN (receptive field = spatial closure), `.gli`→RNN (recurrence = temporal closure), `.nli`→GNN (message passing = relational closure). `closure_isomorphism`, `spatial_cnn`, `temporal_rnn`, `causal_gnn` (Noether conserved currents), `ennead_frame` (3×3 balance solves the frame problem), `ricci_relevance` (Ricci-flow `g′=g−2·Ric·g`; the gauge field/connection is the curvature lever — holonomy of parallel transport = curvature; gauge invariance is the conserved quantity). |

### Looking ahead: nD membranes and parallel ledgers

Two directions this port is positioned for:

- **nD generalisation.** 1D/2D/3D spatial models (as in ReZorg's M-Lingua
  `.mli`) generalise to *n-dimensional* membrane arrangements. A future
  dialect (candidate extensions `.dli`/`.vli` — both currently free) would
  make dimension a parameter rather than a fixed grid, so convolution,
  pooling and spatial self-assembly are rank-generic (cf. `lang/pl/nn_nd.pl`,
  which already does rank-parametric convolution in Prolog).

- **Massively-parallel structured computation.** Because P-System rules are
  maximally parallel, a chart of accounts for a whole supply chain — a
  thousand entities, each a membrane holding `account{acct, balance}` objects
  — settles *all* inter-entity transfers in a constant number of membrane
  steps, independent of entity count (see demo 22, `parallel_ledger_demo`).
  Double-entry conservation holds by construction; O(1) steps, not O(n).

### Weight Interchange Format

`integration.pli` exposes `save_weights` / `load_weights` rules that round-trip
trained models via a simple record format shared conceptually with the other
language ports (`lang/pl`, `lang/rkt`, `lang/scm`):

```plingua
weight_record{model_id, neuron_id, input_index, value}   /* value ×100 scaled */
bias_record{model_id, neuron_id, value}
```

### Highlights

- **Adam optimizer** uses timestep objects for bias correction, mapping directly to P-Systems state.
- **LSTM** encodes gate states (`gate_f`, `gate_i`, `gate_g`, `gate_o`) as objects evolving through time-indexed membranes.
- **Conv2D** uses 2D membrane regions with `input{channel, row, col, value}` objects for spatial data.
- **Gradient checkpointing** recomputes activations from saved membrane snapshots during backward pass.
- **Visualization dashboard** wires all monitoring modules together via membrane communication.

## Contributing

Contributions are welcome! Areas of interest:
- Optimizing P-Systems rules for efficiency
- Adding more activation functions
- Implementing advanced optimizers
- Creating visualization tools
- Writing more examples and tutorials

## Acknowledgments

- Inspired by the original Torch/nn Lua implementation
- P-Lingua framework by RGNC research group
- P-Systems formalism by Gheorghe Păun
- Neural network concepts from deep learning community

## Contact

For questions or discussions about this PLingua implementation, please open an issue in the nn.nn repository.

---

**Note**: This is a conceptual implementation demonstrating how neural network algorithms can be expressed in P-Systems membrane computing. It prioritizes clarity and educational value over performance. For production neural networks, use established frameworks like PyTorch, TensorFlow, or JAX.
