#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench — Historical comparison
# ============================================================
# Compares two benchmark runs and produces a delta report.
# Requires exact score_generation digest match for comparable deltas.

usage() {
    cat <<EOF
Usage:
  ./scripts/compare.sh <current_results>                    Auto-find previous compatible run
  ./scripts/compare.sh <current_results> <previous_results> Compare two specific runs

Options:
  --force    Show side-by-side even if score generations differ (labelled non-comparable)
  --help     Show this help
EOF
    exit "${1:-0}"
}

CURRENT="" PREVIOUS="" FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        --help)  usage 0 ;;
        -*)      echo "Error: Unknown option: $1"; usage 1 ;;
        *)
            if [[ -z "$CURRENT" ]]; then CURRENT="$1"; shift
            elif [[ -z "$PREVIOUS" ]]; then PREVIOUS="$1"; shift
            else echo "Error: Too many arguments"; usage 1; fi
            ;;
    esac
done

[[ -z "$CURRENT" ]] && { echo "Error: Current results directory required."; usage 1; }
CURRENT="${CURRENT:A}"
[[ ! -f "${CURRENT}/manifest.json" ]] && { echo "Error: No manifest.json in ${CURRENT}"; exit 1; }

if ! command -v jq &>/dev/null; then
    echo "Error: jq required for comparison"; exit 1
fi

BENCH_ROOT="${0:A:h:h}"

# ---- Auto-find previous run if not specified ----
if [[ -z "$PREVIOUS" ]]; then
    CURRENT_GEN=$(jq -r '.score_generation // empty' "${CURRENT}/manifest.json")
    [[ -z "$CURRENT_GEN" ]] && { echo "Error: Current manifest has no score_generation"; exit 1; }

    CURRENT_LABEL=$(basename "$CURRENT")
    LATEST_MATCH=""
    LATEST_TS=""

    for manifest in "${BENCH_ROOT}"/results/*/manifest.json(N); do
        dir=$(dirname "$manifest")
        [[ "$(basename "$dir")" == "$CURRENT_LABEL" ]] && continue
        gen=$(jq -r '.score_generation // empty' "$manifest" 2>/dev/null)
        [[ "$gen" != "$CURRENT_GEN" ]] && continue
        ts=$(jq -r '.timestamp // empty' "$manifest" 2>/dev/null)
        if [[ -z "$LATEST_TS" || "$ts" > "$LATEST_TS" ]]; then
            LATEST_TS="$ts"
            LATEST_MATCH="$dir"
        fi
    done

    if [[ -z "$LATEST_MATCH" ]]; then
        echo "No compatible previous run found (matching score_generation)."
        echo "This is the first run with generation: ${CURRENT_GEN:0:16}..."
        exit 0
    fi
    PREVIOUS="${LATEST_MATCH:A}"
    echo "Previous run: $(basename "$PREVIOUS") ($(jq -r '.timestamp' "${PREVIOUS}/manifest.json"))"
fi

PREVIOUS="${PREVIOUS:A}"
[[ ! -f "${PREVIOUS}/manifest.json" ]] && { echo "Error: No manifest.json in ${PREVIOUS}"; exit 1; }

# ---- Check generation compatibility ----
CUR_GEN=$(jq -r '.score_generation // empty' "${CURRENT}/manifest.json")
PREV_GEN=$(jq -r '.score_generation // empty' "${PREVIOUS}/manifest.json")
COMPARABLE=true

if [[ "$CUR_GEN" != "$PREV_GEN" ]]; then
    COMPARABLE=false
    if ! $FORCE; then
        echo "Error: Score generations differ — results are not directly comparable."
        echo "  Current:  ${CUR_GEN:0:40}..."
        echo "  Previous: ${PREV_GEN:0:40}..."
        echo ""
        echo "Use --force for a non-comparable side-by-side view."
        exit 1
    fi
fi

# Check evaluation conditions compatibility
CONDITION_WARNINGS=()
for field in prompt_mode network docker; do
    cur_val=$(jq -r "if .environment.${field} != null then (.environment.${field} | tostring) else \"\" end" "${CURRENT}/manifest.json" 2>/dev/null)
    prev_val=$(jq -r "if .environment.${field} != null then (.environment.${field} | tostring) else \"\" end" "${PREVIOUS}/manifest.json" 2>/dev/null)
    if [[ -n "$cur_val" && -n "$prev_val" && "$cur_val" != "$prev_val" ]]; then
        CONDITION_WARNINGS+=("${field}: ${prev_val} → ${cur_val}")
        COMPARABLE=false
    fi
done
# Check task sets match
CUR_TASKS=$(jq -r '.task_scores | keys | sort | join(",")' "${CURRENT}/manifest.json" 2>/dev/null)
PREV_TASKS=$(jq -r '.task_scores | keys | sort | join(",")' "${PREVIOUS}/manifest.json" 2>/dev/null)
if [[ "$CUR_TASKS" != "$PREV_TASKS" ]]; then
    CONDITION_WARNINGS+=("task sets differ")
    COMPARABLE=false
fi

if [[ ${#CONDITION_WARNINGS[@]} -gt 0 ]] && ! $FORCE; then
    echo "Error: Evaluation conditions differ — results are not comparable."
    for w in "${CONDITION_WARNINGS[@]}"; do echo "  $w"; done
    echo ""
    echo "Use --force for a non-comparable side-by-side view."
    exit 1
fi

# ---- Extract scores ----
CUR_SCORE=$(jq -r '.benchmark_score_precise // .benchmark_score' "${CURRENT}/manifest.json")
PREV_SCORE=$(jq -r '.benchmark_score_precise // .benchmark_score' "${PREVIOUS}/manifest.json")

CUR_AGENT=$(jq -r '.environment.model // "unknown"' "${CURRENT}/manifest.json")
PREV_AGENT=$(jq -r '.environment.model // "unknown"' "${PREVIOUS}/manifest.json")

echo ""
echo "============================================================"
if $COMPARABLE; then
    echo "  unity-gamedev-bench — Run Comparison"
else
    echo "  unity-gamedev-bench — Side-by-Side (NON-COMPARABLE)"
    echo "  Score generations differ. Absolute deltas are not meaningful."
fi
echo "============================================================"
echo ""
printf "  %-24s %8s → %-8s %6s\n" "" "previous" "current" "Δ"
echo "  ────────────────────────────────────────────────────────"

# Overall score
DELTA=$(echo "$CUR_SCORE $PREV_SCORE" | awk '{printf "%+.1f", $1-$2}')
printf "  %-24s %8.1f → %-8.1f %6s\n" "Overall" "$PREV_SCORE" "$CUR_SCORE" "$DELTA"

# Per-rubric averages
for rubric in correctness robustness readability architecture domain_correctness test_quality; do
    cur_avg=$(jq -r ".rubric_averages.${rubric} // empty" "${CURRENT}/manifest.json")
    prev_avg=$(jq -r ".rubric_averages.${rubric} // empty" "${PREVIOUS}/manifest.json")
    [[ -z "$cur_avg" || -z "$prev_avg" ]] && continue
    display=$(echo "$rubric" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
    rdelta=$(echo "$cur_avg $prev_avg" | awk '{printf "%+.1f", $1-$2}')
    printf "  %-24s %8.1f → %-8.1f %6s\n" "$display" "$prev_avg" "$cur_avg" "$rdelta"
done

# Compile/verified counts
cur_compile=$(jq -r '.summary.compile_pass // "?"' "${CURRENT}/manifest.json")
prev_compile=$(jq -r '.summary.compile_pass // "?"' "${PREVIOUS}/manifest.json")
cur_total=$(jq -r '.summary.tasks_scored // 10' "${CURRENT}/manifest.json")
prev_total=$(jq -r '.summary.tasks_scored // 10' "${PREVIOUS}/manifest.json")
cur_verified=$(jq -r '.summary.verified // 0' "${CURRENT}/manifest.json")
prev_verified=$(jq -r '.summary.verified // 0' "${PREVIOUS}/manifest.json")
printf "  %-24s %8s → %-8s\n" "Compile pass" "${prev_compile}/${prev_total}" "${cur_compile}/${cur_total}"
printf "  %-24s %8s → %-8s\n" "Verified" "${prev_verified}/${prev_total}" "${cur_verified}/${cur_total}"

# Timing
cur_wall=$(jq -r '.timing.wall_seconds // "?"' "${CURRENT}/manifest.json")
prev_wall=$(jq -r '.timing.wall_seconds // "?"' "${PREVIOUS}/manifest.json")
printf "  %-24s %7ss → %-7ss\n" "Wall time" "$prev_wall" "$cur_wall"

# Tokens
cur_tok_in=$(jq -r '.cost.total_tokens_in // "?"' "${CURRENT}/manifest.json")
prev_tok_in=$(jq -r '.cost.total_tokens_in // "?"' "${PREVIOUS}/manifest.json")
if [[ "$cur_tok_in" != "?" && "$prev_tok_in" != "?" ]]; then
    cur_k=$(( cur_tok_in / 1000 ))
    prev_k=$(( prev_tok_in / 1000 ))
    printf "  %-24s %7sk → %-7sk\n" "Tokens (in)" "$prev_k" "$cur_k"
fi

echo ""

# ---- Per-task deltas ----
echo "  Task deltas:"
CUR_TASKS=$(jq -r '.task_scores | keys[]' "${CURRENT}/manifest.json" 2>/dev/null)
for task_id in ${=CUR_TASKS}; do
    cur_ts=$(jq -r ".task_scores.\"${task_id}\".score // 0" "${CURRENT}/manifest.json")
    prev_ts=$(jq -r ".task_scores.\"${task_id}\".score // 0" "${PREVIOUS}/manifest.json")
    tdelta=$(( cur_ts - prev_ts ))
    indicator=""
    if [[ $tdelta -gt 5 ]]; then indicator="▲ improved"
    elif [[ $tdelta -gt 2 ]]; then indicator="↑ small gain"
    elif [[ $tdelta -lt -5 ]]; then indicator="▼ regressed"
    elif [[ $tdelta -lt -2 ]]; then indicator="↓ small loss"
    fi
    printf "    %-6s %3d → %3d  %+3d  %s\n" "$task_id" "$prev_ts" "$cur_ts" "$tdelta" "$indicator"
done

echo ""
if $COMPARABLE; then
    echo "  Interpretation: <2 pts = unchanged, 2-5 = directional, >5 = material"
fi

# ---- Save comparison JSON ----
COMPARISON_FILE="${CURRENT}/comparison.json"
jq -n \
    --arg prev "$(basename "$PREVIOUS")" \
    --arg cur "$(basename "$CURRENT")" \
    --argjson comparable "$($COMPARABLE && echo true || echo false)" \
    --argjson prev_score "$PREV_SCORE" \
    --argjson cur_score "$CUR_SCORE" \
    --arg prev_agent "$PREV_AGENT" \
    --arg cur_agent "$CUR_AGENT" \
    '{previous_label:$prev, current_label:$cur, comparable:$comparable, previous_score:$prev_score, current_score:$cur_score, previous_agent:$prev_agent, current_agent:$cur_agent}' \
    > "$COMPARISON_FILE"
echo "  Comparison: ${COMPARISON_FILE}"
echo "============================================================"
