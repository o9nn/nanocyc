# Neural Network Library - Technical Architecture Overview

## Executive Summary

The `nn.pl` neural network library implements a modular, composable deep learning framework inspired by Torch/nn. The library provides implementations in multiple languages (Lua/Torch, Prolog, C) sharing a common architectural design based on the Module pattern, enabling construction of arbitrary neural network topologies through composition.

## System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "User Interface Layer"
        API[Public API]
        Builder[Network Builder]
    end
    
    subgraph "Core Framework"
        Module[Module Base Class]
        Container[Container Modules]
        Layer[Simple Layers]
        Transfer[Transfer Functions]
        Criterion[Loss Criterions]
    end
    
    subgraph "Computation Engine"
        Forward[Forward Pass]
        Backward[Backward Pass]
        Optimizer[Parameter Update]
    end
    
    subgraph "Backend Infrastructure"
        Tensor[Tensor Operations]
        Memory[Memory Management]
        Math[Mathematical Primitives]
    end
    
    API --> Builder
    Builder --> Container
    Container --> Module
    Layer --> Module
    Transfer --> Module
    Criterion --> Module
    
    Module --> Forward
    Module --> Backward
    Forward --> Tensor
    Backward --> Tensor
    Backward --> Optimizer
    Optimizer --> Memory
    
    Tensor --> Math
    Memory --> Math
```

### Multi-Language Implementation Architecture

```mermaid
graph LR
    subgraph "Implementation Layers"
        Prolog[Prolog Implementation<br/>Pure Logic, Educational]
        Lua[Lua/Torch Implementation<br/>Production, Optimized]
        C[C Implementation<br/>Low-level, Performance]
    end
    
    subgraph "Common Architecture"
        Design[Shared Design Pattern<br/>Module-based Architecture]
    end
    
    subgraph "Applications"
        Research[Research & Prototyping]
        Production[Production Systems]
        Education[Learning & Teaching]
    end
    
    Design --> Prolog
    Design --> Lua
    Design --> C
    
    Prolog --> Education
    Prolog --> Research
    Lua --> Production
    Lua --> Research
    C --> Production
```

## Core Components

### 1. Module Pattern

The Module is the fundamental abstraction for all neural network components.

```mermaid
classDiagram
    class Module {
        +Tensor output
        +Tensor gradInput
        +forward(input) Tensor
        +backward(input, gradOutput) Tensor
        +updateOutput(input) Tensor
        +updateGradInput(input, gradOutput) Tensor
        +accGradParameters(input, gradOutput, scale) void
        +zeroGradParameters() void
        +updateParameters(learningRate) void
        +parameters() Tensors
        +training() void
        +evaluate() void
    }
    
    class Container {
        +List~Module~ modules
        +add(module) Container
        +get(index) Module
        +size() int
    }
    
    class Sequential {
        +add(module) Sequential
    }
    
    class Parallel {
        +int inputDimension
        +int outputDimension
    }
    
    class Concat {
        +int dimension
    }
    
    class Linear {
        +Tensor weight
        +Tensor bias
        +Tensor gradWeight
        +Tensor gradBias
        +int inputSize
        +int outputSize
    }
    
    class Criterion {
        +Tensor output
        +Tensor gradInput
        +forward(input, target) scalar
        +backward(input, target) Tensor
    }
    
    Container --|> Module
    Sequential --|> Container
    Parallel --|> Container
    Concat --|> Container
    Linear --|> Module
    Criterion --|> Module
```

### 2. Container Modules

Containers compose multiple modules into complex architectures.

```mermaid
graph TB
    subgraph "Sequential Container"
        S1[Input] --> SM1[Module 1]
        SM1 --> SM2[Module 2]
        SM2 --> SM3[Module 3]
        SM3 --> SO[Output]
    end
    
    subgraph "Parallel Container"
        PI[Input] --> PD{Dimension Split}
        PD --> PM1[Module 1]
        PD --> PM2[Module 2]
        PM1 --> PC{Dimension Concat}
        PM2 --> PC
        PC --> PO[Output]
    end
    
    subgraph "Concat Container"
        CI[Input] --> CM1[Module 1]
        CI --> CM2[Module 2]
        CI --> CM3[Module 3]
        CM1 --> CC{Concatenate}
        CM2 --> CC
        CM3 --> CC
        CC --> CO[Output]
    end
```

### 3. Forward and Backward Propagation

```mermaid
sequenceDiagram
    participant User
    participant Network
    participant Module1
    participant Module2
    participant Criterion
    
    Note over User,Criterion: Forward Pass
    User->>Network: forward(input)
    Network->>Module1: forward(input)
    Module1->>Module1: updateOutput(input)
    Module1-->>Network: output1
    Network->>Module2: forward(output1)
    Module2->>Module2: updateOutput(output1)
    Module2-->>Network: output2
    Network-->>User: prediction
    
    User->>Criterion: forward(prediction, target)
    Criterion-->>User: loss
    
    Note over User,Criterion: Backward Pass
    User->>Criterion: backward(prediction, target)
    Criterion-->>User: gradLoss
    
    User->>Network: backward(input, gradLoss)
    Network->>Module2: backward(output1, gradLoss)
    Module2->>Module2: updateGradInput(output1, gradLoss)
    Module2->>Module2: accGradParameters(output1, gradLoss)
    Module2-->>Network: gradOutput1
    Network->>Module1: backward(input, gradOutput1)
    Module1->>Module1: updateGradInput(input, gradOutput1)
    Module1->>Module1: accGradParameters(input, gradOutput1)
    Module1-->>Network: gradInput
    Network-->>User: gradients computed
```

## Data Flow Architecture

### Training Data Flow

```mermaid
flowchart LR
    subgraph "Data Input"
        DS[Dataset]
        Batch[Batch Sampler]
    end
    
    subgraph "Forward Pass"
        Input[Input Data]
        Network[Neural Network]
        Output[Predictions]
    end
    
    subgraph "Loss Computation"
        Target[Target Labels]
        Criterion[Loss Criterion]
        Loss[Loss Value]
    end
    
    subgraph "Backward Pass"
        GradLoss[Loss Gradient]
        BackProp[Backpropagation]
        Gradients[Parameter Gradients]
    end
    
    subgraph "Optimization"
        Optimizer[Optimizer/SGD]
        Update[Parameter Update]
        NewParams[Updated Parameters]
    end
    
    DS --> Batch
    Batch --> Input
    Batch --> Target
    Input --> Network
    Network --> Output
    Output --> Criterion
    Target --> Criterion
    Criterion --> Loss
    Criterion --> GradLoss
    GradLoss --> BackProp
    BackProp --> Gradients
    Gradients --> Optimizer
    Optimizer --> Update
    Update --> NewParams
    NewParams --> Network
```

### Module State Transitions

```mermaid
stateDiagram-v2
    [*] --> Created: new Module()
    Created --> Initialized: initialize parameters
    Initialized --> Training: training()
    Initialized --> Evaluation: evaluate()
    
    Training --> ForwardTrain: forward(input)
    ForwardTrain --> BackwardTrain: backward(input, gradOutput)
    BackwardTrain --> ParameterUpdate: updateParameters(lr)
    ParameterUpdate --> Training: next iteration
    
    Evaluation --> ForwardEval: forward(input)
    ForwardEval --> Evaluation: prediction only
    
    Training --> Evaluation: evaluate()
    Evaluation --> Training: training()
    
    Training --> [*]: cleanup
    Evaluation --> [*]: cleanup
```

## Component Interaction Patterns

### 1. Module Composition Pattern

```mermaid
graph TB
    subgraph "Composite Pattern"
        C[Container: Composite]
        L1[Leaf Module 1]
        L2[Leaf Module 2]
        SC[Sub-Container: Composite]
        L3[Leaf Module 3]
        L4[Leaf Module 4]
        
        C --> L1
        C --> SC
        C --> L2
        SC --> L3
        SC --> L4
    end
    
    style C fill:#e1f5ff
    style SC fill:#e1f5ff
    style L1 fill:#fff4e1
    style L2 fill:#fff4e1
    style L3 fill:#fff4e1
    style L4 fill:#fff4e1
```

### 2. Layer Communication Pattern

```mermaid
graph LR
    subgraph "Layer N-1"
        L1Out[Output Tensor]
        L1Grad[Gradient Input]
    end
    
    subgraph "Layer N"
        L2In[Input]
        L2Compute[Computation]
        L2Out[Output]
        L2BackIn[Grad Output]
        L2BackCompute[Gradient Computation]
        L2BackOut[Grad Input]
        
        L2In --> L2Compute
        L2Compute --> L2Out
        L2BackIn --> L2BackCompute
        L2BackCompute --> L2BackOut
    end
    
    subgraph "Layer N+1"
        L3In[Input Tensor]
        L3Grad[Gradient Output]
    end
    
    L1Out -->|Forward| L2In
    L2Out -->|Forward| L3In
    L3Grad -->|Backward| L2BackIn
    L2BackOut -->|Backward| L1Grad
```

## Tensor Operations Infrastructure

```mermaid
graph TB
    subgraph "High-Level Operations"
        MatMul[Matrix Multiplication]
        Conv[Convolution]
        Activation[Activation Functions]
    end
    
    subgraph "Mid-Level Operations"
        BLAS[BLAS Operations]
        Reduction[Reduction Operations]
        Transform[Transformation Operations]
    end
    
    subgraph "Low-Level Operations"
        MemAlloc[Memory Allocation]
        MemCopy[Memory Copy]
        Arithmetic[Element-wise Arithmetic]
    end
    
    subgraph "Backend"
        CPU[CPU Backend]
        GPU[GPU Backend - Future]
    end
    
    MatMul --> BLAS
    Conv --> BLAS
    Activation --> Transform
    
    BLAS --> Arithmetic
    Reduction --> Arithmetic
    Transform --> Arithmetic
    
    Arithmetic --> MemAlloc
    Arithmetic --> MemCopy
    
    MemAlloc --> CPU
    MemCopy --> CPU
    CPU -.future.-> GPU
```

## Module Hierarchy

### Complete Module Taxonomy

```mermaid
graph TB
    Module[Module - Abstract Base]
    
    Module --> Container[Container]
    Module --> SimpleLayer[Simple Layers]
    Module --> TransferFn[Transfer Functions]
    Module --> ConvLayer[Convolutional Layers]
    Module --> TableLayer[Table Layers]
    
    Container --> Sequential
    Container --> Parallel
    Container --> Concat
    Container --> ConcatTable
    
    SimpleLayer --> Linear
    SimpleLayer --> Reshape
    SimpleLayer --> Mean
    SimpleLayer --> Max
    SimpleLayer --> Add
    SimpleLayer --> CMul
    SimpleLayer --> Identity
    
    TransferFn --> Sigmoid
    TransferFn --> Tanh
    TransferFn --> ReLU
    TransferFn --> ReLU6
    TransferFn --> PReLU
    TransferFn --> ELU
    TransferFn --> Softmax
    TransferFn --> LogSoftmax
    
    ConvLayer --> SpatialConv[SpatialConvolution]
    ConvLayer --> TemporalConv[TemporalConvolution]
    ConvLayer --> VolumetricConv[VolumetricConvolution]
    ConvLayer --> SpatialPool[SpatialMaxPooling]
    
    TableLayer --> SplitTable
    TableLayer --> JoinTable
    TableLayer --> SelectTable
```

### Criterion Hierarchy

```mermaid
graph TB
    Criterion[Criterion - Abstract Base]
    
    Criterion --> MSE[MSECriterion<br/>Mean Squared Error]
    Criterion --> ClassNLL[ClassNLLCriterion<br/>Negative Log Likelihood]
    Criterion --> BCE[BCECriterion<br/>Binary Cross Entropy]
    Criterion --> Abs[AbsCriterion<br/>L1 Loss]
    Criterion --> MultiLabel[MultiLabelSoftMargin]
    Criterion --> CrossEntropy[CrossEntropyCriterion]
    Criterion --> Hinge[HingeEmbedding]
    Criterion --> Cosine[CosineEmbedding]
```

## Integration Boundaries

### External System Integration

```mermaid
graph TB
    subgraph "nn.pl Library"
        API[Public API]
        Core[Core Framework]
    end
    
    subgraph "External Data Sources"
        File[File Systems]
        DB[Databases]
        Stream[Data Streams]
    end
    
    subgraph "Computation Backends"
        TorchBLAS[Torch BLAS]
        NativeBLAS[Native BLAS]
        CustomMath[Custom Math Libraries]
    end
    
    subgraph "Serialization"
        ModelSave[Model Persistence]
        CheckpointLoad[Checkpoint Loading]
    end
    
    subgraph "Visualization & Monitoring"
        Logging[Training Logs]
        Metrics[Performance Metrics]
        Visualization[Model Visualization]
    end
    
    File --> API
    DB --> API
    Stream --> API
    
    Core --> TorchBLAS
    Core --> NativeBLAS
    Core --> CustomMath
    
    API --> ModelSave
    API --> CheckpointLoad
    
    Core --> Logging
    Core --> Metrics
    API --> Visualization
```

## Technology Stack

### Lua/Torch Implementation

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Language | Lua 5.1+ | Dynamic scripting with C integration |
| Framework | Torch7 | Tensor computation framework |
| Computation | TH (Torch Tensor Library) | Low-level tensor operations |
| FFI | LuaJIT FFI | C library bindings |
| Testing | torch.Tester | Unit testing framework |
| Build | CMake | Cross-platform build system |

### Prolog Implementation

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Language | SWI-Prolog 7.0+ | Logic programming, educational |
| Paradigm | Pure Prolog | No external dependencies |
| Data Structures | Prolog Terms | Native representation |
| Testing | PlUnit | Prolog unit testing |

### C Implementation (Partial)

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Language | C | Performance-critical operations |
| Build | CMake | Cross-platform build |
| Integration | Lua C API | Torch integration |

## Design Patterns and Principles

### 1. Composite Pattern

Containers and Modules follow the Composite pattern, allowing:
- Uniform treatment of individual modules and compositions
- Recursive composition of arbitrary depth
- Simplified client code through polymorphism

### 2. Template Method Pattern

The Module base class defines the algorithmic skeleton:
- `forward()` calls `updateOutput()`
- `backward()` calls `updateGradInput()` and `accGradParameters()`
- Subclasses override specific steps

### 3. Strategy Pattern

Different modules implement different computation strategies:
- Transfer functions: different activation strategies
- Criterions: different loss computation strategies
- Optimizers: different parameter update strategies

### 4. Builder Pattern

Sequential container allows incremental network construction:
```lua
mlp = nn.Sequential()
mlp:add(nn.Linear(10, 20))
mlp:add(nn.Tanh())
mlp:add(nn.Linear(20, 10))
```

## Performance Considerations

### Memory Management

```mermaid
graph LR
    subgraph "Forward Pass"
        F1[Allocate Output Tensors]
        F2[Compute & Store]
        F3[Reuse Buffers]
    end
    
    subgraph "Backward Pass"
        B1[Allocate Gradient Tensors]
        B2[Compute Gradients]
        B3[Accumulate]
    end
    
    subgraph "Memory Optimization"
        O1[In-place Operations]
        O2[Buffer Reuse]
        O3[Gradient Checkpointing]
    end
    
    F1 --> F2 --> F3
    B1 --> B2 --> B3
    F3 --> O2
    B3 --> O2
    O2 --> O3
```

### Computational Optimization

1. **Batch Processing**: Process multiple samples simultaneously
2. **Vectorization**: Use BLAS for matrix operations
3. **In-place Operations**: Minimize memory allocations
4. **Gradient Accumulation**: Efficient mini-batch training
5. **Lazy Evaluation**: Defer computations when possible

## Extension Points

The architecture provides several extension points:

1. **Custom Modules**: Extend `Module` base class
2. **Custom Criterions**: Extend `Criterion` base class
3. **Custom Containers**: Extend `Container` base class
4. **Custom Optimizers**: Implement optimizer interface
5. **Backend Implementations**: Add new computation backends

## Security Considerations

1. **Input Validation**: Tensor dimension checking
2. **Numerical Stability**: Safeguards against overflow/underflow
3. **Resource Limits**: Memory and computation bounds
4. **Serialization Safety**: Secure model loading/saving

## Future Architecture Evolution

```mermaid
graph TB
    subgraph "Current State"
        C1[CPU-only]
        C2[Lua/Prolog/C]
        C3[Manual Memory]
    end
    
    subgraph "Near Future"
        N1[GPU Support]
        N2[Automatic Differentiation]
        N3[Memory Optimization]
    end
    
    subgraph "Long Term"
        L1[Distributed Training]
        L2[Model Compression]
        L3[Hardware Acceleration]
    end
    
    C1 --> N1
    C2 --> N2
    C3 --> N3
    
    N1 --> L1
    N2 --> L2
    N3 --> L3
```

## References

- **Torch/nn Documentation**: Original inspiration and design reference
- **Neural Networks and Deep Learning**: Theoretical foundations
- **Design Patterns**: Software architecture patterns used
- **BLAS Specification**: Low-level computation interface
