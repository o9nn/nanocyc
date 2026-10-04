#!/usr/bin/env bash
# xcheck.sh --- cross-validate the Scheme s-expr kernel against the C++ psim.
#
# For every fixtures/NAME.pli + fixtures/NAME.scm pair:
#   1. compile NAME.pli with bin/plingua  -> /tmp/NAME.compiled.json
#   2. simulate with bin/psim             -> /tmp/NAME.out.json
#   3. run the Scheme kernel on NAME.scm  -> canonical (final ...) line
#   4. convert psim output to the same canonical form and diff
#
# Exit 0 iff all fixtures agree.  Requires: guile, python3, and the built
# plingua/psim binaries (make compiler simulator in plingua/).

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PLINGUA_DIR="$(cd "$HERE/../.." && pwd)"
PLINGUA="$PLINGUA_DIR/bin/plingua"
PSIM="$PLINGUA_DIR/bin/psim"
EXAMPLES="$PLINGUA_DIR/examples"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail=0
count=0

shopt -s nullglob
for pli in "$HERE"/fixtures/*.pli; do
  name="$(basename "$pli" .pli)"
  scm="$HERE/fixtures/$name.scm"
  [ -f "$scm" ] || { echo "SKIP $name (no .scm twin)"; continue; }
  count=$((count + 1))

  compiled="$TMP/$name.compiled.json"
  outjson="$TMP/$name.out.json"

  if ! "$PLINGUA" "$pli" -I "$EXAMPLES" -o "$compiled" -f json >/dev/null 2>&1; then
    echo "FAIL $name: plingua compile"; fail=1; continue
  fi
  if ! "$PSIM" "$compiled" -s 1000 -o "$outjson" >/dev/null 2>&1; then
    echo "FAIL $name: psim run"; fail=1; continue
  fi

  psim_final="$(python3 "$HERE/xcheck_psim.py" "$compiled" "$outjson" 2>/dev/null)"
  scm_final="$(guile -L "$HERE" -s "$HERE/xcheck.scm" "$scm" 2>/dev/null | grep '^(final')"

  if [ -z "$psim_final" ]; then echo "FAIL $name: empty psim canonical"; fail=1; continue; fi
  if [ -z "$scm_final" ];  then echo "FAIL $name: empty scheme canonical"; fail=1; continue; fi

  if [ "$psim_final" = "$scm_final" ]; then
    echo "ok   $name  ($scm_final)"
  else
    echo "FAIL $name"
    echo "     psim:   $psim_final"
    echo "     scheme: $scm_final"
    fail=1
  fi
done

echo "----------------------------------------"
echo "Cross-validated $count fixture(s)"
[ "$fail" -eq 0 ] && echo "ALL ENGINES AGREE" || echo "MISMATCH PRESENT"
exit "$fail"
