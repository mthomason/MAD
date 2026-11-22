#Requires -Version 7
<#
  Windows/package.ps1 — assemble the unsigned Windows release.

  Produces, under -OutputDir (default Windows/build/packages, git-ignored):

    MAD-Designer-Windows-<version>.zip   the app, the engine, the runtime and
                                         the licences, laid out so MadPathResolver
                                         finds everything without an install step
    MAD-Designer-Windows-<version>.zip.sha256
    mad-windows-x64.zip                  the engine alone, the asset the Windows
                                         verification workflow downloads
    mad-windows-x64.zip.sha256

  The archive layout is deliberately the repository-relative layout the app
  already resolves: the executable sits at the root, the engine at
  Windows/Engine/build (beside its GNUstep/ObjC/VC runtime DLLs and fonts), and
  CLI/Fixtures/London.portable.mad is the marker MadPathResolver.RepoRoot
  searches for.  Nothing is code-signed; the docs explain the warning and how
  to self-sign a local copy.

  The engine must be built first:

      pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain

  Then:

      pwsh -File .\Windows\package.ps1

  The runtime DLLs come from the GNUstep prefix (default %GNUSTEP_BIN%, or
  C:\GNUstep\x64\Release\bin; override with -GnuStepBin) and the VC++
  redistributable (found through vswhere; override with -VcRuntimeDir).  The
  build leaves both outside Windows/Engine/build, so the package collects them.

  -SkipPublish reuses Windows/build/publish/win-x64; -SkipEngineBundle skips the
  engine-only zip used by CI.
#>
[CmdletBinding()]
param(
    [string]$Version = "0.7",
    [string]$EngineVersion = "9.0 (r4433)",
    [string]$OutputDir = (Join-Path $PSScriptRoot "build\packages"),
    [string]$GnuStepBin,
    [string]$VcRuntimeDir,
    [switch]$SkipPublish,
    [switch]$SkipEngineBundle
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$EngineDir = Join-Path $PSScriptRoot "Engine\build"
$PublishDir = Join-Path $PSScriptRoot "build\publish\win-x64"
$AppProject = Join-Path $PSScriptRoot "App\Mad.Designer.Windows\Mad.Designer.Windows.csproj"
$Sample = Join-Path $RepoRoot "CLI\Fixtures\London.portable.mad"
$SampleDatabase = Join-Path $RepoRoot "MADDesigner\Resources\Assets\Samples.xcassets\Data\chinook.dataset\chinook.sqlite3"
$Licenses = Join-Path $RepoRoot "ThirdParty\Licenses"

# mad.exe links these runtime DLLs directly or through gnustep-base, measured
# with llvm-objdump -p (docs/developers/build/windows.md section 8).  The engine
# build leaves them in the GNUstep prefix; the bundle puts them beside mad.exe
# so the archive needs no GNUstep install.
$RuntimeFiles = @(
    "gnustep-base-1_31.dll",
    "objc.dll",
    "dispatch.dll",
    "libffi-8.dll",
    "libiconv.dll",
    "libcurl.dll"
)
$VcRuntimeNames = @(
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "msvcp140_atomic_wait.dll",
    "msvcp140_codecvt_ids.dll",
    "concrt140.dll",
    "vccorlib140.dll",
    "vcruntime140_threads.dll"
)

function Require([string]$path, [string]$hint) {
    if (-not (Test-Path $path)) { throw "missing $path — $hint" }
}

function Find-VcRuntimeDir {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    $installation = & $vswhere -latest -products * -property installationPath |
        Select-Object -First 1
    if (-not $installation) { return $null }
    $redist = Join-Path $installation "VC\Redist\MSVC"
    if (-not (Test-Path $redist)) { return $null }
    return Get-ChildItem $redist -Directory |
        Sort-Object Name -Descending |
        ForEach-Object { Get-ChildItem (Join-Path $_.FullName "x64") -Directory -Filter "Microsoft.VC*.CRT" -ErrorAction SilentlyContinue } |
        Select-Object -First 1 |
        ForEach-Object { $_.FullName }
}

function Copy-Engine([string]$destination) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    Copy-Item (Join-Path $EngineDir "mad.exe") $destination
    foreach ($file in $RuntimeFiles) {
        Copy-Item (Join-Path $GnuStepBin $file) $destination
    }
    Copy-Item (Join-Path $EngineDir "fonts") $destination -Recurse
    foreach ($name in $VcRuntimeNames) {
        Copy-Item (Join-Path $VcRuntimeDir $name) $destination
    }
}

function Write-Checksum([string]$path) {
    $hash = (Get-FileHash $path -Algorithm SHA256).Hash
    "$hash  $(Split-Path $path -Leaf)" | Set-Content "$path.sha256" -Encoding utf8NoBOM
}

# ---------------------------------------------------------------------------
Write-Host "### Checking the inputs"
if (-not $GnuStepBin) {
    $GnuStepBin = if ($env:GNUSTEP_BIN) { $env:GNUSTEP_BIN } else { "C:\GNUstep\x64\Release\bin" }
}
Require (Join-Path $EngineDir "mad.exe") "build the engine first: pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain"
foreach ($file in $RuntimeFiles) {
    Require (Join-Path $GnuStepBin $file) "the GNUstep toolchain runtime is missing; pass -GnuStepBin"
}
Require (Join-Path $EngineDir "fonts\LiberationSans-Regular.ttf") "the engine build copies the Liberation fonts beside mad.exe"
Require $Sample "the sample document is the repository-root marker"
Require $SampleDatabase "the sample report refreshes against this SQLite database"
Require $Licenses "the archive must carry every licence and notice"
Require (Join-Path $RepoRoot "LICENSE") "the archive carries the MIT text"
Require (Join-Path $RepoRoot "NOTICE") "the archive carries the brand notice"

if (-not $VcRuntimeDir) {
    $VcRuntimeDir = Find-VcRuntimeDir
}
if (-not $VcRuntimeDir -or -not (Test-Path $VcRuntimeDir)) {
    throw "could not find the Visual C++ redistributable DLLs; pass -VcRuntimeDir (…\VC\Redist\MSVC\<ver>\x64\Microsoft.VC###.CRT)"
}
foreach ($name in $VcRuntimeNames) {
    Require (Join-Path $VcRuntimeDir $name) "the VC++ redistributable runtime is incomplete"
}
Write-Host "  ok   engine, GNUstep runtime ($GnuStepBin), fonts, sample, licences, VC runtime ($VcRuntimeDir)"

# ---------------------------------------------------------------------------
if (-not $SkipPublish) {
    Write-Host "### Publishing the WPF app (self-contained win-x64)"
    if (Test-Path $PublishDir) { Remove-Item -Recurse -Force $PublishDir }
    & dotnet publish $AppProject -c Release -r win-x64 --self-contained true `
        -p:PublishSingleFile=false -o $PublishDir --nologo
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }
}
Require (Join-Path $PublishDir "Mad.Designer.Windows.exe") "publish the app first, or drop -SkipPublish"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$AppName = "MAD-Designer-Windows-$Version"
$StageRoot = Join-Path $OutputDir $AppName
if (Test-Path $StageRoot) { Remove-Item -Recurse -Force $StageRoot }
New-Item -ItemType Directory -Force -Path $StageRoot | Out-Null

# ---------------------------------------------------------------------------
Write-Host "### Laying out $AppName"
Copy-Item (Join-Path $PublishDir "*") $StageRoot -Recurse

New-Item -ItemType Directory -Force -Path (Join-Path $StageRoot "CLI\Fixtures") | Out-Null
Copy-Item $Sample (Join-Path $StageRoot "CLI\Fixtures")
Copy-Item $SampleDatabase (Join-Path $StageRoot "CLI\Fixtures")

Copy-Engine (Join-Path $StageRoot "Windows\Engine\build")

New-Item -ItemType Directory -Force -Path (Join-Path $StageRoot "ThirdParty") | Out-Null
Copy-Item $Licenses (Join-Path $StageRoot "ThirdParty") -Recurse
Copy-Item (Join-Path $RepoRoot "LICENSE") $StageRoot
Copy-Item (Join-Path $RepoRoot "NOTICE") $StageRoot

$readme = @"
MAD Designer for Windows $Version
Engine $EngineVersion

This build is UNSIGNED.  It is built and published from the public source
(https://github.com/mthomason/MAD) but carries no commercial code-signing
certificate, so Windows SmartScreen warns on first launch: choose More info,
then Run anyway.  Verify the archive's SHA-256 against the release page before
running it, or review and self-sign a local copy — see docs/windows.md.

Run:      Mad.Designer.Windows.exe  (top of this folder)
Engine:   Windows\Engine\build\mad.exe
Keep the folder structure: the application finds the engine and its licences
through these relative paths.

No .NET install is needed (self-contained).  The Viewer uses the Microsoft Edge
WebView2 Evergreen Runtime, which ships with Windows 11 and current Edge.

Licences: ThirdParty\Licenses\ ; MIT text: LICENSE ; brand notice: NOTICE.
"@
$readme | Set-Content (Join-Path $StageRoot "README-Windows.txt") -Encoding utf8NoBOM

# The layout is only correct if the engine resolves from where the app expects it.
& (Join-Path $StageRoot "Windows\Engine\build\mad.exe") inspect (Join-Path $StageRoot "CLI\Fixtures\London.portable.mad") | Out-Null
if ($LASTEXITCODE -ne 0) { throw "the staged engine did not inspect the sample document (exit $LASTEXITCODE)" }
Write-Host "  ok   the staged engine inspects the sample"

# ---------------------------------------------------------------------------
Write-Host "### Writing the archives"
$AppZip = Join-Path $OutputDir "$AppName.zip"
if (Test-Path $AppZip) { Remove-Item -Force $AppZip }
Compress-Archive -Path $StageRoot -DestinationPath $AppZip
Write-Checksum $AppZip
$size = [math]::Round((Get-Item $AppZip).Length / 1MB, 1)
Write-Host "  ok   $AppZip ($size MB)"

if (-not $SkipEngineBundle) {
    $EngineStage = Join-Path $OutputDir "mad-windows-x64"
    if (Test-Path $EngineStage) { Remove-Item -Recurse -Force $EngineStage }
    Copy-Engine $EngineStage
    $EngineZip = Join-Path $OutputDir "mad-windows-x64.zip"
    if (Test-Path $EngineZip) { Remove-Item -Force $EngineZip }
    Compress-Archive -Path (Join-Path $EngineStage "*") -DestinationPath $EngineZip
    Write-Checksum $EngineZip
    $engineSize = [math]::Round((Get-Item $EngineZip).Length / 1MB, 1)
    Write-Host "  ok   $EngineZip ($engineSize MB)"
}

Write-Host "### Done"
