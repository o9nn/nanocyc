#!/usr/bin/env python3
"""Convert psim's JSON output into the same canonical s-expr the Scheme kernel
prints, so `diff` can cross-validate the two engines.

psim output JSON references objects/labels by integer id into the *compiled*
file's symbol tables, so we need BOTH the compiled model (for the tables) and
the simulation output (for the halting configuration).

Usage: xcheck_psim.py <compiled.json> <sim_output.json>
Prints: (final ((id label ((sym . n) ...)) ...))   — membranes sorted by id,
objects sorted by name, matching the kernel's canonical form.
"""
import json
import sys


def load(path):
    with open(path) as f:
        return json.load(f)


def main():
    compiled = load(sys.argv[1])["file"]["psystem"]
    out = load(sys.argv[2])["file"]

    objects = compiled["objects"]          # id -> object-name
    labels = compiled["labels"]            # id -> label-name

    rows = []
    for idx, m in enumerate(out["membranes"]):
        label_id = m["label"][0]["id"]
        label = labels[label_id]
        ms = []
        for entry in m["multiset"]:
            sym = objects[entry["key"]["id"]]
            n = entry["value"]["multiplicity"]
            if n > 0:
                ms.append((sym, n))
        ms.sort(key=lambda p: p[0])
        ms_sx = " ".join(f"({s} . {n})" for s, n in ms)
        rows.append((idx, label, ms_sx))

    rows.sort(key=lambda r: r[0])
    body = " ".join(f"({i} {label} ({ms}))" for i, label, ms in rows)
    print(f"(final ({body}))")


if __name__ == "__main__":
    main()
