BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:BuildScriptPath = Join-Path $script:RepoRoot "build.ps1"
    $script:BuildContent = [System.IO.File]::ReadAllText($script:BuildScriptPath, [System.Text.Encoding]::UTF8)
    . (Join-Path $script:RepoRoot 'tools\HoiModBuild.ps1')
    $script:BuildConfig = Get-ModBuildConfig -RepoDir $script:RepoRoot

    # Sync-Localisation reports through build.ps1's Write-* helpers; stub them for the unit tests.
    function Write-Ok   { param([string]$msg) }
    function Write-Info { param([string]$msg) }
    $syncFuncMatch = [regex]::Match($script:BuildContent, '(?s)(function Sync-Localisation\s*\{.*?\n\})')
    if ($syncFuncMatch.Success) {
        . ([ScriptBlock]::Create($syncFuncMatch.Groups[1].Value))
    }

    . (Join-Path $PSScriptRoot 'AirWingNames.Helpers.ps1')
}

Describe 'build.ps1 configuration' {
    It 'ships the common and localisation folders with the descriptor and thumbnail' {
        $shippedTopLevel = @(Get-ModContentFiles -Config $script:BuildConfig | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique)
        $shippedTopLevel | Should -Be @('common', 'descriptor.mod', 'localisation', 'thumbnail.png') -Because 'the namelists name their wings through localisation keys'
    }

    It 'installs as immersive_air_wing_namelists and packages immersive_air_wing_namelists.zip' {
        $script:BuildConfig.ModFolderName | Should -Be 'immersive_air_wing_namelists'
        $script:BuildConfig.ZipArchiveName | Should -Be 'immersive_air_wing_namelists.zip'
        $script:BuildConfig.PackageLayout | Should -Be 'Flat'
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
        New-Item -ItemType Directory -Path (Join-Path $repo 'tools') -Force | Out-Null
        Copy-Item -Path (Join-Path $script:RepoRoot 'tools\HoiModBuild.ps1') -Destination (Join-Path $repo 'tools\HoiModBuild.ps1')
        Write-LocFile -Path (Join-Path $repo 'localisation\english\iawn_XYZ_l_english.yml') -Text ('l_english:' + "`n" + $script:Body)

        $psExe = (Get-Process -Id $PID).Path
        & $psExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'build.ps1') -SyncLoc | Out-Null
        $LASTEXITCODE | Should -Be 0

        foreach ($lang in $script:OtherLanguages) {
            Test-Path (Join-Path $repo ('localisation\' + $lang + '\iawn_XYZ_l_' + $lang + '.yml')) | Should -BeTrue
        }
    }
}
