# T-Lingua Specification (`.tli`)

## Overview

T-Lingua is a domain-specific language for **time-crystal membrane systems** —
the temporal/tensor dialect of the P-Lingua family.  It exists because the
NanoBrain `psystems/` corpus hand-encodes the same temporal machinery in
**85 of 125 models**: an 11-phase closed tick ring, a phase register, prime
signatures gating rule firing, and resonance coupling between membranes.  When
two-thirds of a corpus re-implements the same clock by convention, that clock
belongs in the language.

T-Lingua is a **strict superset of P-Lingua**: every valid `.pli` file is also
a valid `.tli` file.  The `.tli` extension adds first-class temporal and
typed-object constructs.  A `.tli` model is **lowered to plain P-Lingua**
(`.pli`) by macro-expanding clocks and phase registers into the explicit
tick-ring pattern, so the existing `psim` simulator runs `.tli` with **no
simulator changes**.  (Native simulator support is a later optimization.)

The name "T" stands for *temporal* / *tensor* / *time*.  The f/n/s/d/a
variants proposed during design are **profiles and libraries within T-Lingua**,
not separate parsers (see §6).

## Formal Definition

A T-Lingua system `T = (Π, C, Φ, Π₀)` where:

- **Π**: the underlying P system (membranes, multisets, rules) — as in P-Lingua.
- **C**: a set of **clocks**, each `(period, wrap, reseed)` defining a closed
  time loop over a chain of phase membranes.
- **Φ**: a set of **phase registers**, each a cyclic counter driving a slot ring.
- **Π₀**: a **prime alphabet** (default the 15 Phase-Prime-Metric primes
  `2,3,5,7,11,13,17,19,23,29,31,37,41,43,47`) with ordering and gating semantics.

Rule guards extend the firing condition with temporal predicates
(`when phase == k`) and coupling predicates (`with resonance(...)`).

## New Constructs

| Construct | Description |
|-----------|-------------|
| `@tmodel<time_crystal>` | Declares a time-crystal model |
| `@clock name { period N; wrap <from> -> <to>; reseed <obj>; }` | A first-class closed time loop: the simulator owns the tick ring |
| `@phase_register r { cycle N; slots [s1 s2 … sN]; }` | A cyclic register firing one slot per tick |
| `@primes N;` | Declare the first-N prime alphabet as typed objects |
| `@gate <membrane> by prime_signature(p1, p2, …);` | Resonance gating — checked by the simulator, not a comment |
| `when <guard>` | Phase guard on a rule: only fires when the guard holds |
| `with resonance(<mode>)` | Coupling predicate between membranes |
| `@semantics { mode = daemon \| angel; }` | Rule-scheduling pole pragma |
| `@fractal` | Import an M-Lingua geometric profile (self-similar tiling) |

## Semantics of the additions

### `@clock`

```
@clock tick { period 11; wrap d11 -> rim; reseed singularity_point; }
```

expands to an 11-deep nested phase-membrane chain `d1 … d11` and a `tick`
object that falls one dimension per step and is re-created at `rim` when it
reaches `d11` — the closed time loop that the `psystems/` corpus currently
writes by hand (cf. `psystems/common/time_crystal_core.pli`).

### `@phase_register`

```
@phase_register cfga { cycle 13;
  slots [add sub mul div diff int inner outer geometric project reject rotate reflect]; }
```

expands to a `phase(p)` counter object, one `slot(x)` object per entry, and a
wrap rule `phase(12) → phase(0)`.  A rule guarded by `when slot == X` fires its
operation only on its tick — exactly the pattern in `ch04_cfga_operator.pli`,
reduced from ~30 lines of boilerplate to one declaration.

### `when` / `with resonance`

```
[fire : operator * slot(add) --> done(add)]'cfga when phase == 0;
[exchange : signal --> (signal)out]'a with resonance(match);
```

- `when <guard>` is a predicate over the enclosing membrane's clock/phase
  state; the rule is eligible only when the guard holds.
- `with resonance(match)` couples two membranes: objects exchange only when
  their phase/frequency signatures match (checked against the prime signature
  declared by `@gate`).

### `@semantics { mode = daemon | angel; }`

Selects the scheduling pole for the whole model:

- **daemon** — procedural/active: maximal parallelism, priorities, dissolution.
- **angel** — declarative/structural: pattern matching and invariant
  preservation (the default for specification-grade models).

## Lowering to P-Lingua

T-Lingua's reference implementation is a source-to-source compiler
`.tli → .pli`.  The lowering rules:

| T-Lingua | Lowered P-Lingua |
|---|---|
| `@clock …{period N…}` | N nested `d1..dN` membranes + tick-fall + wrap rules |
| `@phase_register r{cycle N; slots[…]}` | `phase(i)` register + `slot(x)` objects + wrap rule |
| `when phase == k` | LHS gains `phase(k)`; RHS restores `phase(k)` |
| `with resonance(…)` | emits a guard object checked by a priority rule pair |
| `@primes N` | `prime_2 … prime_N` typed objects + ordering rules |

Because lowering targets plain `.pli`, the lowered file runs on the unmodified
`psim` and is validated by `psystems/validate.sh`.

## Examples

See `plingua/lang/tli/` for the lowered exemplars:

- `cfga_operator.tli` — the 13-operation CFGA operator (ports
  `psystems/ch04/ch04_cfga_operator.pli`).
- `time_crystal_core.tli` — the 11D nested phase-manifold base (ports
  `psystems/common/time_crystal_core.pli`).

Each is shown beside its `.pli` lowering to demonstrate the line-count
reduction from convention to language primitive.

## Relationship to the other dialects

| Dialect | Role |
|---|---|
| P-Lingua (`.pli`) | discrete multiset rewriting — the base |
| M-Lingua (`.mli`) | spatial geometry / morphogenesis (imported via `@fractal`) |
| R-Lingua (`.rli`) | relevance-realization observables (grip, ennead balance) |
| **T-Lingua (`.tli`)** | temporal/tensor: clocks, phases, primes, resonance |
| L-Lingua (`.scm`/…) | the s-expression semantic kernel (`plingua/lang/`) |

The proposed **AI-Lingua** experiment = T-Lingua temporal core + R-Lingua
observables + ECAN/PLN attention/truth on objects, hosted in the élan dialect
of the L-Lingua kernel.
