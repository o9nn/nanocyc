#!/usr/bin/env raku

# Neural Network Implementation in Pure Raku
# A minimal, pure Raku implementation of feedforward neural networks
# with backpropagation training and modular architecture.
#
# This implementation provides:
# - Feedforward neural networks with arbitrary layer sizes
# - Multiple activation functions (sigmoid, tanh, relu)
# - Backpropagation training algorithm
# - Modular architecture with containers and modules
# - Multiple loss criterions
# - Vector and matrix operations

unit module NN;

# ============================================================================
# Utility Functions - Random Number Generation
# ============================================================================

sub random-real() is export {
    # Generate a random real number between 0 and 1
    rand;
}

sub random-weight() is export {
    # Generate a random weight between -0.5 and 0.5
    rand - 0.5;
}

# ============================================================================
# Mathematical Functions
# ============================================================================

sub exp-safe($x) is export {
    # Safe exponential function that handles overflow
    if $x > 20 { e ** 20 }
    elsif $x < -20 { e ** -20 }
    else { e ** $x }
}

sub sigmoid($x) is export {
    # Sigmoid activation function: 1 / (1 + exp(-x))
    1.0 / (1.0 + exp-safe(-$x));
}

sub sigmoid-derivative($x) is export {
    # Derivative of sigmoid: sigmoid(x) * (1 - sigmoid(x))
    my $s = sigmoid($x);
    $s * (1.0 - $s);
}

sub tanh-activation($x) is export {
    # Hyperbolic tangent activation function
    tanh($x);
}

sub tanh-derivative($x) is export {
    # Derivative of tanh: 1 - tanh(x)^2
    my $t = tanh($x);
    1.0 - ($t * $t);
}

sub relu($x) is export {
    # ReLU activation function: max(0, x)
    max(0.0, $x);
}

sub relu-derivative($x) is export {
    # Derivative of ReLU: 1 if x > 0, else 0
    $x > 0.0 ?? 1.0 !! 0.0;
}

# ============================================================================
# Vector Operations
# ============================================================================

sub vector-map(&f, @v) is export {
    # Apply function f to each element of vector v
    @v.map(&f).Array;
}

sub vector-map2(&f, @v1, @v2) is export {
    # Apply binary function f to corresponding elements of v1 and v2
    (@v1 Z @v2).map(-> ($a, $b) { f($a, $b) }).Array;
}

sub dot-product(@v1, @v2) is export {
    # Compute dot product of two vectors
    [+] (@v1 Z* @v2);
}

sub vector-add(@v1, @v2) is export {
    # Add two vectors element-wise
    vector-map2(* + *, @v1, @v2);
}

sub vector-sub(@v1, @v2) is export {
    # Subtract v2 from v1 element-wise
    vector-map2(* - *, @v1, @v2);
}

sub scalar-mult-vector($s, @v) is export {
    # Multiply vector by scalar
    vector-map(* * $s, @v);
}

sub vector-sum(@v) is export {
    # Sum all elements in vector
    [+] @v;
}

sub vector-mean(@v) is export {
    # Compute mean of vector elements
    vector-sum(@v) / @v.elems;
}

sub vector-max(@v) is export {
    # Find maximum element in vector
    @v.max;
}

sub vector-min(@v) is export {
    # Find minimum element in vector
    @v.min;
}

# ============================================================================
# Matrix Operations
# ============================================================================

sub matrix-vector-mult(@matrix, @vec) is export {
    # Multiply matrix by vector
    @matrix.map(-> @row { dot-product(@row, @vec) }).Array;
}

sub transpose(@matrix) is export {
    # Transpose a matrix
    return [] if @matrix.elems == 0;
    my $cols = @matrix[0].elems;
    (0..^$cols).map(-> $i { @matrix.map(*[$i]).Array }).Array;
}

sub matrix-scalar-mult($s, @matrix) is export {
    # Multiply matrix by scalar
    @matrix.map(-> @row { scalar-mult-vector($s, @row) }).Array;
}

# ============================================================================
# Network Structure
# ============================================================================

class Network is export {
    has @.layer-sizes;
    has @.weights;
    
    method new(@layer-sizes) {
        my @weights = init-weights(@layer-sizes);
        self.bless(:@layer-sizes, :@weights);
    }
}

sub init-weights(@layer-sizes) is export {
    # Initialize random weights for all layers
    my @weights;
    for 0..^(@layer-sizes.elems - 1) -> $i {
        my $input-size = @layer-sizes[$i];
        my $output-size = @layer-sizes[$i + 1];
        @weights.push(init-layer-weights($input-size, $output-size));
    }
    @weights;
}

sub init-layer-weights($input-size, $output-size) is export {
    # Initialize weights for a single layer
    my @layer-weights;
    for 0..^$output-size {
        my @weights = (0..^$input-size).map({ random-weight() }).Array;
        my $bias = random-weight();
        @layer-weights.push({ weights => @weights, bias => $bias });
    }
    @layer-weights;
}

# ============================================================================
# Forward Propagation
# ============================================================================

sub forward(@input, @weights) is export {
    # Forward propagation through the network
    return @input if @weights.elems == 0;
    
    my $layer-weights = @weights[0];
    my @activations = $layer-weights.Array.map(-> $neuron {
        my @w = @($neuron<weights>);
        sigmoid(dot-product(@input, @w) + $neuron<bias>)
    }).Array;
    
    forward(@activations, @weights[1..*]);
}

sub forward-with-activations(@input, @weights) is export {
    # Forward propagation that also returns intermediate activations
    my @all-activations;
    @all-activations.push([@input]);
    my @current = @input;
    
    for @weights -> $layer {
        my @layer-arr = @($layer);
        my @next = @layer-arr.map(-> $neuron {
            my @w = @($neuron<weights>);
            sigmoid(dot-product(@current, @w) + $neuron<bias>)
        }).Array;
        @all-activations.push([@next]);
        @current = @next;
    }
    
    @all-activations;
}

sub predict(@input, Network $network) is export {
    # Make a prediction using the network
    forward(@input, $network.weights);
}

# ============================================================================
# Loss Functions
# ============================================================================

sub mse-loss(@output, @target) is export {
    # Mean Squared Error loss
    my @diff = vector-sub(@output, @target);
    vector-sum(vector-map(* ** 2, @diff)) / @diff.elems;
}

sub mse-loss-derivative(@output, @target) is export {
    # Derivative of MSE loss with respect to output
    my @diff = vector-sub(@output, @target);
    scalar-mult-vector(2.0 / @diff.elems, @diff);
}

# ============================================================================
# Backpropagation
# ============================================================================

sub compute-gradients(@activations, @target, @weights) is export {
    # Compute gradients for all weights using backpropagation
    my @output = @(@activations[*-1]);
    my @output-error = mse-loss-derivative(@output, @target);
    
    # Initialize deltas for output layer
    my @deltas = [@output-error Z* @output.map({ $_ * (1.0 - $_) })];
    
    # Backpropagate through layers
    for (@weights.elems - 1)...1 -> $i {
        my $layer-weights = @weights[$i];
        my @layer-weights-arr = @($layer-weights);
        my @prev-deltas = @(@deltas[0]);
        
        # Compute weight matrix for this layer
        my @weight-matrix = @layer-weights-arr.map(-> $n { @($n<weights>) });
        my @transposed = transpose(@weight-matrix);
        
        # Propagate error backward
        my @error = matrix-vector-mult(@transposed, @prev-deltas);
        my @activation = @(@activations[$i]);
        my @layer-deltas = @error Z* @activation.map({ $_ * (1.0 - $_) });
        
        @deltas.unshift(@layer-deltas);
    }
    
    # Compute weight gradients
    my @gradients;
    for 0..^@weights.elems -> $i {
        my @layer-gradients;
        my @layer-activations = @(@activations[$i]);
        my @layer-deltas = @(@deltas[$i]);
        
        for 0..^@layer-deltas.elems -> $j {
            my @weight-gradients = scalar-mult-vector(@layer-deltas[$j], @layer-activations);
            my $bias-gradient = @layer-deltas[$j];
            @layer-gradients.push({ weights => @weight-gradients, bias => $bias-gradient });
        }
        @gradients.push(@layer-gradients);
    }
    
    @gradients;
}

sub update-weights(@weights, @gradients, $learning-rate) is export {
    # Update weights using computed gradients
    my @new-weights;
    
    for 0..^@weights.elems -> $i {
        my $layer-weights = @weights[$i];
        my @layer-weights-arr = @($layer-weights);
        my $layer-gradients = @gradients[$i];
        my @layer-gradients-arr = @($layer-gradients);
        my @new-layer;
        
        for 0..^@layer-weights-arr.elems -> $j {
            my $neuron = @layer-weights-arr[$j];
            my $gradient = @layer-gradients-arr[$j];
            
            my @new-neuron-weights = vector-sub(
                @($neuron<weights>),
                scalar-mult-vector($learning-rate, @($gradient<weights>))
            );
            my $new-bias = $neuron<bias> - ($learning-rate * $gradient<bias>);
            
            @new-layer.push({ weights => @new-neuron-weights, bias => $new-bias });
        }
        @new-weights.push(@new-layer);
    }
    
    @new-weights;
}

# ============================================================================
# Training
# ============================================================================

sub train-epoch(@training-data, @weights, $learning-rate) is export {
    # Train for one epoch over the training data
    my @current-weights = @weights;
    
    for @training-data -> $sample {
        my @input = $sample<input>;
        my @target = $sample<target>;
        
        my @activations = forward-with-activations(@input, @current-weights);
        my @gradients = compute-gradients(@activations, @target, @current-weights);
        @current-weights = update-weights(@current-weights, @gradients, $learning-rate);
    }
    
    @current-weights;
}

sub train(@training-data, Network $network, $learning-rate, $epochs) is export {
    # Train the network for multiple epochs
    my @weights = $network.weights;
    
    for 1..$epochs -> $epoch {
        @weights = train-epoch(@training-data, @weights, $learning-rate);
    }
    
    Network.new($network.layer-sizes).bless(layer-sizes => $network.layer-sizes, weights => @weights);
}

sub make-sample(@input, @target) is export {
    # Create a training sample
    { input => @input, target => @target };
}

# ============================================================================
# Network Creation Helper
# ============================================================================

sub create-network(@layer-sizes) is export {
    # Create a new neural network with specified layer sizes
    Network.new(@layer-sizes);
}

# ============================================================================
# Module-Based Architecture
# ============================================================================

# Module base class
role Module is export {
    method forward($input) { ... }
    method backward($grad-output) { ... }
}

# Sequential container
class Sequential does Module is export {
    has @.modules;
    
    method new(@modules) {
        self.bless(:@modules);
    }
    
    method forward($input) {
        my @current = @($input);
        for @.modules -> $module {
            @current = @($module.forward(@current));
        }
        @current;
    }
    
    method backward($grad-output) {
        my $grad = $grad-output;
        for @.modules.reverse -> $module {
            $grad = $module.backward($grad);
        }
        $grad;
    }
}

sub make-sequential(@modules) is export {
    # Create a sequential container
    Sequential.new(@modules);
}

# Linear layer
class Linear does Module is export {
    has $.input-size;
    has $.output-size;
    has @.weights;
    has @.bias;
    has @.last-input;
    
    method new($input-size, $output-size) {
        my @weights;
        for 0..^$output-size {
            @weights.push((0..^$input-size).map({ random-weight() }).Array);
        }
        my @bias = (0..^$output-size).map({ random-weight() }).Array;
        self.bless(:$input-size, :$output-size, :@weights, :@bias, :last-input([]));
    }
    
    method forward($input) {
        @.last-input = $input.Array;
        my @output;
        for 0..^$.output-size -> $i {
            @output.push(dot-product(@.weights[$i], $input) + @.bias[$i]);
        }
        @output;
    }
    
    method backward($grad-output) {
        # For now, return gradient (simplified)
        $grad-output;
    }
}

sub make-linear($input-size, $output-size) is export {
    # Create a linear layer
    Linear.new($input-size, $output-size);
}

# Activation modules
class SigmoidModule does Module is export {
    has @.last-output;
    
    method forward($input) {
        @.last-output = vector-map(&sigmoid, $input);
        @.last-output;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub sigmoid-module() is export {
    # Create a sigmoid activation module
    SigmoidModule.new;
}

class TanhModule does Module is export {
    has @.last-output;
    
    method forward($input) {
        @.last-output = vector-map(&tanh-activation, $input);
        @.last-output;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub tanh-module() is export {
    # Create a tanh activation module
    TanhModule.new;
}

class ReLUModule does Module is export {
    has @.last-output;
    
    method forward($input) {
        @.last-output = vector-map(&relu, $input);
        @.last-output;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub relu-module() is export {
    # Create a ReLU activation module
    ReLUModule.new;
}

sub identity-module() is export {
    # Create an identity module (pass-through)
    class Identity does Module {
        method forward($input) { @($input) }
        method backward($grad-output) { $grad-output }
    }.new;
}

# ============================================================================
# Criterion Modules (Loss Functions)
# ============================================================================

role Criterion is export {
    method forward($input, $target) { ... }
    method backward($input, $target) { ... }
}

class MSECriterion does Criterion is export {
    method forward($input, $target) {
        mse-loss($input, $target);
    }
    
    method backward($input, $target) {
        mse-loss-derivative($input, $target);
    }
}

sub mse-criterion() is export {
    # Create an MSE criterion
    MSECriterion.new;
}

class AbsCriterion does Criterion is export {
    method forward($input, $target) {
        my @diff = vector-sub($input, $target);
        vector-sum(vector-map(&abs, @diff)) / @diff.elems;
    }
    
    method backward($input, $target) {
        my @diff = vector-sub($input, $target);
        vector-map(-> $x { $x > 0 ?? 1.0 !! -1.0 }, @diff);
    }
}

sub abs-criterion() is export {
    # Create an absolute error criterion
    AbsCriterion.new;
}

class BCECriterion does Criterion is export {
    method forward($input, $target) {
        # Binary Cross Entropy loss
        my $epsilon = 1e-10;
        my @input-arr = @($input);
        my @target-arr = @($target);
        my @losses = (@input-arr Z @target-arr).map(-> ($pred, $tgt) {
            -($tgt * log($pred + $epsilon) + (1 - $tgt) * log(1 - $pred + $epsilon))
        });
        vector-mean(@losses);
    }
    
    method backward($input, $target) {
        my $epsilon = 1e-10;
        my @input-arr = @($input);
        my @target-arr = @($target);
        (@input-arr Z @target-arr).map(-> ($pred, $tgt) {
            ($pred - $tgt) / (($pred + $epsilon) * (1 - $pred + $epsilon))
        }).Array;
    }
}

sub bce-criterion() is export {
    # Create a binary cross-entropy criterion
    BCECriterion.new;
}

# ============================================================================
# Utility Functions for Modules
# ============================================================================

sub module-forward($module, $input) is export {
    # Forward pass through a module
    $module.forward($input);
}

sub module-backward($module, $grad-output) is export {
    # Backward pass through a module
    $module.backward($grad-output);
}

sub criterion-forward($criterion, $input, $target) is export {
    # Compute loss using a criterion
    $criterion.forward($input, $target);
}

sub criterion-backward($criterion, $input, $target) is export {
    # Compute gradient of loss using a criterion
    $criterion.backward($input, $target);
}

# ============================================================================
# Additional Transfer Functions for Modules
# ============================================================================

class LogSoftMaxModule does Module is export {
    has @.last-output;
    
    method forward($input) {
        my $max-val = vector-max($input);
        my @shifted = $input.map(* - $max-val);
        my @exp-vals = vector-map({ e ** $_ }, @shifted);
        my $sum = vector-sum(@exp-vals);
        @.last-output = @shifted.map(* - log($sum));
        @.last-output;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub log-softmax-module() is export {
    # Create a log-softmax module
    LogSoftMaxModule.new;
}

class SoftMaxModule does Module is export {
    has @.last-output;
    
    method forward($input) {
        my $max-val = vector-max($input);
        my @shifted = $input.map(* - $max-val);
        my @exp-vals = vector-map({ e ** $_ }, @shifted);
        my $sum = vector-sum(@exp-vals);
        @.last-output = scalar-mult-vector(1.0 / $sum, @exp-vals);
        @.last-output;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub softmax-module() is export {
    # Create a softmax module
    SoftMaxModule.new;
}

# ============================================================================
# Simple Layer Modules
# ============================================================================

class ReshapeModule does Module is export {
    has @.target-shape;
    
    method new(@target-shape) {
        self.bless(:@target-shape);
    }
    
    method forward($input) {
        # For now, just flatten or return as-is
        $input.flat.Array;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub reshape-module(@target-shape) is export {
    # Create a reshape module
    ReshapeModule.new(@target-shape);
}

class MeanModule does Module is export {
    has $.dim;
    
    method new($dim) {
        self.bless(:$dim);
    }
    
    method forward($input) {
        vector-mean($input);
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub mean-module($dim) is export {
    # Create a mean module
    MeanModule.new($dim);
}

class MaxModule does Module is export {
    has $.dim;
    
    method new($dim) {
        self.bless(:$dim);
    }
    
    method forward($input) {
        vector-max($input);
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub max-module($dim) is export {
    # Create a max module
    MaxModule.new($dim);
}

# ============================================================================
# Container Modules
# ============================================================================

class Concat does Module is export {
    has @.modules;
    has $.dim;
    
    method new(@modules, $dim) {
        self.bless(:@modules, :$dim);
    }
    
    method forward($input) {
        my @outputs = @.modules.map(*.forward($input));
        # Concatenate outputs
        @outputs.flat.Array;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub concat-module(@modules, $dim) is export {
    # Create a concat module
    Concat.new(@modules, $dim);
}

class ConcatTable does Module is export {
    has @.modules;
    
    method new(@modules) {
        self.bless(:@modules);
    }
    
    method forward($input) {
        @.modules.map(*.forward($input)).Array;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub concat-table(@modules) is export {
    # Create a concat-table module
    ConcatTable.new(@modules);
}

class Parallel does Module is export {
    has @.modules;
    has $.input-dim;
    has $.output-dim;
    
    method new($input-dim, $output-dim, @modules) {
        self.bless(:$input-dim, :$output-dim, :@modules);
    }
    
    method forward($input) {
        # Process inputs in parallel through modules
        @.modules.map(*.forward($input)).flat.Array;
    }
    
    method backward($grad-output) {
        $grad-output;
    }
}

sub parallel-module($input-dim, $output-dim, @modules) is export {
    # Create a parallel module
    Parallel.new($input-dim, $output-dim, @modules);
}
