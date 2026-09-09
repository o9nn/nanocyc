(*  Theory:  NN_Properties
    The proof payload: the invariants stated throughout the Z++
    specifications (docs/data_model.zpp, docs/system_state.zpp,
    docs/operations.zpp, docs/integrations.zpp), mechanized as Isabelle
    lemmas.  Each lemma cites the spec section it discharges.
*)

theory NN_Properties
  imports NN_Training NN_Modules
begin

section \<open>Activation ranges (data_model.zpp Section 7)\<close>

text \<open>SigmoidModule invariant: \<open>\<forall>i. 0 < output\<^sub>i < 1\<close>.\<close>
lemma sigmoid_range: "0 < sigmoid x \<and> sigmoid x < 1"
proof (intro conjI)
  have den_pos: "0 < 1 + exp (- x)"
    by (simp add: add_pos_pos)
  show "0 < sigmoid x"
    unfolding sigmoid_def using den_pos by simp
  have "1 - 1 / (1 + exp (- x)) = exp (- x) / (1 + exp (- x))"
    using den_pos by (simp add: field_simps)
  moreover have "0 < exp (- x) / (1 + exp (- x))"
    using den_pos by (simp add: divide_pos_pos)
  ultimately have "1 / (1 + exp (- x)) < 1"
    by linarith
  thus "sigmoid x < 1"
    by (simp add: sigmoid_def)
qed

text \<open>The clamped executable variant satisfies the same invariant.\<close>
lemma sigmoid_safe_range: "0 < sigmoid_safe x \<and> sigmoid_safe x < 1"
proof (intro conjI)
  have den_pos: "0 < 1 + exp_safe (- x)"
    using exp_safe_pos[of "- x"] by simp
  show "0 < sigmoid_safe x"
    unfolding sigmoid_safe_def using den_pos by simp
  have "1 - 1 / (1 + exp_safe (- x)) = exp_safe (- x) / (1 + exp_safe (- x))"
    using den_pos by (simp add: field_simps)
  moreover have "0 < exp_safe (- x) / (1 + exp_safe (- x))"
    using den_pos exp_safe_pos[of "- x"] by (simp add: divide_pos_pos)
  ultimately have "1 / (1 + exp_safe (- x)) < 1"
    by linarith
  thus "sigmoid_safe x < 1"
    by (simp add: sigmoid_safe_def)
qed

lemma sigmoid_zero: "sigmoid 0 = 1 / 2"
  by (simp add: sigmoid_def)

text \<open>TanhModule invariant: \<open>\<forall>i. -1 < output\<^sub>i < 1\<close>.\<close>
lemma tanh_range: "-1 < tanh_activation x \<and> tanh_activation x < 1"
  by (simp add: tanh_activation_def tanh_real_lt_1 tanh_real_gt_neg1)

text \<open>ReLUModule invariant: \<open>\<forall>i. output\<^sub>i \<ge> 0\<close>.\<close>
lemma relu_nonneg: "relu x \<ge> 0"
  by (simp add: relu_def)

text \<open>ReLU is the identity on non-negative inputs.\<close>
lemma relu_id_nonneg: "x \<ge> 0 \<Longrightarrow> relu x = x"
  by (simp add: relu_def)

lemma relu_zero_nonpos: "x \<le> 0 \<Longrightarrow> relu x = 0"
  by (simp add: relu_def)

section \<open>Softmax correctness (data_model.zpp Section 7, SoftMaxModule)\<close>

lemma sum_list_pos:
  fixes xs :: "real list"
  assumes "xs \<noteq> []" and "\<forall>x \<in> set xs. 0 < x"
  shows "0 < sum_list xs"
  using assms
proof (induct xs)
  case Nil then show ?case by simp
next
  case (Cons x xs)
  then show ?case
    by (cases xs) (auto intro: add_pos_pos)
qed

lemma sum_list_map_divide:
  fixes s :: real
  shows "sum_list (map (\<lambda>x. x / s) xs) = sum_list xs / s"
  by (induct xs) (auto simp: add_divide_distrib)

text \<open>SoftMaxModule invariant: all components strictly positive.\<close>
lemma softmax_pos:
  assumes "y \<in> set (softmax v)"
  shows "0 < y"
proof -
  let ?shifted = "map (\<lambda>x. x - vector_max v) v"
  let ?exps = "map exp ?shifted"
  have spos: "0 < sum_list ?exps" if "v \<noteq> []"
    using that by (intro sum_list_pos) auto
  from assms obtain e where e: "e \<in> set ?exps" "y = e / sum_list ?exps"
    by (auto simp: softmax_def Let_def vector_max_def split: list.splits)
  moreover from e have "v \<noteq> []" by auto
  ultimately show ?thesis
    using spos by (auto intro!: divide_pos_pos)
qed

lemma softmax_nonneg: "y \<in> set (softmax v) \<Longrightarrow> 0 \<le> y"
  using softmax_pos by (fast intro: less_imp_le)

text \<open>SoftMaxModule invariant: \<open>\<Sigma>\<^sub>i output\<^sub>i = 1\<close> for non-empty input.\<close>
lemma softmax_sums_to_one:
  assumes "v \<noteq> []"
  shows "sum_list (softmax v) = 1"
proof -
  define mx where "mx = vector_max v"
  define shifted where "shifted = map (\<lambda>x. x - mx) v"
  define exps where "exps = map exp shifted"
  have "exps \<noteq> []" using assms by (simp add: exps_def shifted_def)
  moreover have "\<forall>x \<in> set exps. 0 < x" by (auto simp: exps_def)
  ultimately have spos: "0 < sum_list exps" by (rule sum_list_pos)
  have "softmax v = map (\<lambda>e. e / sum_list exps) exps"
    by (simp add: softmax_def Let_def mx_def shifted_def exps_def)
  then have "sum_list (softmax v) = sum_list (map (\<lambda>e. e / sum_list exps) exps)"
    by simp
  also have "\<dots> = sum_list exps / sum_list exps"
    by (rule sum_list_map_divide)
  also have "\<dots> = 1"
    using spos by simp
  finally show ?thesis .
qed

text \<open>LogSoftmax is the logarithm of Softmax.\<close>
lemma log_softmax_eq_ln_softmax:
  assumes "v \<noteq> []"
  shows "log_softmax v = map ln (softmax v)"
proof -
  let ?shifted = "map (\<lambda>x. x - vector_max v) v"
  let ?exps = "map exp ?shifted"
  have "?exps \<noteq> []" using assms by simp
  moreover have "\<forall>x \<in> set ?exps. 0 < x" by auto
  ultimately have spos: "0 < sum_list ?exps" by (rule sum_list_pos)
  have "map ln (softmax v) = map (\<lambda>x. ln (exp x / sum_list ?exps)) ?shifted"
    by (simp add: softmax_def Let_def)
  also have "\<dots> = map (\<lambda>x. x - ln (sum_list ?exps)) ?shifted"
    using spos by (intro map_cong) (auto simp: ln_div)
  also have "\<dots> = log_softmax v"
    by (simp add: log_softmax_def Let_def)
  finally show ?thesis by (rule sym)
qed

text \<open>All LogSoftmax outputs are non-positive (log-probabilities).\<close>
lemma log_softmax_nonpos:
  assumes "y \<in> set (log_softmax v)"
  shows "y \<le> 0"
proof -
  have nonempty: "v \<noteq> []" using assms by (auto simp: log_softmax_def Let_def)
  let ?shifted = "map (\<lambda>x. x - vector_max v) v"
  let ?exps = "map exp ?shifted"
  from assms obtain x where x: "x \<in> set ?shifted" "y = x - ln (sum_list ?exps)"
    by (auto simp: log_softmax_def Let_def)
  have spos: "0 < sum_list ?exps"
    using nonempty by (intro sum_list_pos) auto
  obtain ys zs where split: "?shifted = ys @ x # zs"
    using split_list[OF x(1)] by blast
  have "sum_list ?exps = sum_list (map exp ys) + (exp x + sum_list (map exp zs))"
    by (simp add: split)
  moreover have "0 \<le> sum_list (map exp ys)" "0 \<le> sum_list (map exp zs)"
    by (auto intro!: sum_list_nonneg)
  ultimately have "exp x \<le> sum_list ?exps" by linarith
  then have "x \<le> ln (sum_list ?exps)"
    using spos by (simp add: ln_ge_iff)
  with x(2) show ?thesis by simp
qed

section \<open>Algebraic properties (integrations.zpp Section 1)\<close>

text \<open>Dot product is commutative.\<close>
lemma dot_product_comm: "dot_product v1 v2 = dot_product v2 v1"
proof -
  have "map2 (*) v1 v2 = map2 (*) v2 v1"
  proof (induct v1 arbitrary: v2)
    case Nil
    then show ?case by simp
  next
    case (Cons x xs)
    then show ?case by (cases v2) (auto simp: mult.commute)
  qed
  then show ?thesis by (simp add: dot_product_def)
qed

text \<open>Dot product is linear in its first argument (TensorAdd contract).\<close>
lemma dot_product_add_left:
  assumes "length v1 = length w" and "length v2 = length w"
  shows "dot_product (vector_add v1 v2) w = dot_product v1 w + dot_product v2 w"
  using assms
  unfolding dot_product_def vector_add_def
proof (induct w arbitrary: v1 v2)
  case Nil then show ?case by simp
next
  case (Cons x xs)
  then obtain a as b bs where "v1 = a # as" "v2 = b # bs"
    by (metis length_Suc_conv)
  with Cons show ?case by (simp add: field_simps)
qed

text \<open>Dot product scales with scalar multiplication (ScalarMultiply contract).\<close>
lemma dot_product_scalar_left:
  "dot_product (scalar_mult_vector s v) w = s * dot_product v w"
  unfolding dot_product_def scalar_mult_vector_def
proof (induct v arbitrary: w)
  case Nil then show ?case by simp
next
  case (Cons x xs)
  then show ?case by (cases w) (auto simp: field_simps)
qed

text \<open>A dot product of a vector with itself is non-negative.\<close>
lemma dot_product_self_nonneg: "0 \<le> dot_product v v"
proof -
  have "map2 (*) v v = map (\<lambda>x. x * x) v"
    by (induct v) auto
  moreover have "0 \<le> sum_list (map (\<lambda>x. x * x) v)"
    by (induct v) (auto intro: add_nonneg_nonneg)
  ultimately show ?thesis by (simp add: dot_product_def)
qed

lemma dot_product_self_zero_iff:
  "dot_product v v = 0 \<longleftrightarrow> (\<forall>x \<in> set v. x = 0)"
proof -
  have eq: "map2 (*) v v = map (\<lambda>x. x * x) v"
    by (induct v) auto
  have "sum_list (map (\<lambda>x. x * x) v) = 0 \<longleftrightarrow> (\<forall>x \<in> set v. x = 0)"
  proof (induct v)
    case Nil then show ?case by simp
  next
    case (Cons x xs)
    have nn: "0 \<le> sum_list (map (\<lambda>x. x * x) xs)"
      by (induct xs) (auto intro: add_nonneg_nonneg)
    with Cons show ?case
      by (auto simp: add_nonneg_eq_0_iff)
  qed
  with eq show ?thesis by (simp add: dot_product_def)
qed

subsection \<open>Transpose (integrations.zpp Section 1, Transpose contract)\<close>

text \<open>Entry-wise characterization: \<open>result(i, j) = m(j, i)\<close>.\<close>
lemma nth_transpose_matrix:
  assumes "wf_mat m k" "m \<noteq> []" "i < k" "j < length m"
  shows "transpose_matrix m ! i ! j = m ! j ! i"
  using assms
proof (induct m arbitrary: i j k rule: transpose_matrix.induct)
  case 1 then show ?case by simp
next
  case 2 then show ?case by (simp add: wf_mat_def)
next
  case (3 x xs rest)
  from 3(2) have kx: "k = Suc (length xs)"
    by (simp add: wf_mat_def)
  have rows: "\<forall>row \<in> set rest. length row = Suc (length xs)"
    using 3(2) by (auto simp: wf_mat_def kx)
  show ?case
  proof (cases i)
    case 0
    show ?thesis
    proof (cases j)
      case 0 with \<open>i = 0\<close> show ?thesis by simp
    next
      case (Suc j')
      with 3(5) have j': "j' < length rest" by simp
      have lenj: "length (rest ! j') = Suc (length xs)"
        using rows j' by (auto dest: nth_mem)
      then obtain r0 rs where "rest ! j' = r0 # rs"
        by (cases "rest ! j'") auto
      then have "hd (rest ! j') = rest ! j' ! 0"
        by simp
      with \<open>i = 0\<close> Suc j' show ?thesis by simp
    qed
  next
    case (Suc i')
    have wf': "wf_mat (xs # map tl rest) (length xs)"
      using rows by (auto simp: wf_mat_def)
    have i': "i' < length xs" using Suc 3(4) kx by simp
    have j2: "j < length (xs # map tl rest)" using 3(5) by simp
    have IH: "transpose_matrix (xs # map tl rest) ! i' ! j =
              (xs # map tl rest) ! j ! i'"
      using 3(1)[OF wf' _ i' j2] by simp
    show ?thesis
    proof (cases j)
      case 0 with Suc IH show ?thesis by simp
    next
      case (Suc j')
      with 3(5) have jr: "j' < length rest" by simp
      then have lenrow: "length (rest ! j') = Suc (length xs)"
        using rows by (auto dest: nth_mem)
      have bound: "i' < length (tl (rest ! j'))"
        using lenrow i' by simp
      have "tl (rest ! j') ! i' = rest ! j' ! Suc i'"
        by (rule nth_tl[OF bound])
      with \<open>i = Suc i'\<close> Suc IH jr show ?thesis by simp
    qed
  qed
qed

text \<open>Transpose is an involution on non-empty rectangular matrices.\<close>
lemma transpose_matrix_involution:
  assumes "wf_mat m k" "m \<noteq> []" "k > 0"
  shows "transpose_matrix (transpose_matrix m) = m"
proof -
  have lt: "length (transpose_matrix m) = k"
    by (rule length_transpose_matrix[OF assms(1) assms(2)])
  have wt: "wf_mat (transpose_matrix m) (length m)"
    using transpose_matrix_row_lengths[OF assms(1)] by (simp add: wf_mat_def)
  have net: "transpose_matrix m \<noteq> []"
    using lt assms(3) by auto
  have ltt: "length (transpose_matrix (transpose_matrix m)) = length m"
    using length_transpose_matrix[OF wt net] .
  show ?thesis
  proof (rule nth_equalityI)
    show "length (transpose_matrix (transpose_matrix m)) = length m"
      by (fact ltt)
  next
    fix j assume j: "j < length (transpose_matrix (transpose_matrix m))"
    then have jm: "j < length m" using ltt by simp
    have rowlen: "length (transpose_matrix (transpose_matrix m) ! j) =
                  length (transpose_matrix m)"
      using transpose_matrix_row_lengths[OF wt] j by (auto dest: nth_mem)
    have mrow: "length (m ! j) = k"
      using assms(1) jm by (auto simp: wf_mat_def dest: nth_mem)
    show "transpose_matrix (transpose_matrix m) ! j = m ! j"
    proof (rule nth_equalityI)
      show "length (transpose_matrix (transpose_matrix m) ! j) = length (m ! j)"
        using rowlen lt mrow by simp
    next
      fix i assume "i < length (transpose_matrix (transpose_matrix m) ! j)"
      then have i: "i < k" using rowlen lt by simp
      have "transpose_matrix (transpose_matrix m) ! j ! i =
            transpose_matrix m ! i ! j"
        using nth_transpose_matrix[OF wt net jm] i lt by simp
      also have "\<dots> = m ! j ! i"
        using nth_transpose_matrix[OF assms(1) assms(2) i jm] .
      finally show "transpose_matrix (transpose_matrix m) ! j ! i = m ! j ! i" .
    qed
  qed
qed

text \<open>Matrix-vector dimension contract (MatrixMultiply schema).\<close>
lemma matrix_vector_mult_dim:
  "length (matrix_vector_mult m v) = length m"
  by simp

section \<open>Shape preservation (data_model.zpp Sections 2, 11; operations.zpp Section 1)\<close>

text \<open>Layer output length equals neuron count.\<close>
lemma layer_output_length: "length (layer_output l input f) = length l"
  by simp

text \<open>
  Forward propagation through a well-formed network yields output of
  the declared final layer size (CompleteForwardPass contract).
\<close>
lemma forward_propagate_length:
  assumes "wf_weights ws sizes" and "ws \<noteq> []"
  shows "length (forward_propagate input ws) = last sizes"
  using assms
proof (induct ws arbitrary: sizes input)
  case Nil then show ?case by simp
next
  case (Cons l ls)
  from Cons.prems obtain k m rest where sz: "sizes = k # m # rest"
    and wfl: "wf_layer l k m" and wfls: "wf_weights ls (m # rest)"
    by (cases sizes; cases "tl sizes") auto
  show ?case
  proof (cases ls)
    case Nil
    with wfls have "rest = []" by (cases rest) auto
    with Nil sz wfl show ?thesis
      by (simp add: wf_layer_def)
  next
    case (Cons l' ls')
    then have "ls \<noteq> []" by simp
    from Cons.hyps[OF wfls this] sz show ?thesis
      by simp
  qed
qed

lemma forward_length:
  assumes "wf_network net" and "network_weights net \<noteq> []"
  shows "length (forward input net) = last (network_layers net)"
  using assms
  by (simp add: forward_def wf_network_def forward_propagate_length)

subsection \<open>Module shape preservation\<close>

text \<open>
  Well-formedness of modules: \<open>module_wf m k n\<close> states that module
  \<open>m\<close> maps size-\<open>k\<close> inputs to size-\<open>n\<close> outputs (the deep-embedding
  rendering of the shape contracts of data_model.zpp Sections 5-7).
\<close>
inductive module_wf :: "module \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool"
  and seq_wf :: "module list \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool"
  and concat_wf :: "module list \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool"
where
  wf_Sigmoid: "module_wf Sigmoid k k"
| wf_Tanh: "module_wf Tanh k k"
| wf_ReLU: "module_wf ReLU k k"
| wf_Softmax: "module_wf Softmax k k"
| wf_LogSoftmax: "module_wf LogSoftmax k k"
| wf_Identity: "module_wf Identity k k"
| wf_Reshape: "module_wf (Reshape sh) k k"
| wf_Mean: "module_wf (Mean d) k 1"
| wf_Max: "module_wf (Max d) k 1"
| wf_Linear: "wf_mat w k \<Longrightarrow> length w = m \<Longrightarrow> length b = m \<Longrightarrow>
              module_wf (Linear w b) k m"
| wf_Sequential: "seq_wf ms k n \<Longrightarrow> module_wf (Sequential ms) k n"
| wf_Concat: "concat_wf ms k n \<Longrightarrow> module_wf (Concat d ms) k n"
| seq_Nil: "seq_wf [] k k"
| seq_Cons: "module_wf m k j \<Longrightarrow> seq_wf ms j n \<Longrightarrow> seq_wf (m # ms) k n"
| concat_Nil: "concat_wf [] k 0"
| concat_Cons: "module_wf m k j \<Longrightarrow> concat_wf ms k n \<Longrightarrow>
                concat_wf (m # ms) k (j + n)"

text \<open>
  SequentialForward shape contract (operations.zpp Section 1): forward
  through a well-formed module yields output of the declared size.
\<close>
lemma module_forward_length:
  shows "module_wf m k n \<Longrightarrow> length input = k \<Longrightarrow>
           length (module_forward m input) = n"
    and "seq_wf ms k n \<Longrightarrow> length input = k \<Longrightarrow>
           length (sequential_forward ms input) = n"
    and "concat_wf ms k n \<Longrightarrow> length input = k \<Longrightarrow>
           length (concat_forward ms input) = n"
proof (induct arbitrary: input and input and input
       rule: module_wf_seq_wf_concat_wf.inducts)
  case (wf_Linear w k m b)
  then show ?case
    by (simp add: vector_add_def)
qed auto

section \<open>Loss properties (operations.zpp Section 2)\<close>

text \<open>MSEForward invariant: \<open>loss \<ge> 0\<close>.\<close>
lemma mse_loss_nonneg: "0 \<le> mse_loss output target"
  unfolding mse_loss_def Let_def
  by (intro divide_nonneg_nonneg dot_product_self_nonneg) simp

text \<open>MSE is zero exactly when prediction equals target (equal lengths).\<close>
lemma mse_loss_zero_iff:
  assumes "length output = length target"
  shows "mse_loss output target = 0 \<longleftrightarrow> output = target"
proof
  assume "mse_loss output target = 0"
  then have "dot_product (vector_sub output target) (vector_sub output target) = 0
             \<or> length output = 0"
    unfolding mse_loss_def Let_def by (auto simp: divide_eq_0_iff)
  then show "output = target"
  proof
    assume "dot_product (vector_sub output target) (vector_sub output target) = 0"
    then have allzero: "\<forall>x \<in> set (vector_sub output target). x = 0"
      by (simp add: dot_product_self_zero_iff)
    show "output = target"
    proof (rule nth_equalityI)
      show "length output = length target" by (fact assms)
    next
      fix i assume i: "i < length output"
      have len_sub: "length (vector_sub output target) = length output"
        using assms by (simp add: vector_sub_def)
      with assms i have "vector_sub output target ! i = output ! i - target ! i"
        by (simp add: vector_sub_def)
      moreover have "vector_sub output target ! i \<in> set (vector_sub output target)"
        using i len_sub by (simp add: nth_mem)
      ultimately show "output ! i = target ! i"
        using allzero by auto
    qed
  next
    assume "length output = 0"
    with assms show "output = target" by simp
  qed
next
  assume eq: "output = target"
  have zeros: "map2 (-) xs xs = map (\<lambda>_. 0) xs" for xs :: "real list"
    by (induct xs) auto
  have "vector_sub output target = map (\<lambda>_. 0) output"
    using eq by (simp add: vector_sub_def zeros)
  moreover have "dot_product (map (\<lambda>_. 0) output) (map (\<lambda>_. 0) output) = 0"
    by (simp add: dot_product_self_zero_iff)
  ultimately show "mse_loss output target = 0"
    by (simp add: mse_loss_def Let_def)
qed

text \<open>AbsCriterion invariant: \<open>loss \<ge> 0\<close>.\<close>
lemma abs_loss_nonneg: "0 \<le> abs_loss output target"
  unfolding abs_loss_def
  by (auto intro!: sum_list_nonneg)

section \<open>Derivative correctness (integrations.zpp Section 2)\<close>

text \<open>
  The claimed sigmoid derivative is the analytic derivative:
  \<open>\<sigma>'(x) = \<sigma>(x) (1 - \<sigma>(x))\<close>.
\<close>
lemma sigmoid_has_derivative:
  "(sigmoid has_real_derivative sigmoid_derivative x) (at x)"
proof -
  have nz: "1 + exp (- x) \<noteq> 0"
    by (metis add_pos_pos exp_gt_zero less_numeral_extra(1) order_less_irrefl)
  have deriv: "((\<lambda>y. 1 / (1 + exp (- y))) has_real_derivative
                exp (- x) / (1 + exp (- x))\<^sup>2) (at x)"
    using nz by (auto intro!: derivative_eq_intros simp: power2_eq_square)
  have "exp (- x) / (1 + exp (- x))\<^sup>2 = sigmoid x * (1 - sigmoid x)"
    using nz by (simp add: sigmoid_def power2_eq_square field_simps)
  with deriv show ?thesis
    by (simp add: sigmoid_def [abs_def] sigmoid_derivative_def)
qed

text \<open>The claimed tanh derivative is the analytic derivative: \<open>1 - tanh(x)\<^sup>2\<close>.\<close>
lemma tanh_has_derivative:
  "(tanh_activation has_real_derivative tanh_derivative x) (at x)"
  unfolding tanh_activation_def [abs_def] tanh_derivative_def
  by (auto intro!: derivative_eq_intros)

text \<open>MSE derivative correctness in the scalar case: \<open>d/dy (y - t)\<^sup>2 = 2 (y - t)\<close>.\<close>
lemma mse_loss_derivative_correct_1d:
  "((\<lambda>y. mse_loss [y] [t]) has_real_derivative
    hd (mse_loss_derivative [y] [t])) (at y)"
proof -
  have eq: "(\<lambda>y. mse_loss [y] [t]) = (\<lambda>y. (y - t) * (y - t))"
    by (simp add: mse_loss_def vector_sub_def dot_product_def Let_def)
  have "hd (mse_loss_derivative [y] [t]) = 2 * (y - t)"
    by (simp add: mse_loss_derivative_def vector_sub_def scalar_mult_vector_def)
  moreover have "((\<lambda>y. (y - t) * (y - t)) has_real_derivative 2 * (y - t)) (at y)"
    by (auto intro!: derivative_eq_intros simp: field_simps)
  ultimately show ?thesis by (simp add: eq)
qed

text \<open>Component-wise closed form of the MSE gradient (MSEBackward schema).\<close>
lemma mse_loss_derivative_nth:
  assumes "i < length output" and "i < length target"
  shows "mse_loss_derivative output target ! i =
         2 / real (length output) * (output ! i - target ! i)"
  using assms
  by (simp add: mse_loss_derivative_def scalar_mult_vector_def vector_sub_def)

section \<open>Training preserves structure (system_state.zpp Section 5)\<close>

text \<open>Topology is invariant under training (restated from NN_Training).\<close>
lemmas training_topology_invariants =
  train_step_preserves_layers
  train_epoch_preserves_layers
  train_preserves_layers

text \<open>Updating a neuron preserves its weight count when input size matches.\<close>
lemma update_neuron_weights_wf:
  assumes "wf_neuron n k" and "length input = k"
  shows "wf_neuron (update_neuron_weights n input delta lr) k"
  using assms
  by (simp add: update_neuron_weights_def wf_neuron_def neuron_weights_def Let_def)

text \<open>Updating a layer preserves its shape when the deltas cover the layer.\<close>
lemma update_layer_weights_wf:
  assumes "wf_layer l k m" and "length input = k" and "length deltas \<ge> m"
  shows "wf_layer (update_layer_weights l input deltas lr) k m"
proof -
  have len: "length (update_layer_weights l input deltas lr) = m"
    using assms by (simp add: wf_layer_def)
  have "\<forall>n \<in> set (update_layer_weights l input deltas lr). wf_neuron n k"
  proof
    fix n' assume "n' \<in> set (update_layer_weights l input deltas lr)"
    then obtain n d where "n \<in> set l"
      and n': "n' = update_neuron_weights n input d lr"
      unfolding update_layer_weights_def
      by (auto dest!: set_zip_leftD elim!: in_set_zipE)
    with assms show "wf_neuron n' k"
      by (auto simp: wf_layer_def intro: update_neuron_weights_wf)
  qed
  with len show ?thesis by (simp add: wf_layer_def)
qed

end
