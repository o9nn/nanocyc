# Implementation Summary: lang/isa (Isabelle/HOL)

## Overview

Successfully implemented a complete neural network library as a **pure Isabelle/HOL
definitional theory** (`lang/isa`), derived from the Z++ formal specifications in
`docs/` (`data_model.zpp`, `operations.zpp`, `system_state.zpp`, `integrations.zpp`)
and mirroring the sibling functional implementations (`lang/scm`, `lang/rkt`,
`lang/raku`) function for function.

Unlike every other port, the Isabelle rendering does not merely *test* the
invariants the Z++ specs assert — it **proves** them. A successful session build
type-checks the library, re-runs every proof, discharges every regression test by
exact evaluation, and executes the demos: build success *is* the test gate.

## Files Created

### 1. **Core theories** (the library)

- **NN_Types.thy** (109 lines) — type synonyms (`vec`, `mat`, `shape`, `neuron`,
  `layer`, `network`, `sample`) and well-formedness predicates (`wf_neuron`,
  `wf_layer`, `wf_weights`, `wf_network`, `wf_mat`); derived from
  `data_model.zpp` §1–4.
- **NN_Vector.thy** (72 lines) — dot product, element-wise arithmetic, reductions
  (`vector_sum`, `vector_mean`, `vector_max`); `integrations.zpp` §1.
- **NN_Matrix.thy** (87 lines) — matrix–vector product, transpose;
  `integrations.zpp` §1.
- **NN_Activations.thy** (87 lines) — exact-real sigmoid, tanh, ReLU, softmax,
  log-softmax and their derivatives; `data_model.zpp` §7.
- **NN_Network.thy** (140 lines) — deterministic seeded weight initialization
  (linear congruential generator), network construction, forward pass;
  `operations.zpp` §1, §6.
- **NN_Loss.thy** (57 lines) — MSE + derivative, ClassNLL, BCE, Absolute losses;
  `operations.zpp` §2.
- **NN_Backprop.thy** (89 lines) — activation caching, output-layer deltas, SGD
  weight/bias update; `operations.zpp` §3–4.
- **NN_Training.thy** (78 lines) — `train_step`, `train_epoch`, `train`;
  `operations.zpp` §5.
- **NN_Modules.thy** (127 lines) — the `module` and `criterion` datatypes (deep
  embedding) with primitive-recursive forward semantics; `data_model.zpp` §5–8, §10.

### 2. **NN_Properties.thy** (Proof payload — 575 lines)

36 machine-checked lemmas mechanizing the invariants stated in the Z++ specs:

- **Activation ranges**: `sigmoid_range` (strictly in (0,1)), `tanh_range`,
  `relu_nonneg`, `relu_id_nonneg`
- **Softmax correctness**: `softmax_pos`, `softmax_sums_to_one`,
  `log_softmax_eq_ln_softmax`, `log_softmax_nonpos`
- **Derivative correctness**: `sigmoid_has_derivative`, `tanh_has_derivative`
  (the derivatives used by training are proved to *be* the analytic ones via
  `has_real_derivative`), `mse_loss_derivative_correct_1d`, `mse_loss_derivative_nth`
- **Algebraic properties**: `dot_product_comm`, `dot_product_add_left`,
  `dot_product_scalar_left`, `transpose_matrix_involution`, `nth_transpose_matrix`
- **Shape preservation**: `forward_propagate_length`, `forward_length`,
  `module_forward_length` (well-formed networks output `last sizes` values)
- **Loss invariants**: `mse_loss_nonneg`, `mse_loss_zero_iff`, `abs_loss_nonneg`
- **Training topology invariants**: `train_step_preserves_layers`,
  `train_epoch_preserves_layers`, `train_preserves_layers`,
  `update_neuron_weights_wf`, `update_layer_weights_wf` (training never changes
  network topology or well-formedness)

### 3. **NN_Exec.thy** (Executable mirror — 299 lines)

`exp`, `ln` and `tanh` on `real` are not executable in HOL, so this theory
provides `_exec` counterparts built from truncated Taylor / artanh series over
**exact rational arithmetic**, with intermediate results rounded to denominator
10¹² to keep rationals bounded (`integrations.zpp` §6). The proof theories reason
exclusively about the exact definitions, so the approximation layer cannot weaken
any proved statement — and the logically inconsistent float code-setup is never
imported.

### 4. **NN_Test.thy** (Regression suite — 304 lines)

The sibling 45-test suites restated as **65 lemmas** discharged by `eval` (exact
rational computation): activations, vector/matrix ops, network creation, forward
pass, losses, every module type, criterions, softmax/log-softmax, training
structure preservation and loss-decrease, module composition. Universal
properties the siblings can only sample are inherited from `NN_Properties`:

```isabelle
lemma test_softmax_sums_universal: "∀v. v ≠ [] ⟶ sum_list (softmax v) = 1"
  using softmax_sums_to_one by blast
```

A failing test is a failing build — there is no way for a failure to be reported
but ignored.

### 5. **NN_Demo.thy / NN_Examples.thy** (140 + 97 lines)

The sibling demos (`lang/scm/demo.scm`) and quick-start tour
(`lang/scm/example.scm`) as `value` commands executed by the build: network
creation and prediction, AND-gate and XOR training, module composition,
activation functions, criterions, softmax classification. Results print into the
build log.

### 6. **NN.thy** (Umbrella theory — 37 lines)

Importing `NN` gives the whole library.

### 7. **ROOT** (Session definition)

One Isabelle session `NN` based on `HOL-Library` (ships with the distribution —
no AFP entries, no add-on components), listing all theories. Build with:

```bash
isabelle build -d lang/isa -v NN        # from the repository root
cd lang/isa && isabelle build -D . -v   # from lang/isa
```

### 8. **install-isabelle.sh** (CI helper — 78 lines)

Downloads a pinned Isabelle2025-2 Linux tarball from durable HTTPS mirrors
(verifying SHA-256) and unpacks into `~/isabelle-dist`; the ~1.1 GiB distribution
is cached by GitHub Actions and never committed to git.

### 9. **README.md** (lang/isa documentation)

Sibling-style README: features, install/run instructions, quick start, API
reference, theory-to-spec traceability matrix, proved-properties table,
executable-mirror table, limitations.

## Key Design Decisions

1. **Pure Isabelle/HOL, no AFP** — depends only on `Complex_Main` and
   `HOL-Library` from the distribution, keeping the port CI-installable.
2. **Data representation mirrors the siblings** — vectors as `real list`,
   matrices as `real list list`, neurons as weight-list × bias pairs, networks as
   declared shape × layer list; structurally parallel to `data_model.zpp` §1–4
   rather than HOL's fixed-dimension vector types, so everything stays executable.
3. **Two-level executability strategy** — all proofs against exact `real`-valued
   definitions; demos/tests run via the exact-rational `_exec` mirror layer.
4. **Determinism instead of randomness** — a seeded LCG threaded through weight
   initialization (`create_network_seeded`), respecting the [−0.5, 0.5) contract
   of `integrations.zpp` §2 while making every demo reproducible.
5. **Module system as a deep embedding** — one recursive `module` datatype with a
   primitive-recursive `module_forward`, plus a `criterion` datatype; the direct
   Isabelle rendering of `data_model.zpp` §5–8, §10.

## Module System

- **Transfer modules**: `sigmoid_module`, `tanh_module`, `relu_module`,
  `softmax_module`, `log_softmax_module`
- **Layer modules**: `make_linear`, `make_linear_seeded`, `make_identity`,
  `make_reshape`, `make_mean`, `make_max`
- **Container modules**: `make_sequential`, `make_concat`
- **Criterion modules**: `mse_criterion`, `class_nll_criterion`, `bce_criterion`,
  `abs_criterion` (applied with `criterion_forward` / `criterion_forward_class`)

## Continuous Integration

`.github/workflows/ci.yml` has a dedicated `isabelle` job: `lang/isa/**` path
filter, cached `~/isabelle-dist` + `~/.isabelle` heaps, `install-isabelle.sh`,
then `isabelle build -d lang/isa -v -o document=false NN`. The job is part of the
`ci-success` fan-in. Root `README.md` documents the Isabelle row in the CI table
and `FORMAL_SPEC_INDEX.md` notes the specs are now mechanized in `lang/isa`.

## Implementation Statistics

- **Total theory code**: ~2,300 lines (15 `.thy` files + ROOT)
- **Proof payload**: 36 proved lemmas (`NN_Properties.thy`)
- **Regression suite**: 65 `eval`-discharged test lemmas (`NN_Test.thy`)
- **External dependencies**: none beyond the Isabelle2025-2 distribution

## Comparison with sibling ports

| Feature | scm / rkt / raku | lang/isa |
|---|---|---|
| Feedforward networks, modules, criterions | ✓ | ✓ |
| Executable demos/tests | ✓ (floats) | ✓ (exact rationals) |
| Invariant checking | sampled assertions | **machine-checked proofs** |
| Derivative correctness | assumed | proved (`has_real_derivative`) |
| Training topology invariants | untested | proved |
| Arithmetic | inexact floats | exact reals / rationals |

## Limitations

- **Simplified training**, exactly as in the sibling implementations: only the
  output layer is updated by `train_step`, so multi-layer problems such as XOR
  are not fully separated.
- **Vectors, not tensors**: convolutional and table layers are out of scope, as
  in the other functional ports.
- **No floats**: exact rational arithmetic is slower than the float-based
  siblings; keep epoch counts modest.
- `Reshape` is a pass-through on flat vectors, matching the sibling ports.

## Conclusion

Successfully delivered a complete pure Isabelle/HOL neural network library that:

1. ✅ Implements the full core functionality of the sibling ports
2. ✅ Realizes the promise of `FORMAL_SPEC_INDEX.md` ("use Z++ specs for theorem
   proving") with 36 machine-checked invariants
3. ✅ Restates the sibling regression suite as 65 evaluation-proved lemmas
4. ✅ Executes demos and examples inside the logic on every build
5. ✅ Integrates with CI as a first-class job (build success = test gate)
6. ✅ Requires nothing beyond the standard Isabelle distribution

## References

- [Isabelle/HOL](https://isabelle.in.tum.de) — the proof assistant
- [`docs/data_model.zpp`](docs/data_model.zpp),
  [`docs/operations.zpp`](docs/operations.zpp),
  [`docs/system_state.zpp`](docs/system_state.zpp),
  [`docs/integrations.zpp`](docs/integrations.zpp) — the specifications
  this library implements
- [`lang/isa/README.md`](lang/isa/README.md) — full theory-by-theory guide
- [`FORMAL_SPEC_INDEX.md`](FORMAL_SPEC_INDEX.md) — index of all implementations
