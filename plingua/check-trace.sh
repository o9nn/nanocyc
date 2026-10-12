#!/usr/bin/env bash
# check-trace.sh --- intelligible psim --trace modes.
#
# Covers --trace=sexpr|json|human|diff, named rules, grip atoms, narrow-terminal stacking,
# phase-ring glyph collapse, and T-Lingua tick/resonance wire atoms.
#
# Usage: from plingua/, after `make compiler simulator`:
#   bash check-trace.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLINGUA="$HERE/bin/plingua"
PSIM="$HERE/bin/psim"
EXAMPLES="$HERE/examples"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
say() { printf '%s\n' "$*"; }

need() {
	if [ ! -x "$1" ]; then
		say "FAIL missing binary $1 (run make compiler simulator)"
		exit 1
	fi
}
need "$PLINGUA"
need "$PSIM"

compile() {
	local src="$1" out="$2"
	if ! "$PLINGUA" "$src" -I "$EXAMPLES" -o "$out" -f json >"$TMP/compile.err" 2>&1; then
		say "FAIL compile $src"
		cat "$TMP/compile.err"
		fail=1
		return 1
	fi
	return 0
}

assert_has() {
	local label="$1" file="$2" needle="$3"
	if grep -F -q -- "$needle" "$file"; then
		say "ok   $label"
	else
		say "FAIL $label (missing: $needle)"
		say "----- output -----"
		cat "$file"
		fail=1
	fi
}

assert_lacks() {
	local label="$1" file="$2" needle="$3"
	if grep -F -q -- "$needle" "$file"; then
		say "FAIL $label (unexpected: $needle)"
		cat "$file"
		fail=1
	else
		say "ok   $label"
	fi
}

# ---- named rule + json -------------------------------------------------------
if compile "$EXAMPLES/trace/named_send.pli" "$TMP/named.json"; then
	"$PSIM" "$TMP/named.json" -s 5 -o "$TMP/named.out.json" --trace=sexpr --no-unicode \
		>"$TMP/named.sexpr" 2>"$TMP/named.err" || { say "FAIL psim named sexpr"; cat "$TMP/named.err"; fail=1; }
	assert_has "sexpr names the rule" "$TMP/named.sexpr" "(rule send)"
	assert_lacks "sexpr does not fall back when a name is stored" "$TMP/named.sexpr" "(rule r"
	assert_has "sexpr header is replayable" "$TMP/named.sexpr" "(model \"$TMP/named.json\")"
	assert_has "sexpr halted" "$TMP/named.sexpr" "(halted (steps 1) (reason no-applicable-rules))"

	"$PSIM" "$TMP/named.json" -s 5 -o "$TMP/named.out.json" --trace=json \
		>"$TMP/named.jsonl" 2>"$TMP/named.err" || { say "FAIL psim named json"; cat "$TMP/named.err"; fail=1; }
	assert_has "json step event" "$TMP/named.jsonl" '"event":"step"'
	assert_has "json rule name" "$TMP/named.jsonl" '"rule":"send"'
	assert_has "json header" "$TMP/named.jsonl" '"event":"header"'
	assert_has "json checkpoint" "$TMP/named.jsonl" '"event":"checkpoint"'
	assert_has "json halted" "$TMP/named.jsonl" '"event":"halted"'
	assert_has "json consumed object" "$TMP/named.jsonl" '"consumed":{"a":2}'

	COLUMNS=80 "$PSIM" "$TMP/named.json" -s 5 -o "$TMP/named.out.json" --trace=human --no-unicode \
		>"$TMP/named.narrow" 2>/dev/null || true
	# stacked: a --glyph line that does not also carry --wire
	if awk '/--glyph/ && !/--wire/ {found=1} END{exit !found}' "$TMP/named.narrow" \
		&& awk '/^--wire$/ {found=1} END{exit !found}' "$TMP/named.narrow"; then
		say "ok   narrow terminal stacks panes"
	else
		say "FAIL narrow terminal stacks panes"
		cat "$TMP/named.narrow"
		fail=1
	fi

	COLUMNS=160 "$PSIM" "$TMP/named.json" -s 5 -o "$TMP/named.out.json" --trace=human --no-unicode \
		>"$TMP/named.wide" 2>/dev/null || true
	if awk '/--glyph/ && /--wire/ && /--checkpoint/ {found=1} END{exit !found}' "$TMP/named.wide"; then
		say "ok   wide terminal keeps panes side by side"
	else
		say "FAIL wide terminal keeps panes side by side"
		cat "$TMP/named.wide"
		fail=1
	fi
fi

# ---- diff: unchanged multiset is not redrawn --------------------------------
if compile "$EXAMPLES/trace/noop.pli" "$TMP/noop.json"; then
	COLUMNS=160 "$PSIM" "$TMP/noop.json" -s 3 -o "$TMP/noop.out.json" --trace=diff --no-unicode \
		>"$TMP/noop.trace" 2>/dev/null || true
	assert_lacks "diff skips an unchanged multiset" "$TMP/noop.trace" "--glyph"
	assert_has "diff still reports halting" "$TMP/noop.trace" "(halted (steps 3)"

	COLUMNS=160 "$PSIM" "$TMP/named.json" -s 5 -o "$TMP/named.out.json" --trace=diff --no-unicode \
		>"$TMP/named.diff" 2>/dev/null || true
	assert_has "diff draws when the multiset changes" "$TMP/named.diff" "--glyph"
fi

# ---- phase ring collapse + tick atom ----------------------------------------
if compile "$EXAMPLES/trace/phase_ring.pli" "$TMP/phase.json"; then
	"$PSIM" "$TMP/phase.json" -s 5 -o "$TMP/phase.out.json" --trace=sexpr --no-unicode \
		>"$TMP/phase.sexpr" 2>"$TMP/phase.err" || { say "FAIL psim phase sexpr"; cat "$TMP/phase.err"; fail=1; }
	assert_has "tick wire atom" "$TMP/phase.sexpr" "(tick 0 (phase 1->2))"
	assert_has "named tick rule" "$TMP/phase.sexpr" "(rule tick_in)"
	# s-expr checkpoint must still list the deep membranes (collapse is glyph-only)
	assert_has "sexpr checkpoint keeps d6" "$TMP/phase.sexpr" "(label d6)"

	COLUMNS=160 "$PSIM" "$TMP/phase.json" -s 5 -o "$TMP/phase.out.json" --trace=human --no-unicode \
		>"$TMP/phase.human" 2>/dev/null || true
	assert_has "glyph collapses the phase ring" "$TMP/phase.human" "[phase d1..d6"
	# a fully expanded ring would draw a box per membrane; the collapsed row
	# replaces those boxes, so the glyph must not contain a [d6] box label.
	assert_lacks "glyph does not box every phase membrane" "$TMP/phase.human" "]d6"
fi

# ---- grip atom ---------------------------------------------------------------
if compile "$EXAMPLES/trace/grip.pli" "$TMP/grip.json"; then
	"$PSIM" "$TMP/grip.json" -s 1 -o "$TMP/grip.out.json" --trace=sexpr --no-unicode \
		>"$TMP/grip.sexpr" 2>"$TMP/grip.err" || { say "FAIL psim grip"; cat "$TMP/grip.err"; fail=1; }
	assert_has "grip wire atom" "$TMP/grip.sexpr" "(grip a1 0.71)"
	"$PSIM" "$TMP/grip.json" -s 1 -o "$TMP/grip.out.json" --trace=json \
		>"$TMP/grip.jsonl" 2>/dev/null || true
	assert_has "json grip event" "$TMP/grip.jsonl" '"event":"grip"'
	assert_has "json grip id and score" "$TMP/grip.jsonl" '"id":"a1","grip":0.71'
	COLUMNS=80 "$PSIM" "$TMP/grip.json" -s 1 -o "$TMP/grip.out.json" --trace=human --no-unicode \
		>"$TMP/grip.human" 2>/dev/null || true
	assert_has "human wire shows grip" "$TMP/grip.human" "(grip a1 0.71)"
fi

# ---- resonance atom ----------------------------------------------------------
if compile "$EXAMPLES/trace/resonance.pli" "$TMP/res.json"; then
	"$PSIM" "$TMP/res.json" -s 5 -o "$TMP/res.out.json" --trace=sexpr --no-unicode \
		>"$TMP/res.sexpr" 2>"$TMP/res.err" || { say "FAIL psim resonance"; cat "$TMP/res.err"; fail=1; }
	assert_has "resonance wire atom" "$TMP/res.sexpr" "(resonance (a b) (match 2 3 5))"
	"$PSIM" "$TMP/res.json" -s 5 -o "$TMP/res.out.json" --trace=json \
		>"$TMP/res.jsonl" 2>/dev/null || true
	assert_has "json resonance" "$TMP/res.jsonl" '"event":"resonance"'
	assert_has "json resonance match" "$TMP/res.jsonl" '"match":[2,3,5]'
fi

# invalid mode is rejected
if "$PSIM" "$TMP/named.json" --trace=nope -o "$TMP/nope.json" >"$TMP/nope.out" 2>&1; then
	say "FAIL invalid --trace should fail"
	fail=1
else
	assert_has "invalid trace mode is rejected" "$TMP/nope.out" "invalid --trace mode"
fi

say "----------------------------------------"
if [ "$fail" -eq 0 ]; then
	say "check-trace: ALL OK"
else
	say "check-trace: FAILURES"
fi
exit "$fail"
