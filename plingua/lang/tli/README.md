# T-Lingua (`.tli`) — temporal/tensor dialect

T-Lingua is the time-crystal dialect of the P-Lingua family.  It makes the
machinery that the `psystems/` corpus hand-encodes — closed tick rings, phase
registers, prime-signature gating, resonance coupling — into language
primitives.  See `plingua/docs/TLINGUA_SPEC.md` for the full specification.

**Reference implementation = source-to-source lowering.** `tli_lower.py`
expands a `.tli` model into plain P-Lingua (`.pli`), so the result runs on the
unmodified `psim` / `psystems/validate.sh` pipeline.  No simulator changes.

## Lowering

```bash
python3 tli_lower.py time_crystal_core.tli -o time_crystal_core.pli
python3 tli_lower.py cfga_operator.tli      -o cfga_operator.pli
```

## Exemplar ports

| `.tli` source | ports | `.tli` lines | hand-written `.pli` lines |
|---|---|---|---|
| `time_crystal_core.tli` | `psystems/common/time_crystal_core.pli` | **17** | 36 |
| `cfga_operator.tli` | `psystems/ch04/ch04_cfga_operator.pli` | **42** | 85 |

The 11-phase closed time loop that `time_crystal_core.pli` spells out as
13 tick rules + 11 nested membranes collapses to one declaration:

```
@clock tick { period 11; wrap d11 -> skin; reseed singularity_point; }
```

and the CFGA 13-operation ring (a `phase(p)` register + 13 `slot(x)` objects +
advance + wrap in the `.pli`) collapses to:

```
@phase_register cfga { cycle 13;
  slots [add sub mul div diff int inner outer geometric
         project reject rotate reflect]; }

[fire : operator * slot(add) * fuel --> done(add)]'cfga  when slot == add;
```

The `when slot == X` guard lowers to consume-and-restore of the slot object,
so the register keeps cycling; `@phase_register` lowers to the `phase(0)`
register, the 13 slot objects, and the wrap rule.

## Validation

The lowered `.pli` files have balanced brackets, a declared `@mu` tree, named
`--> ` rules, and no undeclared membrane labels — the same structural-lint
checks `psystems/validate.sh` enforces.

## What's next (native support)

Lowering is the bootstrap.  Native `.tli` support in the simulator would let
the engine *check* the temporal invariants (the 11-cycle, phase guards, prime
gating) instead of merely expanding them — that is the payoff that justifies
the dialect's existence.
