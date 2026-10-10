#!/usr/bin/env zsh
set -uo pipefail

# ============================================================
# unity-gamedev-bench — List available tasks
# ============================================================

BENCH_ROOT="${0:A:h:h}"

extract_field() {
    grep -m1 "^\*\*${2}:\*\*" "$1" 2>/dev/null | sed "s/^\*\*${2}:\*\* *//" | sed 's/ *$//' || echo ""
}

get_title() {
    grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //' | sed 's/^Task[: ]*//' || echo "?"
}

get_id_from_file() {
    local base=$(basename "$1" .md)
    case "$base" in
        task-[0-9]*)   echo "s$(echo "$base" | grep -o '[0-9][0-9]' | head -1)" ;;
        task-m[0-9]*)  echo "m$(echo "$base" | grep -o 'm[0-9][0-9]' | sed 's/m//')" ;;
        ngo-[0-9]*)    echo "n$(echo "$base" | grep -o '[0-9][0-9]' | head -1)" ;;
        br-[0-9]*)     echo "b$(echo "$base" | grep -o '[0-9][0-9]' | head -1)" ;;
        h[0-9]*)       echo "${base%%-*}" ;;
        v[0-9]*)       echo "${base%%-*}" ;;
        l[0-9]*)       echo "${base%%-*}" ;;
        u[0-9]*)       echo "${base%%-*}" ;;
        i[0-9]*)       echo "${base%%-*}" ;;
        c[0-9]*)       echo "${base%%-*}" ;;
        *)             echo "?" ;;
    esac
}

SCORED=0

printf "%-6s %-45s %-12s %-10s %s\n" "ID" "TITLE" "CATEGORY" "DIFFICULTY" "SOURCE"
printf "%-6s %-45s %-12s %-10s %s\n" "------" "---------------------------------------------" "------------" "----------" "----------"

# Synthetic
for f in "${BENCH_ROOT}"/tasks/synthetic/task-*.md(N); do
    id=$(get_id_from_file "$f")
    title=$(get_title "$f")
    cat=$(extract_field "$f" "Category")
    diff=$(extract_field "$f" "Difficulty")
    printf "%-6s %-45s %-12s %-10s %s\n" "$id" "${title:0:45}" "${cat:-?}" "${diff:-?}" "synthetic"
    ((SCORED++))
done

# All real-world sources
for dir in "${BENCH_ROOT}"/tasks/real-world/*(N/); do
    source=$(basename "$dir")
    for f in "$dir"/*.md(N); do
        id=$(get_id_from_file "$f")
        title=$(get_title "$f")
        cat=$(extract_field "$f" "Category")
        diff=$(extract_field "$f" "Difficulty")
        printf "%-6s %-45s %-12s %-10s %s\n" "$id" "${title:0:45}" "${cat:-?}" "${diff:-?}" "$source"
        ((SCORED++))
    done
done

echo ""
echo "${SCORED} scored tasks"

# Challenges (separate)
CHALLENGES=0
for f in "${BENCH_ROOT}"/tasks/challenges/**/*.md(N); do
    ((CHALLENGES++))
done
[[ $CHALLENGES -gt 0 ]] && echo "${CHALLENGES} challenge tasks (unscored, in tasks/challenges/)"
