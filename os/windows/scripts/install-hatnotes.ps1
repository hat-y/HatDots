# Clone HatNotes if missing, then register the "HatNotes autosync" scheduled
# task (every 15 minutes). Idempotent: an existing vault is never touched and
# an existing task is updated in place.
$ErrorActionPreference = 'Stop'

$vault = if ($env:HATNOTES_PATH) { $env:HATNOTES_PATH } else { Join-Path $HOME 'HatNotes' }
if (Test-Path $vault) {
    Write-Host "HatNotes already present at $vault; skipping clone"
} else {
    git clone https://github.com/hat-y/HatNotes.git $vault
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$script = Join-Path $PSScriptRoot 'hatnotes-autosync.ps1'
$arg = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$action = New-ScheduledTaskAction -Execute 'powershell' -Argument $arg
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName 'HatNotes autosync' -Action $action -Trigger $trigger `
    -Settings $settings -Description 'HatNotes git autosync every 15 minutes' -Force | Out-Null
Write-Host 'Scheduled task "HatNotes autosync" registered (every 15 minutes)'
