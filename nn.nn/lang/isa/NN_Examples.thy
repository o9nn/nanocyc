(*  Theory:  NN_Examples
    Derived from: the sibling quick-start scripts (lang/scm/example.scm,
    lang/rkt/example.rkt, lang/raku/example.raku).

    A short tour of the user-facing API.  As in NN_Demo every step is a
    \<open>value\<close> command, so `isabelle build` executes the whole tour; the
    final section prints the machine-checked guarantees that come with
    the Isabelle rendering and have no counterpart in the sibling
    implementations.
*)

theory NN_Examples
  imports NN_Demo
begin

section \<open>Example 1: simple network and prediction\<close>

definition example_net :: network where
  "example_net = create_network [2, 3, 1]"

value "(STR ''example 1: layer sizes'', network_layers example_net)"

value "(STR ''example 1: predictions for [0,0], [0.5,0.5], [1,1]'',
        map (\<lambda>x. show_vec (predict_exec x example_net))
            [[0, 0], [0.5, 0.5], [1, 1]])"

section \<open>Example 2: module-based architecture\<close>

text \<open>Linear(2 -> 4) -> Tanh -> Linear(4 -> 1) -> Sigmoid.\<close>

definition example_modular :: module where
  "example_modular = make_sequential
     [make_linear 2 4, tanh_module, make_linear 4 1, sigmoid_module]"

value "(STR ''example 2: output for [0.5, 0.5]'',
        show_vec (module_forward_exec example_modular [0.5, 0.5]))"

section \<open>Example 3: multi-class classification with softmax\<close>

definition example_classifier :: module where
  "example_classifier = make_sequential [make_linear 2 3, softmax_module]"

value "(STR ''example 3: class probabilities for [0.8, 0.3] and their sum'',
        let p = module_forward_exec example_classifier [0.8, 0.3]
        in (show_vec p, show_real (vector_sum p)))"

section \<open>Example 4: loss functions\<close>

text \<open>Output \<open>[0.7]\<close> against target \<open>[1.0]\<close>, as in the siblings.\<close>

value "(STR ''example 4: MSE / BCE / Abs'',
        (show_real (criterion_forward_exec mse_criterion [0.7] [1.0]),
         show_real (criterion_forward_exec bce_criterion [0.7] [1.0]),
         show_real (criterion_forward_exec abs_criterion [0.7] [1.0])))"

section \<open>Example 5: activation functions\<close>

definition example_input :: vec where
  "example_input = [-2.0, -1.0, 0.0, 1.0, 2.0]"

value "(STR ''example 5: sigmoid / tanh / relu'',
        (show_vec (module_forward_exec sigmoid_module example_input),
         show_vec (module_forward_exec tanh_module example_input),
         show_vec (module_forward_exec relu_module example_input)))"

section \<open>Example 6: training\<close>

value "(STR ''example 6: MSE on [1,1] before / after 50 epochs'',
        let samples = [make_sample [0, 0] [0], make_sample [1, 1] [1]];
            net = create_network [2, 3, 1];
            trained = train_exec samples net 0.5 50
        in (show_real (mse_loss (forward_exec [1, 1] net) [1]),
            show_real (mse_loss (forward_exec [1, 1] trained) [1])))"

section \<open>Example 7: what the Isabelle rendering adds\<close>

text \<open>
  The results above are computed; the facts below are \<^emph>\<open>proved\<close>, once
  and for all inputs, in \<open>NN_Properties\<close>.
\<close>

thm sigmoid_range
thm tanh_range
thm relu_nonneg
thm softmax_sums_to_one
thm log_softmax_nonpos
thm sigmoid_has_derivative
thm tanh_has_derivative
thm mse_loss_nonneg
thm mse_loss_zero_iff
thm abs_loss_nonneg
thm forward_length
thm module_forward_length
thm transpose_matrix_involution
thm training_topology_invariants

end
