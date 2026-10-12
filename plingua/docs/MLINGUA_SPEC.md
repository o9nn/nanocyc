# M-Lingua Specification (`.mli`)

## Overview

M-Lingua is a domain-specific language for **Morphogenetic Systems (M systems)**,
extending P-Lingua (`.pli`) for membrane computing with spatial geometry, tile
self-assembly, and morphogenetic processes.

M-Lingua is a strict superset of P-Lingua: every valid `.pli` file is also a
valid `.mli` file. The `.mli` extension adds constructs for defining tiles,
connectors, glues, protions, floating objects with spatial properties, and
M-system-specific rule types (creation, destruction, division, metabolic).

## Formal Definition

An M system `M = (F, P, T, μ, R, σ)` where:

- **F = (O, m, ρ, ε)**: Catalog of floating objects with mobility, radius, concentration
- **P**: Set of protions (analogous to proteins on membranes)
- **T = (Q, G, γ, dg, S)**: Polytopic tile system
- **μ**: Mapping of protions to positions on tiles
- **R**: Finite set of reaction rules
- **σ**: Glue-pair to floating-object release mapping

## New Keywords

| Keyword | Description |
|---------|-------------|
| `@msystem` | Declares an M system model |
| `@tiling` | Defines the polytopic tile system |
| `@tile` | Defines a tile (polytope) |
| `@connector` | Defines a connector on a tile |
| `@glue` | Defines a glue |
| `@glue_relation` | Defines which glues can bind |
| `@protion` | Defines a protion (protein-like object) |
| `@floating` | Defines a floating object catalog |
| `@seed` | Defines seed tiles |
| `@glue_radius` | Gluing distance |
| `@sigma` | Glue-pair release mapping |
| `@geometry` | Selects geometry profile (`euclidean`, `projective`, `hyperbolic`, custom) |
| `@manifold` | Declares manifold metadata (charts, dimension, compactness) |
| `@metric` | Declares metric tensor family metadata |
| `@connection` | Declares connection metadata (e.g., Levi-Civita, gauge) |
| `@polytope` | Declares high-dimensional polytope incidence metadata |
| `@flow` | Declares geometric flow metadata (e.g., discrete Ricci) |
| `@capability` | Enables capability/invariant flags (e.g., gauge invariance) |
| `@fractal` | Self-similar tiling profile: `depth`, `scale`, and a `tile` that must exist in the tiling. Not a separate grammar |
| `@import` | Composes another module. `@import "rel.mli";` or `@import <rel.pli>;`. Same-dialect `.mli` files are inlined; other dialects are recorded as companions and not inlined |

## Rule Types

### Metabolic Rules (from P-Lingua, extended)

```
// Simple
u --> v;

// Catalytic (protion-mediated)
p: u --> v;

// Symport (in)
u [| p --> [| p u;

// Symport (out)
[| p u --> u [| p;

// Antiport
u [| p v --> v [| p u;
```

### Creation Rules

```
// Floating objects create a tile
@create u --> t;
```

### Destruction Rules

```
// Consume tile and floating objects, produce floating objects
@destroy u, t --> v;
```

### Division Rules

```
// Disconnect two tiles at glue pair
@divide g1, u, g2 --> g1, g2;
```

## Tile Definition Syntax

```mli
@tile name(sides=N, radius=R) {
    @connector c1(vertices=[v1,v2], glue=g1, angle=90);
    @connector c2(vertices=[v2,v3], glue=g1, angle=90);
    @surface_glue gx;
    @color Blue alpha=128;
    @protion p1 at (x, y);
}
```

## Geometry & Advanced Topology Directives

```mli
@geometry<projective>;
@manifold sphere(charts=8, dimension=2, compact=true);
@metric g(type=riemannian, signature=+++);
@connection nabla(type=levi_civita, bundle=tangent);
@capability gauge_invariance;
@flow rf(type=discrete_ricci, step=0.02, iterations=25, preserve_volume=true);
@polytope c120(dimension=4, vertices=600, edges=1200, faces=720, cells=120, symmetry=H4);
```

These directives are currently parsed as **model metadata** and are designed to
keep backward compatibility while enabling staged language evolution for
higher-dimensional and non-Euclidean experiments.

`@fractal` is the F-Lingua profile, parsed here rather than by a new grammar.
The tile must already be declared in `@tiling` (including tiles inlined by
`@import`). `depth` must be at least 1 and `scale` must be greater than 0.
The directive is omitted from Cytos XML and binary archives, the same way
`@import` metadata is.

```mli
@fractal {
    depth 3;
    scale 0.5;
    tile scale_1;
}
```

## Full Example: Boxy Hallows

```mli
@msystem<morphogenetic>

@tiling {
    @glue g1;
    @glue gx;
    @glue_relation(g1, g1);
    @glue_radius 0.1;

    @tile d(sides=4, radius=2) {
        @connector c1(vertices=[v1,v2], glue=g1, angle=90);
        @connector c2(vertices=[v2,v3], glue=g1, angle=90);
        @connector c3(vertices=[v3,v4], glue=g1, angle=90);
        @connector c4(vertices=[v4,v1], glue=g1, angle=90);
        @surface_glue gx;
        @color Blue alpha=128;
    }

    @seed d at (0, 0, 0);
}

@floating a(mobility=5, radius=0.05, concentration=10);

def main() {
    @create a --> d;
    @divide g1, a, g1 --> g1, g1;
}
```

## Relation to Cytos XML

M-Lingua `.mli` files can be compiled to Cytos-compatible XML for simulation
in the Cytos/Unity visualization engine, or simulated directly by `msim`.

| M-Lingua | Cytos XML |
|----------|-----------|
| `@tile` | `<tile>` |
| `@connector` | `<connector>` |
| `@glue_relation` | `<glueTuple>` |
| `@floating` | `<floatingObject>` |
| `@protion` | `<protein>` |
| `@create` | `<evoRule type="Create">` |
| `@destroy` | `<evoRule type="Destroy">` |
| `@divide` | `<evoRule type="Divide">` |

## Model Types

- `@msystem<morphogenetic>` — Full M system with tiles and spatial geometry
- `@msystem<tissue_morphogenetic>` — Tissue-like M system with graph topology
- `@model<transition>` — Standard P-Lingua transition (backward compatible)
- `@model<probabilistic>` — Standard P-Lingua probabilistic (backward compatible)

## Composition (`@import`)

```
@import "ch02_singularity_assembly.pli";
@import <../common/assembly_glues.mli>;
```

- Paths are resolved relative to the importing file. Absolute paths are used as given. `.` and `..` are normalized.
- A `.mli` import is inlined into the current system (tiles, glues, rules append; the host is not reset).
- A `.pli` (or any non-`.mli`) import is a companion record: path, dialect, and extracted symbols (`@mu` labels for `.pli`). Its rules are not parsed, so cell-like `[ lhs --> rhs ]'mem;` syntax cannot be misread as a metabolic rule.
- A repeated import of the same normalized path is skipped. A cycle is an error. A missing file or a malformed `@import` is an error.
- `mlingua -v` prints `Imports: N` and one `import <dialect> <path> (inlined|companion) symbols=K` line per module.

Chapter geometric hybrids live beside their discrete specs under `psystems/ch02`, `ch06`, `ch08`, and `ch09`. `make check-extensions` compiles all eight.
