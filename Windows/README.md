# Windows — the headless engine's native build

The Windows counterpart to `Linux/`: a native Windows build of the headless
engine's Objective-C frameworks, compiled with Clang against GNUstep Base, so
the same engine that runs the macOS app and the Linux CLI can run on Windows.
Nothing here is the app — the WPF shell is a later phase (`docs/project/MAD_WINDOWS.md`).

This increment builds all seven headless frameworks — **MADDataStructures**,
**MADFoundation**, **MADAPI**, **MADSqlite3**, **MADCocoaExtensions**,
**MADFileManager** and **MAD** — compiles the pinned SQLite, zlib, bzip2 and
libarchive libraries, and builds **`mad.exe`** from `CLI/Source`. It runs the
ported Linux test suites (GNUstep `Testing.h` + `MADTestSupport.h`) plus a
smoke test: 107 suites, 966 tests, 6 needs, 0 failures. `mad.exe` runs
`inspect`, `schema`, `query`, `refresh` (76 rows on the London fixture),
`export` in every format, and `write --reproducible` — all with byte-identical
digests to the Mac/Linux pins in `Linux/README.md`.

## Prerequisites

| Tool | Version | Where |
|---|---|---|
| LLVM/Clang (`clang`, `clang-cl`, `lld-link`) | **20.1.8** | `C:\Program Files\LLVM\bin` |
| CMake | 4.4.4 | `C:\Program Files\CMake\bin` |
| Ninja | 1.13.2 | on `PATH` |
| NASM | 3.02 | `C:\Program Files\NASM` |
| MSYS2 (`make`, `autoconf`, `automake`, `libtool`, `pkg-config`) | current | `C:\msys64` |
| Git | 2.56.0 | `C:\Program Files\Git` |
| Visual Studio | Community 2026, **18.12.0** | `C:\Program Files\Microsoft Visual Studio\18\Community` |
| Windows SDK | 10.0.26100.0 | `C:\Program Files (x86)\Windows Kits\10` |

Install Clang 20.1.8 if a different LLVM is present (winget installs to the
same directory, so remove any other LLVM first):

```
winget uninstall --id LLVM.LLVM --accept-source-agreements --silent
winget install -e --id LLVM.LLVM --version 20.1.8 --accept-source-agreements --accept-package-agreements
```

## The pinned recipe, and why it is pinned

The proven, reproducible environment is recorded in
`Engine/toolchain.conf` (the single source of truth) and applied by
`Engine/toolchain/bootstrap.ps1` as two patch files against the pinned
`gnustep/tools-windows-msvc` driver:

* **Clang 20.1.8.** The Phase 1 startup crash (`0xC0000005` in every
  Foundation binary) was a runtime regression in the floating-master GNUstep
  components — the seven pins below fix it — not a Clang 23 codegen bug.
  Clang 20.1.8 is the CI-tested compiler and part of the proven recipe;
  Clang 22/23 with the pins were not tested.
* **`-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH`.** This machine's VS 2026
  (18.12.0) MSVC STL hard-requires "Clang 22 or newer" (`_MSVC_STL_UPDATE
  202609L`). The override is the STL's own escape hatch and is proven benign
  for the code involved (`docs/project/MAD_WINDOWS.md` §2).
* **Seven pinned GNUstep component revisions.** `tools-windows-msvc` clones
  floating master, and its CI builds but never runs a binary, so a runtime
  regression (11-14 → 11-17) shipped unnoticed. The known-good 11-14 revisions
  are pinned: libobjc2, libffi, libiconv, libdispatch, gnustep-make,
  gnustep-base, gnustep-corebase.
* **The `tools-windows-msvc` driver itself is pinned** to commit
  `54d08e57` (recorded in `toolchain.conf`) because its master floats.

Do not change the compiler, STL, or Visual Studio/SDK without a new viability
test.

## Building and testing

From an **elevated** PowerShell 7 prompt (the toolchain installs into
`C:\GNUstep`, the drive root):

```powershell
pwsh -File .\Windows\Engine\build.ps1                 # full: bootstrap + build + test
pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain  # build + test, toolchain already built
```

`build.ps1` does six things: the prerequisite check, an idempotent toolchain
bootstrap (clone the pinned driver, apply the two patches, build GNUstep from
source into `C:\GNUstep`, ~20–30 minutes on first run), the SQLite library
build (download, verify sha256, extract, compile the amalgamation, archive it),
the framework build, and the test run (the smoke test plus every ported suite).
It exits non-zero on any failure.

The smoke test (`Engine/Tests/smoke.m`) exercises `MTStack` (LIFO, fast
enumeration), `MTQueue` (FIFO), `MTGraph`, and `MADStringUtilities` /
`MADDataType`. Expected result: `SMOKE RESULT: 0 failure(s)`, exit code 0.

The ported suites are `Engine/Tests/*.m`, one executable each, driven by
`Engine/Tests/Support/MADTestSupport.h` over GNUstep's `Testing.h` — the same
shape as `Linux/Tests`. The run prints a `MADTEST <suite> tests=… needs=…
skips=… failed=…` line per suite; the build fails on any non-zero exit. The one
deliberate skip is `MADDataTableFastBenchmarkTests`, which skips at its default
scale zero (set `MAD_BENCH_ROWS=<n>` to run the benchmarks). The six recorded
needs are the platform gaps the Linux image reports: `MADDirectoryMonitorTests`
(3 — the Windows directory monitor is inert, `sys/inotify.h` shim),
`MADStoreTests` (1 — Core Data + the compiled `MAD.momd`) and
`RptqStoreContextTests` (2 — the converter/document path). Four MAD suites that
need the Phase 3b drivers are not registered yet — `MADDatabaseDriverDispatchTests`,
`MADQueryFullTests`, `MADSQLParserTests` and `MADQueryMaxFieldLengthTests` —
recorded in `build.ps1`, not skipped silently.

> The build wrapper uses the `vcvars64` environment, an absolute `build.bat`
> path, and the `BASH` setting, without rewriting `PATH` (the vcvars64 `PATH`
> is ~2500 chars and breaks bare-name lookup). From Git Bash, invoke `cmd`
> with `cmd //c` (not `cmd /c`); from PowerShell, `cmd /c` is correct.

## What compiles, and what does not

| Framework | Windows build | Excluded, and why |
|---|---|---|
| MADFoundation | 26 of 27 (+ `madlib.c`) | `MADKeyChain` (Security.framework, as on Linux) and `BDHost` (POSIX-socket reverse DNS — `sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`; needs a Winsock2 port). The umbrella goes with `MADKeyChain`. |
| MADDataStructures | all 17 | (`madmap.cpp` is not in the Xcode target either) |
| MADAPI | 8 of 11 | the three connection view controllers (`MADConnectionViewController`, `MADConnectionSQLGenericViewController`) — UIKit, not headless. |
| MADSqlite3 | all 26 | five orphan `.m` files not in the Xcode target either (see `Engine/cmake/MADSqlite3Sources.cmake`) |
| MADCocoaExtensions | 7 of 17 | the ten UIKit drawers/presenters (colors, labels, text fields, alerts, view helpers, the error presenter, MessageUI) — the same Linux split |
| MADFileManager | 10 of 11 | `MADCloudFileCoordinator` (NSMetadataQuery/iCloud) — the same Linux exclusion; `MADDirectoryMonitor` uses an inert `inotify` shim |
| MAD | 168 of 199 | the UI tail, `MADocument` + the build/close operations, the keychain operations, and the barcode element files — the same Linux exclusions (each named in `Engine/cmake/MADSources.cmake`) |

## The SQLite library

`MADSqlite3` links a static SQLite built from the same **3.53.3 amalgamation**
pin as Linux (`Engine/libraries.conf`, sha256 `c917d7db…`), never a winget
install. `build.ps1` downloads the released amalgamation tarball, verifies its
sha256, extracts it, and compiles `sqlite3.c` with the option list in
`Compressor/sqlite3.xcconfig` (the one place those format-deciding flags are
written down) plus `-DSQLITE_THREADSAFE=1`, then archives it with `llvm-lib`
into a COFF `sqlite3.lib`. The framework imports it as `<MADSqlite3/sqlite3.h>`
through a header shim beside the framework self-import junction, the same way
the Linux build exposes the header.

The `.mad` container's archive stack is built the same way from the Linux pins
in `Engine/libraries.conf`: **zlib 1.3.2** and **bzip2 1.0.8** (direct `clang` +
`llvm-lib`) and **libarchive 3.8.9** (CMake + clang-cl; zlib/bzip2 in, the
tools out). `MADArchiveManager.m`/`madtar.m` link them to read and write a
document's bzip2/tar body.

The per-framework source lists, with the exclusion reasons, are
`Engine/cmake/<Name>Sources.cmake`, mirroring `Linux/cmake/`. The Windows shims
live in `Engine/Compat/` (a copy of `Linux/Compat` adapted for Windows):

* `syslog.h` — no-op `syslog()` and the `LOG_*` constants, for `madlog`'s
  off-Apple branch.
* `pthread.h` — `pthread_mutex_t` over a `CRITICAL_SECTION` (recursive), for
  `MADOperation.m`'s state lock.
* the `NSData+ReadingOptions` shim is **dropped** — the pinned GNUstep master
  already carries `NSDataReadingOptions` and `-options:error:`.
* `NSPropertyListSerialization+Stream.m` gains an explicit
  `#import <Foundation/NSData.h>` (Windows header-include-order divergence), and
  reads the already-open stream rather than opening it again — a second open
  leaks a `FILE_SHARE_READ` handle that blocked the `.mdcache`'s atomic rewrite
  (the repeated-export failure).
* `unistd.h` maps POSIX `open`/`read`/`write`/`close`/`access`/`chdir`/`mkdir`
  onto the UCRT `_`-spellings, and `open` ORs in `_O_BINARY` so a file's bytes
  are read raw — the UCRT's text-mode default treated the SQLite store's `0x1A`
  byte as EOF, which was the `write --reproducible` 518-byte-archive bug.
* `dirent.h`, `libgen.h`, `sys/{unistd,fcntl,inotify}.h` — the container code's
  POSIX imports; `sys/inotify.h` is an inert stub (`inotify_init1` answers `-1`,
  so `MADDirectoryMonitor` is a no-op on Windows).
* `MADCompat.h` drops the `<endian.h>` + `htonll`/`ntohll` block (not used by
  these two frameworks, and `<endian.h>` does not exist on Windows).
* `MADCompat.h` gains a `static inline strlcat` — the Windows UCRT has no
  `strlcat`/`strlcpy` (BSD/Apple spellings; glibc 2.38+ provides them, which is
  why Linux needs no shim), and `MADQueryCacheAddRow.m` reaches for it.
* `NSURL+FileSystem.m` answers `-fileSystemRepresentation` with
  `self.path.UTF8String` instead of GNUstep's UTF-16 `GSNativeChar*` spelling,
  which broke `sqlite3_open_v2`'s path when masqueraded as `const char *`.

Two shared-source changes were unavoidable, both minimal and portable (the
Linux CI and Apple suites are the gates):

* `madlib.c` defines `itoa`/`ltoa`/`ultoa`, which collide with the Windows UCRT.
  They are renamed `mad_itoa`/`mad_ltoa`/`mad_ultoa` (and their callers
  updated), behaviour-neutral on Apple and Linux. See `docs/project/MAD_WINDOWS.md` §5.
* `MTStack.m`/`MTQueue.m`/`MTLinkedList.m` store their fast-enumeration cursor
  node pointer in `NSFastEnumerationState.extra[0]`, which is `unsigned long` —
  32 bits on Windows (LLP64), where a pointer does not fit. They now copy the
  pointer with `memcpy` (correct on LP64 and LLP64 alike) and hold it in an
  `__unsafe_unretained` local (the collection owns the node chain). See
  `docs/project/MAD_WINDOWS.md` §5.

## The CLI (`mad.exe`)

`build.ps1` builds `mad.exe` from `CLI/Source`, linked whole against every
framework object, the SQLite library, and the archive stack (libarchive + zlib +
bzip2). Run it from a prompt with `C:\GNUstep\x64\Release\bin` on `PATH`:

```
mad inspect   CLI\Fixtures\London.portable.mad
mad schema    CLI\Fixtures\London.portable.mad
mad query     CLI\Fixtures\London.portable.mad
mad refresh   CLI\Fixtures\London.portable.mad        # 76 rows
mad export    CLI\Fixtures\London.portable.mad --format json --out out.json --deterministic
mad write     CLI\Fixtures\London.portable.mad --out copy.mad --reproducible
```

The export digests are byte-identical to the Mac/Linux pins in `Linux/README.md`
(json `569c6ee2…`, csv `773f6215…`, text `7dcee96c…`, html `285541ed…`,
html-flow `0565204a…`, json-report `9d01d0da…`), and `write --reproducible`
writes the same 16261-byte document the Mac and Linux write
(`09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5`).
`export` refreshes the document itself and rewrites the row cache; repeated
exports in the same user work (the `.mdcache` rename issue is fixed — see
`Engine/Compat/NSPropertyListSerialization+Stream.m`).

## Known gaps

* `BDHost` (reverse DNS) and `MADKeyChain` (Security.framework) are excluded;
  `BDHostTests` is not registered on Windows for the same reason (its class
  cannot link without `BDHost.m`). `BDHost` needs a Winsock2 port.
* The database drivers (MADMySQL, MADTds/MADTdsClient, MADPostgres) are Phase 3b.
  Four MAD suites that need those drivers — `MADDatabaseDriverDispatchTests`,
  `MADQueryFullTests`, `MADSQLParserTests` and `MADQueryMaxFieldLengthTests` —
  are likewise deferred to Phase 3b and recorded in `build.ps1`, not skipped
  silently.

## Third-party and licensing

The Windows engine is a distribution surface of its own. It is registered in
`docs/project/THIRD_PARTY_LICENSES.md` §10, and its notices and texts travel in
`ThirdParty/Licenses/` (the C libraries shared with the Apple app) and
`ThirdParty/Licenses/Windows/` (the GNUstep runtime):

| Component | Licence | Notes |
|---|---|---|
| GNUstep Base, gnustep-corebase | LGPL-2.1-or-later | runtime DLLs; relink offer |
| libiconv (library) | LGPL-2.1-or-later | the `iconv` tools are GPL and are not shipped |
| libobjc2 (incl. libBlocksRuntime) | MIT | retain the notice |
| libdispatch | Apache-2.0 with the Swift runtime exception | ship the licence text with the exception |
| libffi | MIT | retain the notice |
| SQLite, zlib, bzip2, libarchive | public domain / Zlib / bzip2 / BSD-2 | the existing §3.1 entries |
| OpenSSL, FreeTDS, MariaDB Connector/C, libpq | Apache-2.0 / LGPL-3.0 election / LGPL-3.0 election / PostgreSQL | the existing §3.1–§3.4 entries; FreeTDS's `sybdb.h` is marked |

`gnustep-make` is GPL-3.0-or-later **build tooling** and is not distributed; its
`Testing.h` is compiled only into test binaries, which are not shipped. The
GNUstep Base command-line tools (`gdomap`, `gdnc`, `defaults`, `plutil`,
`gspath`) are GPL-3.0-or-later and are **not** part of `mad.exe`; do not package
them unless the GPL text and corresponding-source offer are added. Clang,
Visual Studio, the Windows SDK, CMake, Ninja, NASM and MSYS2 are build tools and
are not distributed.

The build records the actual DLL/static split with `dumpbin /dependents` (or
`llvm-objdump -p`) on `mad.exe`; do not infer it. A Windows package must copy
`ThirdParty/Licenses` and `NOTICE` beside `mad.exe` or into the WPF app package.
The WPF **About** window (Phase 5 shell proof, completed in Phase 6) must render
the Windows component list, the GNUstep and C-library texts, and the LGPL relink
offer from the register and `ThirdParty/Licenses/Windows/`. The iOS and macOS
About screens stay Apple-only; they must not claim the Apple app links GNUstep.
The written offer is in `ThirdParty/Licenses/README.md`.

## Supported Windows versions

`.NET 10`'s supported OS matrix (Windows 10 Enterprise 21H2/1809/1607,
Windows 11) and GNUstep's Windows 10 1903+ baseline. Tested on Windows 11
Enterprise 26H2 (build 26300). Windows 7/8 are not supported by .NET 10.
