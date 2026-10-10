BeforeAll {
    $script:RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
    $script:BuildScriptPath = Join-Path $script:RepoRoot "build.ps1"
    $script:BuildContent = [System.IO.File]::ReadAllText($script:BuildScriptPath, [System.Text.Encoding]::UTF8)

    $metaFuncMatch = [regex]::Match($script:BuildContent, '(?s)(function Get-ModMetadata\s*\{.*?\n\})')
    $launcherFuncMatch = [regex]::Match($script:BuildContent, '(?s)(function New-LauncherModContent\s*\{.*?\n\})')

    if ($metaFuncMatch.Success) {
        . ([ScriptBlock]::Create($metaFuncMatch.Groups[1].Value))
    }
    if ($launcherFuncMatch.Success) {
        . ([ScriptBlock]::Create($launcherFuncMatch.Groups[1].Value))
    }

    # Sync-Localisation reports through build.ps1's Write-* helpers; stub them for the unit tests.
    function Write-Ok   { param([string]$msg) }
    function Write-Info { param([string]$msg) }
    $syncFuncMatch = [regex]::Match($script:BuildContent, '(?s)(function Sync-Localisation\s*\{.*?\n\})')
    if ($syncFuncMatch.Success) {
        . ([ScriptBlock]::Create($syncFuncMatch.Groups[1].Value))
    }

    . (Join-Path $PSScriptRoot 'AirWingNames.Helpers.ps1')
}

Describe "build.ps1 Helper: Get-ModMetadata" {
    It "Parses mod metadata correctly from descriptor file" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $sampleLines = @(
                'version="1.0.0"',
                'tags={',
                "`t`"Historical`"",
                "`t`"Military`"",
                '}',
                'name="Immersive Air Wing Namelists"',
                'supported_version="1.19.*"',
                'remote_file_id="1234567890"'
            )
            $sampleDescriptor = $sampleLines -join "`r`n"
            [System.IO.File]::WriteAllText($tempFile, $sampleDescriptor, [System.Text.Encoding]::UTF8)

            $meta = Get-ModMetadata -Path $tempFile
            $meta.Version | Should -Be "1.0.0"
            $meta.Name | Should -Be "Immersive Air Wing Namelists"
            $meta.SupportedVersion | Should -Be "1.19.*"
            $meta.RemoteFileId | Should -Be "1234567890"
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item -Force $tempFile }
        }
    }
}

Describe "build.ps1 Helper: New-LauncherModContent" {
    It "Normalizes backslashes to forward slashes in target mod path" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $sampleLines = @(
                'version="1.0"',
                'name="Immersive Air Wing Namelists"',
                'supported_version="1.19.*"'
            )
            $sampleDescriptor = $sampleLines -join "`r`n"
            [System.IO.File]::WriteAllText($tempFile, $sampleDescriptor, [System.Text.Encoding]::UTF8)

            $result = New-LauncherModContent -DescriptorPath $tempFile -TargetModPath "C:\Games\Hearts of Iron IV\mod\immersive_air_wing_namelists"
            $result | Should -Match 'path="C:/Games/Hearts of Iron IV/mod/immersive_air_wing_namelists"'
            $result | Should -Not -Match '\\\\'
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item -Force $tempFile }
        }
    }
}

Describe "build.ps1 Packaging & Staging Exclusions" {
    It "Build script must exclude tests directory from packages and deployment" {
        $script:BuildContent | Should -Match "excludeDirs\s*=\s*@\([^)]*['`"]tests['`"]"
    }

    It "Build script must exclude wiki directory from packages and deployment" {
        $script:BuildContent | Should -Match "excludeDirs\s*=\s*@\([^)]*['`"]wiki['`"]"
    }

    It "Build script must exclude .git and dev tools from packaging" {
        $script:BuildContent | Should -Match "excludeDirs\s*=\s*@\([^)]*['`"]\.git['`"]"
        $script:BuildContent | Should -Match "excludeDirs\s*=\s*@\([^)]*['`"]\.github['`"]"
    }
}

Describe "build.ps1 Packaging Includes Localisation" {
    It "Build script must not exclude the localisation directory from packages and deployment" {
        $script:BuildContent | Should -Not -Match "excludeDirs\s*=\s*@\([^)]*['`"]localisation['`"]"
    }

    It "Build script must not exclude yml files from packages and deployment" {
        $script:BuildContent | Should -Not -Match "excludeFiles\s*=\s*@\([^)]*yml"
    }
}

Describe "build.ps1 Switch: -SyncLoc" {
    BeforeAll {
        $script:Utf8 = [System.Text.UTF8Encoding]::new($false)
        $script:Bom = [byte[]](0xEF, 0xBB, 0xBF)

        function script:Write-LocFile {
            param([string]$Path, [string]$Text)
            $dir = [System.IO.Path]::GetDirectoryName($Path)
            if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            [System.IO.File]::WriteAllBytes($Path, ($script:Bom + $script:Utf8.GetBytes($Text)))
        }

        # Single-quoted on purpose: the tokens must reach the file untouched.
        $script:Body = ' IAWN_XYZ_FALLBACK: "$NUMBER$. Testilaivue"' + "`n" + ' IAWN_XYZ_GENERIC: "$NAME$ $NR$"' + "`n"
    }

    It "Declares the -SyncLoc switch in its own parameter set" {
        $script:BuildContent | Should -Match "ParameterSetName\s*=\s*'SyncLoc'\)\]\s*\[switch\]\`$SyncLoc"
    }

    It "Lists exactly the vanilla non-English localisation languages" {
        $m = [regex]::Match($script:BuildContent, '\$LocLanguages\s*=\s*@\(([^)]*)\)')
        $m.Success | Should -BeTrue
        $langs = @([regex]::Matches($m.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
        $langs.Count | Should -Be 9
        @($langs | Sort-Object) | Should -Be @($script:OtherLanguages | Sort-Object)
    }

    It "Writes one file per language with only the header line changed, keeping BOM and tokens" {
        $locRoot = Join-Path $TestDrive 'loc1'
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)

        Sync-Localisation -LocRoot $locRoot -Languages $script:OtherLanguages

        foreach ($lang in $script:OtherLanguages) {
            $target = Join-Path $locRoot ($lang + '\iawn_XYZ_l_' + $lang + '.yml')
            Test-Path $target | Should -BeTrue
            $bytes = [System.IO.File]::ReadAllBytes($target)
            $bytes[0] | Should -Be 0xEF
            $bytes[1] | Should -Be 0xBB
            $bytes[2] | Should -Be 0xBF
            $expected = $script:Bom + $script:Utf8.GetBytes('l_' + $lang + ':' + "`n" + $script:Body)
            Test-ByteArrayEqual -A $bytes -B $expected | Should -BeTrue
            $script:Utf8.GetString($bytes, 3, $bytes.Length - 3) | Should -Match ([regex]::Escape('$NUMBER$. Testilaivue'))
        }
    }

    It "Keeps CRLF line endings and non-ASCII text of the English source" {
        $locRoot = Join-Path $TestDrive 'loc2'
        $text = 'l_english:' + "`r`n" + ' IAWN_XYZ_FALLBACK: "$NUMBER$. H' + [char]0x00E4 + 'vitt' + [char]0x00E4 + 'j' + [char]0x00E4 + '"' + "`r`n"
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text $text

        Sync-Localisation -LocRoot $locRoot -Languages @('german')

        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $locRoot 'german\iawn_XYZ_l_german.yml'))
        $expected = $script:Bom + $script:Utf8.GetBytes($text.Replace('l_english:', 'l_german:'))
        Test-ByteArrayEqual -A $bytes -B $expected | Should -BeTrue
    }

    It "Is idempotent: a second run changes no file" {
        $locRoot = Join-Path $TestDrive 'loc3'
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)

        Sync-Localisation -LocRoot $locRoot -Languages $script:OtherLanguages
        $before = @(Get-ChildItem -Path $locRoot -Recurse -File | Sort-Object FullName | ForEach-Object {
            $_.FullName + '|' + $_.LastWriteTimeUtc.Ticks + '|' + $_.Length
        })
        Start-Sleep -Milliseconds 50
        Sync-Localisation -LocRoot $locRoot -Languages $script:OtherLanguages
        $after = @(Get-ChildItem -Path $locRoot -Recurse -File | Sort-Object FullName | ForEach-Object {
            $_.FullName + '|' + $_.LastWriteTimeUtc.Ticks + '|' + $_.Length
        })

        $after | Should -Be $before
    }

    It "Rewrites a counterpart that drifted from the English source" {
        $locRoot = Join-Path $TestDrive 'loc4'
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)
        Write-LocFile -Path (Join-Path $locRoot 'french\iawn_XYZ_l_french.yml') -Text ('l_french:' + "`n" + ' IAWN_XYZ_FALLBACK: "stale"' + "`n")

        Sync-Localisation -LocRoot $locRoot -Languages @('french')

        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $locRoot 'french\iawn_XYZ_l_french.yml'))
        Test-ByteArrayEqual -A $bytes -B ($script:Bom + $script:Utf8.GetBytes('l_french:' + "`n" + $script:Body)) | Should -BeTrue
    }

    It "Removes stale generated files whose English source is gone and leaves other files alone" {
        $locRoot = Join-Path $TestDrive 'loc5'
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)
        Write-LocFile -Path (Join-Path $locRoot 'german\iawn_OLD_l_german.yml') -Text ('l_german:' + "`n" + ' IAWN_OLD_X: "x"' + "`n")
        Write-LocFile -Path (Join-Path $locRoot 'german\other_mod_l_german.yml') -Text ('l_german:' + "`n" + ' OTHER_X: "x"' + "`n")

        Sync-Localisation -LocRoot $locRoot -Languages @('german')

        Test-Path (Join-Path $locRoot 'german\iawn_OLD_l_german.yml') | Should -BeFalse
        Test-Path (Join-Path $locRoot 'german\other_mod_l_german.yml') | Should -BeTrue
        Test-Path (Join-Path $locRoot 'german\iawn_XYZ_l_german.yml') | Should -BeTrue
    }

    It "Refuses an English source whose first line is not l_english:" {
        $locRoot = Join-Path $TestDrive 'loc6'
        Write-LocFile -Path (Join-Path $locRoot 'english\iawn_XYZ_l_english.yml') -Text ('l_german:' + "`n" + $script:Body)

        { Sync-Localisation -LocRoot $locRoot -Languages @('german') } | Should -Throw
    }

    It "Runs end to end as build.ps1 -SyncLoc against a repository copy" {
        $repo = Join-Path $TestDrive 'repo'
        New-Item -ItemType Directory -Path $repo -Force | Out-Null
        Copy-Item -Path $script:BuildScriptPath -Destination (Join-Path $repo 'build.ps1')
        Write-LocFile -Path (Join-Path $repo 'localisation\english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)

        $psExe = (Get-Process -Id $PID).Path
        & $psExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'build.ps1') -SyncLoc | Out-Null
        $LASTEXITCODE | Should -Be 0

        foreach ($lang in $script:OtherLanguages) {
            Test-Path (Join-Path $repo ('localisation\' + $lang + '\iawn_XYZ_l_' + $lang + '.yml')) | Should -BeTrue
        }
    }
}
