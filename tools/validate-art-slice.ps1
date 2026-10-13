param([Parameter(Mandatory=$true)][string]$Godot, [Parameter(Mandatory=$true)][string]$WindowsTemplate)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$Godot = (Resolve-Path -LiteralPath $Godot).Path
& (Join-Path $PSScriptRoot 'validate.ps1') -Godot $Godot -WindowsTemplate $WindowsTemplate -PackageName 'emberfall-art-preview'
if ($LASTEXITCODE -ne 0) { throw 'Foundation validation failed' }
foreach ($preview in @($false, $true)) {
    $suffix = if ($preview) { 'skin' } else { 'default' }
    $flags = @('--prototype-test')
    if ($preview) { $flags += '--art-slice-preview' }
    $sourceLog = Join-Path $root "artifacts\stage03-source-$suffix.log"
    $output = & $Godot --headless --path $root --fixed-fps 120 --quit-after 150000 -- @flags 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content -Encoding UTF8 $sourceLog
    $result = $output -join "`n"
    if ($code -ne 0 -or $result -match 'SCRIPT ERROR:|ERROR:' -or $result -notmatch 'PROTOTYPE_RESULT=.*"passed":true') { throw "Source $suffix failed: $sourceLog" }
    Write-Host $result
    $exe = Join-Path $root 'builds\windows\测试 空格\emberfall-art-preview.exe'
    $log = Join-Path $root "artifacts\stage03-exported-$suffix.log"
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log }
    $arguments = @('--headless','--fixed-fps','120','--quit-after','150000','--log-file',('"' + $log + '"'),'--') + $flags
    $process = Start-Process -FilePath $exe -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw "Exported $suffix timed out" }
    $result = Get-Content -LiteralPath $log -Raw
    if ($process.ExitCode -ne 0 -or $result -match 'SCRIPT ERROR:|ERROR:' -or $result -notmatch 'PROTOTYPE_RESULT=.*"passed":true') { throw "Exported $suffix failed: $log" }
    Write-Host $result
}
Write-Host 'Default and art preview source/export checks passed; final art acceptance remains open.'
