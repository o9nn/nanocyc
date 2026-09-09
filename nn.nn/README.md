[![CI](https://github.com/ReZorg/nn.nn/actions/workflows/ci.yml/badge.svg)](https://github.com/ReZorg/nn.nn/actions/workflows/ci.yml)
<a name="nn.dok"></a>
# Neural Network Package #

This package provides an easy and modular way to build and train simple or complex neural networks using [Torch](https://github.com/torch/torch7/blob/master/README.md):
 * Modules are the bricks used to build neural networks. Each are themselves neural networks, but can be combined with other networks using containers to create complex neural networks:
   * [Module](doc/module.md#nn.Module): abstract class inherited by all modules;
   * [Containers](doc/containers.md#nn.Containers): composite and decorator classes like [`Sequential`](doc/containers.md#nn.Sequential), [`Parallel`](doc/containers.md#nn.Parallel), [`Concat`](doc/containers.md#nn.Concat) and [`NaN`](doc/containers.md#nn.NaN);
   * [Transfer functions](doc/transfer.md#nn.transfer.dok): non-linear functions like [`Tanh`](doc/transfer.md#nn.Tanh) and [`Sigmoid`](doc/transfer.md#nn.Sigmoid);
   * [Simple layers](doc/simple.md#nn.simplelayers.dok): like [`Linear`](doc/simple.md#nn.Linear), [`Mean`](doc/simple.md#nn.Mean), [`Max`](doc/simple.md#nn.Max) and [`Reshape`](doc/simple.md#nn.Reshape);
   * [Table layers](doc/table.md#nn.TableLayers): layers for manipulating `table`s like [`SplitTable`](doc/table.md#nn.SplitTable), [`ConcatTable`](doc/table.md#nn.ConcatTable) and [`JoinTable`](doc/table.md#nn.JoinTable);
   * [Convolution layers](doc/convolution.md#nn.convlayers.dok): [`Temporal`](doc/convolution.md#nn.TemporalModules),  [`Spatial`](doc/convolution.md#nn.SpatialModules) and [`Volumetric`](doc/convolution.md#nn.VolumetricModules) convolutions;
 * Criterions compute a gradient according to a given loss function given an input and a target:
   * [Criterions](doc/criterion.md#nn.Criterions): a list of all criterions, including [`Criterion`](doc/criterion.md#nn.Criterion), the abstract class;
   * [`MSECriterion`](doc/criterion.md#nn.MSECriterion): the Mean Squared Error criterion used for regression;
   * [`ClassNLLCriterion`](doc/criterion.md#nn.ClassNLLCriterion): the Negative Log Likelihood criterion used for classification;
 * Additional documentation:
   * [Overview](doc/overview.md#nn.overview.dok) of the package essentials including modules, containers and training;
   * [Training](doc/training.md#nn.traningneuralnet.dok): how to train a neural network using [`StochasticGradient`](doc/training.md#nn.StochasticGradient);
   * [Testing](doc/testing.md): how to test your modules.
   * [Experimental Modules](https://github.com/clementfarabet/lua---nnx/blob/master/README.md): a package containing experimental modules and criteria.

## Continuous Integration & Testing ##

Every implementation in this repository is exercised by [GitHub Actions](.github/workflows/ci.yml). To run the suites locally:

| Implementation | Unit tests | E2E demos |
|---|---|---|
| a9nn (pure Lua) | `cd lang/a9nn && lua run_tests.lua` | `lua examples/<example>.lua` |
| Prolog | `cd lang/pl && swipl -q -l test_nn.pl -g run_tests -t halt` (also `test_modules.pl` / `run_module_tests`, `test_nd.pl` / `run_nd_tests`, `test_consistency.pl` / `run_consistency_tests`) | `swipl -q -l demo.pl -g run_all_demos -t halt` |
| P-Lingua | `bash lang/pli/validate.sh` | — |
| Raku | `cd lang/raku && raku test-nn.raku` | `raku demo.raku`, `raku example.raku` |
| Racket | `cd lang/rkt && racket test-nn.rkt` | `racket demo.rkt`, `racket example.rkt` |
| Scheme (Guile) | `cd lang/scm && guile --no-auto-compile -l nn.scm -l test-nn.scm -c '(run-all-tests)'` | `guile --no-auto-compile -l nn.scm -l demo.scm -c '(run-all-demos)'` |
| Isabelle/HOL | `isabelle build -d lang/isa -v NN` (the build re-runs every proof and every `eval`-based test) | Demos and examples run as part of the same build |
| THNN (C backend) | `bash lang/c/THNN/check.sh` (structural smoke check) | — |
| Torch/nn (Lua) | Requires a full [Torch7](https://github.com/torch/distro) install: `luarocks make rocks/nn-scm-1.rockspec` then `lua -lnn -e "nn.test()"` (CI performs a syntax check of all modules; the opt-in nightly `torch-legacy` job attempts the full build) | — |

Lint Lua sources with `luacheck lang/lua lang/a9nn` and build the docs with `mkdocs build --strict`.

### Cross-implementation consistency

All seven ports agree numerically on a single deterministic fixture,
[`docs/fixtures/xor_fixture.json`](docs/fixtures/xor_fixture.json): a fixed
2-2-1 sigmoid MLP with known weights, an input, and the expected forward output
and MSE loss. Each port constructs the network and asserts the results to a
tolerance (10⁻⁶ for the float ports; 10⁻³ for Isabelle's exact-rational
approximation layer, in `lang/isa/NN_Consistency.thy`). A disagreement between
any two ports fails CI, so the implementations cannot silently drift apart.

### CI jobs

The `ci-success` job is a single fan-in gate suitable as a required status
check. Per-language jobs run only when their `lang/<x>/` subtree changes (or on
the default branch / manual dispatch). The `torch-legacy` job runs the full
legacy Torch7 `nn.test()` suite on a nightly schedule and manual dispatch only,
and is best-effort (`continue-on-error`).
