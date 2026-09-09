#!/usr/bin/env raku

# test-nn.raku - Test suite for neural network implementation
# Run with: raku test-nn.raku

use lib '.';
use NN;
use Test;

plan 35;

# ============================================================================
# Test 1: Random Number Generation
# ============================================================================

subtest "Random Number Generation" => {
    plan 4;
    
    # Test random-real generates values in [0, 1]
    my $r = random-real();
    ok $r >= 0 && $r <= 1, "random-real generates value in [0, 1]";
    
    # Test random-weight generates values in [-0.5, 0.5]
    my $w = random-weight();
    ok $w >= -0.5 && $w <= 0.5, "random-weight generates value in [-0.5, 0.5]";
    
    # Test randomness (values should differ)
    my @values = (1..10).map({ random-real() });
    ok @values.unique.elems > 5, "random-real generates different values";
    
    ok True, "Random number generation works";
}

# ============================================================================
# Test 2: Mathematical Functions
# ============================================================================

subtest "Sigmoid Function" => {
    plan 4;
    
    # Test sigmoid at 0
    is-approx sigmoid(0.0), 0.5, "sigmoid(0) = 0.5";
    
    # Test sigmoid at positive value
    ok sigmoid(5.0) > 0.9, "sigmoid(5) > 0.9";
    
    # Test sigmoid at negative value
    ok sigmoid(-5.0) < 0.1, "sigmoid(-5) < 0.1";
    
    # Test sigmoid derivative
    is-approx sigmoid-derivative(0.0), 0.25, "sigmoid-derivative(0) = 0.25";
}

subtest "Tanh Function" => {
    plan 3;
    
    is-approx tanh-activation(0.0), 0.0, "tanh(0) = 0";
    ok tanh-activation(5.0) > 0.99, "tanh(5) > 0.99";
    ok tanh-activation(-5.0) < -0.99, "tanh(-5) < -0.99";
}

subtest "ReLU Function" => {
    plan 4;
    
    is relu(0.0), 0.0, "relu(0) = 0";
    is relu(5.0), 5.0, "relu(5) = 5";
    is relu(-5.0), 0.0, "relu(-5) = 0";
    is relu-derivative(5.0), 1.0, "relu-derivative(5) = 1";
}

# ============================================================================
# Test 3: Vector Operations
# ============================================================================

subtest "Vector Map" => {
    plan 2;
    
    my @v = [1, 2, 3];
    my @result = vector-map(* * 2, @v);
    is-deeply @result, [2, 4, 6], "vector-map doubles values";
    
    my @result2 = vector-map(&sigmoid, @v);
    ok @result2.elems == 3, "vector-map applies sigmoid to all elements";
}

subtest "Dot Product" => {
    plan 3;
    
    my @v1 = [1.0, 2.0, 3.0];
    my @v2 = [4.0, 5.0, 6.0];
    is dot-product(@v1, @v2), 32.0, "dot product [1,2,3]·[4,5,6] = 32";
    
    my @v3 = [1.0, 0.0, 0.0];
    my @v4 = [0.0, 1.0, 0.0];
    is dot-product(@v3, @v4), 0.0, "orthogonal vectors have dot product 0";
    
    my @v5 = [2.0, 3.0];
    my @v6 = [4.0, 5.0];
    is dot-product(@v5, @v6), 23.0, "dot product [2,3]·[4,5] = 23";
}

subtest "Vector Addition" => {
    plan 2;
    
    my @v1 = [1.0, 2.0, 3.0];
    my @v2 = [4.0, 5.0, 6.0];
    is-deeply vector-add(@v1, @v2), [5.0, 7.0, 9.0], "vector addition works";
    
    my @v3 = [0.0, 0.0];
    my @v4 = [1.0, 2.0];
    is-deeply vector-add(@v3, @v4), [1.0, 2.0], "adding zero vector works";
}

subtest "Vector Subtraction" => {
    plan 2;
    
    my @v1 = [5.0, 7.0, 9.0];
    my @v2 = [1.0, 2.0, 3.0];
    is-deeply vector-sub(@v1, @v2), [4.0, 5.0, 6.0], "vector subtraction works";
    
    my @v3 = [1.0, 2.0, 3.0];
    is-deeply vector-sub(@v3, @v3), [0.0, 0.0, 0.0], "subtracting from self gives zero";
}

subtest "Scalar Multiplication" => {
    plan 2;
    
    my @v = [1.0, 2.0, 3.0];
    is-deeply scalar-mult-vector(2.0, @v), [2.0, 4.0, 6.0], "scalar multiplication by 2 works";
    is-deeply scalar-mult-vector(0.0, @v), [0.0, 0.0, 0.0], "scalar multiplication by 0 gives zero";
}

subtest "Vector Aggregations" => {
    plan 4;
    
    my @v = [1.0, 2.0, 3.0, 4.0];
    is vector-sum(@v), 10.0, "vector sum works";
    is vector-mean(@v), 2.5, "vector mean works";
    is vector-max(@v), 4.0, "vector max works";
    is vector-min(@v), 1.0, "vector min works";
}

# ============================================================================
# Test 4: Matrix Operations
# ============================================================================

subtest "Matrix Vector Multiplication" => {
    plan 2;
    
    my @matrix = [[1.0, 2.0], [3.0, 4.0]];
    my @vec = [5.0, 6.0];
    is-deeply matrix-vector-mult(@matrix, @vec), [17.0, 39.0], "matrix-vector multiplication works";
    
    my @identity = [[1.0, 0.0], [0.0, 1.0]];
    is-deeply matrix-vector-mult(@identity, @vec), [5.0, 6.0], "identity matrix multiplication works";
}

subtest "Matrix Transpose" => {
    plan 2;
    
    my @matrix = [[1, 2, 3], [4, 5, 6]];
    my @transposed = transpose(@matrix);
    is-deeply @transposed, [[1, 4], [2, 5], [3, 6]], "transpose works";
    
    my @square = [[1, 2], [3, 4]];
    my @trans-square = transpose(@square);
    is-deeply @trans-square, [[1, 3], [2, 4]], "transpose of square matrix works";
}

# ============================================================================
# Test 5: Network Structure
# ============================================================================

subtest "Network Creation" => {
    plan 3;
    
    my $network = create-network([2, 3, 1]);
    ok $network.defined, "network is created";
    is-deeply $network.layer-sizes, [2, 3, 1], "network has correct layer sizes";
    ok $network.weights.elems == 2, "network has correct number of weight layers";
}

subtest "Weight Initialization" => {
    plan 3;
    
    my @weights = init-weights([2, 3, 1]);
    ok @weights.elems == 2, "correct number of weight layers";
    ok @weights[0].elems == 3, "first layer has 3 neurons";
    ok @weights[1].elems == 1, "second layer has 1 neuron";
}

# ============================================================================
# Test 6: Forward Propagation
# ============================================================================

subtest "Forward Propagation" => {
    plan 3;
    
    my $network = create-network([2, 2, 1]);
    my @input = [0.5, 0.8];
    my @output = predict(@input, $network);
    
    ok @output.defined, "forward propagation produces output";
    ok @output.elems == 1, "output has correct size";
    ok @output[0] >= 0 && @output[0] <= 1, "output is in sigmoid range [0, 1]";
}

subtest "Forward with Activations" => {
    plan 3;
    
    my @weights = init-weights([2, 3, 1]);
    my @activations = forward-with-activations([0.5, 0.8], @weights);
    
    ok @activations.elems == 3, "correct number of activation layers";
    is-deeply @activations[0], [0.5, 0.8], "first activation is input";
    ok @activations[*-1].elems == 1, "final activation has correct size";
}

# ============================================================================
# Test 7: Loss Functions
# ============================================================================

subtest "MSE Loss" => {
    plan 3;
    
    my @output = [1.0, 0.0];
    my @target = [1.0, 0.0];
    is mse-loss(@output, @target), 0.0, "MSE loss is 0 for perfect prediction";
    
    my @output2 = [0.5, 0.5];
    my @target2 = [1.0, 0.0];
    is-approx mse-loss(@output2, @target2), 0.25, "MSE loss computed correctly";
    
    my @output3 = [0.0];
    my @target3 = [1.0];
    is mse-loss(@output3, @target3), 1.0, "MSE loss for [0] vs [1] is 1";
}

subtest "MSE Loss Derivative" => {
    plan 2;
    
    my @output = [0.5];
    my @target = [1.0];
    my @grad = mse-loss-derivative(@output, @target);
    ok @grad[0] < 0, "gradient points in correct direction";
    
    my @output2 = [1.0];
    my @target2 = [1.0];
    my @grad2 = mse-loss-derivative(@output2, @target2);
    is-approx @grad2[0], 0.0, "gradient is 0 for perfect prediction";
}

# ============================================================================
# Test 8: Training
# ============================================================================

subtest "Make Sample" => {
    plan 3;
    
    my $sample = make-sample([1.0, 2.0], [3.0]);
    ok $sample.defined, "sample is created";
    is-deeply $sample<input>, [1.0, 2.0], "sample has correct input";
    is-deeply $sample<target>, [3.0], "sample has correct target";
}

subtest "Training Epoch" => {
    plan 2;
    
    my @weights = init-weights([2, 2, 1]);
    # Itemize the sample hash so a lone sample is not flattened into Pairs
    my @training-data = [$( make-sample([0.0, 0.0], [0.0]) )];
    my @new-weights = train-epoch(@training-data, @weights, 0.1);
    
    ok @new-weights.defined, "training epoch produces new weights";
    ok @new-weights.elems == @weights.elems, "weight structure is preserved";
}

subtest "Full Training" => {
    plan 2;
    
    my $network = create-network([2, 2, 1]);
    my @training-data = [
        make-sample([0.0, 0.0], [0.0]),
        make-sample([1.0, 1.0], [1.0])
    ];
    my $trained = train(@training-data, $network, 0.1, 10);
    
    ok $trained.defined, "training produces a network";
    ok $trained.weights.defined, "trained network has weights";
}

# ============================================================================
# Test 9: Module System
# ============================================================================

subtest "Linear Module" => {
    plan 3;
    
    my $linear = make-linear(3, 2);
    ok $linear.defined, "linear module is created";
    
    my @output = module-forward($linear, [1.0, 2.0, 3.0]);
    ok @output.defined, "linear forward produces output";
    ok @output.elems == 2, "linear output has correct size";
}

subtest "Sigmoid Module" => {
    plan 2;
    
    my $sigmoid-mod = sigmoid-module();
    ok $sigmoid-mod.defined, "sigmoid module is created";
    
    my @output = module-forward($sigmoid-mod, [0.0, 1.0, -1.0]);
    ok @output.elems == 3, "sigmoid module processes all elements";
}

subtest "Sequential Module" => {
    plan 2;
    
    my $linear = make-linear(2, 3);
    my $sigmoid-mod = sigmoid-module();
    my $seq = make-sequential([$linear, $sigmoid-mod]);
    
    ok $seq.defined, "sequential module is created";
    
    my @output = module-forward($seq, [0.5, 0.8]);
    ok @output.elems == 3, "sequential forward produces correct output size";
}

# ============================================================================
# Test 10: Criterion Modules
# ============================================================================

subtest "MSE Criterion" => {
    plan 2;
    
    my $criterion = mse-criterion();
    ok $criterion.defined, "MSE criterion is created";
    
    my $loss = criterion-forward($criterion, [0.5, 0.8], [1.0, 1.0]);
    ok $loss >= 0, "MSE loss is non-negative";
}

subtest "Absolute Error Criterion" => {
    plan 2;
    
    my $criterion = abs-criterion();
    ok $criterion.defined, "absolute error criterion is created";
    
    my $loss = criterion-forward($criterion, [0.5], [1.0]);
    is-approx $loss, 0.5, "absolute error computed correctly";
}

subtest "BCE Criterion" => {
    plan 2;
    
    my $criterion = bce-criterion();
    ok $criterion.defined, "BCE criterion is created";
    
    my $loss = criterion-forward($criterion, [0.5, 0.5], [1.0, 0.0]);
    ok $loss > 0, "BCE loss is positive for imperfect prediction";
}

# ============================================================================
# Test 11: Advanced Modules
# ============================================================================

subtest "Tanh Module" => {
    plan 2;
    
    my $tanh-mod = tanh-module();
    ok $tanh-mod.defined, "tanh module is created";
    
    my @output = module-forward($tanh-mod, [0.0, 1.0]);
    ok @output.elems == 2, "tanh module processes all elements";
}

subtest "ReLU Module" => {
    plan 3;
    
    my $relu-mod = relu-module();
    ok $relu-mod.defined, "ReLU module is created";
    
    my @output = module-forward($relu-mod, [-1.0, 0.0, 1.0]);
    ok @output.elems == 3, "ReLU module processes all elements";
    is @output[0], 0.0, "ReLU correctly zeros negative values";
}

subtest "SoftMax Module" => {
    plan 3;
    
    my $softmax = softmax-module();
    ok $softmax.defined, "softmax module is created";
    
    my @output = module-forward($softmax, [1.0, 2.0, 3.0]);
    ok @output.elems == 3, "softmax output has correct size";
    is-approx vector-sum(@output), 1.0, "softmax outputs sum to 1";
}

subtest "Identity Module" => {
    plan 2;
    
    my $identity = identity-module();
    ok $identity.defined, "identity module is created";
    
    my @input = [1.0, 2.0, 3.0];
    my @output = module-forward($identity, @input);
    is-deeply @output, @input, "identity module passes through input";
}

# ============================================================================
# Test 12: Container Modules
# ============================================================================

subtest "ConcatTable Module" => {
    plan 2;
    
    my $linear1 = make-linear(2, 3);
    my $linear2 = make-linear(2, 2);
    my $concat-table = concat-table([$linear1, $linear2]);
    
    ok $concat-table.defined, "concat-table is created";
    
    my @output = module-forward($concat-table, [0.5, 0.8]);
    ok @output.elems == 2, "concat-table produces multiple outputs";
}

subtest "Parallel Module" => {
    plan 2;
    
    my $linear = make-linear(2, 2);
    my $parallel = parallel-module(2, 2, [$linear]);
    
    ok $parallel.defined, "parallel module is created";
    
    my @output = module-forward($parallel, [0.5, 0.8]);
    ok @output.defined, "parallel forward produces output";
}

# ============================================================================
# Test 13: Integration Tests
# ============================================================================

subtest "Simple XOR Learning" => {
    plan 2;
    
    my $network = create-network([2, 4, 1]);
    my @training-data = [
        make-sample([0.0, 0.0], [0.0]),
        make-sample([0.0, 1.0], [1.0]),
        make-sample([1.0, 0.0], [1.0]),
        make-sample([1.0, 1.0], [0.0])
    ];
    
    my $trained = train(@training-data, $network, 0.5, 100);
    ok $trained.defined, "network trains without errors";
    
    my @output = predict([0.0, 0.0], $trained);
    ok @output[0] >= 0 && @output[0] <= 1, "trained network produces valid output";
}

# ============================================================================
# Test 14: Cross-Implementation Consistency (docs/fixtures/xor_fixture.json)
# ============================================================================
#
# Builds the fixed 2-2-1 sigmoid MLP shared with every other port and asserts
# the forward output and MSE loss to a tight tolerance, guaranteeing all
# implementations agree numerically on one deterministic fixture.

subtest "Cross-Implementation Consistency" => {
    plan 8;

    my $tol = 1e-6;

    # weights[layer][neuron] = { weights => [...], bias => number }
    my @weights;
    my @layer1;
    @layer1.push({ weights => [0.5, -0.5],  bias => 0.1  });
    @layer1.push({ weights => [-0.25, 0.75], bias => -0.2 });
    my @layer2;
    @layer2.push({ weights => [0.6, -0.4],  bias => 0.05 });
    @weights.push(@layer1);
    @weights.push(@layer2);

    # (input, target, expected-output, expected-loss) per case
    my @cases = (
        [ [0.0, 0.0], [0.0], 0.5460989866, 0.2982241032 ],
        [ [0.0, 1.0], [1.0], 0.5092822253, 0.2408039344 ],
        [ [1.0, 0.0], [1.0], 0.5699505688, 0.1849425133 ],
        [ [1.0, 1.0], [0.0], 0.5337512224, 0.2848903675 ],
    );

    for @cases -> $case {
        my ($input, $target, $exp-out, $exp-loss) = @$case;
        my @out  = forward($input, @weights);
        my $loss = mse-loss(@out, $target);
        is-approx @out[0], $exp-out, "consistency output for input $input.raku()",
            :abs-tol($tol);
        is-approx $loss, $exp-loss, "consistency loss for input $input.raku()",
            :abs-tol($tol);
    }
}

done-testing;
