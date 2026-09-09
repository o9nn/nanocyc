(*  Theory:  NN_Test
    Derived from: the sibling 45-test suites (lang/scm/test-nn.scm,
    lang/rkt/test-nn.rkt, lang/raku/test-nn.raku).

    Executable regression tests as machine-checked lemmas, discharged
    with eval over exact rational arithmetic.  Tests that touch the
    transcendental functions exp/ln/tanh run against the executable
    approximation layer of NN_Exec (as the siblings run against
    floats); everything else tests the exact library definitions
    directly.  Universal properties are inherited from NN_Properties.

    A successful `isabelle build` of this session certifies every test.
*)

theory NN_Test
  imports NN
begin

section \<open>Test helpers\<close>

text \<open>Approximate equality, mirroring the siblings' assert-approx.\<close>
definition approx :: "real \<Rightarrow> real \<Rightarrow> real \<Rightarrow> bool" where
  "approx actual expected tol \<longleftrightarrow> \<bar>actual - expected\<bar> < tol"

definition in_unit_interval :: "real \<Rightarrow> bool" where
  "in_unit_interval x \<longleftrightarrow> 0 \<le> x \<and> x \<le> 1"

section \<open>Activation function tests (sibling: test-sigmoid/test-tanh/test-relu)\<close>

lemma test_sigmoid_zero: "approx (sigmoid_exec 0) 0.5 0.01"
  by eval

lemma test_sigmoid_large: "sigmoid_exec 100 > 0.99"
  by eval

lemma test_sigmoid_small: "sigmoid_exec (-100) < 0.01"
  by eval

lemma test_sigmoid_monotone_sample: "sigmoid_exec (-1) < sigmoid_exec 0 \<and>
                                     sigmoid_exec 0 < sigmoid_exec 1"
  by eval

lemma test_tanh_zero: "approx (tanh_exec 0) 0 0.01"
  by eval

lemma test_tanh_large: "tanh_exec 10 > 0.99"
  by eval

lemma test_tanh_small: "tanh_exec (-10) < -0.99"
  by eval

lemma test_relu_pos: "relu 5 = 5"
  by eval

lemma test_relu_neg: "relu (-3) = 0"
  by eval

lemma test_relu_zero: "relu 0 = 0"
  by eval

lemma test_relu_derivative: "relu_derivative 2 = 1 \<and> relu_derivative (-2) = 0"
  by eval

section \<open>Vector operation tests (sibling: test-vector-ops)\<close>

lemma test_dot_product: "dot_product [1, 2, 3] [4, 5, 6] = 32"
  by eval

lemma test_vector_add: "vector_add [1, 2] [3, 4] = [4, 6]"
  by eval

lemma test_vector_sub: "vector_sub [5, 7] [2, 3] = [3, 4]"
  by eval

lemma test_scalar_mult: "scalar_mult_vector 2 [1, 2, 3] = [2, 4, 6]"
  by eval

section \<open>Vector reduction tests (sibling: test-vector-reductions)\<close>

lemma test_vector_sum: "vector_sum [1, 2, 3, 4] = 10"
  by eval

lemma test_vector_mean: "vector_mean [2, 4, 6, 8] = 5"
  by eval

lemma test_vector_max: "vector_max [1, 5, 3, 2] = 5"
  by eval

section \<open>Matrix operation tests\<close>

lemma test_matrix_vector_mult:
  "matrix_vector_mult [[1, 2], [3, 4]] [1, 1] = [3, 7]"
  by eval

lemma test_transpose:
  "transpose_matrix [[1, 2, 3], [4, 5, 6]] = [[1, 4], [2, 5], [3, 6]]"
  by eval

lemma test_transpose_involution:
  "transpose_matrix (transpose_matrix [[1, 2], [3, 4], [5, 6]]) =
   [[1, 2], [3, 4], [5, 6]]"
  by eval

section \<open>Network creation tests (sibling: test-create-network/test-neuron)\<close>

lemma test_network_layers: "network_layers (create_network [2, 3, 1]) = [2, 3, 1]"
  by eval

lemma test_network_has_weights: "network_weights (create_network [2, 3, 1]) \<noteq> []"
  by eval

lemma test_network_depth: "length (network_weights (create_network [2, 3, 1])) = 2"
  by eval

lemma test_neuron_weight_count:
  "length (neuron_weights (fst (make_neuron 3 42))) = 3"
  by eval

lemma test_network_wf: "wf_network (create_network [2, 3, 1])"
  by eval

lemma test_weight_range:
  "let w = random_weight 123 in - (1/2) \<le> w \<and> w < 1/2"
  by eval

section \<open>Forward propagation tests (sibling: test-forward-propagation)\<close>

lemma test_forward_output_size:
  "length (forward_exec [0.5, 0.5] (create_network [2, 3, 1])) = 1"
  by eval

lemma test_forward_sigmoid_range:
  "list_all in_unit_interval (forward_exec [0.5, 0.5] (create_network [2, 3, 1]))"
  by eval

lemma test_predict_is_forward:
  "predict_exec [0.5, 0.5] (create_network [2, 3, 1]) =
   forward_exec [0.5, 0.5] (create_network [2, 3, 1])"
  by (simp add: predict_exec_def)

section \<open>Loss function tests (sibling: test-mse-loss)\<close>

lemma test_mse_identical: "mse_loss [0.5] [0.5] = 0"
  by eval

lemma test_mse_unit: "mse_loss [0] [1] = 1"
  by eval

lemma test_mse_derivative: "mse_loss_derivative [1] [0] = [2]"
  by eval

lemma test_abs_loss: "abs_loss [1, 3] [2, 5] = 3"
  by eval

section \<open>Module system tests (sibling: test-*-module)\<close>

lemma test_sigmoid_module_size:
  "length (module_forward_exec sigmoid_module [0, 2, -2]) = 3"
  by eval

lemma test_sigmoid_module_zero:
  "approx (hd (module_forward_exec sigmoid_module [0, 2, -2])) 0.5 0.01"
  by eval

lemma test_tanh_module_size:
  "length (module_forward_exec tanh_module [0, 1, -1]) = 3"
  by eval

lemma test_relu_module:
  "module_forward_exec relu_module [-1, 0, 1, 5] = [0, 0, 1, 5]"
  by eval

lemma test_linear_module_size:
  "length (module_forward_exec (make_linear 2 3) [1, 1]) = 3"
  by eval

lemma test_identity_module:
  "module_forward_exec make_identity [1, 2, 3] = [1, 2, 3]"
  by eval

lemma test_reshape_module:
  "module_forward_exec (make_reshape [3]) [1, 2, 3] = [1, 2, 3]"
  by eval

lemma test_mean_module:
  "module_forward_exec (make_mean 0) [2, 4, 6, 8] = [5]"
  by eval

lemma test_max_module:
  "module_forward_exec (make_max 0) [1, 5, 3, 2] = [5]"
  by eval

lemma test_sequential_module_size:
  "length (module_forward_exec (make_sequential [make_linear 2 3, sigmoid_module])
                               [0.5, 0.5]) = 3"
  by eval

lemma test_sequential_sigmoid_range:
  "list_all in_unit_interval
     (module_forward_exec (make_sequential [make_linear 2 3, sigmoid_module])
                          [0.5, 0.5])"
  by eval

lemma test_concat_module:
  "module_forward_exec (make_concat 0 [make_identity, make_identity]) [1, 2] =
   [1, 2, 1, 2]"
  by eval

section \<open>Criterion tests (sibling: test-mse-criterion/test-class-nll-criterion)\<close>

lemma test_mse_criterion:
  "criterion_forward_exec mse_criterion [0.5] [0.5] = 0"
  by eval

lemma test_class_nll_criterion:
  "approx (class_nll_loss [-0.5, -1.5, -0.1] 2) 0.1 0.001"
  by eval

lemma test_bce_criterion_nonneg:
  "criterion_forward_exec bce_criterion [0.5] [1] > 0"
  by eval

lemma test_abs_criterion:
  "criterion_forward_exec abs_criterion [1, 3] [2, 5] = 3"
  by eval

section \<open>Softmax tests (sibling: test-softmax/test-log-softmax)\<close>

lemma test_softmax_length: "length (softmax_exec [1, 2, 3]) = 3"
  by eval

lemma test_softmax_sums_to_one:
  "approx (vector_sum (softmax_exec [1, 2, 3])) 1 0.001"
  by eval

lemma test_softmax_monotone:
  "let s = softmax_exec [1, 2, 3] in s ! 0 < s ! 1 \<and> s ! 1 < s ! 2"
  by eval

lemma test_softmax_nonneg:
  "list_all (\<lambda>x. 0 \<le> x) (softmax_exec [1, 2, 3])"
  by eval

lemma test_log_softmax_length: "length (log_softmax_exec [1, 2, 3]) = 3"
  by eval

lemma test_log_softmax_negative:
  "list_all (\<lambda>x. x < 0) (log_softmax_exec [1, 2, 3])"
  by eval

section \<open>Integration tests (sibling: test-simple-training/test-module-composition)\<close>

definition test_train_samples :: "sample list" where
  "test_train_samples = [make_sample [0, 0] [0], make_sample [1, 1] [1]]"

lemma test_training_preserves_structure:
  "network_layers
     (train_exec test_train_samples (create_network [2, 3, 1]) 0.5 5) =
   [2, 3, 1]"
  by eval

lemma test_training_preserves_depth:
  "length (network_weights
            (train_exec test_train_samples (create_network [2, 3, 1]) 0.5 5)) = 2"
  by eval

text \<open>
  Training reduces the loss on a fixed-seed run (structural convergence
  smoke check; exact learned values are deliberately not asserted).
\<close>
lemma test_training_reduces_loss:
  "let net = create_network [2, 3, 1];
       trained = train_exec test_train_samples net 0.5 50;
       loss_before = mse_loss (forward_exec [1, 1] net) [1];
       loss_after = mse_loss (forward_exec [1, 1] trained) [1]
   in loss_after < loss_before"
  by eval

lemma test_module_composition:
  "let seq = make_sequential
               [make_linear 2 3, tanh_module, make_linear 3 1, sigmoid_module];
       output = module_forward_exec seq [0.5, 0.5]
   in length output = 1 \<and> list_all in_unit_interval output"
  by eval

section \<open>Proved-invariant spot checks (these hold for all inputs, see NN_Properties)\<close>

lemma test_sigmoid_range_universal: "\<forall>x. 0 < sigmoid x \<and> sigmoid x < 1"
  using sigmoid_range by blast

lemma test_tanh_range_universal:
  "\<forall>x. -1 < tanh_activation x \<and> tanh_activation x < 1"
  using tanh_range by blast

lemma test_relu_nonneg_universal: "\<forall>x. relu x \<ge> 0"
  using relu_nonneg by blast

lemma test_softmax_sums_universal: "\<forall>v. v \<noteq> [] \<longrightarrow> sum_list (softmax v) = 1"
  using softmax_sums_to_one by blast

lemma test_mse_nonneg_universal: "\<forall>out tgt. 0 \<le> mse_loss out tgt"
  using mse_loss_nonneg by blast

end
