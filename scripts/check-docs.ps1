# Windows PowerShell 5.1 / PowerShell 7. No modules, downloads or document writes.
param([switch]$Template, [string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$script:Problems = [Collections.Generic.List[string]]::new()
$script:Documents = [Collections.Generic.List[object]]::new()
$script:Links = [Collections.Generic.List[object]]::new()
$script:Terms = @{}
$script:TermLinks = [Collections.Generic.List[object]]::new()
$script:Ids = @{}
$script:Count = 0
$script:Sep = [char]28
$script:Utf8 = [Text.UTF8Encoding]::new($false, $true)

function Add-Problem($File, $Line, $Message) {
    $name = $File
    if ($name.StartsWith($script:RootPath + [IO.Path]::DirectorySeparatorChar)) {
        $name = $name.Substring($script:RootPath.Length + 1)
    }
    $script:Problems.Add(('ERROR {0}:{1}: {2}' -f $name, $Line, $Message))
}

function Read-Atom([string]$Source) {
    foreach ($pattern in @('^"([^"\\]*)"(.*)$', "^'([^']*)'(.*)$", '^([A-Za-z0-9_.-]+)(.*)$')) {
        $match = [regex]::Match($Source, $pattern)
        if ($match.Success) {
            return @{ Value = $match.Groups[1].Value; Rest = $match.Groups[2].Value; Quoted = ($pattern -ne '^([A-Za-z0-9_.-]+)(.*)$') }
        }
    }
    throw 'unsupported scalar syntax'
}

function Read-Value([string]$Source) {
    $Source = $Source.Trim()
    if ($Source.StartsWith('[')) {
        $remaining = $Source.Substring(1).Trim()
        $items = [Collections.Generic.List[string]]::new()
        while ($true) {
            $atom = Read-Atom $remaining
            if (-not $atom.Quoted -or [string]::IsNullOrWhiteSpace($atom.Value)) { throw 'list entries must be non-empty quoted strings' }
            $items.Add($atom.Value)
            $remaining = $atom.Rest.Trim()
            if ($remaining.StartsWith(']')) {
                $tail = $remaining.Substring(1).Trim()
                if ($tail -and -not $tail.StartsWith('#')) { throw 'unexpected text after list' }
                return @{ Value = $items.ToArray(); Kind = 'list' }
            }
            if (-not $remaining.StartsWith(',')) { throw 'missing list separator or closing bracket' }
            $remaining = $remaining.Substring(1).Trim()
        }
    }
    $atom = Read-Atom $Source
    $tail = $atom.Rest.Trim()
    if ($tail -and -not $tail.StartsWith('#')) { throw 'unexpected text after scalar' }
    $kind = 'string'
    if (-not $atom.Quoted) {
        if ($atom.Value -ceq 'null') { $kind = 'null' }
        elseif ($atom.Value -cin @('true', 'false')) { $kind = 'bool' }
        elseif ($atom.Value -cmatch '^[0-9]') { $kind = 'number' }
    }
    return @{ Value = $atom.Value; Kind = $kind }
}

function Test-Date($Value) {
    $date = [datetime]::MinValue
    return ($Value -is [string] -and $Value -cmatch '^[0-9]{8}$' -and
        [datetime]::TryParseExact($Value, 'yyyyMMdd', [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::None, [ref]$date))
}

function Test-Metadata($Doc) {
    $m = $Doc.Meta; $t = $Doc.Types; $file = $Doc.Path; $kind = $Doc.Kind
    foreach ($key in @('doc_id', 'title', 'type', 'status')) {
        if ($t[$key] -cne 'string' -or [string]::IsNullOrWhiteSpace($m[$key])) { Add-Problem $file 1 "$key must be a non-empty string" }
    }
    if ($t['owners'] -cne 'list') { Add-Problem $file 1 'owners must be a non-empty quoted-string list' }
    if ($t['updated'] -cne 'string' -or -not (Test-Date $m['updated'])) { Add-Problem $file 1 'updated must be a quoted valid YYYYMMDD date' }
    if ($m['type'] -cne $kind) { Add-Problem $file 1 "type must match directory: $kind" }
    $states = @{ spec = @('Draft', 'Active', 'Deprecated'); adr = @('Active', 'Superseded', 'Deprecated'); research = @('Draft', 'Complete', 'Archived'); glossary = @('Draft', 'Active', 'Deprecated') }
    if ($states[$kind] -cnotcontains $m['status']) { Add-Problem $file 1 "invalid $kind status" }
    $id = [string]$m['doc_id']
    if ($id -cnotmatch ('^[A-Z0-9_]+-[A-Z0-9_]+-' + $kind.ToUpperInvariant() + '-[0-9]{4}$') -or $id.EndsWith('-0000')) {
        Add-Problem $file 1 'doc_id must be PROJECT-SCOPE-TYPE-NNNN; PROJECT/SCOPE use A-Z, 0-9, _; number starts at 0001'
    }
    if ([IO.Path]::GetFileName($file) -cnotmatch ('^' + [regex]::Escape($id) + '-[a-z0-9]+(-[a-z0-9]+)*\.md$')) {
        Add-Problem $file 1 'filename must be <doc_id>-<lowercase-hyphenated-slug>.md'
    }
    if ($id) {
        $key = $Doc.Namespace + $script:Sep + $id
        if ($script:Ids.ContainsKey($key)) { Add-Problem $file 1 "duplicate doc_id: $id" }
        $script:Ids[$key] = $Doc
    }
    foreach ($key in @('affects', 'supersedes', 'superseded_by', 'trace.req')) {
        if ($m.ContainsKey($key) -and $t[$key] -cne 'list') { Add-Problem $file 1 "$key must be a non-empty quoted-string list" }
    }
    if ($kind -cne 'adr') {
        foreach ($key in @('decision_target', 'outcome', 'decision_date', 'decision_makers', 'legacy_record', 'legacy_note', 'supersedes', 'superseded_by')) {
            if ($m.ContainsKey($key)) { Add-Problem $file 1 "$key is only valid on ADR" }
        }
        return
    }
    if ($t['decision_target'] -cne 'string' -or [string]::IsNullOrWhiteSpace($m['decision_target'])) { Add-Problem $file 1 'decision_target must be a non-empty string' }
    if ($m['outcome'] -cnotin @('Adopted', 'NotAdopted')) { Add-Problem $file 1 'outcome must be Adopted or NotAdopted' }
    $legacy = $m['legacy_record'] -ceq 'true' -and $t['legacy_record'] -ceq 'bool'
    if ($m.ContainsKey('legacy_record') -and -not $legacy) { Add-Problem $file 1 'legacy_record must be unquoted true or omitted' }
    $unknown = $false
    foreach ($key in @('decision_date', 'decision_makers')) {
        if ($t[$key] -ceq 'null') {
            $unknown = $true
            if (-not $legacy) { Add-Problem $file 1 "$key can be null only in a legacy record" }
        }
        elseif ($key -ceq 'decision_date') {
            if ($t[$key] -cne 'string' -or -not (Test-Date $m[$key])) { Add-Problem $file 1 'decision_date must be a quoted valid YYYYMMDD date' }
        }
        elseif ($t[$key] -cne 'list') { Add-Problem $file 1 'decision_makers must be a non-empty quoted-string list' }
    }
    if ($legacy) {
        if (-not $unknown -or $t['legacy_note'] -cne 'string' -or [string]::IsNullOrWhiteSpace($m['legacy_note'])) {
            Add-Problem $file 1 'legacy record needs a null decision field and a non-empty legacy_note'
        }
    }
    elseif ($m.ContainsKey('legacy_note')) { Add-Problem $file 1 'legacy_note requires legacy_record: true' }
}

function Read-Document($File, $Kind, $Namespace, $AllowPlaceholders) {
    $script:Count++
    try { $lines = [IO.File]::ReadAllLines($File, $script:Utf8) }
    catch { Add-Problem $File 1 "cannot read UTF-8 document: $($_.Exception.Message)"; return }
    $doc = @{ Path = $File; Kind = $Kind; Namespace = $Namespace; Meta = @{}; Types = @{} }
    $script:Documents.Add($doc)
    $start = 0
    if ($Kind) {
        if ($lines.Count -lt 1 -or $lines[0] -cne '---') { Add-Problem $File 1 'front matter must start with ---'; return }
        $closed = $false; $trace = $false
        for ($i = 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -ceq '---') { $start = $i + 1; $closed = $true; break }
            if (-not $line.Trim() -or $line.Trim().StartsWith('#')) { continue }
            if ($line -ceq 'trace:') {
                if ($trace) { Add-Problem $File ($i + 1) 'duplicate trace key' }
                $trace = $true; continue
            }
            if ($trace -and $line -cmatch '^  req:\s*(.*)$') { $key = 'trace.req'; $raw = $Matches[1] }
            elseif ($line -cmatch '^([a-z_]+):\s*(.*)$') { $key = $Matches[1]; $raw = $Matches[2] }
            else { Add-Problem $File ($i + 1) 'unsupported metadata syntax (see README)'; continue }
            if ($key -cnotin @('doc_id', 'title', 'type', 'status', 'owners', 'updated', 'rev', 'trace.req', 'affects', 'supersedes', 'superseded_by', 'decision_target', 'outcome', 'decision_date', 'decision_makers', 'legacy_record', 'legacy_note')) {
                Add-Problem $File ($i + 1) "unsupported metadata key: $key"; continue
            }
            if ($doc.Meta.ContainsKey($key)) { Add-Problem $File ($i + 1) "duplicate metadata key: $key" }
            try { $parsed = Read-Value $raw }
            catch { Add-Problem $File ($i + 1) "unsupported or invalid value for $key"; continue }
            if ($raw.Contains('{{') -or $raw.Contains('}}')) { Add-Problem $File ($i + 1) 'unfilled placeholder in metadata' }
            $doc.Meta[$key] = $parsed.Value; $doc.Types[$key] = $parsed.Kind
        }
        if (-not $closed) { Add-Problem $File $lines.Count 'front matter closing --- is missing'; return }
        if ($trace -and -not $doc.Meta.ContainsKey('trace.req')) { Add-Problem $File 1 'trace requires an indented req list' }
        Test-Metadata $doc
    }
    $comment = $false; $fence = ''; $fenceLength = 0; $headers = @()
    for ($i = $start; $i -lt $lines.Count; $i++) {
        $content = $lines[$i]; $number = $i + 1
        if ($fence) {
            if ($content -cmatch '^[ ]{0,3}(`{3,}|~{3,})(.*)$' -and $Matches[1].Substring(0, 1) -ceq $fence -and $Matches[1].Length -ge $fenceLength -and -not $Matches[2].Trim()) { $fence = '' }
            continue
        }
        while ($true) {
            if ($comment) {
                $end = $content.IndexOf('-->')
                if ($end -lt 0) { $content = ''; break }
                $content = $content.Substring($end + 3); $comment = $false
            }
            else {
                $begin = $content.IndexOf('<!--')
                if ($begin -lt 0) { break }
                $end = $content.IndexOf('-->', $begin + 4)
                if ($end -lt 0) { $content = $content.Substring(0, $begin); $comment = $true; break }
                $content = $content.Substring(0, $begin) + $content.Substring($end + 3)
            }
        }
        if ($content -cmatch '^[ ]{0,3}(`{3,}|~{3,})(.*)$') { $fence = $Matches[1].Substring(0, 1); $fenceLength = $Matches[1].Length; continue }
        if (-not $AllowPlaceholders -and ($content.Contains('{{') -or $content.Contains('}}'))) { Add-Problem $File $number 'unfilled placeholder in visible text' }
        $raw = [regex]::Replace($content, '`[^`]*`', '')
        if ($raw -cmatch '\[[^\[\]]+\]\[[^\[\]]*\]|^[ ]{0,3}\[[^\[\]]+\]:') { Add-Problem $File $number 'reference-style links are unsupported; use [label](relative-path)' }
        $pattern = '!?\[[^\[\]]*\]\(([^()]*)\)'
        foreach ($link in [regex]::Matches($raw, $pattern)) {
            $script:Links.Add(@{ File = $File; Line = $number; Target = $link.Groups[1].Value; Context = $content })
        }
        $raw = [regex]::Replace($raw, $pattern, '')
        if ($raw.Contains('](')) { Add-Problem $File $number 'unsupported or malformed link; encode parentheses/spaces in the destination' }
        if ($Kind -and $content.StartsWith('|')) {
            $cells = @($content.Replace('\|', [string][char]29).Split('|') | ForEach-Object { $_.Trim().Replace('`', '') })
            if ($cells.Count -gt 1 -and $cells[1] -ceq 'ID') { $headers = $cells; continue }
            $idColumn = [array]::IndexOf($headers, 'ID'); $stateColumn = [array]::IndexOf($headers, '状態')
            if ($idColumn -ge 0 -and $stateColumn -ge 0 -and $Kind -cin @('spec', 'glossary')) {
                $id = if ($idColumn -lt $cells.Count) { $cells[$idColumn] } else { '' }
                $state = if ($stateColumn -lt $cells.Count) { $cells[$stateColumn] } else { '' }
                if ($id.Contains('---')) { continue }
                if ($Kind -ceq 'spec') {
                    if ($id -cnotmatch '^[FN][0-9]{3,}$' -or $state -cnotin @('Current', 'Deprecated')) { Add-Problem $File $number 'invalid requirement ID or state' }
                }
                elseif ($id -cnotmatch '^T[0-9]{3,}$' -or $state -cnotin @('Active', 'Deprecated')) { Add-Problem $File $number 'invalid term ID or state' }
                $fullId = $doc.Meta['doc_id'] + '/' + $id; $key = $Namespace + $script:Sep + $fullId
                if ($script:Terms.ContainsKey($key)) { Add-Problem $File $number "duplicate row ID: $id" }
                $script:Terms[$key] = $true
                $successor = [array]::IndexOf($headers, '後継ID')
                if ($Kind -ceq 'glossary' -and $successor -ge 0 -and $successor -lt $cells.Count) {
                    $target = $cells[$successor]
                    if ($target -and $target -cne 'なし') {
                        if (-not $target.Contains('/')) { $target = $doc.Meta['doc_id'] + '/' + $target }
                        $script:TermLinks.Add(@{ Key = $Namespace + $script:Sep + $target; File = $File; Line = $number })
                    }
                }
            }
        }
        else { $headers = @() }
    }
    if ($comment) { Add-Problem $File $lines.Count 'unclosed HTML comment' }
    if ($fence) { Add-Problem $File $lines.Count 'unclosed code fence' }
}

function Read-Namespace($Base, $Namespace, $AllowPlaceholders, $Required) {
    foreach ($kind in @('spec', 'adr', 'research', 'glossary')) {
        $directory = Join-Path $Base $kind
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File -Filter '*.md') {
            if ($file.FullName -eq (Join-Path $directory '_template.md')) { continue }
            Read-Document $file.FullName $kind $Namespace $false
        }
    }
    foreach ($name in @('README.md', 'index.md')) {
        $file = Join-Path $Base $name
        if (Test-Path -LiteralPath $file -PathType Leaf) { Read-Document $file '' $Namespace $AllowPlaceholders }
        elseif ($Required) { Add-Problem $file 1 'required entry document is missing' }
    }
}

function Test-Links {
    $byPath = @{}
    foreach ($doc in $script:Documents) { $byPath[$doc.Path] = $doc }
    foreach ($link in $script:Links) {
        $target = $link.Target
        if ($target -cmatch '^[A-Za-z][A-Za-z0-9+.-]*:' -or $target.StartsWith('//')) { continue }
        $target = ($target -split '[#?]', 2)[0]
        if (-not $target) { continue }
        if ($target.StartsWith('/') -or $target.Contains('\') -or $target -match '\s') { Add-Problem $link.File $link.Line 'link destination must be relative and use %20 for spaces'; continue }
        try {
            $target = [Uri]::UnescapeDataString($target)
            if ($target -match '[\x00\r\n\x1c]') { throw 'control character in link' }
            $path = [IO.Path]::GetFullPath((Join-Path (Split-Path $link.File -Parent) $target))
            if (-not (Test-Path -LiteralPath $path)) { Add-Problem $link.File $link.Line "link target does not exist: $($link.Target)"; continue }
        }
        catch { Add-Problem $link.File $link.Line 'invalid link destination'; continue }
        if ([IO.Path]::GetFileName($link.File) -ceq 'index.md' -and $byPath.ContainsKey($path) -and $byPath[$path].Kind) {
            $linked = $byPath[$path]; $status = [string]$linked.Meta['status']
            $expected = if ($linked.Kind -ceq 'research') { 'Complete' } else { 'Active' }
            if ($status -cne $expected -and (-not $status -or $link.Context -cnotmatch ([regex]::Escape($status) + '\s*[:：]\s*[^\s|)）]+'))) {
                Add-Problem $link.File $link.Line "index link requires '$status`: reason' on the same line"
            }
        }
    }
    foreach ($link in $script:TermLinks) {
        if (-not $script:Terms.ContainsKey($link.Key)) { Add-Problem $link.File $link.Line 'successor term ID does not exist' }
    }
}

function Test-Replacements {
    $edges = @{}
    foreach ($doc in $script:Documents) {
        if ($doc.Kind -cne 'adr') { continue }
        $m = $doc.Meta; $id = [string]$m['doc_id']; $ns = $doc.Namespace
        if (($m['status'] -ceq 'Superseded') -ne [bool]$m['superseded_by']) { Add-Problem $doc.Path 1 'Superseded state and superseded_by must be set together' }
        foreach ($field in @('supersedes', 'superseded_by')) {
            $inverse = if ($field -ceq 'supersedes') { 'superseded_by' } else { 'supersedes' }
            $seen = @{}
            foreach ($target in @($m[$field])) {
                if (-not $target) { continue }
                if ($seen.ContainsKey($target)) { Add-Problem $doc.Path 1 "duplicate $field target: $target" }
                $seen[$target] = $true
                $other = $script:Ids[$ns + $script:Sep + $target]
                if (-not $other -or $other.Kind -cne 'adr') { Add-Problem $doc.Path 1 "$field target ADR does not exist: $target"; continue }
                if (@($other.Meta[$inverse]) -cnotcontains $id) { Add-Problem $doc.Path 1 "$field lacks reciprocal $inverse`: $target" }
                if ($field -ceq 'superseded_by') { $edges[$ns + $script:Sep + $id] += @($target) }
            }
        }
    }
    foreach ($node in @($edges.Keys)) {
        $parts = $node.Split($script:Sep); $ns = $parts[0]; $id = $parts[1]
        $pending = [Collections.Generic.Stack[string]]::new(); $pending.Push($id); $seen = @{}
        while ($pending.Count) {
            $current = $pending.Pop()
            if ($seen.ContainsKey($current)) { continue }
            $seen[$current] = $true
            foreach ($next in @($edges[$ns + $script:Sep + $current])) {
                if (-not $next) { continue }
                if ($next -ceq $id) { Add-Problem $script:Ids[$node].Path 1 "cycle in ADR replacement history: $id"; $pending.Clear(); break }
                $pending.Push($next)
            }
        }
    }
}

try {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw 'docs directory does not exist' }
    $script:RootPath = (Resolve-Path -LiteralPath $Root).ProviderPath.TrimEnd([IO.Path]::DirectorySeparatorChar)
    Read-Namespace $script:RootPath 'main' ([bool]$Template) $true
    $examples = Join-Path $script:RootPath 'examples'
    if (Test-Path -LiteralPath $examples -PathType Container) { Read-Namespace $examples 'examples' $false $false }
    Test-Links
    Test-Replacements
    foreach ($problem in $script:Problems) { Write-Output $problem }
    $mode = if ($Template) { 'template' } else { 'strict' }
    if ($script:Problems.Count) { Write-Output "FAIL: $script:Count documents, $($script:Problems.Count) errors ($mode mode)"; exit 1 }
    Write-Output "OK: $script:Count documents, 0 errors ($mode mode)"
    exit 0
}
catch { Write-Output "ERROR: $($_.Exception.Message)"; exit 2 }
