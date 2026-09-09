%% Demo file for new modular architecture in nn.pl
%% Shows how to use the new module-based interface

:- consult('nn.pl').

%% ============================================================================
%% Demo 1: Building a Classification Network with Sequential
%% ============================================================================

demo_sequential_classification :-
    format('~n=== Demo: Sequential Classification Network ===~n~n'),
    
    % Build a network using Sequential container
    % Input: 2 features -> Hidden: 4 units -> Output: 3 classes
    nn:linear_module(2, 4, Linear1),
    nn:tanh_module(Tanh),
    nn:linear_module(4, 3, Linear2),
    nn:log_softmax_module(LogSoftMax),
    
    Network = sequential([Linear1, Tanh, Linear2, LogSoftMax]),
    
    % Test forward pass
    Input = [0.5, 0.8],
    nn:sequential_forward(Network, Input, Output),
    
    format('Input: ~w~n', [Input]),
    format('Log probabilities: ~w~n', [Output]),
    
    % Find predicted class (highest log probability)
    max_list(Output, MaxLogProb),
    nth0(PredictedClass, Output, MaxLogProb),
    format('Predicted class: ~w~n', [PredictedClass]),
    format('~nDemo completed successfully!~n').

%% ============================================================================
%% Demo 2: Using Different Activation Functions
%% ============================================================================

demo_activations :-
    format('~n=== Demo: Comparing Activation Functions ===~n~n'),
    
    TestInput = [-2, -1, 0, 1, 2],
    format('Input: ~w~n~n', [TestInput]),
    
    % Sigmoid
    nn:sigmoid_module(Sigmoid),
    nn:module_forward(Sigmoid, TestInput, SigmoidOut),
    format('Sigmoid output: ~w~n', [SigmoidOut]),
    
    % Tanh
    nn:tanh_module(Tanh),
    nn:module_forward(Tanh, TestInput, TanhOut),
    format('Tanh output: ~w~n', [TanhOut]),
    
    % ReLU
    nn:relu_module(ReLU),
    nn:module_forward(ReLU, TestInput, ReLUOut),
    format('ReLU output: ~w~n', [ReLUOut]),
    
    format('~nDemo completed successfully!~n').

%% ============================================================================
%% Demo 3: Using Loss Functions/Criterions
%% ============================================================================

demo_criterions :-
    format('~n=== Demo: Different Loss Functions ===~n~n'),
    
    % Example 1: MSE for regression
    format('Example 1: MSE Loss (Regression)~n'),
    Predicted1 = [1.5, 2.3, 3.1],
    Target1 = [1.0, 2.0, 3.0],
    nn:mse_criterion(MSE),
    nn:criterion_forward(MSE, Predicted1, Target1, MSELoss),
    format('  Predicted: ~w~n', [Predicted1]),
    format('  Target: ~w~n', [Target1]),
    format('  MSE Loss: ~w~n~n', [MSELoss]),
    
    % Example 2: ClassNLL for classification
    format('Example 2: ClassNLL Loss (Classification)~n'),
    LogProbs = [-0.5, -1.2, -2.3],  % Log probabilities for 3 classes
    TargetClass = 0,  % Correct class is 0
    nn:class_nll_criterion(NLL),
    nn:criterion_forward(NLL, LogProbs, TargetClass, NLLLoss),
    format('  Log Probabilities: ~w~n', [LogProbs]),
    format('  Target Class: ~w~n', [TargetClass]),
    format('  NLL Loss: ~w~n~n', [NLLLoss]),
    
    % Example 3: Binary Cross Entropy
    format('Example 3: BCE Loss (Binary Classification)~n'),
    Predicted3 = [0.8, 0.3, 0.9],
    Target3 = [1.0, 0.0, 1.0],
    nn:bce_criterion(BCE),
    nn:criterion_forward(BCE, Predicted3, Target3, BCELoss),
    format('  Predicted: ~w~n', [Predicted3]),
    format('  Target: ~w~n', [Target3]),
    format('  BCE Loss: ~w~n~n', [BCELoss]),
    
    % Example 4: Absolute Error
    format('Example 4: L1/Abs Loss~n'),
    Predicted4 = [1.5, 2.5],
    Target4 = [1.0, 3.0],
    nn:abs_criterion(Abs),
    nn:criterion_forward(Abs, Predicted4, Target4, AbsLoss),
    format('  Predicted: ~w~n', [Predicted4]),
    format('  Target: ~w~n', [Target4]),
    format('  L1 Loss: ~w~n~n', [AbsLoss]),
    
    format('Demo completed successfully!~n').

%% ============================================================================
%% Demo 4: Simple Layers
%% ============================================================================

demo_simple_layers :-
    format('~n=== Demo: Simple Layer Operations ===~n~n'),
    
    % Identity
    format('Identity Layer:~n'),
    nn:identity_module(Identity),
    Input1 = [1, 2, 3, 4],
    nn:module_forward(Identity, Input1, Output1),
    format('  Input: ~w~n', [Input1]),
    format('  Output: ~w~n~n', [Output1]),
    
    % Mean reduction
    format('Mean Layer:~n'),
    nn:mean_module(1, Mean),
    Input2 = [1, 2, 3, 4, 5],
    nn:module_forward(Mean, Input2, Output2),
    format('  Input: ~w~n', [Input2]),
    format('  Mean: ~w~n~n', [Output2]),
    
    % Max reduction
    format('Max Layer:~n'),
    nn:max_module(1, Max),
    Input3 = [1, 5, 3, 2, 4],
    nn:module_forward(Max, Input3, Output3),
    format('  Input: ~w~n', [Input3]),
    format('  Max: ~w~n~n', [Output3]),
    
    % Linear transformation
    format('Linear Layer:~n'),
    nn:linear_module(3, 2, Linear),
    Input4 = [1, 2, 3],
    nn:module_forward(Linear, Input4, Output4),
    format('  Input: ~w~n', [Input4]),
    format('  Output (2 units): ~w~n~n', [Output4]),
    
    format('Demo completed successfully!~n').

%% ============================================================================
%% Demo 5: SoftMax and LogSoftMax
%% ============================================================================

demo_softmax :-
    format('~n=== Demo: SoftMax vs LogSoftMax ===~n~n'),
    
    Logits = [2.0, 1.0, 0.1],
    format('Raw logits: ~w~n~n', [Logits]),
    
    % SoftMax
    nn:softmax_module(SoftMax),
    nn:module_forward(SoftMax, Logits, SoftMaxOut),
    format('SoftMax output (probabilities):~n'),
    format('  ~w~n', [SoftMaxOut]),
    sum_list(SoftMaxOut, Sum1),
    format('  Sum: ~w (should be 1.0)~n~n', [Sum1]),
    
    % LogSoftMax
    nn:log_softmax_module(LogSoftMax),
    nn:module_forward(LogSoftMax, Logits, LogSoftMaxOut),
    format('LogSoftMax output (log probabilities):~n'),
    format('  ~w~n', [LogSoftMaxOut]),
    format('  (All values should be negative)~n~n'),
    
    format('Demo completed successfully!~n').

%% ============================================================================
%% Demo 6: Building Complex Networks
%% ============================================================================

demo_complex_network :-
    format('~n=== Demo: Complex Multi-Layer Network ===~n~n'),
    
    % Build a deeper network
    nn:linear_module(5, 8, L1),
    nn:relu_module(R1),
    nn:linear_module(8, 6, L2),
    nn:tanh_module(T1),
    nn:linear_module(6, 4, L3),
    nn:relu_module(R2),
    nn:linear_module(4, 2, L4),
    nn:log_softmax_module(LS),
    
    DeepNetwork = sequential([L1, R1, L2, T1, L3, R2, L4, LS]),
    
    % Test forward pass
    Input = [0.1, 0.2, 0.3, 0.4, 0.5],
    format('Building network: 5 -> 8 -> 6 -> 4 -> 2~n'),
    format('Input (5 features): ~w~n', [Input]),
    
    nn:sequential_forward(DeepNetwork, Input, Output),
    format('Output (2 classes, log probs): ~w~n', [Output]),
    
    % Determine predicted class
    max_list(Output, MaxProb),
    nth0(Class, Output, MaxProb),
    format('Predicted class: ~w~n', [Class]),
    
    format('~nDemo completed successfully!~n').

%% ============================================================================
%% Demo 7: Using Concat
%% ============================================================================

demo_concat :-
    format('~n=== Demo: Concat Container ===~n~n'),
    
    % Create two parallel branches
    nn:identity_module(Branch1),
    nn:identity_module(Branch2),
    
    ConcatNet = concat(1, [Branch1, Branch2]),
    
    Input = [1, 2, 3],
    format('Input: ~w~n', [Input]),
    
    nn:concat_forward(ConcatNet, Input, Output),
    format('Concatenated output: ~w~n', [Output]),
    format('(Both branches see same input, outputs are concatenated)~n~n'),
    
    format('Demo completed successfully!~n').

%% ============================================================================
%% Run All Demos
%% ============================================================================

run_all_demos :-
    format('~n╔════════════════════════════════════════════════════════╗~n'),
    format('║     Neural Network Module Demonstrations (nn.pl)      ║~n'),
    format('╚════════════════════════════════════════════════════════╝~n'),
    
    demo_sequential_classification,
    demo_activations,
    demo_criterions,
    demo_simple_layers,
    demo_softmax,
    demo_complex_network,
    demo_concat,
    
    format('~n╔════════════════════════════════════════════════════════╗~n'),
    format('║            All Demos Completed Successfully!          ║~n'),
    format('╚════════════════════════════════════════════════════════╝~n~n').

%% Usage instructions
:- format('~n╔════════════════════════════════════════════════════════╗~n').
:- format('║     Neural Network Module Demonstrations (nn.pl)      ║~n').
:- format('╚════════════════════════════════════════════════════════╝~n~n').
:- format('Run individual demos:~n').
:- format('  ?- demo_sequential_classification.~n').
:- format('  ?- demo_activations.~n').
:- format('  ?- demo_criterions.~n').
:- format('  ?- demo_simple_layers.~n').
:- format('  ?- demo_softmax.~n').
:- format('  ?- demo_complex_network.~n').
:- format('  ?- demo_concat.~n~n').
:- format('Run all demos:~n').
:- format('  ?- run_all_demos.~n~n').
:- format('Or from command line:~n').
:- format('  swipl -l demo_modules.pl -g "run_all_demos" -t halt~n~n').
