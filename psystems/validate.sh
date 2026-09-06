#!/usr/bin/env bash
# Validate every P-Lingua (.pli) file in this directory tree.
#
# Primary path:  pLinguaCore CLI (`plingua <file> check`) when installed.
# Fallback path: structural lint — header comment, balanced [ ] / ( ) / ' ' ,
#                membrane structure declaration (@mu), at least one rule (-->).
#
# Exit code 0 = all files OK, 1 = at least one failure.

set -u
cd "$(dirname "$0")"

HAVE_PLINGUA=0
if command -v plingua >/dev/null 2>&1; then
  HAVE_PLINGUA=1
fi

fail=0
count=0

lint_file() {
  local f="$1"
  local errs=""
  grep -q '@mu' "$f"                     || errs="$errs missing @mu membrane structure;"
  grep -q -- '-->' "$f"                  || errs="$errs no evolution rules (-->) found;"
  grep -q 'Traceability' "$f"            || errs="$errs missing Traceability header;"

  # balanced square brackets / parens, computed on comment-stripped
  # content so apostrophes and brackets inside prose do not skew the counts
  local counts
  counts=$(python3 - "$f" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
src = re.sub(r'//.*', '', src)
print(src.count('['), src.count(']'), src.count('('), src.count(')'))
PY
)
  read -r ob cb op cp <<< "$counts"
  [ "$ob" -eq "$cb" ] || errs="$errs unbalanced [] ($ob vs $cb);"
  [ "$op" -eq "$cp" ] || errs="$errs unbalanced () ($op vs $cp);"

  # every membrane label referenced as 'label must be declared in @mu / @m<label>
  local missing
  missing=$(python3 - "$f" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
src = re.sub(r'//.*', '', src)
labels = set(re.findall(r"'([A-Za-z_][A-Za-z0-9_]*)", src))
declared = set(re.findall(r"@m([A-Za-z_][A-Za-z0-9_]*)", src))
# labels appearing in the @mu structure are declared by definition
mu = re.search(r"@mu\s*=(.*?);", src, re.S)
if mu:
    declared |= set(re.findall(r"'([A-Za-z_][A-Za-z0-9_]*)", mu.group(1)))
missing = sorted(l for l in labels - declared if l not in ('skin',) or "'skin" not in src)
missing = [l for l in (labels - declared)]
print(' '.join(missing))
PY
)
  [ -z "$missing" ] || errs="$errs undeclared membrane labels: $missing;"

  if [ -n "$errs" ]; then
    echo "LINT FAIL: $f ->$errs"
    return 1
  fi
  return 0
}

while IFS= read -r f; do
  count=$((count + 1))
  if [ "$HAVE_PLINGUA" -eq 1 ]; then
    if ! plingua "$f" check >/dev/null 2>&1; then
      echo "PLINGUA FAIL: $f"
      fail=1
      continue
    fi
  fi
  lint_file "$f" || fail=1
done < <(find . -name '*.pli' | sort)

echo "----------------------------------------"
echo "Checked $count .pli file(s) (plingua=$HAVE_PLINGUA)"
[ "$fail" -eq 0 ] && echo "ALL OK" || echo "FAILURES PRESENT"
exit "$fail"
