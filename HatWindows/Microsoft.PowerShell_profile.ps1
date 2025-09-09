# ---------- Rendimiento / telemetría ----------
$env:POWERSHELL_UPDATECHECK      = "Off"
$env:POWERSHELL_TELEMETRY_OPTOUT = "1"
$env:DOTNET_CLI_TELEMETRY_OPTOUT = "1"
$ProgressPreference              = 'SilentlyContinue'

# ---------- PSReadLine  ----------
try {
  if (-not (Get-Module -ListAvailable PSReadLine)) {
    Install-Module PSReadLine -Scope CurrentUser -Force -AllowClobber | Out-Null
  }
  Import-Module PSReadLine -ErrorAction Stop

  Set-PSReadLineOption -EditMode Windows
 # Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineOption -BellStyle None
  if ($Host.UI.SupportsVirtualTerminal) {
    Set-PSReadLineOption -Colors @{ InlinePrediction = "#808080" }
  }

  # Navegación y atajos
  Set-PSReadLineKeyHandler -Key UpArrow    -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow  -Function HistorySearchForward
  Set-PSReadLineKeyHandler -Key Ctrl+r     -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function AcceptSuggestion
  Set-PSReadLineKeyHandler -Key Ctrl+e     -Function EndOfLine
  Set-PSReadLineKeyHandler -Key Ctrl+a     -Function BeginningOfLine
  Set-PSReadLineKeyHandler -Key Alt+f      -Function ForwardWord
  Set-PSReadLineKeyHandler -Key Alt+b      -Function BackwardWord
} catch {
  Write-Host "[PSReadLine] No se pudo cargar: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------- Listados con iconos ----------
# Si existe alias 'ls' (de alguna app/tema), quitalo para que gane nuestra función
if (Get-Alias ls -ErrorAction SilentlyContinue) { Remove-Item Alias:ls -ErrorAction SilentlyContinue }

$hasEza = Get-Command eza -ErrorAction SilentlyContinue
if ($hasEza) {
  $env:EZA_ICON_SPACING = "2"
  function ls { eza --icons=always --group --git $args }
  function ll { eza -l  --icons=always --group --git $args }
  function la { eza -la --icons=always --group --git $args }
} else {
  if (Get-Module -ListAvailable Terminal-Icons) { Import-Module Terminal-Icons }
  function ll { Get-ChildItem -Force | Format-Wide -AutoSize }
  function la { Get-ChildItem -Force -Hidden }
}

# ---------- Starship (prompt) ----------
if (Get-Command starship -ErrorAction SilentlyContinue) {
  Invoke-Expression (& starship init powershell)
}

# ---------- Zoxide (cd inteligente, opcional) ----------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ---------- Alias / helpers ----------
Set-Alias -Name vim -Value nvim
Set-Alias -Name g   -Value git
function gs { git status }
function nv { nvim . }
function reload-profile { . $PROFILE; Write-Host "Profile recargado" -ForegroundColor Green }


function msvc64 {
  $vswhere = "$env:ProgramFiles(x86)\Microsoft Visual Studio\Installer\vswhere.exe"
  $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
  $bat = Join-Path $vs "VC\Auxiliary\Build\vcvarsall.bat"
  cmd /k "`"$bat`" x64 && powershell -NoExit -Command Set-Location $PWD"
}

