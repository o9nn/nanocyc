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

## `psim --trace` modes

`--trace=off|sexpr|json|human|diff`.  `sexpr` is the cross-engine wire format.
`json` is one object per line (`event` is `header`, `fired`, `tick`,
`resonance`, `checkpoint`, or `halted`).  `human` draws `--glyph / --wire /
--checkpoint` side by side, and stacks those panes when the terminal (or
`COLUMNS`) is under 120 columns.  `diff` uses the same panes but skips a step
whose multiset and membrane tree did not change.  `--no-unicode` switches the
glyph and the phase arrow (`→` vs `->`).

Fired events print the rule's `@name` when the compiler stored one, otherwise
`r<index>`.  A pure phase ring (`d1`…`dN`, clock objects only) collapses to one
glyph row (`[phase d1..dN @ dK tick ]`); the s-expr checkpoint still lists
every membrane.  A tick that falls into the next phase membrane also emits
`(tick <step> (phase <from>-><to>))`.  `@resonance` / `@partner` emit
`(resonance (<mem> <partner>) (match …))` as a trace annotation — they do not
change which rules fire.

Regression: `make -C plingua check-trace` (fixtures in `examples/trace/`).
