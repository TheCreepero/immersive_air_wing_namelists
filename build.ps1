[CmdletBinding(DefaultParameterSetName = 'Deploy')]
param(
    [Parameter(ParameterSetName = 'Deploy')]
    [switch]$Deploy,

    [Parameter(ParameterSetName = 'DevLink')]
    [switch]$DevLink,

    [Parameter(ParameterSetName = 'Package')]
    [switch]$Package,

    [Parameter(ParameterSetName = 'PublishSteam')]
    [switch]$PublishSteam,

    [Parameter(ParameterSetName = 'InstallSteamCmd')]
    [switch]$InstallSteamCmd,

    [Parameter(ParameterSetName = 'ValidateOnly')]
    [switch]$ValidateOnly,

    [Parameter(ParameterSetName = 'Test')]
    [switch]$Test,

    [Parameter(ParameterSetName = 'SyncLoc')]
    [switch]$SyncLoc,

    [switch]$Validate,
    [switch]$NoValidate,
    [switch]$Clean,

    [string]$ModDir,
    [string]$ZipOutput,
    [string]$SteamUser,
    [string]$ChangeNote,
    [string]$SteamCmdPath,
    [switch]$DryRun,
    [switch]$UpdateDescription
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'tools\HoiModBuild.ps1')

# Vanilla HOI4 1.19 localisation folders other than english. The game does not fall back to
# English for a missing key, so -SyncLoc generates every English file for each of these.
$LocLanguages = @('braz_por', 'french', 'german', 'japanese', 'korean', 'polish', 'russian', 'simp_chinese', 'spanish')

function Sync-Localisation {
    # Writes localisation/<lang>/iawn_<TAG>_l_<lang>.yml for every localisation/english/iawn_<TAG>_l_english.yml:
    # the English file with only the header line changed, UTF-8 with BOM, line endings kept.
    # Works on bytes and single-quoted strings only, so no dollar-delimited token can be interpolated.
    param(
        [string]$LocRoot,
        [string[]]$Languages
    )

    $bom = [byte[]](0xEF, 0xBB, 0xBF)
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $englishDir = Join-Path $LocRoot 'english'
    $expected = @{}
    $written = 0
    $unchanged = 0
    $removed = 0

    $sources = @()
    if (Test-Path $englishDir) {
        $sources = @(Get-ChildItem -Path $englishDir -Filter 'iawn_*_l_english.yml' -File)
    }

    foreach ($src in $sources) {
        $bytes = [System.IO.File]::ReadAllBytes($src.FullName)
        $start = 0
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $start = 3 }

        $nl = [System.Array]::IndexOf($bytes, [byte]10, $start)
        if ($nl -lt 0) { throw ($src.Name + ': no line feed found after the header line') }

        $headerEnd = $nl
        $eol = [byte[]](10)
        if ($nl -gt $start -and $bytes[$nl - 1] -eq 13) {
            $headerEnd = $nl - 1
            $eol = [byte[]](13, 10)
        }

        $header = $utf8.GetString($bytes, $start, $headerEnd - $start)
        if ($header -cne 'l_english:') { throw ($src.Name + ': first line must be l_english: but is ' + $header) }

        $bodyLength = $bytes.Length - $nl - 1
        $body = New-Object 'byte[]' $bodyLength
        [System.Array]::Copy($bytes, $nl + 1, $body, 0, $bodyLength)

        foreach ($lang in $Languages) {
            $targetDir = Join-Path $LocRoot $lang
            $targetName = $src.Name -replace '_l_english\.yml$', ('_l_' + $lang + '.yml')
            $targetPath = Join-Path $targetDir $targetName
            $expected[$lang + '/' + $targetName] = $true

            $headerBytes = $utf8.GetBytes('l_' + $lang + ':')
            $content = [System.Collections.Generic.List[byte]]::new()
            $content.AddRange($bom)
            $content.AddRange($headerBytes)
            $content.AddRange($eol)
            $content.AddRange($body)
            $newBytes = $content.ToArray()

            if (Test-Path $targetPath) {
                $oldBytes = [System.IO.File]::ReadAllBytes($targetPath)
                $same = ($oldBytes.Length -eq $newBytes.Length)
                for ($i = 0; $same -and $i -lt $newBytes.Length; $i++) {
                    if ($oldBytes[$i] -ne $newBytes[$i]) { $same = $false }
                }
                if ($same) { $unchanged++; continue }
            }

            if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            [System.IO.File]::WriteAllBytes($targetPath, $newBytes)
            $written++
        }
    }

    # Remove generated files whose English source no longer exists.
    foreach ($lang in $Languages) {
        $langDir = Join-Path $LocRoot $lang
        if (-not (Test-Path $langDir)) { continue }
        foreach ($stale in @(Get-ChildItem -Path $langDir -Filter ('iawn_*_l_' + $lang + '.yml') -File)) {
            if (-not $expected.ContainsKey($lang + '/' + $stale.Name)) {
                Remove-Item -Force $stale.FullName
                $removed++
                Write-Info ('Removed stale ' + $lang + '/' + $stale.Name)
            }
        }
    }

    Write-Ok ('Localisation synced: ' + $sources.Count + ' English file(s) x ' + @($Languages).Count + ' language(s); ' + $written + ' written, ' + $unchanged + ' unchanged, ' + $removed + ' removed.')
}

if ($SyncLoc) {
    Write-Step "Syncing localisation to all game languages..."
    Sync-Localisation -LocRoot (Join-Path $PSScriptRoot 'localisation') -Languages $LocLanguages
    exit 0
}

$buildConfig = Get-ModBuildConfig -RepoDir $PSScriptRoot -ModDir $ModDir
$buildParameters = Select-ModBuildParameters -BoundParameters $PSBoundParameters
exit (Invoke-ModBuild -Config $buildConfig @buildParameters)
