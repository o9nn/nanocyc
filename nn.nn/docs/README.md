# Neural Network Library - Formal Specifications and Documentation

This directory contains comprehensive technical architecture documentation and formal Z++ specifications for the `nn.pl` neural network library.

## Overview

The documentation provides both high-level architectural views (with Mermaid diagrams) and rigorous formal specifications using Z++ notation. Together, they form a complete, verifiable model of the neural network system's structure and behavior.

## Documentation Files

### 1. Architecture Overview (`architecture_overview.md`)

**Purpose**: High-level system architecture with visual diagrams

**Contents**:
- Executive summary of the modular, composable design
- Multi-language implementation architecture (Lua/Torch, Prolog, C)
- Core component descriptions with Mermaid class diagrams
- Data flow and state transition diagrams
- Module hierarchy and taxonomy
- Technology stack details
- Design patterns and principles
- Performance considerations
- Security considerations
- Future evolution roadmap

**When to read**: Start here for a visual, intuitive understanding of the system architecture. Ideal for:
- New developers joining the project
- Architectural reviews
- System design discussions
- Understanding component relationships

### 2. Data Model Specification (`data_model.zpp`)

**Purpose**: Formal Z++ specification of all data structures

**Contents**:
- **Section 1**: Basic types (Real, Natural, Integer, Boolean, Enumerations)
- **Section 2**: Tensor representation (Shape, TensorData, Tensor schemas)
- **Section 3**: Module parameters (Parameter, ParameterSet)
- **Section 4**: Module base schema (Module, StatelessModule, ParameterizedModule)
- **Section 5**: Container modules (Sequential, Parallel, Concat, ConcatTable)
- **Section 6**: Simple layer modules (Linear, Identity, Reshape, Mean, Max)
- **Section 7**: Transfer functions (Sigmoid, Tanh, ReLU, PReLU, Softmax, LogSoftmax)
- **Section 8**: Criterion/loss modules (MSE, ClassNLL, BCE, Abs)
- **Section 9**: Convolution layers (Spatial, Temporal)
- **Section 10**: Table layers (Split, Join, Select)
- **Section 11**: Summary and relationships

**When to read**: When you need precise definitions of:
- Data structure invariants
- Type constraints
- Structural relationships
- Module properties

### 3. System State Specification (`system_state.zpp`)

**Purpose**: Formal specification of complete system state and global invariants

**Contents**:
- **Section 1**: Module registry (centralized module management)
- **Section 2**: Network topology (hierarchical structure, parent-child relationships)
- **Section 3**: Training state (datasets, batching, epochs, optimizer state)
- **Section 4**: Computation state (forward/backward caches)
- **Section 5**: Complete system state with global invariants
- **Section 6**: System initialization operations
- **Section 7**: Mode transitions (Training ↔ Evaluation)
- **Section 8**: State query operations
- **Section 9**: Summary

**When to read**: When you need to understand:
- How the system maintains consistency
- Global invariants that must hold
- Training progress tracking
- State transitions
- Cache management

### 4. Operations Specification (`operations.zpp`)

**Purpose**: Formal specification of all neural network operations

**Contents**:
- **Section 1**: Forward propagation (module-by-module forward pass)
- **Section 2**: Loss computation (MSE, ClassNLL, etc.)
- **Section 3**: Backward propagation (gradient computation)
- **Section 4**: Parameter updates (SGD, Momentum)
- **Section 5**: Training loop (batch processing, epoch management)
- **Section 6**: Inference operations (predictions)
- **Section 7**: Summary

**When to read**: When you need precise semantics for:
- Forward/backward pass algorithms
- Gradient computation
- Parameter update rules
- Training procedures
- Inference behavior

### 5. Integration Contracts (`integrations.zpp`)

**Purpose**: Formal contracts for external interfaces and boundaries

**Contents**:
- **Section 1**: Tensor operation contracts (add, multiply, reshape, slice, concatenate)
- **Section 2**: Mathematical function contracts (activations with derivatives)
- **Section 3**: Serialization contracts (model persistence, formats)
- **Section 4**: File I/O contracts (save/load operations)
- **Section 5**: Dataset loading contracts (data sources, shuffling, splitting)
- **Section 6**: Numerical stability contracts (validation, gradient clipping)
- **Section 7**: Error handling contracts (result types, error propagation)
- **Section 8**: Summary

**When to read**: When working on:
- External integrations
- Serialization/deserialization
- Data loading pipelines
- Error handling
- Numerical stability features

## Reading Guide

### For Different Audiences

**Software Engineers (Implementation)**:
1. Start with `architecture_overview.md` for the big picture
2. Read `data_model.zpp` for precise data structure definitions
3. Consult `operations.zpp` when implementing specific operations
4. Refer to `integrations.zpp` for external interface contracts

**Formal Methods Practitioners**:
1. Begin with `data_model.zpp` for foundational schemas
2. Study `system_state.zpp` for state invariants
3. Analyze `operations.zpp` for operational semantics
4. Review `integrations.zpp` for boundary conditions

**Project Managers / Architects**:
1. Read `architecture_overview.md` thoroughly
2. Skim the Z++ specifications for completeness
3. Focus on summary sections in each specification
4. Use diagrams for presentations and discussions

**Quality Assurance / Testers**:
1. Use `architecture_overview.md` to understand system structure
2. Extract test cases from pre/post-conditions in `operations.zpp`
3. Verify invariants from `system_state.zpp` hold during testing
4. Check error handling per `integrations.zpp` contracts

### Progressive Reading Path

**Level 1 - Overview** (30 minutes):
- `architecture_overview.md` - Complete read
- Each `.zpp` file - Read Section 1 and final Summary

**Level 2 - Detailed Understanding** (2-3 hours):
- `architecture_overview.md` - Study all diagrams
- `data_model.zpp` - Sections 1-4 (base types and module structure)
- `system_state.zpp` - Sections 1-2, 5 (registry, topology, complete state)
- `operations.zpp` - Sections 1-3 (forward, loss, backward)

**Level 3 - Complete Mastery** (1-2 days):
- All files - Complete, detailed reading
- Work through examples manually
- Verify invariants hold for sample data
- Trace operations through state transitions

## Z++ Notation Guide

### Basic Symbols

| Symbol | Meaning | Example |
|--------|---------|---------|
| `ℕ` | Natural numbers | `n : ℕ` |
| `ℤ` | Integers | `i : ℤ` |
| `ℝ` | Real numbers | `x : ℝ` |
| `𝔹` | Booleans | `flag : 𝔹` |
| `seq T` | Sequence of T | `seq ℕ` |
| `⇸` | Partial function | `A ⇸ B` |
| `→` | Total function | `A → B` |
| `↔` | Relation | `A ↔ B` |
| `⟨⟩` | Empty sequence | `s = ⟨⟩` |
| `⌢` | Sequence concatenation | `s₁ ⌢ s₂` |

### Quantifiers and Logic

| Symbol | Meaning | Example |
|--------|---------|---------|
| `∀` | For all | `∀ x : S • P(x)` |
| `∃` | Exists | `∃ x : S • P(x)` |
| `∧` | And | `P ∧ Q` |
| `∨` | Or | `P ∨ Q` |
| `¬` | Not | `¬P` |
| `⇒` | Implies | `P ⇒ Q` |
| `⇔` | If and only if | `P ⇔ Q` |

### Set Operations

| Symbol | Meaning | Example |
|--------|---------|---------|
| `∈` | Element of | `x ∈ S` |
| `⊆` | Subset | `A ⊆ B` |
| `∪` | Union | `A ∪ B` |
| `∩` | Intersection | `A ∩ B` |
| `∅` | Empty set | `S = ∅` |
| `#S` | Cardinality | `#S = 5` |
| `dom f` | Domain | `dom f` |
| `ran f` | Range | `ran f` |

### Schema Operations

| Symbol | Meaning | Description |
|--------|---------|-------------|
| `Δ` | Delta | State change (before and after) |
| `Ξ` | Xi | Read-only (state unchanged) |
| `?` | Input | Input parameter |
| `!` | Output | Output parameter |
| `'` | Prime | After state (post-condition) |

### Example Schema

```
┌─ SchemaName ────────────────────────────────────────┐
│ variable1 : Type1                                   │
│ variable2 : Type2                                   │
│                                                     │
│ -- Invariants/Constraints                          │
│ variable1 > 0                                       │
│ #variable2 = variable1                              │
└─────────────────────────────────────────────────────┘
  Explanation of what this schema represents
```

## Validation and Verification

The formal specifications enable:

1. **Property Checking**: Verify invariants hold across operations
2. **Refinement Proofs**: Prove implementation satisfies specification
3. **Test Generation**: Derive test cases from pre/post-conditions
4. **Documentation Generation**: Auto-generate API docs from schemas
5. **Static Analysis**: Check code against formal contracts

## Contributing

When modifying the system:

1. **Update specifications first**: Changes should be reflected in the formal specs
2. **Maintain consistency**: Ensure all documents remain synchronized
3. **Verify invariants**: Check that global invariants still hold
4. **Update diagrams**: Keep Mermaid diagrams current with architecture
5. **Add examples**: Include concrete examples in specifications when helpful

## Tools and Resources

### Z++ Tools
- **Z/EVES**: Theorem prover for Z specifications
- **CZT**: Community Z Tools for type checking
- **fuzz**: Type checker for Z specifications

### Mermaid Resources
- [Mermaid Live Editor](https://mermaid.live/): Test and edit diagrams
- [Mermaid Documentation](https://mermaid-js.github.io/): Full syntax reference

### Related Standards
- ISO/IEC 13568:2002 - Z formal specification notation
- Z++ extensions for object-oriented specifications

## Maintenance

This documentation should be updated when:
- New modules or layers are added
- State structure changes
- Operations are modified or added
- External interfaces change
- System invariants are relaxed or strengthened

**Last Updated**: 2025-12-31

**Specification Version**: 1.0

**Corresponds to**: nn.pl main branch as of 2025-12-31
