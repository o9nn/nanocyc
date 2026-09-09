(*  Theory:  NN_Exec
    Executable rational approximation layer.

    The exact library definitions use \<open>exp\<close>, \<open>ln\<close> and \<open>tanh\<close> on \<open>real\<close>,
    which are not executable.  This theory provides executable mirrors
    (suffix \<open>_exec\<close>) built from truncated Taylor / artanh series over
    exact rational arithmetic, so that demos and regression tests can
    run with \<open>value\<close> and \<open>eval\<close> without importing the (logically
    inconsistent) float-approximation code setup.

    Intermediate results are rounded to denominator \<open>10\<^sup>1\<^sup>2\<close> to keep
    rational sizes bounded, mirroring the finite precision of the
    sibling float implementations (integrations.zpp Section 6).
    The proof theories (NN_Properties) are exclusively about the exact
    definitions and are unaffected by this layer.
*)

theory NN_Exec
  imports NN_Training NN_Modules "HOL-Library.Code_Target_Numeral"
begin

section \<open>Rounding to bounded-denominator rationals\<close>

definition round_approx :: "real \<Rightarrow> real" where
  "round_approx x = real_of_int \<lfloor>x * 1000000000000\<rfloor> / 1000000000000"

text \<open>Round to a small number of decimals, for readable demo output.\<close>
definition round_to :: "nat \<Rightarrow> real \<Rightarrow> real" where
  "round_to d x = real_of_int \<lfloor>x * 10 ^ d + 1/2\<rfloor> / 10 ^ d"

section \<open>Exponential: Taylor series with argument halving\<close>

text \<open>\<open>exp_series n x = \<Sigma>\<^sub>i\<^sub>\<le>\<^sub>n x\<^sup>i / i!\<close>.\<close>
fun exp_series :: "nat \<Rightarrow> real \<Rightarrow> real" where
  "exp_series 0 x = 1"
| "exp_series (Suc n) x = exp_series n x + x ^ Suc n / fact (Suc n)"

text \<open>Square \<open>n\<close> times, rounding after each step.\<close>
fun square_n :: "nat \<Rightarrow> real \<Rightarrow> real" where
  "square_n 0 x = x"
| "square_n (Suc n) x = square_n n (round_approx (x * x))"

text \<open>
  \<open>exp x \<approx> (exp (x/256))\<^sup>2\<^sup>5\<^sup>6\<close>: 15 Taylor terms at \<open>|x|/256 \<le> 0.16\<close>
  followed by 8 squarings.  Accurate to \<open>\<approx> 10\<^sup>-\<^sup>1\<^sup>1\<close> relative error on
  \<open>[-40, 40]\<close>.
\<close>
definition exp_approx_raw :: "real \<Rightarrow> real" where
  "exp_approx_raw x = square_n 8 (exp_series 15 (round_approx x / 256))"

text \<open>Executable mirror of \<open>exp_safe\<close>: clamp the argument to \<open>[-20, 20]\<close>.\<close>
definition exp_approx :: "real \<Rightarrow> real" where
  "exp_approx x =
     (if x > 20 then exp_approx_raw 20
      else if x < -20 then exp_approx_raw (-20)
      else exp_approx_raw x)"

section \<open>Natural logarithm: artanh series with base-2 normalization\<close>

text \<open>\<open>atanh_sum n t = \<Sigma>\<^sub>k\<^sub>\<le>\<^sub>n t\<^sup>2\<^sup>k\<^sup>+\<^sup>1 / (2k+1)\<close>, so \<open>ln x = 2 \<cdot> atanh ((x-1)/(x+1))\<close>.\<close>
fun atanh_sum :: "nat \<Rightarrow> real \<Rightarrow> real" where
  "atanh_sum 0 t = t"
| "atanh_sum (Suc n) t =
     atanh_sum n t + t ^ (2 * Suc n + 1) / real (2 * Suc n + 1)"

definition ln2_approx :: real where
  "ln2_approx = round_approx (2 * atanh_sum 14 (1 / 3))"

text \<open>Bring \<open>x\<close> into \<open>[2/3, 4/3]\<close> by doubling, counting the shift.\<close>
fun ln_norm_up :: "nat \<Rightarrow> real \<Rightarrow> real \<times> int" where
  "ln_norm_up 0 x = (x, 0)"
| "ln_norm_up (Suc n) x =
     (if x < 2/3 then (let (m, e) = ln_norm_up n (2 * x) in (m, e - 1))
      else (x, 0))"

text \<open>Bring \<open>x\<close> into \<open>[2/3, 4/3]\<close> by halving, counting the shift.\<close>
fun ln_norm_down :: "nat \<Rightarrow> real \<Rightarrow> real \<times> int" where
  "ln_norm_down 0 x = (x, 0)"
| "ln_norm_down (Suc n) x =
     (if x > 4/3 then (let (m, e) = ln_norm_down n (x / 2) in (m, e + 1))
      else (x, 0))"

text \<open>
  \<open>ln x = e \<cdot> ln 2 + 2 \<cdot> atanh ((m-1)/(m+1))\<close> for \<open>x = m \<cdot> 2\<^sup>e\<close>,
  \<open>m \<in> [2/3, 4/3]\<close>.  Total on non-positive input (returns 0), matching
  HOL's total \<open>ln\<close>.
\<close>
definition ln_approx :: "real \<Rightarrow> real" where
  "ln_approx x =
     (if x \<le> 0 then 0
      else (let (m, e) = (if x > 4/3 then ln_norm_down 2000 x
                          else ln_norm_up 2000 x);
                t = round_approx ((m - 1) / (m + 1))
            in round_approx (of_int e * ln2_approx + 2 * atanh_sum 14 t)))"

section \<open>Executable activations\<close>

text \<open>Mirror of \<open>sigmoid_safe\<close>.\<close>
definition sigmoid_exec :: "real \<Rightarrow> real" where
  "sigmoid_exec x = round_approx (1 / (1 + exp_approx (- x)))"

definition sigmoid_derivative_exec :: "real \<Rightarrow> real" where
  "sigmoid_derivative_exec x = (let s = sigmoid_exec x in s * (1 - s))"

text \<open>Mirror of \<open>tanh_activation\<close>: \<open>tanh x = (e\<^sup>2\<^sup>x - 1) / (e\<^sup>2\<^sup>x + 1)\<close>.\<close>
definition tanh_exec :: "real \<Rightarrow> real" where
  "tanh_exec x =
     (if x > 20 then 1
      else if x < -20 then -1
      else (let e = exp_approx_raw (2 * x)
            in round_approx ((e - 1) / (e + 1))))"

definition tanh_derivative_exec :: "real \<Rightarrow> real" where
  "tanh_derivative_exec x = (let t = tanh_exec x in 1 - t * t)"

definition relu_exec :: "real \<Rightarrow> real" where
  "relu_exec x = relu x"

text \<open>Mirror of \<open>softmax\<close> (max-subtracted, clamped exponential).\<close>
definition softmax_exec :: "vec \<Rightarrow> vec" where
  "softmax_exec v =
     (let mx = vector_max v;
          shifted = map (\<lambda>x. x - mx) v;
          exps = map exp_approx shifted;
          s = sum_list exps
      in map (\<lambda>e. round_approx (e / s)) exps)"

text \<open>Mirror of \<open>log_softmax\<close>.\<close>
definition log_softmax_exec :: "vec \<Rightarrow> vec" where
  "log_softmax_exec v =
     (let mx = vector_max v;
          shifted = map (\<lambda>x. x - mx) v;
          exps = map exp_approx shifted;
          s = sum_list exps
      in map (\<lambda>x. round_approx (x - ln_approx s)) shifted)"

lemma length_softmax_exec [simp]: "length (softmax_exec v) = length v"
  by (simp add: softmax_exec_def Let_def)

lemma length_log_softmax_exec [simp]: "length (log_softmax_exec v) = length v"
  by (simp add: log_softmax_exec_def Let_def)

section \<open>Executable losses\<close>

text \<open>Mirror of \<open>bce_loss\<close>.\<close>
definition bce_exec :: "vec \<Rightarrow> vec \<Rightarrow> real" where
  "bce_exec output target =
     - sum_list (map2 (\<lambda>out tgt. tgt * ln_approx (out + bce_epsilon) +
                                 (1 - tgt) * ln_approx (1 - out + bce_epsilon))
                 output target)"

text \<open>
  Executable criterion dispatch: MSE, ClassNLL and Abs are already
  executable exactly; BCE uses the approximated logarithm.
\<close>
fun criterion_forward_exec :: "criterion \<Rightarrow> vec \<Rightarrow> vec \<Rightarrow> real" where
  "criterion_forward_exec MSECriterion output target = mse_loss output target"
| "criterion_forward_exec ClassNLLCriterion output target =
     class_nll_loss output (nat \<lfloor>hd (target @ [0])\<rfloor>)"
| "criterion_forward_exec BCECriterion output target = bce_exec output target"
| "criterion_forward_exec AbsCriterion output target = abs_loss output target"

section \<open>Executable forward pass\<close>

definition layer_output_exec :: "layer \<Rightarrow> vec \<Rightarrow> vec" where
  "layer_output_exec l input = layer_output l input sigmoid_exec"

fun forward_propagate_exec :: "vec \<Rightarrow> layer list \<Rightarrow> vec" where
  "forward_propagate_exec input [] = input"
| "forward_propagate_exec input (l # ls) =
     forward_propagate_exec (layer_output_exec l input) ls"

definition forward_exec :: "vec \<Rightarrow> network \<Rightarrow> vec" where
  "forward_exec input net = forward_propagate_exec input (network_weights net)"

definition predict_exec :: "vec \<Rightarrow> network \<Rightarrow> vec" where
  "predict_exec input net = forward_exec input net"

lemma length_forward_propagate_exec:
  assumes "wf_weights ws sizes" and "ws \<noteq> []"
  shows "length (forward_propagate_exec input ws) = last sizes"
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
      by (simp add: wf_layer_def layer_output_exec_def)
  next
    case (Cons l' ls')
    then have "ls \<noteq> []" by simp
    from Cons.hyps[OF wfls this] sz show ?thesis
      by simp
  qed
qed

section \<open>Executable training\<close>

fun compute_layer_activations_exec :: "vec \<Rightarrow> layer list \<Rightarrow> vec list" where
  "compute_layer_activations_exec input [] = [input]"
| "compute_layer_activations_exec input (l # ls) =
     input # compute_layer_activations_exec (layer_output_exec l input) ls"

definition output_deltas_exec :: "vec \<Rightarrow> vec \<Rightarrow> vec" where
  "output_deltas_exec loss_grad pre_activations =
     map2 (\<lambda>g z. g * sigmoid_derivative_exec z) loss_grad pre_activations"

text \<open>SGD update with weight rounding to keep rational sizes bounded.\<close>
definition update_neuron_weights_exec :: "neuron \<Rightarrow> vec \<Rightarrow> real \<Rightarrow> real \<Rightarrow> neuron" where
  "update_neuron_weights_exec n input delta lr =
     (let ws = neuron_weights n;
          b = neuron_bias n;
          wdeltas = map (\<lambda>x. lr * delta * x) input;
          ws' = map2 (\<lambda>w d. round_approx (w - d)) ws wdeltas
      in (ws', round_approx (b - lr * delta)))"

definition update_layer_weights_exec :: "layer \<Rightarrow> vec \<Rightarrow> vec \<Rightarrow> real \<Rightarrow> layer" where
  "update_layer_weights_exec l input deltas lr =
     map2 (\<lambda>n d. update_neuron_weights_exec n input d lr) l deltas"

definition train_step_exec :: "vec \<Rightarrow> vec \<Rightarrow> network \<Rightarrow> real \<Rightarrow> network" where
  "train_step_exec input target net lr =
     (let ws = network_weights net;
          sizes = network_layers net;
          activations = compute_layer_activations_exec input ws;
          output = last activations;
          loss_grad = mse_loss_derivative output target
      in if ws = [] then net
         else
           (let last_layer = last ws;
                last_activation =
                  (if length activations < 2 then input
                   else activations ! (length activations - 2));
                pre_activations =
                  map (\<lambda>n. neuron_output n last_activation) last_layer;
                deltas = output_deltas_exec loss_grad pre_activations;
                updated_last =
                  update_layer_weights_exec last_layer last_activation deltas lr;
                ws' = butlast ws @ [updated_last]
            in (sizes, ws')))"

fun train_epoch_exec :: "sample list \<Rightarrow> network \<Rightarrow> real \<Rightarrow> network" where
  "train_epoch_exec [] net lr = net"
| "train_epoch_exec (s # ss) net lr =
     train_epoch_exec ss (train_step_exec (sample_input s) (sample_target s) net lr) lr"

fun train_exec :: "sample list \<Rightarrow> network \<Rightarrow> real \<Rightarrow> nat \<Rightarrow> network" where
  "train_exec samples net lr 0 = net"
| "train_exec samples net lr (Suc n) =
     train_exec samples (train_epoch_exec samples net lr) lr n"

lemma train_step_exec_preserves_layers:
  "network_layers (train_step_exec input target net lr) = network_layers net"
  by (simp add: train_step_exec_def network_layers_def Let_def)

lemma train_epoch_exec_preserves_layers:
  "network_layers (train_epoch_exec samples net lr) = network_layers net"
  by (induct samples arbitrary: net)
     (auto simp: train_step_exec_preserves_layers)

lemma train_exec_preserves_layers:
  "network_layers (train_exec samples net lr epochs) = network_layers net"
  by (induct epochs arbitrary: net)
     (auto simp: train_epoch_exec_preserves_layers)

section \<open>Executable module forward\<close>

fun module_forward_exec :: "module \<Rightarrow> vec \<Rightarrow> vec"
  and sequential_forward_exec :: "module list \<Rightarrow> vec \<Rightarrow> vec"
  and concat_forward_exec :: "module list \<Rightarrow> vec \<Rightarrow> vec"
where
  "module_forward_exec Sigmoid input = map sigmoid_exec input"
| "module_forward_exec Tanh input = map tanh_exec input"
| "module_forward_exec ReLU input = map relu input"
| "module_forward_exec Softmax input = softmax_exec input"
| "module_forward_exec LogSoftmax input = log_softmax_exec input"
| "module_forward_exec (Linear w b) input =
     vector_add (matrix_vector_mult w input) b"
| "module_forward_exec Identity input = input"
| "module_forward_exec (Reshape _) input = input"
| "module_forward_exec (Mean _) input = [vector_mean input]"
| "module_forward_exec (Max _) input = [vector_max input]"
| "module_forward_exec (Sequential ms) input = sequential_forward_exec ms input"
| "module_forward_exec (Concat _ ms) input = concat_forward_exec ms input"
| "sequential_forward_exec [] input = input"
| "sequential_forward_exec (m # ms) input =
     sequential_forward_exec ms (module_forward_exec m input)"
| "concat_forward_exec [] input = []"
| "concat_forward_exec (m # ms) input =
     module_forward_exec m input @ concat_forward_exec ms input"

end
