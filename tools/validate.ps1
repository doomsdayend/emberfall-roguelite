param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$WindowsTemplate
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$evidence = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Force $evidence | Out-Null

function Invoke-Checked([string]$Executable, [string[]]$Arguments, [string]$LogName) {
    $output = & $Executable @Arguments 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content -Encoding UTF8 (Join-Path $evidence $LogName)
    $output | ForEach-Object { Write-Host $_ }
    if ($code -ne 0 -or ($output -match 'SCRIPT ERROR:|ERROR:')) {
        throw "Validation failed: $LogName (exit $code)"
    }
    return ($output -join "`n")
}

$version = & $Godot --headless --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.6\.3\.stable') { throw "Expected Godot 4.6.3 stable, got $version" }
Invoke-Checked $Godot @('--headless','--path',$root,'--editor','--import') 'import.log' | Out-Null
$probe = Invoke-Checked $Godot @('--headless','--path',$root,'--','--probe') 'source-probe.log'
if ($probe -notmatch 'PROBE_RESULT=.*"passed":true') { throw 'Source probe did not report success' }

if ($WindowsTemplate) {
    $WindowsTemplate = (Resolve-Path -LiteralPath $WindowsTemplate).Path
    $preset = Join-Path $root 'export_presets.cfg'
    $original = [IO.File]::ReadAllText($preset)
    $target = Join-Path $root 'builds\windows\测试 空格\emberfall-probe.exe'
    New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
    try {
        $changed = $original.Replace('custom_template/release=""', ('custom_template/release="' + $WindowsTemplate.Replace('\','/') + '"'))
        [IO.File]::WriteAllText($preset, $changed, (New-Object Text.UTF8Encoding $false))
        Invoke-Checked $Godot @('--headless','--path',$root,'--export-release','Windows x86_64',$target) 'export.log' | Out-Null
    } finally {
        [IO.File]::WriteAllText($preset, $original, (New-Object Text.UTF8Encoding $false))
    }
    # Run an independent exported exe/pck pair from a Chinese+space path.
    $packageLog = Join-Path $evidence 'exported-probe.log'
    if (Test-Path -LiteralPath $packageLog) { Remove-Item -LiteralPath $packageLog }
    # Windows release template uses the GUI subsystem; PowerShell's & does not
    # reliably wait/capture stdout. Wait for the process and read its own log.
    $process = Start-Process -FilePath $target -ArgumentList @('--headless','--log-file',('"' + $packageLog + '"'),'--','--probe') -PassThru -WindowStyle Hidden
    if (-not $process.WaitForExit(60000)) {
        $process.Kill()
        throw 'Exported probe timed out after 60 seconds'
    }
    $exported = Get-Content -LiteralPath $packageLog -Raw
    Write-Host $exported
    if ($process.ExitCode -ne 0 -or $exported -match 'SCRIPT ERROR:|ERROR:') { throw 'Exported executable failed' }
    if ($exported -notmatch 'PROBE_RESULT=.*"passed":true') { throw 'Exported probe did not report success' }
    Get-FileHash -LiteralPath $target,([IO.Path]::ChangeExtension($target,'.pck')) -Algorithm SHA256 |
        Select-Object Path,Hash | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $evidence 'build-sha256.json')
} else {
    Write-Host 'Windows native export NOT TESTED (supply -WindowsTemplate).'
}
Write-Host 'Technical checks finished. Art, gameplay, GPU rendering and human acceptance remain separate.'
