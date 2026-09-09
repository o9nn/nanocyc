%% Test file for nn.pl
%% Run with: swipl -q -l test_nn.pl -g run_tests -t halt

:- consult('nn.pl').

%% Test basic network creation
test_create_network :-
    format('Test: Creating network...~n'),
    create_network([2, 3, 1], Network, _Weights),
    Network = network([2, 3, 1], _),
    format('  PASSED: Network created successfully~n').

%% Test forward propagation
test_forward :-
    format('Test: Forward propagation...~n'),
    create_network([2, 2, 1], Network, _),
    forward([0.5, 0.5], Network, Output),
    length(Output, 1),
    format('  PASSED: Forward propagation produces output~n').

%% Test sigmoid function
test_sigmoid :-
    format('Test: Sigmoid activation...~n'),
    sigmoid(0, Y0),
    sigmoid(100, Y1),
    sigmoid(-100, Y2),
    (Y0 > 0.49, Y0 < 0.51 -> true ; format('  FAILED: sigmoid(0) should be ~0.5~n'), fail),
    (Y1 > 0.99 -> true ; format('  FAILED: sigmoid(100) should be ~1~n'), fail),
    (Y2 < 0.01 -> true ; format('  FAILED: sigmoid(-100) should be ~0~n'), fail),
    format('  PASSED: Sigmoid function works correctly~n').

%% Test vector operations
test_vector_ops :-
    format('Test: Vector operations...~n'),
    dot_product([1, 2, 3], [4, 5, 6], Dot),
    (Dot =:= 32 -> true ; format('  FAILED: dot_product~n'), fail),
    add_vectors([1, 2], [3, 4], Sum),
    (Sum = [4, 6] -> true ; format('  FAILED: add_vectors~n'), fail),
    format('  PASSED: Vector operations work correctly~n').

%% Test XOR training (simplified version with fewer epochs)
test_xor_simple :-
    format('Test: XOR training (simple)...~n'),
    create_network([2, 4, 1], Network, _),
    TrainingData = [
        sample([0, 0], [0]),
        sample([0, 1], [1]),
        sample([1, 0], [1]),
        sample([1, 1], [0])
    ],
    % Train for just 100 epochs to test quickly
    train(TrainingData, Network, 0.5, 100, TrainedNetwork),
    predict([0, 0], TrainedNetwork, _Out1),
    predict([1, 1], TrainedNetwork, _Out2),
    format('  PASSED: XOR training completed~n').

%% Run all tests
run_tests :-
    format('~n=== Running Neural Network Tests ===~n~n'),
    catch(test_create_network, Error, (format('  FAILED with error: ~w~n', [Error]), fail)),
    catch(test_sigmoid, Error, (format('  FAILED with error: ~w~n', [Error]), fail)),
    catch(test_vector_ops, Error, (format('  FAILED with error: ~w~n', [Error]), fail)),
    catch(test_forward, Error, (format('  FAILED with error: ~w~n', [Error]), fail)),
    catch(test_xor_simple, Error, (format('  FAILED with error: ~w~n', [Error]), fail)),
    format('~n=== All Tests Passed ===~n~n').
