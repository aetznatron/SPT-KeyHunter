<#
.SYNOPSIS
    Builds SPT-KeyHunter against SPT 4.1.x (NuGet packages) and installs it.

.PARAMETER SptRoot
    SPT runtime folder (default: SPT_Runtime of the 4.1.6 install).

.PARAMETER Package
    Also write build\KeyHunter-v<version>.zip with the release layout.

.PARAMETER SkipDeploy
    Only build/package, do not touch the game folder.
#>
[CmdletBinding()]
param(
    [string]$SptRoot = 'D:\Games\SPT 4.1.6 essential\SPT_Runtime',
    [string]$Configuration = 'Release',
    [switch]$Package,
    [switch]$SkipDeploy
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$proj = Join-Path $repo 'KeyHunter.csproj'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'dotnet SDK not found. SPT 4.1.x runs on .NET 10 - install the .NET 10 SDK.'
}

$version = ([regex]::Match((Get-Content $proj -Raw), '<Version>([^<]+)</Version>')).Groups[1].Value
if (-not $version) {
    $version = ([regex]::Match((Get-Content (Join-Path $repo 'Mod.cs') -Raw), 'new\("([0-9.]+)"\)')).Groups[1].Value
}
Write-Host "dotnet  : $(& dotnet --version)"
Write-Host "version : $version"

& dotnet build $proj -c $Configuration -v minimal --nologo
if ($LASTEXITCODE -ne 0) { throw "Build failed (exit $LASTEXITCODE)" }

$out = Join-Path $repo "bin\$Configuration\net10.0"
$dll = Join-Path $out 'KeyHunter.dll'
if (-not (Test-Path $dll)) { throw "missing build output: $dll" }
Write-Host ("built {0} ({1} bytes)" -f $dll, (Get-Item $dll).Length)

function Copy-ModFiles([string]$dest) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item $dll (Join-Path $dest 'KeyHunter.dll') -Force
    $cfgDir = Join-Path $dest 'Config'
    if (-not (Test-Path (Join-Path $cfgDir 'config.json'))) {
        New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
        Copy-Item (Join-Path $repo 'Config\config.json') (Join-Path $cfgDir 'config.json') -Force
    }
}

if ($Package) {
    $stage = Join-Path $repo 'build\SPT_Runtime\user\mods\KeyHunter'
    if (Test-Path (Join-Path $repo 'build')) { Remove-Item (Join-Path $repo 'build') -Recurse -Force }
    Copy-ModFiles $stage
    $zip = Join-Path $repo "build\KeyHunter-v$version.zip"
    Compress-Archive -Path (Join-Path $repo 'build\SPT_Runtime') -DestinationPath $zip -Force
    Write-Host "package : $zip"
}

if ($SkipDeploy) { Write-Host 'Built, deployment skipped.'; return }
if (Get-Process -Name 'SPT.Server' -ErrorAction SilentlyContinue) {
    Write-Warning 'SPT.Server is running - stop it and re-run to deploy.'
    return
}

$mod = Join-Path $SptRoot 'user\mods\KeyHunter'
Copy-ModFiles $mod
Write-Host ''
Write-Host "Installed to: $mod"
Get-ChildItem $mod -Recurse -File | Select-Object @{n='file';e={$_.FullName.Substring($mod.Length)}},Length | Format-Table -AutoSize
