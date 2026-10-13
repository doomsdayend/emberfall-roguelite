param([Parameter(Mandatory=$true)][string]$Godot, [ValidateSet('capture','rate')][string]$Mode = 'capture', [ValidateSet(30,60,120)][int]$Fps = 60, [switch]$ArtSlice)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$Godot = (Resolve-Path -LiteralPath $Godot).Path
$project = Join-Path $root 'project.godot'
$original = [IO.File]::ReadAllText($project)
$log = Join-Path $root $(if ($Mode -eq 'capture') { 'artifacts\gpu-capture.log' } else { "artifacts\gpu-rate-$Fps.log" })
New-Item -ItemType Directory -Force (Join-Path $root 'artifacts') | Out-Null
New-Item -ItemType File -Force (Join-Path $root 'artifacts\.gdignore') | Out-Null
try {
    # Godot must create its context with Windows display. Start minimized before
    # scene initialization; render only a SubViewport, never a visible game.
    $changed = $original.Replace('[display]', "[display]`nwindow/size/mode=1")
    [IO.File]::WriteAllText($project, $changed, [Text.UTF8Encoding]::new($false))
    $arguments = @('--path',('"' + $root + '"'),'--display-driver','windows','--rendering-driver','opengl3','--rendering-method','gl_compatibility','--audio-driver','Dummy','--disable-render-loop','--fixed-fps','120','--quit-after','2000','--log-file',('"' + $log + '"'),'--script','res://tests/gpu_capture.gd')
    $marker = 'GPU_CAPTURE_RESULT='
    if ($Mode -eq 'rate') {
        $arguments = @('--path',('"' + $root + '"'),'--display-driver','windows','--rendering-driver','opengl3','--rendering-method','gl_compatibility','--audio-driver','Dummy','--disable-render-loop','--disable-vsync','--max-fps',"$Fps",'--quit-after','2000','--log-file',('"' + $log + '"'),'--script','res://tests/gpu_rate_probe.gd')
        $marker = 'GPU_RATE_RESULT='
    }
    $arguments += @('--','--gpu-test')
    if ($ArtSlice) { $arguments += '--art-slice-preview' }
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'GPU capture timed out' }
    $result = Get-Content -LiteralPath $log -Raw
    Write-Host $result
    if ($process.ExitCode -ne 0 -or $result -match 'SCRIPT ERROR:|ERROR:' -or $result -notmatch ($marker + '.*"passed":true')) { throw 'GPU verification failed' }
} finally {
    [IO.File]::WriteAllText($project, $original, [Text.UTF8Encoding]::new($false))
}
