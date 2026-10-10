#!/usr/bin/env bash
# Focused checks for psim --trace (issue: intelligible step output).
# Requires bin/plingua and bin/psim (make compiler simulator).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PLINGUA="$ROOT/bin/plingua"
PSIM="$ROOT/bin/psim"
EXAMPLES="$ROOT/examples"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
check() {
  local name="$1"
  local cond="$2"
  if eval "$cond"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    fail=1
  fi
}

cat >"$TMP/send_in.pli" <<'EOF'
@model<transition>
@include "transition_model.pli"

def main()
{
  @mu = [ [ ]'inner ]'skin;
  @ms(skin) = a*3;
  [a [ ]'inner --> b [b]'inner]'skin;
  [b --> c, c]'inner;
}
EOF

cat >"$TMP/named.pli" <<'EOF'
@model<transition>
@include "transition_model.pli"

def main()
{
  @mu = [ ]'skin;
  @ms(skin) = a;
  [a --> b]'skin @name="send";
}
EOF

cat >"$TMP/identity.pli" <<'EOF'
@model<transition>
@include "transition_model.pli"

def main()
{
  @mu = [ ]'skin;
  @ms(skin) = a;
  [a --> a]'skin;
}
EOF

cat >"$TMP/crystal.pli" <<'EOF'
@model<transition>
@include "transition_model.pli"

def main()
{
  @mu = [ [ [ [ [ [ [ [ [ [ [ []'d11 ]'d10 ]'d9 ]'d8 ]'d7 ]'d6 ]'d5 ]'d4 ]'d3 ]'d2 ]'d1 ]'skin;
  @ms(skin) = fuel;
  @ms(d3) = tick;
  [fuel --> done]'skin;
}
EOF

compile() {
  local src="$1" out="$2"
  "$PLINGUA" "$src" -I "$EXAMPLES" -o "$out" -f json >/dev/null
}

if ! compile "$TMP/send_in.pli" "$TMP/send.json"; then
  echo "FAIL compile send_in"; exit 1
fi
if ! compile "$TMP/named.pli" "$TMP/named.json"; then
  echo "FAIL compile named"; exit 1
fi
if ! compile "$TMP/identity.pli" "$TMP/identity.json"; then
  echo "FAIL compile identity"; exit 1
fi
if ! compile "$TMP/crystal.pli" "$TMP/crystal.json"; then
  echo "FAIL compile crystal"; exit 1
fi

sexpr="$("$PSIM" "$TMP/send.json" -s 5 --seed 42 -o "$TMP/send.out.json" --trace=sexpr)"
check "sexpr header" 'printf "%s\n" "$sexpr" | head -1 | grep -q "(seed 42) (steps 5) (model \""'
check "sexpr fired" 'printf "%s\n" "$sexpr" | grep -q "(fired (step 0) (membrane "'
check "sexpr consumed/produced" 'printf "%s\n" "$sexpr" | grep -q "(consumed " && printf "%s\n" "$sexpr" | grep -q "(produced "'
check "sexpr halt" 'printf "%s\n" "$sexpr" | grep -q "(halted (steps 2) (reason no-applicable-rules))"'
check "sexpr one checkpoint per step by default" '[ "$(printf "%s\n" "$sexpr" | grep -c "^(checkpoint ")" -eq 2 ]'

every="$("$PSIM" "$TMP/send.json" -s 5 --seed 42 -o "$TMP/every.out.json" --trace=sexpr --checkpoint-every 2)"
check "checkpoint-every suppresses intermediate" '[ "$(printf "%s\n" "$every" | grep -c "^(checkpoint ")" -eq 1 ]'

json="$("$PSIM" "$TMP/send.json" -s 5 --seed 42 -o "$TMP/json.out.json" --trace=json)"
check "json header" 'printf "%s\n" "$json" | head -1 | grep -q "\"event\":\"header\"" && printf "%s\n" "$json" | head -1 | grep -q "\"seed\":42"'
check "json step object" 'printf "%s\n" "$json" | grep -q "\"event\":\"step\"" && printf "%s\n" "$json" | grep -q "\"fired\":\["'
check "json halt" 'printf "%s\n" "$json" | grep -q "\"event\":\"halted\"" && printf "%s\n" "$json" | grep -q "no-applicable-rules"'
check "json lines parse" 'printf "%s\n" "$json" | python3 -c "import json,sys; [json.loads(l) for l in sys.stdin if l.strip()]"'

wide="$(COLUMNS=160 "$PSIM" "$TMP/send.json" -s 1 --seed 1 -o "$TMP/wide.out.json" --trace=human)"
check "wide panes share a header" 'printf "%s\n" "$wide" | grep -q -- "--glyph  *--wire  *--checkpoint"'

narrow="$(COLUMNS=80 "$PSIM" "$TMP/send.json" -s 1 --seed 1 -o "$TMP/narrow.out.json" --trace=human --no-unicode)"
check "narrow stacks glyph" 'printf "%s\n" "$narrow" | grep -qx -- "--glyph"'
check "narrow stacks wire" 'printf "%s\n" "$narrow" | grep -qx -- "--wire"'
check "narrow stacks checkpoint" 'printf "%s\n" "$narrow" | grep -qx -- "--checkpoint"'
check "narrow does not use side-by-side header" '! printf "%s\n" "$narrow" | grep -q -- "--glyph.*--wire"'
check "ascii box fallback" 'printf "%s\n" "$narrow" | grep -q "+-"'

diff_id="$(COLUMNS=80 "$PSIM" "$TMP/identity.json" -s 2 --seed 7 -o "$TMP/id.out.json" --trace=diff --no-unicode)"
check "diff header" 'printf "%s\n" "$diff_id" | head -1 | grep -q "(seed 7) (steps 2)"'
check "diff skips unchanged panes" 'printf "%s\n" "$diff_id" | grep -q "(unchanged (step 1))" && printf "%s\n" "$diff_id" | grep -q "(unchanged (step 2))"'
check "diff still emits wire" 'printf "%s\n" "$diff_id" | grep -q "(fired (step 0)"'
check "diff unchanged has no glyph header" '! printf "%s\n" "$diff_id" | grep -q -- "--glyph"'
check "diff halt max-steps" 'printf "%s\n" "$diff_id" | grep -q "(halted (steps 2) (reason max-steps))"'

diff_chg="$(COLUMNS=160 "$PSIM" "$TMP/send.json" -s 1 --seed 1 -o "$TMP/chg.out.json" --trace=diff)"
check "diff redraws when state changes" 'printf "%s\n" "$diff_chg" | grep -q -- "--glyph"'

named="$("$PSIM" "$TMP/named.json" -s 1 --seed 1 -o "$TMP/named.out.json" --trace=sexpr)"
check "named rule" 'printf "%s\n" "$named" | grep -q "(rule send)"'

crystal="$(COLUMNS=80 "$PSIM" "$TMP/crystal.json" -s 1 --seed 1 -o "$TMP/crystal.out.json" --trace=human --no-unicode)"
check "collapse phase nest" 'printf "%s\n" "$crystal" | grep -q "d1...d11 phase=3"'
check "collapse hides inner boxes" '! printf "%s\n" "$crystal" | grep -q "]d11"'

crystal_u="$(COLUMNS=80 "$PSIM" "$TMP/crystal.json" -s 1 --seed 1 -o "$TMP/crystal_u.out.json" --trace=human)"
check "unicode collapse note" 'printf "%s\n" "$crystal_u" | grep -q "d1⋯d11 ◔ phase=3"'

expanded="$(COLUMNS=80 "$PSIM" "$TMP/crystal.json" -s 1 --seed 1 -o "$TMP/exp.out.json" --trace=human --no-unicode --expand)"
check "expand shows d11" 'printf "%s\n" "$expanded" | grep -q "]d11"'
check "expand does not collapse" '! printf "%s\n" "$expanded" | grep -q "d1...d11"'

set +e
bad="$("$PSIM" "$TMP/send.json" --trace=xml -o "$TMP/bad.json" 2>&1)"
bad_rc=$?
set -e
check "invalid trace rejected" '[ "$bad_rc" -ne 0 ] && printf "%s\n" "$bad" | grep -q "invalid --trace mode"'

echo "----------------------------------------"
if [ "$fail" -eq 0 ]; then
  echo "ALL TRACE CHECKS PASSED"
  exit 0
fi
echo "TRACE CHECKS FAILED"
exit 1
