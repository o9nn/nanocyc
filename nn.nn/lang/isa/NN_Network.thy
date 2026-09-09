(*  Theory:  NN_Network
    Derived from: docs/data_model.zpp Section 4 (module base schema),
    docs/operations.zpp Section 1 (forward propagation) and Section 6
    (inference), plus the sibling network construction API.

    Randomness is replaced by a deterministic linear congruential
    generator threaded through weight initialization, honouring the
    initialization-in-(-0.5, 0.5) contract of integrations.zpp Section 2
    while keeping all demos reproducible.
*)

theory NN_Network
  imports NN_Matrix NN_Activations
begin

section \<open>Deterministic pseudo-random weights\<close>

text \<open>Linear congruential generator (Numerical Recipes parameters).\<close>
definition lcg_next :: "nat \<Rightarrow> nat" where
  "lcg_next s = (1664525 * s + 1013904223) mod 4294967296"

text \<open>A pseudo-random real in \<open>[0, 1)\<close>, mirroring \<open>random-real\<close>.\<close>
definition lcg_real :: "nat \<Rightarrow> real" where
  "lcg_real s = real (s mod 10000) / 10000"

text \<open>A pseudo-random weight in \<open>[-0.5, 0.5)\<close>, mirroring \<open>random-weight\<close>.\<close>
definition random_weight :: "nat \<Rightarrow> real" where
  "random_weight s = lcg_real s - 1/2"

text \<open>Generate \<open>n\<close> weights from a seed, returning the advanced seed.\<close>
fun random_weights :: "nat \<Rightarrow> nat \<Rightarrow> vec \<times> nat" where
  "random_weights 0 s = ([], s)"
| "random_weights (Suc n) s =
     (let s' = lcg_next s;
          (ws, s'') = random_weights n s'
      in (random_weight s' # ws, s''))"

lemma length_random_weights [simp]:
  "length (fst (random_weights n s)) = n"
  by (induct n arbitrary: s) (simp_all add: Let_def case_prod_beta)

lemma random_weight_range: "-1/2 \<le> random_weight s \<and> random_weight s < 1/2"
  by (simp add: random_weight_def lcg_real_def)

section \<open>Neuron, layer and network construction\<close>

text \<open>make-neuron: a neuron with \<open>input_size\<close> weights and a bias.\<close>
definition make_neuron :: "nat \<Rightarrow> nat \<Rightarrow> neuron \<times> nat" where
  "make_neuron input_size s =
     (let (ws, s') = random_weights input_size s;
          s'' = lcg_next s'
      in ((ws, random_weight s''), s''))"

lemma make_neuron_wf: "wf_neuron (fst (make_neuron k s)) k"
proof -
  obtain ws s' where *: "random_weights k s = (ws, s')"
    by (cases "random_weights k s")
  then have "length ws = k"
    using length_random_weights[of k s] by simp
  with * show ?thesis
    by (simp add: make_neuron_def wf_neuron_def neuron_weights_def Let_def)
qed

text \<open>make-layer: \<open>output_size\<close> neurons, each with \<open>input_size\<close> inputs.\<close>
fun make_layer :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> layer \<times> nat" where
  "make_layer input_size 0 s = ([], s)"
| "make_layer input_size (Suc n) s =
     (let (neuron, s') = make_neuron input_size s;
          (rest, s'') = make_layer input_size n s'
      in (neuron # rest, s''))"

lemma make_layer_wf: "wf_layer (fst (make_layer k m s)) k m"
proof (induct m arbitrary: s)
  case 0 then show ?case by (simp add: wf_layer_def)
next
  case (Suc m)
  obtain n s' where 1: "make_neuron k s = (n, s')"
    by (cases "make_neuron k s")
  obtain rest s'' where 2: "make_layer k m s' = (rest, s'')"
    by (cases "make_layer k m s'")
  have "wf_neuron n k"
    using make_neuron_wf[of k s] 1 by simp
  moreover have "wf_layer rest k m"
    using Suc[of s'] 2 by simp
  ultimately show ?case
    using 1 2 by (simp add: wf_layer_def)
qed

text \<open>init-weights: one layer per consecutive pair of layer sizes.\<close>
fun init_weights :: "shape \<Rightarrow> nat \<Rightarrow> layer list \<times> nat" where
  "init_weights [] s = ([], s)"
| "init_weights [_] s = ([], s)"
| "init_weights (k # m # rest) s =
     (let (l, s') = make_layer k m s;
          (ls, s'') = init_weights (m # rest) s'
      in (l # ls, s''))"

text \<open>create-network with an explicit seed.\<close>
definition create_network_seeded :: "shape \<Rightarrow> nat \<Rightarrow> network" where
  "create_network_seeded sizes s = (sizes, fst (init_weights sizes s))"

text \<open>create-network with the default seed, mirroring the sibling API.\<close>
definition create_network :: "shape \<Rightarrow> network" where
  "create_network sizes = create_network_seeded sizes 42"

section \<open>Forward propagation (operations.zpp Section 1)\<close>

text \<open>
  neuron-output: the pre-activation \<open>w \<cdot> x + b\<close> (LinearForward schema,
  specialized to one row).
\<close>
definition neuron_output :: "neuron \<Rightarrow> vec \<Rightarrow> real" where
  "neuron_output n input = dot_product (neuron_weights n) input + neuron_bias n"

text \<open>layer-output: apply an activation to each neuron's pre-activation.\<close>
definition layer_output :: "layer \<Rightarrow> vec \<Rightarrow> (real \<Rightarrow> real) \<Rightarrow> vec" where
  "layer_output l input f = map (\<lambda>n. f (neuron_output n input)) l"

lemma length_layer_output [simp]:
  "length (layer_output l input f) = length l"
  by (simp add: layer_output_def)

text \<open>
  forward-propagate: chain sigmoid layers (SequentialForward /
  CompleteForwardPass schemas).  The siblings use the clamped sigmoid.
\<close>
fun forward_propagate :: "vec \<Rightarrow> layer list \<Rightarrow> vec" where
  "forward_propagate input [] = input"
| "forward_propagate input (l # ls) =
     forward_propagate (layer_output l input sigmoid_safe) ls"

text \<open>forward: network output for an input.\<close>
definition forward :: "vec \<Rightarrow> network \<Rightarrow> vec" where
  "forward input net = forward_propagate input (network_weights net)"

text \<open>predict: alias for forward (operations.zpp Section 6, Predict schema).\<close>
definition predict :: "vec \<Rightarrow> network \<Rightarrow> vec" where
  "predict input net = forward input net"

end
