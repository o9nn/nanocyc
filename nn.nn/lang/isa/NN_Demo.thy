(*  Theory:  NN_Demo
    Derived from: the sibling demonstration scripts (lang/scm/demo.scm,
    lang/rkt/demo.rkt, lang/raku/demo.raku).

    Every demo is a \<open>value\<close> command over the executable layer of
    NN_Exec, so a plain `isabelle build` runs all of them and prints the
    results into the build log.  Displayed numbers are rounded to four
    decimals for readability; the underlying computation is exact
    rational arithmetic (see NN_Exec).

    Each expensive result is produced by a single \<open>value\<close> command, so
    the training runs below are each executed exactly once.
*)

theory NN_Demo
  imports NN
begin

section \<open>Display helpers\<close>

text \<open>Round a scalar / a vector for display.\<close>

definition show_real :: "real \<Rightarrow> real" where
  "show_real x = round_to 4 x"

definition show_vec :: "vec \<Rightarrow> vec" where
  "show_vec v = map (round_to 4) v"

text \<open>
  Index of the largest component, as used by the classification demo
  (the siblings compute this inline).
\<close>

fun argmax_from :: "nat \<Rightarrow> nat \<Rightarrow> real \<Rightarrow> vec \<Rightarrow> nat" where
  "argmax_from i best bv [] = best"
| "argmax_from i best bv (x # xs) =
     (if x > bv then argmax_from (Suc i) i x xs else argmax_from (Suc i) best bv xs)"

definition argmax_index :: "vec \<Rightarrow> nat" where
  "argmax_index v = (case v of [] \<Rightarrow> 0 | x # xs \<Rightarrow> argmax_from 1 0 x xs)"

section \<open>Demo 1: basic network creation and prediction\<close>

definition demo_net :: network where
  "demo_net = create_network [2, 3, 1]"

value "(STR ''demo 1: layer sizes'', network_layers demo_net)"

value "(STR ''demo 1: weight layers'', length (network_weights demo_net))"

value "(STR ''demo 1: forward [0.5, 0.8]'',
        show_vec (forward_exec [0.5, 0.8] demo_net))"

section \<open>Demo 2: AND gate\<close>

definition and_data :: "sample list" where
  "and_data = [make_sample [0, 0] [0], make_sample [0, 1] [0],
               make_sample [1, 0] [0], make_sample [1, 1] [1]]"

text \<open>
  Train a 2-2-1 network for 200 epochs at learning rate \<open>0.5\<close> and show
  the four predictions, expected to approximate \<open>0, 0, 0, 1\<close>.
\<close>

value "(STR ''demo 2: AND predictions for (0,0) (0,1) (1,0) (1,1)'',
        let net = train_exec and_data (create_network [2, 2, 1]) 0.5 200
        in map (\<lambda>x. show_vec (forward_exec x net))
               [[0, 0], [0, 1], [1, 0], [1, 1]])"

section \<open>Demo 3: XOR problem\<close>

definition xor_data :: "sample list" where
  "xor_data = [make_sample [0, 0] [0], make_sample [0, 1] [1],
               make_sample [1, 0] [1], make_sample [1, 1] [0]]"

text \<open>
  As in the siblings, \<open>train\<close> is the simplified variant that updates the
  output layer only, so XOR is not fully separated; the demo shows the
  loss decreasing rather than a perfect fit.
\<close>

value "(STR ''demo 3: XOR mean loss before / after 100 epochs'',
        let net = create_network [2, 4, 1];
            trained = train_exec xor_data net 0.5 100;
            loss = (\<lambda>n. vector_mean (map (\<lambda>s. mse_loss (forward_exec (sample_input s) n)
                                                       (sample_target s))
                                          xor_data))
        in (show_real (loss net), show_real (loss trained)))"

section \<open>Demo 4: module-based architecture\<close>

definition demo_modular :: module where
  "demo_modular = make_sequential
     [make_linear 2 4, tanh_module, make_linear 4 3, sigmoid_module]"

value "(STR ''demo 4: Linear(2->4) -> Tanh -> Linear(4->3) -> Sigmoid on [0.5, 0.5]'',
        show_vec (module_forward_exec demo_modular [0.5, 0.5]))"

section \<open>Demo 5: activation functions\<close>

definition demo_activation_input :: vec where
  "demo_activation_input = [-2, -1, 0, 1, 2]"

value "(STR ''demo 5: sigmoid'',
        show_vec (module_forward_exec sigmoid_module demo_activation_input))"

value "(STR ''demo 5: tanh'',
        show_vec (module_forward_exec tanh_module demo_activation_input))"

value "(STR ''demo 5: relu'',
        show_vec (module_forward_exec relu_module demo_activation_input))"

section \<open>Demo 6: loss functions (criterions)\<close>

value "(STR ''demo 6: MSE / BCE / Abs for output [0.8], target [1.0]'',
        (show_real (criterion_forward_exec mse_criterion [0.8] [1.0]),
         show_real (criterion_forward_exec bce_criterion [0.8] [1.0]),
         show_real (criterion_forward_exec abs_criterion [0.8] [1.0])))"

value "(STR ''demo 6: ClassNLL of log-probabilities [-0.5, -1.5, -0.1] for class 2'',
        show_real (class_nll_loss [-0.5, -1.5, -0.1] 2))"

section \<open>Demo 7: softmax and classification\<close>

definition demo_logits :: vec where
  "demo_logits = [2.0, 1.0, 0.1]"

value "(STR ''demo 7: softmax probabilities and their sum'',
        let p = softmax_exec demo_logits
        in (show_vec p, show_real (vector_sum p)))"

value "(STR ''demo 7: log-softmax'',
        show_vec (log_softmax_exec demo_logits))"

value "(STR ''demo 7: predicted class and its probability'',
        let p = softmax_exec demo_logits;
            c = argmax_index p
        in (c, show_real (p ! c)))"

end
