%% Cross-implementation consistency test for nn.pl
%% Run with: swipl -q -l test_consistency.pl -g run_consistency_tests -t halt
%%
%% Builds the fixed 2-2-1 sigmoid MLP from docs/fixtures/xor_fixture.json and
%% asserts the forward output and MSE loss to a tight tolerance. The identical
%% check is implemented by every other port (a9nn, scm, rkt, raku) and by the
%% Isabelle/HOL theories (lang/isa/NN_Consistency.thy), guaranteeing that all
%% implementations agree numerically on a single deterministic fixture.

:- consult('nn.pl').

%% approx_equal(+A, +B, +Tol)
approx_equal(A, B, Tol) :-
    Diff is abs(A - B),
    Diff =< Tol.

%% The shared fixture network: fixed weights, sigmoid on every layer.
fixture_network(network([2, 2, 1],
    [ [ neuron([0.5, -0.5],  0.1),
        neuron([-0.25, 0.75], -0.2) ],
      [ neuron([0.6, -0.4],  0.05) ] ])).

%% fixture_case(+Input, +Target, -ExpectedOutput, -ExpectedLoss)
fixture_case([0, 0], [0], 0.5460989866, 0.2982241032).
fixture_case([0, 1], [1], 0.5092822253, 0.2408039344).
fixture_case([1, 0], [1], 0.5699505688, 0.1849425133).
fixture_case([1, 1], [0], 0.5337512224, 0.2848903675).

%% Check one case: forward output and MSE loss match the reference.
check_case(Input, Target, ExpOut, ExpLoss) :-
    fixture_network(Net),
    forward(Input, Net, Out),
    Out = [OutVal],
    Tol = 1e-6,
    (   approx_equal(OutVal, ExpOut, Tol)
    ->  format('  PASSED: output for ~w = ~10f~n', [Input, OutVal])
    ;   format('  FAILED: output for ~w: expected ~w, got ~w~n',
               [Input, ExpOut, OutVal]),
        fail
    ),
    mse_loss(Out, Target, Loss),
    (   approx_equal(Loss, ExpLoss, Tol)
    ->  format('  PASSED: loss   for ~w = ~10f~n', [Input, Loss])
    ;   format('  FAILED: loss   for ~w: expected ~w, got ~w~n',
               [Input, ExpLoss, Loss]),
        fail
    ).

test_consistency :-
    format('Test: Cross-implementation consistency (xor_fixture)...~n'),
    forall(
        fixture_case(Input, Target, ExpOut, ExpLoss),
        check_case(Input, Target, ExpOut, ExpLoss)
    ),
    format('  PASSED: all consistency cases agree with the reference~n').

run_consistency_tests :-
    format('~n=== Running Consistency Tests ===~n~n'),
    (   catch(test_consistency, Error,
              (format('  FAILED with error: ~w~n', [Error]), fail))
    ->  format('~n=== All Consistency Tests Passed ===~n~n')
    ;   format('~n=== Consistency Tests FAILED ===~n~n'),
        halt(1)
    ).
