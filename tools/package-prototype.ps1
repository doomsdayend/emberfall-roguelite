param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$WindowsTemplate
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    $changes = git status --porcelain
    if ($changes) { throw 'Commit source and reports before creating a traceable development package' }
    $sha = git rev-parse HEAD
    & (Join-Path $PSScriptRoot 'validate-prototype.ps1') -Godot $Godot -WindowsTemplate $WindowsTemplate
    if ($LASTEXITCODE -ne 0) { throw 'Validation failed' }
    $stage = Join-Path $root 'builds\emberfall-0.1.0-dev.2-windows-x64'
    New-Item -ItemType Directory -Force $stage | Out-Null
    $built = Join-Path $root 'builds\windows\测试 空格'
    foreach ($extension in @('exe','pck')) {
        Copy-Item -LiteralPath (Join-Path $built ('emberfall-0.1.0-dev.2.' + $extension)) -Destination $stage -Force
    }
    Copy-Item -LiteralPath (Join-Path $root 'docs\testing\prototype-playtest.md') -Destination (Join-Path $stage 'READ-ME.md') -Force
    Copy-Item -LiteralPath (Join-Path $root 'docs\licenses') -Destination $stage -Recurse -Force
    $metadata = [ordered]@{
        version = '0.1.0-dev.2'
        source_commit = $sha
        built_utc = [DateTime]::UtcNow.ToString('o')
        engine = 'Godot 4.6.3.stable.official.7d41c59c4'
        development_candidate = $true
        published = $false
        human_playtested = $false
        clean_virtual_machine_tested = $false
    }
    $metadata | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $stage 'BUILD.json')
    Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object Name -ne 'SHA256SUMS.txt' |
        ForEach-Object { $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256; $hash.Hash.ToLower() + '  ' + $_.FullName.Substring($stage.Length + 1).Replace('\','/') } |
        Set-Content -Encoding UTF8 (Join-Path $stage 'SHA256SUMS.txt')
    $zip = $stage + '.zip'
    Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
    Get-FileHash -LiteralPath $zip -Algorithm SHA256 | Format-List
    Write-Host "Development candidate: $zip (source $sha); no Tag or Release created."
} finally { Pop-Location }
