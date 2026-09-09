(*  Theory:  NN_Modules
    Derived from: docs/data_model.zpp Section 5 (container modules),
    Section 6 (simple layer modules), Section 7 (transfer function
    modules), Section 8 (criterion modules) and Section 10 (table
    layers), as a deep embedding: one recursive datatype for modules
    with a primitive-recursive forward function, and one datatype for
    criterions.
*)

theory NN_Modules
  imports NN_Network NN_Loss
begin

section \<open>Module datatype (data_model.zpp Sections 5-7, 10)\<close>

datatype module =
    Sigmoid                          \<comment> \<open>transfer function (Section 7)\<close>
  | Tanh                             \<comment> \<open>transfer function (Section 7)\<close>
  | ReLU                             \<comment> \<open>transfer function (Section 7)\<close>
  | Softmax                          \<comment> \<open>transfer function (Section 7)\<close>
  | LogSoftmax                       \<comment> \<open>transfer function (Section 7)\<close>
  | Linear mat vec                   \<comment> \<open>simple layer, weights and bias (Section 6)\<close>
  | Identity                         \<comment> \<open>simple layer (Section 6)\<close>
  | Reshape shape                    \<comment> \<open>simple layer (Section 6); pass-through on vectors\<close>
  | Mean nat                         \<comment> \<open>reduction layer (Section 6)\<close>
  | Max nat                          \<comment> \<open>reduction layer (Section 6)\<close>
  | Sequential "module list"         \<comment> \<open>container (Section 5)\<close>
  | Concat nat "module list"         \<comment> \<open>container (Section 5)\<close>

section \<open>Module forward semantics (operations.zpp Section 1)\<close>

text \<open>
  module-forward, defined mutually with the sequential and concat
  folds.  Uses the clamped activations for executability, mirroring
  the siblings.
\<close>
fun module_forward :: "module \<Rightarrow> vec \<Rightarrow> vec"
  and sequential_forward :: "module list \<Rightarrow> vec \<Rightarrow> vec"
  and concat_forward :: "module list \<Rightarrow> vec \<Rightarrow> vec"
where
  "module_forward Sigmoid input = map sigmoid_safe input"
| "module_forward Tanh input = map tanh_activation input"
| "module_forward ReLU input = map relu input"
| "module_forward Softmax input = softmax input"
| "module_forward LogSoftmax input = log_softmax input"
| "module_forward (Linear w b) input = vector_add (matrix_vector_mult w input) b"
| "module_forward Identity input = input"
| "module_forward (Reshape _) input = input"
| "module_forward (Mean _) input = [vector_mean input]"
| "module_forward (Max _) input = [vector_max input]"
| "module_forward (Sequential ms) input = sequential_forward ms input"
| "module_forward (Concat _ ms) input = concat_forward ms input"
| "sequential_forward [] input = input"
| "sequential_forward (m # ms) input =
     sequential_forward ms (module_forward m input)"
| "concat_forward [] input = []"
| "concat_forward (m # ms) input =
     module_forward m input @ concat_forward ms input"

section \<open>Module constructors (sibling user-facing API)\<close>

definition sigmoid_module :: module where "sigmoid_module = Sigmoid"
definition tanh_module :: module where "tanh_module = Tanh"
definition relu_module :: module where "relu_module = ReLU"
definition softmax_module :: module where "softmax_module = Softmax"
definition log_softmax_module :: module where "log_softmax_module = LogSoftmax"
definition make_identity :: module where "make_identity = Identity"

definition make_reshape :: "shape \<Rightarrow> module" where
  "make_reshape sh = Reshape sh"

definition make_mean :: "nat \<Rightarrow> module" where
  "make_mean n = Mean n"

definition make_max :: "nat \<Rightarrow> module" where
  "make_max n = Max n"

definition make_sequential :: "module list \<Rightarrow> module" where
  "make_sequential ms = Sequential ms"

definition make_concat :: "nat \<Rightarrow> module list \<Rightarrow> module" where
  "make_concat n ms = Concat n ms"

text \<open>
  make-linear: a Linear module with deterministically initialized
  weights (input_size columns, output_size rows) and bias.
\<close>
definition make_linear_seeded :: "nat \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> module" where
  "make_linear_seeded input_size output_size s =
     (let (l, s') = make_layer input_size output_size s
      in Linear (map neuron_weights l) (map neuron_bias l))"

definition make_linear :: "nat \<Rightarrow> nat \<Rightarrow> module" where
  "make_linear input_size output_size = make_linear_seeded input_size output_size 42"

section \<open>Criterion datatype and forward (data_model.zpp Section 8)\<close>

datatype criterion =
    MSECriterion
  | ClassNLLCriterion
  | BCECriterion
  | AbsCriterion

text \<open>
  criterion-forward for vector targets.  ClassNLL interprets the first
  component of the target as the class index, matching the tensor-free
  sibling convention.
\<close>
fun criterion_forward :: "criterion \<Rightarrow> vec \<Rightarrow> vec \<Rightarrow> real" where
  "criterion_forward MSECriterion output target = mse_loss output target"
| "criterion_forward ClassNLLCriterion output target =
     class_nll_loss output (nat \<lfloor>hd (target @ [0])\<rfloor>)"
| "criterion_forward BCECriterion output target = bce_loss output target"
| "criterion_forward AbsCriterion output target = abs_loss output target"

text \<open>Convenience wrapper taking the class index directly.\<close>
definition criterion_forward_class :: "criterion \<Rightarrow> vec \<Rightarrow> nat \<Rightarrow> real" where
  "criterion_forward_class c output target =
     (case c of ClassNLLCriterion \<Rightarrow> class_nll_loss output target
              | _ \<Rightarrow> criterion_forward c output [real target])"

definition mse_criterion :: criterion where "mse_criterion = MSECriterion"
definition class_nll_criterion :: criterion where "class_nll_criterion = ClassNLLCriterion"
definition bce_criterion :: criterion where "bce_criterion = BCECriterion"
definition abs_criterion :: criterion where "abs_criterion = AbsCriterion"

end
