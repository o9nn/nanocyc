%% Neural Network Implementation in Pure Prolog
%% A minimal, pure Prolog implementation of feedforward neural networks
%% with backpropagation training.
%%
%% Note: Some utility predicates (derivative functions, scalar_mult_vector)
%% are defined but not exported. They are available for internal use and
%% for users who want to extend the module. The module currently uses
%% sigmoid activation in backpropagation, but tanh and relu are provided
%% for forward propagation and can be integrated if needed.

:- module(nn, [
    % Network creation and structure
    create_network/3,
    init_weights/2,
    
    % Forward propagation
    forward/3,
    sigmoid/2,
    tanh_activation/2,
    relu/2,
    
    % Backpropagation and training
    train/5,
    backprop/5,
    
    % Utilities
    dot_product/3,
    matrix_vector_mult/3,
    add_vectors/3,
    mse_loss/3,
    
    % Prediction
    predict/3,
    
    % Module-based architecture
    module_forward/3,
    module_backward/4,
    
    % Container modules
    sequential/1,
    sequential_add/3,
    sequential_forward/3,
    concat/2,
    concat_forward/3,
    
    % Transfer/Activation modules
    sigmoid_module/1,
    tanh_module/1,
    relu_module/1,
    log_softmax_module/1,
    softmax_module/1,
    
    % Criterion modules
    mse_criterion/1,
    class_nll_criterion/1,
    bce_criterion/1,
    abs_criterion/1,
    criterion_forward/4,
    criterion_backward/4,
    
    % Simple layer modules
    linear_module/3,
    reshape_module/2,
    mean_module/2,
    max_module/2,
    identity_module/1
]).

%% ============================================================================
%% Network Structure
%% ============================================================================

%% create_network(+LayerSizes, -Network, -NetworkWeights)
%% Creates a neural network structure with the specified layer sizes.
%% LayerSizes: list of integers [InputSize, Hidden1, Hidden2, ..., OutputSize]
%% Network: structure network(Layers, Weights)
%% NetworkWeights: initial random weights
create_network(LayerSizes, network(LayerSizes, Weights), Weights) :-
    init_weights(LayerSizes, Weights).

%% init_weights(+LayerSizes, -Weights)
%% Initialize random weights for all layers.
%% Weights are represented as a list of layer weight matrices.
init_weights([_], []) :- !.
init_weights([InputSize, OutputSize | Rest], [LayerWeights | RestWeights]) :-
    init_layer_weights(InputSize, OutputSize, LayerWeights),
    init_weights([OutputSize | Rest], RestWeights).

%% init_layer_weights(+InputSize, +OutputSize, -LayerWeights)
%% Initialize weights for a single layer.
%% LayerWeights: list of [Weights, Bias] for each neuron
init_layer_weights(InputSize, OutputSize, LayerWeights) :-
    length(LayerWeights, OutputSize),
    maplist(init_neuron_weights(InputSize), LayerWeights).

%% init_neuron_weights(+InputSize, -NeuronWeights)
%% Initialize weights for a single neuron.
init_neuron_weights(InputSize, neuron(Weights, Bias)) :-
    length(Weights, InputSize),
    maplist(random_weight, Weights),
    random_weight(Bias).

%% random_weight(-Weight)
%% Generate a random weight between -1 and 1.
random_weight(W) :-
    random(R),
    W is (R * 2.0) - 1.0.

%% ============================================================================
%% Activation Functions
%% ============================================================================

%% sigmoid(+X, -Y)
%% Sigmoid activation function: y = 1 / (1 + e^(-x))
sigmoid(X, Y) :-
    Y is 1.0 / (1.0 + exp(-X)).

%% sigmoid_derivative(+Y, -Derivative)
%% Derivative of sigmoid: y * (1 - y)
sigmoid_derivative(Y, D) :-
    D is Y * (1.0 - Y).

%% tanh_activation(+X, -Y)
%% Hyperbolic tangent activation function
tanh_activation(X, Y) :-
    Y is tanh(X).

%% tanh_derivative(+Y, -Derivative)
%% Derivative of tanh: 1 - y^2
tanh_derivative(Y, D) :-
    D is 1.0 - (Y * Y).

%% relu(+X, -Y)
%% ReLU activation function: y = max(0, x)
relu(X, Y) :-
    (X > 0 -> Y = X ; Y = 0).

%% relu_derivative(+X, -Derivative)
%% Derivative of ReLU
relu_derivative(X, D) :-
    (X > 0 -> D = 1 ; D = 0).

%% ============================================================================
%% Vector and Matrix Operations
%% ============================================================================

%% dot_product(+Vector1, +Vector2, -Result)
%% Compute dot product of two vectors
dot_product([], [], 0).
dot_product([X|Xs], [Y|Ys], Result) :-
    dot_product(Xs, Ys, Rest),
    Result is Rest + (X * Y).

%% add_vectors(+Vector1, +Vector2, -Result)
%% Element-wise addition of two vectors
add_vectors([], [], []).
add_vectors([X|Xs], [Y|Ys], [Z|Zs]) :-
    Z is X + Y,
    add_vectors(Xs, Ys, Zs).

%% scalar_mult_vector(+Scalar, +Vector, -Result)
%% Multiply vector by scalar
scalar_mult_vector(_, [], []).
scalar_mult_vector(S, [X|Xs], [Y|Ys]) :-
    Y is S * X,
    scalar_mult_vector(S, Xs, Ys).

%% matrix_vector_mult(+Matrix, +Vector, -Result)
%% Multiply matrix by vector (list of dot products)
matrix_vector_mult([], _, []).
matrix_vector_mult([Row|Rows], Vector, [Result|Results]) :-
    dot_product(Row, Vector, Result),
    matrix_vector_mult(Rows, Vector, Results).

%% ============================================================================
%% Forward Propagation
%% ============================================================================

%% forward(+Input, +Network, -Output)
%% Perform forward propagation through the network
forward(Input, network(_, Weights), Output) :-
    forward_layers(Input, Weights, _, Output).

%% forward_layers(+Input, +Weights, -Activations, -Output)
%% Forward propagation through all layers, keeping track of activations
forward_layers(Input, [], [Input], Input).
forward_layers(Input, [LayerWeights|RestWeights], [Input|RestActivations], Output) :-
    forward_layer(Input, LayerWeights, LayerOutput),
    forward_layers(LayerOutput, RestWeights, RestActivations, Output).

%% forward_layer(+Input, +LayerWeights, -Output)
%% Forward propagation through a single layer
forward_layer(Input, LayerWeights, Output) :-
    maplist(forward_neuron(Input), LayerWeights, Output).

%% forward_neuron(+Input, +NeuronWeights, -Output)
%% Compute output of a single neuron with sigmoid activation
forward_neuron(Input, neuron(Weights, Bias), Output) :-
    dot_product(Weights, Input, WeightedSum),
    PreActivation is WeightedSum + Bias,
    sigmoid(PreActivation, Output).

%% ============================================================================
%% Loss Functions
%% ============================================================================

%% mse_loss(+Predicted, +Target, -Loss)
%% Mean squared error loss
mse_loss(Predicted, Target, Loss) :-
    squared_errors(Predicted, Target, Errors),
    sum_list(Errors, Sum),
    length(Errors, N),
    Loss is Sum / N.

%% squared_errors(+Predicted, +Target, -Errors)
squared_errors([], [], []).
squared_errors([P|Ps], [T|Ts], [E|Es]) :-
    E is (P - T) * (P - T),
    squared_errors(Ps, Ts, Es).

%% ============================================================================
%% Backpropagation
%% ============================================================================

%% backprop(+Input, +Target, +Network, +LearningRate, -UpdatedNetwork)
%% Perform backpropagation and update weights
backprop(Input, Target, network(Layers, Weights), LearningRate, network(Layers, UpdatedWeights)) :-
    % Forward pass with activations
    forward_with_activations(Input, Weights, Activations, Output),
    
    % Calculate output error
    subtract_vectors(Output, Target, OutputError),
    
    % Backward pass
    reverse(Weights, RevWeights),
    reverse(Activations, RevActivations),
    backward_layers(RevWeights, RevActivations, OutputError, [], WeightGradients),
    
    % Update weights
    update_weights(Weights, WeightGradients, LearningRate, UpdatedWeights).

%% forward_with_activations(+Input, +Weights, -Activations, -Output)
forward_with_activations(Input, Weights, Activations, Output) :-
    forward_layers(Input, Weights, Activations, Output).

%% backward_layers(+RevWeights, +RevActivations, +Error, +AccGrad, -Gradients)
backward_layers([], _, _, Gradients, Gradients).
backward_layers([LayerWeights|RestWeights], [CurrentAct, PrevAct|RestActs], Error, AccGrad, Gradients) :-
    % Compute gradients for current layer
    compute_layer_gradients(LayerWeights, PrevAct, CurrentAct, Error, LayerGrad, PropError),
    
    % Recursively process previous layers
    backward_layers(RestWeights, [PrevAct|RestActs], PropError, [LayerGrad|AccGrad], Gradients).
backward_layers([LayerWeights|_], [CurrentAct], Error, AccGrad, [LayerGrad|AccGrad]) :-
    % Base case: first layer (use CurrentAct as input since there's no previous layer)
    compute_layer_gradients_first(LayerWeights, CurrentAct, Error, LayerGrad).

%% compute_layer_gradients(+LayerWeights, +Input, +Output, +Error, -LayerGrad, -PropagatedError)
compute_layer_gradients(LayerWeights, Input, Output, Error, LayerGrad, PropError) :-
    % Compute gradient for each neuron with corresponding output and error
    compute_neuron_gradients(LayerWeights, Input, Output, Error, LayerGrad),
    propagate_error(LayerWeights, Error, PropError).

%% compute_layer_gradients_first(+LayerWeights, +Output, +Error, -LayerGrad)
compute_layer_gradients_first(LayerWeights, Output, Error, LayerGrad) :-
    compute_neuron_gradients(LayerWeights, [], Output, Error, LayerGrad).

%% compute_neuron_gradients(+Neurons, +Input, +Outputs, +Errors, -Gradients)
compute_neuron_gradients([], _, [], [], []).
compute_neuron_gradients([neuron(_Weights, _Bias)|RestNeurons], Input, [O|RestOut], [E|RestErr], [gradient(WeightGrads, BiasGrad)|RestGrad]) :-
    sigmoid_derivative(O, Derivative),
    Delta is E * Derivative,
    (Input = [] -> WeightGrads = [] ; maplist(mult_delta(Delta), Input, WeightGrads)),
    BiasGrad = Delta,
    compute_neuron_gradients(RestNeurons, Input, RestOut, RestErr, RestGrad).

%% mult_delta(+Delta, +Input, -Gradient)
mult_delta(Delta, Input, Grad) :-
    Grad is Delta * Input.

%% propagate_error(+LayerWeights, +Error, -PropagatedError)
propagate_error(LayerWeights, Error, PropError) :-
    extract_weights(LayerWeights, WeightMatrix),
    transpose_multiply(WeightMatrix, Error, PropError).

%% extract_weights(+NeuronWeights, -WeightMatrix)
extract_weights([], []).
extract_weights([neuron(Weights, _)|Rest], [Weights|RestWeights]) :-
    extract_weights(Rest, RestWeights).

%% transpose_multiply(+Matrix, +Vector, -Result)
transpose_multiply(Matrix, Vector, Result) :-
    transpose(Matrix, Transposed),
    matrix_vector_mult(Transposed, Vector, Result).

%% transpose(+Matrix, -Transposed)
transpose([[]|_], []).
transpose(Matrix, [Row|Rows]) :-
    maplist(nth0(0), Matrix, Row),
    maplist(list_tail, Matrix, RestMatrix),
    transpose(RestMatrix, Rows).

list_tail([_|T], T).

%% subtract_vectors(+V1, +V2, -Result)
subtract_vectors([], [], []).
subtract_vectors([X|Xs], [Y|Ys], [Z|Zs]) :-
    Z is X - Y,
    subtract_vectors(Xs, Ys, Zs).

%% update_weights(+Weights, +Gradients, +LearningRate, -UpdatedWeights)
update_weights([], [], _, []).
update_weights([LayerW|RestW], [LayerG|RestG], LR, [UpdatedLayer|UpdatedRest]) :-
    update_layer_weights(LayerW, LayerG, LR, UpdatedLayer),
    update_weights(RestW, RestG, LR, UpdatedRest).

%% update_layer_weights(+LayerWeights, +LayerGradients, +LR, -UpdatedWeights)
update_layer_weights([], [], _, []).
update_layer_weights([neuron(W, B)|Rest], [gradient(GW, GB)|RestG], LR, [neuron(NewW, NewB)|UpdatedRest]) :-
    update_vector(W, GW, LR, NewW),
    NewB is B - (LR * GB),
    update_layer_weights(Rest, RestG, LR, UpdatedRest).

%% update_vector(+Weights, +Gradients, +LR, -UpdatedWeights)
update_vector([], [], _, []).
update_vector([W|Ws], [G|Gs], LR, [NewW|NewWs]) :-
    NewW is W - (LR * G),
    update_vector(Ws, Gs, LR, NewWs).

%% ============================================================================
%% Training
%% ============================================================================

%% train(+TrainingData, +Network, +LearningRate, +Epochs, -TrainedNetwork)
%% Train network on dataset for specified epochs
train(_, Network, _, 0, Network) :- !.
train(TrainingData, Network, LearningRate, Epochs, TrainedNetwork) :-
    Epochs > 0,
    train_epoch(TrainingData, Network, LearningRate, UpdatedNetwork),
    NewEpochs is Epochs - 1,
    train(TrainingData, UpdatedNetwork, LearningRate, NewEpochs, TrainedNetwork).

%% train_epoch(+TrainingData, +Network, +LearningRate, -UpdatedNetwork)
%% Train network on all samples in one epoch
train_epoch([], Network, _, Network).
train_epoch([sample(Input, Target)|Rest], Network, LearningRate, UpdatedNetwork) :-
    backprop(Input, Target, Network, LearningRate, IntermediateNetwork),
    train_epoch(Rest, IntermediateNetwork, LearningRate, UpdatedNetwork).

%% ============================================================================
%% Prediction
%% ============================================================================

%% predict(+Input, +Network, -Output)
%% Make a prediction using the trained network
predict(Input, Network, Output) :-
    forward(Input, Network, Output).

%% ============================================================================
%% Example Usage and Tests
%% ============================================================================

%% Example: XOR problem
example_xor :-
    % Create network: 2 inputs, 2 hidden neurons, 1 output
    create_network([2, 2, 1], Network, _),
    
    % Training data for XOR
    TrainingData = [
        sample([0, 0], [0]),
        sample([0, 1], [1]),
        sample([1, 0], [1]),
        sample([1, 1], [0])
    ],
    
    % Train network
    format('Training XOR network...~n'),
    train(TrainingData, Network, 0.5, 1000, TrainedNetwork),
    
    % Test predictions
    format('Testing predictions:~n'),
    predict([0, 0], TrainedNetwork, Out1),
    format('  [0, 0] -> ~w~n', [Out1]),
    predict([0, 1], TrainedNetwork, Out2),
    format('  [0, 1] -> ~w~n', [Out2]),
    predict([1, 0], TrainedNetwork, Out3),
    format('  [1, 0] -> ~w~n', [Out3]),
    predict([1, 1], TrainedNetwork, Out4),
    format('  [1, 1] -> ~w~n', [Out4]).

%% Example: Simple regression
example_regression :-
    % Create network: 1 input, 3 hidden neurons, 1 output
    create_network([1, 3, 1], Network, _),
    
    % Training data: approximate f(x) = x^2
    TrainingData = [
        sample([0.0], [0.0]),
        sample([0.5], [0.25]),
        sample([1.0], [1.0]),
        sample([1.5], [2.25]),
        sample([2.0], [4.0])
    ],
    
    % Train network
    format('Training regression network...~n'),
    train(TrainingData, Network, 0.1, 2000, TrainedNetwork),
    
    % Test predictions
    format('Testing predictions:~n'),
    predict([0.0], TrainedNetwork, P1),
    format('  f(0.0) = ~w (expected: 0.0)~n', [P1]),
    predict([1.0], TrainedNetwork, P2),
    format('  f(1.0) = ~w (expected: 1.0)~n', [P2]),
    predict([1.5], TrainedNetwork, P3),
    format('  f(1.5) = ~w (expected: 2.25)~n', [P3]).

%% Run all examples
run_examples :-
    format('~n=== Neural Network Examples ===~n~n'),
    example_xor,
    format('~n'),
    example_regression.

%% ============================================================================
%% Module-Based Architecture
%% ============================================================================
%% This section implements a more modular architecture similar to Torch's nn
%% where each component (layer, activation, criterion) is a standalone module
%% that can be composed together.

%% module_forward(+Module, +Input, -Output)
%% Generic forward pass for any module type
module_forward(Module, Input, Output) :-
    Module =.. [Type|Args],
    module_forward_dispatch(Type, Args, Input, Output).

%% module_forward_dispatch(+Type, +Args, +Input, -Output)
module_forward_dispatch(sequential, [Modules], Input, Output) :-
    sequential_forward_impl(Modules, Input, Output).
module_forward_dispatch(linear, [Weights, Bias], Input, Output) :-
    linear_forward(Weights, Bias, Input, Output).
module_forward_dispatch(sigmoid, [], Input, Output) :-
    maplist(sigmoid, Input, Output).
module_forward_dispatch(tanh, [], Input, Output) :-
    maplist(tanh_activation, Input, Output).
module_forward_dispatch(relu, [], Input, Output) :-
    maplist(relu, Input, Output).
module_forward_dispatch(softmax, [], Input, Output) :-
    softmax_forward(Input, Output).
module_forward_dispatch(log_softmax, [], Input, Output) :-
    log_softmax_forward(Input, Output).
module_forward_dispatch(reshape, [Shape], Input, Output) :-
    reshape_forward(Shape, Input, Output).
module_forward_dispatch(mean, [Dim], Input, Output) :-
    mean_forward(Dim, Input, Output).
module_forward_dispatch(max, [Dim], Input, Output) :-
    max_forward(Dim, Input, Output).
module_forward_dispatch(identity, [], Input, Input).
module_forward_dispatch(concat, [Dim, Modules], Input, Output) :-
    concat_forward_impl(Dim, Modules, Input, Output).

%% module_backward(+Module, +Input, +GradOutput, -GradInput)
%% Generic backward pass for any module type
module_backward(Module, Input, GradOutput, GradInput) :-
    Module =.. [Type|Args],
    module_backward_dispatch(Type, Args, Input, GradOutput, GradInput).

module_backward_dispatch(identity, [], _, GradOutput, GradOutput).
% More backward implementations can be added as needed

%% ============================================================================
%% Container Modules
%% ============================================================================

%% sequential(+Modules)
%% Creates a Sequential container that chains modules together
sequential(Modules) :- 
    is_list(Modules).

%% sequential_add(+Sequential, +Module, -NewSequential)
%% Adds a module to a sequential container
sequential_add(Modules, Module, [Module|Modules]) :-
    is_list(Modules).

%% sequential_forward(+Modules, +Input, -Output)
%% Forward pass through a sequential container
sequential_forward(sequential(Modules), Input, Output) :-
    sequential_forward_impl(Modules, Input, Output).

sequential_forward_impl([], Output, Output).
sequential_forward_impl([Module|Rest], Input, Output) :-
    module_forward(Module, Input, Intermediate),
    sequential_forward_impl(Rest, Intermediate, Output).

%% concat(+Dim, +Modules)
%% Creates a Concat container that concatenates outputs along a dimension
concat(Dim, Modules) :-
    integer(Dim),
    is_list(Modules).

%% concat_forward(+ConcatModule, +Input, -Output)
%% Forward pass through concat container
concat_forward(concat(Dim, Modules), Input, Output) :-
    concat_forward_impl(Dim, Modules, Input, Output).

concat_forward_impl(_, [], _, []).
concat_forward_impl(Dim, [Module|Rest], Input, Output) :-
    module_forward(Module, Input, ModuleOutput),
    concat_forward_impl(Dim, Rest, Input, RestOutput),
    (Dim =:= 1 -> append(ModuleOutput, RestOutput, Output) ; 
     Output = [ModuleOutput|RestOutput]).

%% ============================================================================
%% Transfer/Activation Modules
%% ============================================================================

%% sigmoid_module(-Module)
%% Creates a Sigmoid activation module
sigmoid_module(sigmoid).

%% tanh_module(-Module)
%% Creates a Tanh activation module
tanh_module(tanh).

%% relu_module(-Module)
%% Creates a ReLU activation module
relu_module(relu).

%% softmax_module(-Module)
%% Creates a SoftMax activation module
softmax_module(softmax).

%% softmax_forward(+Input, -Output)
%% SoftMax: exp(x_i) / sum(exp(x_j))
softmax_forward(Input, Output) :-
    max_list(Input, MaxVal),
    maplist(subtract_scalar(MaxVal), Input, Shifted),
    maplist(exp_scalar, Shifted, Exps),
    sum_list(Exps, SumExp),
    maplist(divide_by(SumExp), Exps, Output).

exp_scalar(X, Y) :- Y is exp(X).
subtract_scalar(Scalar, X, Y) :- Y is X - Scalar.
divide_by(Divisor, X, Y) :- Y is X / Divisor.

%% log_softmax_module(-Module)
%% Creates a LogSoftMax activation module
log_softmax_module(log_softmax).

%% log_softmax_forward(+Input, -Output)
%% LogSoftMax: log(exp(x_i) / sum(exp(x_j))) = x_i - log(sum(exp(x_j)))
log_softmax_forward(Input, Output) :-
    max_list(Input, MaxVal),
    maplist(subtract_scalar(MaxVal), Input, Shifted),
    maplist(exp_scalar, Shifted, Exps),
    sum_list(Exps, SumExp),
    LogSumExp is log(SumExp) + MaxVal,
    maplist(subtract_scalar(LogSumExp), Input, Output).

%% ============================================================================
%% Criterion/Loss Modules
%% ============================================================================

%% mse_criterion(-Criterion)
%% Creates an MSE (Mean Squared Error) criterion
mse_criterion(mse_criterion).

%% class_nll_criterion(-Criterion)
%% Creates a ClassNLLCriterion (Negative Log Likelihood for classification)
class_nll_criterion(class_nll_criterion).

%% bce_criterion(-Criterion)
%% Creates a BCE (Binary Cross Entropy) criterion
bce_criterion(bce_criterion).

%% abs_criterion(-Criterion)
%% Creates an Absolute Error (L1) criterion
abs_criterion(abs_criterion).

%% criterion_forward(+Criterion, +Input, +Target, -Loss)
%% Compute loss for a given criterion
criterion_forward(mse_criterion, Input, Target, Loss) :-
    mse_loss(Input, Target, Loss).
criterion_forward(class_nll_criterion, Input, Target, Loss) :-
    class_nll_loss(Input, Target, Loss).
criterion_forward(bce_criterion, Input, Target, Loss) :-
    bce_loss(Input, Target, Loss).
criterion_forward(abs_criterion, Input, Target, Loss) :-
    abs_loss(Input, Target, Loss).

%% criterion_backward(+Criterion, +Input, +Target, -GradInput)
%% Compute gradient for a given criterion
criterion_backward(mse_criterion, Input, Target, GradInput) :-
    subtract_vectors(Input, Target, Diff),
    length(Input, N),
    Scalar is 2.0 / N,
    scalar_mult_vector(Scalar, Diff, GradInput).
criterion_backward(class_nll_criterion, Input, Target, GradInput) :-
    class_nll_gradient(Input, Target, GradInput).
criterion_backward(bce_criterion, Input, Target, GradInput) :-
    bce_gradient(Input, Target, GradInput).
criterion_backward(abs_criterion, Input, Target, GradInput) :-
    abs_gradient(Input, Target, GradInput).

%% class_nll_loss(+LogProbs, +Target, -Loss)
%% Negative log likelihood loss for classification
%% Input: log probabilities, Target: class index (0-based)
class_nll_loss(LogProbs, Target, Loss) :-
    nth0(Target, LogProbs, LogProb),
    Loss is -LogProb.

%% class_nll_gradient(+LogProbs, +Target, -Gradient)
class_nll_gradient(LogProbs, Target, Gradient) :-
    length(LogProbs, N),
    length(Gradient, N),
    create_zero_list(N, Zeros),
    replace_at_index(Zeros, Target, -1.0, Gradient).

%% Helper to create a list of zeros
create_zero_list(0, []).
create_zero_list(N, [0.0|Rest]) :-
    N > 0,
    N1 is N - 1,
    create_zero_list(N1, Rest).

%% Helper to replace element at index
replace_at_index([_|T], 0, Value, [Value|T]).
replace_at_index([H|T], Index, Value, [H|Rest]) :-
    Index > 0,
    Index1 is Index - 1,
    replace_at_index(T, Index1, Value, Rest).

%% bce_loss(+Predicted, +Target, -Loss)
%% Binary cross entropy: -[t*log(p) + (1-t)*log(1-p)]
bce_loss(Predicted, Target, Loss) :-
    bce_elements(Predicted, Target, Losses),
    sum_list(Losses, Sum),
    length(Losses, N),
    Loss is Sum / N.

bce_elements([], [], []).
bce_elements([P|Ps], [T|Ts], [L|Ls]) :-
    Epsilon is 1e-7,
    P_clipped is max(Epsilon, min(1.0 - Epsilon, P)),
    L is -(T * log(P_clipped) + (1.0 - T) * log(1.0 - P_clipped)),
    bce_elements(Ps, Ts, Ls).

%% bce_gradient(+Predicted, +Target, -Gradient)
bce_gradient([], [], []).
bce_gradient([P|Ps], [T|Ts], [G|Gs]) :-
    Epsilon is 1e-7,
    P_clipped is max(Epsilon, min(1.0 - Epsilon, P)),
    G is (P_clipped - T) / (P_clipped * (1.0 - P_clipped)),
    bce_gradient(Ps, Ts, Gs).

%% abs_loss(+Predicted, +Target, -Loss)
%% Mean absolute error (L1 loss)
abs_loss(Predicted, Target, Loss) :-
    abs_errors(Predicted, Target, Errors),
    sum_list(Errors, Sum),
    length(Errors, N),
    Loss is Sum / N.

abs_errors([], [], []).
abs_errors([P|Ps], [T|Ts], [E|Es]) :-
    E is abs(P - T),
    abs_errors(Ps, Ts, Es).

%% abs_gradient(+Predicted, +Target, -Gradient)
abs_gradient([], [], []).
abs_gradient([P|Ps], [T|Ts], [G|Gs]) :-
    (P > T -> G = 1.0 ; (P < T -> G = -1.0 ; G = 0.0)),
    abs_gradient(Ps, Ts, Gs).

%% ============================================================================
%% Simple Layer Modules
%% ============================================================================

%% linear_module(+InputSize, +OutputSize, -Module)
%% Creates a Linear transformation module
linear_module(InputSize, OutputSize, linear(Weights, Bias)) :-
    init_layer_weights(InputSize, OutputSize, NeuronWeights),
    extract_weights_and_biases(NeuronWeights, Weights, Bias).

extract_weights_and_biases([], [], []).
extract_weights_and_biases([neuron(W, B)|Rest], [W|Ws], [B|Bs]) :-
    extract_weights_and_biases(Rest, Ws, Bs).

%% linear_forward(+Weights, +Bias, +Input, -Output)
linear_forward(Weights, Bias, Input, Output) :-
    matrix_vector_mult(Weights, Input, WeightedSum),
    add_vectors(WeightedSum, Bias, Output).

%% reshape_module(+Shape, -Module)
%% Creates a Reshape module
reshape_module(Shape, reshape(Shape)).

%% reshape_forward(+Shape, +Input, -Output)
reshape_forward(Shape, Input, Output) :-
    flatten(Input, Flat),
    reshape_to_shape(Flat, Shape, Output).

reshape_to_shape(Flat, [], Flat) :- !.
reshape_to_shape(Flat, [Dim], Flat) :- 
    length(Flat, Dim), !.
reshape_to_shape(Flat, [Dim|RestDims], Output) :-
    length(RestDims, NumDims),
    NumDims > 0,
    product(RestDims, RestProduct),
    split_list(Flat, RestProduct, Groups),
    length(Groups, Dim),
    maplist(reshape_to_shape_partial(RestDims), Groups, Output).

reshape_to_shape_partial(Shape, Input, Output) :-
    reshape_to_shape(Input, Shape, Output).

product([], 1).
product([X|Xs], P) :-
    product(Xs, P0),
    P is X * P0.

split_list([], _, []).
split_list(List, Size, [Chunk|Rest]) :-
    length(Chunk, Size),
    append(Chunk, Remainder, List),
    split_list(Remainder, Size, Rest).

%% mean_module(+Dim, -Module)
%% Creates a Mean reduction module
mean_module(Dim, mean(Dim)).

%% mean_forward(+Dim, +Input, -Output)
mean_forward(1, Input, Output) :-
    (is_list(Input), Input = [H|_], is_list(H) ->
        transpose(Input, Transposed),
        maplist(mean_list, Transposed, Output)
    ;
        mean_list(Input, Output)
    ).

mean_list(List, Mean) :-
    sum_list(List, Sum),
    length(List, N),
    Mean is Sum / N.

%% max_module(+Dim, -Module)
%% Creates a Max reduction module
max_module(Dim, max(Dim)).

%% max_forward(+Dim, +Input, -Output)
max_forward(1, Input, Output) :-
    (is_list(Input), Input = [H|_], is_list(H) ->
        transpose(Input, Transposed),
        maplist(max_list, Transposed, Output)
    ;
        max_list(Input, Output)
    ).

%% identity_module(-Module)
%% Creates an Identity module (passes input through unchanged)
identity_module(identity).
