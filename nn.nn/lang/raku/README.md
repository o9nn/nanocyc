# Neural Network Implementation in Raku

A pure Raku implementation of feedforward neural networks with backpropagation training and modular architecture.

## Features

- **Feedforward Neural Networks**: Build networks with arbitrary layer sizes
- **Multiple Activation Functions**: Sigmoid, Tanh, ReLU with derivatives
- **Backpropagation Training**: Complete gradient descent implementation
- **Modular Architecture**: Compose networks using modules and containers
- **Loss Functions**: MSE, Absolute Error, Binary Cross-Entropy
- **Vector/Matrix Operations**: Comprehensive linear algebra utilities
- **Pure Raku**: No external dependencies required

## Installation

This is a pure Raku implementation with no external dependencies. Simply ensure you have Raku installed:

```bash
# Check if Raku is installed
raku --version
```

If you need to install Raku, visit [raku.org](https://raku.org/downloads/).

## Quick Start

### Basic Neural Network

```raku
use NN;

# Create a network with 2 inputs, 4 hidden neurons, and 1 output
my $network = create-network([2, 4, 1]);

# Make a prediction
my @output = predict([0.5, 0.8], $network);
say "Output: ", @output;
```

### Training a Network

```raku
use NN;

# Create training data for XOR problem
my @training-data = [
    make-sample([0.0, 0.0], [0.0]),
    make-sample([0.0, 1.0], [1.0]),
    make-sample([1.0, 0.0], [1.0]),
    make-sample([1.0, 1.0], [0.0])
];

# Create and train network
my $network = create-network([2, 4, 1]);
my $trained = train(@training-data, $network, 0.5, 1000);

# Test predictions
say "XOR(0, 0) = ", predict([0.0, 0.0], $trained)[0];
say "XOR(1, 1) = ", predict([1.0, 1.0], $trained)[0];
```

### Module-Based Architecture

```raku
use NN;

# Build network using modules
my $linear1 = make-linear(2, 4);
my $tanh-layer = tanh-module();
my $linear2 = make-linear(4, 1);
my $sigmoid-layer = sigmoid-module();

# Create sequential network
my $network = make-sequential([
    $linear1, $tanh-layer, $linear2, $sigmoid-layer
]);

# Forward pass
my @output = module-forward($network, [0.5, 0.8]);

# Use with criterion
my $criterion = mse-criterion();
my $loss = criterion-forward($criterion, @output, [1.0]);
say "Loss: ", $loss;
```

## Running Examples

### Example Script

Run the complete XOR example:

```bash
cd lang/raku
raku example.raku
```

### Demo Script

Run all demonstrations:

```bash
cd lang/raku
raku demo.raku
```

### Test Suite

Run the test suite:

```bash
cd lang/raku
raku test-nn.raku
```

## API Reference

### Network Creation

#### `create-network(@layer-sizes)`
Create a neural network with specified layer sizes.

```raku
my $network = create-network([2, 3, 1]);  # 2 inputs, 3 hidden, 1 output
```

#### `init-weights(@layer-sizes)`
Initialize random weights for network layers.

#### `predict(@input, $network)`
Make a prediction using a trained network.

### Activation Functions

#### `sigmoid($x)`
Sigmoid activation: `1 / (1 + exp(-x))`

#### `tanh-activation($x)`
Hyperbolic tangent activation

#### `relu($x)`
ReLU activation: `max(0, x)`

Each activation function has a corresponding derivative function (e.g., `sigmoid-derivative`).

### Vector Operations

#### `dot-product(@v1, @v2)`
Compute dot product of two vectors

#### `vector-add(@v1, @v2)` / `vector-sub(@v1, @v2)`
Element-wise addition/subtraction

#### `scalar-mult-vector($scalar, @vector)`
Multiply vector by scalar

#### `vector-sum(@v)` / `vector-mean(@v)` / `vector-max(@v)` / `vector-min(@v)`
Aggregate operations on vectors

### Matrix Operations

#### `matrix-vector-mult(@matrix, @vector)`
Matrix-vector multiplication

#### `transpose(@matrix)`
Matrix transpose

#### `matrix-scalar-mult($scalar, @matrix)`
Multiply matrix by scalar

### Training

#### `train(@training-data, $network, $learning-rate, $epochs)`
Train network using backpropagation.

```raku
my @data = [
    make-sample([0.0, 0.0], [0.0]),
    make-sample([1.0, 1.0], [1.0])
];
my $trained = train(@data, $network, 0.5, 1000);
```

#### `make-sample(@input, @target)`
Create a training sample.

### Loss Functions

#### `mse-loss(@output, @target)`
Mean Squared Error loss

#### `mse-loss-derivative(@output, @target)`
Gradient of MSE loss

### Module System

#### Container Modules

- `make-sequential(@modules)` - Sequential container
- `concat-module(@modules, $dim)` - Concatenation module
- `concat-table(@modules)` - Parallel outputs
- `parallel-module($input-dim, $output-dim, @modules)` - Parallel processing

#### Layer Modules

- `make-linear($input-size, $output-size)` - Linear/Dense layer
- `reshape-module(@target-shape)` - Reshape layer
- `mean-module($dim)` - Mean pooling
- `max-module($dim)` - Max pooling

#### Activation Modules

- `sigmoid-module()` - Sigmoid activation
- `tanh-module()` - Tanh activation  
- `relu-module()` - ReLU activation
- `softmax-module()` - Softmax activation
- `log-softmax-module()` - Log-Softmax activation
- `identity-module()` - Pass-through (no operation)

#### Criterion Modules (Loss Functions)

- `mse-criterion()` - Mean Squared Error
- `abs-criterion()` - Absolute Error (L1)
- `bce-criterion()` - Binary Cross-Entropy

#### Module Operations

- `module-forward($module, $input)` - Forward pass
- `module-backward($module, $grad-output)` - Backward pass
- `criterion-forward($criterion, $input, $target)` - Compute loss
- `criterion-backward($criterion, $input, $target)` - Compute gradient

## Architecture

### Data Structures

The implementation uses simple Raku data structures:

- **Network**: Object with `layer-sizes` and `weights` attributes
- **Weights**: Array of layers, each containing neurons with weights and bias
- **Neuron**: Hash with `weights` (Array) and `bias` (Numeric)
- **Sample**: Hash with `input` (Array) and `target` (Array)
- **Modules**: Objects implementing the `Module` role with `forward` and `backward` methods
- **Criterions**: Objects implementing the `Criterion` role

### Training Algorithm

1. **Forward Propagation**: Compute activations layer by layer
2. **Loss Computation**: Calculate error between prediction and target
3. **Backpropagation**: Compute gradients using chain rule
4. **Weight Update**: Apply gradient descent with learning rate

## Examples

### Example 1: XOR Problem

The XOR problem is a classic test for neural networks as it's not linearly separable.

```raku
use NN;

my $network = create-network([2, 4, 1]);
my @data = [
    make-sample([0.0, 0.0], [0.0]),
    make-sample([0.0, 1.0], [1.0]),
    make-sample([1.0, 0.0], [1.0]),
    make-sample([1.0, 1.0], [0.0])
];

my $trained = train(@data, $network, 0.5, 2000);

say "XOR(0, 0) = ", predict([0.0, 0.0], $trained)[0];  # ≈ 0
say "XOR(0, 1) = ", predict([0.0, 1.0], $trained)[0];  # ≈ 1
say "XOR(1, 0) = ", predict([1.0, 0.0], $trained)[0];  # ≈ 1
say "XOR(1, 1) = ", predict([1.0, 1.0], $trained)[0];  # ≈ 0
```

### Example 2: Simple Regression

Learn a linear function `f(x) = 2x + 1`:

```raku
use NN;

my $network = create-network([1, 3, 1]);

# Generate training data
my @data;
for 0..9 -> $i {
    my $x = $i / 10.0;
    my $y = 2.0 * $x + 1.0;
    @data.push(make-sample([$x], [$y]));
}

my $trained = train(@data, $network, 0.1, 500);

# Test
say "f(0.5) = ", predict([0.5], $trained)[0];  # ≈ 2.0
```

### Example 3: Modular Network

Build a network compositionally:

```raku
use NN;

# Define architecture
my $linear1 = make-linear(3, 5);
my $sigmoid = sigmoid-module();
my $linear2 = make-linear(5, 2);
my $tanh = tanh-module();

# Compose modules
my $network = make-sequential([
    $linear1, $sigmoid, $linear2, $tanh
]);

# Use network
my @output = module-forward($network, [0.2, 0.5, 0.8]);
say "Output: ", @output;
```

## Performance Characteristics

- **Target Use Case**: Educational, prototyping, small-scale experiments
- **Network Size**: Best for networks with < 100 neurons
- **Dataset Size**: Suitable for datasets < 1000 samples
- **Training Speed**: Moderate (pure Raku implementation)
- **Memory Usage**: Minimal, stores only weights and activations

## Comparison with Other Implementations

This repository contains neural network implementations in multiple languages:

- **Lua** (`lang/lua`): Original Torch-based implementation with extensive features
- **Prolog** (`lang/pl`): Logic programming approach with declarative style
- **Scheme** (`lang/scm`): Functional programming with Lisp syntax
- **Racket** (`lang/rkt`): Modern Lisp with contracts and types
- **Raku** (`lang/raku`): **This implementation** - Modern Perl with gradual typing

### Raku Advantages

- **Modern Syntax**: Clean, readable code with sigils and method calls
- **Gradual Typing**: Optional type annotations for safety
- **Native Operators**: Built-in zip (`Z`), reduction (`[+]`), hyperoperators
- **Functional Features**: First-class functions, lazy evaluation, junctions
- **Object System**: Roles, classes, multiple dispatch

## Educational Use

This implementation is ideal for:

- **Learning Neural Networks**: Clear, readable implementation of core concepts
- **Understanding Backpropagation**: Step-by-step gradient computation
- **Exploring Raku**: Practical example of Raku's features
- **Prototyping**: Quick experiments with small networks
- **Teaching**: Demonstration tool for ML courses

## Limitations

- **No GPU Support**: Pure CPU implementation
- **No Convolution**: Only fully-connected layers
- **No Recurrence**: Feedforward networks only
- **No Optimization**: No momentum, Adam, or other advanced optimizers
- **No Batch Processing**: Trains one sample at a time
- **Simplified Backprop**: Module backward passes are simplified

## Future Extensions

Possible enhancements:

- Mini-batch gradient descent
- Advanced optimizers (momentum, Adam, RMSprop)
- Dropout regularization
- Batch normalization
- More sophisticated module backward passes
- Convolutional layers
- Recurrent layers (LSTM, GRU)

## Contributing

Contributions are welcome! Areas for improvement:

- Performance optimizations
- Additional activation functions
- More loss functions
- Better testing coverage
- Documentation improvements
- Example applications

## License

See the COPYRIGHT.txt file in the repository root.

## References

- [Raku Documentation](https://docs.raku.org/)
- [Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/)
- [Backpropagation Algorithm](https://en.wikipedia.org/wiki/Backpropagation)
- [Torch nn Package](https://github.com/torch/nn)

## Acknowledgments

This implementation is inspired by:

- The original Torch `nn` package
- Other implementations in this repository (Prolog, Scheme, Racket)
- The Raku community and ecosystem

---

**Author**: Generated for the nn.nn multi-language neural network repository  
**Language**: Raku (formerly Perl 6)  
**Status**: Educational/Experimental  
**Version**: 1.0
