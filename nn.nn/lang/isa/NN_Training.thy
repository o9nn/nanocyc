(*  Theory:  NN_Training
    Derived from: docs/operations.zpp Section 5 (training loop
    operations: TrainBatch, TrainEpoch, Train) and
    docs/system_state.zpp Section 3 (training state).

    Mirrors the sibling simplified training: one gradient-descent step
    on the output layer per sample (train-step), iterated over all
    samples (train-epoch) and over a fixed number of epochs (train).
*)

theory NN_Training
  imports NN_Backprop
begin

section \<open>Single training step (operations.zpp TrainBatch, simplified)\<close>

text \<open>
  train-step: forward pass with activation caching, MSE loss gradient,
  output-layer deltas, and SGD update of the last layer only —
  exactly the sibling behaviour.
\<close>
definition train_step :: "vec \<Rightarrow> vec \<Rightarrow> network \<Rightarrow> real \<Rightarrow> network" where
  "train_step input target net lr =
     (let ws = network_weights net;
          sizes = network_layers net;
          activations = compute_layer_activations input ws;
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
                deltas = output_deltas loss_grad pre_activations;
                updated_last =
                  update_layer_weights last_layer last_activation deltas lr;
                ws' = butlast ws @ [updated_last]
            in (sizes, ws')))"

text \<open>Training never changes the declared topology (system_state.zpp Section 5).\<close>
lemma train_step_preserves_layers:
  "network_layers (train_step input target net lr) = network_layers net"
  by (simp add: train_step_def network_layers_def Let_def)

lemma train_step_preserves_depth:
  "length (network_weights (train_step input target net lr)) =
   length (network_weights net)"
  by (simp add: train_step_def network_weights_def Let_def)

section \<open>Epoch and multi-epoch training (operations.zpp TrainEpoch, Train)\<close>

text \<open>train-epoch: fold one train-step per sample, in order.\<close>
fun train_epoch :: "sample list \<Rightarrow> network \<Rightarrow> real \<Rightarrow> network" where
  "train_epoch [] net lr = net"
| "train_epoch (s # ss) net lr =
     train_epoch ss (train_step (sample_input s) (sample_target s) net lr) lr"

lemma train_epoch_preserves_layers:
  "network_layers (train_epoch samples net lr) = network_layers net"
  by (induct samples arbitrary: net) (auto simp: train_step_preserves_layers)

text \<open>
  train: iterate train-epoch for the requested number of epochs.
  Argument order matches the sibling API: samples, network, learning
  rate, epochs.
\<close>
fun train :: "sample list \<Rightarrow> network \<Rightarrow> real \<Rightarrow> nat \<Rightarrow> network" where
  "train samples net lr 0 = net"
| "train samples net lr (Suc n) = train samples (train_epoch samples net lr) lr n"

lemma train_preserves_layers:
  "network_layers (train samples net lr epochs) = network_layers net"
  by (induct epochs arbitrary: net) (auto simp: train_epoch_preserves_layers)

end
