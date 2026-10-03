#!/usr/bin/env bash
set -euo pipefail
test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd -- "$test_dir/../.." && pwd)"
temp_parent="$(cd -- "${TMPDIR:-/tmp}" && pwd)"
test_root="$(mktemp -d "$temp_parent/docs-check.XXXXXXXX")"
cleanup() {
    if [[ ${test_root%/*} == "$temp_parent" && ${test_root##*/} == docs-check.* ]]; then
        rm -rf -- "$test_root"
    else printf '%s\n' 'Unsafe fixture cleanup path' >&2; return 1
    fi
}
trap cleanup EXIT
expand() {
    text=${1//@SPEC@/spec\/DEMO-GLOBAL-SPEC-0001-port-check.md}
    text=${text//@SPEC2@/spec\/DEMO-GLOBAL-SPEC-0002-port-check.md}
    text=${text//@ADR@/adr\/DEMO-GLOBAL-ADR-0001-cli-interface.md}
    text=${text//@ADR2@/adr\/DEMO-GLOBAL-ADR-0002-cli-interface.md}
    text=${text//\\n/$'\n'}; text=${text//\\t/$'\t'}
}
previous='' fixture='' expected=0 diagnostic='-' failures=0 total=0
run_case() {
    local result actual
    if result=$(bash "$repo/scripts/check-docs.sh" --root "$fixture" 2>&1); then actual=0; else actual=$?; fi
    ((total+=1))
    if [[ $actual != "$expected" || ( $diagnostic != - && $result != *"$diagnostic"* ) ]]; then
        ((failures+=1)); printf 'FAIL %s (expected %s, got %s):\n%s\n' "$previous" "$expected" "$actual" "$result"
    else printf 'PASS %s\n' "$previous"
    fi
}
while IFS=$'\t' read -r name code operation file before after message || [[ -n $name ]]; do
    message=${message%$'\r'}
    [[ -n $name && $name != \#* ]] || continue
    if [[ $name != "$previous" ]]; then
        [[ -z $previous ]] || run_case
        previous=$name; expected=$code; diagnostic=$message
        fixture="$test_root/$name space"
        mkdir -- "$fixture"
        cp -R -- "$repo/examples/." "$fixture/"
        cp -- "$test_dir/index.md" "$fixture/index.md"
    fi
    expand "$file"; file="$fixture/$text"
    expand "$before"; before=$text; expand "$after"; after=$text
    case $operation in
        noop) ;;
        replace)
            text=$(< "$file")
            [[ $text == *"$before"* ]] || { printf 'Missing replacement text in %s\n' "$name" >&2; exit 2; }
            printf '%s\n' "${text//"$before"/"$after"}" > "$file" ;;
        append) printf '%s' "$after" >> "$file" ;;
        put) mkdir -p -- "${file%/*}"; printf '%s' "$after" > "$file" ;;
        copy) cp -- "$file" "$fixture/$after" ;;
        remove) rm -- "$file" ;;
        *) printf 'Unknown test operation: %s\n' "$operation" >&2; exit 2 ;;
    esac
done < "$test_dir/cases.tsv"
[[ -z $previous ]] || run_case
printf 'Tests: %s, failures: %s\n' "$total" "$failures"
(( failures == 0 ))
