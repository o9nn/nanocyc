#!/usr/bin/env python3
"""tli_lower.py --- lower a T-Lingua (.tli) model to plain P-Lingua (.pli).

This is the reference source-to-source compiler for T-Lingua (see
plingua/docs/TLINGUA_SPEC.md).  It expands the temporal constructs into the
explicit tick-ring pattern that the psystems/ corpus writes by hand, so the
lowered .pli runs on the unmodified psim / validate.sh pipeline:

  @clock name { period N; wrap A -> B; reseed R; }
      -> N nested phase membranes d1..dN + tick-fall rules + wrap + reseed

  @phase_register r { cycle N; slots [s1 ... sN]; }
      -> slot(s) objects + a phase(i) counter + advance + wrap rules

  [r : lhs --> rhs]'m when slot == X;
      -> [r : lhs * slot(X) --> rhs * slot(X)]'m;   (consume+restore the slot)

Usage: tli_lower.py <input.tli> [-o output.pli]      (default: stdout)

The lowered output targets the *psystems authoring convention* (top-level @mu,
named rules `[name : ...]'mem`, `(obj)in_x`) used across psystems/*.pli, which
is the superset accepted by psystems/validate.sh.
"""

import re
import sys


# ---------------------------------------------------------------------------
# tokenize / small helpers
# ---------------------------------------------------------------------------

def strip_comments(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    src = re.sub(r"//[^\n]*", "", src)
    return src


def find_block(src, start):
    """Given src[start] == '{', return (body, end_index_after_closing_brace)."""
    assert src[start] == "{"
    depth = 0
    for i in range(start, len(src)):
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
            if depth == 0:
                return src[start + 1:i], i + 1
    raise ValueError("unterminated block")


# ---------------------------------------------------------------------------
# directive parsing
# ---------------------------------------------------------------------------

class Clock:
    def __init__(self, name, period, wrap_from, wrap_to, reseed):
        self.name = name
        self.period = period
        self.wrap_from = wrap_from
        self.wrap_to = wrap_to
        self.reseed = reseed


class PhaseRegister:
    def __init__(self, name, cycle, slots):
        self.name = name
        self.cycle = cycle
        self.slots = slots


def parse_clock(body, name):
    period = int(re.search(r"period\s+(\d+)", body).group(1))
    wm = re.search(r"wrap\s+(\w+)\s*->\s*(\w+)", body)
    wrap_from, wrap_to = (wm.group(1), wm.group(2)) if wm else (None, None)
    rm = re.search(r"reseed\s+(\w+)", body)
    reseed = rm.group(1) if rm else None
    return Clock(name, period, wrap_from, wrap_to, reseed)


def parse_phase_register(body, name):
    cycle = int(re.search(r"cycle\s+(\d+)", body).group(1))
    sm = re.search(r"slots\s*\[([^\]]*)\]", body)
    slots = sm.group(1).split() if sm else []
    return PhaseRegister(name, cycle, slots)


# ---------------------------------------------------------------------------
# lowering
# ---------------------------------------------------------------------------

def lower(src):
    """Return the lowered .pli text."""
    raw = src
    src = strip_comments(src)

    out = []
    # header
    title = "lowered from T-Lingua"
    m = re.search(r"@tmodel<(\w+)>", src)
    model = m.group(1) if m else "time_crystal"

    clocks = []
    registers = []
    manual_mu = None
    extra_init = {}   # label -> multiset text

    # ---- @clock -----------------------------------------------------------
    for m in re.finditer(r"@clock\s+(\w+)\s*\{", src):
        body, _ = find_block(src, m.end() - 1)
        clocks.append(parse_clock(body, m.group(1)))

    # ---- @phase_register --------------------------------------------------
    for m in re.finditer(r"@phase_register\s+(\w+)\s*\{", src):
        body, _ = find_block(src, m.end() - 1)
        registers.append(PhaseRegister(
            m.group(1),
            int(re.search(r"cycle\s+(\d+)", body).group(1)),
            re.search(r"slots\s*\[([^\]]*)\]", body).group(1).split()))

    # ---- @mu (manual structure, if any) -----------------------------------
    mu_m = re.search(r"@mu\s*=\s*(.*?);", src, re.S)
    if mu_m:
        manual_mu = mu_m.group(1).strip()

    # ---- @m<label> = ... ; initial multisets -------------------------------
    # (skip @mu itself: `mu` would be captured as label "u" by \w+ — exclude it)
    for m in re.finditer(r"@m(\w+)\s*=\s*([^;]*);", src):
        if m.group(1) == "u":
            continue
        extra_init[m.group(1)] = m.group(2).strip()

    # ---- plain rules (keep, expanding `when slot == X`) -------------------
    # remove the directive blocks so only rules + @mu/@ms remain
    body_only = re.sub(r"@tmodel<\w+>", "", src)
    body_only = re.sub(r"@clock\s+\w+\s*\{", "", body_only)
    body_only = re.sub(r"@phase_register\s+\w+\s*\{", "", body_only)
    # drop the now-orphaned closing braces of directive blocks is tricky; we
    # instead extract rules directly from `src`.
    rule_texts = []
    for m in re.finditer(r"\[(.*?)\]'(\w+)\s*(?:when\s+slot\s*==\s*(\w+))?\s*;",
                         src, re.S):
        rule_texts.append((m.group(1).strip(), m.group(2), m.group(3)))

    # ================= emit ================================================
    out.append("/* Lowered by tli_lower.py from a T-Lingua (.tli) model.")
    out.append(f" * Source model: @tmodel<{model}>")
    out.append(" * Lowering: @clock/@phase_register/when -> explicit tick ring. */")
    out.append("")
    out.append("@model<psystems_basic>")
    out.append("")

    # ---- membrane structure ----------------------------------------------
    # build the nested clock chain for each clock: d1..dN nested under `skin`
    # (or the wrap_to membrane).  If a manual @mu exists we keep it and nest
    # clock chains under it.
    def clock_chain(period):
        # returns text for [ [ ... [ []'dN ]'d{N-1} ... ]'d1 ]
        s = "[]'%s" % ("d%d" % period)
        for i in range(period - 1, 0, -1):
            s = "[ %s ]'d%d" % (s, i)
        return s

    if clocks and not manual_mu:
        # single-clock convenience: skin wraps the whole chain
        chains = " ".join(clock_chain(c.period) for c in clocks)
        out.append(f"@mu = [ {chains} ]'skin;")
    elif manual_mu:
        out.append(f"@mu = {manual_mu};")
    if clocks and manual_mu:
        out.append("/* NOTE: @clock chains lowered as rules below; nest the")
        out.append(" * d1..dN chain in @mu where the clock lives. */")
    out.append("")

    # ---- initial multisets -------------------------------------------------
    for label, ms in extra_init.items():
        out.append(f"@m{label} = {ms};")
    for c in clocks:
        # ensure the clock seed: tick in the rim (skin or wrap_to)
        rim = c.wrap_to if c.wrap_to else "skin"
        if rim not in extra_init:
            out.append(f"@m{rim} = {c.name};")
    for r in registers:
        # phase register starts at phase(0); one slot object per slot
        slots = ", ".join(f"slot({s})" for s in r.slots)
        out.append(f"@m{r.name} = phase(0){', ' if slots else ''}{slots};")
    out.append("")

    # ---- lowered rules -----------------------------------------------------
    for text, label, guard in rule_texts:
        # text is "name : lhs --> rhs"
        nm = re.match(r"(\w+)\s*:\s*(.*?)-->\s*(.*)$", text, re.S)
        if not nm:
            continue
        name, lhs, rhs = nm.group(1), nm.group(2).strip(), nm.group(3).strip()
        if guard:
            # consume and restore the slot so the register keeps cycling —
            # but only add it if the LHS doesn't already reference that slot.
            if f"slot({guard})" not in lhs:
                lhs = f"{lhs} * slot({guard})"
                rhs = f"{rhs} * slot({guard})"
            else:
                # slot already consumed on LHS; restore it on the RHS
                rhs = f"{rhs} * slot({guard})"
        out.append(f"[{name} : {lhs} --> {rhs} ]'{label};")

    # ---- clock tick ring ----------------------------------------------------
    for c in clocks:
        out.append("")
        out.append(f"/* @clock {c.name} (period {c.period}) lowered: */")
        rim = c.wrap_to if c.wrap_to else "skin"
        # tick falls one dimension deeper per step
        out.append(f"[{c.name}_in : {c.name} --> ({c.name})in_d1 ]'{rim};")
        for i in range(1, c.period):
            out.append(f"[{c.name}_in : {c.name} --> ({c.name})in_d{i+1} ]'d{i};")
        # wrap at the innermost phase back to the rim
        if c.wrap_from:
            out.append(f"[{c.name}_wrap : {c.name} --> ({c.name})out ]'{c.wrap_from};")
        # reseed rule
        if c.reseed:
            where = c.wrap_from if c.wrap_from else f"d{c.period}"
            out.append(f"[singularity : {c.reseed} --> {c.reseed} * {c.name} ]'{where};")

    # ---- phase register ring -------------------------------------------------
    for r in registers:
        out.append("")
        out.append(f"/* @phase_register {r.name} (cycle {r.cycle}) lowered: */")
        # advance the register one slot per tick (here: per step, since the
        # register rides the membrane's own activity)
        out.append(f"[advance : phase(p) * tick --> phase(p1) ]'{r.name};"
                   if "tick" in src else
                   f"/* register advances when its slot fires; see wrap below */")
        # wrap the register at the last slot
        if r.slots:
            out.append(f"[wrap_{r.name} : done({r.slots[-1]}) --> "
                       f"cycle_complete * phase(0) ]'{r.name};")

    out.append("")
    return "\n".join(out)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    src_path = argv[1]
    out_path = None
    if "-o" in argv:
        i = argv.index("-o")
        out_path = argv[i + 1]
    with open(src_path) as f:
        src = f.read()
    lowered = lower(src)
    if out_path:
        with open(out_path, "w") as f:
            f.write(lowered)
        print(f"wrote {out_path}", file=sys.stderr)
    else:
        print(lowered)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
