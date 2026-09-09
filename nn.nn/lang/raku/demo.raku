#!/usr/bin/env raku

# demo.raku - Demonstration script for nn.raku
# Run with: raku demo.raku

use lib '.';
use NN;

# ============================================================================
# Demo 1: Basic Network Creation
# ============================================================================

sub demo-basic() {
    say "";
    say "=== Demo 1: Basic Network Creation ===";
    say "Creating a 2-3-1 network...";
    my $network = create-network([2, 3, 1]);
    say "Network created with layers: ", $network.layer-sizes.raku;
    say "Testing forward propagation with input [0.5, 0.8]...";
    my @output = predict([0.5, 0.8], $network);
    printf "Output: %.6f\n", @output[0];
}

# ============================================================================
# Demo 2: XOR Problem
# ============================================================================

sub demo-xor() {
    say "";
    say "=== Demo 2: XOR Problem ===";
    say "Training network to learn XOR function...";
    my $network = create-network([2, 4, 1]);
    
    my @training-data = [
        make-sample([0.0, 0.0], [0.0]),
        make-sample([0.0, 1.0], [1.0]),
        make-sample([1.0, 0.0], [1.0]),
        make-sample([1.0, 1.0], [0.0])
    ];
    
    say "Training for 1000 epochs with learning rate 0.5...";
    my $trained-network = train(@training-data, $network, 0.5, 1000);
    
    say "";
    say "Testing predictions:";
    my $out1 = predict([0.0, 0.0], $trained-network)[0];
    my $out2 = predict([0.0, 1.0], $trained-network)[0];
    my $out3 = predict([1.0, 0.0], $trained-network)[0];
    my $out4 = predict([1.0, 1.0], $trained-network)[0];
    
    printf "  XOR(0, 0) = %.4f (expected: 0)\n", $out1;
    printf "  XOR(0, 1) = %.4f (expected: 1)\n", $out2;
    printf "  XOR(1, 0) = %.4f (expected: 1)\n", $out3;
    printf "  XOR(1, 1) = %.4f (expected: 0)\n", $out4;
}

# ============================================================================
# Demo 3: AND Gate
# ============================================================================

sub demo-and() {
    say "";
    say "=== Demo 3: AND Gate ===";
    say "Training network to learn AND function...";
    my $network = create-network([2, 2, 1]);
    
    my @training-data = [
        make-sample([0.0, 0.0], [0.0]),
        make-sample([0.0, 1.0], [0.0]),
        make-sample([1.0, 0.0], [0.0]),
        make-sample([1.0, 1.0], [1.0])
    ];
    
    say "Training for 500 epochs with learning rate 0.5...";
    my $trained-network = train(@training-data, $network, 0.5, 500);
    
    say "";
    say "Testing predictions:";
    my $out1 = predict([0.0, 0.0], $trained-network)[0];
    my $out2 = predict([0.0, 1.0], $trained-network)[0];
    my $out3 = predict([1.0, 0.0], $trained-network)[0];
    my $out4 = predict([1.0, 1.0], $trained-network)[0];
    
    printf "  AND(0, 0) = %.4f (expected: 0)\n", $out1;
    printf "  AND(0, 1) = %.4f (expected: 0)\n", $out2;
    printf "  AND(1, 0) = %.4f (expected: 0)\n", $out3;
    printf "  AND(1, 1) = %.4f (expected: 1)\n", $out4;
}

# ============================================================================
# Demo 4: Module Architecture
# ============================================================================

sub demo-modules() {
    say "";
    say "=== Demo 4: Module-Based Architecture ===";
    say "Creating a modular neural network...";
    
    # Create modules
    my $linear1 = make-linear(3, 5);
    my $sigmoid1 = sigmoid-module();
    my $linear2 = make-linear(5, 2);
    my $tanh1 = tanh-module();
    
    # Build sequential network
    my $network = make-sequential([$linear1, $sigmoid1, $linear2, $tanh1]);
    
    say "Network structure:";
    say "  Linear(3 -> 5) -> Sigmoid -> Linear(5 -> 2) -> Tanh";
    
    say "";
    say "Testing forward pass with input [0.2, 0.5, 0.8]...";
    my @output = module-forward($network, [0.2, 0.5, 0.8]);
    say "Output: ", @output.raku;
}

# ============================================================================
# Demo 5: Activation Functions
# ============================================================================

sub demo-activations() {
    say "";
    say "=== Demo 5: Activation Functions ===";
    say "Testing different activation functions:";
    
    my @test-values = [-2.0, -1.0, 0.0, 1.0, 2.0];
    
    say "";
    say "Sigmoid:";
    for @test-values -> $x {
        printf "  sigmoid(%.1f) = %.6f\n", $x, sigmoid($x);
    }
    
    say "";
    say "Tanh:";
    for @test-values -> $x {
        printf "  tanh(%.1f) = %.6f\n", $x, tanh-activation($x);
    }
    
    say "";
    say "ReLU:";
    for @test-values -> $x {
        printf "  relu(%.1f) = %.6f\n", $x, relu($x);
    }
}

# ============================================================================
# Demo 6: Vector Operations
# ============================================================================

sub demo-vectors() {
    say "";
    say "=== Demo 6: Vector Operations ===";
    
    my @v1 = [1.0, 2.0, 3.0];
    my @v2 = [4.0, 5.0, 6.0];
    
    say "Vector 1: ", @v1.raku;
    say "Vector 2: ", @v2.raku;
    
    say "";
    say "Operations:";
    say "  Dot product: ", dot-product(@v1, @v2);
    say "  Addition: ", vector-add(@v1, @v2).raku;
    say "  Subtraction: ", vector-sub(@v1, @v2).raku;
    say "  Scalar multiplication (2 * v1): ", scalar-mult-vector(2.0, @v1).raku;
    say "  Sum: ", vector-sum(@v1);
    say "  Mean: ", vector-mean(@v1);
    say "  Max: ", vector-max(@v1);
    say "  Min: ", vector-min(@v1);
}

# ============================================================================
# Demo 7: Loss Functions
# ============================================================================

sub demo-loss-functions() {
    say "";
    say "=== Demo 7: Loss Functions ===";
    
    my @predictions = [0.8, 0.2, 0.9];
    my @targets = [1.0, 0.0, 1.0];
    
    say "Predictions: ", @predictions.raku;
    say "Targets: ", @targets.raku;
    
    say "";
    say "MSE Loss: ", mse-loss(@predictions, @targets);
    
    my $mse-crit = mse-criterion();
    say "MSE Criterion forward: ", criterion-forward($mse-crit, @predictions, @targets);
    
    my $abs-crit = abs-criterion();
    say "Absolute Error Criterion: ", criterion-forward($abs-crit, @predictions, @targets);
}

# ============================================================================
# Demo 8: Simple Regression
# ============================================================================

sub demo-regression() {
    say "";
    say "=== Demo 8: Simple Regression ===";
    say "Learning a simple function: f(x) = 2*x + 1";
    
    my $network = create-network([1, 3, 1]);
    
    # Generate training data
    my @training-data;
    for 0..9 -> $i {
        my $x = $i / 10.0;
        my $y = 2.0 * $x + 1.0;
        @training-data.push(make-sample([$x], [$y]));
    }
    
    say "Training for 500 epochs...";
    my $trained-network = train(@training-data, $network, 0.1, 500);
    
    say "";
    say "Testing on new values:";
    for (0.15, 0.35, 0.55, 0.75) -> $x {
        my $predicted = predict([$x], $trained-network)[0];
        my $expected = 2.0 * $x + 1.0;
        printf "  f(%.2f) = %.4f (expected: %.4f)\n", $x, $predicted, $expected;
    }
}

# ============================================================================
# Main execution
# ============================================================================

sub MAIN() {
    say "";
    say "=" x 50;
    say " Neural Network Demonstrations in Raku ";
    say "=" x 50;
    
    demo-basic();
    demo-xor();
    demo-and();
    demo-modules();
    demo-activations();
    demo-vectors();
    demo-loss-functions();
    demo-regression();
    
    say "";
    say "=" x 50;
    say " All demonstrations completed successfully! ";
    say "=" x 50;
    say "";
}
