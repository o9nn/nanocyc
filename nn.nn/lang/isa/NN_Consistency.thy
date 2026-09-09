(*  Theory:  NN_Consistency
    Derived from: docs/fixtures/xor_fixture.json (shared by every port).

    Cross-implementation consistency: builds the fixed 2-2-1 sigmoid MLP
    shared with every sibling port (a9nn, scm, rkt, raku, pl) and asserts the
    forward output and MSE loss, guaranteeing that all implementations agree
    numerically on one deterministic fixture.

    The sibling ports run this check against inexact double-precision floats;
    here it runs against the exact-rational executable mirror (NN_Exec), whose
    truncated-series sigmoid agrees with the float reference to well within
    the fixture's \<open>tolerance_isa = 10\<^sup>-\<^sup>3\<close>.  A successful `isabelle build`
    of this theory certifies the agreement — a mismatch is a failing build.
*)

theory NN_Consistency
  imports NN_Test
begin

section \<open>The shared fixture network\<close>

text \<open>
  Fixed 2-2-1 network, one (\<open>weights\<close>, \<open>bias\<close>) neuron pair per unit,
  mirroring \<open>docs/fixtures/xor_fixture.json\<close>.
\<close>
definition fixture_net :: network where
  "fixture_net =
     ([2, 2, 1],
      [ [([0.5, -0.5], 0.1), ([-0.25, 0.75], -0.2)],
        [([0.6, -0.4], 0.05)] ])"

text \<open>The fixture network is well-formed (its weights realize its shape).\<close>
lemma fixture_net_wf: "wf_network fixture_net"
  by eval

section \<open>Consistency: forward outputs agree with the reference\<close>

text \<open>
  Each case asserts the forward output and the MSE loss against the target,
  with the fixture's Isabelle tolerance \<open>10\<^sup>-\<^sup>3\<close> (the float ports use
  \<open>10\<^sup>-\<^sup>6\<close>; the exact-rational approximation is well within both).
\<close>

lemma consistency_out_00:
  "approx (hd (forward_exec [0, 0] fixture_net)) 0.5460989866 (1/10^3)"
  by eval

lemma consistency_loss_00:
  "approx (mse_loss (forward_exec [0, 0] fixture_net) [0]) 0.2982241032 (1/10^3)"
  by eval

lemma consistency_out_01:
  "approx (hd (forward_exec [0, 1] fixture_net)) 0.5092822253 (1/10^3)"
  by eval

lemma consistency_loss_01:
  "approx (mse_loss (forward_exec [0, 1] fixture_net) [1]) 0.2408039344 (1/10^3)"
  by eval

lemma consistency_out_10:
  "approx (hd (forward_exec [1, 0] fixture_net)) 0.5699505688 (1/10^3)"
  by eval

lemma consistency_loss_10:
  "approx (mse_loss (forward_exec [1, 0] fixture_net) [1]) 0.1849425133 (1/10^3)"
  by eval

lemma consistency_out_11:
  "approx (hd (forward_exec [1, 1] fixture_net)) 0.5337512224 (1/10^3)"
  by eval

lemma consistency_loss_11:
  "approx (mse_loss (forward_exec [1, 1] fixture_net) [0]) 0.2848903675 (1/10^3)"
  by eval

section \<open>Structural agreement: output shape and range\<close>

text \<open>
  Independent of the numeric tolerance, the fixture output has the declared
  shape and stays in the sigmoid range — properties the float ports can only
  sample but which hold universally here (see NN_Properties).
\<close>
lemma consistency_output_length:
  "length (forward_exec [0, 0] fixture_net) = 1"
  by eval

lemma consistency_output_range:
  "list_all in_unit_interval (forward_exec [1, 0] fixture_net)"
  by eval

end
