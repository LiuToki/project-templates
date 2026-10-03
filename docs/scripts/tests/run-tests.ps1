# Shared black-box cases for the PowerShell and Bash checkers.
$ErrorActionPreference = 'Stop'
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
$testRoot = Join-Path $tempParent ('docs-check-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)
$aliases = @{
    '@SPEC@' = 'spec/DEMO-GLOBAL-SPEC-0001-port-check.md'
    '@SPEC2@' = 'spec/DEMO-GLOBAL-SPEC-0002-port-check.md'
    '@ADR@' = 'adr/DEMO-GLOBAL-ADR-0001-cli-interface.md'
    '@ADR2@' = 'adr/DEMO-GLOBAL-ADR-0002-cli-interface.md'
}
function Expand-TestText([string]$Text) {
    foreach ($key in $aliases.Keys) { $Text = $Text.Replace($key, $aliases[$key]) }
    return $Text.Replace('\n', "`n").Replace('\t', "`t")
}
$groups = [ordered]@{}
foreach ($line in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot 'cases.tsv'), $utf8)) {
    if (-not $line -or $line.StartsWith('#')) { continue }
    $fields = $line.Split("`t")
    if ($fields.Count -ne 7) { throw "Invalid test row: $line" }
    if (-not $groups.Contains($fields[0])) { $groups[$fields[0]] = [Collections.Generic.List[object]]::new() }
    $groups[$fields[0]].Add($fields)
}
$failures = 0
try {
    [void][IO.Directory]::CreateDirectory($testRoot)
    foreach ($name in $groups.Keys) {
        $fixture = Join-Path $testRoot ($name + ' space')
        [void][IO.Directory]::CreateDirectory($fixture)
        Copy-Item -Path (Join-Path $repo 'examples/*') -Destination $fixture -Recurse
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'index.md') -Destination (Join-Path $fixture 'index.md')
        foreach ($fields in $groups[$name]) {
            $file = Join-Path $fixture (Expand-TestText $fields[3])
            $before = Expand-TestText $fields[4]; $after = Expand-TestText $fields[5]
            switch ($fields[2]) {
                'noop' { }
                'replace' {
                    $text = [IO.File]::ReadAllText($file, $utf8)
                    if (-not $text.Contains($before)) { throw "Missing replacement text in $name" }
                    [IO.File]::WriteAllText($file, $text.Replace($before, $after), $utf8)
                }
                'append' { [IO.File]::AppendAllText($file, $after, $utf8) }
                'put' { [void][IO.Directory]::CreateDirectory((Split-Path $file -Parent)); [IO.File]::WriteAllText($file, $after, $utf8) }
                'copy' { Copy-Item -LiteralPath $file -Destination (Join-Path $fixture $after) }
                'remove' { Remove-Item -LiteralPath $file }
                default { throw "Unknown test operation: $($fields[2])" }
            }
        }
        $expected = [int]$groups[$name][0][1]; $diagnostic = $groups[$name][0][6]
        $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'scripts/check-docs.ps1') -Root $fixture
        $actual = $LASTEXITCODE
        if ($actual -ne $expected -or ($diagnostic -ne '-' -and -not (($result -join "`n").Contains($diagnostic)))) {
            $failures++; Write-Output "FAIL $name (expected $expected, got $actual):"; Write-Output $result
        }
        else { Write-Output "PASS $name" }
    }
}
finally {
    # Remove only the uniquely named fixture directory created by this test run.
    $resolved = [IO.Path]::GetFullPath($testRoot)
    if ((Split-Path $resolved -Parent) -ne $tempParent -or (Split-Path $resolved -Leaf) -notmatch '^docs-check-[0-9a-f]{32}$') { throw 'Unsafe fixture cleanup path' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
Write-Output "Tests: $($groups.Count), failures: $failures"
if ($failures) { exit 1 }
exit 0
