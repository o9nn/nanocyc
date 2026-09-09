# nn.pl - Neural Network Implementation in Pure Prolog

A comprehensive, pure Prolog implementation of neural networks with a modular architecture inspired by Torch/nn. Features feedforward networks, backpropagation training, multiple activation functions, loss criterions, and composable container modules.

## Features

### Core Features
- **Pure Prolog implementation** - No external dependencies, works with standard SWI-Prolog
- **Feedforward neural networks** - Multi-layer perceptron architecture
- **Backpropagation training** - Gradient descent with configurable learning rate
- **Modular architecture** - Composable modules similar to Torch/nn

### Module-Based Architecture (NEW!)
- **Container Modules**:
  - `Sequential`: Chain modules together in a feed-forward manner
  - `Concat`: Concatenate outputs from multiple parallel modules
  
- **Activation/Transfer Modules**:
  - `Sigmoid`: Logistic sigmoid activation
  - `Tanh`: Hyperbolic tangent activation
  - `ReLU`: Rectified Linear Unit activation
  - `SoftMax`: Softmax for multi-class probabilities
  - `LogSoftMax`: Log-Softmax for numerical stability

- **Criterion/Loss Modules**:
  - `MSECriterion`: Mean Squared Error for regression
  - `ClassNLLCriterion`: Negative Log Likelihood for classification
  - `BCECriterion`: Binary Cross Entropy for binary classification
  - `AbsCriterion`: L1/Absolute Error loss

- **Simple Layer Modules**:
  - `Linear`: Fully connected linear transformation
  - `Identity`: Pass-through layer
  - `Reshape`: Reshape tensors
  - `Mean`: Mean reduction along a dimension
  - `Max`: Max reduction along a dimension

### Rank-Parametric nD and Fractal Modules (`nn_nd.pl`)
- **`convnd`**: One rank-generic convolution replacing the Temporal/Spatial/Volumetric triplet — 1D, 2D, 3D, 4D, 5D+ with a single mechanism (unfold → matrix multiply → fold), with stride, zero padding, and dilation
- **`separable_convnd`**: Factorized convolution (k^R kernel → R axis-aligned 1D passes) for high ranks
- **`poolnd`**: Rank-generic max/average pooling (reduction over arbitrary window of dims)
- **`fractal_module`**: FractalNet-style self-similar container recursion with `concat_avg` join and drop-path regularization
- **Graph lowering path**: `graph_conv` message passing, `grid_graph` (nD lattice as graph), `sierpinski_graph` (fractal data domains), `fractal_pool` (renormalization pooling)

### Traditional Interface
- **Vector/Matrix operations** - Dot products, matrix multiplication, etc.
- **Loss functions** - Mean Squared Error (MSE)
- **Example problems** - XOR and simple regression examples included

## Requirements

- SWI-Prolog 7.0 or higher

## Installation

Simply clone the repository and load the `nn.pl` file:

```bash
git clone https://github.com/e9-o9/nn.pl
cd nn.pl/lang/pl
swipl
```

Then in the Prolog REPL:

```prolog
?- consult('nn.pl').
```

## Quick Start

### Traditional Interface: Creating a Network

```prolog
% Create a network with 2 inputs, 3 hidden neurons, and 1 output
?- create_network([2, 3, 1], Network, Weights).
```

### Traditional Interface: Making Predictions

```prolog
% Forward propagation
?- create_network([2, 3, 1], Network, _),
   predict([0.5, 0.8], Network, Output).
```

### Traditional Interface: Training a Network

```prolog
% Train on XOR problem
?- create_network([2, 4, 1], Network, _),
   TrainingData = [
       sample([0, 0], [0]),
       sample([0, 1], [1]),
       sample([1, 0], [1]),
       sample([1, 1], [0])
   ],
   train(TrainingData, Network, 0.5, 1000, TrainedNetwork),
   predict([1, 1], TrainedNetwork, Output).
```

### NEW! Module-Based Interface: Building Networks

```prolog
% Build a classification network using Sequential
?- nn:linear_module(2, 4, L1),
   nn:tanh_module(Tanh),
   nn:linear_module(4, 3, L2),
   nn:log_softmax_module(LogSoftMax),
   Network = sequential([L1, Tanh, L2, LogSoftMax]),
   nn:sequential_forward(Network, [0.5, 0.8], Output).
```

### NEW! Using Different Loss Functions

```prolog
% MSE for regression
?- nn:mse_criterion(MSE),
   nn:criterion_forward(MSE, [1.5, 2.3], [1.0, 2.0], Loss).

% ClassNLL for classification
?- nn:class_nll_criterion(NLL),
   nn:criterion_forward(NLL, [-0.5, -1.2, -2.3], 0, Loss).

% Binary Cross Entropy
?- nn:bce_criterion(BCE),
   nn:criterion_forward(BCE, [0.8, 0.3], [1.0, 0.0], Loss).
```

## API Reference

### Network Creation

#### `create_network(+LayerSizes, -Network, -Weights)`
Creates a neural network with the specified architecture.

- **LayerSizes**: List of integers `[InputSize, Hidden1, Hidden2, ..., OutputSize]`
- **Network**: Returns the network structure
- **Weights**: Returns the initialized random weights

Example:
```prolog
?- create_network([2, 4, 1], Network, Weights).
```

### Forward Propagation

#### `forward(+Input, +Network, -Output)`
Performs forward propagation through the network.

- **Input**: List of input values
- **Network**: The network structure
- **Output**: List of output values

#### `predict(+Input, +Network, -Output)`
Alias for `forward/3`, makes a prediction using the trained network.

### Training

#### `train(+TrainingData, +Network, +LearningRate, +Epochs, -TrainedNetwork)`
Trains the network using backpropagation.

- **TrainingData**: List of `sample(Input, Target)` terms
- **Network**: Initial network
- **LearningRate**: Learning rate (typically 0.01 - 1.0)
- **Epochs**: Number of training epochs
- **TrainedNetwork**: Returns the trained network

Example:
```prolog
?- TrainingData = [sample([0, 0], [0]), sample([0, 1], [1])],
   train(TrainingData, Network, 0.5, 1000, TrainedNetwork).
```

#### `backprop(+Input, +Target, +Network, +LearningRate, -UpdatedNetwork)`
Performs one step of backpropagation for a single training example.

### Activation Functions

#### `sigmoid(+X, -Y)`
Sigmoid activation: `y = 1 / (1 + e^(-x))`

#### `tanh_activation(+X, -Y)`
Hyperbolic tangent activation

#### `relu(+X, -Y)`
ReLU activation: `y = max(0, x)`

### Loss Functions

#### `mse_loss(+Predicted, +Target, -Loss)`
Computes Mean Squared Error loss.

### Vector and Matrix Operations

#### `dot_product(+Vector1, +Vector2, -Result)`
Computes dot product of two vectors.

#### `add_vectors(+Vector1, +Vector2, -Result)`
Element-wise vector addition.

#### `matrix_vector_mult(+Matrix, +Vector, -Result)`
Matrix-vector multiplication.

## Module-Based API Reference (NEW!)

The module-based interface provides a more flexible and composable way to build neural networks, similar to PyTorch or Torch/nn.

### Container Modules

#### `sequential(+Modules)`
Creates a Sequential container that chains modules together in feed-forward manner.

```prolog
?- nn:linear_module(10, 20, L1),
   nn:relu_module(ReLU),
   nn:linear_module(20, 10, L2),
   Network = sequential([L1, ReLU, L2]).
```

#### `sequential_forward(+Sequential, +Input, -Output)`
Performs forward pass through a sequential container.

#### `concat(+Dim, +Modules)`
Creates a Concat container that applies each module to the input and concatenates outputs.

```prolog
?- nn:identity_module(Branch1),
   nn:identity_module(Branch2),
   Network = concat(1, [Branch1, Branch2]).
```

### Activation/Transfer Modules

#### `sigmoid_module(-Module)`
Creates a Sigmoid activation module.

#### `tanh_module(-Module)`
Creates a Tanh activation module.

#### `relu_module(-Module)`
Creates a ReLU activation module.

#### `softmax_module(-Module)`
Creates a SoftMax module that converts logits to probabilities.

#### `log_softmax_module(-Module)`
Creates a LogSoftMax module (log of softmax, numerically stable).

#### `module_forward(+Module, +Input, -Output)`
Generic forward pass through any module.

```prolog
?- nn:sigmoid_module(Sigmoid),
   nn:module_forward(Sigmoid, [0, 1, -1], Output).
```

### Criterion/Loss Modules

#### `mse_criterion(-Criterion)`
Mean Squared Error criterion for regression.

#### `class_nll_criterion(-Criterion)`
Negative Log Likelihood criterion for classification (use with LogSoftMax).

#### `bce_criterion(-Criterion)`
Binary Cross Entropy criterion for binary classification.

#### `abs_criterion(-Criterion)`
L1/Absolute Error criterion.

#### `criterion_forward(+Criterion, +Input, +Target, -Loss)`
Computes loss for a given criterion.

```prolog
?- nn:mse_criterion(MSE),
   nn:criterion_forward(MSE, [1.5, 2.3], [1.0, 2.0], Loss).
```

#### `criterion_backward(+Criterion, +Input, +Target, -GradInput)`
Computes gradient for backpropagation.

### Simple Layer Modules

#### `linear_module(+InputSize, +OutputSize, -Module)`
Creates a fully connected linear layer.

```prolog
?- nn:linear_module(10, 5, Linear).
```

#### `identity_module(-Module)`
Creates an Identity module (pass-through).

#### `reshape_module(+Shape, -Module)`
Creates a Reshape module.

#### `mean_module(+Dim, -Module)`
Creates a Mean reduction module.

#### `max_module(+Dim, -Module)`
Creates a Max reduction module.

## Examples

### Example: Building a Classification Network with Modules

```prolog
% Load the library
?- consult('nn.pl').

% Build a 2-layer network for 3-class classification
?- nn:linear_module(5, 10, L1),
   nn:tanh_module(Tanh),
   nn:linear_module(10, 3, L2),
   nn:log_softmax_module(LogSoftMax),
   Network = sequential([L1, Tanh, L2, LogSoftMax]),
   
   % Forward pass
   Input = [0.1, 0.2, 0.3, 0.4, 0.5],
   nn:sequential_forward(Network, Input, LogProbs),
   
   % Compute loss
   nn:class_nll_criterion(NLL),
   Target = 1,  % Correct class
   nn:criterion_forward(NLL, LogProbs, Target, Loss).
```

### Rank-Parametric nD Convolution and Fractal Networks

Dimension is a parameter, not a class. `nn_nd.pl` provides a single `convnd`
abstraction whose rank selects behavior, obeying the output shape law
`out_i = ⌊(in_i + 2p_i − d_i·(k_i − 1) − 1) / s_i⌋ + 1` for all ranks:

```prolog
?- consult('nn_nd.pl').

% 2D convolution: 1 input channel, 4 output channels, 3x3 kernel
?- nn_nd:convnd_module(2, 1, 4, [3,3], Conv2D).

% The same constructor at rank 4 (spatiotemporal) — no new code
?- nn_nd:convnd_module(4, 1, 4, [2,2,2,2], Conv4D).

% Rank-generic pooling and forward pass
?- nn_nd:convnd_module(2, 1, 1, [2,2], Conv),
   nn_nd:poolnd_module(2, [2,2], max, Pool),
   Net = sequential([Conv, Pool]),
   nn_nd:nd_module_forward(Net, [[[1,2,3],[4,5,6],[7,8,9]]], Out).

% High ranks: separable factorization, O(R·k) instead of O(k^R) parameters
?- nn_nd:separable_convnd_module(3, 8, [3,3,3], SepConv3D).

% Fractal topology: f_k = join(f_{k-1} ∘ f_{k-1}, base), depth 2^(k-1)
?- nn_nd:convnd_module(2, 1, 1, [3,3], Base),
   nn_nd:fractal_module(3, Base, Fractal).

% Drop-path regularization: stochastic branch mask over concat_avg
?- nn_nd:fractal_module(2, identity, concat_avg(Branches)),
   nn_nd:random_drop_path_mask(2, 0.7, Mask),
   nn_nd:drop_path_forward(concat_avg(Branches), Mask, [1.0, 2.0], Out).

% Fractal data domains: lower to a graph and use message passing
?- nn_nd:sierpinski_graph(3, Graph, Vertices),
   nn_nd:graph_conv_module(4, 8, GConv).

% nD grids are just graphs with regular structure
?- nn_nd:grid_graph([4,4,4], Graph).
```

### XOR Problem

The XOR problem is a classic test for neural networks:

```prolog
?- consult('nn.pl').
?- example_xor.

Training XOR network...
Testing predictions:
  [0, 0] -> [0.05123...]
  [0, 1] -> [0.94567...]
  [1, 0] -> [0.95234...]
  [1, 1] -> [0.04891...]
```

### Simple Regression

Approximate a function (e.g., `f(x) = x^2`):

```prolog
?- consult('nn.pl').
?- example_regression.

Training regression network...
Testing predictions:
  f(0.0) = [0.0234...] (expected: 0.0)
  f(1.0) = [0.9876...] (expected: 1.0)
  f(1.5) = [2.1543...] (expected: 2.25)
```

### Custom Problem

```prolog
% Create a network for binary classification
?- create_network([5, 8, 2], Network, _),
   TrainingData = [
       sample([1, 0, 1, 0, 1], [1, 0]),
       sample([0, 1, 0, 1, 0], [0, 1])
   ],
   train(TrainingData, Network, 0.3, 500, TrainedNetwork),
   predict([1, 0, 1, 0, 1], TrainedNetwork, Output).
```

## Running Tests

Run the traditional interface tests:
```bash
cd lang/pl
swipl -q -l test_nn.pl -g run_tests -t halt
```

Run the module-based interface tests:
```bash
cd lang/pl
swipl -q -l test_modules.pl -g run_module_tests -t halt
```

Run the nD / fractal module tests:

```bash
swipl -q -l test_nd.pl -g run_nd_tests -t halt
```

Or within the Prolog REPL:

```prolog
?- consult('test_nn.pl').
?- run_tests.

?- consult('test_modules.pl').
?- run_module_tests.
```

## Running Demos

Run the traditional demos:
```bash
cd lang/pl
swipl -l demo.pl -g "run_all_demos" -t halt
```

Run the module-based demos (NEW!):
```bash
cd lang/pl
swipl -l demo_modules.pl -g "run_all_demos" -t halt
```

The module demos include:
- Sequential classification networks
- Comparing different activation functions
- Using different loss functions
- Simple layer operations
- SoftMax vs LogSoftMax
- Building complex multi-layer networks
- Using Concat containers

## Architecture

The implementation consists of several key components:

1. **Network Structure**: Networks are represented as `network(LayerSizes, Weights)` terms
2. **Weights**: Each layer has a list of neurons, each neuron has `neuron(Weights, Bias)`
3. **Forward Propagation**: Recursive computation through layers with sigmoid activation
4. **Backpropagation**: Gradient computation and weight updates using chain rule
5. **Training**: Iterative epoch-based training with full batch updates

### Data Structures

- **Network**: `network(LayerSizes, Weights)`
- **Neuron**: `neuron(Weights, Bias)`
- **Training Sample**: `sample(Input, Target)`
- **Gradient**: `gradient(WeightGradients, BiasGradient)`

## Limitations

- Backpropagation currently only integrated with traditional interface (module-based training coming soon)
- Full batch training only (no mini-batch or stochastic gradient descent)
- No regularization (L1/L2)
- No momentum or adaptive learning rates
- Performance is limited compared to optimized libraries (this is for educational purposes)

## Performance Tips

- Use smaller networks for faster training
- Adjust learning rate based on problem (0.1 - 0.5 works well for most problems)
- More hidden neurons can help with complex problems but slow down training
- Training time grows with: network size, dataset size, and number of epochs

## Educational Purpose

This implementation is designed for:
- Learning how neural networks work
- Understanding backpropagation in detail
- Experimenting with network architectures
- Teaching Prolog programming
- Prototyping simple ML problems

For production use, consider established libraries like TensorFlow, PyTorch, or similar.

## License

See COPYRIGHT.txt in the repository.

## Contributing

Contributions are welcome! See CONTRIBUTING.md for guidelines.

## References

- [Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/)
- [Backpropagation Algorithm](https://en.wikipedia.org/wiki/Backpropagation)
- [SWI-Prolog Documentation](https://www.swi-prolog.org/pldoc/)
