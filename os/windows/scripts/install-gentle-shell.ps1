# Install Gentle Shell (https://github.com/Gentleman-Programming/gentle-shell)
# via its upstream browser installer. Skips when `gentle-shell` is on PATH.
# The installer opens a wizard on 127.0.0.1 and changes nothing until you
# confirm. Idempotent: reuses the cached checkout with `git pull --ff-only`.
$ErrorActionPreference = 'Stop'

if (Get-Command gentle-shell -ErrorAction SilentlyContinue) {
    Write-Host 'gentle-shell already on PATH; skipping'
    exit 0
}

$dir = Join-Path $env:LOCALAPPDATA 'hatdots\gentle-shell'
if (Test-Path (Join-Path $dir '.git')) {
    git -C $dir pull --ff-only
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path $dir) | Out-Null
    git clone --depth=1 https://github.com/Gentleman-Programming/gentle-shell.git $dir
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $dir
cmd /c 'scripts\bootstrap.cmd'
exit $LASTEXITCODE
