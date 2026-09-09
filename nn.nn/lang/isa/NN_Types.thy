(*  Theory:  NN_Types
    Derived from: docs/data_model.zpp Sections 1-3 (basic types, tensor
    representation, module parameters).

    Type synonyms and well-formedness predicates for the neural network
    library.  Vectors are real lists and matrices are lists of row
    vectors, mirroring the sibling implementations (lang/scm/nn.scm,
    lang/rkt/nn.rkt, lang/raku/NN.rakumod).
*)

theory NN_Types
  imports Complex_Main
begin

section \<open>Basic types (data_model.zpp Section 1)\<close>

text \<open>
  \<^item> \<open>\<real>\<close> (real numbers) \<rightarrow> \<^typ>\<open>real\<close>
  \<^item> \<open>\<nat>\<close> (naturals for dimensions/counts) \<rightarrow> \<^typ>\<open>nat\<close>
  \<^item> \<open>seq \<real>\<close> (TensorData) \<rightarrow> \<^typ>\<open>real list\<close>
\<close>

type_synonym vec = "real list"
type_synonym mat = "real list list"

text \<open>Shape == seq \<nat> (data_model.zpp Section 2).\<close>
type_synonym shape = "nat list"

section \<open>Neurons, layers and networks (data_model.zpp Sections 3-4)\<close>

text \<open>
  A neuron is a pair of a weight vector and a bias, matching the sibling
  representation \<open>(neuron weights bias)\<close>.
\<close>
type_synonym neuron = "vec \<times> real"

definition neuron_weights :: "neuron \<Rightarrow> vec" where
  "neuron_weights n = fst n"

definition neuron_bias :: "neuron \<Rightarrow> real" where
  "neuron_bias n = snd n"

text \<open>A layer is a list of neurons.\<close>
type_synonym layer = "neuron list"

text \<open>
  A network is a pair of declared layer sizes and per-layer weights,
  matching the sibling representation \<open>(network layer-sizes weights)\<close>.
\<close>
type_synonym network = "shape \<times> layer list"

definition network_layers :: "network \<Rightarrow> shape" where
  "network_layers net = fst net"

definition network_weights :: "network \<Rightarrow> layer list" where
  "network_weights net = snd net"

section \<open>Training samples\<close>

text \<open>sample(Input, Target) as in the sibling implementations.\<close>
type_synonym sample = "vec \<times> vec"

definition make_sample :: "vec \<Rightarrow> vec \<Rightarrow> sample" where
  "make_sample i t = (i, t)"

definition sample_input :: "sample \<Rightarrow> vec" where
  "sample_input s = fst s"

definition sample_target :: "sample \<Rightarrow> vec" where
  "sample_target s = snd s"

section \<open>Well-formedness predicates (data_model.zpp invariants)\<close>

text \<open>
  \<open>wf_neuron n k\<close>: the neuron accepts inputs of size \<open>k\<close>
  (weight vector has length \<open>k\<close>).
\<close>
definition wf_neuron :: "neuron \<Rightarrow> nat \<Rightarrow> bool" where
  "wf_neuron n k \<longleftrightarrow> length (neuron_weights n) = k"

text \<open>
  \<open>wf_layer l k m\<close>: the layer maps size-\<open>k\<close> inputs to size-\<open>m\<close> outputs
  (\<open>m\<close> neurons, each with \<open>k\<close> weights).
\<close>
definition wf_layer :: "layer \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool" where
  "wf_layer l k m \<longleftrightarrow> length l = m \<and> (\<forall>n \<in> set l. wf_neuron n k)"

text \<open>
  \<open>wf_weights ws sizes\<close>: the list of layers \<open>ws\<close> realizes the declared
  layer sizes \<open>sizes\<close>; consecutive sizes give each layer's input/output
  dimensions.  This is the shape-consistency invariant of
  data_model.zpp Sections 2 and 11.
\<close>
fun wf_weights :: "layer list \<Rightarrow> shape \<Rightarrow> bool" where
  "wf_weights [] sizes \<longleftrightarrow> length sizes \<le> 1"
| "wf_weights (l # ls) sizes \<longleftrightarrow>
     (case sizes of
        k # m # rest \<Rightarrow> wf_layer l k m \<and> wf_weights ls (m # rest)
      | _ \<Rightarrow> False)"

text \<open>A well-formed network: weights realize the declared shape.\<close>
definition wf_network :: "network \<Rightarrow> bool" where
  "wf_network net \<longleftrightarrow> wf_weights (network_weights net) (network_layers net)"

text \<open>Matrix well-formedness: all rows have length \<open>k\<close> (ragged matrices excluded).\<close>
definition wf_mat :: "mat \<Rightarrow> nat \<Rightarrow> bool" where
  "wf_mat m k \<longleftrightarrow> (\<forall>row \<in> set m. length row = k)"

end
