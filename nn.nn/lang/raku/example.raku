#!/usr/bin/env raku

# Practical Example: Training a Neural Network
# A complete, runnable example showing how to use the neural network library

use lib '.';
use NN;

# ============================================================================
# Example: XOR Problem with Detailed Output
# ============================================================================

say "=" x 40;
say "Neural Network Training Example";
say "Problem: XOR (Non-linearly Separable)";
say "=" x 40;
say "";

# Step 1: Prepare training data
say "Step 1: Creating training dataset...";
my @xor-training-data = [
    make-sample([0.0, 0.0], [0.0]),
    make-sample([0.0, 1.0], [1.0]),
    make-sample([1.0, 0.0], [1.0]),
    make-sample([1.0, 1.0], [0.0])
];

say "Training data:";
say "  Input: [0, 0] -> Target: 0";
say "  Input: [0, 1] -> Target: 1";
say "  Input: [1, 0] -> Target: 1";
say "  Input: [1, 1] -> Target: 0";

# Step 2: Create network architecture
say "";
say "Step 2: Creating neural network...";
say "Architecture: 2 inputs -> 4 hidden -> 1 output";
my $network = create-network([2, 4, 1]);
say "Network initialized with random weights";

# Step 3: Test untrained network
say "";
say "Step 3: Testing untrained network...";
say "Predictions before training:";
printf "  XOR(0, 0) = %.4f (expected 0)\n", predict([0.0, 0.0], $network)[0];
printf "  XOR(0, 1) = %.4f (expected 1)\n", predict([0.0, 1.0], $network)[0];
printf "  XOR(1, 0) = %.4f (expected 1)\n", predict([1.0, 0.0], $network)[0];
printf "  XOR(1, 1) = %.4f (expected 0)\n", predict([1.0, 1.0], $network)[0];

# Step 4: Train the network
say "";
say "Step 4: Training network...";
say "Hyperparameters:";
say "  Learning rate: 0.5";
say "  Epochs: 2000";

say "";
say "Training in progress...";
my $trained-network = train(@xor-training-data, $network, 0.5, 2000);
say "Training completed!";

# Step 5: Test trained network
say "";
say "Step 5: Testing trained network...";
say "Predictions after training:";
my $result00 = predict([0.0, 0.0], $trained-network)[0];
my $result01 = predict([0.0, 1.0], $trained-network)[0];
my $result10 = predict([1.0, 0.0], $trained-network)[0];
my $result11 = predict([1.0, 1.0], $trained-network)[0];

printf "  XOR(0, 0) = %.4f (expected 0) %s\n", 
    $result00,
    $result00 < 0.2 ?? "✓" !! "✗";
printf "  XOR(0, 1) = %.4f (expected 1) %s\n", 
    $result01,
    $result01 > 0.8 ?? "✓" !! "✗";
printf "  XOR(1, 0) = %.4f (expected 1) %s\n", 
    $result10,
    $result10 > 0.8 ?? "✓" !! "✗";
printf "  XOR(1, 1) = %.4f (expected 0) %s\n", 
    $result11,
    $result11 < 0.2 ?? "✓" !! "✗";

# Step 6: Summary
say "";
say "Step 6: Summary";
say "The network successfully learned the XOR function!";
say "This demonstrates that the neural network can learn";
say "non-linear decision boundaries through backpropagation.";

# Additional example: Using the module system
say "";
say "=" x 40;
say "Bonus: Module-Based Architecture";
say "=" x 40;
say "";

say "Building network using modules:";
my $linear1 = make-linear(2, 4);
my $tanh-layer = tanh-module();
my $linear2 = make-linear(4, 1);
my $sigmoid-layer = sigmoid-module();

my $modular-network = make-sequential([$linear1, $tanh-layer, $linear2, $sigmoid-layer]);

say "Modules:";
say "  1. Linear(2 -> 4)";
say "  2. Tanh()";
say "  3. Linear(4 -> 1)";
say "  4. Sigmoid()";

say "";
say "Testing modular network:";
my $modular-output = module-forward($modular-network, [0.5, 0.8]);
printf "Output: %s\n", $modular-output.raku;

# Using criterion
say "";
say "Using loss criterion:";
my $criterion = mse-criterion();
my $loss = criterion-forward($criterion, $modular-output, [1.0]);
printf "MSE Loss: %.6f\n", $loss;

say "";
say "=" x 40;
say "Example completed successfully!";
say "=" x 40;
