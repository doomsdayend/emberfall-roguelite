param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$project = Join-Path $root 'project.godot'
$original = [IO.File]::ReadAllText($project)
$log = Join-Path $root 'artifacts\gpu-capture.log'
New-Item -ItemType Directory -Force (Join-Path $root 'artifacts') | Out-Null
New-Item -ItemType File -Force (Join-Path $root 'artifacts\.gdignore') | Out-Null
try {
    # Godot must create its context with Windows display. Start minimized before
    # scene initialization; render only a SubViewport, never a visible game.
    $changed = $original.Replace('[display]', "[display]`nwindow/size/mode=1")
    [IO.File]::WriteAllText($project, $changed, [Text.UTF8Encoding]::new($false))
    $arguments = @('--path',('"' + $root + '"'),'--display-driver','windows','--rendering-driver','opengl3','--rendering-method','gl_compatibility','--audio-driver','Dummy','--disable-render-loop','--fixed-fps','120','--quit-after','2000','--log-file',('"' + $log + '"'),'--script','res://tests/gpu_capture.gd')
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'GPU capture timed out' }
    $result = Get-Content -LiteralPath $log -Raw
    Write-Host $result
    if ($process.ExitCode -ne 0 -or $result -match 'SCRIPT ERROR:|ERROR:' -or $result -notmatch 'GPU_CAPTURE_RESULT=.*"passed":true') { throw 'GPU capture failed' }
} finally {
    [IO.File]::WriteAllText($project, $original, [Text.UTF8Encoding]::new($false))
}
