param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][string]$WindowsTemplate
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$Godot = (Resolve-Path -LiteralPath $Godot).Path
& (Join-Path $PSScriptRoot 'validate.ps1') -Godot $Godot -WindowsTemplate $WindowsTemplate -PackageName 'emberfall-0.1.0-dev.2'
if ($LASTEXITCODE -ne 0) { throw 'Foundation validation failed' }
$source = & $Godot --headless --path $root --fixed-fps 120 --quit-after 150000 -- --prototype-test 2>&1
$code = $LASTEXITCODE
$source | Set-Content -Encoding UTF8 (Join-Path $root 'artifacts\prototype-source.log')
$text = $source -join "`n"
Write-Host $text
if ($code -ne 0 -or $text -match 'SCRIPT ERROR:|ERROR:' -or $text -notmatch 'PROTOTYPE_RESULT=.*"passed":true') { throw 'Prototype source failed' }
$exe = Join-Path $root 'builds\windows\测试 空格\emberfall-0.1.0-dev.2.exe'
$log = Join-Path $root 'artifacts\prototype-exported.log'
if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log }
$process = Start-Process -FilePath $exe -ArgumentList @('--headless','--fixed-fps','120','--quit-after','150000','--log-file',('"' + $log + '"'),'--','--prototype-test') -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'Exported prototype timed out' }
$text = Get-Content -LiteralPath $log -Raw
Write-Host $text
if ($process.ExitCode -ne 0 -or $text -match 'SCRIPT ERROR:|ERROR:' -or $text -notmatch 'PROTOTYPE_RESULT=.*"passed":true') { throw 'Exported prototype failed' }
Write-Host 'Source and independent Windows package passed; this is not a published release or human acceptance.'
