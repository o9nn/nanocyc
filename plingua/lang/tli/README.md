# T-Lingua (`.tli`) — temporal/tensor dialect

T-Lingua is the time-crystal dialect of the P-Lingua family.  It makes the
machinery that the `psystems/` corpus hand-encodes — closed tick rings, phase
registers, prime-signature gating, resonance coupling — into language
primitives.  See `plingua/docs/TLINGUA_SPEC.md` for the full specification.

**Verifying compiler = `tlingua`.** From `plingua/`:

```bash
make tcompiler
make check-tlingua
bin/tlingua examples/tlingua/time_crystal_neuron.tli -s 11 -v
```

`tlingua` checks the 11-cycle, circular phase distance, prime gating, and
resonance exchange on a language-owned ring.  `tli_lower.py` remains the
bootstrap lowerer: it expands a `.tli` model into plain P-Lingua so the result
still runs on the unmodified `psim` / `psystems/validate.sh` pipeline.

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

## Native verification

`tlingua` is that check.  A clock is a ring of `period` phases; phase 0 is the
rim, and after `period` steps the wrap count is 1.  `circ(10, 0, 11)` is 1.
A prime gate is open only when `step % signature == 0`.  Resonance `match`
exchanges when signatures intersect; `mismatch` dissipates.  Spinor and
fractal files in `profiles/` are imported libraries, not dialects.
