#Requires -Version 5.1
<#
.SYNOPSIS
    HatDots bootstrap for Windows: clone/update the repo, download the
    latest `hatdots` installer release for this architecture (verifying
    its sha256 against the release's checksums.txt), and run it. Falls
    back to `go run` when no release exists yet and Go is available.

.DESCRIPTION
    Mirrors bootstrap.sh's behavior for Windows/PowerShell. NOT verified
    with a real pwsh run in this environment (pwsh is not installed
    here) — reviewed carefully against PowerShell 5.1/7 syntax instead.
    See odd/tasks/hatdots-unify.md.

.PARAMETER HatdotsArgs
    Arguments passed through to the `hatdots` binary (e.g. -dry-run,
    -all, -only, -yes).
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$HatdotsArgs = @()
)

$ErrorActionPreference = 'Stop'

$HatdotsRepoUrl = 'https://github.com/hat-y/HatDots.git'
$HatdotsReleasesApi = 'https://api.github.com/repos/hat-y/HatDots/releases/latest'

function Write-BootstrapLog {
    param([string]$Message)
    Write-Host "bootstrap: $Message"
}

function Get-HatdotsAssetPair {
    <#
        Maps the current process architecture to the "<goos>_<goarch>"
        pair used in release asset names (windows_amd64 / windows_arm64;
        see .goreleaser.yaml). Returns $null when unsupported. Kept as
        its own function so it can be dot-sourced and tested in
        isolation, mirroring bootstrap.sh's hatdots_asset_pair.
    #>
    param([string]$Arch)

    switch ($Arch.ToLowerInvariant()) {
        'amd64' { return 'windows_amd64' }
        'x64' { return 'windows_amd64' }
        'arm64' { return 'windows_arm64' }
        default { return $null }
    }
}

function Test-HatdotsClone {
    param([string]$Dir)
    $manifest = Join-Path $Dir 'modules.toml'
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
        return $false
    }
    return (Select-String -LiteralPath $manifest -Pattern 'schema\s*=\s*"hatdots/v1"' -Quiet)
}

function Ensure-HatdotsRepo {
    param([string]$Dir)

    if (Test-Path -LiteralPath $Dir) {
        $existingItems = Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue
        if (-not $existingItems) {
            Write-BootstrapLog "cloning HatDots into empty directory $Dir"
            git clone --depth=1 $HatdotsRepoUrl $Dir
            return
        }
        if (Test-HatdotsClone -Dir $Dir) {
            Write-BootstrapLog "updating existing HatDots clone at $Dir"
            try {
                git -C $Dir pull --ff-only
            } catch {
                Write-BootstrapLog "update failed or not possible (local changes?); continuing with the existing checkout"
            }
            return
        }
        throw "$Dir exists, is not empty, and does not look like a HatDots clone (no modules.toml with schema = `"hatdots/v1`"); refusing to touch it. Set `$env:HATDOTS_DIR to a different path."
    }

    Write-BootstrapLog "cloning HatDots into $Dir"
    git clone --depth=1 $HatdotsRepoUrl $Dir
}

function Get-Sha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ReleaseAssetUrl {
    param(
        [Parameter(Mandatory)] $Release,
        [Parameter(Mandatory)] [string]$Pattern
    )
    $asset = $Release.assets | Where-Object { $_.name -like "*$Pattern*" } | Select-Object -First 1
    if ($asset) { return $asset.browser_download_url }
    return $null
}

function Invoke-HatdotsRelease {
    param([string]$Dir, [string[]]$ExtraArgs)

    $arch = $env:PROCESSOR_ARCHITECTURE
    if ([Environment]::Is64BitOperatingSystem -and $env:PROCESSOR_ARCHITEW6432) {
        $arch = $env:PROCESSOR_ARCHITEW6432
    }
    $pair = Get-HatdotsAssetPair -Arch $arch
    if (-not $pair) {
        Write-BootstrapLog "unsupported architecture for a prebuilt release: $arch"
        return $false
    }

    try {
        $release = Invoke-RestMethod -Uri $HatdotsReleasesApi -ErrorAction Stop
    } catch {
        Write-BootstrapLog "could not reach the GitHub releases API (no network, or no release published yet)"
        return $false
    }

    $assetUrl = Get-ReleaseAssetUrl -Release $release -Pattern "_$($pair).zip"
    if (-not $assetUrl) {
        Write-BootstrapLog "no release asset found for $pair"
        return $false
    }
    $checksumsUrl = Get-ReleaseAssetUrl -Release $release -Pattern 'checksums.txt'
    if (-not $checksumsUrl) {
        Write-BootstrapLog "no checksums.txt found in the latest release"
        return $false
    }

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("hatdots-bootstrap-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $assetFile = Join-Path $tmp (Split-Path -Leaf $assetUrl)
        $checksumsFile = Join-Path $tmp 'checksums.txt'
        Write-BootstrapLog "downloading $(Split-Path -Leaf $assetUrl)"
        Invoke-WebRequest -Uri $assetUrl -OutFile $assetFile
        Invoke-WebRequest -Uri $checksumsUrl -OutFile $checksumsFile

        $assetName = Split-Path -Leaf $assetFile
        $expectedLine = Select-String -LiteralPath $checksumsFile -Pattern ([regex]::Escape($assetName)) | Select-Object -First 1
        if (-not $expectedLine) {
            throw "no checksum entry found for $assetName in checksums.txt; aborting"
        }
        $expected = ($expectedLine.Line -split '\s+')[0].ToLowerInvariant()
        $actual = Get-Sha256 -Path $assetFile
        if ($expected -ne $actual) {
            throw "sha256 mismatch for $assetName`: expected $expected, got $actual; aborting"
        }
        Write-BootstrapLog "sha256 verified"

        $extractDir = Join-Path $tmp 'extracted'
        Expand-Archive -LiteralPath $assetFile -DestinationPath $extractDir

        $bin = Join-Path $extractDir 'hatdots.exe'
        if (-not (Test-Path -LiteralPath $bin -PathType Leaf)) {
            throw "extracted archive did not contain hatdots.exe"
        }

        & $bin --repo $Dir @ExtraArgs
        return $true
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-HatdotsFromSource {
    param([string]$Dir, [string[]]$ExtraArgs)

    $go = Get-Command go -ErrorAction SilentlyContinue
    if (-not $go) {
        Write-BootstrapLog "no published release for this platform yet, and 'go' is not available to build from source."
        Write-BootstrapLog "install Go (https://go.dev/dl/) or wait for a tagged release, then re-run this script."
        return $false
    }
    Write-BootstrapLog "no published release available; falling back to 'go run ./installer/cmd/hatdots'"
    Push-Location $Dir
    try {
        & go run ./installer/cmd/hatdots --repo $Dir @ExtraArgs
    } finally {
        Pop-Location
    }
    return $true
}

function Invoke-HatdotsBootstrap {
    param([string[]]$ExtraArgs)

    $dir = $env:HATDOTS_DIR
    if (-not $dir) { $dir = Join-Path $HOME 'projects\HatDots' }

    Ensure-HatdotsRepo -Dir $dir

    if (Invoke-HatdotsRelease -Dir $dir -ExtraArgs $ExtraArgs) {
        return
    }
    if (-not (Invoke-HatdotsFromSource -Dir $dir -ExtraArgs $ExtraArgs)) {
        exit 1
    }
}

# Only run when executed directly, not when dot-sourced for testing
# individual functions (mirrors bootstrap.sh's $0-based guard).
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-HatdotsBootstrap -ExtraArgs $HatdotsArgs
}
