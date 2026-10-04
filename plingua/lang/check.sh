#!/usr/bin/env bash
# check.sh --- one-shot verification of the whole L-Lingua layer.
#
#   1. Guile kernel unit tests
#   2. cross-validation: C++ psim vs Guile vs Racket on the fixtures
#   3. Emacs ERT tests for the three-pane display
#
# Skips any engine whose interpreter is not installed.  Exit 0 iff everything
# that ran passed.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
fail=0

echo "=== 1. Scheme kernel unit tests ==="
if command -v guile >/dev/null 2>&1; then
  ( cd "$HERE/scm" && guile -L . -s test-psystem.scm ) || fail=1
else
  echo "SKIP (guile not installed)"
fi

echo
echo "=== 2. Cross-validation (psim / guile / racket) ==="
if [ -x "$HERE/../bin/psim" ]; then
  ( cd "$HERE/scm" && bash xcheck.sh ) || fail=1
else
  echo "SKIP (psim not built; run 'make simulator' in plingua/)"
fi

echo
echo "=== 3. Emacs ERT tests ==="
if command -v emacs >/dev/null 2>&1; then
  ( cd "$HERE/elisp" && \
    emacs -Q --batch -L . -l test-plingua-mode.el \
          -f ert-run-tests-batch-and-exit ) || fail=1
else
  echo "SKIP (emacs not installed)"
fi

echo
[ "$fail" -eq 0 ] && echo "ALL L-LINGUA CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit "$fail"
