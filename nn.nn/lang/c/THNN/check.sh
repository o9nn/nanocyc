#!/usr/bin/env bash
# THNN structural smoke check.
#
# A full compile of lang/c/THNN requires the Torch7 TH headers and build
# system, which are heavyweight and fragile in CI.  This script provides a
# dependency-free smoke check instead: it verifies that every THNN source file
# is present, non-empty, and has balanced (), {}, and [] delimiters (ignoring
# those inside comments and string/char literals).  It catches the most common
# classes of source corruption without needing a Torch toolchain.
#
# A full Torch7 build of THNN is exercised separately by the opt-in nightly
# "torch-legacy" job in .github/workflows/ci.yml.
#
# Usage:  bash lang/c/THNN/check.sh        (from the repository root)
#         bash check.sh                    (from lang/c/THNN)
set -euo pipefail

cd "$(dirname "$0")"

fail=0
count=0

check_file() {
  local f="$1"
  count=$((count + 1))
  if [ ! -s "$f" ]; then
    echo "ERROR: $f is empty or missing"
    fail=1
    return
  fi
  # Balanced-delimiter check via awk, skipping // and /* */ comments and
  # string/char literals.
  if ! awk '
    BEGIN { p=0; b=0; c=0; inblock=0 }
    {
      line=$0; n=length(line); i=1; instr=0; q=""
      while (i<=n) {
        ch=substr(line,i,1); nx=substr(line,i+1,1)
        if (inblock) { if (ch=="*" && nx=="/") { inblock=0; i+=2; continue } i++; continue }
        if (instr) {
          if (ch=="\\") { i+=2; continue }
          if (ch==q) { instr=0 }
          i++; continue
        }
        if (ch=="/" && nx=="/") { break }
        if (ch=="/" && nx=="*") { inblock=1; i+=2; continue }
        if (ch=="\"" || ch=="\x27") { instr=1; q=ch; i++; continue }
        if (ch=="(") p++
        else if (ch==")") p--
        else if (ch=="{") b++
        else if (ch=="}") b--
        else if (ch=="[") c++
        else if (ch=="]") c--
        if (p<0||b<0||c<0) { print "UNBALANCED"; exit 1 }
        i++
      }
    }
    END { if (p!=0||b!=0||c!=0) { print "UNBALANCED"; exit 1 } }
  ' "$f" >/dev/null; then
    echo "ERROR: $f has unbalanced delimiters"
    fail=1
  fi
}

while IFS= read -r f; do
  check_file "$f"
done < <(find . -name '*.c' -o -name '*.h' | sort)

echo "Checked $count THNN source files."
if [ "$fail" -ne 0 ]; then
  echo "THNN structural check FAILED"
  exit 1
fi
echo "THNN structural check passed."
