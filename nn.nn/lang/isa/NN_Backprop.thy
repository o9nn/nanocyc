(*  Theory:  NN_Backprop
    Derived from: docs/operations.zpp Section 3 (backward propagation)
    and Section 4 (parameter updates, SGDUpdate schema).

    Mirrors the sibling simplified backpropagation: activations are
    cached during the forward pass and the output layer is updated by
    gradient descent.
*)

theory NN_Backprop
  imports NN_Network NN_Loss
begin

section \<open>Activation cache (operations.zpp Section 3, backwardCache)\<close>

text \<open>
  compute-layer-activations: the list of post-activation values of every
  layer, starting with the input itself.
\<close>
fun compute_layer_activations :: "vec \<Rightarrow> layer list \<Rightarrow> vec list" where
  "compute_layer_activations input [] = [input]"
| "compute_layer_activations input (l # ls) =
     input # compute_layer_activations (layer_output l input sigmoid_safe) ls"

lemma length_compute_layer_activations [simp]:
  "length (compute_layer_activations input ws) = Suc (length ws)"
  by (induct ws arbitrary: input) auto

text \<open>The last cached activation is the network output.\<close>
lemma last_compute_layer_activations:
  "last (compute_layer_activations input ws) = forward_propagate input ws"
proof (induct ws arbitrary: input)
  case Nil
  then show ?case by simp
next
  case (Cons l ls)
  let ?input' = "layer_output l input sigmoid_safe"
  let ?acts = "compute_layer_activations ?input' ls"
  have ih: "last ?acts = forward_propagate ?input' ls"
    by (rule Cons.hyps)
  have "length ?acts = Suc (length ls)"
    by (rule length_compute_layer_activations)
  then obtain a as where acts_cons: "?acts = a # as"
    by (cases ?acts) auto
  have "last (compute_layer_activations input (l # ls)) = last ?acts"
    by (simp add: acts_cons)
  also have "\<dots> = forward_propagate ?input' ls"
    by (rule ih)
  also have "\<dots> = forward_propagate input (l # ls)" by simp
  finally show ?case .
qed

section \<open>SGD weight update (operations.zpp Section 4, SGDUpdate)\<close>

text \<open>
  update-neuron-weights: \<open>w' = w - \<eta> \<cdot> \<delta> \<cdot> x\<close>, \<open>b' = b - \<eta> \<cdot> \<delta>\<close>.
\<close>
definition update_neuron_weights :: "neuron \<Rightarrow> vec \<Rightarrow> real \<Rightarrow> real \<Rightarrow> neuron" where
  "update_neuron_weights n input delta lr =
     (let ws = neuron_weights n;
          b = neuron_bias n;
          wdeltas = map (\<lambda>x. lr * delta * x) input;
          ws' = map2 (-) ws wdeltas
      in (ws', b - lr * delta))"

text \<open>update-layer-weights: update each neuron with its own delta.\<close>
definition update_layer_weights :: "layer \<Rightarrow> vec \<Rightarrow> vec \<Rightarrow> real \<Rightarrow> layer" where
  "update_layer_weights l input deltas lr =
     map2 (\<lambda>n d. update_neuron_weights n input d lr) l deltas"

lemma length_update_layer_weights [simp]:
  "length (update_layer_weights l input deltas lr) = min (length l) (length deltas)"
  by (simp add: update_layer_weights_def)

section \<open>Output-layer deltas (operations.zpp Section 3, SigmoidBackward)\<close>

text \<open>
  \<open>\<delta>\<^sub>i = (\<partial>L/\<partial>o)\<^sub>i \<cdot> \<sigma>'(z\<^sub>i)\<close> where \<open>z\<close> are the output layer's
  pre-activations.  The clamped sigmoid derivative matches the sibling
  executable path.
\<close>
definition sigmoid_safe_derivative :: "real \<Rightarrow> real" where
  "sigmoid_safe_derivative x = sigmoid_safe x * (1 - sigmoid_safe x)"

definition output_deltas :: "vec \<Rightarrow> vec \<Rightarrow> vec" where
  "output_deltas loss_grad pre_activations =
     map2 (\<lambda>g z. g * sigmoid_safe_derivative z) loss_grad pre_activations"

end
