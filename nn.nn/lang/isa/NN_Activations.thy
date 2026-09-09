(*  Theory:  NN_Activations
    Derived from: docs/data_model.zpp Section 7 (transfer function
    modules) and docs/integrations.zpp Section 2 (mathematical function
    contracts).

    All functions are defined over exact reals; executability for demos
    and tests is provided by the exact-rational approximation layer in
    NN_Exec (keeping the proof theories float-free).
*)

theory NN_Activations
  imports NN_Vector
begin

section \<open>Safe exponential (integrations.zpp Section 6, numerical stability)\<close>

text \<open>
  The siblings clamp the argument of \<open>exp\<close> to \<open>[-20, 20]\<close> to avoid
  overflow.  We mirror that behaviour exactly.
\<close>
definition exp_safe :: "real \<Rightarrow> real" where
  "exp_safe x = (if x > 20 then exp 20 else if x < -20 then exp (-20) else exp x)"

lemma exp_safe_pos: "exp_safe x > 0"
  by (simp add: exp_safe_def)

section \<open>Sigmoid (data_model.zpp Section 7: SigmoidModule)\<close>

text \<open>\<open>\<sigma>(x) = 1 / (1 + e\<^sup>-\<^sup>x)\<close>.  The exact mathematical definition used for proofs.\<close>
definition sigmoid :: "real \<Rightarrow> real" where
  "sigmoid x = 1 / (1 + exp (- x))"

text \<open>Clamped variant used by the executable forward pass, as in the siblings.\<close>
definition sigmoid_safe :: "real \<Rightarrow> real" where
  "sigmoid_safe x = 1 / (1 + exp_safe (- x))"

text \<open>\<open>\<sigma>'(x) = \<sigma>(x) \<cdot> (1 - \<sigma>(x))\<close> (integrations.zpp Section 2).\<close>
definition sigmoid_derivative :: "real \<Rightarrow> real" where
  "sigmoid_derivative x = sigmoid x * (1 - sigmoid x)"

section \<open>Tanh (data_model.zpp Section 7: TanhModule)\<close>

definition tanh_activation :: "real \<Rightarrow> real" where
  "tanh_activation x = tanh x"

text \<open>\<open>tanh'(x) = 1 - tanh(x)\<^sup>2\<close>.\<close>
definition tanh_derivative :: "real \<Rightarrow> real" where
  "tanh_derivative x = 1 - (tanh x)\<^sup>2"

section \<open>ReLU (data_model.zpp Section 7: ReLUModule)\<close>

definition relu :: "real \<Rightarrow> real" where
  "relu x = max 0 x"

definition relu_derivative :: "real \<Rightarrow> real" where
  "relu_derivative x = (if x > 0 then 1 else 0)"

section \<open>Softmax and LogSoftmax (data_model.zpp Section 7)\<close>

text \<open>
  Numerically stable softmax: subtract the maximum before exponentiating
  (integrations.zpp Section 6), exactly as the siblings do.
\<close>
definition softmax :: "vec \<Rightarrow> vec" where
  "softmax v =
     (let mx = vector_max v;
          shifted = map (\<lambda>x. x - mx) v;
          exps = map exp shifted;
          s = sum_list exps
      in map (\<lambda>e. e / s) exps)"

text \<open>\<open>log-softmax(x)\<^sub>i = (x\<^sub>i - max) - ln (\<Sigma>\<^sub>j e\<^sup>x\<^sup>j\<^sup>-\<^sup>m\<^sup>a\<^sup>x)\<close>.\<close>
definition log_softmax :: "vec \<Rightarrow> vec" where
  "log_softmax v =
     (let mx = vector_max v;
          shifted = map (\<lambda>x. x - mx) v;
          exps = map exp shifted;
          s = sum_list exps
      in map (\<lambda>x. x - ln s) shifted)"

lemma length_softmax [simp]: "length (softmax v) = length v"
  by (simp add: softmax_def Let_def)

lemma length_log_softmax [simp]: "length (log_softmax v) = length v"
  by (simp add: log_softmax_def Let_def)

end
