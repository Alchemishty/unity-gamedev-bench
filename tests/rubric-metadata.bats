#!/usr/bin/env bats

# Validates that all 39 scored tasks have rubric declarations in their metadata

REAL_BENCH_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

@test "all 39 scored tasks have rubric declarations" {
    local missing=() count=0
    for f in "${REAL_BENCH_ROOT}"/tasks/synthetic/*.md "${REAL_BENCH_ROOT}"/tasks/real-world/**/*.md; do
        [[ -f "$f" ]] || continue
        ((++count))
        local rubrics
        rubrics=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^rubrics:" 2>/dev/null | sed "s/^rubrics: *//" || echo "")
        if [[ -z "$rubrics" ]]; then
            missing+=("$(basename "$f")")
        fi
    done
    echo "Total scored tasks: ${count}"
    echo "Missing rubrics: ${missing[*]:-none}"
    [ "$count" -eq 39 ]
    [ "${#missing[@]}" -eq 0 ]
}

@test "every rubric declaration uses only valid rubric slugs" {
    local valid_slugs="correctness robustness readability architecture domain_correctness test_quality"
    local errors=()
    for f in "${REAL_BENCH_ROOT}"/tasks/synthetic/*.md "${REAL_BENCH_ROOT}"/tasks/real-world/**/*.md; do
        [[ -f "$f" ]] || continue
        local rubrics
        rubrics=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^rubrics:" 2>/dev/null | sed "s/^rubrics: *//" || echo "")
        [[ -z "$rubrics" ]] && continue
        IFS=',' read -ra slugs <<< "$rubrics"
        for slug in "${slugs[@]}"; do
            slug=$(echo "$slug" | tr -d ' ')
            if [[ ! " $valid_slugs " == *" $slug "* ]]; then
                errors+=("$(basename "$f"): invalid slug '${slug}'")
            fi
        done
    done
    echo "Errors: ${errors[*]:-none}"
    [ "${#errors[@]}" -eq 0 ]
}

@test "every rubric declaration includes correctness" {
    local missing=()
    for f in "${REAL_BENCH_ROOT}"/tasks/synthetic/*.md "${REAL_BENCH_ROOT}"/tasks/real-world/**/*.md; do
        [[ -f "$f" ]] || continue
        local rubrics
        rubrics=$(sed -n '/^<!--/,/^-->/p' "$f" 2>/dev/null | grep -m1 "^rubrics:" 2>/dev/null | sed "s/^rubrics: *//" || echo "")
        [[ -z "$rubrics" ]] && continue
        if [[ ! "$rubrics" == *"correctness"* ]]; then
            missing+=("$(basename "$f")")
        fi
    done
    echo "Missing correctness: ${missing[*]:-none}"
    [ "${#missing[@]}" -eq 0 ]
}
