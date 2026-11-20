# Windows Agent Overview

## What this is

The native Windows engine and its WPF application (see
[`MAD_WINDOWS.md`](../docs/project/MAD_WINDOWS.md) and this directory's
[`README.md`](README.md)). It compiles the engine's Objective-C frameworks
against GNUstep Base with Clang, the Windows sibling of the Linux build, and
`App/` is the WPF app on top of the `mad serve` process boundary (Phases 5 and
6a–6e). It builds all eleven headless frameworks (MADDataStructures, MADFoundation,
MADAPI, MADSqlite3, MADCocoaExtensions, MADFileManager, MAD, plus the four drivers
MADMySQL, MADTds, MADTdsClient, MADPostgres), compiles the pinned
SQLite/zlib/bzip2/libarchive and OpenSSL/FreeTDS/MariaDB/libpq libraries, builds
`mad.exe` from `CLI/Source`, and runs the ported Linux test suites (125 suites +
the smoke test, 1294 tests, 6 needs, 5 skips, 0 failures).

## Layout

*   **`Engine/toolchain.conf`** — the toolchain pins, the single place the
    recipe is written down: the pinned `tools-windows-msvc` commit, Clang
    20.1.8 / lld / VS 2026 / the Windows SDK, the STL gate override, and the
    seven pinned GNUstep component revisions.
*   **`Engine/toolchain/`** — the reproducible toolchain build:
    `bootstrap.ps1` (clone the pinned driver, apply the patches, build into the
    prefix) and the two patch files it applies:
    *   `stl-gate-override.patch` — appends `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`
        to the driver's `scripts/sdkenv.bat` (the VS 2026 STL gate).
    *   `revision-pins.patch` — sets `TAG=` in the driver's `phases/*` to the
        seven known-good revisions (the floating-master regression).
*   **`Engine/build.ps1`** — the entry point: prerequisite check, idempotent
    toolchain bootstrap, the SQLite library build, the framework build, the
    test build, and the test run.
*   **`Engine/libraries.conf`** — the C-library pins (sqlite3, zlib, bzip2,
    libarchive, and the four drivers openssl/freetds/mariadb/postgres), the same
    shape as `Linux/libraries.conf`; read by `build.ps1`.
*   **`Engine/cmake/<Name>Sources.cmake`** — the per-framework source lists and
    exclusion reasons, mirroring `Linux/cmake/`. These are the canonical file
    inventory; `build.ps1` reads them back so the two cannot drift.
*   **`Engine/Compat/`** — the Windows shims, a copy of `Linux/Compat` adapted
    for Windows: `syslog.h` (no-op), `pthread.h` (`CRITICAL_SECTION` mutex),
    the `NSData+ReadingOptions` shim dropped, `NSPropertyListSerialization+Stream.m`
    (reads the already-open stream — never re-opens it), `unistd.h` (`open`
    with `_O_BINARY`), `dirent.h`/`libgen.h`/`sys/{unistd,fcntl,inotify}.h`,
    `MADCompat.h` (the force-included prelude) with the `<endian.h>` block
    dropped and a `static inline strlcat` added, and `NSURL+FileSystem.m`
    answering UTF-8 (not GNUstep's UTF-16).
*   **`Engine/Tests/`** — the ported Linux test suites (one `.m` per
    executable) plus the smoke test, and `Support/MADTestSupport.h` (the
    GNUstep `Testing.h` glue). `BDHostTests` is now registered (`BDHost.m`
    carries a Winsock2 branch); the four Phase 3a-deferred MAD suites
    (`MADDatabaseDriverDispatchTests`, `MADQueryFullTests`, `MADSQLParserTests`,
    `MADQueryMaxFieldLengthTests`) and the MySQL/TDS/PostgreSQL suites are wired
    in `build.ps1`.
*   **`Engine/build/`** — build output (gitignored): clang objects, `smoke.exe`,
    the `tests/` executables, the SQLite library, the toolchain clone, and the
    include-shim junctions.
*   **`global.json`** — pins .NET 10 LTS for the WPF app and its tests.
*   **`Client/`** — the Phase 4 stdio acceptance client (`.NET 10`): `Mad.Client`
    (a console client for `mad serve`) and `Mad.Client.Tests` (xunit; success,
    malformed, engine-failure and shutdown paths).  The protocol is documented in
    `docs/project/MAD_WINDOWS.md` §6d.
*   **`App/`** — the WPF application (`net10.0-windows`): `Mad.Designer.Windows`
    (the app — connection, Query, Designer and Viewer workspaces, MVVM over the
    Phase 4 client) and `Mad.Designer.Windows.Tests` (xunit; the acceptance tests,
    the localization dictionaries, the licence register, and the WPF smoke test
    `SmokeTests.cs`, which pins the London export bytes). `App/.../Resources/`
    holds the six `Strings-<language>.xaml` dictionaries. It reuses
    `Client/Mad.Client` via a project reference; see `Windows/README.md`.

## How the build works

`build.ps1` drives Clang directly — it does **not** go through CMake's
Objective-C language. CMake's Objective-C support on Windows is broken for the
GNU-driver clang + MSVC target: its link probe passes GNU-ld flags
(`--out-implib`, `-nostdlib`) to `lld-link` and appends `.lib` to library names
already prefixed with `-l`. The proven recipe is direct `clang` invocations
(the viability phase's `compile-mad.sh` / `link-and-run.sh`), and `build.ps1`
is that recipe cleaned up. The `cmake/*.cmake` lists stay CMake-ready so a
real CMake build can consume them once CMake's Windows ObjC support lands.

## Conventions and hazards

*   The two shared-source changes this build required (the `madlib.c`
    `itoa`/`ltoa`/`ultoa` → `mad_*` rename, and the `MTStack`/`MTQueue`/
    `MTLinkedList` fast-enumeration `memcpy` cursor) are portable and
    behaviour-neutral on Apple/Linux; both are enumerated in
    `docs/project/MAD_WINDOWS.md` §5. The `NSPropertyListSerialization+Stream.m`
    `NSData.h` import and the `strlcat`/UTF-8 `fileSystemRepresentation` shims
    live in `Windows/Engine/Compat`, not in shared source. Prefer a
    `Windows/Engine/Compat` shim before editing a shared framework source; a gap
    that needs a source guard is `#if __APPLE__` (never a `TARGET_OS_*` spelling
    GNUstep does not define).
*   `Engine/Compat/` mirrors `Linux/Compat/`. When a Linux shim changes, port
    the change to the Windows copy (or record why it does not apply).
*   `.mm` files compile with `-std=gnu++20` and
    `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`; `MADVectorBool.mm` also gets
    `-fno-objc-arc` (the file enforces it itself). `madlib.c` compiles as
    Objective-C (`-x objective-c`, manual-retain-release) because it uses
    `#import`.
*   The framework and test translation units all compile with `-DDEBUG=1` (to
    match Linux's `gnustep-config --objc-flags` under `--enable-debug-by-default`)
    and **without** `NS_BLOCK_ASSERTIONS`, so `NSAssert` is active. Tests are
    MRC (`-fno-objc-arc`); frameworks stay ARC. SQLite compiles with the
    `Compressor/sqlite3.xcconfig` option list, never a winget install.
*   The toolchain build must run elevated (it installs into `C:\GNUstep`), from
    the `vcvars64` environment, with the `BASH` setting, by absolute
    `build.bat` path, without editing `PATH`.
*   Do not change the compiler, STL, or Visual Studio/SDK without a new
    viability test — they are the environment, not a knob.
*   The Windows engine's licence surface is not the Apple app's. GNUstep Base,
    gnustep-corebase and the libiconv library are LGPL-2.1-or-later; libobjc2
    and libffi are MIT; libdispatch is Apache-2.0 with the Swift runtime
    exception. Their texts live in `ThirdParty/Licenses/Windows/`, the register
    entry is `docs/project/THIRD_PARTY_LICENSES.md` §10, and the relink offer is
    in `ThirdParty/Licenses/README.md`. The WPF About window (completed in
    Phase 6e) renders the Windows components from the register, plus Microsoft
    Edge WebView2, which is a Microsoft redistributable with an attribution
    notice (`ThirdParty/Licenses/Windows/WebView2-Runtime-NOTICE.txt`), not an
    open-source licence text. Do not add GNUstep rows to the iOS/macOS About
    screens. A Windows package must ship `ThirdParty/Licenses` and `NOTICE`. The
    GNUstep Base command-line tools
    (`gdomap`, `gdnc`, `defaults`, `plutil`, `gspath`) are GPL-3.0-or-later and
    are not part of `mad.exe`; do not package them without the GPL text and a
    corresponding-source offer.

## Verification

`pwsh -File .\Windows\Engine\build.ps1` from an elevated prompt is the whole
check: toolchain bootstrap (idempotent) + SQLite build + framework build + test
build + test run, exiting non-zero on any failure. The smoke test prints
`SMOKE RESULT: 0 failure(s)`; each suite prints `MADTEST <suite> tests=… needs=…
skips=… failed=0` and exits 0. `MADDataTableFastBenchmarkTests` skips at its
default scale zero (`MAD_BENCH_ROWS`). The Linux CI and the Apple suites are the
regression gates for the shared-source changes this tree makes. The Phase 4
client and the WPF app are checked separately: build `mad.exe`, then
`dotnet test Windows/Client/Mad.Client.Tests` and
`dotnet test Windows/App/Mad.Designer.Windows.Tests`. The app suite includes the
WPF smoke test, whose London exports must match the pins in `Linux/README.md`
(see `Windows/README.md`).
