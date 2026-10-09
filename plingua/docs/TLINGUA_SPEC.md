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
tick-ring pattern, so the existing `psim` simulator runs the lowered file with
**no simulator changes**.  The `tlingua` compiler also verifies the temporal
claims natively (see Verification): the 11-cycle, circular phase distance,
prime gating, and resonance exchange.  Nested `(tick)out` in a hand-written
`.pli` does not return to the rim in one hop, so those claims are checked on
the language-owned ring, not by hoping the convention is right.

The name "T" stands for *temporal* / *tensor* / *time*.  The f/n/s/d/a
variants proposed during design are **profiles and libraries within T-Lingua**,
not separate parsers (see Profiles).

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

## Verification

`tlingua` owns a ring of `period` phases.  Phase 0 is the rim (`wrap_to`).
After exactly `period` steps the phase is 0 and the wrap count is 1.  That is
the closed time loop.

| Check | Predicate |
|---|---|
| Eleven-cycle | a clock with `period 11` returns to phase 0 with one wrap |
| Circular phase distance | `circ(a,b,n) = min((a-b) mod n, n - that)`; `circ(10,0,11) == 1` |
| Prime gating | `@primes N` is the first N of `2,3,5,7,11,13,17,19,23,29,31,37,41,43,47`; the gate signature is their product; the gate is open iff `step % signature == 0` (step 0 is open). A signature that divides no positive tick inside the clock period is a warning, not a failure — `prime_signature(2,3,5) = 30` on an 11-cycle is the corpus case |
| Resonance exchange | `match`/`exchange` fires only when signatures intersect (or, with one signature, the phase-prime is in it; with none, circular distance is 0). `mismatch`/`dissipate` is the complement and consumes without delivering |
| Spinor | `2 * flip_at == period`; sign is −1 at `flip_at` and +1 at `period` |

Scheduling is simultaneous: eligibility is decided against a budget snapshot,
each rule at most once per step.  **daemon** fires every non-conflicting rule;
**angel** (the default) fires the first eligible rule per membrane.  Phase,
slot, and gate are read at the start of the step; clocks advance after rules.
`reseed` restores the tick at the rim on wrap.

```bash
make tcompiler
make check-tlingua
bin/tlingua examples/tlingua/time_crystal_neuron.tli -s 11 -v -o report.json
bin/tlingua model.tli -l model.pli
```

Exit status is 1 on a parse error or a failed verification.

## Profiles

One dialect.  The other proposed letters are libraries and pragmas:

| Proposal | In T-Lingua |
|---|---|
| F-Lingua (fractal/frequency) | `@fractal { depth N; scale s; tile name; }` — a profile recorded for an M-Lingua companion, not a parser |
| N-Lingua (neural/nested) | `@module` / `@import` — same-dialect `.tli` is inlined; other dialects are recorded |
| S-Lingua (spinor/spectral) | `@spinor name { period N; flip_at N/2; object obj; }` — one rule schema |
| D-Lingua / A-Lingua | `@semantics { mode = daemon \| angel; }` — scheduling poles, default angel |

Profiles live in `plingua/lang/tli/profiles/` and are imported, not parsed by a
second grammar.

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

**Ai-Lingua** (`.ali`) is that composition with a reference runner:
T-Lingua temporal core + R-Lingua observables + ECAN/PLN/MOSES + AtomSpace.
See `plingua/docs/AILINGUA_SPEC.md` and `make acompiler`. The élan sketch in
`plingua/lang/DIALECTS.md` remains the Lisp host of the same quadruple.
