param([string]$Step = 'baseline', [switch]$Cards2)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$godotExe = 'C:/Users/ddwig/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe'
$resultsRoot = Join-Path $projectRoot "screenshots/cards2-checks/$Step"
New-Item -ItemType Directory -Path $resultsRoot -Force | Out-Null
$checks = @(
    @{ Name='import'; Args=@('--headless','--import') },
    @{ Name='smoke'; Args=@('--headless','--quit-after','300') }
)
foreach ($rig in @('feedback','shots','ai_probe','rarity','lane','lastcard')) {
    $outputPath = Join-Path $resultsRoot $rig
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
    if ($rig -in @('lane','lastcard')) { $outputPath = Join-Path $outputPath "$rig.png" }
    $mode = if ($rig -eq 'ai_probe') { @('--headless') } else { @('--rendering-method','gl_compatibility','--windowed','--resolution','1280x720','--position','-1400,-900') }
    $checks += @{ Name=$rig; Args=(@($mode) + @("res://tools/rigs/check/$rig.tscn",'--',$outputPath)) }
}
if ($Cards2) {
    $checks += @{ Name='cards2'; Args=@('--headless','res://tools/rigs/check/cards2.tscn','--',$resultsRoot) }
}
$results = @()
foreach ($check in $checks) {
    $stdout = Join-Path $resultsRoot ($check.Name + '.log')
    $stderr = Join-Path $resultsRoot ($check.Name + '.err.log')
    $arguments = @('--path',('"' + $projectRoot + '"')) + $check.Args
    $proc = Start-Process -FilePath $godotExe -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $proc.WaitForExit(180000)) { $proc.Kill(); throw "$($check.Name) timed out" }
    $proc.WaitForExit()
    $lines = @(Get-Content -LiteralPath $stdout) + @(Get-Content -LiteralPath $stderr)
    $failures = @($lines | Where-Object { $_ -match 'SCRIPT ERROR|Parse Error|^FAIL |^FAILS [1-9]' })
    $passes = @($lines | Where-Object { $_ -match '^PASS ' }).Count
    $ok = $proc.ExitCode -eq 0 -and $failures.Count -eq 0
    if ($check.Name -eq 'ai_probe') { $ok = $ok -and $passes -eq 20 }
    if ($check.Name -eq 'feedback') { $ok = $ok -and $passes -eq 14 } # current rig has 14 assertions
    if ($check.Name -in @('feedback','shots','ai_probe','rarity','cards2')) { $ok = $ok -and ($lines -contains 'FAILS 0') }
    $results += [pscustomobject]@{check=$check.Name; pass=$ok; exit_code=$proc.ExitCode; assertions=$passes; failures=$failures; diagnostics=@($lines | Where-Object { $_ -match '^ERROR:' })}
    Write-Output ("{0}: {1} ({2} assertions, exit {3})" -f $check.Name, $(if ($ok) {'PASS'} else {'FAIL'}), $passes, $proc.ExitCode)
    $failures | Select-Object -First 12 | Write-Output
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $resultsRoot 'results.json')
    if (-not $ok) { exit 1 }
}
Write-Output "All requested checks passed: $Step"
