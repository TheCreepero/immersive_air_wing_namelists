<#
.SYNOPSIS
    Pester unit and invariant tests for Hearts of Iron IV air wing namelist and localisation files.

.DESCRIPTION
    Checks are discovered from the repository: every common/units/names/iawn_<TAG>_names.txt gets
    the per-namelist checks and every localisation/english/iawn_<TAG>_l_english.yml gets the
    per-localisation checks, so adding a nation needs no change here.

    Never put a localisation token (a dollar-delimited name such as NR or NAME) in a PowerShell
    double-quoted string in this file: PowerShell expands it as a variable and silently eats it.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot 'AirWingNames.Helpers.ps1')

    $NamelistCases = @(Get-IawnNamelistFiles | ForEach-Object {
        @{ Name = $_.Name; Path = $_.FullName; Tag = (Get-IawnTagFromFileName -FileName $_.Name) }
    })
    $TagCases = @($NamelistCases | ForEach-Object { @{ Tag = $_.Tag } })
    $EnglishLocCases = @(Get-IawnEnglishLocFiles | ForEach-Object {
        $tagMatch = [regex]::Match($_.Name, '^iawn_(.+)_l_english\.yml$')
        @{ Name = $_.Name; Path = $_.FullName; Tag = $tagMatch.Groups[1].Value }
    })
    $ArchetypeCases = @($script:ExpectedArchetypes)
    $LanguageCases = @($script:OtherLanguages)
    $ScriptFileCases = @(Get-ChildItem -Path $script:NamelistDir -Filter '*.txt' | Where-Object { $_.Name -notlike '.*' })
    $LocFileCases = @(Get-AllLocFiles)
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'AirWingNames.Helpers.ps1')

    $script:NamelistFiles = @(Get-ChildItem -Path $script:NamelistDir -Filter '*.txt' | Where-Object { $_.Name -notlike '.*' })
    $script:LocFiles = @(Get-AllLocFiles)

    # Everything the English localisation defines, and everything the namelists reference.
    $script:EnglishLoc = @(Get-IawnEnglishLocFiles | ForEach-Object { Read-IawnLoc -Path $_.FullName })
    $script:EnglishKeys = @{}
    foreach ($lf in $script:EnglishLoc) {
        foreach ($e in $lf.Entries) { $script:EnglishKeys[$e.Key] = $e.Value }
    }

    $script:TemplateKeys = @{}
    $script:PatternKeys = @{}
    foreach ($nf in (Get-IawnNamelistFiles)) {
        $parsed = Read-IawnNamelist -Path $nf.FullName
        if ($parsed.Template) { $script:TemplateKeys[$parsed.Template] = $true }
        foreach ($a in $parsed.Archetypes.Values) {
            if ($a.GenericPattern) { $script:PatternKeys[$a.GenericPattern] = $true }
        }
    }
}

Describe 'Air Wing Namelists: Global Invariants' {
    It 'Finds air wing namelist files in common/units/names' {
        $script:NamelistFiles.Count | Should -BeGreaterThan 0
    }

    It 'Finds per-nation namelists named iawn_<TAG>_names.txt' {
        @(Get-IawnNamelistFiles).Count | Should -BeGreaterThan 0
    }

    It 'Finds localisation files in localisation/english' {
        @(Get-IawnEnglishLocFiles).Count | Should -BeGreaterThan 0
    }

    It 'Finds localisation files for every language folder' {
        $script:LocFiles.Count | Should -BeGreaterThan 0
    }
}

Describe 'Air Wing Namelists: File Invariants' {
    Context 'Script File: <_.Name>' -ForEach $ScriptFileCases {
        BeforeAll {
            $script:CurrentFile = $_
            $script:RawBytes = [System.IO.File]::ReadAllBytes($script:CurrentFile.FullName)
            $script:FileText = [System.IO.File]::ReadAllText($script:CurrentFile.FullName, [System.Text.Encoding]::UTF8)
            $script:CleanText = ($script:FileText -replace '(?m)#.*$', '')
        }

        It 'Must be saved as UTF-8 without BOM' {
            $hasBom = ($script:RawBytes.Length -ge 3 -and $script:RawBytes[0] -eq 0xEF -and $script:RawBytes[1] -eq 0xBB -and $script:RawBytes[2] -eq 0xBF)
            $hasBom | Should -BeFalse
        }

        It 'Must have strictly balanced curly braces' {
            $openB = ([regex]::Matches($script:CleanText, '\{')).Count
            $closeB = ([regex]::Matches($script:CleanText, '\}')).Count
            $openB | Should -Be $closeB
        }

        It 'Must have balanced double quotes' {
            $quoteCount = ([regex]::Matches($script:CleanText, '"')).Count
            ($quoteCount % 2) | Should -Be 0
        }

        It 'Must not contain empty generic blocks' {
            $emptyGeneric = [regex]::Matches($script:CleanText, 'generic\s*=\s*\{\s*\}')
            $emptyGeneric.Count | Should -Be 0
        }
    }

    Context 'Localisation File: <_.FullName>' -ForEach $LocFileCases {
        BeforeAll {
            $script:CurrentLocFile = $_
            $script:LocBytes = [System.IO.File]::ReadAllBytes($script:CurrentLocFile.FullName)
            $script:LocText = [System.IO.File]::ReadAllText($script:CurrentLocFile.FullName, [System.Text.Encoding]::UTF8)
            $script:LocLanguage = $script:CurrentLocFile.Directory.Name
        }

        It 'Must be saved as UTF-8 with BOM' {
            $hasBom = ($script:LocBytes.Length -ge 3 -and $script:LocBytes[0] -eq 0xEF -and $script:LocBytes[1] -eq 0xBB -and $script:LocBytes[2] -eq 0xBF)
            $hasBom | Should -BeTrue
        }

        It 'Must start with the l_<language>: header matching its folder' {
            $first = ($script:LocText.TrimStart([char]0xFEFF) -split '\r?\n') | Select-Object -First 1
            $first.TrimEnd() | Should -BeExactly ('l_' + $script:LocLanguage + ':')
        }
    }
}

Describe 'Air Wing Namelists: Namelist <Name>' -ForEach $NamelistCases {
    BeforeAll {
        $script:Doc = Read-IawnNamelist -Path $Path
    }

    It 'Filename follows iawn_<TAG>_names.txt with a 3-character upper-case tag' {
        $Tag | Should -MatchExactly '^[A-Z][A-Z0-9]{2}$'
    }

    It 'Defines exactly one root block and it is the tag from the filename' {
        $script:Doc.RootKeys.Count | Should -Be 1
        $script:Doc.RootKeys[0] | Should -BeExactly $Tag
    }

    It 'Defines all expected archetypes' {
        $missing = @($script:ExpectedArchetypes | Where-Object { -not $script:Doc.Archetypes.Contains($_) })
        $missing | Should -BeNullOrEmpty
    }

    It 'Has no keys in the tag block except air_wing_names_template and the expected archetypes' {
        $unexpected = @(foreach ($m in $script:Doc.Members) {
            if ($null -eq $m.Key) {
                'loose value: ' + $m.Scalar
            }
            elseif ($m.Key -cne 'air_wing_names_template' -and $m.Key -cnotin $script:ExpectedArchetypes) {
                $m.Key
            }
        })
        $unexpected | Should -BeNullOrEmpty
    }

    It 'Defines each key in the tag block once' {
        $dups = @($script:Doc.Members | Where-Object { $null -ne $_.Key } | Group-Object -Property Key |
            Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
        $dups | Should -BeNullOrEmpty
    }

    It 'Defines air_wing_names_template and the key exists in the English localisation' {
        $script:Doc.Template | Should -Not -BeNullOrEmpty
        $script:EnglishKeys.ContainsKey($script:Doc.Template) | Should -BeTrue -Because ('missing localisation key ' + $script:Doc.Template)
    }

    It 'References only generic_pattern keys that exist in the English localisation' {
        $missing = @(foreach ($a in $script:Doc.Archetypes.Values) {
            if (-not $a.GenericPattern -or -not $script:EnglishKeys.ContainsKey($a.GenericPattern)) {
                $a.Name + ' -> ' + $a.GenericPattern
            }
        })
        $missing | Should -BeNullOrEmpty
    }

    It 'Has no unique name shared between two archetype pools' {
        $seen = @{}
        foreach ($a in $script:Doc.Archetypes.Values) {
            foreach ($u in ($a.Unique | Select-Object -Unique)) {
                if (-not $seen.ContainsKey($u)) { $seen[$u] = [System.Collections.Generic.List[string]]::new() }
                $seen[$u].Add($a.Name)
            }
        }
        $shared = @($seen.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } |
            ForEach-Object { '"' + $_.Key + '" in ' + ($_.Value -join ', ') })
        $shared | Should -BeNullOrEmpty
    }

    Context 'Archetype: <_>' -ForEach $ArchetypeCases {
        BeforeAll {
            $script:Arch = $script:Doc.Archetypes[$_]
        }

        It 'Archetype is defined in the tag block' {
            $script:Arch | Should -Not -BeNullOrEmpty
        }

        It 'Archetype has generic_pattern referencing a valid localisation key' {
            $script:Arch | Should -Not -BeNullOrEmpty
            $script:Arch.GenericPattern | Should -Not -BeNullOrEmpty
            $script:EnglishKeys.ContainsKey($script:Arch.GenericPattern) | Should -BeTrue
        }

        It 'Archetype contains non-empty generic list' {
            $script:Arch | Should -Not -BeNullOrEmpty
            $script:Arch.Generic.Count | Should -BeGreaterThan 0
        }

        It 'Archetype unique names list contains no duplicates within its pool' {
            $script:Arch | Should -Not -BeNullOrEmpty
            $dups = @($script:Arch.Unique | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
            $dups | Should -BeNullOrEmpty
        }

        It 'Archetype prefix, when non-empty, ends with a space' {
            $script:Arch | Should -Not -BeNullOrEmpty
            if ($script:Arch.HasPrefix -and $script:Arch.Prefix.Length -gt 0) {
                $script:Arch.Prefix.EndsWith(' ') | Should -BeTrue
            }
        }
    }
}

Describe 'Air Wing Namelists: English Localisation <Name>' -ForEach $EnglishLocCases {
    BeforeAll {
        $script:Loc = Read-IawnLoc -Path $Path
    }

    It 'Defines at least one entry' {
        $script:Loc.Entries.Count | Should -BeGreaterThan 0
    }

    It 'Contains only the header, comments and KEY: "value" entries' {
        $script:Loc.BadLines | Should -BeNullOrEmpty
    }

    It 'Uses only keys that start with IAWN_' {
        $bad = @($script:Loc.Entries | Where-Object { -not $_.Key.StartsWith('IAWN_', [System.StringComparison]::Ordinal) } | ForEach-Object { $_.Key })
        $bad | Should -BeNullOrEmpty
    }

    It 'Uses only keys in the IAWN_<TAG>_ namespace of its own tag' {
        $prefix = 'IAWN_' + $Tag + '_'
        $bad = @($script:Loc.Entries | Where-Object { -not $_.Key.StartsWith($prefix, [System.StringComparison]::Ordinal) } | ForEach-Object { $_.Key })
        $bad | Should -BeNullOrEmpty
    }

    It 'Contains only valid tokens (NR, NAME, NUMBER, TYPE) and no stray dollar signs' {
        $tokenPattern = '\$(' + ($script:ValidLocTokens -join '|') + ')\$'
        $bad = @(foreach ($e in $script:Loc.Entries) {
            $residue = [regex]::Replace($e.Value, $tokenPattern, '')
            if ($residue.Contains('$')) { $e.Key + ' = "' + $e.Value + '"' }
        })
        $bad | Should -BeNullOrEmpty
    }

    It 'Has NUMBER in every key used as an air_wing_names_template' {
        $bad = @(foreach ($e in $script:Loc.Entries) {
            if ($script:TemplateKeys.ContainsKey($e.Key) -and -not $e.Value.Contains('$NUMBER$')) { $e.Key + ' = "' + $e.Value + '"' }
        })
        $bad | Should -BeNullOrEmpty
    }

    It 'Has NR in every key used as a generic_pattern' {
        $bad = @(foreach ($e in $script:Loc.Entries) {
            if ($script:PatternKeys.ContainsKey($e.Key) -and -not $e.Value.Contains('$NR$')) { $e.Key + ' = "' + $e.Value + '"' }
        })
        $bad | Should -BeNullOrEmpty
    }

    It 'Has every key referenced by a namelist' {
        $unused = @($script:Loc.Entries | Where-Object {
            -not $script:TemplateKeys.ContainsKey($_.Key) -and -not $script:PatternKeys.ContainsKey($_.Key)
        } | ForEach-Object { $_.Key })
        $unused | Should -BeNullOrEmpty
    }
}

Describe 'Air Wing Namelists: Localisation Key Uniqueness' {
    It 'Defines no key twice within any language' {
        $dups = @(foreach ($lang in (@('english') + $script:OtherLanguages)) {
            $dir = Join-Path $script:LocRoot $lang
            if (-not (Test-Path $dir)) { continue }
            $keys = @(Get-ChildItem -Path $dir -Filter 'iawn_*.yml' -File | ForEach-Object { (Read-IawnLoc -Path $_.FullName).Entries } | ForEach-Object { $_.Key })
            $keys | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $lang + ': ' + $_.Name }
        })
        $dups | Should -BeNullOrEmpty
    }
}

Describe 'Air Wing Namelists: Localisation in All Languages (<_>)' -ForEach $LanguageCases {
    BeforeAll {
        $script:Lang = $_
        $script:LangDir = Join-Path $script:LocRoot $script:Lang
        $script:LangSuffix = '_l_' + $script:Lang + '.yml'
    }

    It 'Has a counterpart for every English file, identical apart from the header line' {
        $problems = @(foreach ($src in (Get-IawnEnglishLocFiles)) {
            $targetName = $src.Name -replace '_l_english\.yml$', $script:LangSuffix
            $target = Join-Path $script:LangDir $targetName
            if (-not (Test-Path $target)) { $targetName + ': missing (run build.ps1 -SyncLoc)'; continue }

            $a = Split-LocBytes -Bytes ([System.IO.File]::ReadAllBytes($src.FullName))
            $b = Split-LocBytes -Bytes ([System.IO.File]::ReadAllBytes($target))
            if (-not $b.HasBom) { $targetName + ': missing BOM'; continue }
            if ($b.Header -cne ('l_' + $script:Lang + ':')) { $targetName + ': wrong header ' + $b.Header; continue }
            if ($a.Eol -ne $b.Eol) { $targetName + ': line endings differ from the English file'; continue }
            if (-not (Test-ByteArrayEqual -A $a.Body -B $b.Body)) { $targetName + ': content differs from the English file (run build.ps1 -SyncLoc)' }
        })
        $problems | Should -BeNullOrEmpty
    }

    It 'Has no orphan generated files without an English source' {
        $orphans = @()
        if (Test-Path $script:LangDir) {
            $suffixPattern = [regex]::Escape($script:LangSuffix) + '$'
            $orphans = @(Get-ChildItem -Path $script:LangDir -Filter ('iawn_*' + $script:LangSuffix) -File | Where-Object {
                $englishName = $_.Name -replace $suffixPattern, '_l_english.yml'
                -not (Test-Path (Join-Path $script:EnglishLocDir $englishName))
            } | ForEach-Object { $_.Name })
        }
        $orphans | Should -BeNullOrEmpty
    }
}

Describe 'Air Wing Namelists: Documentation Cross-Reference' {
    BeforeAll {
        $guidelines = Join-Path $script:RepoRoot 'WORKSHOP_DESCRIPTION_GUIDELINES.md'
        $text = [System.IO.File]::ReadAllText($guidelines, [System.Text.Encoding]::UTF8)
        $section = [regex]::Match($text, '(?ms)^##\s+Repository Cross-Reference.*?(?=^##\s|\z)')
        $script:TableRows = @()
        if ($section.Success) {
            $script:TableRows = @($section.Value -split '\r?\n' | Where-Object { $_.TrimStart().StartsWith('|') })
        }
    }

    It 'Finds the Repository Cross-Reference table' {
        $script:TableRows.Count | Should -BeGreaterThan 0
    }

    Context 'Nation <Tag>' -ForEach $TagCases {
        It 'Appears in the Repository Cross-Reference table with its file and tag' {
            $fileCell = '`iawn_' + $Tag + '_names.txt`'
            $tagCell = '`' + $Tag + '`'
            $rows = @($script:TableRows | Where-Object { $_.Contains($fileCell) -and $_.Contains($tagCell) })
            $rows.Count | Should -BeGreaterThan 0
        }
    }
}
