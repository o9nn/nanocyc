# L-Lingua across the Lisp family

The s-expr kernel (`scm/plingua/psystem.scm`) is deliberately tiny — three
functions over one data format — so it ports to any Lisp in an afternoon.  This
note is the map: which dialect does what, and how they cross-check each other.

## The architecture rule

> **One semantic kernel, dialect-specific readers/macros/printers.**
> Scheme holds the reference kernel; Racket adds the `.pli` reader; Elisp adds
> the display; Guile adds C-embedding for cross-validation against `psim`.

| Dialect | Role in the stack | Status |
|---|---|---|
| **Scheme (R⁷RS / Guile)** | reference kernel — `scm/plingua/psystem.scm` | ✅ implemented + tested |
| **Racket** | language-oriented host — `rkt/` reader + kernel | ✅ implemented + tested |
| **Elisp** | display king — `elisp/plingua-mode.el` three panes | ✅ implemented + ERT-tested |
| **Guile (C-embed)** | bridge to C++ `psim` for cross-checking | sketch below |
| **Common Lisp** | performance (CLOS, compiled) | straightforward port |
| **NetLogo** | education/demo (agent-sets as membranes) | not a real simulator |
| **élan** | the cognitive variant — AI-Lingua testbed | sketch below |

## Guile ↔ C++ bridge (cross-validation by construction)

Guile embeds in C.  The bridge lets the same model run in both engines and
assert identical halting multisets — catching bugs in *either* engine:

```c
/* psim_guile_check.c — link against libguile + the psim objects */
#include <libguile.h>

/* Run the Scheme kernel on model.scm, return the canonical (final ...) string. */
static const char *scm_final(const char *model_path) {
    scm_c_eval_string("(use-modules (plingua psystem))");
    /* load the model, run, format the canonical final line */
    return scm_to_locale_string(
        scm_c_eval_string("(begin (load model) (canonical-final model))"));
}
```

The shell harness `scm/xcheck.sh` already does this comparison without the C
bridge (both engines print the same canonical line); the C bridge turns it into
a *property-based* check over generated models.

## élan — the AI-Lingua testbed

élan (the echolisp extension) is positioned as the **cognitive** variant: the
kernel plus an ECAN attention economy and PLN truth values on objects,
mirroring `plingua/include/ecan_integration.hpp` / `pln_integration.hpp`.

Objects become `(symbol truth attention)` triples; rule firing spends STI wages
and pays rent; PLN revision merges evidence when the same object arrives by two
paths.  The canonical model grows an attention/ truth annotation:

```lisp
(psystem
  (membrane 0 (label skin) (parent #f)
    (objects ((perception . 1) <tv (0.9 0.8)> <sti 120>))
    (rules
      ;; rule firing gated by attention: only fires while sti > threshold
      (rule attend (lhs ((perception . 1)))
            (rhs (((concept . 1) (in 1))))
            (attend (wage 10) (threshold 50)))
      ;; PLN deduction: two perceptions revise into a stronger concept
      (rule revise (lhs ((concept . 2)))
            (rhs ((concept . 1)))
            (pln revision)))))
```

This is the natural host for the **AI-Lingua** experiment of
`plingua/docs/TLINGUA_SPEC.md`: T-Lingua temporal core + R-Lingua observables +
ECAN/PLN economics, all expressed as membrane rules.

## Cross-dialect consistency

Every engine prints the canonical `(final ((id label ((sym . n) …)) …))` line.
`scm/xcheck.sh` currently enforces C++ = Scheme = Racket; each new dialect adds
one line to that harness.
