#!/bin/bash
set -uo pipefail

# Unity build verification for benchmark tasks.
# Compiles the project and runs EditMode/PlayMode tests.
#
# Usage: ./verify-unity.sh <project_path> <results_path> [output_name]
#
# output_name defaults to "verification.json". Pass "baseline-verification.json"
# for pre-agent baseline checks.
#
# Requires Unity Editor in PATH (provided by game-ci Docker images).

PROJECT_PATH="${1:?Usage: verify-unity.sh <project_path> <results_path> [output_name]}"
RESULTS_PATH="${2:?Usage: verify-unity.sh <project_path> <results_path> [output_name]}"
OUTPUT_NAME="${3:-verification.json}"

UNITY_BIN=$(command -v unity-editor 2>/dev/null || command -v Unity 2>/dev/null || echo "")
if [[ -z "$UNITY_BIN" ]]; then
    echo "Unity Editor not found in PATH. Skipping verification."
    echo '{"verification": "skipped", "reason": "unity_not_found"}' > "${RESULTS_PATH}/${OUTPUT_NAME}"
    exit 0
fi

echo "Unity verification: ${PROJECT_PATH}"

# Step 1: Compile
echo "  Compiling..."
COMPILE_LOG="${RESULTS_PATH}/compile.log"
COMPILE_EXIT=0
"$UNITY_BIN" -batchmode -nographics -projectPath "$PROJECT_PATH" \
    -logFile "$COMPILE_LOG" -quit 2>&1 || COMPILE_EXIT=$?

COMPILE_ERRORS=$(grep -c "error CS" "$COMPILE_LOG" 2>/dev/null || true)
[[ -z "$COMPILE_ERRORS" || "$COMPILE_ERRORS" == "" ]] && COMPILE_ERRORS=0

echo "  Compile: exit=${COMPILE_EXIT}, errors=${COMPILE_ERRORS}"

# Step 2: EditMode tests
EDITMODE_XML="${RESULTS_PATH}/editmode-results.xml"
echo "  Running EditMode tests..."
EDITMODE_EXIT=0
"$UNITY_BIN" -batchmode -nographics -projectPath "$PROJECT_PATH" \
    -runTests -testPlatform EditMode \
    -testResults "$EDITMODE_XML" \
    -logFile "${RESULTS_PATH}/editmode.log" 2>&1 || EDITMODE_EXIT=$?

EDITMODE_TOTAL=0 EDITMODE_PASSED=0 EDITMODE_FAILED=0
if [[ -f "$EDITMODE_XML" ]]; then
    EDITMODE_TOTAL=$(grep -o 'total="[0-9]*"' "$EDITMODE_XML" | head -1 | grep -o '[0-9]*') || true
    EDITMODE_PASSED=$(grep -o 'passed="[0-9]*"' "$EDITMODE_XML" | head -1 | grep -o '[0-9]*') || true
    EDITMODE_FAILED=$(grep -o 'failed="[0-9]*"' "$EDITMODE_XML" | head -1 | grep -o '[0-9]*') || true
    [[ -z "$EDITMODE_TOTAL" ]] && EDITMODE_TOTAL=0
    [[ -z "$EDITMODE_PASSED" ]] && EDITMODE_PASSED=0
    [[ -z "$EDITMODE_FAILED" ]] && EDITMODE_FAILED=0
else
    echo "  EditMode: no results XML produced"
    EDITMODE_EXIT=-1
fi
echo "  EditMode: exit=${EDITMODE_EXIT}, total=${EDITMODE_TOTAL}, passed=${EDITMODE_PASSED}, failed=${EDITMODE_FAILED}"

# Step 3: PlayMode tests
PLAYMODE_XML="${RESULTS_PATH}/playmode-results.xml"
echo "  Running PlayMode tests..."
PLAYMODE_EXIT=0
"$UNITY_BIN" -batchmode -nographics -projectPath "$PROJECT_PATH" \
    -runTests -testPlatform PlayMode \
    -testResults "$PLAYMODE_XML" \
    -logFile "${RESULTS_PATH}/playmode.log" 2>&1 || PLAYMODE_EXIT=$?

PLAYMODE_TOTAL=0 PLAYMODE_PASSED=0 PLAYMODE_FAILED=0
if [[ -f "$PLAYMODE_XML" ]]; then
    PLAYMODE_TOTAL=$(grep -o 'total="[0-9]*"' "$PLAYMODE_XML" | head -1 | grep -o '[0-9]*') || true
    PLAYMODE_PASSED=$(grep -o 'passed="[0-9]*"' "$PLAYMODE_XML" | head -1 | grep -o '[0-9]*') || true
    PLAYMODE_FAILED=$(grep -o 'failed="[0-9]*"' "$PLAYMODE_XML" | head -1 | grep -o '[0-9]*') || true
    [[ -z "$PLAYMODE_TOTAL" ]] && PLAYMODE_TOTAL=0
    [[ -z "$PLAYMODE_PASSED" ]] && PLAYMODE_PASSED=0
    [[ -z "$PLAYMODE_FAILED" ]] && PLAYMODE_FAILED=0
else
    echo "  PlayMode: no results XML produced"
    PLAYMODE_EXIT=-1
fi
echo "  PlayMode: exit=${PLAYMODE_EXIT}, total=${PLAYMODE_TOTAL}, passed=${PLAYMODE_PASSED}, failed=${PLAYMODE_FAILED}"

# Determine overall pass/fail
COMPILES=$([[ $COMPILE_EXIT -eq 0 && $COMPILE_ERRORS -eq 0 ]] && echo true || echo false)
EDITMODE_PASS=$([[ $EDITMODE_EXIT -eq 0 && $EDITMODE_FAILED -eq 0 ]] && echo true || echo false)
PLAYMODE_PASS=$([[ $PLAYMODE_EXIT -eq 0 && $PLAYMODE_FAILED -eq 0 ]] && echo true || echo false)

# Detect infrastructure failures
EDITMODE_INFRA=false
PLAYMODE_INFRA=false
# Runner exited nonzero without producing test XML = runner crash
[[ $EDITMODE_EXIT -ne 0 && ! -f "$EDITMODE_XML" ]] && EDITMODE_INFRA=true
[[ $PLAYMODE_EXIT -ne 0 && ! -f "$PLAYMODE_XML" ]] && PLAYMODE_INFRA=true

# Determine top-level outcome
if ! $COMPILES; then
    if [[ $COMPILE_ERRORS -gt 0 ]]; then
        OUTCOME="compile_failed"
    else
        OUTCOME="infrastructure_error"
    fi
elif $EDITMODE_INFRA || $PLAYMODE_INFRA; then
    OUTCOME="infrastructure_error"
elif ! $EDITMODE_PASS || ! $PLAYMODE_PASS; then
    OUTCOME="tests_failed"
else
    OUTCOME="pass"
fi

# Write verification results using jq if available
if command -v jq &>/dev/null; then
    jq -n \
        --arg verif "completed" \
        --arg outcome "$OUTCOME" \
        --argjson cexit "$COMPILE_EXIT" \
        --argjson cerrs "$COMPILE_ERRORS" \
        --argjson compiles "$COMPILES" \
        --argjson eexit "$EDITMODE_EXIT" \
        --argjson etotal "$EDITMODE_TOTAL" \
        --argjson epassed "$EDITMODE_PASSED" \
        --argjson efailed "$EDITMODE_FAILED" \
        --argjson epass "$EDITMODE_PASS" \
        --argjson pexit "$PLAYMODE_EXIT" \
        --argjson ptotal "$PLAYMODE_TOTAL" \
        --argjson ppassed "$PLAYMODE_PASSED" \
        --argjson pfailed "$PLAYMODE_FAILED" \
        --argjson ppass "$PLAYMODE_PASS" \
        '{
          verification: $verif,
          outcome: $outcome,
          compile: {exit_code: $cexit, errors: $cerrs, pass: $compiles},
          editmode_tests: {exit_code: $eexit, total: $etotal, passed: $epassed, failed: $efailed, pass: $epass},
          playmode_tests: {exit_code: $pexit, total: $ptotal, passed: $ppassed, failed: $pfailed, pass: $ppass}
        }' > "${RESULTS_PATH}/${OUTPUT_NAME}"
else
    cat > "${RESULTS_PATH}/${OUTPUT_NAME}" << VJSON
{
  "verification": "completed",
  "outcome": "${OUTCOME}",
  "compile": {"exit_code": ${COMPILE_EXIT}, "errors": ${COMPILE_ERRORS}, "pass": ${COMPILES}},
  "editmode_tests": {"exit_code": ${EDITMODE_EXIT}, "total": ${EDITMODE_TOTAL}, "passed": ${EDITMODE_PASSED}, "failed": ${EDITMODE_FAILED}, "pass": ${EDITMODE_PASS}},
  "playmode_tests": {"exit_code": ${PLAYMODE_EXIT}, "total": ${PLAYMODE_TOTAL}, "passed": ${PLAYMODE_PASSED}, "failed": ${PLAYMODE_FAILED}, "pass": ${PLAYMODE_PASS}}
}
VJSON
fi

echo "  Results: ${RESULTS_PATH}/${OUTPUT_NAME}"
