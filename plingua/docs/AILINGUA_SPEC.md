# Ai-Lingua Specification (`.ali`)

## Overview

Ai-Lingua (`.ali`) is the experimental cognitive dialect of the P-Lingua family.
It is the composition named in `TLINGUA_SPEC.md`:

**T-Lingua temporal core + R-Lingua cognitive observables + ECAN/PLN/MOSES + AtomSpace backing.**

Every piece already has a home in this repository. Ai-Lingua does not fork those
bridges. It gives them a membrane language:

| Piece | Already in the repo | Ai-Lingua construct |
|---|---|---|
| Closed tick / phase gate | T-Lingua (`@clock`, `when phase`) | `@clock`, `@phase_register`, `when` |
| Grip / ennead / emergence | R-Lingua, `relevance_realization.hpp` | `@ennead`, `@observe` |
| Attention economy | `ecan_integration.hpp`, `examples/opencog/opencog_ecan.pli` | `@attention ecan` |
| Truth values and inference | `pln_integration.hpp`, `examples/opencog/opencog_pln.pli` | `@truth pln`, `pln` on a rule |
| Rule-population evolution | `moses_integration.hpp`, `examples/opencog/opencog_moses.pli` | `@learn moses` |
| Hypergraph memory | `atomspace_integration.hpp`, `examples/opencog/opencog_atomspace.pli` | `@atomspace`, `remember` |

Semantics, in one sentence: objects carry `(symbol, truth_value, attention_value, phase)`;
rule firing is modulated by ECAN wages and phase gates; MOSES evolves rule
populations between cognitive cycles; every run emits grip and emergence metrics.

The reference implementation is the `ailingua` compiler/runner
(`plingua/src/ailingua/`, `plingua/include/ailingua/`). It is a strict superset
of the P-Lingua *authoring principles* (membranes, multisets, cell-like sends),
not a source-to-source lowering onto unmodified `psim`. `psim` cannot check
STI wages or PLN revision; those are semantic claims, so the dialect has its
own runner, the same way R-Lingua has `rlingua`. A Lisp host sketch lives in
`plingua/lang/DIALECTS.md` (élan). This document is the normative plan.

## Implementation plan

The work is ordered so each subsystem stays a P-Lingua membrane concern and
calls the existing header, rather than growing a second cognitive kernel.

1. **Parse** `.ali` into an `AiLinguaSystem` (`ali_parser.hpp` / `ali_parser.cpp`).
   Same-dialect `@import` is inlined; other dialects are recorded and not
   inlined; cycles error; diamonds skip (`dialect_import.hpp`).
2. **Validate cell-like communication.** A rule in membrane X may name a target
   only when that target is X itself (`here`), the parent (`out`), or a direct
   child (`in`). Sibling-to-sibling sends are a parse error. Route them
   `out` to the parent, then `in` to the child — the same rule as
   `psystems/ch01/ch01_decision_making.pli`.
3. **Bind the object quadruple.** Each object is a multiset entry in one
   membrane plus a `PLNTruthValue`, an ECAN `AttentionValue`, and a phase
   integer. ECAN atom ids and AtomSpace concept nodes are allocated from the
   object, not from a side table that can drift away from the membrane.
4. **Run the cognitive cycle** (`ai_engine.hpp`), one clock tick per step:
   `perceive → orient (grip) → decide (PLN) → act → remember (AtomSpace)`.
   ECAN rent/wages run as the attention economy around `act`. MOSES runs
   *between* cycles, when `step % every == 0`.
5. **Emit** a JSON report on every run. `grip_index` and `emergence_score`
   are always present, whether or not `@observe` lists them.

### ECAN as a membrane economy

`@attention ecan` configures `ecan::AttentionBank` (`rentRate`, `afThreshold`,
`totalSTI`, default wage). Objects are registered atoms.

- **Rent** is collected from positive STI each step (`AttentionBank::collectRent`).
- **Wages** are spent by the firing rule (`boostSTI(-wage)` on the LHS object)
  and the rent pool is paid back to the rule atoms that fired
  (`AttentionBank::payWages` via `ECANEngine::step`).
- **Attentional focus** is the set of atoms with `STI >= af_threshold`. The
  `af` child membrane holds one `af_member` token per focused atom. Objects
  are *not* relocated into `af`: moving them would break the membrane a rule
  is allowed to read. Focus is a view, the same way an attentional-focus
  membrane in `opencog_ecan.pli` is a boundary, not a second copy of the
  AtomSpace.
- A rule is wage-eligible only when the LHS object's STI is at least
  `threshold` after `perceive`. Phase eligibility is independent (below).

`rent` is a fraction in `(0, 1]`. The informal sketch `rent 1` is one rent
*token*; the normative rate is `rent 0.01` (the ECAN default, one percent of
positive STI). `wage` is an STI delta, defaulting rules that omit their own.

### PLN on objects

`@truth pln` turns on `pln::PLNTruthValue` and `pln::PLNInferenceEngine` over
the dialect's `atomspace::AtomSpace`.

A rule's `pln` clause is the inference step applied when the rule fires, and
it is also an implication link installed before `performInferenceCycle`:

| Clause | Formula (matches `pln_integration.hpp`) |
|---|---|
| `deduction` | `TV(B) = TV(A→B) ∧ TV(A)` via `PLNTruthValue::conjunction`. The rule is the implication; default TV `(0.9, 0.8)` unless `impl S C` is set. Conclusion is `max`'d onto the existing TV. |
| `abduction` | `strength = s(B) * s(A→B) * 0.8`, `confidence` scaled by `0.6`, then `max`. |
| `revision` | Independent-evidence revision: `s = (s1*c1 + s2*c2) / (c1+c2)`, `c = c1 + c2 - c1*c2`, clamped to `[0, 1]`. |
| `none` (default) | RHS keeps its current TV; phase and attention still update. |

`performDeduction` in the existing engine only rewrites a consequent whose
antecedent strength is above `0.7`. The rule-local formula above is what the
dialect guarantees on the firing step; the engine call is the AtomSpace
witness of the same links.

### MOSES between cycles

`@learn moses` is a meta-rule: the P system rewrites its own rule parameters.

```
@learn moses {
    population 20;
    fitness grip_index;
    evolve rule_set(perception) every 4 ticks;
    mutation_rate 0.1;
    elitism 0.2;
    seed 1;
}
```

- `fitness` must be `grip_index` (the R-Lingua observable). A lower wage is
  only a tie-break, so equal grip prefers the cheaper rule.
- `rule_set(name)` selects rules whose name, membrane, LHS, or RHS is `name`.
  No match means the whole rule population.
- Each evolution tick copies the live wages/thresholds into a population,
  mutates the non-elite fraction (`wage += U(-10, 10)`, threshold `±5`),
  and writes the best genome back. That is single-point parameter crossover
  plus mutation, the same genetic operations the OpenCog MOSES bridge uses
  for combo trees.
- The same tick calls `moses::MOSESEngine`: one training row from object
  truth values, features taken from RR salience (`updateFeaturesFromRR`),
  then `initialise` once and `evolve` once per due tick. `moses_best_score`
  in the report is that bridge's score in `[-1, 0]`.

Evolution does not invent membrane targets. A mutant cannot grow a
sibling send. Only wage and threshold are genes; the `@mu` tree and the
parent/child constraint are immutable, the way symmetry genes are immutable
in the ontogenetic kernel.

### AtomSpace backing

`remember` upserts one concept node per live symbol (`findAtomsByName`, else
`addConceptNode`) with the object's PLN strength and confidence. The node is
the hypergraph image of the membrane object, not a second source of truth.
Implication links installed for `pln deduction` / `abduction` rules are the
only links the dialect adds. `@atomspace { backing memory; }` names the
membrane whose incoming sends are the remember-path (default `memory`).

### What is intentionally not a new parser

Clocks and phase guards are *evaluated* by `ailingua`, not macro-expanded to
`.pli`, because the wage and truth gates would be comments again after
lowering — the failure mode T-Lingua was created to escape. The correspondence
is still defined, so a later lowering pass has a spec:

| Ai-Lingua | P-Lingua image |
|---|---|
| `@clock skin { period N; wrap dN -> skin; reseed R; }` | N phase objects and a wrap rule, as in `tli_lower.py` |
| `when phase == k` | LHS gains `phase(k)`; RHS restores it |
| `when slot == X` | consume-and-restore of `slot(X)` |
| wage / threshold | catalyst check on `sti_unit` before the rewrite (`opencog_ecan.pli`) |
| `pln deduction` | implication object consumed in the `pln` membrane |
| `remember` | `(symbol)in_memory` plus an AtomSpace concept with the same TV |
| MOSES tick | a meta-rule in the `moses` membrane rewriting `wage` / `threshold` objects |

## Formal definition

An Ai-Lingua system `A = (Π, C, E, $, T, M, Ω)` where:

- **Π**: a cell-like P system — membrane tree `μ`, object multisets, rules.
- **C**: one clock `(name, period, wrap, reseed)` and an optional phase register.
- **E**: an R-Lingua ennead (nine dimensions in `[0, 1]`).
- **$**: an ECAN attention bank `(wage, rent, af_threshold, total_sti)`.
- **T**: PLN defaults and per-rule inference clauses.
- **M**: a MOSES schedule `(population, fitness, rule_set, every, mutation_rate, elitism, seed)`.
- **Ω**: the observe block. Grip and emergence are emitted even if Ω is empty.

An object is the quadruple `(symbol, (strength, confidence), (sti, lti, vlti), phase)`
sitting in exactly one membrane with a multiplicity `count`.

## New keywords

| Keyword | Description |
|---|---|
| `@aimodel<cognitive_time_crystal>` | Model declaration. The identifier is required. |
| `@import` | Same contract as M/R-Lingua. `.ali` is inlined; other dialects are companions. |
| `@ennead` / `@triad_a` / `@triad_b` / `@triad_c` | R-Lingua initial ennead. Missing dimensions default to `0.5`. |
| `@clock` | Closed time loop. `period` is at least 1. |
| `@phase_register` | Cyclic slot name per phase, as in T-Lingua. |
| `@attention ecan` | ECAN bank: `wage`, `rent`, `af_threshold`, `total_sti`. |
| `@truth pln` | Enable PLN truth values. Optional `default_strength` / `default_confidence`. |
| `@learn moses` | Evolve rule wages/thresholds every N ticks. Fitness is `grip_index`. |
| `@atomspace` | Name the memory membrane (default `memory`). |
| `@mu` | Cell-like membrane tree. A frame's label follows its closing bracket. |
| `@object` | One quadruple in a membrane. |
| `@rule` | A rewrite gated by phase and wage, optionally sending to parent or child. |
| `def cognitive_cycle()` | Ordered pipeline. `def main()` is an alias. |
| `@observe` | Sample period and extra report fields. |
| `@constraints` | Optional `grip_threshold` copied onto the RR hypergraph. |

## Syntax

### Membrane tree

```
@mu = [ [ [ ]'af ]'ecan [ ]'pln [ ]'moses [ ]'memory ]'skin;
```

`skin` contains `ecan`, `pln`, `moses`, and `memory`. `ecan` contains `af`.
If `@mu` is omitted the runner installs this tree. Labels are the send targets.

### Objects and rules

```
@object perception {
    symbol perception;
    truth 0.9 0.8;          /* strength confidence, both in [0, 1] */
    attention 200;          /* initial STI */
    phase 0;
    membrane skin;
    kind arena;             /* agent | arena | relation | concept | stimulus */
    count 1;
}

@rule attend {
    membrane skin;
    lhs perception;
    rhs concept;
    wage 10;                /* STI spent on fire; default is @attention wage */
    threshold 50;           /* LHS STI must be >= threshold */
    when phase == 0;        /* optional; AND with when slot == name */
    pln deduction;          /* deduction | abduction | revision | none */
    impl 0.9 0.8;           /* implication TV used by deduction/abduction */
    target memory;          /* here | parent | direct child. Default: here */
    restore;                /* catalyst: LHS is not consumed. Wage is still spent. */
}
```

`kind relation` objects count toward `emergence_score`.

### Cognitive cycle

```
def cognitive_cycle() {
    perceive -> orient (grip) -> decide (PLN) -> act -> remember (AtomSpace);
}
```

Stages, in order:

1. **perceive** — stimulate each live object in the clock membrane (default `skin`) by the default wage.
2. **orient (grip)** — copy truth/STI into the RR hypergraph and call `updateRelevanceRealization`. Recompute `grip_index` (mean node grip), `emergence_score`, `ennead_balance`, `relevance_gradient`, `grip_stability`.
3. **decide (PLN)** — upsert concept nodes, install implication links for inference rules, run `PLNInferenceEngine::performInferenceCycle`, copy truth values back.
4. **act** — fire every eligible rule once (reference scheduler: declaration order, one application per rule per step, the `@N{...}` cap of 1). Eligibility is phase gate AND wage gate AND `count(LHS) >= 1` in the rule's membrane. A firing spends `wage`, produces one RHS in the target membrane at the current phase, and applies the PLN clause. A product that did not already exist is seeded with STI `wage` (at least 1). ECAN's forgetting rule removes atoms with `STI <= 0`; without that seed the rewrite would vanish in the same step.
5. **remember (AtomSpace)** — upsert concept nodes for every live symbol.

After the pipeline the runner always:

6. Syncs attention values and calls `ECANEngine::step` with the fired rule ids as wage earners. Projects `af_member` tokens into `af`.
7. If `step % every == 0`, evolves the rule population and calls `MOSESEngine::evolve`.
8. Advances the clock. Phase starts at 0 and increments at the end of the step, wrapping at `period`. On wrap, if `reseed` names a symbol that is absent, one copy is placed in the clock membrane.

Omitting `def cognitive_cycle` selects the five stages above. Metrics are refreshed at the end of every step even if `orient` was omitted, so a run cannot silently drop grip/emergence.

## P-Lingua principles (normative)

These are checked, not commented:

1. Objects are multisets. `count` is the multiplicity. A rule reads only the membrane it is written in.
2. Sends follow the `@mu` tree. `target` must be the rule membrane, its parent, or a direct child. Anything else is `sibling-to-sibling send` and the file does not compile.
3. Maximal parallelism is capped at one application per rule per step so the reference trace is deterministic. Two rules in the same membrane may both fire in one step if each has its own LHS.
4. The scheduler does not relocate objects into the attentional-focus membrane. Focus is a token projection.
5. MOSES may rewrite wages and thresholds. It may not rewrite targets, membranes, or the `@mu` tree.
6. AtomSpace names are the object symbols. There is no second namespace.
7. `@import` resolves relative to the importing file. `.ali` is inlined. A `.pli` / `.tli` / `.rli` / `.mli` companion is recorded with extracted symbols and is not parsed as Ai-Lingua rules.

## Observability

Every successful run writes JSON:

```json
{
  "dialect": "ali",
  "steps_run": 11,
  "phase": 0,
  "wraps": 1,
  "rules_fired": 1,
  "system_metrics": {
    "grip_index": 0.0,
    "emergence_score": 0.0,
    "ennead_balance": 0.0,
    "relevance_gradient": 0.0,
    "grip_stability": 0.0
  },
  "ecan": { "af_size": 1, "atoms": 2 },
  "pln": { "conclusions": 0 },
  "moses": { "generations": 2, "best_score": -1.0, "population_varied": true },
  "atomspace": { "atoms": 2 },
  "objects": [
    {
      "symbol": "perception",
      "membrane": "skin",
      "strength": 0.9,
      "confidence": 0.8,
      "sti": 198,
      "lti": 0,
      "phase": 0,
      "count": 1
    }
  ]
}
```

`grip_index` and `emergence_score` are always present. `rlingua`'s grip report
is the model for the `system_metrics` block; the ECAN/PLN/MOSES/AtomSpace
blocks are the cognitive extension.

```bash
ailingua model.ali -s 11 -v -o report.json
```

| Option | Meaning |
|---|---|
| `-s N` | Run N cognitive cycles (default 0: parse and emit the initial quadruples). |
| `-o file` | JSON report (default stdout). |
| `-v` | Print model stats, imports, and one line per sample period. |
| `--trace=off\|sexpr\|json` | Step wire on stdout (default `off`). With tracing and no `-o`, the JSON report goes to stderr so the wire stays a pure stream. |
| `--no-unicode` | Phase arrow is `->` instead of `→`. |
| `-h` | Help. |

Each traced step emits `(tick <step> (phase <from>→<to>))` when the clock
phase changes, using the phase from before `advanceClock`, and
`(grip <object-id> <score>)` for every live object except `af_member`.
`--trace=json` uses `{"event":"tick",...}` and `{"event":"grip","id":...,"grip":...}`.
Scores are two decimal places. These lines do not change which rules fire.

Verbose import lines match R-Lingua: `Imports: N` and
`import <dialect> <path> (inlined|companion) symbols=K`.

## Example

The runnable model is `plingua/examples/ailingua/cognitive_cycle.ali`.
It is the issue sketch, normalized (`rent 0.01`, an explicit `@mu`, a
restoring phase-gated deduction into `memory`) plus a `.pli` companion that
is recorded and not inlined.

```ali
@aimodel<cognitive_time_crystal>

@ennead { … }                         /* R-Lingua agent/arena/relation */
@clock skin { period 11; wrap d11 -> skin; reseed singularity_point; }
@attention ecan { wage 10; rent 0.01; af_threshold 100; }
@truth pln;

@learn moses {
    population 20;
    fitness grip_index;
    evolve rule_set(perception) every 4 ticks;
}

def cognitive_cycle() {
    perceive -> orient (grip) -> decide (PLN) -> act -> remember (AtomSpace);
}
```

## Authoring checklist

- [ ] `@aimodel<cognitive_time_crystal>` is present (`@import` may precede it).
- [ ] `@mu` labels (or the default tree) include every membrane a rule or object names.
- [ ] No rule `target` is a sibling. Parent, child, or `here` only.
- [ ] `@clock` `period` is at least 1. Phase guards use `when phase == k` with `0 <= k < period`.
- [ ] Truth components are in `[0, 1]`. STI fits in a signed 16-bit attention value.
- [ ] `@learn` fitness is `grip_index`. `every` is at least 1 if the block is present.
- [ ] A repeating percept is `restore`d (catalyst) or reseeded; otherwise one firing consumes it.
- [ ] `@observe` may be omitted; grip and emergence are still emitted.

## Relationship to the other dialects

| Dialect | Role |
|---|---|
| P-Lingua (`.pli`) | discrete multiset rewriting — the base principles |
| M-Lingua (`.mli`) | spatial geometry (companion import, not inlined) |
| R-Lingua (`.rli`) | ennead, grip, emergence — the observables Ai-Lingua emits |
| T-Lingua (`.tli`) | clocks, phase registers, phase guards — the temporal core |
| **Ai-Lingua (`.ali`)** | cognitive time crystal: T + R + ECAN/PLN/MOSES + AtomSpace |
| L-Lingua / élan | s-expression host sketch of the same quadruple (`lang/DIALECTS.md`) |

## Build

```bash
cd plingua
make acompiler          # bin/ailingua
make bin/test_ailingua
./bin/test_ailingua
make check-ailingua     # unit tests + the cognitive_cycle example
```

No new libraries. The runner includes the existing header-only bridges
(`ecan_integration.hpp`, `pln_integration.hpp`, `moses_integration.hpp`,
`atomspace_integration.hpp`, `relevance_realization.hpp`).
