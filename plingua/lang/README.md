# L-Lingua: the s-expression membrane-computing layer

**A P system *is* a nested s-expression.** The membrane structure is a tree, a
multiset is an association list `((symbol . count) …)`, a configuration is one
s-expression, and a computation is a sequence of configurations. The program
text is the membrane.

This directory holds the **host-agnostic s-expr kernel** plus per-dialect
readers and renderers. One semantic core, many surface syntaxes — the same
model must produce the same halting configuration in every engine, which is
what the cross-validation harness enforces.

## Canonical model format

```lisp
(psystem
  (membrane 0 (label skin) (parent #f)
    (objects ((a . 3)))                       ; multiset: a×3
    (rules
      (rule send (lhs ((a . 1)))
            (rhs ((b . 1) ((b . 1) (in 1)))))) ; a → b here + b into child 1
    (membrane 1 (label inner) (parent 0)
      (objects ())
      (rules
        (rule consume (lhs ((b . 1))) (rhs ((c . 2))))))))
```

RHS products are `(sym . count)` (stay here), `((sym . count) out)` (to
parent), or `((sym . count) (in <id>))` (into child `<id>`).

## The three kernel functions

| Function | Meaning |
|---|---|
| `match-rules` | rule instances whose LHS ⊆ membrane multiset |
| `apply-step` | one maximally-parallel step: consume LHS, produce RHS, route `(in k)`/`out`/`here` |
| `run` | iterate to halting, yielding the s-expr event stream |

Because the configuration is a single immutable s-expr per step, time-travel,
replay and checkpointing come free.

## Layout

| Path | Contents |
|---|---|
| `scm/plingua/psystem.scm` | reference kernel (R7RS + SRFI-1/11), Guile |
| `scm/test-psystem.scm` | 20 unit tests |
| `scm/xcheck.{scm,sh}` `scm/xcheck_psim.py` | cross-validation harness |
| `scm/fixtures/` | paired `.pli` + `.scm` twin models |
| `rkt/psystem.rkt` | Racket port of the kernel |
| `rkt/pli-reader.rkt` | `.pli` → s-expr reader (the `#lang plingua` reader half) |
| `rkt/pli-run.rkt` | parse + simulate a `.pli`, print the canonical trace |
| `elisp/plingua-mode.el` | three-pane --glyph/--wire/--checkpoint display (Emacs) |

## Cross-validation

```bash
bash scm/xcheck.sh        # compiles each .pli with bin/plingua, simulates with
                          # bin/psim, runs the Guile and Racket kernels, and
                          # diffs the canonical (final ...) lines
```

All three engines must agree byte-for-byte on the halting configuration.

## The wire / checkpoint trace

`bin/psim --trace=sexpr` and the Lisp kernels emit the same s-expr streams:

```
(seed 0) (steps 100) (model "send_in.pli")
(fired (step 0) (membrane 0) (rule send) (consumed ((a . 3))) (produced ((b . 3) ((b . 3) (in 1)))))
(fired (step 1) (membrane 1) (rule consume) (consumed ((b . 3))) (produced ((c . 6) here)))
(halted (steps 2) (reason no-applicable-rules))
(final ((0 skin ((b . 3))) (1 inner ((c . 6)))))
```

`--trace=human` renders the three-pane `--glyph / --wire / --checkpoint`
layout (box-drawing membrane tree, event wire, full checkpoint), with an
`--no-unicode` ASCII fallback.

## Plan: remaining `psim --trace` work

Already implemented (do not redo): `--trace=off|sexpr|human`,
`--checkpoint-every`, `--no-unicode`, the `(seed …) (steps …) (model …)`
header, `(fired …)` events, glyph panes, checkpoint s-exprs, and the
`(halted (steps N) (reason max-steps|no-applicable-rules))` line from
`src/simulator/psim/psim.cpp`.

Remaining, owned by the intelligible-trace issue rather than the dialect
extensions:

1. **`--trace=json`.** Add the mode beside the existing check in
   `src/simulator/command_line.cpp`, and emit one JSON object per step from
   `Simulator::stepEventLines()` (`include/simulator/simulator.hpp`) instead of
   an s-expr. Keep `sexpr` as the cross-engine wire format.
2. **`--trace=diff`.** Remember the previous checkpoint and redraw only when
   the multiset or membrane tree changes. Hook this in `traceHumanStep`, which
   already owns the pane render.
3. **Narrow terminals.** `traceHumanStep` assumes a wide layout. If the
   terminal width is under 120 columns, stack glyph, wire, and checkpoint
   vertically instead of side by side. Read width once per step; do not
   require a new flag.
4. **11-deep time-crystal collapse.** Chapter models nest an 11-phase clock.
   In human mode, collapse a pure phase ring (`phase(0)` … wrap) to a single
   glyph row so the pane stays readable. Do not change the s-expr wire.
5. **Named rules.** Fired events currently print `(rule r<index>)`
   (`stepEventLines`, the `"r" << it2->first` field). Prefer the rule's
   source name when the compiler stored one, and fall back to `r<index>`.

T-Lingua wire atoms (`tick`, resonance, grip) belong to the T-Lingua
simulator, not to this `psim` plan.
