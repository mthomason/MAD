#Requires -Version 7
<#
  Windows/Engine/toolchain/bootstrap.ps1

  Clones the pinned gnustep/tools-windows-msvc build driver, applies the two
  local patches (the STL gate override and the seven component revision pins),
  and builds the GNUstep toolchain from source into the configured prefix.

  This is the reproducible source of the toolchain.

  Idempotent: if the prefix already carries a built Release toolchain
  (bin/gnustep-config exists) it skips the clone and build, unless -Force.

  Must run from an elevated prompt: the driver installs into %PREFIX% (the
  default is C:\GNUstep, the drive root).
#>
[CmdletBinding()]
param(
	[string]$ToolchainDir = "",
	[string]$Prefix = "C:\GNUstep",
	[string]$Commit = "54d08e57414781f3ff41caa6eff265ca15e29724",
	[string]$CloneUrl = "https://github.com/gnustep/tools-windows-msvc.git",
	[string]$Msys2Shell = "C:\msys64\msys2_shell.cmd -defterm -no-start -msys2 -full-path -here -c",
	[string]$Vcvars64 = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat",
	[switch]$Force
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Read the canonical pins from toolchain.conf when they are not overridden, so
# the file stays the single place the recipe is written down.  The Clang version
# and the seven component revisions are also read here so the built toolchain
# can be verified against them (see Confirm-Toolchain below).
$Conf = Join-Path $PSScriptRoot "..\toolchain.conf"
$ConfClang = ""
$ConfPins = @{}
if (Test-Path $Conf) {
	$lines = Get-Content $Conf
	foreach ($line in $lines) {
		$t = $line.Trim()
		if ($t -match '^tools-windows-msvc\s*=\s*(\S+)') { $Commit = $Matches[1] }
		elseif ($t -match '^prefix\s*=\s*(\S+)') { $Prefix = $Matches[1] }
		elseif ($t -match '^clang\s*=\s*(\S+)') { $ConfClang = $Matches[1] }
		elseif ($t -match '^(libobjc2|libffi|libiconv|libdispatch|gnustep-make|gnustep-base|gnustep-corebase)\s*=\s*(\S+)') {
			$ConfPins[$Matches[1]] = $Matches[2]
		}
	}
}

if (-not $ToolchainDir) {
	# The clone is a build artifact; keep it inside the gitignored build dir.
	$ToolchainDir = Join-Path (Join-Path $PSScriptRoot "..\build") "toolchain"
}

$SrcDir = Join-Path $ToolchainDir "tools-windows-msvc"
$BuildBat = Join-Path $SrcDir "build.bat"
$Stamp = Join-Path $Prefix "x64\Release\bin\gnustep-config"
$BuildTxt = Join-Path $Prefix "x64\Release\build.txt"

# Verify the built toolchain against the pins in toolchain.conf.  The driver
# records the resolved component revisions (and the Clang version) in
# %PREFIX%\x64\Release\build.txt, so this is the check that the pinned recipe is
# what actually got built.  A mismatch means the on-disk toolchain predates or
# drifted from the current pins; rebuild with -Force.
function Confirm-Toolchain {
	if (-not (Test-Path $BuildTxt)) {
		throw "No build.txt at $BuildTxt; the toolchain was not built by this recipe. Rebuild with -Force."
	}
	$txt = Get-Content $BuildTxt -Raw
	if ($ConfClang -and ($txt -notmatch [regex]::Escape("clang version $ConfClang"))) {
		throw "Toolchain Clang mismatch: build.txt does not report $ConfClang (from toolchain.conf). Rebuild with -Force."
	}
	# Parse build.txt into component -> list of "Revision"/"Tag" values.
	$built = @{}
	$current = ""
	foreach ($line in (Get-Content $BuildTxt)) {
		if ($line -match '^\* (.+)$') { $current = $Matches[1].Trim() }
		elseif ($current -and $line -match '^\s*-\s*(?:Revision|Tag):\s*(\S+)') {
			if (-not $built.ContainsKey($current)) { $built[$current] = @() }
			$built[$current] += $Matches[1]
		}
	}
	foreach ($name in $ConfPins.Keys) {
		$want = $ConfPins[$name]
		if (-not $built.ContainsKey($name) -or ($built[$name] -notcontains $want)) {
			$got = if ($built.ContainsKey($name)) { $built[$name] -join ', ' } else { '(missing)' }
			throw "Toolchain pin mismatch for ${name}: expected $want, build.txt has $got. Rebuild with -Force."
		}
	}
	Write-Host "### Toolchain verified against toolchain.conf: Clang $ConfClang + the seven pins"
}

# --- Already built? ---------------------------------------------------------
if (-not $Force -and (Test-Path $Stamp)) {
	Confirm-Toolchain
	Write-Host "### GNUstep toolchain already present at $Prefix (use -Force to rebuild)."
	return
}

# --- Clone + pin + patch -----------------------------------------------------
if (-not (Test-Path (Join-Path $SrcDir ".git"))) {
	Write-Host "### Cloning tools-windows-msvc @ $Commit"
	New-Item -ItemType Directory -Force -Path $ToolchainDir | Out-Null
	git clone $CloneUrl $SrcDir
	if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
	git -C $SrcDir checkout $Commit
	if ($LASTEXITCODE -ne 0) { throw "git checkout $Commit failed" }
} else {
	# Reuse an existing clone but force it to the pinned commit.
	git -C $SrcDir fetch origin
	git -C $SrcDir checkout --force $Commit
	if ($LASTEXITCODE -ne 0) { throw "git checkout $Commit failed" }
}

# Apply the two patches (idempotent: git apply --check rejects an already-applied patch).
foreach ($patch in @("stl-gate-override.patch", "revision-pins.patch")) {
	$patchPath = Join-Path $PSScriptRoot $patch
	& git -C $SrcDir apply --check $patchPath 2>$null
	if ($LASTEXITCODE -eq 0) {
		& git -C $SrcDir apply $patchPath
		if ($LASTEXITCODE -ne 0) { throw "git apply $patch failed" }
		Write-Host "### Applied $patch"
	} else {
		Write-Host "### $patch already applied"
	}
}

# --- Build --------------------------------------------------------------------
# The driver requires the MSVC x64 developer environment and MSYS2's bash.  It
# must be invoked by absolute path from inside its own directory, without
# editing PATH (the vcvars64 PATH is ~2500 chars and breaks bare-name lookup).
$Wrapped = @"
@echo off
call "$Vcvars64" >nul
set "BASH=$Msys2Shell"
cd /d "$SrcDir"
call "$BuildBat" --type Release
exit /b %ERRORLEVEL%
"@
$WrapperPath = Join-Path $ToolchainDir "build-toolchain.cmd"
Set-Content -Path $WrapperPath -Value $Wrapped -Encoding Ascii

Write-Host "### Building GNUstep into $Prefix (this takes 20-30 minutes)"
& cmd.exe /c ('"{0}"' -f $WrapperPath)
if ($LASTEXITCODE -ne 0) { throw "toolchain build failed with exit code $LASTEXITCODE" }

if (-not (Test-Path $Stamp)) {
	throw "toolchain build reported success but $Stamp was not produced"
}
Confirm-Toolchain
Write-Host "### Toolchain built and verified: $Stamp"
