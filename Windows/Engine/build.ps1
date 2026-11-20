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
	[switch]$Clean,
	[switch]$LibrariesOnly
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
Require "meson (PostgreSQL 17 libpq)" { Test-Path "C:\Program Files\Meson\meson.exe" } "install Meson (winget install Meson.Meson)"
Require "Strawberry Perl 5.42 (OpenSSL Configure)" { Test-Path "C:\Strawberry\perl\bin\perl.exe" } "install Strawberry Perl (winget install StrawberryPerl.StrawberryPerl)"
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

# libpng 1.6.59 and zint 2.16.0 -- the barcode stack MADBarcodes links.  libpng
# is built through CMake with clang-cl (its pnglibconf.h is generated from the
# feature checks, the same reason libarchive is); zint is the pinned 2.16.0
# recipe's option set, with the libpng just built.  Static only: both are linked
# into mad.exe, nothing is installed.
$libpngDir = Get-LibrarySource "libpng" (Get-LibraryPin "libpng")
$libpngBuild = Join-Path $BuildDir "libpng-cmake"
$libpngInstall = Join-Path $BuildDir "libpng-install"
$libpngInclude = Join-Path $libpngInstall "include"
$libpngLib = Join-Path $libpngInstall "lib\libpng16_static.lib"
if (-not (Test-Path $libpngLib)) {
	Write-Host "  configuring libpng (cmake + clang-cl; static)"
	$lpSource = $libpngDir -replace '\\', '/'
	$lpBuild = $libpngBuild -replace '\\', '/'
	$lpInstall = $libpngInstall -replace '\\', '/'
	$zlibLibFwd = $zlibLib -replace '\\', '/'
	$zlibDirFwd = $zlibDir -replace '\\', '/'
	& cmake -S $lpSource -B $lpBuild -G Ninja `
		"-DCMAKE_POLICY_VERSION_MINIMUM=3.5" `
		"-DCMAKE_C_COMPILER=clang-cl" "-DCMAKE_BUILD_TYPE=Release" `
		"-DPNG_SHARED=OFF" "-DPNG_STATIC=ON" "-DPNG_TESTS=OFF" "-DPNG_TOOLS=OFF" `
		"-DZLIB_LIBRARY=$zlibLibFwd" "-DZLIB_INCLUDE_DIR=$zlibDirFwd" `
		"-DCMAKE_INSTALL_PREFIX=$lpInstall" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "libpng configure failed" }
	& cmake --build $lpBuild --target png_static 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "libpng build failed" }
	& cmake --install $lpBuild 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "libpng install failed" }
	if (-not (Test-Path $libpngLib)) { throw "libpng16_static.lib not installed at $libpngLib" }
	Write-Host "  ok   libpng.lib built"
} else {
	Write-Host "  ok   libpng.lib (cached)"
}

$zintDir = Get-LibrarySource "zint" (Get-LibraryPin "zint")
$zintBuild = Join-Path $BuildDir "zint-cmake"
$zintInstall = Join-Path $BuildDir "zint-install"
$zintInclude = Join-Path $zintInstall "include"
$zintLib = Join-Path $zintInstall "lib\zint-static.lib"
if (-not (Test-Path $zintLib)) {
	Write-Host "  configuring zint (cmake + clang-cl; static, PNG output)"
	$znSource = $zintDir -replace '\\', '/'
	$znBuild = $zintBuild -replace '\\', '/'
	$znInstall = $zintInstall -replace '\\', '/'
	$libpngLibFwd = $libpngLib -replace '\\', '/'
	$libpngIncludeFwd = $libpngInclude -replace '\\', '/'
	$zlibLibFwd = $zlibLib -replace '\\', '/'
	$zlibDirFwd = $zlibDir -replace '\\', '/'
	& cmake -S $znSource -B $znBuild -G Ninja `
		"-DCMAKE_POLICY_VERSION_MINIMUM=3.5" `
		"-DCMAKE_C_COMPILER=clang-cl" "-DCMAKE_CXX_COMPILER=clang-cl" "-DCMAKE_BUILD_TYPE=Release" `
		"-DZINT_SHARED=OFF" "-DZINT_STATIC=ON" "-DZINT_FRONTEND=OFF" "-DZINT_USE_PNG=ON" `
		"-DPNG_INCLUDE_DIR=$libpngIncludeFwd" "-DPNG_LIBRARY=$libpngLibFwd" `
		"-DZLIB_INCLUDE_DIR=$zlibDirFwd" "-DZLIB_LIBRARY=$zlibLibFwd" `
		"-DCMAKE_INSTALL_PREFIX=$znInstall" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "zint configure failed" }
	& cmake --build $znBuild --target zint-static 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "zint build failed" }
	& cmake --install $znBuild 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "zint install failed" }
	if (-not (Test-Path $zintLib)) {
		# A CMake that does not install the static archive still builds it; the
		# build dir holds zint-static.lib.
		$found = Get-ChildItem -Path $zintBuild -Recurse -Filter "zint-static.lib" -File | Select-Object -First 1
		if ($null -eq $found) { throw "zint-static.lib not found" }
		New-Item -ItemType Directory -Force -Path (Split-Path $zintLib) | Out-Null
		Copy-Item $found.FullName $zintLib -Force
	}
	if (-not (Test-Path (Join-Path $zintInclude "zint.h"))) {
		New-Item -ItemType Directory -Force -Path $zintInclude | Out-Null
		Copy-Item (Join-Path $zintDir "backend\zint.h") (Join-Path $zintInclude "zint.h") -Force
	}
	Write-Host "  ok   zint.lib built"
} else {
	Write-Host "  ok   zint.lib (cached)"
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
# 3c. The driver C libraries: openssl, freetds, mariadb and libpq.  Mirrors
#     Linux/lib/libraries.sh's build_openssl/freetds/mariadb/postgres, but each
#     built the Windows way:
#       * openssl  -- perl Configure VC-WIN64A + nmake + clang-cl (static, no
#                     tests).  The installed Perl/NASM are used; no-asm is only
#                     a fallback if the asm path fails.
#       * freetds  -- FreeTDS's own CMake path (not autotools), the static
#                     db-lib (sybdb), ENABLE_MSDBLIB on, OpenSSL on.  The
#                     odbc/apps/server/pool targets are simply not built.
#       * mariadb  -- CMake, the static mariadbclient, OpenSSL + the existing
#                     zlib, the MySQL 8 auth plugins static, the rest off.
#       * postgres -- Meson (PostgreSQL 17 dropped the MSVC build), libpq +
#                     pgcommon/pgport static, OpenSSL on, everything else off.
# ---------------------------------------------------------------------------

# Find a freshly built static .lib by name (the output location differs per
# library and per CMake/Meson layout).
function Find-Lib([string]$dir, [string]$name) {
	$f = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "$name.lib" -or $_.Name -eq "$name.a" } | Select-Object -First 1
	if ($f) { return $f.FullName }
	throw "$name library not found under $dir"
}

$MesonExe = "C:\Program Files\Meson\meson.exe"
$nmake = (Get-ChildItem "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\*\bin\Hostx64\x64\nmake.exe" -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($nmake) { $nmake = $nmake.FullName } else { $nmake = $null }

# --- openssl 3.5.9 (static, no tests) ---------------------------------------
$opensslDir = Get-LibrarySource "openssl" (Get-LibraryPin "openssl")
$opensslInstall = Join-Path $opensslDir "install"
$opensslInclude = Join-Path $opensslInstall "include"
$opensslLibSsl = Join-Path $opensslInstall "lib\libssl.lib"
$opensslLibCrypto = Join-Path $opensslInstall "lib\libcrypto.lib"
if (-not (Test-Path $opensslLibCrypto)) {
	Write-Host "  building openssl (perl Configure VC-WIN64A + nmake + clang-cl)"
	if (-not $nmake) { throw "nmake.exe not found under the VS 2026 MSVC tools" }
	$prefixFwd = $opensslInstall -replace '\\', '/'
	$oldPath = $env:PATH
	$oldInclude = $env:INCLUDE
	$oldLib = $env:LIB
	# nmake for the Configure-generated makefile, and the Windows SDK bin dir so
	# the `rc` resource compiler is on PATH (OpenSSL compiles its .rc files).
	# INCLUDE/LIB are set for rc (winver.h) and link; clang-cl finds MSVC on its
	# own, so the rest of the build does not need this.
	$sdkBin = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64"
	$msvcTools = Split-Path (Split-Path (Split-Path (Split-Path $nmake)))
	$sdkRoot = "C:\Program Files (x86)\Windows Kits\10"
	$sdkVer = "10.0.26100.0"
	$env:PATH = "$(Split-Path $nmake);$sdkBin;$oldPath"
	$env:INCLUDE = "$msvcTools\include;$sdkRoot\Include\$sdkVer\ucrt;$sdkRoot\Include\$sdkVer\um;$sdkRoot\Include\$sdkVer\shared"
	$env:LIB = "$msvcTools\lib\x64;$sdkRoot\Lib\$sdkVer\ucrt\x64;$sdkRoot\Lib\$sdkVer\um\x64"
	# OpenSSL's Configure is a Perl script; it needs a complete native-Windows
	# Perl (Strawberry), not the MSYS2 perl which lacks core modules and uses
	# cygwin path semantics.
	try {
		Push-Location $opensslDir
		try {
			& "C:\Strawberry\perl\bin\perl.exe" Configure VC-WIN64A no-shared no-tests "--prefix=$prefixFwd" "--openssldir=$prefixFwd/ssl" CC=clang-cl 2>&1 | ForEach-Object { Write-Host $_ }
			if ($LASTEXITCODE -ne 0) { throw "openssl Configure failed" }
			& nmake 2>&1 | ForEach-Object { Write-Host $_ }
			if ($LASTEXITCODE -ne 0) { throw "openssl nmake failed" }
			& nmake install_sw 2>&1 | ForEach-Object { Write-Host $_ }
			# install_sw copies the .lib files before it reaches the optional
			# ossl_static.pdb copy, which this clang-cl build does not produce
			# ("Can't Open ossl_static.pdb"); the archives are the real gate.
			if (-not (Test-Path $opensslLibCrypto) -or -not (Test-Path $opensslLibSsl)) {
				throw "openssl install failed (libcrypto/libssl missing)"
			}
		} finally {
			Pop-Location
		}
	} finally {
		$env:PATH = $oldPath
		$env:INCLUDE = $oldInclude
		$env:LIB = $oldLib
	}
	Write-Host "  ok   openssl.lib built (libssl + libcrypto)"
} else {
	Write-Host "  ok   openssl.lib (cached)"
}

# --- freetds 1.4.27 (CMake, static sybdb db-lib) ----------------------------
$freetdsDir = Get-LibrarySource "freetds" (Get-LibraryPin "freetds")
$freetdsBuild = Join-Path $BuildDir "freetds-cmake"
$freetdsHeaderDir = Join-Path $BuildDir "freetds-headers"
$freetdsGenInclude = Join-Path $freetdsBuild "include"
$freetdsLib = Join-Path $freetdsBuild "src\dblib\db-lib.lib"
if (-not (Test-Path $freetdsLib)) {
	Write-Host "  configuring freetds (cmake + clang-cl; static db-lib)"
	$ftSource = $freetdsDir -replace '\\', '/'
	$ftBuild = $freetdsBuild -replace '\\', '/'
	& cmake -S $ftSource -B $ftBuild -G Ninja `
		"-DCMAKE_C_COMPILER=clang-cl" "-DCMAKE_CXX_COMPILER=clang-cl" "-DCMAKE_BUILD_TYPE=Release" `
		"-DCMAKE_POLICY_VERSION_MINIMUM=3.5" `
		"-DENABLE_MSDBLIB=ON" "-DWITH_OPENSSL=ON" `
		"-DOPENSSL_ROOT_DIR=$($opensslInstall -replace '\\','/')" `
		"-DBUILD_SHARED_LIBS=OFF" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "freetds configure failed" }
	Write-Host "  building freetds db-lib (static sybdb)"
	& cmake --build $ftBuild --target db-lib 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "freetds build failed" }
	Write-Host "  ok   freetds db-lib.lib built"
} else {
	Write-Host "  ok   freetds db-lib.lib (cached)"
}
# Assemble the "installed" public headers: the source include/ files plus the
# CMake-generated ones (config.h, tds_sysdep_public.h, freetds/*), with the one
# installed-header edit from Compressor/lib/recipes/freetds.sh (BOOL commented
# out, with the LGPL change notice).  The library sources are unmodified.
if (-not (Test-Path (Join-Path $freetdsHeaderDir "sybdb.h"))) {
	New-Item -ItemType Directory -Force -Path $freetdsHeaderDir | Out-Null
	Copy-Item (Join-Path $freetdsDir "include\*") $freetdsHeaderDir -Recurse -Force
	Copy-Item (Join-Path $freetdsGenInclude "*") $freetdsHeaderDir -Recurse -Force
	$sybdbPath = Join-Path $freetdsHeaderDir "sybdb.h"
	$sybdbText = Get-Content $sybdbPath -Raw
	$notice = '/* MODIFIED BY MAD Designer (2026-11-18): "typedef int BOOL;" is commented out below because Objective-C already defines BOOL and the redefinition fails the framework build. The FreeTDS library itself is built unmodified; only this installed header is edited. See Windows/Engine/build.ps1 and ThirdParty/Licenses/README.md. */'
	$sybdbText = $sybdbText -replace '(?m)^typedef int BOOL;\s*$', "//typedef int BOOL;`n$notice"
	Set-Content -Path $sybdbPath -Value $sybdbText -NoNewline
}
$freetdsInclude = $freetdsHeaderDir
$freetdsTdsLib = Join-Path $freetdsBuild "src\tds\tds.lib"
$freetdsReplacementsLib = Join-Path $freetdsBuild "src\replacements\replacements.lib"
$freetdsTdsutilsLib = Join-Path $freetdsBuild "src\utils\tdsutils.lib"

# --- mariadb 3.4.11 (CMake, static mariadbclient) ---------------------------
$mariadbDir = Get-LibrarySource "mariadb" (Get-LibraryPin "mariadb")
$mariadbBuild = Join-Path $BuildDir "mariadb-cmake"
$mariadbInclude = Join-Path $BuildDir "mariadb-headers"
$mariadbLib = Join-Path $mariadbBuild "libmariadb\mariadbclient.lib"
if (-not (Test-Path $mariadbLib)) {
	Write-Host "  configuring mariadb (cmake + clang-cl; static mariadbclient)"
	$maSource = $mariadbDir -replace '\\', '/'
	$maBuild = $mariadbBuild -replace '\\', '/'
	$zlibLibFwd = $zlibLib -replace '\\', '/'
	$zlibDirFwd = $zlibDir -replace '\\', '/'
	& cmake -S $maSource -B $maBuild -G Ninja `
		"-DCMAKE_C_COMPILER=clang-cl" "-DCMAKE_CXX_COMPILER=clang-cl" "-DCMAKE_BUILD_TYPE=Release" `
		"-DWITH_SSL=OPENSSL" "-DOPENSSL_ROOT_DIR=$($opensslInstall -replace '\\','/')" "-DOPENSSL_USE_STATIC_LIBS=TRUE" `
		"-DWITH_EXTERNAL_ZLIB=ON" "-DZLIB_LIBRARY=$zlibLibFwd" "-DZLIB_INCLUDE_DIR=$zlibDirFwd" `
		"-DWITH_CURL=OFF" "-DWITH_UNIT_TESTS=OFF" `
		"-DCLIENT_PLUGIN_CACHING_SHA2_PASSWORD=STATIC" "-DCLIENT_PLUGIN_SHA256_PASSWORD=STATIC" `
		"-DCLIENT_PLUGIN_DIALOG=OFF" "-DCLIENT_PLUGIN_CLIENT_ED25519=OFF" "-DCLIENT_PLUGIN_PARSEC=OFF" `
		"-DCLIENT_PLUGIN_AUTH_GSSAPI_CLIENT=OFF" "-DCLIENT_PLUGIN_MYSQL_CLEAR_PASSWORD=OFF" "-DCLIENT_PLUGIN_ZSTD=OFF" `
		"-DINSTALL_LIBDIR=lib" "-DINSTALL_INCLUDEDIR=include" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "mariadb configure failed" }
	Write-Host "  building mariadb mariadbclient (static)"
	& cmake --build $maBuild --target mariadbclient 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "mariadb build failed" }
	Write-Host "  ok   mariadbclient.lib built"
} else {
	Write-Host "  ok   mariadbclient.lib (cached)"
}
# Flatten the headers so <mysql.h>/<mysqld_error.h> resolve from one include
# root: the source include/*.h plus the CMake-generated ma_config.h/
# mariadb_version.h (the same flatten the Compressor recipe makes after install).
if (-not (Test-Path (Join-Path $mariadbInclude "mysql.h"))) {
	New-Item -ItemType Directory -Force -Path $mariadbInclude | Out-Null
	Copy-Item (Join-Path $mariadbDir "include\*.h") $mariadbInclude -Force
	Copy-Item (Join-Path $mariadbBuild "include\*.h") $mariadbInclude -Force
}

# --- postgres 17.11 (Meson, libpq static) -----------------------------------
$postgresDir = Get-LibrarySource "postgres" (Get-LibraryPin "postgres")
$postgresBuild = Join-Path $BuildDir "postgres-meson"
$postgresHeaders = Join-Path $BuildDir "postgres-headers"
$postgresInclude = $postgresHeaders
$postgresLib = Join-Path $postgresBuild "libpq.lib"
$oldCC = $env:CC
$oldCXX = $env:CXX
$oldPath = $env:PATH
$oldInclude = $env:INCLUDE
$oldLib = $env:LIB
if (-not (Test-Path $postgresLib)) {
	Write-Host "  configuring postgres libpq (meson + clang-cl)"
	$pgSource = $postgresDir -replace '\\', '/'
	$pgBuild = $postgresBuild -replace '\\', '/'
	# PKG_CONFIG_PATH lets meson's openssl dependency locate the from-source
	# OpenSSL install, and the MSYS2 usr/bin is on PATH so meson finds the
	# pkg-config binary it needs for that lookup.
	$env:PKG_CONFIG_PATH = "$($opensslInstall -replace '\\','/')/lib/pkgconfig"
	# Build libpq with MSVC's native cl.exe (PostgreSQL's supported Windows path),
	# not clang-cl: several of PostgreSQL's meson checks compare cc.get_id() to
	# 'msvc', and clang-cl reports 'clang-cl', which silently drops
	# win32gettimeofday.c/dirent.c and the win32_msvc include dir.  cl.exe needs
	# the vcvars INCLUDE/LIB/PATH, set here (the engine itself still uses clang,
	# which finds MSVC on its own).
	$msvcTools = Split-Path (Split-Path (Split-Path (Split-Path $nmake)))
	$sdkRoot = "C:\Program Files (x86)\Windows Kits\10"
	$sdkVer = "10.0.26100.0"
	$sdkBin = Join-Path $sdkRoot "bin\$sdkVer\x64"
	$env:PATH = "$msvcTools\bin\Hostx64\x64;C:\msys64\usr\bin;$sdkBin;$oldPath"
	$env:INCLUDE = "$msvcTools\include;$sdkRoot\Include\$sdkVer\ucrt;$sdkRoot\Include\$sdkVer\um;$sdkRoot\Include\$sdkVer\shared"
	$env:LIB = "$msvcTools\lib\x64;$sdkRoot\Lib\$sdkVer\ucrt\x64;$sdkRoot\Lib\$sdkVer\um\x64"
	# PostgreSQL's Meson configure requires perl/flex/bison even for a libpq-only
	# build, though none is actually run for libpq.  The Linux recipe fakes
	# flex/bison the same way (FLEX=":" in libraries.sh); here they are no-op
	# .bat files that answer --version, and perl is Strawberry (the only complete
	# native-Windows Perl).
	$dummyTools = Join-Path $BuildDir "pg-dummy-tools"
	New-Item -ItemType Directory -Force -Path $dummyTools | Out-Null
	@'
@echo off
if "%~1"=="--version" echo flex 2.6.4
'@ | Set-Content -Path (Join-Path $dummyTools "flex.bat")
	@'
@echo off
if "%~1"=="--version" echo bison (GNU Bison) 3.8.2
'@ | Set-Content -Path (Join-Path $dummyTools "bison.bat")
	$flexBat = (Join-Path $dummyTools "flex.bat") -replace '\\', '/'
	$bisonBat = (Join-Path $dummyTools "bison.bat") -replace '\\', '/'
	# Meson's find_library('ssl') looks for the MSVC name (no `lib` prefix); the
	# OpenSSL build produces libssl.lib/libcrypto.lib, so expose the unprefixed
	# names alongside them.
	foreach ($pair in @(@("ssl", $opensslLibSsl), @("crypto", $opensslLibCrypto))) {
		$dst = Join-Path (Split-Path $pair[1]) ($pair[0] + ".lib")
		if (-not (Test-Path $dst)) { Copy-Item $pair[1] $dst -Force }
	}
	# The from-source OpenSSL install has no pkg-config .pc files, and Meson's
	# dependency('openssl') needs them to learn the transitive Windows system
	# libs (crypt32/ws2_32/…) that static libcrypto pulls in; write the three the
	# package normally ships.
	$pgPkgConfig = Join-Path (Split-Path $opensslLibSsl) "pkgconfig"
	if (-not (Test-Path (Join-Path $pgPkgConfig "openssl.pc"))) {
		New-Item -ItemType Directory -Force -Path $pgPkgConfig | Out-Null
		$pcPrefix = $opensslInstall -replace '\\', '/'
		@"
prefix=$pcPrefix
exec_prefix=`${prefix}
libdir=`${exec_prefix}/lib
includedir=`${prefix}/include

Name: OpenSSL
Description: Secure Sockets Layer and cryptography libraries and tools
Version: 3.5.9
Requires: libssl libcrypto
"@ | Set-Content -Path (Join-Path $pgPkgConfig "openssl.pc")
		@"
prefix=$pcPrefix
exec_prefix=`${prefix}
libdir=`${exec_prefix}/lib
includedir=`${prefix}/include

Name: OpenSSL-libssl
Description: Secure Sockets Layer and cryptography libraries
Version: 3.5.9
Requires.private: libcrypto
Libs: -L`${libdir} -lssl
Cflags: -I`${includedir}
"@ | Set-Content -Path (Join-Path $pgPkgConfig "libssl.pc")
		@"
prefix=$pcPrefix
exec_prefix=`${prefix}
libdir=`${exec_prefix}/lib
includedir=`${prefix}/include

Name: OpenSSL-libcrypto
Description: OpenSSL cryptography library
Version: 3.5.9
Libs: -L`${libdir} -lcrypto
Libs.private: -lcrypt32 -lws2_32 -lgdi32 -luser32 -ladvapi32 -lbcrypt
Cflags: -I`${includedir}
"@ | Set-Content -Path (Join-Path $pgPkgConfig "libcrypto.pc")
	}
	# The MSYS2 pkgconf ignores PKG_CONFIG_PATH, so Meson cannot find the .pc
	# files through it.  A small Windows-native Python shim is the pkg-config
	# Meson invokes (via PKG_CONFIG): it reads PKG_CONFIG_PATH itself and answers
	# the --modversion/--cflags/--libs/--print-requires questions.
	$pgPkgConfigPy = Join-Path $dummyTools "pkg-config.py"
	@'
import os, re, sys

def read_pc(name, dirs):
    for d in dirs:
        p = os.path.join(d, name + ".pc")
        if os.path.isfile(p):
            with open(p, "r") as f:
                return f.read()
    return None

def parse(text):
    vars = {"prefix": "/usr"}
    fields = {}
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", s)
        if m:
            vars[m.group(1)] = m.group(2)
        elif ":" in s and not s.startswith(" "):
            k, v = s.split(":", 1)
            fields.setdefault(k, []).append(v.strip())
    return vars, fields

def expand(s, vars):
    prev = None
    while prev != s:
        prev = s
        s = re.sub(r"\$\{([^}]+)\}", lambda m: vars.get(m.group(1), ""), s)
    return s

def collect(pkg, dirs, vars, fields, seen):
    if pkg in seen:
        return True
    seen.add(pkg)
    text = read_pc(pkg, dirs)
    if text is None:
        return False
    v, f = parse(text)
    vars.update(v)
    for k, vals in f.items():
        fields.setdefault(k, []).extend(vals)
    for r in list(fields.get("Requires", [])) + list(fields.get("Requires.private", [])):
        for dep in r.replace(",", " ").split():
            if not collect(dep, dirs, vars, fields, seen):
                return False
    return True

def main():
    args = sys.argv[1:]
    pkgs = [a for a in args if not a.startswith("-")]
    dirs = [p for p in os.environ.get("PKG_CONFIG_PATH", "").split(os.pathsep) if p]
    vars, fields, seen = {}, {}, set()
    ok = True
    for p in pkgs:
        if not collect(p, dirs, vars, fields, seen):
            ok = False
    if "--version" in args and not pkgs:
        print("0.29.2")
        return 0
    if "--modversion" in args:
        if not ok:
            print("Package %s was not found in the pkg-config search path." % ", ".join(pkgs), file=sys.stderr)
            return 1
        for line in fields.get("Version", ["0.0.0"]):
            print(line)
        return 0
    if "--exists" in args:
        return 0 if ok else 1
    if any(a.startswith("--atleast-version") or a.startswith("--exact-version") for a in args):
        return 0 if ok else 1
    if not ok:
        print("Package %s was not found in the pkg-config search path." % ", ".join(pkgs), file=sys.stderr)
        return 1
    want_cflags = "--cflags" in args or "--cflags-only-I" in args or "--cflags-only-other" in args
    want_libs = "--libs" in args or "--libs-only-l" in args or "--libs-only-L" in args or "--libs-only-other" in args or "--static" in args
    want_requires = "--print-requires" in args
    out = []
    if want_requires:
        for line in fields.get("Requires", []):
            out.append(line)
    if want_cflags:
        for line in fields.get("Cflags", []):
            out.append(expand(line, vars))
    if want_libs:
        for line in fields.get("Libs", []) + fields.get("Libs.private", []):
            out.append(expand(line, vars))
    print(" ".join(out))
    return 0

sys.exit(main())
'@ | Set-Content -Path $pgPkgConfigPy
	$pgPkgConfigExe = Join-Path $dummyTools "pkg-config.exe"
	if (-not (Test-Path $pgPkgConfigExe)) {
		$pyPath = "C:/Users/Michael/AppData/Local/Programs/Python/Python313/python.exe"
		$scriptFwd = $pgPkgConfigPy -replace '\\', '/'
		@"
#include <process.h>
#include <stdlib.h>
int main(int argc, char **argv) {
    const char *python = "$pyPath";
    const char *script = "$scriptFwd";
    const char **v = (const char **)malloc(sizeof(char *) * (argc + 2));
    v[0] = python; v[1] = script;
    for (int i = 1; i < argc; i++) v[i + 1] = argv[i];
    v[argc + 1] = 0;
    return (int)_spawnv(_P_WAIT, python, v);
}
"@ | Set-Content -Path (Join-Path $dummyTools "pkg-config-launcher.c")
		& clang (Join-Path $dummyTools "pkg-config-launcher.c") -o $pgPkgConfigExe 2>&1 | ForEach-Object { Write-Host $_ }
		if ($LASTEXITCODE -ne 0) { throw "pkg-config launcher compile failed" }
	}
	$env:PKG_CONFIG = $pgPkgConfigExe
	$env:CC = "cl"
	$env:CXX = "cl"
	& $MesonExe setup $pgBuild $pgSource `
		"--backend=ninja" `
		"-DPERL=C:/Strawberry/perl/bin/perl.exe" `
		"-DFLEX=$flexBat" "-DBISON=$bisonBat" `
		"-Dextra_include_dirs=$($opensslInclude -replace '\\','/')" `
		"-Dextra_lib_dirs=$((Join-Path $opensslInstall 'lib') -replace '\\','/')" `
		"-Dssl=openssl" `
		"-Dzlib=disabled" "-Dreadline=disabled" "-Dicu=disabled" `
		"-Dlz4=disabled" "-Dzstd=disabled" "-Dgssapi=disabled" `
		"-Dldap=disabled" "-Dpam=disabled" "-Dbonjour=disabled" `
		"-Dlibxml=disabled" "-Dnls=disabled" `
		"-Dbuildtype=release" "-Ddefault_library=static" `
		2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "postgres meson setup failed" }
	Write-Host "  building postgres libpq + pgcommon_shlib + pgport_shlib (static)"
	# The _shlib variants are the frontend ones that export the nominal
	# pg_char_to_encoding()/pg_encoding_to_char() names (the plain libpgcommon.a
	# is built with -DUSE_PRIVATE_ENCODING_FUNCS and only exports the "_private"
	# spellings libpq does not call).  Same choice as Linux/lib/libraries.sh.
	& ninja -C $pgBuild src/interfaces/libpq/libpq.a src/common/libpgcommon_shlib.a src/port/libpgport_shlib.a 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "postgres libpq build failed" }
	# Meson produces GNU-ar .a archives, but lld-link resolves members only out of
	# COFF .lib archives.  llvm-lib converts (and merges) the three into one COFF
	# libpq.lib the frameworks link.
	& llvm-lib /out:$postgresLib `
		(Join-Path $pgBuild "src\interfaces\libpq\libpq.a") `
		(Join-Path $pgBuild "src\common\libpgcommon_shlib.a") `
		(Join-Path $pgBuild "src\port\libpgport_shlib.a") 2>&1 | ForEach-Object { Write-Host $_ }
	if ($LASTEXITCODE -ne 0) { throw "postgres libpq.lib archive failed" }
	Write-Host "  ok   libpq.lib built"
} else {
	Write-Host "  ok   libpq.lib (cached)"
}
$env:PKG_CONFIG_PATH = ""
$env:PKG_CONFIG = $null
$env:CC = $oldCC
$env:CXX = $oldCXX
$env:INCLUDE = $oldInclude
$env:LIB = $oldLib
$env:PATH = $oldPath

# Assemble the libpq client headers (a few are generated by Meson, the rest are
# source) into one flattened directory so <libpq-fe.h> and <MADPostgres/...>
# both resolve from a single include root, the same way Linux/lib/libraries.sh
# copies them into /usr/local/include.
if (-not (Test-Path (Join-Path $postgresHeaders "libpq-fe.h"))) {
	New-Item -ItemType Directory -Force -Path $postgresHeaders | Out-Null
	Copy-Item (Join-Path $postgresDir "src\interfaces\libpq\libpq-fe.h") $postgresHeaders -Force
	Copy-Item (Join-Path $postgresDir "src\interfaces\libpq\libpq-events.h") $postgresHeaders -Force
	Copy-Item (Join-Path $postgresDir "src\include\postgres_ext.h") $postgresHeaders -Force
	Copy-Item (Join-Path $postgresDir "src\include\pg_config_manual.h") $postgresHeaders -Force
	foreach ($h in @("pg_config.h", "pg_config_ext.h", "pg_config_os.h")) {
		$gen = Get-ChildItem -Path $postgresBuild -Recurse -Filter $h -File -ErrorAction SilentlyContinue | Select-Object -First 1
		if (-not $gen) { throw "generated $h not found under $postgresBuild" }
		Copy-Item $gen.FullName (Join-Path $postgresHeaders $h) -Force
	}
	$typd = Get-ChildItem -Path $postgresBuild -Recurse -Filter "pg_type_d.h" -File -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $typd) { throw "generated pg_type_d.h not found under $postgresBuild" }
	Copy-Item $typd.FullName (Join-Path $postgresHeaders "pg_type_d.h") -Force
}

if ($LibrariesOnly) {
	Write-Host "### Libraries built (-LibrariesOnly); stopping before the framework compile."
	exit 0
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
		} elseif ($framework -eq "MADBarcodes") {
			# The framework exposes the headers it builds on as
			# <MADBarcodes/zint.h> and <MADBarcodes/png.h> (the Xcode target
			# keeps them Public), so the shim is a directory of copies.
			New-Item -ItemType Directory -Force -Path $link | Out-Null
			Get-ChildItem -Path $sourceDir -Filter *.h -File | ForEach-Object {
				Copy-Item $_.FullName (Join-Path $link $_.Name)
			}
			foreach ($h in @("zint.h")) {
				Copy-Item (Join-Path $zintInclude $h) (Join-Path $link $h) -Force
			}
			foreach ($h in @("png.h", "pngconf.h", "pnglibconf.h")) {
				Copy-Item (Join-Path $libpngInclude $h) (Join-Path $link $h) -Force
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
$barcodeSource = Join-Path $RepoRoot "MADBarcodes\MADBarcodes\MADBarcodes"
$madSource = Join-Path $RepoRoot "MAD\Source"
$mysqlSource = Join-Path $RepoRoot "MADMySQL\Source"
$tdsSource = Join-Path $RepoRoot "MADTds\MADTds"
$tdsClientSource = Join-Path $RepoRoot "MADTdsClient\Source"
$pgSource = Join-Path $RepoRoot "MADPostgres\Source"

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

# The driver frameworks expose C headers the Xcode targets keep Public:
#   <MADTds/sybdb.h> and <MADTds/tds_sysdep_public.h>    (freetds)
#   <MADTdsClient/MADTdsClient.h>                         (the umbrella above Source/)
#   <MADPostgres/libpq-fe.h>, postgres_ext.h, pg_config_ext.h, pg_type_d.h (libpq)
# These are copies beside the framework self-import junctions, the same shape as
# Linux's sybdb-shim/umbrella-shim/libpq-shim directories.
$SybdbShimDir = Join-Path $BuildDir "sybdb-shim"
$UmbrellaShimDir = Join-Path $BuildDir "umbrella-shim"
$LibpqShimDir = Join-Path $BuildDir "libpq-shim"
foreach ($d in @((Join-Path $SybdbShimDir "MADTds"),
				 (Join-Path $UmbrellaShimDir "MADTdsClient"),
				 (Join-Path $LibpqShimDir "MADPostgres"))) {
	New-Item -ItemType Directory -Force -Path $d | Out-Null
}
# <MADTds/sybdb.h> and <MADTds/tds_sysdep_public.h> are copies of the freetds
# "installed" headers, whose sybdb.h already carries the BOOL edit + notice.
Copy-Item (Join-Path $freetdsInclude "sybdb.h") (Join-Path $SybdbShimDir "MADTds\sybdb.h") -Force
Copy-Item (Join-Path $freetdsInclude "tds_sysdep_public.h") (Join-Path $SybdbShimDir "MADTds\tds_sysdep_public.h") -Force
Copy-Item (Join-Path $RepoRoot "MADTdsClient\MADTdsClient.h") (Join-Path $UmbrellaShimDir "MADTdsClient\MADTdsClient.h") -Force
foreach ($h in @("libpq-fe.h", "postgres_ext.h", "pg_config_ext.h", "pg_type_d.h")) {
	Copy-Item (Join-Path $postgresInclude $h) (Join-Path $LibpqShimDir "MADPostgres\$h") -Force
}

# The driver frameworks' C-header include dirs, per-framework (not global) so
# they do not shadow the other frameworks' headers.
$mysqlIncludeDirs = @($mariadbInclude)
$tdsIncludeDirs = @($SybdbShimDir, $freetdsInclude)
$tdsClientIncludeDirs = @($SybdbShimDir, $UmbrellaShimDir, $freetdsInclude)
$pgIncludeDirs = @($LibpqShimDir, $postgresInclude)

$mysqlFlags = { param($f) $flags = @("-fobjc-arc"); foreach ($d in $script:mysqlIncludeDirs) { $flags += "-I$d" }; return $flags }
$tdsFlags = { param($f) $flags = @("-fobjc-arc"); foreach ($d in $script:tdsIncludeDirs) { $flags += "-I$d" }; return $flags }
$tdsClientFlags = { param($f) $flags = @("-fobjc-arc"); foreach ($d in $script:tdsClientIncludeDirs) { $flags += "-I$d" }; return $flags }
$pgFlags = { param($f) $flags = @("-fobjc-arc"); foreach ($d in $script:pgIncludeDirs) { $flags += "-I$d" }; return $flags }

# The union of the driver include dirs, for the test and CLI compile lines (the
# driver tests import <MADMySQL/...>, <MADTds/...>, <MADTdsClient/...>,
# <MADPostgres/...>, whose headers reach the C library headers).
$driverIncludeDirs = @($mariadbInclude, $SybdbShimDir, $UmbrellaShimDir, $LibpqShimDir,
						$freetdsInclude, $postgresInclude)

Compile-FrameworkSources "MADDataStructures" "ds_" $dsSource (Join-Path $EngineDir "cmake\MADDataStructuresSources.cmake") $dsFlags
Compile-FrameworkSources "MADFoundation" "fd_" $fdSource (Join-Path $EngineDir "cmake\MADFoundationSources.cmake") $fdFlags
Compile-FrameworkSources "MADAPI" "api_" $apiSource (Join-Path $EngineDir "cmake\MADAPISources.cmake") $arcFlags
Compile-FrameworkSources "MADSqlite3" "sql_" $sqlite3Source (Join-Path $EngineDir "cmake\MADSqlite3Sources.cmake") $arcFlags
Compile-FrameworkSources "MADCocoaExtensions" "coco_" $cocoSource (Join-Path $EngineDir "cmake\MADCocoaExtensionsSources.cmake") $arcFlags
Compile-FrameworkSources "MADFileManager" "fm_" $fmSource (Join-Path $EngineDir "cmake\MADFileManagerSources.cmake") $arcFlags
# MADBarcodes before MAD: MADPrintPageElementBarcode imports <MADBarcodes/...>.
Compile-FrameworkSources "MADBarcodes" "bc_" $barcodeSource (Join-Path $EngineDir "cmake\MADBarcodesSources.cmake") $arcFlags

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

# The four driver frameworks.  MADMySQL, MADTdsClient and MADPostgres are linked
# whole (their work is reached through categories), exactly as Linux
# whole-archives them.  MADTds is the exception: MADTdsDb.m defines the global
# err_handler symbol that MADTdsClient's MADDatabaseSQLServer.m also defines, so
# its object is archived by itself and linked normally -- it resolves only if
# something references it, which the headless engine does not (nothing names the
# MADTdsDb class; Linux/CMakeLists.txt:416 records the same).
New-Shim "MADTds" $tdsSource
Compile-FrameworkSources "MADMySQL" "mysql_" $mysqlSource (Join-Path $EngineDir "cmake\MADMySQLSources.cmake") $mysqlFlags
Compile-FrameworkSources "MADTdsClient" "tdsc_" $tdsClientSource (Join-Path $EngineDir "cmake\MADTdsClientSources.cmake") $tdsClientFlags
Compile-FrameworkSources "MADPostgres" "pg_" $pgSource (Join-Path $EngineDir "cmake\MADPostgresSources.cmake") $pgFlags

Write-Host "### MADTds"
$tdsObj = Join-Path $ObjDir "tds_MADTdsDb.obj"
Compile-One (Join-Path $tdsSource "MADTdsDb.m") $tdsObj (@(& $tdsFlags "MADTdsDb.m"))
$madtdsLib = Join-Path $BuildDir "madtds.lib"
& llvm-lib /out:$madtdsLib $tdsObj 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) { throw "madtds archive failed" }

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
	"-lole32", "-lxmllite", "-lcrypt32", "-lsecur32", "-lshlwapi", "-lgdi32", "-lbcrypt"
)

# The static C libraries, in link order: the framework objects come first, then
# the driver libraries, then the archive stack.  libarchive references zlib and
# bzip2, so it precedes them; openssl is linked once, after the three drivers
# that reference it (freetds, mariadb, libpq).  madtds.lib (MADTdsDb) is linked
# normally, not whole: its member is dropped unless something references the
# MADTdsDb class, which the headless engine does not.
$archiveLibs = @($freetdsLib, $freetdsTdsLib, $freetdsReplacementsLib, $freetdsTdsutilsLib,
				$mariadbLib, $postgresLib, $opensslLibSsl, $opensslLibCrypto,
				$sqliteLib, $libarchiveLib, $zintLib, $libpngLib, $zlibLib, $bzip2Lib, $madtdsLib)

# The ported Linux test suites (Linux/Tests), one executable per file.  Tests
# are manual-retain-release (GNUstep's Testing.h is MRC) while the frameworks
# stay ARC, exactly as on Linux.  BDHostTests is registered: BDHost.m carries a
# Winsock2 branch (see MADFoundation/Source/BDHost.m) and links here.
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
	"MADCredentialTests", "BDHostTests", "MADApplicationTests", "MADBlockObserverTests",
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
	# MADBarcodes
	"MADBarcodesTests",
	# MADCocoaExtensions
	"MADBorderStyleTests", "MADDirectionTests", "MADGeometryExtrasTests",
	"MADMarginTests", "MADMathAlgebraTests", "MADPaddingTests",
	"MADTextStyleTests", "MTMathTests", "NSNumberFormatterExtensionsTests",
	# MADAPI
	"MADAPIEnumsAndConstantsTests", "MADDatabaseDriverRegistryTests",
	"MADDatabaseConnectionTests", "MADDatabaseDataBindingTests",
	"MADDatabaseFieldTests", "MADDatabaseTableTests", "MADDatabaseTests",
	"MADErrorContainerTests", "MADNotificationDidReadRowsTests", "MADQueryTests",
	# MADMySQL
	"MADMySQLLiveTests", "MADMySQLTests", "MADMySQLDeleteTests",
	"MADMySQLExceptionTests", "MADMySQLFetchFieldTests", "MADMySQLInsertTests",
	"MADMySQLSupportTypesTests", "MADMySQLTruncateTests", "MADMySQLUpdateTests",
	# MADTdsClient (its suite is what exercises MADTds)
	"MADTdsClientTests", "MADTdsClientLiveTests",
	# MADPostgres
	"MADPostgresLiveTests", "MADPostgresTests",
	# MAD.  The four suites that need the drivers are wired with them.
	"MADArchiveManagerTests", "MADCoreLogicTests",
	"MADDatabaseDriverDispatchTests",
	"MADHeadlessDocumentTests", "MADDataTableRegressionTests",
	"MADDesignerQueryTests", "MADDesignerViewerTests",
	"MADDocumentObjectDataReferenceTests", "MADDocumentObjectDataReferenceAggregateTests",
	"MADDocumentObjectDataReferenceImageTests", "MADDocumentObjectDataReferenceLabelDynamicTests",
	"MADDocumentObjectDataReferenceLabelStaticTests", "MADFontTests",
	"MADLegacyStoreConversionTests", "MADModelQueryFieldTests", "MADModelQueryTableTests",
	"MADNotificationAndOperationTests", "MADOperationHoldsProtocolsTests",
	"MADPageOptionsTests", "MADQueryCacheAggregateFunctionTests", "MADQueryDefinitionTests",
	"MADSQLParserTests", "MADSQLQueryCompilerTests",
	"MADQueryPredicateTests", "MADQuerySampleDataTests", "MADQuerySelectExpressionTests",
	"MADQueryTestTests", "MADQueryFullTests", "MADQueryMaxFieldLengthTests",
	"MADQueryFullTableEnumeratorTests",
	"MADQuerySimpleTypesTests", "MADReportExporterTests", "MADReportSectionEnumeratorTests",
	"MADReportSectionRepresentationTests", "MADReportSectionTests", "MADRptqDatabaseTests",
	"MADRptqDocumentSectionTests", "MADRptqQueryTests", "MADRptqValueTypeTests",
	"MADSchemaFieldSelectorModelTests", "MADStoreTests", "MADStoreMigrationTests",
	"RptqDataHelperTests", "RptqDocumentElementFormulaTests", "RptqDocumentElementGroupKeyTests",
	"RptqDocumentElementLabelLinkTests", "RptqDocumentSectionEnumeratorTests", "RptqStoreContextTests"
)

$testExes = New-Object System.Collections.Generic.List[string]
$testCompileFlags = @("-fno-objc-arc", "-I$TestingInclude", "-I$TestsSupportDir", "-I$Sqlite3Dir")
foreach ($d in $driverIncludeDirs) { $testCompileFlags += "-I$d" }
foreach ($name in $testNames) {
	$src = Join-Path $EngineDir ("Tests\" + $name + ".m")
	$obj = Join-Path $ObjDir ("test_" + $name + ".obj")
	$exe = Join-Path $TestExeDir ($name + ".exe")
	Write-Host "### test $name"
	Compile-One $src $obj $testCompileFlags
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
foreach ($d in $driverIncludeDirs) { $cliFlags += "-I$d" }
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
