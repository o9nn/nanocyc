(*  Theory:  NN_Vector
    Derived from: docs/integrations.zpp Section 1 (tensor operation
    contracts) and the sibling vector operations in lang/scm/nn.scm,
    lang/rkt/nn.rkt and lang/raku/NN.rakumod.
*)

theory NN_Vector
  imports NN_Types
begin

section \<open>Element-wise maps\<close>

text \<open>vector-map and vector-map2 from the siblings.\<close>

definition vector_map :: "(real \<Rightarrow> real) \<Rightarrow> vec \<Rightarrow> vec" where
  "vector_map f v = map f v"

definition vector_map2 :: "(real \<Rightarrow> real \<Rightarrow> real) \<Rightarrow> vec \<Rightarrow> vec \<Rightarrow> vec" where
  "vector_map2 f v1 v2 = map2 f v1 v2"

section \<open>Vector arithmetic (integrations.zpp Section 1)\<close>

text \<open>dot-product: \<open>\<Sigma>\<^sub>i v1\<^sub>i \<times> v2\<^sub>i\<close>\<close>
definition dot_product :: "vec \<Rightarrow> vec \<Rightarrow> real" where
  "dot_product v1 v2 = sum_list (map2 (*) v1 v2)"

text \<open>TensorAdd contract: element-wise addition.\<close>
definition vector_add :: "vec \<Rightarrow> vec \<Rightarrow> vec" where
  "vector_add v1 v2 = map2 (+) v1 v2"

text \<open>Element-wise subtraction \<open>v1 - v2\<close>.\<close>
definition vector_sub :: "vec \<Rightarrow> vec \<Rightarrow> vec" where
  "vector_sub v1 v2 = map2 (-) v1 v2"

text \<open>ScalarMultiply contract: \<open>s \<cdot> v\<close>.\<close>
definition scalar_mult_vector :: "real \<Rightarrow> vec \<Rightarrow> vec" where
  "scalar_mult_vector s v = map ((*) s) v"

section \<open>Reductions\<close>

definition vector_sum :: "vec \<Rightarrow> real" where
  "vector_sum v = sum_list v"

definition vector_mean :: "vec \<Rightarrow> real" where
  "vector_mean v = vector_sum v / real (length v)"

text \<open>Maximum element; 0 for the empty vector (total function).\<close>
definition vector_max :: "vec \<Rightarrow> real" where
  "vector_max v = (case v of [] \<Rightarrow> 0 | x # xs \<Rightarrow> fold max xs x)"

section \<open>Basic length lemmas (shape contracts of integrations.zpp Section 1)\<close>

lemma length_vector_map [simp]: "length (vector_map f v) = length v"
  by (simp add: vector_map_def)

lemma length_vector_map2 [simp]:
  "length (vector_map2 f v1 v2) = min (length v1) (length v2)"
  by (simp add: vector_map2_def)

lemma length_vector_add [simp]:
  "length (vector_add v1 v2) = min (length v1) (length v2)"
  by (simp add: vector_add_def)

lemma length_vector_sub [simp]:
  "length (vector_sub v1 v2) = min (length v1) (length v2)"
  by (simp add: vector_sub_def)

lemma length_scalar_mult_vector [simp]:
  "length (scalar_mult_vector s v) = length v"
  by (simp add: scalar_mult_vector_def)

end
