# G-Systems Specification (draft)

## Overview

G-systems (Gauge systems) are the proposed generalization of the three
membrane-computing dialects maintained in this repository:

| Pole | Dialect | Extension | Contributes |
|---|---|---|---|
| **P** | P-Lingua | `.pli` | Discrete multiset rewriting inside a membrane hierarchy (matter/state) |
| **M** | M-Lingua | `.mli` | Spatial realization: tiles, glues, manifolds, metrics, connections (geometry) |
| **R** | R-Lingua | `.rli` | Agent–arena–relation coupling and grip optimization (dynamics of fit) |

The purpose of a G-system is **gauge-invariant parallel transport of
n-forms** over the membrane structure: quantities attached to membranes
(0-forms), to inter-membrane channels (1-forms), or to higher facets
(n-forms) must transform consistently when moved through the system, so that
all observable results are independent of arbitrary local labeling choices.

This document derives the G-system definition from the (P,M,R) triad and
maps every ingredient to constructs that already exist in the toolchain, so
that G-models can be prototyped today in plain P-Lingua (see
`examples/todo_g_gauge_parallel_transport.pli`) before dedicated syntax lands.

## Derivation from (P,M,R)

A membrane structure is a rooted tree (cell-like) or graph (tissue-like).
Each dialect contributes one layer of the fiber-bundle picture:

1. **P provides the base complex.** Membranes are vertices; communication
   channels (`(u)in_h`, `(u)out`, antiport `[u]'h1 <--> [v]'h2`) are oriented
   edges. Multisets are sections of a discrete bundle: an object `x{g}`
   carrying an index is a fiber element over its membrane.
2. **M provides the connection.** `@connection nabla(type=..., bundle=...)`
   (see `MLINGUA_SPEC.md`) declares how fibers over adjacent cells are
   identified. In discrete form a connection is a **link field**: an
   assignment of a group element `U(e) ∈ G` to every oriented edge `e`, with
   `U(e⁻¹) = U(e)⁻¹`. `@capability gauge_invariance` asserts that model
   observables must not depend on local trivializations.
3. **R provides the invariance criterion.** The agent–arena **relation** is
   meaningful only if it is stable under re-description of either side.
   Grip metrics must therefore be built from gauge-invariant quantities
   (holonomies, Wilson loops), never from bare fiber coordinates.

## Formal Definition

A **G-system** of degree `n` is a tuple

```
G = (Γ, G, U, Ω, R, i)
```

where:

- `Γ` — a membrane complex: cells `Γ₀` (membranes), channels `Γ₁`
  (communication edges), and higher facets `Γ₂, …, Γₙ` (closed channel
  loops, loop-of-loop shells);
- `G` — a finite **gauge group** (e.g. `Z_k`, `S_k`); fibers are `G`-sets;
- `U : Γ₁ → G` — the **link field** (discrete connection);
- `Ω` — object alphabet; transported objects are pairs `x{g}` of a species
  `x ∈ Ω` and a fiber index `g ∈ G`;
- `R` — rewriting rules in the P sense, restricted to the two
  **covariant** rule schemas below;
- `i` — initial configuration.

### Covariant transport rule

Moving `x{g}` across edge `e = (h₁ → h₂)` must multiply the fiber index by
the link element:

```
[x{g}]'h1 → (x{g·U(e)})in_h2      (transport)
```

In plain P-Lingua the group product is precomputed per edge, giving one
concrete rule per `(g, e)` pair — exactly the encoding used in
`todo_g_gauge_parallel_transport.pli`.

### Gauge transformation

A gauge transformation is a relabeling `λ : Γ₀ → G` of every fiber:

```
x{g}  over h   ↦  x{g·λ(h)}
U(e=(h₁→h₂))   ↦  λ(h₁)⁻¹ · U(e) · λ(h₂)     (for right-action transport g ↦ g·U(e))
```

Configurations related by `λ` are **physically identical**. A model is
gauge-invariant iff every halting observable is unchanged under all `λ`.

### Holonomy and Wilson loops

For a closed loop `ℓ = e₁ e₂ … e_k` the **holonomy** is

```
Hol(ℓ) = U(e₁) · U(e₂) · ⋯ · U(e_k)
```

Under a gauge transformation `Hol(ℓ)` is conjugated by `λ(base)`; its
**conjugacy class** (for abelian `G`, its value) is invariant. Wilson-loop
observables `W(ℓ) = χ(Hol(ℓ))` for a character `χ` of `G` are the canonical
gauge-invariant outputs of a G-system.

### Parallel transport of n-forms

- **0-forms** (membrane-valued data): transported by the covariant rule
  above; comparing values at different membranes requires transport along a
  chosen path.
- **1-forms** (channel-valued data): a 1-form assigns a fiber value to each
  edge; transport around a facet boundary accumulates the facet holonomy.
- **n-forms**: values on `Γₙ` facets; the discrete exterior covariant
  derivative `d_U ω` evaluates `ω` on facet boundaries with each summand
  transported to a common base point. Gauge invariance of `d_U` follows
  from the covariance of the transport rule, mirroring lattice gauge theory
  (Wilson 1974) on the membrane complex.

## Proposed Keywords

Staged extension of the M-Lingua metadata directives (all parse today as
model metadata; simulator semantics to follow):

| Keyword | Meaning |
|---|---|
| `@gauge_group G(order=k, type=cyclic\|symmetric)` | Declares the gauge group |
| `@link u(from=h1, to=h2, element=g)` | Assigns `U(e) = g` to a channel |
| `@form omega(degree=n, support=[...])` | Declares an n-form field |
| `@holonomy hol(loop=[h1,h2,...])` | Declares a holonomy observable |
| `@wilson w(loop=..., character=chi)` | Declares a Wilson-loop observable |
| `@capability gauge_invariance` | Reused from M-Lingua: enables invariance checks |

## Rule Types

1. **Transport rules** — the covariant schema above; the only rules allowed
   to change an object's membrane.
2. **Curvature rules** — fire on facets where `Hol(∂f) ≠ 1`, producing
   curvature markers (source terms for higher-form dynamics).
3. **Gauge-fixing rules** — apply a gauge transformation `λ` at one
   membrane (relabel fibers + conjugate incident links). Semantically a
   no-op on observables; used to test invariance.
4. **Measurement rules** — project accumulated fiber indices onto
   gauge-invariant tokens (e.g. emit `wilson{c}` where `c = Hol(ℓ)` class).

## Prototyping in plain P-Lingua

Until dedicated syntax exists, a G-model of degree 1 with abelian `G = Z_k`
is expressible with the communication schemas of the `membrane_division`
model (whose send-out/send-in templates transform objects while they cross
a membrane; no structural rules are needed):

- fiber-indexed objects `x{g}`, `g ∈ {0..k-1}`;
- one transport rule per `(g, edge)` with the sum `g + U(e) mod k` unrolled;
- a measurement rule mapping the returned index to a `wilson{c}` token;
- gauge checking by re-running with a transformed link field and comparing
  the `wilson` output.

`examples/todo_g_gauge_parallel_transport.pli` implements exactly this: a
3-membrane cycle with `Z_3` links `U = (1, 2, 1)`, total holonomy
`1+2+1 = 4 ≡ 1 (mod 3)`, and a gauge-transformed twin field
`U' = (0, 0, 1)` (gauge `λ = (0, 2, 0)` applied at the three cells) whose
probe provably returns the **same** Wilson class `1`.

## Relation to P-Lingua, M-Lingua and R-Lingua

- Every G-system forgets to a P-system by erasing fiber indices.
- The link field is the discrete shadow of an M-Lingua `@connection`; facet
  holonomy is the discrete curvature of `@flow` geometry.
- R-Lingua grip metrics defined on Wilson observables are automatically
  re-description-stable, closing the loop with the RR requirement that
  agent–arena fit be independent of arbitrary labels.

## Authoring Checklist

1. Declare the gauge group and link field; keep `U(e⁻¹) = U(e)⁻¹`.
2. Use only covariant transport rules to move fiber-indexed objects.
3. Output through holonomy/Wilson measurements — never bare fiber indices.
4. Include a gauge-transformed twin (or gauge-fixing rules) in tests and
   assert observables are unchanged.
5. Document the loop, expected holonomy class, and halting configuration in
   the file header, as done in `examples/todo_g_gauge_parallel_transport.pli`.

## References

- Wilson, K. G. (1974). Confinement of quarks. *Physical Review D* 10, 2445.
- Baez, J. C., Muniain, J. P. (1994). *Gauge Fields, Knots and Gravity*.
- Păun, Gh. (2000). Computing with membranes. *JCSS* 61(1), 108–143.
- Desbrun, M., Hirani, A. N., Leok, M., Marsden, J. E. (2005). Discrete
  Exterior Calculus. arXiv:math/0508341.
- `docs/MLINGUA_SPEC.md` (geometry directives), `docs/RLINGUA_SPEC.md`
  (grip metrics), `examples/TODO_EXAMPLES_CATALOG.md` §8.
