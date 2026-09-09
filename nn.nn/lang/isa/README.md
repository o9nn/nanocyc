# Neural Network Implementation in Pure Isabelle/HOL

A pure [Isabelle/HOL](https://isabelle.in.tum.de) rendering of the neural
network library: the same feedforward networks, module system and
criterions as the sibling implementations, but as a *definitional theory*
whose invariants are machine-checked proofs rather than test assertions.

The library is derived from the Z++ formal specifications in
[`docs/`](../../docs) and mirrors the functional implementations in
[`lang/scm`](../scm), [`lang/rkt`](../rkt) and [`lang/raku`](../raku)
function for function.

## Features

### Core functionality
- **Feedforward neural networks**: arbitrary layer sizes and architectures
- **Simplified backpropagation**: activation caching, MSE gradient, SGD update
- **Activation functions**: Sigmoid, Tanh, ReLU, Softmax, LogSoftmax
- **Loss functions**: MSE, Classification NLL, Binary Cross Entropy, Absolute Error
- **Vector/matrix operations**: dot product, matrix–vector product, transpose,
  element-wise arithmetic, reductions

### Modular architecture
- **Module system**: a single `module` datatype (a *deep embedding*) with a
  primitive-recursive `module_forward`
- **Container modules**: `Sequential`, `Concat`
- **Transfer modules**: `Sigmoid`, `Tanh`, `ReLU`, `Softmax`, `LogSoftmax`
- **Layer modules**: `Linear`, `Identity`, `Reshape`, `Mean`, `Max`
- **Criterion modules**: `MSECriterion`, `ClassNLLCriterion`, `BCECriterion`,
  `AbsCriterion`

### What Isabelle adds
- **Proved invariants** instead of sampled assertions — see
  [`NN_Properties.thy`](NN_Properties.thy)
- **Exact real arithmetic** in the specification layer: `sigmoid`, `tanh`,
  `exp` and `ln` are the genuine mathematical functions, not floats
- **Derivative correctness**: the activation derivatives used by training are
  proved to *be* the analytic derivatives (`has_real_derivative`)
- **Executable mirror**: an approximation layer (`NN_Exec.thy`) makes every
  definition runnable over exact rationals, so demos and regression tests
  execute inside the logic

## Requirements

- Isabelle2025-2 (or any recent release); no Archive of Formal Proofs entries
  and no add-on components are required
- The session builds on `HOL-Library`, which ships with the distribution

### Installing Isabelle (CI / fresh machines)

The official `isabelle.in.tum.de` download redirects to
`dist.isabelle.cit.tum.de`, which is not always reachable from CI. Prefer the
helper script, which tries durable HTTPS mirrors first, verifies the tarball
SHA-256, and unpacks into `~/isabelle-dist`:

```bash
# from the repository root
bash lang/isa/install-isabelle.sh
export PATH="$HOME/isabelle-dist/bin:$PATH"
```

The ~1.1 GiB Linux distribution is **not** stored in git (it would dominate
the clone). GitHub Actions caches `~/isabelle-dist` so a cold download only
happens when the cache key changes. To reuse a local archive:

```bash
ISABELLE_TARBALL=/path/to/Isabelle2025-2_linux.tar.gz bash lang/isa/install-isabelle.sh
```

## Quick start

```bash
# from the repository root
isabelle build -d lang/isa -v NN

# or from this directory
cd lang/isa && isabelle build -D . -v
```

A successful build type-checks the library, re-runs **every** proof in
`NN_Properties`, discharges **every** regression test in `NN_Test` by
evaluation, and executes the demos and examples, printing their results into
the build log.

To explore interactively:

```bash
isabelle jedit -d lang/isa -l HOL-Library lang/isa/NN_Examples.thy
```

## Theory structure

| Theory | Contents | Specification source |
|---|---|---|
| [`NN_Types.thy`](NN_Types.thy) | `vec`, `mat`, `neuron`, `layer`, `network`, `sample`, well-formedness predicates | `data_model.zpp` §1–4 |
| [`NN_Vector.thy`](NN_Vector.thy) | dot product, element-wise arithmetic, reductions | `integrations.zpp` §1 |
| [`NN_Matrix.thy`](NN_Matrix.thy) | matrix–vector product, transpose | `integrations.zpp` §1 |
| [`NN_Activations.thy`](NN_Activations.thy) | sigmoid, tanh, ReLU, softmax, log-softmax and derivatives | `data_model.zpp` §7 |
| [`NN_Network.thy`](NN_Network.thy) | weight initialization, neuron/layer/network construction, forward pass | `operations.zpp` §1, §6 |
| [`NN_Loss.thy`](NN_Loss.thy) | MSE, ClassNLL, BCE, L1 | `operations.zpp` §2 |
| [`NN_Backprop.thy`](NN_Backprop.thy) | activation cache, output deltas, SGD update | `operations.zpp` §3–4 |
| [`NN_Training.thy`](NN_Training.thy) | `train_step`, `train_epoch`, `train` | `operations.zpp` §5 |
| [`NN_Modules.thy`](NN_Modules.thy) | `module` / `criterion` datatypes and their forward semantics | `data_model.zpp` §5–8, §10 |
| [`NN_Properties.thy`](NN_Properties.thy) | the proof payload (see below) | all four `.zpp` files |
| [`NN_Exec.thy`](NN_Exec.thy) | executable `_exec` mirrors over exact rationals | `integrations.zpp` §6 |
| [`NN.thy`](NN.thy) | umbrella theory: importing it gives the whole library | — |
| [`NN_Test.thy`](NN_Test.thy) | the sibling regression suite as `by eval` lemmas | sibling test suites |
| [`NN_Consistency.thy`](NN_Consistency.thy) | cross-implementation consistency fixture as `by eval` lemmas | `docs/fixtures/xor_fixture.json` |
| [`NN_Demo.thy`](NN_Demo.thy) | the sibling demos as `value` commands | `lang/scm/demo.scm` |
| [`NN_Examples.thy`](NN_Examples.thy) | the sibling quick-start tour | `lang/scm/example.scm` |

## API reference

### Networks

| Isabelle | Sibling equivalent |
|---|---|
| `create_network :: shape ⇒ network` | `(create-network '(2 3 1))` |
| `create_network_seeded :: shape ⇒ nat ⇒ network` | — (explicit PRNG seed) |
| `forward :: vec ⇒ network ⇒ vec` | `(forward input net)` |
| `predict :: vec ⇒ network ⇒ vec` | `(predict input net)` |
| `train :: sample list ⇒ network ⇒ real ⇒ nat ⇒ network` | `(train samples net lr epochs)` |
| `make_sample :: vec ⇒ vec ⇒ sample` | `(make-sample input target)` |
| `network_layers`, `network_weights` | `(network-layers net)`, `(network-weights net)` |

Weight initialization is deterministic: a linear congruential generator is
threaded through `make_neuron` / `make_layer` / `init_weights`, so
`create_network` is a *function* and every demo is reproducible.
`random_weight` still respects the `[-0.5, 0.5)` contract of
`integrations.zpp` §2 (`random_weight_range`).

### Modules

`sigmoid_module`, `tanh_module`, `relu_module`, `softmax_module`,
`log_softmax_module`, `make_identity`, `make_reshape`, `make_mean`,
`make_max`, `make_linear`, `make_linear_seeded`, `make_sequential`,
`make_concat`; applied with `module_forward :: module ⇒ vec ⇒ vec`.

### Criterions

`mse_criterion`, `class_nll_criterion`, `bce_criterion`, `abs_criterion`;
applied with `criterion_forward :: criterion ⇒ vec ⇒ vec ⇒ real` or, for
classification targets, `criterion_forward_class :: criterion ⇒ vec ⇒ nat ⇒ real`.

### Executable mirrors

`exp`, `ln` and `tanh` are not executable in HOL, so `NN_Exec.thy` provides
`_exec` counterparts built from truncated Taylor / artanh series over exact
rational arithmetic, with intermediate results rounded to a denominator of
10<sup>12</sup> to keep rationals bounded:

| Exact (for proofs) | Executable (for demos and tests) |
|---|---|
| `sigmoid_safe` | `sigmoid_exec` |
| `tanh_activation` | `tanh_exec` |
| `softmax`, `log_softmax` | `softmax_exec`, `log_softmax_exec` |
| `bce_loss` | `bce_exec` |
| `forward`, `predict` | `forward_exec`, `predict_exec` |
| `train_step`, `train_epoch`, `train` | `train_step_exec`, `train_epoch_exec`, `train_exec` |
| `module_forward` | `module_forward_exec` |
| `criterion_forward` | `criterion_forward_exec` |

`mse_loss`, `abs_loss`, `class_nll_loss`, `relu` and every vector/matrix
operation are already executable exactly and have no separate mirror.

`NN_Properties` reasons exclusively about the exact definitions, so the
approximation layer cannot weaken any proved statement.

## Proved properties

`NN_Properties.thy` mechanizes the invariants stated in the Z++ specs:

| Property | Statement |
|---|---|
| `sigmoid_range` | `0 < sigmoid x ∧ sigmoid x < 1` |
| `tanh_range` | `-1 < tanh_activation x ∧ tanh_activation x < 1` |
| `relu_nonneg` | `relu x ≥ 0` |
| `softmax_pos`, `softmax_sums_to_one` | softmax is a probability distribution |
| `log_softmax_eq_ln_softmax`, `log_softmax_nonpos` | log-softmax is `ln ∘ softmax`, and non-positive |
| `sigmoid_has_derivative`, `tanh_has_derivative` | the derivatives used by training are the analytic ones |
| `dot_product_comm`, `dot_product_add_left`, `dot_product_scalar_left` | bilinearity of the dot product |
| `transpose_matrix_involution`, `nth_transpose_matrix` | transpose is an involution with the expected entries |
| `forward_propagate_length`, `forward_length` | a well-formed network outputs `last sizes` values |
| `module_forward_length` | shape contract of the module system (`module_wf`) |
| `mse_loss_nonneg`, `mse_loss_zero_iff`, `abs_loss_nonneg` | loss invariants |
| `mse_loss_derivative_correct_1d`, `mse_loss_derivative_nth` | MSE gradient correctness |
| `train_step_preserves_layers`, `train_epoch_preserves_layers`, `train_preserves_layers` | training never changes the topology |
| `update_neuron_weights_wf`, `update_layer_weights_wf` | SGD updates preserve well-formedness |

## Running the tests

The regression suite is part of the session, so it runs on every build:

```bash
isabelle build -d lang/isa -v NN
```

`NN_Test.thy` restates the sibling 45-test suites as lemmas.  Concrete cases
are discharged by `eval` (exact rational computation); the universal
properties that the siblings can only sample are inherited from
`NN_Properties`, e.g.

```isabelle
lemma test_softmax_sums_universal: "∀v. v ≠ [] ⟶ sum_list (softmax v) = 1"
  using softmax_sums_to_one by blast
```

A failing test is a failing build — there is no separate runner and no way
for a failure to be reported but ignored.

### Cross-implementation consistency

`NN_Consistency.thy` builds the fixed 2-2-1 sigmoid MLP from
[`docs/fixtures/xor_fixture.json`](../docs/fixtures/xor_fixture.json) — the
same fixture every sibling port checks — and asserts the forward output and
MSE loss as `by eval` lemmas against the exact-rational executable mirror
(`NN_Exec`). Because the mirror's truncated-series sigmoid is accurate to
~10⁻¹⁰, the fixture's `tolerance_isa` (10⁻³) holds with a wide margin.  This
makes the Isabelle build a participant in the cross-port agreement check: if
any port drifts from the shared reference, CI fails.

## Running the demos

`NN_Demo.thy` and `NN_Examples.thy` are executed by the same build and print
their results into the log; run the build with `-v` to see them.  They cover
network creation and prediction, AND-gate and XOR training, module
composition, the activation functions, the criterions, and softmax
classification — the same set as `lang/scm/demo.scm` and
`lang/scm/example.scm`.

## Limitations

- **Simplified training**, exactly as in the sibling implementations: only the
  output layer is updated by `train_step`, so multi-layer problems such as XOR
  are not fully separated.
- **Vectors, not tensors**: the module system operates on `real list`;
  convolutional and table layers are out of scope, as in the other functional
  ports.
- **No floats**: computation is exact rational arithmetic, which is slower
  than the float-based siblings.  Keep epoch counts modest when experimenting.
- `Reshape` is a pass-through on flat vectors, matching the sibling ports.

## References

- [Isabelle/HOL](https://isabelle.in.tum.de) — the proof assistant
- [`docs/data_model.zpp`](../../docs/data_model.zpp),
  [`docs/operations.zpp`](../../docs/operations.zpp),
  [`docs/system_state.zpp`](../../docs/system_state.zpp),
  [`docs/integrations.zpp`](../../docs/integrations.zpp) — the specifications
  this library implements
- [`FORMAL_SPEC_INDEX.md`](../../FORMAL_SPEC_INDEX.md) — index of all
  implementations
