<#
.SYNOPSIS
    Shared parsing helpers and constants for the IAWN Pester suites.
    Dot-source this file from both BeforeDiscovery and BeforeAll in a test file.

.NOTES
    Never put a localisation token (a dollar-delimited name such as NR or NAME) inside a
    PowerShell double-quoted string: PowerShell would expand it as a variable and silently
    eat it. Use single quotes in this file.
#>

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:NamelistDir = Join-Path $script:RepoRoot 'common\units\names'
$script:LocRoot = Join-Path $script:RepoRoot 'localisation'
$script:EnglishLocDir = Join-Path $script:LocRoot 'english'

# Vanilla HOI4 1.19 localisation folders other than english. The game does not fall back to
# English for a missing key, so every one of these needs the mod's keys.
$script:OtherLanguages = @(
    'braz_por',
    'french',
    'german',
    'japanese',
    'korean',
    'polish',
    'russian',
    'simp_chinese',
    'spanish'
)

# Every air wing archetype a national list must define (see CLAUDE.md section 2).
$script:ExpectedArchetypes = @(
    'small_plane_airframe',
    'small_plane_cas_airframe',
    'small_plane_naval_bomber_airframe',
    'small_plane_suicide_airframe',
    'cv_small_plane_airframe',
    'cv_small_plane_cas_airframe',
    'cv_small_plane_naval_bomber_airframe',
    'cv_small_plane_suicide_airframe',
    'medium_plane_fighter_airframe',
    'medium_plane_airframe',
    'medium_plane_scout_plane_airframe',
    'large_plane_airframe',
    'large_plane_maritime_patrol_plane_airframe',
    'transport_plane_equipment',
    'rocket_interceptor_equipment',
    'jet_fighter_equipment',
    'jet_tac_bomber_equipment',
    'jet_strat_bomber_equipment'
)

# The only dollar-delimited tokens the engine understands in air wing strings.
$script:ValidLocTokens = @('NR', 'NAME', 'NUMBER', 'TYPE')

function Get-PdxEntries {
    <#
    Splits Clausewitz script text into its depth-0 entries. Comments are ignored (a hash sign
    inside a quoted string is kept). Each entry has:
      Key     the key, or $null for a loose value such as a quoted name in a pool
      Scalar  the scalar value (quotes removed), or $null for a block
      Body    the text between the braces of a block, or $null for a scalar
    #>
    param([string]$Text)

    $tokens = [regex]::Matches($Text, '#[^\r\n]*|"[^"]*"|[{}=]|[^\s{}="#]+')
    $entries = [System.Collections.Generic.List[object]]::new()
    $i = 0
    $n = $tokens.Count

    while ($i -lt $n) {
        $tok = $tokens[$i].Value
        if ($tok.StartsWith('#')) { $i++; continue }
        if ($tok -eq '{' -or $tok -eq '}' -or $tok -eq '=') { $i++; continue }

        $word = $tok
        if ($word.Length -ge 2 -and $word.StartsWith('"')) { $word = $word.Substring(1, $word.Length - 2) }
        $i++

        # Find the next significant token (skip comments).
        $j = $i
        while ($j -lt $n -and $tokens[$j].Value.StartsWith('#')) { $j++ }

        if ($j -lt $n -and $tokens[$j].Value -eq '=') {
            $j++
            while ($j -lt $n -and $tokens[$j].Value.StartsWith('#')) { $j++ }
            if ($j -ge $n) {
                $entries.Add([pscustomobject]@{ Key = $word; Scalar = $null; Body = '' })
                $i = $j
            }
            elseif ($tokens[$j].Value -eq '{') {
                $open = $tokens[$j]
                $depth = 1
                $k = $j + 1
                while ($k -lt $n -and $depth -gt 0) {
                    $v = $tokens[$k].Value
                    if ($v -eq '{') { $depth++ } elseif ($v -eq '}') { $depth-- }
                    $k++
                }
                if ($depth -eq 0) {
                    $close = $tokens[$k - 1]
                    $body = $Text.Substring($open.Index + 1, $close.Index - $open.Index - 1)
                } else {
                    $body = $Text.Substring($open.Index + 1)
                }
                $entries.Add([pscustomobject]@{ Key = $word; Scalar = $null; Body = $body })
                $i = $k
            }
            else {
                $val = $tokens[$j].Value
                if ($val.Length -ge 2 -and $val.StartsWith('"')) { $val = $val.Substring(1, $val.Length - 2) }
                $entries.Add([pscustomobject]@{ Key = $word; Scalar = $val; Body = $null })
                $i = $j + 1
            }
        }
        else {
            $entries.Add([pscustomobject]@{ Key = $null; Scalar = $word; Body = $null })
        }
    }

    return $entries.ToArray()
}

function Get-ArchetypeBlock {
    <# Returns the body text of the named depth-0 block in $Text, or $null when it is not there. #>
    param([string]$Text, [string]$ArchetypeName)

    $hit = @(Get-PdxEntries -Text $Text | Where-Object { $null -ne $_.Body -and $_.Key -ceq $ArchetypeName }) | Select-Object -First 1
    if ($null -eq $hit) { return $null }
    return $hit.Body
}

function Get-PdxStrings {
    <# Returns the quoted strings of a pool body such as a generic or unique block. #>
    param([string]$Body)

    if ([string]::IsNullOrEmpty($Body)) { return @() }
    return @(foreach ($e in (Get-PdxEntries -Text $Body)) {
        if ($null -eq $e.Key -and $null -ne $e.Scalar) { $e.Scalar }
    })
}

function Get-IawnNamelistFiles {
    return @(Get-ChildItem -Path $script:NamelistDir -Filter 'iawn_*_names.txt' -File)
}

function Get-IawnTagFromFileName {
    param([string]$FileName)
    $m = [regex]::Match($FileName, '^iawn_(.+)_names\.txt$')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Read-IawnNamelist {
    <# Parses one iawn_<TAG>_names.txt into a structure the tests can interrogate. #>
    param([string]$Path)

    $text = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    $roots = @(Get-PdxEntries -Text $text)
    $rootKeys = @($roots | ForEach-Object { $_.Key })

    $fileTag = Get-IawnTagFromFileName -FileName ([System.IO.Path]::GetFileName($Path))
    $tagEntry = @($roots | Where-Object { $null -ne $_.Body -and $_.Key -ceq $fileTag }) | Select-Object -First 1
    if ($null -eq $tagEntry) {
        $tagEntry = @($roots | Where-Object { $null -ne $_.Body }) | Select-Object -First 1
    }

    $members = @()
    $template = $null
    $archetypes = [ordered]@{}
    if ($null -ne $tagEntry) {
        $members = @(Get-PdxEntries -Text $tagEntry.Body)
        foreach ($m in $members) {
            if ($m.Key -ceq 'air_wing_names_template') { $template = $m.Scalar }
            elseif ($null -ne $m.Body -and $m.Key -cin $script:ExpectedArchetypes) {
                $inner = @(Get-PdxEntries -Text $m.Body)
                $prefix = @($inner | Where-Object { $_.Key -ceq 'prefix' }) | Select-Object -First 1
                $gp = @($inner | Where-Object { $_.Key -ceq 'generic_pattern' }) | Select-Object -First 1
                $gen = @($inner | Where-Object { $_.Key -ceq 'generic' }) | Select-Object -First 1
                $uni = @($inner | Where-Object { $_.Key -ceq 'unique' }) | Select-Object -First 1
                $archetypes[$m.Key] = [pscustomobject]@{
                    Name           = $m.Key
                    HasPrefix      = ($null -ne $prefix)
                    Prefix         = if ($null -ne $prefix) { $prefix.Scalar } else { $null }
                    GenericPattern = if ($null -ne $gp) { $gp.Scalar } else { $null }
                    Generic        = if ($null -ne $gen) { @(Get-PdxStrings -Body $gen.Body) } else { @() }
                    Unique         = if ($null -ne $uni) { @(Get-PdxStrings -Body $uni.Body) } else { @() }
                }
            }
        }
    }

    return [pscustomobject]@{
        Path       = $Path
        FileTag    = $fileTag
        RootKeys   = $rootKeys
        HasTagBody = ($null -ne $tagEntry)
        Members    = $members
        Template   = $template
        Archetypes = $archetypes
    }
}

function Read-IawnLoc {
    <# Parses one localisation .yml (BOM state, header line, KEY: "value" entries). #>
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $offset = if ($hasBom) { 3 } else { 0 }
    $text = [System.Text.UTF8Encoding]::new($false).GetString($bytes, $offset, $bytes.Length - $offset)

    $header = $null
    $entries = [System.Collections.Generic.List[object]]::new()
    $bad = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($text -split '\r?\n')) {
        if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
        if ($null -eq $header) { $header = $line.TrimEnd(); continue }
        $m = [regex]::Match($line, '^ ([A-Za-z0-9_.\-]+):(\d*) "(.*)"\s*(#.*)?$')
        if ($m.Success) {
            $entries.Add([pscustomobject]@{ Key = $m.Groups[1].Value; Value = $m.Groups[3].Value })
        } else {
            $bad.Add($line)
        }
    }

    return [pscustomobject]@{
        Path     = $Path
        Name     = [System.IO.Path]::GetFileName($Path)
        Language = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($Path))
        HasBom   = $hasBom
        Header   = $header
        Entries  = $entries.ToArray()
        BadLines = $bad.ToArray()
    }
}

function Split-LocBytes {
    <#
    Splits a localisation file into its header line and everything after the first line feed.
    Returns the header text, its line ending (CRLF or LF), the BOM flag and the body bytes.
    #>
    param([byte[]]$Bytes)

    $hasBom = ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF)
    $start = if ($hasBom) { 3 } else { 0 }
    $nl = [System.Array]::IndexOf($Bytes, [byte]10, $start)
    if ($nl -lt 0) {
        return [pscustomobject]@{ HasBom = $hasBom; Header = [System.Text.Encoding]::UTF8.GetString($Bytes, $start, $Bytes.Length - $start); Eol = 'none'; Body = [byte[]]@() }
    }
    $headerEnd = $nl
    $eol = 'LF'
    if ($nl -gt $start -and $Bytes[$nl - 1] -eq 13) { $headerEnd = $nl - 1; $eol = 'CRLF' }
    $header = [System.Text.Encoding]::UTF8.GetString($Bytes, $start, $headerEnd - $start)
    $body = New-Object 'byte[]' ($Bytes.Length - $nl - 1)
    [System.Array]::Copy($Bytes, $nl + 1, $body, 0, $body.Length)
    return [pscustomobject]@{ HasBom = $hasBom; Header = $header; Eol = $eol; Body = $body }
}

function Test-ByteArrayEqual {
    param([byte[]]$A, [byte[]]$B)
    if ($A.Length -ne $B.Length) { return $false }
    for ($i = 0; $i -lt $A.Length; $i++) {
        if ($A[$i] -ne $B[$i]) { return $false }
    }
    return $true
}

function Get-IawnEnglishLocFiles {
    if (-not (Test-Path $script:EnglishLocDir)) { return @() }
    return @(Get-ChildItem -Path $script:EnglishLocDir -Filter 'iawn_*_l_english.yml' -File)
}

function Get-AllLocFiles {
    if (-not (Test-Path $script:LocRoot)) { return @() }
    return @(Get-ChildItem -Path $script:LocRoot -Recurse -Filter '*.yml' -File | Where-Object { $_.Name -notlike '.*' })
}
