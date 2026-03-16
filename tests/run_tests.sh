#!/usr/bin/env bash
# run_tests.sh
# Runs all test_*.lua files in the tests/ directory.
# Requires lua5.4 on PATH.

PASS=0
FAIL=0
ERRORS=()

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for f in "$SCRIPT_DIR"/test_*.lua; do
    if lua5.4 "$f" 2>&1; then
        echo "PASS: $(basename $f)"
        ((PASS++))
    else
        echo "FAIL: $(basename $f)"
        ((FAIL++))
        ERRORS+=("$(basename $f)")
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "Failed files:"
    for e in "${ERRORS[@]}"; do
        echo "  $e"
    done
    exit 1
fi

exit 0