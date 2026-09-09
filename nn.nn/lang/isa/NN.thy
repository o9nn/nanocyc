(*  Theory:  NN
    Umbrella theory: importing this theory gives the complete pure
    Isabelle/HOL neural network library.
*)

theory NN
  imports
    NN_Types
    NN_Vector
    NN_Matrix
    NN_Activations
    NN_Network
    NN_Loss
    NN_Backprop
    NN_Training
    NN_Modules
    NN_Properties
    NN_Exec
begin

text \<open>
  Pure Isabelle/HOL neural network library.

  Derived from the Z++ formal specifications in \<open>docs/*.zpp\<close> and the
  sibling functional implementations (\<open>lang/scm\<close>, \<open>lang/rkt\<close>,
  \<open>lang/raku\<close>).  Available components:

  \<^item> \<open>create_network sizes\<close> — build a feedforward network
  \<^item> \<open>forward input net\<close> / \<open>predict input net\<close> — inference
  \<^item> \<open>train samples net lr epochs\<close> — gradient-descent training
  \<^item> Module system: \<open>make_linear\<close>, \<open>make_sequential\<close>, \<open>sigmoid_module\<close>, ...
  \<^item> Criterions: \<open>mse_criterion\<close>, \<open>class_nll_criterion\<close>, \<open>bce_criterion\<close>,
    \<open>abs_criterion\<close>
  \<^item> Proved invariants: see \<open>NN_Properties\<close>
\<close>

end
