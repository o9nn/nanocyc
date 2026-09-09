%% Test file for new modular architecture in nn.pl
%% Run with: swipl -q -l test_modules.pl -g run_module_tests -t halt

:- consult('nn.pl').

%% ============================================================================
%% Container Module Tests
%% ============================================================================

test_sequential :-
    format('Test: Sequential container...~n'),
    % Create a simple sequential network
    nn:sigmoid_module(Sigmoid),
    nn:linear_module(2, 3, Linear1),
    nn:linear_module(3, 1, Linear2),
    Sequential = sequential([Linear1, Sigmoid, Linear2]),
    
    % Test forward pass
    Input = [0.5, 0.8],
    nn:sequential_forward(Sequential, Input, Output),
    length(Output, 1),
    format('  PASSED: Sequential forward pass works~n').

test_concat :-
    format('Test: Concat container...~n'),
    nn:identity_module(Identity1),
    nn:identity_module(Identity2),
    Concat = concat(1, [Identity1, Identity2]),
    
    Input = [1, 2, 3],
    nn:concat_forward(Concat, Input, Output),
    length(Output, 6),  % Should concatenate the outputs
    format('  PASSED: Concat forward pass works~n').

%% ============================================================================
%% Activation Module Tests
%% ============================================================================

test_sigmoid_module :-
    format('Test: Sigmoid module...~n'),
    nn:sigmoid_module(Sigmoid),
    Input = [0, 1, -1],
    nn:module_forward(Sigmoid, Input, Output),
    length(Output, 3),
    Output = [Y0, Y1, Y2],
    (Y0 > 0.49, Y0 < 0.51 -> true ; format('  FAILED: sigmoid(0)~n'), fail),
    (Y1 > 0.7, Y1 < 0.8 -> true ; format('  FAILED: sigmoid(1)~n'), fail),
    (Y2 > 0.2, Y2 < 0.3 -> true ; format('  FAILED: sigmoid(-1)~n'), fail),
    format('  PASSED: Sigmoid module works~n').

test_tanh_module :-
    format('Test: Tanh module...~n'),
    nn:tanh_module(Tanh),
    Input = [0, 1, -1],
    nn:module_forward(Tanh, Input, Output),
    length(Output, 3),
    Output = [Y0, Y1, Y2],
    (Y0 > -0.01, Y0 < 0.01 -> true ; format('  FAILED: tanh(0)~n'), fail),
    (Y1 > 0.7, Y1 < 0.8 -> true ; format('  FAILED: tanh(1)~n'), fail),
    (Y2 < -0.7, Y2 > -0.8 -> true ; format('  FAILED: tanh(-1)~n'), fail),
    format('  PASSED: Tanh module works~n').

test_relu_module :-
    format('Test: ReLU module...~n'),
    nn:relu_module(ReLU),
    Input = [0, 1, -1, 5],
    nn:module_forward(ReLU, Input, Output),
    Output = [0, 1, 0, 5],
    format('  PASSED: ReLU module works~n').

test_softmax_module :-
    format('Test: SoftMax module...~n'),
    nn:softmax_module(SoftMax),
    Input = [1, 2, 3],
    nn:module_forward(SoftMax, Input, Output),
    sum_list(Output, Sum),
    (Sum > 0.99, Sum < 1.01 -> true ; format('  FAILED: SoftMax sum~n'), fail),
    format('  PASSED: SoftMax module works~n').

test_log_softmax_module :-
    format('Test: LogSoftMax module...~n'),
    nn:log_softmax_module(LogSoftMax),
    Input = [1, 2, 3],
    nn:module_forward(LogSoftMax, Input, Output),
    length(Output, 3),
    Output = [Y1, Y2, Y3],
    (Y1 < 0, Y2 < 0, Y3 < 0 -> true ; format('  FAILED: LogSoftMax values~n'), fail),
    format('  PASSED: LogSoftMax module works~n').

%% ============================================================================
%% Criterion Module Tests
%% ============================================================================

test_mse_criterion :-
    format('Test: MSE Criterion...~n'),
    nn:mse_criterion(MSE),
    Input = [1.0, 2.0, 3.0],
    Target = [1.0, 2.0, 3.0],
    nn:criterion_forward(MSE, Input, Target, Loss),
    (Loss < 0.01 -> true ; format('  FAILED: MSE loss should be near 0~n'), fail),
    
    % Test with different values
    Input2 = [1.0, 2.0],
    Target2 = [2.0, 3.0],
    nn:criterion_forward(MSE, Input2, Target2, Loss2),
    (Loss2 > 0.9, Loss2 < 1.1 -> true ; format('  FAILED: MSE loss calculation~n'), fail),
    format('  PASSED: MSE Criterion works~n').

test_class_nll_criterion :-
    format('Test: ClassNLL Criterion...~n'),
    nn:class_nll_criterion(NLL),
    % Log probabilities for 3 classes
    Input = [-0.5, -1.5, -2.0],
    Target = 0,  % Target class is 0
    nn:criterion_forward(NLL, Input, Target, Loss),
    (Loss > 0.4, Loss < 0.6 -> true ; format('  FAILED: NLL loss calculation~n'), fail),
    format('  PASSED: ClassNLL Criterion works~n').

test_bce_criterion :-
    format('Test: BCE Criterion...~n'),
    nn:bce_criterion(BCE),
    Input = [0.8, 0.2],
    Target = [1.0, 0.0],
    nn:criterion_forward(BCE, Input, Target, Loss),
    (Loss > 0, Loss < 1 -> true ; format('  FAILED: BCE loss calculation~n'), fail),
    format('  PASSED: BCE Criterion works~n').

test_abs_criterion :-
    format('Test: Abs Criterion...~n'),
    nn:abs_criterion(Abs),
    Input = [1.0, 2.0],
    Target = [2.0, 3.0],
    nn:criterion_forward(Abs, Input, Target, Loss),
    (Loss > 0.9, Loss < 1.1 -> true ; format('  FAILED: Abs loss calculation~n'), fail),
    format('  PASSED: Abs Criterion works~n').

%% ============================================================================
%% Simple Layer Module Tests
%% ============================================================================

test_linear_module :-
    format('Test: Linear module...~n'),
    nn:linear_module(3, 2, Linear),
    Input = [1, 2, 3],
    nn:module_forward(Linear, Input, Output),
    length(Output, 2),
    format('  PASSED: Linear module works~n').

test_identity_module :-
    format('Test: Identity module...~n'),
    nn:identity_module(Identity),
    Input = [1, 2, 3, 4],
    nn:module_forward(Identity, Input, Output),
    Output = Input,
    format('  PASSED: Identity module works~n').

test_reshape_module :-
    format('Test: Reshape module...~n'),
    nn:reshape_module([2, 2], Reshape),
    Input = [1, 2, 3, 4],
    nn:module_forward(Reshape, Input, Output),
    % Output should be reshaped to 2x2
    (is_list(Output) -> true ; format('  FAILED: Reshape output~n'), fail),
    format('  PASSED: Reshape module works~n').

test_mean_module :-
    format('Test: Mean module...~n'),
    nn:mean_module(1, Mean),
    Input = [1, 2, 3, 4],
    nn:module_forward(Mean, Input, Output),
    (Output =:= 2.5 -> true ; format('  FAILED: Mean calculation~n'), fail),
    format('  PASSED: Mean module works~n').

test_max_module :-
    format('Test: Max module...~n'),
    nn:max_module(1, Max),
    Input = [1, 5, 3, 2],
    nn:module_forward(Max, Input, Output),
    (Output =:= 5 -> true ; format('  FAILED: Max calculation~n'), fail),
    format('  PASSED: Max module works~n').

%% ============================================================================
%% Integration Tests
%% ============================================================================

test_sequential_classification :-
    format('Test: Sequential for classification...~n'),
    % Create a simple classification network
    nn:linear_module(2, 3, Linear1),
    nn:tanh_module(Tanh),
    nn:linear_module(3, 2, Linear2),
    nn:log_softmax_module(LogSoftMax),
    
    Network = sequential([Linear1, Tanh, Linear2, LogSoftMax]),
    Input = [0.5, 0.8],
    nn:sequential_forward(Network, Input, Output),
    
    length(Output, 2),
    sum_list(Output, Sum),
    % Log probabilities should sum to less than 0 (since they're logs)
    (Sum < 0 -> true ; format('  FAILED: LogSoftMax output~n'), fail),
    format('  PASSED: Sequential classification network works~n').

%% ============================================================================
%% Run All Module Tests
%% ============================================================================

run_module_tests :-
    format('~n=== Running Neural Network Module Tests ===~n~n'),
    
    % Container tests
    catch(test_sequential, Error, (format('  Sequential FAILED: ~w~n', [Error]), fail)),
    catch(test_concat, Error, (format('  Concat FAILED: ~w~n', [Error]), fail)),
    
    % Activation tests
    catch(test_sigmoid_module, Error, (format('  Sigmoid FAILED: ~w~n', [Error]), fail)),
    catch(test_tanh_module, Error, (format('  Tanh FAILED: ~w~n', [Error]), fail)),
    catch(test_relu_module, Error, (format('  ReLU FAILED: ~w~n', [Error]), fail)),
    catch(test_softmax_module, Error, (format('  SoftMax FAILED: ~w~n', [Error]), fail)),
    catch(test_log_softmax_module, Error, (format('  LogSoftMax FAILED: ~w~n', [Error]), fail)),
    
    % Criterion tests
    catch(test_mse_criterion, Error, (format('  MSE FAILED: ~w~n', [Error]), fail)),
    catch(test_class_nll_criterion, Error, (format('  ClassNLL FAILED: ~w~n', [Error]), fail)),
    catch(test_bce_criterion, Error, (format('  BCE FAILED: ~w~n', [Error]), fail)),
    catch(test_abs_criterion, Error, (format('  Abs FAILED: ~w~n', [Error]), fail)),
    
    % Simple layer tests
    catch(test_linear_module, Error, (format('  Linear FAILED: ~w~n', [Error]), fail)),
    catch(test_identity_module, Error, (format('  Identity FAILED: ~w~n', [Error]), fail)),
    catch(test_reshape_module, Error, (format('  Reshape FAILED: ~w~n', [Error]), fail)),
    catch(test_mean_module, Error, (format('  Mean FAILED: ~w~n', [Error]), fail)),
    catch(test_max_module, Error, (format('  Max FAILED: ~w~n', [Error]), fail)),
    
    % Integration tests
    catch(test_sequential_classification, Error, (format('  Integration FAILED: ~w~n', [Error]), fail)),
    
    format('~n=== All Module Tests Passed ===~n~n').
