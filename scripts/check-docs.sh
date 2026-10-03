#!/usr/bin/env bash
# No downloads, package managers, eval, or document writes.
# Intentionally validates the documented metadata/Markdown subset, not all YAML.
set -uo pipefail
if (( BASH_VERSINFO[0] < 4 )); then
    printf '%s\n' 'ERROR: Bash 4 or newer is required.' >&2
    exit 2
fi
export LC_ALL=C
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
template=0
while (( $# )); do
    case $1 in
        --template) template=1; shift ;;
        --root)
            if (( $# < 2 )) || [[ ! -d $2 ]]; then
                printf '%s\n' 'ERROR: --root requires an existing docs directory.' >&2; exit 2
            fi
            root="$(cd -- "$2" && pwd)"; shift 2 ;;
        --help|-h)
            printf '%s\n' 'Usage: check-docs.sh [--template] [--root DOCS_DIR]'
            exit 0 ;;
        *) printf 'ERROR: Unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
done
for command_name in find realpath; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'ERROR: Existing %s command is required. Nothing was installed.\n' "$command_name" >&2
        exit 2
    fi
done

errors=0 count=0
sep=$'\034'
declare -A meta=() types=() ids=() rows=() edges=() color=()
declare -a files=() namespaces=() entry_flags=() refs=() ref_files=() ref_lines=() ref_contexts=()
declare -a term_refs=() term_files=() term_lines=()
error() { printf 'ERROR %s:%s: %s\n' "${1#"$root"/}" "$2" "$3"; ((errors+=1)); }
trim() { value=$1; value="${value#"${value%%[![:space:]]*}"}"; value="${value%"${value##*[![:space:]]}"}"; }
get() { value=${meta["$1$sep$2"]-}; }
nonempty() { [[ -n ${1//[[:space:]]/} ]]; }
valid_date() {
    [[ $1 =~ ^[0-9]{8}$ ]] || return 1
    local year=$((10#${1:0:4})) month=$((10#${1:4:2})) day=$((10#${1:6:2})) max_day
    (( year > 0 && month >= 1 && month <= 12 && day >= 1 )) || return 1
    case $month in 4|6|9|11) max_day=30 ;; 2)
        max_day=28
        if (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) )); then max_day=29; fi ;;
        *) max_day=31 ;;
    esac
    (( day <= max_day ))
}

# Parse only the safe, single-line values used by the templates. Never evaluate input.
parse_atom() {
    local source=$1 double='^"([^"\\]*)"(.*)$' single="^'([^']*)'(.*)$" bare='^([A-Za-z0-9_.-]+)(.*)$'
    atom= rest= quoted=0
    if [[ $source =~ $double ]]; then
        atom=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}; quoted=1
    elif [[ $source =~ $single ]]; then
        atom=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}; quoted=1
    elif [[ $source =~ $bare ]]; then
        atom=${BASH_REMATCH[1]}; rest=${BASH_REMATCH[2]}
    else return 1
    fi
}
parse_value() {
    local source=$1 item
    parsed= value_type= items=()
    trim "$source"; source=$value
    if [[ $source == \[* ]]; then
        value_type=list; source=${source:1}; trim "$source"; source=$value
        [[ $source != \]* ]] || return 1
        while :; do
            parse_atom "$source" || return 1
            (( quoted )) && nonempty "$atom" || return 1
            items+=("$atom")
            trim "$rest"; source=$value
            if [[ $source == \]* ]]; then
                source=${source:1}; trim "$source"
                [[ -z $value || $value == \#* ]] || return 1
                printf -v parsed '%s\034' "${items[@]}"; parsed=${parsed%"$sep"}
                return 0
            fi
            [[ $source == ,* ]] || return 1
            source=${source:1}; trim "$source"; source=$value
        done
    fi
    parse_atom "$source" || return 1
    trim "$rest"; [[ -z $value || $value == \#* ]] || return 1
    parsed=$atom; value_type=string
    if (( ! quoted )); then
        case $atom in null) value_type=null ;; true|false) value_type=bool ;;
            *) [[ $atom =~ ^[0-9] ]] && value_type=number ;;
        esac
    fi
    return 0
}

validate_meta() {
    local file=$1 kind=$2 ns=$3 key id status v token date_type unknown=0 legacy
    for key in doc_id title type status; do
        get "$file" "$key"
        if [[ ${types["$file$sep$key"]-} != string ]] || ! nonempty "$value"; then
            error "$file" 1 "$key must be a non-empty string"
        fi
    done
    [[ ${types["$file${sep}owners"]-} == list ]] || error "$file" 1 'owners must be a non-empty quoted-string list'
    get "$file" updated
    if [[ ${types["$file${sep}updated"]-} != string ]] || ! valid_date "$value"; then
        error "$file" 1 'updated must be a quoted valid YYYYMMDD date'
    fi
    get "$file" type; [[ $value == "$kind" ]] || error "$file" 1 "type must match directory: $kind"
    get "$file" status; status=$value
    case "$kind/$status" in
        spec/Draft|spec/Active|spec/Deprecated|adr/Active|adr/Superseded|adr/Deprecated|research/Draft|research/Complete|research/Archived|glossary/Draft|glossary/Active|glossary/Deprecated) ;;
        *) error "$file" 1 "invalid $kind status: $status" ;;
    esac
    get "$file" doc_id; id=$value
    if [[ ! $id =~ ^[A-Z0-9_]+-[A-Z0-9_]+-(SPEC|ADR|RESEARCH|GLOSSARY)-[0-9]{4}$ || $id == *-0000 || $id != *-"${kind^^}"-* ]]; then
        error "$file" 1 'doc_id must be PROJECT-SCOPE-TYPE-NNNN; PROJECT/SCOPE use A-Z, 0-9, _; number starts at 0001'
    fi
    if [[ ${file##*/} != "$id"-* ]]; then
        error "$file" 1 'filename must start with doc_id followed by a hyphen'
    else
        token=${file##*/}; token=${token#"$id"-}
        [[ $token =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || error "$file" 1 'invalid lowercase-hyphenated slug'
    fi
    if [[ -n $id ]]; then
        [[ ! ${ids["$ns$sep$id"]+exists} ]] || error "$file" 1 "duplicate doc_id: $id"
        ids["$ns$sep$id"]=$file
    fi
    for key in affects supersedes superseded_by trace.req; do
        if [[ ${meta["$file$sep$key"]+exists} && ${types["$file$sep$key"]} != list ]]; then
            error "$file" 1 "$key must be a non-empty quoted-string list"
        fi
    done
    if [[ $kind != adr ]]; then
        for key in decision_target outcome decision_date decision_makers legacy_record legacy_note supersedes superseded_by; do
            [[ ! ${meta["$file$sep$key"]+exists} ]] || error "$file" 1 "$key is only valid on ADR"
        done
        return
    fi
    get "$file" decision_target
    [[ ${types["$file${sep}decision_target"]-} == string ]] && nonempty "$value" || error "$file" 1 'decision_target must be a non-empty string'
    get "$file" outcome
    [[ $value == Adopted || $value == NotAdopted ]] || error "$file" 1 'outcome must be Adopted or NotAdopted'
    get "$file" legacy_record; legacy=$value
    if [[ ${meta["$file${sep}legacy_record"]+exists} && ( $legacy != true || ${types["$file${sep}legacy_record"]} != bool ) ]]; then
        error "$file" 1 'legacy_record must be unquoted true or omitted'
    fi
    for key in decision_date decision_makers; do
        get "$file" "$key"
        if [[ ${types["$file$sep$key"]-} == null ]]; then
            unknown=1; [[ $legacy == true ]] || error "$file" 1 "$key can be null only in a legacy record"
        elif [[ $key == decision_date ]]; then
            [[ ${types["$file$sep$key"]-} == string ]] && valid_date "$value" || error "$file" 1 'decision_date must be a quoted valid YYYYMMDD date'
        else
            [[ ${types["$file$sep$key"]-} == list ]] || error "$file" 1 'decision_makers must be a non-empty quoted-string list'
        fi
    done
    get "$file" legacy_note
    if [[ $legacy == true ]]; then
        (( unknown )) && [[ ${types["$file${sep}legacy_note"]-} == string ]] && nonempty "$value" || error "$file" 1 'legacy record needs a null decision field and a non-empty legacy_note'
    elif [[ ${meta["$file${sep}legacy_note"]+exists} ]]; then
        error "$file" 1 'legacy_note requires legacy_record: true'
    fi
}

scan_file() {
    local file=$1 kind=$2 ns=$3 allow=$4 line n=0 in_meta=0 closed=0 trace=0 key raw
    local comment=0 fence='' fence_len=0 content before after id state header=0 id_col=-1 state_col=-1 successor_col=-1 i target
    local key_re='^([a-z_]+):[[:space:]]*(.*)$' trace_re='^  req:[[:space:]]*(.*)$'
    local placeholder='\{\{.*\}\}' fence_re='^[ ]{0,3}(`{3,}|~{3,})(.*)$'
    local link_re='!?\[[^][]*\]\(([^()]*)\)' reference_re='\[[^][]]+\]\[[^][]]*\]|^[ ]{0,3}\[[^][]]+\]:'
    local -a cells=()
    ((count+=1))
    while IFS= read -r line || [[ -n $line ]]; do
        ((n+=1)); line=${line%$'\r'}
        if (( n == 1 )); then
            line=${line#$'\357\273\277'}
            if [[ -n $kind ]]; then
                if [[ $line != --- ]]; then error "$file" 1 'front matter must start with ---'; return; fi
                in_meta=1; continue
            fi
        fi
        if (( in_meta )); then
            if [[ $line == --- ]]; then in_meta=0; closed=1; validate_meta "$file" "$kind" "$ns"; continue; fi
            trim "$line"; [[ -z $value || $value == \#* ]] && continue
            if [[ $line == 'trace:' ]]; then
                if (( trace )); then error "$file" "$n" 'duplicate trace key'; fi
                trace=1; continue
            elif [[ $line =~ $trace_re && $trace == 1 ]]; then
                key=trace.req; raw=${BASH_REMATCH[1]}
            elif [[ $line =~ $key_re ]]; then
                key=${BASH_REMATCH[1]}; raw=${BASH_REMATCH[2]}
            else error "$file" "$n" 'unsupported metadata syntax (see README)'; continue
            fi
            case $key in doc_id|title|type|status|owners|updated|rev|trace.req|affects|supersedes|superseded_by|decision_target|outcome|decision_date|decision_makers|legacy_record|legacy_note) ;;
                *) error "$file" "$n" "unsupported metadata key: $key"; continue ;;
            esac
            [[ ! ${meta["$file$sep$key"]+exists} ]] || error "$file" "$n" "duplicate metadata key: $key"
            if ! parse_value "$raw"; then error "$file" "$n" "unsupported or invalid value for $key"; continue; fi
            [[ $parsed != *'{{'* && $parsed != *'}}'* ]] || error "$file" "$n" 'unfilled placeholder in metadata'
            [[ $parsed != *"$sep"* || $value_type == list ]] || error "$file" "$n" 'control character in metadata'
            meta["$file$sep$key"]=$parsed; types["$file$sep$key"]=$value_type
            continue
        fi
        # Fenced examples are skipped before comment removal, so literal <!-- in code is harmless.
        if [[ -n $fence ]]; then
            if [[ $line =~ $fence_re ]]; then
                before=${BASH_REMATCH[1]}; after=${BASH_REMATCH[2]}; trim "$after"
                if [[ ${before:0:1} == "$fence" && ${#before} -ge $fence_len && -z $value ]]; then fence=''; fi
            fi
            continue
        fi
        content=$line
        while :; do
            if (( comment )); then
                if [[ $content == *'-->'* ]]; then content=${content#*'-->'}; comment=0; else content=''; break; fi
            elif [[ $content == *'<!--'* ]]; then
                before=${content%%'<!--'*}; after=${content#*'<!--'}
                if [[ $after == *'-->'* ]]; then content=$before${after#*'-->'}; else content=$before; comment=1; break; fi
            else break
            fi
        done
        if [[ $content =~ $fence_re ]]; then fence=${BASH_REMATCH[1]:0:1}; fence_len=${#BASH_REMATCH[1]}; continue; fi
        if (( ! allow )) && [[ $content == *'{{'* || $content == *'}}'* ]]; then error "$file" "$n" 'unfilled placeholder in visible text'; fi
        # Inline code may show syntax examples; do not interpret it as a link.
        raw=$content
        while [[ $raw =~ \`[^\`]*\` ]]; do raw=${raw/"${BASH_REMATCH[0]}"/}; done
        if [[ $raw =~ $reference_re ]]; then error "$file" "$n" 'reference-style links are unsupported; use [label](relative-path)'; fi
        while [[ $raw =~ $link_re ]]; do
            before=${BASH_REMATCH[0]}; target=${BASH_REMATCH[1]}
            refs+=("$target"); ref_files+=("$file"); ref_lines+=("$n"); ref_contexts+=("$content")
            raw=${raw/"$before"/}
        done
        [[ $raw != *']('* ]] || error "$file" "$n" 'unsupported or malformed link; encode parentheses/spaces in the destination'
        if [[ -n $kind && $content == \|* ]]; then
            raw=${content//\\|/$'\035'}; IFS='|' read -r -a cells <<< "$raw"
            for i in "${!cells[@]}"; do trim "${cells[$i]}"; cells[$i]=${value//\`/}; done
            if [[ ${cells[1]-} == ID ]]; then
                id_col=-1; state_col=-1; successor_col=-1
                for i in "${!cells[@]}"; do
                    case ${cells[$i]} in ID) id_col=$i ;; 状態) state_col=$i ;; 後継ID) successor_col=$i ;; esac
                done
                header=1; continue
            fi
            if (( header && id_col >= 0 && state_col >= 0 )); then
                id=${cells[$id_col]-}; state=${cells[$state_col]-}
                [[ $id != *---* ]] || continue
                case $kind in
                    spec) [[ $id =~ ^[FN][0-9]{3,}$ ]] && [[ $state == Current || $state == Deprecated ]] || error "$file" "$n" 'invalid requirement ID or state' ;;
                    glossary) [[ $id =~ ^T[0-9]{3,}$ ]] && [[ $state == Active || $state == Deprecated ]] || error "$file" "$n" 'invalid term ID or state' ;;
                    *) continue ;;
                esac
                get "$file" doc_id; key="$ns$sep$value/$id"
                [[ ! ${rows["$key"]+exists} ]] || error "$file" "$n" "duplicate row ID: $id"
                rows["$key"]=1
                if [[ $kind == glossary ]] && (( successor_col >= 0 )); then
                    target=${cells[$successor_col]-}
                    if [[ -n $target && $target != なし ]]; then
                        [[ $target == */* ]] || target="$value/$target"
                        term_refs+=("$ns$sep$target"); term_files+=("$file"); term_lines+=("$n")
                    fi
                fi
            fi
        else header=0
        fi
    done < "$file"
    if [[ -n $kind ]]; then
        (( closed )) || error "$file" "$n" 'front matter closing --- is missing'
        if (( trace )) && [[ ! ${meta["$file${sep}trace.req"]+exists} ]]; then error "$file" 1 'trace requires an indented req list'; fi
    fi
    (( ! comment )) || error "$file" "$n" 'unclosed HTML comment'
    [[ -z $fence ]] || error "$file" "$n" 'unclosed code fence'
}

scan_namespace() {
    local base=$1 ns=$2 allow=$3 required=$4 kind file
    for kind in spec adr research glossary; do
        [[ -d $base/$kind ]] || continue
        while IFS= read -r -d '' file; do
            [[ $file != "$base/$kind/_template.md" ]] || continue
            files+=("$file"); namespaces+=("$ns"); entry_flags+=(0)
            scan_file "$file" "$kind" "$ns" 0
        done < <(find "$base/$kind" -type f -name '*.md' -print0)
    done
    for kind in README.md index.md; do
        file=$base/$kind
        if [[ -f $file ]]; then
            files+=("$file"); namespaces+=("$ns"); entry_flags+=(1)
            scan_file "$file" '' "$ns" "$allow"
        elif (( required )); then error "$file" 1 'required entry document is missing'
        fi
    done
}

check_links() {
    local i target file path status kind expected decoded byte hex context pattern
    for i in "${!refs[@]}"; do
        target=${refs[$i]}; file=${ref_files[$i]}
        [[ ! $target =~ ^[A-Za-z][A-Za-z0-9+.-]*: && $target != //* ]] || continue
        target=${target%%#*}; target=${target%%\?*}; [[ -n $target ]] || continue
        if [[ $target == /* || $target == *\\* || $target == *[[:space:]]* ]]; then
            error "$file" "${ref_lines[$i]}" 'link destination must be relative and use %20 for spaces'; continue
        fi
        decoded=''
        while [[ $target =~ ^([^%]*)%([0-9A-Fa-f]{2})(.*)$ ]]; do
            decoded+=${BASH_REMATCH[1]}; hex=${BASH_REMATCH[2]}; target=${BASH_REMATCH[3]}
            if [[ $hex == 00 || $hex == 0[aAdD] || $hex == 1[cC] ]]; then
                error "$file" "${ref_lines[$i]}" 'control character in link'; target=''; break
            fi
            printf -v byte '%b' "\\x$hex"; decoded+=$byte
        done
        target=$decoded$target
        path=$(realpath -m -- "${file%/*}/$target")
        if [[ ! -e $path ]]; then error "$file" "${ref_lines[$i]}" "link target does not exist: ${refs[$i]}"; continue; fi
        if [[ ${file##*/} == index.md && ${meta["$path${sep}type"]+exists} ]]; then
            get "$path" type; kind=$value; get "$path" status; status=$value
            expected=Active; [[ $kind != research ]] || expected=Complete
            if [[ $status != "$expected" ]]; then
                context=${ref_contexts[$i]}; pattern="$status[[:space:]]*[:：][[:space:]]*[^[:space:]|)）]+"
                [[ -n $status && $context =~ $pattern ]] || error "$file" "${ref_lines[$i]}" "index link requires '$status: reason' on the same line"
            fi
        fi
    done
    for i in "${!term_refs[@]}"; do
        [[ ${rows["${term_refs[$i]}"]+exists} ]] || error "${term_files[$i]}" "${term_lines[$i]}" 'successor term ID does not exist'
    done
}

check_replacements() {
    local i file ns id status field inverse target other reverse key node next current
    local -a targets=() pending=()
    local -A seen=()
    for i in "${!files[@]}"; do
        file=${files[$i]}; ns=${namespaces[$i]}
        get "$file" type; [[ $value == adr ]] || continue
        get "$file" doc_id; id=$value; get "$file" status; status=$value
        get "$file" superseded_by
        if [[ $status == Superseded && -z $value || $status != Superseded && -n $value ]]; then
            error "$file" 1 'Superseded state and superseded_by must be set together'
        fi
        for field in supersedes superseded_by; do
            inverse=supersedes; [[ $field != supersedes ]] || inverse=superseded_by
            get "$file" "$field"; IFS=$sep read -r -a targets <<< "$value"
            seen=()
            for target in "${targets[@]}"; do
                [[ -n $target ]] || continue
                [[ ! ${seen["$target"]+exists} ]] || error "$file" 1 "duplicate $field target: $target"
                seen["$target"]=1; other=${ids["$ns$sep$target"]-}
                get "$other" type
                if [[ -z $other || $value != adr ]]; then error "$file" 1 "$field target ADR does not exist: $target"; continue; fi
                get "$other" "$inverse"; reverse="$sep$value$sep"
                [[ $reverse == *"$sep$id$sep"* ]] || error "$file" 1 "$field lacks reciprocal $inverse: $target"
                if [[ $field == superseded_by ]]; then
                    key="$ns$sep$id"; edges["$key"]+="$target$sep"
                fi
            done
        done
    done
    # Reachability per source: no recursion limit, including split/merge histories.
    for node in "${!edges[@]}"; do
        ns=${node%%"$sep"*}; id=${node#*"$sep"}; pending=("$id"); seen=()
        while (( ${#pending[@]} )); do
            current=${pending[${#pending[@]}-1]}; unset 'pending[${#pending[@]}-1]'
            [[ ! ${seen["$current"]+exists} ]] || continue
            seen["$current"]=1; key="$ns$sep$current"
            IFS=$sep read -r -a targets <<< "${edges["$key"]-}"
            for next in "${targets[@]}"; do
                [[ -n $next ]] || continue
                if [[ $next == "$id" ]]; then error "${ids["$node"]}" 1 "cycle in ADR replacement history: $id"; pending=(); break; fi
                pending+=("$next")
            done
        done
    done
}

scan_namespace "$root" main "$template" 1
[[ ! -d $root/examples ]] || scan_namespace "$root/examples" examples 0 0
check_links
check_replacements
mode=strict; (( ! template )) || mode=template
if (( errors )); then printf 'FAIL: %s documents, %s errors (%s mode)\n' "$count" "$errors" "$mode"; exit 1; fi
printf 'OK: %s documents, 0 errors (%s mode)\n' "$count" "$mode"
