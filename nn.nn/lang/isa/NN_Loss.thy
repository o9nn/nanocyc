(*  Theory:  NN_Loss
    Derived from: docs/data_model.zpp Section 8 (criterion/loss modules)
    and docs/operations.zpp Section 2 (loss computation).
*)

theory NN_Loss
  imports NN_Vector
begin

section \<open>Mean Squared Error (MSECriterion; operations.zpp MSEForward)\<close>

text \<open>\<open>MSE(o, t) = (\<Sigma>\<^sub>i (o\<^sub>i - t\<^sub>i)\<^sup>2) / n\<close> where \<open>n = length o\<close>.\<close>
definition mse_loss :: "vec \<Rightarrow> vec \<Rightarrow> real" where
  "mse_loss output target =
     (let diff = vector_sub output target
      in dot_product diff diff / real (length output))"

text \<open>\<open>\<partial>MSE/\<partial>o = (2/n) \<cdot> (o - t)\<close> (operations.zpp MSEBackward).\<close>
definition mse_loss_derivative :: "vec \<Rightarrow> vec \<Rightarrow> vec" where
  "mse_loss_derivative output target =
     scalar_mult_vector (2 / real (length output)) (vector_sub output target)"

lemma length_mse_loss_derivative [simp]:
  "length (mse_loss_derivative output target) = min (length output) (length target)"
  by (simp add: mse_loss_derivative_def)

section \<open>Class Negative Log Likelihood (ClassNLLCriterion)\<close>

text \<open>
  \<open>ClassNLL(o, c) = - o\<^sub>c\<close> where \<open>o\<close> holds log-probabilities and \<open>c\<close>
  is the target class index (operations.zpp ClassNLLForward).
\<close>
definition class_nll_loss :: "vec \<Rightarrow> nat \<Rightarrow> real" where
  "class_nll_loss output target =
     (if target < length output then - output ! target else 0)"

section \<open>Binary Cross Entropy (BCECriterion)\<close>

text \<open>
  \<open>BCE(o, t) = - \<Sigma>\<^sub>i (t\<^sub>i ln(o\<^sub>i + \<epsilon>) + (1 - t\<^sub>i) ln(1 - o\<^sub>i + \<epsilon>))\<close>
  with \<open>\<epsilon> = 10\<^sup>-\<^sup>7\<close> for numerical stability (integrations.zpp Section 6).
\<close>
definition bce_epsilon :: real where
  "bce_epsilon = 1 / 10000000"

definition bce_loss :: "vec \<Rightarrow> vec \<Rightarrow> real" where
  "bce_loss output target =
     - sum_list (map2 (\<lambda>out tgt. tgt * ln (out + bce_epsilon) +
                                 (1 - tgt) * ln (1 - out + bce_epsilon))
                 output target)"

section \<open>Absolute Error (AbsCriterion, L1)\<close>

definition abs_loss :: "vec \<Rightarrow> vec \<Rightarrow> real" where
  "abs_loss output target = sum_list (map abs (vector_sub output target))"

end
