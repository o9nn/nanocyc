# Cross-validation fixtures

Each fixture pairs a **standard P-Lingua** model (`*.pli`, runnable by the
bundled C++ `psim`) with the **same model** written in the canonical s-expr
form (`*.scm`, runnable by the Scheme kernel).  Both must halt in the same
configuration — that is the cross-engine check.

| Fixture | Exercises |
|---|---|
| `send_in` | `a` in skin rewrites to `b` here **and** sends `b` into child; child doubles `b`→`c*2`. Tests `(in k)` routing + 2-step latency. |
| `send_out` | child sends `y` out to skin. Tests `out` routing up the tree. |
| `two_children` | skin broadcasts into two children independently. Tests sibling routing isolation. |

Run the whole harness:

```bash
bash ../xcheck.sh
```

It compiles each `.pli` with `plingua`, simulates with `psim`, runs the Scheme
kernel on the `.scm` twin, and diffs the canonical `(final ...)` lines.
