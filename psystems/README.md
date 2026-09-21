# NanoBrain P-Systems (P-Lingua) Models

This directory contains formal **P-system** models of all NanoBrain features, written in the
**P-Lingua language** (the standard input language of the
[pLinguaCore](https://www.p-lingua.org/) / MeCoSim membrane-computing ecosystem).

Every feature listed in the chapter issues (#6–#15) MUST be generated as a `.pli` file here
before (or alongside) its C++/Elixir implementation. The `.pli` model is the executable
specification; the C++ (`src/cpp/nanobrain_*`) and Elixir (`nanobrain_ex/`) modules are its
high-performance realizations.

## Layout

```
psystems/
├── README.md            ← this file
├── validate.sh          ← parses every .pli file (see Validation below)
├── common/              ← shared modules reused by all chapters
│   ├── alphabet_primes.pli
│   ├── time_crystal_core.pli
│   ├── gml_shapes.pli
│   ├── hypernumbers.pli
│   ├── ecan_attention.pli
│   └── pln_truth.pli
├── ch01/ … ch10/        ← one folder per chapter issue (#6 = ch01 … #15 = ch10)
│   └── ch03/            ← Phase Prime Metric (issue #8): ch03_ppm_core.pli
│                          (3.1, 3.1.1–3.1.3), ch03_ppm_metric1_shape.pli …
│                          ch03_ppm_metric10_imaginary.pli (3.2–3.11),
│                          ch03_prime_operators.pli (3.12),
│                          ch03_ppm_evolution.pli (3.13–3.14),
│                          ch03_diabetes_bigdata.pli (3.15),
│                          ch03_prime_classes.pli (3.16, 3.16.1–3.16.2)
│   └── ch09/            ← Brain jelly to humanoid avatar (issue #14):
│                          ch09_biomorphic_devices.pli (9.1),
│                          ch09_cortical_sheet.pli (9.2, 9.2.1–9.2.2),
│                          ch09_quantum_cloaking.pli (9.3, 9.3.1),
│                          ch09_living_gel.pli (9.4),
│                          ch09_fractal_condensation.pli (9.5, 9.5.1),
│                          ch09_fractal_reaction_kinetics.pli (9.6),
│                          ch09_nanobrain_lifeform.pli (9.7, 9.7.1–9.7.2),
│                          ch09_magnetic_light_reading.pli (9.8, 9.8.1–9.8.2),
│                          ch09_entropy_primes.pli (9.9, 9.9.1),
│                          ch09_cortical_pen.pli (9.10, 9.10.1),
│                          ch09_seeking_sensor.pli (9.11, 9.11.1–9.11.2),
│                          ch09_sensor_triad.pli (9.12, 9.12.1)
```

Naming: `chNN_<feature>.pli` (e.g. `ch03_ppm_metric3_phasepath.pli`).

## P-Lingua conventions used

* **P-Lingua 4.0**, cell-like P systems (model: `psystems_basic` / `transition` style rules).
* Each file is self-contained: it declares its own membrane structure via `@mu` and its
  multisets; shared definitions from `common/` are **inlined by convention** (P-Lingua has no
  import statement — copy the needed declarations from the common file and cite it in the
  header comment).
* Every file carries a header comment block with:
  * chapter / issue / section coverage,
  * the C++/Elixir module it specifies (traceability),
  * a sample initial multiset that lets the simulator run ≥ 1 step.
* Rule syntax: `[ lhs --> rhs ]'label'membrane` with optional priorities, catalysts and
  send-in/send-out targets (`(...)in_memb`, `(...)out`, `(...)here`).

## Validation

```bash
./validate.sh            # syntax-check every .pli in the tree
```

The script uses `plingua` (pLinguaCore CLI) when it is installed. When pLinguaCore is not
available it falls back to a structural lint (balanced brackets, declared membranes, rule
arrow sanity) so CI can still gate on well-formedness.

To run a simulation (with pLinguaCore ≥ 4.0 installed):

```bash
plingua psystems/ch03/ch03_ppm_core.pli simulate -steps 10
```

## Traceability

| P-Lingua folder | C++ module(s) | Issue |
|---|---|---|
| `common/` | `nanobrain_metacognitive.h` (`CognitiveMembrane`), `nanobrain_time_crystal.h`, `nanobrain_attention.h`, `nanobrain_reasoning.h` | all |
| `ch01/` | `nanobrain_philosophical.*`, `nanobrain_unified.*` | #6 |
| `ch02/` | `nanobrain_fractal_tape.*`, `nanobrain_fractal.*` | #7 |
| `ch03/` | `nanobrain_ppm.*` | #8 |
| `ch04/` | `nanobrain_dodecanion.*`, `nanobrain_fractal.*` | #9 |
| `ch05/` | `nanobrain_gog.*`, `nanobrain_tc_transform.*`, `nanobrain_spontaneous.*` | #10 |
| `ch06/` | `nanobrain_singularity.*` | #11 |
| `ch07/` | `nanobrain_brain_model.*` | #12 |
| `ch08/` | `nanobrain_hinductor.*` | #13 |
| `ch09/` | `nanobrain_brain_jelly.*` | #14 |
| `ch10/` | `nanobrain_consciousness.*`, `nanobrain_ontogenesis.*` | #15 |
