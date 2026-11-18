#Requires -Version 7
<#
  Windows/Engine/build.ps1 — the Windows engine build entry point.

  Reproduces the proven recipe (docs/project/MAD_WINDOWS.md) from the repo, not
  the scratch workspace:

    1. prerequisite check (Clang 20.1.8, lld, CMake, Ninja, MSYS2, git,
       Visual Studio 2026, the Windows SDK, NASM);
    2. idempotent toolchain bootstrap (toolchain/bootstrap.ps1: clone the
       pinned tools-windows-msvc, apply the STL-gate override and revision
       pins, build GNUstep from source into %Prefix%);
    3. compile MADDataStructures and MADFoundation (plus the Windows/Engine/
       Compat shims) and link the smoke test;
    4. run the smoke test and fail the build on any failure.

  The framework source lists are the cmake/*.cmake files (the canonical,
  CMake-ready inventory with exclusion reasons); this script reads them back,
  so the two cannot drift.

  Must run from an elevated prompt (the toolchain installs into %Prefix%, the
  default C:\GNUstep).  Run it from PowerShell:

      pwsh -File .\Windows\Engine\build.ps1

  Fast iteration after the toolchain is built (skip the bootstrap):

      pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain
#>
[CmdletBinding()]
param(
	[string]$Prefix = "C:\GNUstep",
	[switch]$SkipToolchain,
	[switch]$NoTest,
	[switch]$Clean
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$EngineDir = $PSScriptRoot
$RepoRoot = (Resolve-Path (Join-Path $EngineDir "..\..")).Path
$CompatDir = Join-Path $EngineDir "Compat"
$BuildDir = Join-Path $EngineDir "build"
$ObjDir = Join-Path $BuildDir "obj"
$ShimDir = Join-Path $BuildDir "shim"

$GsRelease = Join-Path $Prefix "x64\Release"
$GsInclude = Join-Path $GsRelease "include"
$GsLib = Join-Path $GsRelease "lib"
$GsBin = Join-Path $GsRelease "bin"

$StlOverride = "-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH"

# ---------------------------------------------------------------------------
# 1. Prerequisites
# ---------------------------------------------------------------------------
function Require([string]$name, [scriptblock]$check, [string]$hint) {
	if (& $check) {
		Write-Host "  ok   $name"
	} else {
		Write-Error "Prerequisite missing: $name — $hint"
	}
}

Write-Host "### Checking prerequisites"
Require "clang 20.1.8" { (clang --version 2>$null | Select-Object -First 1) -match '20\.1\.8' } `
	"install LLVM 20.1.8 (winget install -e --id LLVM.LLVM --version 20.1.8)"
Require "lld 20.1.8" { (lld-link --version 2>$null | Select-Object -First 1) -match '20\.1\.8' } `
	"lld ships with LLVM 20.1.8"
Require "cmake" { (cmake --version 2>$null | Select-Object -First 1) -match 'cmake version' } "install CMake"
Require "ninja" { $null -ne (ninja --version 2>$null) } "install Ninja"
Require "git" { $null -ne (git --version 2>$null) } "install Git for Windows"
Require "MSYS2" { Test-Path "C:\msys64\msys2_shell.cmd" } "install MSYS2 at C:\msys64"
Require "NASM" { Test-Path "C:\Program Files\NASM\nasm.exe" } "install NASM"
$vcvars = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
Require "Visual Studio 2026 (18.12.0)" { Test-Path $vcvars } "install Visual Studio 2026 Community (NativeDesktop)"
Require "Windows SDK 10.0.26100" { Test-Path "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0" } "install the Windows 10.0.26100 SDK"
if (-not (Test-Path (Join-Path $GsRelease "include"))) {
	Write-Warning "GNUstep toolchain not found at $GsRelease (the bootstrap will build it)."
}

# ---------------------------------------------------------------------------
# 2. Toolchain bootstrap (idempotent)
# ---------------------------------------------------------------------------
if (-not $SkipToolchain) {
	& (Join-Path $EngineDir "toolchain\bootstrap.ps1") -Prefix $Prefix
} else {
	Write-Host "### Skipping toolchain bootstrap (-SkipToolchain)"
}
if (-not (Test-Path (Join-Path $GsBin "gnustep-config"))) {
	throw "GNUstep toolchain not found at $GsRelease; run without -SkipToolchain."
}

# ---------------------------------------------------------------------------
# 3. Framework compile + link
# ---------------------------------------------------------------------------
if ($Clean) { Remove-Item -Recurse -Force $BuildDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $ObjDir | Out-Null
New-Item -ItemType Directory -Force -Path $ShimDir | Out-Null

# The GNUstep Objective-C flags (gnustep-config --objc-flags for the pinned
# toolchain).  Hardcoded because gnustep-config is a shell script on Windows;
# these are the exact flags the viability phase used.
$commonFlags = @(
	"-DGNUSTEP", "-DGNUSTEP_BASE_LIBRARY=1", "-DGNUSTEP_RUNTIME=1", "-D_NONFRAGILE_ABI=1",
	"-DGNUSTEP_WITH_DLL", "-fno-strict-aliasing", "-fexceptions", "-fobjc-exceptions",
	"-D_NATIVE_OBJC_EXCEPTIONS", "-pthread", "-Wno-microsoft-include", "-DGSWARN", "-DGSDIAGNOSE",
	"-Wno-import", "-m64", "-fobjc-runtime=gnustep-2.2", "-fblocks",
	"-fconstant-string-class=NSConstantString",
	"-I$GsInclude", "-I$CompatDir", "-I$ShimDir",
	"-include", "MADCompat.h",
	"-D__unused=__attribute__((unused))",
	"-Wno-format-security", "-Wno-unused-command-line-argument",
	"-g", "-O0"
)

# Include shims: <MADFoundation/Foo.h> and <MADDataStructures/Foo.h> resolve to
# the framework Source directories (the same shape the Linux build's symlinked
# shim provides; Windows junctions are the local equivalent).
function New-Shim([string]$framework, [string]$sourceDir) {
	$link = Join-Path $ShimDir $framework
	if (-not (Test-Path $link)) {
		New-Item -ItemType Junction -Path $link -Target $sourceDir | Out-Null
	}
}

# Read the file list out of a cmake/<Name>Sources.cmake list (the canonical
# source of truth).  The files are written as "${SOURCE_DIR}/Name.ext".
function Get-SourceFiles([string]$cmakeList) {
	$text = Get-Content $cmakeList -Raw
	$files = [regex]::Matches($text, '\$\{SOURCE_DIR\}/([A-Za-z0-9_+.]+\.(?:mm|m|c))') |
		ForEach-Object { $_.Groups[1].Value }
	return ,$files
}

# Compile one file; returns the object path.
function Compile-One([string]$src, [string]$obj, [string[]]$extra) {
	& clang @commonFlags @extra -c $src -o $obj 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "compile failed: $src" }
}

$allObjects = New-Object System.Collections.Generic.List[string]

# --- MADDataStructures ------------------------------------------------------
$dsSource = Join-Path $RepoRoot "MADDataStructures\Source"
New-Shim "MADDataStructures" $dsSource
Write-Host "### MADDataStructures"
foreach ($f in (Get-SourceFiles (Join-Path $EngineDir "cmake\MADDataStructuresSources.cmake"))) {
	$src = Join-Path $dsSource $f
	$obj = Join-Path $ObjDir ("ds_" + [IO.Path]::GetFileNameWithoutExtension($f) + ".obj")
	if ($f -like "*.mm") {
		if ($f -eq "MADVectorBool.mm") {
			Compile-One $src $obj @("-fno-objc-arc", "-std=gnu++20", $StlOverride)
		} else {
			Compile-One $src $obj @("-fobjc-arc", "-std=gnu++20", $StlOverride)
		}
	} else {
		Compile-One $src $obj @("-fobjc-arc")
	}
	$allObjects.Add($obj)
}

# --- MADFoundation ----------------------------------------------------------
$fdSource = Join-Path $RepoRoot "MADFoundation\Source"
New-Shim "MADFoundation" $fdSource
Write-Host "### MADFoundation"
foreach ($f in (Get-SourceFiles (Join-Path $EngineDir "cmake\MADFoundationSources.cmake"))) {
	$src = Join-Path $fdSource $f
	$obj = Join-Path $ObjDir ("fd_" + [IO.Path]::GetFileNameWithoutExtension($f) + ".obj")
	if ($f -eq "madlib.c") {
		# madlib.c uses #import; compile it as Objective-C, manual-retain-release.
		Compile-One $src $obj @("-x", "objective-c", "-fno-objc-arc")
	} else {
		Compile-One $src $obj @("-fobjc-arc")
	}
	$allObjects.Add($obj)
}

# --- Compat shims -----------------------------------------------------------
Write-Host "### Compat shims"
foreach ($m in (Get-ChildItem -Path $CompatDir -Filter *.m -File)) {
	$obj = Join-Path $ObjDir ("compat_" + $m.BaseName + ".obj")
	Compile-One $m.FullName $obj @("-fobjc-arc")
	$allObjects.Add($obj)
}

# --- Smoke test -------------------------------------------------------------
$smokeSrc = Join-Path $EngineDir "Tests\smoke.m"
$smokeObj = Join-Path $ObjDir "smoke.obj"
$smokeExe = Join-Path $BuildDir "smoke.exe"
Write-Host "### smoke test"
Compile-One $smokeSrc $smokeObj @("-fobjc-arc")
$allObjects.Add($smokeObj)

Write-Host "### linking smoke.exe"
& clang "-fuse-ld=lld" "-fexceptions" "-fobjc-runtime=gnustep-2.2" "-fblocks" "-m64" `
	"-L$GsLib" @allObjects `
	"-lgnustep-base" "-lobjc" "-ldispatch" `
	"-lws2_32" "-ladvapi32" "-lcomctl32" "-luser32" "-lcomdlg32" "-lmpr" "-lnetapi32" "-lkernel32" "-lshell32" "-lmsvcrt" "-lvcruntime" "-lucrt" `
	"-o" $smokeExe 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "link failed" }

# ---------------------------------------------------------------------------
# 4. Run the smoke test
# ---------------------------------------------------------------------------
if ($NoTest) {
	Write-Host "### Skipping test run (-NoTest)"
} else {
	Write-Host "### running smoke.exe"
	$oldPath = $env:PATH
	try {
		$env:PATH = "$GsBin;$oldPath"
		& $smokeExe
		$code = $LASTEXITCODE
	} finally {
		$env:PATH = $oldPath
	}
	Write-Host "SMOKE EXIT CODE = $code"
	if ($code -ne 0) { throw "smoke test failed (exit $code)" }
	Write-Host "### BUILD OK — 0 failures"
}
