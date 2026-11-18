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
    3. build the pinned SQLite amalgamation (download, verify sha256, extract,
       compile sqlite3.c with the Compressor/sqlite3.xcconfig option list, and
       archive it as libsqlite3.a) for MADSqlite3;
    4. compile MADDataStructures, MADFoundation, MADAPI (the transitive
       dependency MADSqlite3 pulls in) and MADSqlite3, plus the Windows/Engine/
       Compat shims;
    5. compile and link the smoke test and the ported test suites (GNUstep
       Testing.h + MADTestSupport.h), run every one, and fail the build on any
       failure.

  The framework source lists are the cmake/*.cmake files (the canonical,
  CMake-ready inventory with exclusion reasons); this script reads them back,
  so the two cannot drift.

  Must run from an elevated prompt (the toolchain installs into %Prefix%, the
  default C:\GNUstep).  Run it from PowerShell:

      pwsh -File .\Windows\Engine\build.ps1

  Fast iteration after the toolchain is built (skip the bootstrap):

      pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain

  Skip the test run (build + link only):

      pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain -NoTest
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
Require "curl" { $null -ne (curl.exe --version 2>$null) } "curl ships with Windows 11"
Require "tar" { $null -ne (tar --version 2>$null) } "tar ships with Windows 11"
Require "llvm-lib" { $null -ne (llvm-lib /? 2>$null) } "llvm-lib ships with LLVM 20.1.8"
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
# 3. Build directories + the C libraries (sqlite3)
# ---------------------------------------------------------------------------
if ($Clean) { Remove-Item -Recurse -Force $BuildDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $ObjDir | Out-Null
New-Item -ItemType Directory -Force -Path $ShimDir | Out-Null
$LibBuildDir = Join-Path $BuildDir "libs"
$Sqlite3Dir = Join-Path $LibBuildDir "sqlite3"
New-Item -ItemType Directory -Force -Path $LibBuildDir | Out-Null

# The Windows bsdtar, by absolute path: GNU tar (Git Bash's /usr/bin/tar, when
# this script runs under Git Bash) reads a "C:\..." path as a remote host.
$TarExe = Join-Path $env:SystemRoot "System32\tar.exe"

# Read a pin out of libraries.conf (the same shape as Linux/libraries.conf).
function Get-LibraryPin([string]$name) {
	foreach ($line in (Get-Content (Join-Path $EngineDir "libraries.conf"))) {
		$t = $line.Trim()
		if ($t -eq "" -or $t.StartsWith("#") -or $t.StartsWith("name")) { continue }
		$parts = $t -split '\s+'
		if ($parts.Count -ge 6 -and $parts[0] -eq $name) {
			return @{ name = $parts[0]; version = $parts[1]; ref = $parts[2]; commit = $parts[3]; sha256 = $parts[4]; url = $parts[5] }
		}
	}
	throw "library pin not found: $name"
}

# The SQLITE_DEFINES line from Compressor/sqlite3.xcconfig, bare macro names
# turned into -D flags, exactly as Linux/lib/libraries.sh does.  That file is
# still the one place the format-deciding flags are written down.
function Get-Sqlite3Defines {
	$xcconfig = Join-Path $RepoRoot "Compressor\sqlite3.xcconfig"
	$line = (Get-Content $xcconfig) | Where-Object { $_ -match '^SQLITE_DEFINES\s*=' } | Select-Object -First 1
	if (-not $line) { throw "no SQLITE_DEFINES line in $xcconfig" }
	$rhs = ($line -split '=', 2)[1].Trim()
	$defines = @($rhs -split '\s+' | Where-Object { $_ }) | ForEach-Object { "-D$_" }
	return ,$defines
}

Write-Host "### sqlite3 library"
$sqlitePin = Get-LibraryPin "sqlite3"
$primaryUrl = ($sqlitePin.url -split ',')[0]
$sqliteArchiveName = ($primaryUrl -split '/')[-1]
$sqliteArchive = Join-Path $LibBuildDir $sqliteArchiveName

if ((Test-Path $sqliteArchive) -and ((Get-FileHash $sqliteArchive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $sqlitePin.sha256)) {
	Write-Host "  ok   $sqliteArchiveName (cached, sha256 verified)"
} else {
	Write-Host "  downloading $sqliteArchiveName"
	$downloaded = $false
	foreach ($u in ($sqlitePin.url -split ',')) {
		& curl.exe -L --fail -o $sqliteArchive $u 2>&1 | ForEach-Object { Write-Host "    $_" }
		if ($LASTEXITCODE -eq 0) { $downloaded = $true; break }
	}
	if (-not $downloaded) { throw "sqlite3 download failed" }
}
$actual = (Get-FileHash $sqliteArchive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $sqlitePin.sha256) {
	throw "sqlite3 sha256 mismatch: expected $($sqlitePin.sha256), got $actual"
}
Write-Host "  ok   sqlite3 $($sqlitePin.version) (sha256 $($sqlitePin.sha256.Substring(0,8))…)"

$sqlite3c = Join-Path $Sqlite3Dir "sqlite3.c"
if (-not (Test-Path $sqlite3c)) {
	New-Item -ItemType Directory -Force -Path $Sqlite3Dir | Out-Null
	& $TarExe -xzf $sqliteArchive -C $Sqlite3Dir --strip-components=1
	if ($LASTEXITCODE -ne 0) { throw "sqlite3 extract failed" }
}

$sqliteObj = Join-Path $Sqlite3Dir "sqlite3.obj"
$sqliteLib = Join-Path $Sqlite3Dir "sqlite3.lib"
if (-not (Test-Path $sqliteLib)) {
	$sqliteFlags = @("-O2", "-DSQLITE_THREADSAFE=1") + (Get-Sqlite3Defines)
	& clang @sqliteFlags -c $sqlite3c -o $sqliteObj 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "sqlite3 compile failed" }
	# A COFF archive (the Windows static-library format), not a GNU ar archive:
	# lld-link reads COFF .lib members on demand but does not resolve symbols
	# out of a GNU ar .a built from a COFF object.
	& llvm-lib /out:$sqliteLib $sqliteObj 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "sqlite3 archive failed" }
	Write-Host "  ok   sqlite3.lib built"
} else {
	Write-Host "  ok   sqlite3.lib (cached)"
}

# The framework imports the SQLite header as <MADSqlite3/sqlite3.h> (the Xcode
# target keeps it Public).  The Linux build symlinks the installed header under
# that name; the Windows equivalent is a second include shim beside the
# framework self-import junction.
$Sqlite3ShimDir = Join-Path $BuildDir "sqlite3-shim"
$sqlite3HeaderShim = Join-Path $Sqlite3ShimDir "MADSqlite3\sqlite3.h"
if (-not (Test-Path $sqlite3HeaderShim)) {
	New-Item -ItemType Directory -Force -Path (Join-Path $Sqlite3ShimDir "MADSqlite3") | Out-Null
	Copy-Item (Join-Path $Sqlite3Dir "sqlite3.h") $sqlite3HeaderShim
}

# ---------------------------------------------------------------------------
# 3b. The archive stack: zlib, bzip2 and libarchive (the .mad container).
#     Mirrors Linux/lib/libraries.sh and Compressor's recipes, but built the way
#     the Windows build builds everything else -- direct clang for the two leaf
#     libraries, and CMake + clang-cl for libarchive (whose config.h is the
#     product of its feature checks).  libarchive links zlib and bzip2.
# ---------------------------------------------------------------------------

# Download + verify (sha256) + extract one pinned archive library; echoes the
# extracted source directory.  Cached: a verified archive is not re-downloaded,
# and an extracted tree is not re-extracted.
function Get-LibrarySource([string]$name, [hashtable]$pin) {
	$primaryUrl = ($pin.url -split ',')[0]
	$archiveName = ($primaryUrl -split '/')[-1]
	$archive = Join-Path $LibBuildDir $archiveName
	if ((Test-Path $archive) -and ((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $pin.sha256)) {
		Write-Host "  ok   $archiveName (cached, sha256 verified)"
	} else {
		Write-Host "  downloading $archiveName"
		$downloaded = $false
		foreach ($u in ($pin.url -split ',')) {
			& curl.exe -L --fail -o $archive $u 2>&1 | ForEach-Object { Write-Host "    $_" }
			if ($LASTEXITCODE -eq 0) { $downloaded = $true; break }
		}
		if (-not $downloaded) { throw "$name download failed" }
	}
	$actual = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
	if ($actual -ne $pin.sha256) {
		throw "$name sha256 mismatch: expected $($pin.sha256), got $actual"
	}
	$dir = Join-Path $LibBuildDir $name
	if (-not (Test-Path (Join-Path $dir ".extracted"))) {
		New-Item -ItemType Directory -Force -Path $dir | Out-Null
		& $TarExe -xzf $archive -C $dir --strip-components=1
		if ($LASTEXITCODE -ne 0) { throw "$name extract failed" }
		New-Item -ItemType File -Force -Path (Join-Path $dir ".extracted") | Out-Null
	}
	Write-Host "  ok   $name $($pin.version) (sha256 $($pin.sha256.Substring(0,8))…)"
	return $dir
}

# zlib 1.3.2 -- the leaf the pax/zip formats reach for.  Its sources are
# self-contained and portable; the Compressor recipe's -O3 is the flag here.
$zlibDir = Get-LibrarySource "zlib" (Get-LibraryPin "zlib")
$zlibObjDir = Join-Path $zlibDir "obj"
$zlibLib = Join-Path $zlibDir "zlib.lib"
if (-not (Test-Path $zlibLib)) {
	New-Item -ItemType Directory -Force -Path $zlibObjDir | Out-Null
	$zlibSources = @("adler32.c","compress.c","crc32.c","deflate.c","gzclose.c","gzlib.c","gzread.c","gzwrite.c","infback.c","inffast.c","inflate.c","inftrees.c","trees.c","uncompr.c","zutil.c")
	$zlibObjs = @()
	foreach ($s in $zlibSources) {
		$obj = Join-Path $zlibObjDir ($s -replace '\.c$', '.obj')
		& clang -O3 -DNDEBUG "-I$zlibDir" -c (Join-Path $zlibDir $s) -o $obj 2>&1 | ForEach-Object { Write-Host $_ }
		if ($LASTEXITCODE -ne 0) { throw "zlib compile failed: $s" }
		$zlibObjs += $obj
	}
	& llvm-lib /out:$zlibLib $zlibObjs 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "zlib archive failed" }
	Write-Host "  ok   zlib.lib built"
} else {
	Write-Host "  ok   zlib.lib (cached)"
}

# bzip2 1.0.8 -- the .mad container's compression filter.  Library files only
# (the bzip2/bzip2recover tools are not built).
$bzip2Dir = Get-LibrarySource "bzip2" (Get-LibraryPin "bzip2")
$bzip2ObjDir = Join-Path $bzip2Dir "obj"
$bzip2Lib = Join-Path $bzip2Dir "bzip2.lib"
if (-not (Test-Path $bzip2Lib)) {
	New-Item -ItemType Directory -Force -Path $bzip2ObjDir | Out-Null
	$bzip2Sources = @("blocksort.c","huffman.c","crctable.c","randtable.c","compress.c","decompress.c","bzlib.c")
	$bzip2Objs = @()
	foreach ($s in $bzip2Sources) {
		$obj = Join-Path $bzip2ObjDir ($s -replace '\.c$', '.obj')
		& clang -O3 -DNDEBUG -Wno-deprecated-declarations "-I$bzip2Dir" -c (Join-Path $bzip2Dir $s) -o $obj 2>&1 | ForEach-Object { Write-Host $_ }
		if ($LASTEXITCODE -ne 0) { throw "bzip2 compile failed: $s" }
		$bzip2Objs += $obj
	}
	& llvm-lib /out:$bzip2Lib $bzip2Objs 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "bzip2 archive failed" }
	Write-Host "  ok   bzip2.lib built"
} else {
	Write-Host "  ok   bzip2.lib (cached)"
}

# libarchive 3.8.9 -- the reader/writer behind MADArchiveManager/madtar.m.  CMake
# (not autotools) is libarchive's Windows path, and its config.h is the output of
# the feature checks, so this is the one library built through CMake + clang-cl
# rather than direct clang.  Same feature set as Linux/Compressor: zlib + bzip2
# in, xml2/lzma/zstd/lz4/openssl out, the tools (tar/cpio/cat) not built.
$libarchiveDir = Get-LibrarySource "libarchive" (Get-LibraryPin "libarchive")
# The CMake binary dir lives OUTSIDE the source tree: libarchive's own source
# carries a `build/` directory (with the `version` file its CMakeLists reads),
# so a `build` dir beside it would collide with the sources.
$libarchiveBuild = Join-Path $BuildDir "libarchive-cmake"
$libarchiveLib = Join-Path $libarchiveBuild "libarchive\archive.lib"
$LibArchiveInclude = Join-Path $libarchiveDir "libarchive"
if (-not (Test-Path $libarchiveLib)) {
	Write-Host "  configuring libarchive (cmake + clang-cl; the feature checks take a few minutes)"
	# cmake treats a backslash in a -D value as an escape, so the Windows paths
	# are handed over with forward slashes (cmake accepts both on Windows).
	$laSource = $libarchiveDir -replace '\\', '/'
	$laBuild = $libarchiveBuild -replace '\\', '/'
	$zlibLibFwd = $zlibLib -replace '\\', '/'
	$zlibDirFwd = $zlibDir -replace '\\', '/'
	$bzip2LibFwd = $bzip2Lib -replace '\\', '/'
	$bzip2DirFwd = $bzip2Dir -replace '\\', '/'
	& cmake -S $laSource -B $laBuild -G Ninja `
		"-DCMAKE_C_COMPILER=clang-cl" "-DCMAKE_BUILD_TYPE=Release" `
		"-DENABLE_ZLIB=ON" "-DZLIB_LIBRARY=$zlibLibFwd" "-DZLIB_INCLUDE_DIR=$zlibDirFwd" `
		"-DENABLE_BZip2=ON" "-DBZIP2_LIBRARY_RELEASE=$bzip2LibFwd" "-DBZIP2_INCLUDE_DIR=$bzip2DirFwd" `
		"-DENABLE_LIBXML2=OFF" "-DENABLE_LZMA=OFF" "-DENABLE_ZSTD=OFF" "-DENABLE_LZ4=OFF" `
		"-DENABLE_OPENSSL=OFF" "-DBUILD_TESTING=OFF" "-DBUILD_SHARED_LIBS=OFF" `
		"-DENABLE_TAR=OFF" "-DENABLE_CPIO=OFF" "-DENABLE_CAT=OFF" "-DENABLE_WERROR=OFF" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "libarchive configure failed" }
	& cmake --build $laBuild --target archive_static 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "libarchive build failed" }
	Write-Host "  ok   libarchive.lib built"
} else {
	Write-Host "  ok   libarchive.lib (cached)"
}

# ---------------------------------------------------------------------------
# 4. Framework compile
# ---------------------------------------------------------------------------

# The GNUstep Objective-C flags (gnustep-config --objc-flags for the pinned
# toolchain).  Hardcoded because gnustep-config is a shell script on Windows;
# these are the exact flags the viability phase used.
$commonFlags = @(
	"-DGNUSTEP", "-DGNUSTEP_BASE_LIBRARY=1", "-DGNUSTEP_RUNTIME=1", "-D_NONFRAGILE_ABI=1",
	"-DGNUSTEP_WITH_DLL", "-fno-strict-aliasing", "-fexceptions", "-fobjc-exceptions",
	"-D_NATIVE_OBJC_EXCEPTIONS", "-pthread", "-Wno-microsoft-include", "-DGSWARN", "-DGSDIAGNOSE",
	"-DDEBUG=1",
	"-Wno-import", "-m64", "-fobjc-runtime=gnustep-2.2", "-fblocks",
	"-fconstant-string-class=NSConstantString",
	"-I$CompatDir", "-I$ShimDir", "-I$Sqlite3ShimDir", "-I$GsInclude",
	"-include", "MADCompat.h",
	"-D__unused=__attribute__((unused))",
	"-Wno-format-security", "-Wno-unused-command-line-argument",
	"-g", "-O0"
)

# Include shims: <MADFoundation/Foo.h> and <MADDataStructures/Foo.h> resolve to
# the framework Source directories (the same shape the Linux build's symlinked
# shim provides; Windows junctions are the local equivalent).  MAD is special:
# its Xcode target flattens its headers as <MAD/Foo.h> across several
# subdirectories, so its shim is a directory of copies rather than one junction.
function New-Shim([string]$framework, [string]$sourceDir) {
	$link = Join-Path $ShimDir $framework
	if (-not (Test-Path $link)) {
		if ($framework -eq "MAD") {
			New-Item -ItemType Directory -Force -Path $link | Out-Null
			foreach ($d in @("$sourceDir", "$sourceDir\model", "$sourceDir\rptq",
							 "$sourceDir\rptq\autogen", "$sourceDir\rptq\store",
							 "$sourceDir\sql", "$sourceDir\paper")) {
				if (Test-Path $d) {
					Get-ChildItem -Path $d -Filter *.h -File | ForEach-Object {
						Copy-Item $_.FullName (Join-Path $link $_.Name)
					}
				}
			}
		} else {
			New-Item -ItemType Junction -Path $link -Target $sourceDir | Out-Null
		}
	}
}

# Read the file list out of a cmake/<Name>Sources.cmake list (the canonical
# source of truth).  The files are written as "${SOURCE_DIR}/Name.ext", and
# MAD's carry a subdirectory ("${SOURCE_DIR}/model/MADModel.m"), so the match
# keeps the whole relative path (subdirectories included).
function Get-SourceFiles([string]$cmakeList) {
	$text = Get-Content $cmakeList -Raw
	$files = [regex]::Matches($text, '\$\{SOURCE_DIR\}/([A-Za-z0-9_+./]+\.(?:mm|m|c))') |
		ForEach-Object { $_.Groups[1].Value }
	return ,$files
}

# Compile one file; returns the object path via the caller.  A source that is
# older than its object is skipped (fast iteration; -Clean forces a full pass).
function Compile-One([string]$src, [string]$obj, [string[]]$extra) {
	if ((Test-Path $obj) -and ((Get-Item $src).LastWriteTime -le (Get-Item $obj).LastWriteTime)) {
		return
	}
	& clang @commonFlags @extra -c $src -o $obj 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "compile failed: $src" }
}

$allObjects = New-Object System.Collections.Generic.List[string]

# Compile one framework's source list.  $flagsFor maps a file name to the
# per-file flags (dialect + ARC/MRC); the same per-file knowledge the Linux
# build carries in set_source_files_properties beside each mad_add_framework.
function Compile-FrameworkSources([string]$name, [string]$prefix, [string]$sourceDir, [string]$cmakeList, [scriptblock]$flagsFor) {
	Write-Host "### $name"
	New-Shim $name $sourceDir
	foreach ($f in (Get-SourceFiles $cmakeList)) {
		$src = Join-Path $sourceDir $f
		# The object name is the relative path with the separators flattened, so
		# MAD's subdirectory files ("model/MADModel.m") cannot collide.
		$leaf = $f -replace '[/\\]', '_'
		$obj = Join-Path $ObjDir ($prefix + [IO.Path]::GetFileNameWithoutExtension($leaf) + ".obj")
		$extra = @(& $flagsFor $f)
		Compile-One $src $obj $extra
		$script:allObjects.Add($obj)
	}
}

$dsSource = Join-Path $RepoRoot "MADDataStructures\Source"
$fdSource = Join-Path $RepoRoot "MADFoundation\Source"
$apiSource = Join-Path $RepoRoot "MADAPI\Source"
$sqlite3Source = Join-Path $RepoRoot "MADSqlite3\Source"
$cocoSource = Join-Path $RepoRoot "MADCocoaExtensions\Source"
$fmSource = Join-Path $RepoRoot "MADFileManager\Source"
$madSource = Join-Path $RepoRoot "MAD\Source"

$dsFlags = {
	param($f)
	if ($f -like "*.mm") {
		if ($f -eq "MADVectorBool.mm") { return @("-fno-objc-arc", "-std=gnu++20", $StlOverride) }
		return @("-fobjc-arc", "-std=gnu++20", $StlOverride)
	}
	return @("-fobjc-arc")
}

$fdFlags = {
	param($f)
	if ($f -eq "madlib.c") {
		# madlib.c uses #import; compile it as Objective-C, manual-retain-release.
		return @("-x", "objective-c", "-fno-objc-arc")
	}
	return @("-fobjc-arc")
}

$arcFlags = { param($f) return @("-fobjc-arc") }

Compile-FrameworkSources "MADDataStructures" "ds_" $dsSource (Join-Path $EngineDir "cmake\MADDataStructuresSources.cmake") $dsFlags
Compile-FrameworkSources "MADFoundation" "fd_" $fdSource (Join-Path $EngineDir "cmake\MADFoundationSources.cmake") $fdFlags
Compile-FrameworkSources "MADAPI" "api_" $apiSource (Join-Path $EngineDir "cmake\MADAPISources.cmake") $arcFlags
Compile-FrameworkSources "MADSqlite3" "sql_" $sqlite3Source (Join-Path $EngineDir "cmake\MADSqlite3Sources.cmake") $arcFlags
Compile-FrameworkSources "MADCocoaExtensions" "coco_" $cocoSource (Join-Path $EngineDir "cmake\MADCocoaExtensionsSources.cmake") $arcFlags
Compile-FrameworkSources "MADFileManager" "fm_" $fmSource (Join-Path $EngineDir "cmake\MADFileManagerSources.cmake") $arcFlags

# MAD compiles last: its quoted imports reach across its subdirectories (the way
# the Xcode target's header search paths do), and madtar.m reaches the libarchive
# headers.  The include dirs are per-file here, not global, so they do not shadow
# the other frameworks' headers.
# madtar.h imports <libxml2/libxml/list.h>; GNUstep bundles libxml2 under its
# include dir, and the libxml header's own <libxml/xmlversion.h> resolves once
# the libxml2 directory is on the include path (the Linux build's -I/usr/include/libxml2).
# MADStore.m imports <sqlite3.h> bare, so the extracted amalgamation's directory
# is on the path too (the Linux build's -I/usr/local/include).
$madIncludeDirs = @("$madSource", "$madSource\model", "$madSource\rptq",
					"$madSource\rptq\autogen", "$madSource\rptq\store",
					"$madSource\sql", "$madSource\paper", $LibArchiveInclude,
					(Join-Path $GsInclude "libxml2"), $Sqlite3Dir)
$madFlags = {
	param($f)
	if ($f -eq "madmath.c") {
		# Pure C (no #import); no ARC flag, but it still gets the prelude's C parts.
		return @()
	}
	$flags = @("-fobjc-arc", "-DLIBARCHIVE_STATIC")
	foreach ($d in $script:madIncludeDirs) { $flags += "-I$d" }
	return $flags
}
Compile-FrameworkSources "MAD" "mad_" $madSource (Join-Path $EngineDir "cmake\MADSources.cmake") $madFlags

# --- Compat shims -----------------------------------------------------------
Write-Host "### Compat shims"
foreach ($m in (Get-ChildItem -Path $CompatDir -Filter *.m -File)) {
	$obj = Join-Path $ObjDir ("compat_" + $m.BaseName + ".obj")
	Compile-One $m.FullName $obj @("-fobjc-arc")
	$allObjects.Add($obj)
}

# ---------------------------------------------------------------------------
# 5. Test compile + link
# ---------------------------------------------------------------------------
$TestingInclude = Join-Path $GsRelease "share\GNUstep\Makefiles\TestFramework"
if (-not (Test-Path (Join-Path $TestingInclude "Testing.h"))) {
	throw "Testing.h not found under $TestingInclude"
}
$TestsSupportDir = Join-Path $EngineDir "Tests\Support"
$TestExeDir = Join-Path $BuildDir "tests"
New-Item -ItemType Directory -Force -Path $TestExeDir | Out-Null

$linkLibs = @(
	"-lgnustep-base", "-lobjc", "-ldispatch",
	"-lws2_32", "-ladvapi32", "-lcomctl32", "-luser32", "-lcomdlg32", "-lmpr", "-lnetapi32",
	"-lkernel32", "-lshell32", "-lmsvcrt", "-lvcruntime", "-lucrt", "-lpsapi",
	"-lole32", "-lxmllite"
)

# The static C libraries, in link order: the framework objects come first, then
# the archive stack.  libarchive references zlib and bzip2, so it precedes them.
$archiveLibs = @($sqliteLib, $libarchiveLib, $zlibLib, $bzip2Lib)

# The ported Linux test suites (Linux/Tests), one executable per file.  Tests
# are manual-retain-release (GNUstep's Testing.h is MRC) while the frameworks
# stay ARC, exactly as on Linux.  BDHostTests is not here: BDHost.m is excluded
# on Windows (see cmake/MADFoundationSources.cmake), so its suite cannot link;
# the gap is recorded rather than silently skipped.
$testNames = @(
	# MADDataStructures
	"MADDataStructuresTests", "MADMapStringsTests", "MADVectorBoolTests",
	"MTGraphTests", "MTLinkedListTests", "MTQueueTests", "MTStackTests",
	# MADFoundation
	"madlogTests", "MADProgressTests", "MADStringUtilitiesTests",
	"NSDataComparisonTests", "NSStringComparisonTests", "MADDataTypeTests",
	"MADBlockOperationTests", "MADGroupOperationTests", "MADOperationQueueTests",
	"MADNotificationProgressTests", "MADExclusivityControllerTests", "MADOperationTests",
	"MADOperationConditionTests", "MADOperationConditionResultTests", "MADDataColumnTests",
	"MADCredentialTests", "MADApplicationTests", "MADBlockObserverTests",
	"MADDataTableBaseTests", "MADDataTableVirtualTests", "MADOperationBooleanAndTests",
	"MADURLFactoryTests", "NSOperationAdvancedTests", "madlibTests",
	# MADSqlite3
	"MADDatabaseSqlite3BindingTests", "MADDatabaseSqlite3DatabaseTests",
	"MADDatabaseSqlite3ResultValueTests", "MADDatabaseSqlite3Tests",
	"MADDataTableFastBenchmarkTests", "MADDataTableFastSelectTests",
	# MADFileManager
	"MADAppStorageOptionTests", "MADDirectoryMonitorTests",
	"MADFileInfoTests", "MADFileUtilitiesTests",
	"MADLocalFileCoordinatorTests", "MADMetaDataTests", "MADStorageStateTests",
	# MADCocoaExtensions
	"MADBorderStyleTests", "MADDirectionTests", "MADGeometryExtrasTests",
	"MADMarginTests", "MADMathAlgebraTests", "MADPaddingTests",
	"MADTextStyleTests", "MTMathTests", "NSNumberFormatterExtensionsTests",
	# MADAPI
	"MADAPIEnumsAndConstantsTests", "MADDatabaseDriverRegistryTests",
	"MADDatabaseConnectionTests", "MADDatabaseDataBindingTests",
	"MADDatabaseFieldTests", "MADDatabaseTableTests", "MADDatabaseTests",
	"MADErrorContainerTests", "MADNotificationDidReadRowsTests", "MADQueryTests",
	# MAD.  Four of the Linux MAD suites are deferred to Phase 3b with the
	# drivers: MADDatabaseDriverDispatchTests, MADQueryFullTests and
	# MADSQLParserTests each import and instantiate MADMySQL/MADTdsClient/
	# MADPostgres, whose frameworks (and the live fixtures) Phase 3a does not
	# build, and MADQueryMaxFieldLengthTests dispatches MADDatabaseTypeMySQL
	# through the constructor (no driver is registered).  The gap is recorded
	# here rather than silently skipped, exactly as BDHostTests is above.
	"MADArchiveManagerTests", "MADCoreLogicTests",
	"MADHeadlessDocumentTests", "MADDataTableRegressionTests",
	"MADDesignerQueryTests", "MADDesignerViewerTests",
	"MADDocumentObjectDataReferenceTests", "MADDocumentObjectDataReferenceAggregateTests",
	"MADDocumentObjectDataReferenceImageTests", "MADDocumentObjectDataReferenceLabelDynamicTests",
	"MADDocumentObjectDataReferenceLabelStaticTests", "MADFontTests",
	"MADLegacyStoreConversionTests", "MADModelQueryFieldTests", "MADModelQueryTableTests",
	"MADNotificationAndOperationTests", "MADOperationHoldsProtocolsTests",
	"MADPageOptionsTests", "MADQueryCacheAggregateFunctionTests", "MADQueryDefinitionTests",
	"MADSQLQueryCompilerTests",
	"MADQueryPredicateTests", "MADQuerySampleDataTests", "MADQuerySelectExpressionTests",
	"MADQueryTestTests", "MADQueryFullTableEnumeratorTests",
	"MADQuerySimpleTypesTests", "MADReportExporterTests", "MADReportSectionEnumeratorTests",
	"MADReportSectionRepresentationTests", "MADReportSectionTests", "MADRptqDatabaseTests",
	"MADRptqDocumentSectionTests", "MADRptqQueryTests", "MADRptqValueTypeTests",
	"MADSchemaFieldSelectorModelTests", "MADStoreTests", "MADStoreMigrationTests",
	"RptqDataHelperTests", "RptqDocumentElementFormulaTests", "RptqDocumentElementGroupKeyTests",
	"RptqDocumentElementLabelLinkTests", "RptqDocumentSectionEnumeratorTests", "RptqStoreContextTests"
)

$testExes = New-Object System.Collections.Generic.List[string]
foreach ($name in $testNames) {
	$src = Join-Path $EngineDir ("Tests\" + $name + ".m")
	$obj = Join-Path $ObjDir ("test_" + $name + ".obj")
	$exe = Join-Path $TestExeDir ($name + ".exe")
	Write-Host "### test $name"
	Compile-One $src $obj @("-fno-objc-arc", "-I$TestingInclude", "-I$TestsSupportDir", "-I$Sqlite3Dir")
	Write-Host "  linking $name.exe"
	& clang "-fuse-ld=lld" "-fexceptions" "-fobjc-runtime=gnustep-2.2" "-fblocks" "-m64" `
		"-L$GsLib" @allObjects $obj @archiveLibs @linkLibs `
		"-o" $exe 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "link failed: $name" }
	$testExes.Add($exe)
}

# --- Smoke test -------------------------------------------------------------
$smokeSrc = Join-Path $EngineDir "Tests\smoke.m"
$smokeObj = Join-Path $ObjDir "smoke.obj"
$smokeExe = Join-Path $BuildDir "smoke.exe"
Write-Host "### smoke test"
Compile-One $smokeSrc $smokeObj @("-fobjc-arc")
Write-Host "### linking smoke.exe"
& clang "-fuse-ld=lld" "-fexceptions" "-fobjc-runtime=gnustep-2.2" "-fblocks" "-m64" `
	"-L$GsLib" @allObjects $smokeObj @archiveLibs @linkLibs `
	"-o" $smokeExe 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "link failed" }

# ---------------------------------------------------------------------------
# 5b. The CLI (mad.exe) -- CLI/Source, linked whole against every framework.
#     The same ten sources Linux/CMakeLists.txt builds as `mad-cli`, plus the
#     sqlite3 header include (MADCLIInspect.m imports <sqlite3.h>).
# ---------------------------------------------------------------------------
Write-Host "### CLI (mad.exe)"
$cliSourceDir = Join-Path $RepoRoot "CLI\Source"
$cliFlags = @("-fobjc-arc", "-I$cliSourceDir", "-I$Sqlite3Dir")
$cliObjects = New-Object System.Collections.Generic.List[string]
foreach ($f in (Get-ChildItem -Path $cliSourceDir -Filter *.m -File | Sort-Object Name)) {
	$obj = Join-Path $ObjDir ("cli_" + $f.BaseName + ".obj")
	Compile-One $f.FullName $obj $cliFlags
	$cliObjects.Add($obj)
}
$madExe = Join-Path $BuildDir "mad.exe"
Write-Host "### linking mad.exe"
& clang "-fuse-ld=lld" "-fexceptions" "-fobjc-runtime=gnustep-2.2" "-fblocks" "-m64" `
	"-L$GsLib" @allObjects @cliObjects @archiveLibs @linkLibs `
	"-o" $madExe 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "link failed: mad.exe" }

# ---------------------------------------------------------------------------
# 6. Run every test (and the smoke test)
# ---------------------------------------------------------------------------
$failed = 0
if ($NoTest) {
	Write-Host "### Skipping test run (-NoTest)"
} else {
	Write-Host "### running tests"
	$oldPath = $env:PATH
	try {
		$env:PATH = "$GsBin;$oldPath"

		Write-Host "--- smoke.exe"
		& $smokeExe
		$code = $LASTEXITCODE
		Write-Host "SMOKE EXIT CODE = $code"
		if ($code -ne 0) { $failed++ }

		foreach ($exe in $testExes) {
			$leaf = Split-Path $exe -Leaf
			Write-Host "--- $leaf"
			& $exe
			$code = $LASTEXITCODE
			Write-Host "TEST $leaf EXIT CODE = $code"
			if ($code -ne 0) { $failed++ }
		}
	} finally {
		$env:PATH = $oldPath
	}
}

if ($failed -gt 0) {
	Write-Host "### BUILD FAILED — $failed executable(s) failed"
	exit 1
}
Write-Host "### BUILD OK — $($testExes.Count + 1) executable(s), 0 failures"
