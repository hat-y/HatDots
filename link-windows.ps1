$Repo = "$HOME\HatDots\HatWindows"
$Paths = @{
  NvimDir     = "$Repo\nvim"
  WeztermFile = "$Repo\wezterm\wezterm.lua"
  PSProfile   = "$Repo\powershell\Microsoft.PowerShell_profile.ps1"
  Starship    = "$Repo\starship\starship.toml"
}
$Targets = @{
  NvimDir     = "$env:LOCALAPPDATA\nvim"
  WeztermFile = "$HOME\.wezterm.lua"
  PSProfile   = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
  Starship    = "$HOME\.config\starship.toml"
}

function New-FileLink($link,$target) {
  New-Item -ItemType Directory -Force (Split-Path $link) | Out-Null
  if (Test-Path $link) { Remove-Item $link -Force }
  try { New-Item -ItemType SymbolicLink -Path $link -Target $target -Force | Out-Null }
  catch { New-Item -ItemType HardLink -Path $link -Target $target | Out-Null }
}
function New-DirLink($link,$target) {
  if (Test-Path $link) { Remove-Item $link -Recurse -Force }
  try { New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null }
  catch { New-Item -ItemType Junction     -Path $link -Target $target | Out-Null }
}

New-Item -ItemType Directory -Force "$Repo\nvim","$Repo\wezterm","$Repo\powershell","$Repo\starship","$HOME\.config","$HOME\Documents\PowerShell" | Out-Null
foreach ($f in @($Paths.WeztermFile,$Paths.PSProfile,$Paths.Starship)) {
  if (-not (Test-Path $f)) { New-Item -ItemType File $f | Out-Null }
}
New-DirLink  $Targets.NvimDir     $Paths.NvimDir
New-FileLink $Targets.WeztermFile $Paths.WeztermFile
New-FileLink $Targets.PSProfile   $Paths.PSProfile
New-FileLink $Targets.Starship    $Paths.Starship

Write-Host "Links creados. Cierra y reabre WezTerm si estaba abierto." -ForegroundColor Green
