%% demo.pl - Simple demo script for nn.pl
%% Run with: swipl -l demo.pl

:- use_module(nn).

%% Demo 1: Create and test a network
demo_basic :-
    format('~n=== Demo 1: Basic Network Creation ===~n'),
    format('Creating a 2-3-1 network...~n'),
    nn:create_network([2, 3, 1], Network, _),
    format('Network created: ~w~n', [Network]),
    format('Testing forward propagation with input [0.5, 0.8]...~n'),
    nn:predict([0.5, 0.8], Network, Output),
    format('Output: ~w~n', [Output]).

%% Demo 2: XOR Problem
demo_xor :-
    format('~n=== Demo 2: XOR Problem ===~n'),
    format('Training network to learn XOR function...~n'),
    nn:create_network([2, 4, 1], Network, _),
    TrainingData = [
        sample([0, 0], [0]),
        sample([0, 1], [1]),
        sample([1, 0], [1]),
        sample([1, 1], [0])
    ],
    format('Training for 1000 epochs with learning rate 0.5...~n'),
    nn:train(TrainingData, Network, 0.5, 1000, TrainedNetwork),
    format('~nTesting predictions:~n'),
    nn:predict([0, 0], TrainedNetwork, Out1),
    format('  XOR(0, 0) = ~w (expected: 0)~n', [Out1]),
    nn:predict([0, 1], TrainedNetwork, Out2),
    format('  XOR(0, 1) = ~w (expected: 1)~n', [Out2]),
    nn:predict([1, 0], TrainedNetwork, Out3),
    format('  XOR(1, 0) = ~w (expected: 1)~n', [Out3]),
    nn:predict([1, 1], TrainedNetwork, Out4),
    format('  XOR(1, 1) = ~w (expected: 0)~n', [Out4]).

%% Demo 3: AND gate
demo_and :-
    format('~n=== Demo 3: AND Gate ===~n'),
    format('Training network to learn AND function...~n'),
    nn:create_network([2, 2, 1], Network, _),
    TrainingData = [
        sample([0, 0], [0]),
        sample([0, 1], [0]),
        sample([1, 0], [0]),
        sample([1, 1], [1])
    ],
    format('Training for 500 epochs with learning rate 0.5...~n'),
    nn:train(TrainingData, Network, 0.5, 500, TrainedNetwork),
    format('~nTesting predictions:~n'),
    nn:predict([0, 0], TrainedNetwork, A1),
    format('  AND(0, 0) = ~w (expected: 0)~n', [A1]),
    nn:predict([0, 1], TrainedNetwork, A2),
    format('  AND(0, 1) = ~w (expected: 0)~n', [A2]),
    nn:predict([1, 0], TrainedNetwork, A3),
    format('  AND(1, 0) = ~w (expected: 0)~n', [A3]),
    nn:predict([1, 1], TrainedNetwork, A4),
    format('  AND(1, 1) = ~w (expected: 1)~n', [A4]).

%% Run all demos
run_all_demos :-
    format('~n╔════════════════════════════════════════╗~n'),
    format('║   Neural Network Demo - Pure Prolog   ║~n'),
    format('╚════════════════════════════════════════╝~n'),
    demo_basic,
    demo_xor,
    demo_and,
    format('~n╔════════════════════════════════════════╗~n'),
    format('║          All Demos Completed!          ║~n'),
    format('╚════════════════════════════════════════╝~n~n').

%% Print usage information
usage :-
    format('~n=== nn.pl - Neural Network in Pure Prolog ===~n~n'),
    format('Usage examples:~n'),
    format('  ?- run_all_demos.           % Run all demonstrations~n'),
    format('  ?- demo_basic.              % Basic network creation~n'),
    format('  ?- demo_xor.                % XOR problem~n'),
    format('  ?- demo_and.                % AND gate~n'),
    format('~n'),
    format('Quick start:~n'),
    format('  1. Create a network: nn:create_network([2,3,1], Net, _).~n'),
    format('  2. Make prediction: nn:predict([0.5, 0.8], Net, Out).~n'),
    format('  3. Train network: nn:train(Data, Net, 0.5, 1000, Trained).~n'),
    format('~n'),
    format('For more information, see README_PROLOG.md~n~n').

%% Automatically show usage when loaded
:- initialization(usage).
