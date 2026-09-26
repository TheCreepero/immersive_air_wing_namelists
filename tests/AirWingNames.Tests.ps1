<#
.SYNOPSIS
    Pester unit and invariant tests for Hearts of Iron IV air wing namelist and localisation files.
#>

BeforeAll {
    $script:RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    $script:NamelistDir = Join-Path $script:RepoRoot "common\units\names"
    $script:LocDir = Join-Path $script:RepoRoot "localisation\english"

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

    $script:NamelistFiles = @(Get-ChildItem -Path $script:NamelistDir -Filter "*.txt" | Where-Object { $_.Name -notlike ".*" })
    $script:LocFiles = @(Get-ChildItem -Path $script:LocDir -Filter "*.yml" | Where-Object { $_.Name -notlike ".*" })
}

Describe "Air Wing Namelists: Global Invariants" {
    It "Finds air wing namelist files in common/units/names" {
        $script:NamelistFiles.Count | Should -BeGreaterThan 0
    }

    It "Finds localisation files in localisation/english" {
        $script:LocFiles.Count | Should -BeGreaterThan 0
    }
}

Describe "Air Wing Namelists: File Invariants" {
    Context "Script File: <_.Name>" -ForEach (@(Get-ChildItem -Path (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "common\units\names") -Filter "*.txt" | Where-Object { $_.Name -notlike ".*" })) {
        BeforeAll {
            $script:CurrentFile = $_
            $script:RawBytes = [System.IO.File]::ReadAllBytes($script:CurrentFile.FullName)
            $script:FileText = [System.IO.File]::ReadAllText($script:CurrentFile.FullName, [System.Text.Encoding]::UTF8)
            $script:CleanText = ($script:FileText -replace '(?m)#.*$', '')
        }

        It "Must be saved as UTF-8 without BOM" {
            $hasBom = ($script:RawBytes.Length -ge 3 -and $script:RawBytes[0] -eq 0xEF -and $script:RawBytes[1] -eq 0xBB -and $script:RawBytes[2] -eq 0xBF)
            $hasBom | Should -BeFalse
        }

        It "Must have strictly balanced curly braces" {
            $openB = ([regex]::Matches($script:CleanText, '\{')).Count
            $closeB = ([regex]::Matches($script:CleanText, '\}')).Count
            $openB | Should -Be $closeB
        }

        It "Must have balanced double quotes" {
            $quoteCount = ([regex]::Matches($script:CleanText, '"')).Count
            ($quoteCount % 2) | Should -Be 0
        }

        It "Must not contain empty generic blocks" {
            $emptyGeneric = [regex]::Matches($script:CleanText, 'generic\s*=\s*\{\s*\}')
            $emptyGeneric.Count | Should -Be 0
        }
    }

    Context "Localisation File: <_.Name>" -ForEach (@(Get-ChildItem -Path (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "localisation\english") -Filter "*.yml" | Where-Object { $_.Name -notlike ".*" })) {
        BeforeAll {
            $script:CurrentLocFile = $_
            $script:LocBytes = [System.IO.File]::ReadAllBytes($script:CurrentLocFile.FullName)
            $script:LocText = [System.IO.File]::ReadAllText($script:CurrentLocFile.FullName, [System.Text.Encoding]::UTF8)
        }

        It "Must be saved as UTF-8 with BOM" {
            $hasBom = ($script:LocBytes.Length -ge 3 -and $script:LocBytes[0] -eq 0xEF -and $script:LocBytes[1] -eq 0xBB -and $script:LocBytes[2] -eq 0xBF)
            $hasBom | Should -BeTrue
        }

        It "Must start with l_english: header" {
            $script:LocText | Should -Match '(?m)^l_english:\s*$'
        }
    }
}

Describe "Air Wing Namelists: FIN Archetype Coverage & Localisation" {
    BeforeAll {
        $finFile = Join-Path $script:NamelistDir "iawn_FIN_names.txt"
        $script:FinRaw = [System.IO.File]::ReadAllText($finFile, [System.Text.Encoding]::UTF8)
        $script:FinClean = ($script:FinRaw -replace '(?m)#.*$', '')

        $allLoc = ""
        foreach ($lf in $script:LocFiles) {
            $allLoc += "`n" + [System.IO.File]::ReadAllText($lf.FullName, [System.Text.Encoding]::UTF8)
        }
        $script:AllLocText = $allLoc
        function Get-ArchetypeBlock {
            param([string]$Text, [string]$ArchetypeName)
            $m = [regex]::Match($Text, "(?m)^\s*$([regex]::Escape($ArchetypeName))\s*=\s*\{")
            if (-not $m.Success) { return $null }
            $start = $m.Index + $m.Length
            $depth = 1
            for ($i = $start; $i -lt $Text.Length; $i++) {
                if ($Text[$i] -eq '{') { $depth++ }
                elseif ($Text[$i] -eq '}') {
                    $depth--
                    if ($depth -eq 0) {
                        return $Text.Substring($start, $i - $start)
                    }
                }
            }
            return $null
        }

        $script:GetArchetypeBlock = ${function:Get-ArchetypeBlock}
    }

    It "Country tag FIN is defined at root" {
        $script:FinClean | Should -Match '(?m)^\s*FIN\s*=\s*\{'
    }

    It "Defines air_wing_names_template and key exists in localisation" {
        $templateMatch = [regex]::Match($script:FinClean, 'air_wing_names_template\s*=\s*([A-Za-z0-9_]+)')
        $templateMatch.Success | Should -BeTrue
        $key = $templateMatch.Groups[1].Value
        $script:AllLocText | Should -Match "(?m)^\s+${key}:"
    }

    Context "Archetype: <_>" -ForEach @(
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
    ) {
        BeforeAll {
            $script:Arch = $_
            $script:ArchContent = & $script:GetArchetypeBlock -Text $script:FinClean -ArchetypeName $script:Arch
        }

        It "Archetype is defined in FIN block" {
            $script:ArchContent | Should -Not -BeNullOrEmpty
        }

        It "Archetype has generic_pattern referencing a valid localisation key" {
            $script:ArchContent | Should -Not -BeNullOrEmpty
            $gpMatch = [regex]::Match($script:ArchContent, 'generic_pattern\s*=\s*([A-Za-z0-9_]+)')
            $gpMatch.Success | Should -BeTrue
            $locKey = $gpMatch.Groups[1].Value
            $script:AllLocText | Should -Match "(?m)^\s+${locKey}:"
        }

        It "Archetype contains non-empty generic list" {
            $script:ArchContent | Should -Not -BeNullOrEmpty
            $gMatch = [regex]::Match($script:ArchContent, '(?s)generic\s*=\s*\{(?<items>.*?)\}')
            $gMatch.Success | Should -BeTrue
            $items = [regex]::Matches($gMatch.Groups['items'].Value, '"([^"]+)"')
            $items.Count | Should -BeGreaterThan 0
        }

        It "Archetype unique names list contains no duplicates within its pool" {
            $script:ArchContent | Should -Not -BeNullOrEmpty
            $uMatch = [regex]::Match($script:ArchContent, '(?s)unique\s*=\s*\{(?<items>.*?)\}')
            if ($uMatch.Success) {
                $names = @([regex]::Matches($uMatch.Groups['items'].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
                $dups = @($names | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
                $dups | Should -BeNullOrEmpty
            }
        }
    }
}
