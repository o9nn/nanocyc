# Neural Network Implementation in Pure Racket

A comprehensive, pure Racket implementation of feedforward neural networks with backpropagation training and a modular architecture inspired by Torch/nn.

## Features

### Core Functionality
- **Feedforward Neural Networks**: Arbitrary layer sizes and architectures
- **Backpropagation**: Complete training algorithm with gradient descent
- **Multiple Activation Functions**: Sigmoid, Tanh, ReLU, Softmax, LogSoftmax
- **Loss Functions**: MSE, Classification NLL, Binary Cross Entropy, Absolute Error
- **Vector/Matrix Operations**: Dot product, matrix multiplication, element-wise operations

### Modular Architecture
- **Module System**: Composable neural network components
- **Container Modules**: Sequential, Concat for building complex networks
- **Transfer Modules**: Sigmoid, Tanh, ReLU, Softmax, LogSoftmax as modules
- **Layer Modules**: Linear (fully connected), Identity, Reshape, Mean, Max
- **Criterion Modules**: MSE, ClassNLL, BCE, Absolute Error

### Pure Racket Implementation
- No external dependencies (uses `#lang racket`)
- Clear, readable, and educational code
- Idiomatic Racket style
- Suitable for learning and prototyping

## Installation

No installation required! Simply use the Racket files in your project.

### Requirements
- Racket 8.0+ (recommended)
- Standard Racket distribution

## Quick Start

### Basic Usage

```racket
#lang racket
(require "nn.rkt")

; Create a network with layer sizes [2, 3, 1]
(define net (create-network '(2 3 1)))

; Make a prediction
(define output (forward '(0.5 0.8) net))
(displayln output)  ; => (0.7123...)

; Train on data
(define training-data 
  (list (make-sample '(0 0) '(0))
        (make-sample '(1 1) '(1))))

(define trained-net (train training-data net 0.5 1000))

; Test the trained network
(define result (predict '(0.5 0.5) trained-net))
```

### Module-Based Usage

```racket
; Build a network using modules
(define linear1 (make-linear 2 4))      ; Input: 2, Output: 4
(define tanh1 (tanh-module))            ; Tanh activation
(define linear2 (make-linear 4 1))      ; Hidden to output
(define sigmoid1 (sigmoid-module))      ; Output activation

; Compose into a sequential network
(define net (make-sequential (list linear1 tanh1 linear2 sigmoid1)))

; Forward pass
(define output (module-forward net '(0.5 0.8)))

; Use with loss criterion
(define criterion (mse-criterion))
(define loss (criterion-forward criterion output '(1.0)))
```

## API Reference

### Network Functions

#### `(create-network layer-sizes)`
Create a neural network with specified layer sizes.
- **Parameters**: `layer-sizes` - List of integers `[input-size hidden1 ... output-size]`
- **Returns**: Network structure
- **Example**: `(create-network '(2 3 1))`

#### `(forward input network)`
Perform forward propagation through the network.
- **Parameters**: 
  - `input` - Input vector (list of numbers)
  - `network` - Network created by `create-network`
- **Returns**: Output vector
- **Example**: `(forward '(0.5 0.8) net)`

#### `(predict input network)`
Alias for `forward`. Compute network prediction.
- **Parameters**: Same as `forward`
- **Returns**: Output vector
- **Example**: `(predict '(0.5 0.8) net)`

#### `(train samples network learning-rate epochs)`
Train the network using backpropagation.
- **Parameters**:
  - `samples` - List of training samples (use `make-sample`)
  - `network` - Network to train
  - `learning-rate` - Learning rate (e.g., 0.5)
  - `epochs` - Number of training iterations
- **Returns**: Trained network
- **Example**: `(train data net 0.5 1000)`

#### `(make-sample input target)`
Create a training sample.
- **Parameters**:
  - `input` - Input vector
  - `target` - Target output vector
- **Returns**: Sample structure
- **Example**: `(make-sample '(0 1) '(1))`

### Activation Functions

#### `(sigmoid x)`
Sigmoid activation: `1 / (1 + exp(-x))`
- **Range**: (0, 1)
- **Use**: Binary classification, hidden layers

#### `(tanh-activation x)`
Hyperbolic tangent activation
- **Range**: (-1, 1)
- **Use**: Hidden layers, zero-centered

#### `(relu x)`
Rectified Linear Unit: `max(0, x)`
- **Range**: [0, ∞)
- **Use**: Hidden layers, efficient training

#### `(softmax vector)`
Softmax activation (normalizes to probabilities)
- **Range**: (0, 1), sums to 1
- **Use**: Multi-class classification output

#### `(log-softmax vector)`
Log of softmax (numerically stable)
- **Range**: (-∞, 0)
- **Use**: Classification with NLL loss

### Vector Operations

#### `(dot-product v1 v2)`
Compute dot product of two vectors.

#### `(vector-add v1 v2)`
Element-wise vector addition.

#### `(vector-sub v1 v2)`
Element-wise vector subtraction.

#### `(scalar-mult-vector s v)`
Multiply vector by scalar.

#### `(vector-sum v)`
Sum all elements in vector.

#### `(vector-mean v)`
Compute mean of vector elements.

#### `(vector-max v)`
Find maximum element in vector.

### Module System

#### Module Creation

```racket
; Activation modules
(sigmoid-module)           ; Sigmoid activation
(tanh-module)             ; Tanh activation
(relu-module)             ; ReLU activation
(softmax-module)          ; Softmax activation
(log-softmax-module)      ; LogSoftmax activation

; Layer modules
(make-linear in-size out-size)  ; Fully connected layer
(make-identity)                  ; Pass-through layer
(make-reshape shape)             ; Reshape layer
(make-mean dim)                  ; Mean reduction
(make-max dim)                   ; Max reduction

; Container modules
(make-sequential modules)        ; Sequential container
(make-concat dim modules)        ; Concatenate outputs
```

#### Module Operations

```racket
; Forward pass through a module
(module-forward module input)

; Example: Chain multiple modules
(define net (make-sequential 
              (list (make-linear 2 4)
                    (tanh-module)
                    (make-linear 4 1)
                    (sigmoid-module))))
(define output (module-forward net '(0.5 0.8)))
```

### Criterion/Loss Functions

#### Criterion Creation

```racket
(mse-criterion)          ; Mean Squared Error
(class-nll-criterion)    ; Negative Log Likelihood
(bce-criterion)          ; Binary Cross Entropy
(abs-criterion)          ; Absolute Error (L1)
```

#### Criterion Operations

```racket
; Compute loss
(criterion-forward criterion output target)

; Example: MSE loss
(define criterion (mse-criterion))
(define loss (criterion-forward criterion '(0.8) '(1.0)))
; => 0.04
```

## Examples

### Example 1: XOR Problem

The XOR problem is a classic test for neural networks, as it's not linearly separable.

```racket
#lang racket
(require "nn.rkt")

; Create network: 2 inputs, 4 hidden neurons, 1 output
(define net (create-network '(2 4 1)))

; XOR training data
(define xor-data
  (list (make-sample '(0 0) '(0))
        (make-sample '(0 1) '(1))
        (make-sample '(1 0) '(1))
        (make-sample '(1 1) '(0))))

; Train for 1000 epochs
(define trained-net (train xor-data net 0.5 1000))

; Test predictions
(predict '(0 0) trained-net)  ; => ~0.0
(predict '(0 1) trained-net)  ; => ~1.0
(predict '(1 0) trained-net)  ; => ~1.0
(predict '(1 1) trained-net)  ; => ~0.0
```

### Example 2: AND Gate

```racket
(define net (create-network '(2 2 1)))

(define and-data
  (list (make-sample '(0 0) '(0))
        (make-sample '(0 1) '(0))
        (make-sample '(1 0) '(0))
        (make-sample '(1 1) '(1))))

(define trained-net (train and-data net 0.5 500))

(predict '(1 1) trained-net)  ; => ~1.0
(predict '(0 1) trained-net)  ; => ~0.0
```

### Example 3: Module-Based Network

```racket
; Build a network with modules
(define linear1 (make-linear 2 3))
(define tanh1 (tanh-module))
(define linear2 (make-linear 3 1))
(define sigmoid1 (sigmoid-module))

; Create sequential network
(define net (make-sequential 
              (list linear1 tanh1 linear2 sigmoid1)))

; Forward pass
(define output (module-forward net '(0.5 0.5)))

; Use with criterion
(define criterion (mse-criterion))
(define loss (criterion-forward criterion output '(1.0)))
```

### Example 4: Classification with Softmax

```racket
; Network for 3-class classification
(define linear (make-linear 4 3))     ; 4 features -> 3 classes
(define softmax (softmax-module))
(define net (make-sequential (list linear softmax)))

; Forward pass
(define probs (module-forward net '(0.5 0.3 0.8 0.2)))
; => (0.33 0.35 0.32)  ; probabilities sum to 1

; Find predicted class
(define (argmax lst)
  (define (helper lst idx max-idx max-val)
    (cond
      [(null? lst) max-idx]
      [(> (car lst) max-val)
       (helper (cdr lst) (+ idx 1) idx (car lst))]
      [else
       (helper (cdr lst) (+ idx 1) max-idx max-val)]))
  (helper (cdr lst) 1 0 (car lst)))

(define predicted-class (argmax probs))
```

## Running Tests

```bash
# Run the test suite
racket test-nn.rkt

# Output shows test results
# ✓ indicates passing test
# ✗ indicates failing test
```

Test suite includes:
- Activation function tests (sigmoid, tanh, relu)
- Vector operation tests
- Network creation and structure tests
- Forward propagation tests
- Loss function tests
- Module system tests
- Integration tests

## Running Demos

```bash
# Run all demonstration examples
racket demo.rkt

# Or run the practical example
racket example.rkt
```

Demo suite includes:
- Basic network usage
- XOR problem solution
- AND gate implementation
- Module-based architectures
- Activation functions showcase
- Loss functions comparison
- Softmax classification
- Vector operations

## Architecture

### Data Structures

```racket
; Network
'(network (2 3 1) weights)

; Neuron
'(neuron (w1 w2 ...) bias)

; Training Sample
'(sample (x1 x2) (y1))

; Module
'(sigmoid)
'(linear weights bias)
'(sequential (module1 module2 ...))
```

### Algorithm Flow

1. **Network Creation**:
   - Define layer sizes
   - Initialize random weights and biases
   - Create network structure

2. **Forward Propagation**:
   - Layer-by-layer computation
   - Apply activation functions
   - Produce output

3. **Loss Computation**:
   - Compare output to target
   - Calculate error (MSE, NLL, etc.)

4. **Backpropagation**:
   - Compute gradients
   - Update weights using learning rate
   - Iterate for multiple epochs

5. **Prediction**:
   - Forward pass on new input
   - Return network output

## Performance Characteristics

- **Training Speed**: Suitable for small networks and datasets
- **Memory Usage**: Minimal, stores only weights and activations
- **Scalability**: Best for:
  - Networks < 100 neurons
  - Datasets < 1000 samples
  - Educational and prototyping purposes

## Educational Value

This implementation is ideal for:
- Learning neural network fundamentals
- Understanding backpropagation algorithm
- Teaching functional programming concepts
- Prototyping small ML experiments
- Demonstrating Racket's expressiveness

## Comparison with Original torch/nn

| Feature | torch/nn (Lua) | nn.rkt (Racket) |
|---------|----------------|-----------------|
| GPU Acceleration | ✓ | ✗ |
| Convolutional Layers | ✓ | ✗ |
| Recurrent Networks | ✓ | ✗ |
| Production Ready | ✓ | ✗ |
| Pure Language | ✓ | ✓ |
| Educational | ◐ | ✓ |
| Minimal Dependencies | ✗ | ✓ |
| Easy to Understand | ◐ | ✓ |

## Limitations

- Not optimized for large-scale production use
- No GPU support
- Limited to feedforward networks
- Basic backpropagation implementation
- No advanced optimization algorithms (Adam, RMSprop, etc.)

## Racket-Specific Features

This implementation uses idiomatic Racket:
- `#lang racket` for full Racket features
- Square brackets `[]` for clarity in nested forms
- `define` with internal definitions
- `let` and `let*` for local bindings
- `cond` for multi-way conditionals
- `displayln` and `printf` for output
- `range` for generating sequences
- `provide (all-defined-out)` for module exports

## Future Enhancements

Potential additions:
- More sophisticated backpropagation
- Advanced optimizers (momentum, Adam)
- Batch training support
- Dropout regularization
- Batch normalization
- Convolutional layers
- Recurrent layers (LSTM, GRU)
- Model serialization

## Contributing

This is a minimal educational implementation. Contributions welcome for:
- Bug fixes
- Additional activation functions
- More loss functions
- Better documentation
- Performance improvements
- Additional examples

## License

Same license as the parent repository (torch/nn).

## References

- [Original torch/nn](https://github.com/torch/nn)
- [Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/)
- [Racket Documentation](https://docs.racket-lang.org/)

## Acknowledgments

Inspired by the torch/nn architecture and adapted for pure Racket implementation focusing on educational clarity and functional programming principles.
