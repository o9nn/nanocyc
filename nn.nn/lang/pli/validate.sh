#!/usr/bin/env bash
#
# validate.sh - Validation harness for the PLingua neural network sources.
#
# Usage:
#   ./validate.sh                 # structural checks only (no dependencies)
#   PLINGUA=plingua ./validate.sh # additionally compile each file with the
#                                 # P-Lingua 5 compiler (github.com/RGNC/plingua)
#
# Structural checks performed on every .pli file:
#   - balanced /* ... */ comments
#   - balanced braces { }
#   - balanced brackets [ ]
#   - balanced parentheses ( )
#
set -u

cd "$(dirname "$0")"

fail=0
files=(*.pli)

echo "Validating ${#files[@]} PLingua source files..."
echo

for f in "${files[@]}"; do
    errors=""

    # Strip string literals, then check comment balance
    opens=$(grep -o '/\*' "$f" | wc -l)
    closes=$(grep -o '\*/' "$f" | wc -l)
    if [ "$opens" -ne "$closes" ]; then
        errors="$errors unbalanced-comments($opens/$closes)"
    fi

    # Remove comments and string literals before delimiter counting
    stripped=$(sed -e 's://.*$::' "$f" | awk 'BEGIN{RS="\0"} {gsub(/\/\*[^*]*\*+([^\/*][^*]*\*+)*\//, ""); gsub(/"[^"]*"/, ""); print}')

    for pair in '{ }' '[ ]' '( )'; do
        open_ch=${pair% *}
        close_ch=${pair#* }
        o=$(printf '%s' "$stripped" | tr -cd "$open_ch" | wc -c)
        c=$(printf '%s' "$stripped" | tr -cd "$close_ch" | wc -c)
        if [ "$o" -ne "$c" ]; then
            errors="$errors unbalanced-$open_ch$close_ch($o/$c)"
        fi
    done

    if [ -n "$errors" ]; then
        echo "FAIL  $f:$errors"
        fail=1
    else
        echo "ok    $f"
    fi

    # Optional: full syntax check with the P-Lingua compiler
    if [ -n "${PLINGUA:-}" ]; then
        if ! "$PLINGUA" "$f" > /dev/null 2>&1; then
            echo "FAIL  $f: P-Lingua compiler rejected the file"
            fail=1
        fi
    fi
done

echo
if [ "$fail" -ne 0 ]; then
    echo "Validation FAILED"
    exit 1
fi
echo "All files passed validation"
