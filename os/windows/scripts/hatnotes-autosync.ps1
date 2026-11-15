# One git writer for HatNotes (PowerShell port of common/bin/hatnotes-autosync).
# Pull --rebase, commit if dirty, push. Never --force.
$ErrorActionPreference = 'Continue'

$Vault = if ($env:HATNOTES_PATH) { $env:HATNOTES_PATH } else { Join-Path $HOME 'HatNotes' }
$LogDir = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $env:LOCALAPPDATA 'hatnotes' }
$Log = Join-Path $LogDir 'hatnotes-autosync.log'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log([string]$Message) {
    Add-Content -Path $Log -Value ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'), $Message)
}

function Send-Notice([string]$Message) {
    # Optional: no portable toast API across Windows versions; the log is the record.
    Write-Warning $Message
}

if (-not (Test-Path (Join-Path $Vault '.git'))) {
    Write-Log "ERROR: not a git repo: $Vault"
    Send-Notice "No es un repo git: $Vault"
    exit 1
}

# Single-instance lock: a named mutex is released by the OS if we die.
$created = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\HatNotesAutosync', [ref]$created)
if (-not $created) {
    Write-Log 'skip: already running'
    exit 0
}

try {
    Set-Location $Vault

    git pull --rebase --autostash
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: git pull --rebase failed in $Vault"
        Send-Notice 'Falló git pull --rebase. Revisá HatNotes a mano.'
        git rebase --abort *> $null
        exit 1
    }

    git add -A
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'ERROR: git add failed'
        exit 1
    }

    git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Log 'ok: nothing to commit'
        exit 0
    }

    git commit -m ("chore(vault): autosync {0}" -f (Get-Date -Format 'yyyy-MM-ddTHH:mmzzz'))
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'ERROR: git commit failed'
        Send-Notice 'Falló git commit de autosync.'
        exit 1
    }

    git push origin HEAD
    if ($LASTEXITCODE -ne 0) {
        Write-Log 'ERROR: git push failed'
        Send-Notice 'Falló git push de autosync.'
        exit 1
    }

    Write-Log 'ok: committed and pushed'
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
