# Compiling the MAD Engine on Windows — architecture and decision record

Written 2026-11-18 against `master` for the `windows-engine` branch (Phase 2
of the Windows PoC). The Windows build is the sibling
of `Linux/`: the headless engine's Objective-C frameworks compiled natively on
Windows with Clang against GNUstep Base, so the same engine that runs the macOS
app and the Linux CLI can run on Windows. This document is the technical
companion to `Linux/README.md` / `docs/project/MAD_LINUX.md`; it records the
toolchain recipe, why each piece is pinned, and the decisions this increment
made.

---

## 1. What this is, and what it is not

The target is a native Windows MAD Designer (WPF on .NET 10 LTS) reusing the
existing headless Objective-C engine compiled natively for Windows. The engine
build lands under `Windows/`, a sibling of `Mac/` and `Linux/`; the WPF app is
a later phase (`Windows/App`, not yet created).

This increment proves the toolchain and the framework port. Phase 2 (the first
increment) built **MADDataStructures** and **MADFoundation** and ran a smoke
test. Phase 2b (this revision) adds **MADAPI** (the transitive dependency
MADSqlite3 pulls in) and **MADSqlite3**, compiles the pinned SQLite
amalgamation into a static library, and ports the Linux test suites for
MADDataStructures, MADFoundation and MADSqlite3 (GNUstep `Testing.h` +
`MADTestSupport.h`). It still does not build the remaining headless frameworks,
the CLI, or the app.

---

## 2. The toolchain recipe, and why each piece is pinned

The summary (this section stands alone):

### 2.1 Compiler: Clang 20.1.8

The Phase 1 startup crash (`0xC0000005` in every Foundation binary) was a
runtime regression in the floating-master GNUstep components — the seven pins
in §2.3 fix it — not a Clang 23 codegen bug. Clang 20.1.8 is the CI-tested
compiler and part of the proven recipe; Clang 22/23 with the pins were not
tested. This is a pin, not a preference; do not upgrade LLVM without a new
viability test.

### 2.2 The STL gate override

This machine ships Visual Studio 2026 (18.12.0), whose MSVC STL hard-requires
"Clang 22 or newer" (`_MSVC_STL_UPDATE 202609L`, `yvals_core.h:923`):

```c
#elif defined(__clang__)
#if __clang_major__ < 22
_EMIT_STL_ERROR(STL1000, "Unexpected compiler version, expected Clang 22 or newer.");
```

The override `-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH` is the STL's own
escape hatch. It is proven benign: a `<map>`-using C++ program compiles and
runs with Clang 20.1.8 + the override, and so do the full toolchain and MAD's
`.mm` files (which include `<map>`/`<vector>`). It is applied to the toolchain
build (`Engine/toolchain/stl-gate-override.patch`) and to every Objective-C++
translation unit in the framework build.

### 2.3 The seven pinned GNUstep revisions (the floating-master regression)

`gnustep/tools-windows-msvc` clones the latest master of every component
(`TAG=` is empty in its phase scripts). Its CI (`.github/workflows/ci.yml`)
builds and packages the toolchain but **never runs a binary**, so a runtime
regression went unnoticed. A/B testing isolated it:

| Component | 11-14 (runs) | 11-17/18 master (crashes) |
|---|---|---|
| libobjc2 | `a21ae931` | `762f9d7` |
| gnustep-base | `24654296` | `ff647838` |
| libdispatch | `22798930` | `20b4c8b2` |
| gnustep-make | `e7c0730d` | `8fa108c7` |
| libffi | v3.8.0 | v3.8.1 |
| libiconv | v1.19 (`a536e24a`) | v1.19.1 |

The fix is to pin the seven known-good 11-14 revisions
(`Engine/toolchain/revision-pins.patch`). The driver itself is also pinned to
commit `54d08e57` (its master floats and must not be tracked). Both facts are
recorded in `Windows/Engine/toolchain.conf`.

### 2.4 The build wrapper's three non-obvious requirements

The toolchain's `build.bat` must run from the `vcvars64` developer environment,
with `BASH` set to MSYS2's shell, and by **absolute** `build.bat` path, without
editing `PATH` (the vcvars64 `PATH` is ~2500 chars and breaks cmd's bare-name
resolution). From Git Bash, invoke `cmd` with `cmd //c` (not `cmd /c`); from
PowerShell, `cmd /c` is correct. `Engine/toolchain/bootstrap.ps1` encapsulates
all three.

---

## 3. The build entry point

`Windows/Engine/build.ps1` reproduces the recipe from the repo:

1. **Prerequisite check** — Clang 20.1.8, lld, CMake, Ninja, MSYS2, git, curl,
   tar, `llvm-lib`, VS 2026, the Windows SDK, NASM.
2. **Idempotent toolchain bootstrap** — `Engine/toolchain/bootstrap.ps1`
   clones the pinned driver, applies the two patch files, and builds GNUstep
   from source into `C:\GNUstep` (configurable; ~20–30 min on first run).
3. **SQLite library build** — download the 3.53.3 amalgamation from
   `Engine/libraries.conf`, verify its sha256, extract, compile `sqlite3.c`
   with the `Compressor/sqlite3.xcconfig` option list, and archive it into a
   COFF `sqlite3.lib` with `llvm-lib`.
4. **Framework build** — compile MADDataStructures, MADFoundation, MADAPI and
   MADSqlite3 (plus the `Engine/Compat` shims).
5. **Test build** — compile and link one executable per ported test file (plus
   the smoke test).
6. **Test run** — run the smoke test and every suite; exit non-zero on any
   failure.

The framework compile flags match the Linux build's Debug profile: GNUstep's
`gnustep-config --objc-flags` under `--enable-debug-by-default` (which the Linux
toolchain uses) carries `-DDEBUG`, so `build.ps1` passes `-DDEBUG=1` to every
translation unit — library and test alike — and does **not** define
`NS_BLOCK_ASSERTIONS`, keeping `NSAssert` active exactly as on Linux.

**Decision — `build.ps1` drives Clang directly, not through CMake.** CMake's
Objective-C language support on Windows is broken for the combination this
recipe requires (the GNU-driver `clang` targeting `x86_64-pc-windows-msvc`):
its Objective-C link probe passes GNU-ld flags (`--out-implib`, `-nostdlib`,
`-nostartfiles`) to `lld-link` and appends `.lib` to library names already
prefixed with `-l`, so the link fails (`undefined symbol: $_OBJC_CLASS_NSObject`,
and section-GC errors for ObjC metadata). The proven recipe is direct `clang`
invocations — the viability phase's `compile-mad.sh` / `link-and-run.sh` — and
`build.ps1` is that recipe cleaned up and made idempotent. The per-framework
source lists still live in `Engine/cmake/<Name>Sources.cmake` (the canonical,
CMake-ready inventory with exclusion reasons), and `build.ps1` reads them back
so the two cannot drift; a real CMake build can consume them unchanged once
CMake's Windows Objective-C support lands.

---

## 4. What compiles, and the Windows shims

| Framework | Windows build | Excluded, and why |
|---|---|---|
| MADFoundation | 26 of 27 (+ `madlib.c`) | `MADKeyChain` (Security.framework; already excluded on Linux) and `BDHost` (POSIX-socket reverse DNS — `sys/socket.h`/`netpacket/packet.h`/`ifaddrs.h`/`arpa/inet.h`; needs a Winsock2 port). The umbrella goes with `MADKeyChain`. |
| MADDataStructures | all 17 | (`madmap.cpp` is not in the Xcode target either) |
| MADAPI | 8 of 11 | the three connection view controllers (`MADConnectionViewController`, `MADConnectionSQLGenericViewController`) — UIKit, not headless. Not a Phase 2b deliverable of its own; MADSqlite3's transitive dependency. |
| MADSqlite3 | all 26 | five orphan `.m` files not in the Xcode target either (named in `Engine/cmake/MADSqlite3Sources.cmake`) |

`Windows/Engine/Compat/` is a copy of `Linux/Compat`, adapted for Windows:

* **`syslog.h`** — no-op `syslog()` and the `LOG_*` constants, for `madlog`'s
  off-Apple branch (`madlog.h` includes `<syslog.h>` when `__APPLE__` is not
  defined).
* **`pthread.h`** — `pthread_mutex_t` (recursive) over a Windows
  `CRITICAL_SECTION`, for `MADOperation.m`'s state lock.
* **`NSData+ReadingOptions` dropped** — the pinned GNUstep master already
  carries `NSDataReadingOptions` and `-options:error:`; the Linux shim
  (which re-declares them, for gnustep-base 1.31.1) would be a duplicate
  interface on Windows.
* **`NSPropertyListSerialization+Stream.m`** gains an explicit
  `#import <Foundation/NSData.h>` — a Windows header-include-order divergence
  (Linux's headers happen to reach NSData first; Windows' do not).
* **`MADCompat.h`** (the force-included prelude) drops the `<endian.h>` +
  `htonll`/`ntohll` block — neither MADFoundation nor MADDataStructures uses it
  (grep-verified), and `<endian.h>` does not exist on Windows. The driver layer
  (`MAD`) will need a Windows byte-order shim when it is ported.
* **`MADCompat.h`** also gains a `static inline strlcat` — the Windows UCRT has
  no `strlcat`/`strlcpy` (BSD/Apple spellings; glibc 2.38+ provides them, which
  is why Linux needs no shim), and `MADQueryCacheAddRow.m` reaches for it.
* **`NSURL+FileSystem.m`** answers `-fileSystemRepresentation` with
  `self.path.UTF8String` rather than GNUstep's `GSNativeChar*` spelling (UTF-16
  on Windows), which broke `sqlite3_open_v2`'s path when masqueraded as
  `const char *`.

The other Linux shims carry over unchanged, since the Windows and Linux
GNUstep-base are the same 1.31.x line.

---

## 5. The unavoidable shared-source changes

Two shared-source changes were required, both minimal and portable (the Linux
CI and the Apple suites are the gates):

### 5.1 The `madlib.c` `itoa`/`ltoa`/`ultoa` rename

`MADFoundation/Source/madlib.c` defines `itoa`/`ltoa`/`ultoa`, which collide
with the Windows UCRT's three-argument non-standard names of the same spelling.
They are renamed `mad_itoa`/`mad_ltoa`/`mad_ultoa`, and every caller updated:

* `MADFoundation/Source/madlib.{c,h}` — the definitions and declarations;
  also drops `#import <strings.h>` (unused, and absent on Windows).
* `MADFoundation/MADFoundationTests/madlibTests.m` and `Linux/Tests/madlibTests.m`
  — the tests.
* `MAD/Source/model/MADModelQueryTable.m`, `MAD/Source/rptq/RptqQueryTable+Extras.m`
  (`ltoa`) and `MADSqlite3/Source/MADDataTableFast.m`,
  `MADSqlite3/Source/MADQueryCacheAddRow.m` (`ultoa`).

This is a pure mechanical rename, behaviour-neutral on Apple and Linux.
`uitoa`, `reverse`, `count_digits`, and `count_digits_ul` are untouched (they
do not collide with the UCRT). The `itoa` reference in `MADExplorer` is inside
a commented-out block and is not a caller.

### 5.2 The fast-enumeration cursor pointer

`MTStack.m`, `MTQueue.m` and `MTLinkedList.m` store their `countByEnumerating…
` cursor node pointer in `NSFastEnumerationState.extra[0]`, cast through
`unsigned long`. That is 32 bits on Windows (LLP64) but 64 on Linux/Apple
(LP64), so the pointer was truncated and multi-batch enumeration (any
collection over one stack-buffer's worth of items) crashed or yielded garbage.
The three files now copy the pointer into `extra` with `memcpy` (correct on
both LP64 and LLP64) and hold it in an `__unsafe_unretained` local — the
collection owns the node chain, which outlives the call, so the borrowed
pointer is the honest ownership model on every platform. The change is
behaviour-neutral on Apple/Linux (the same pointer bytes move through).

---

## 6. Known gaps and next increments

* **`BDHost`** (reverse DNS) and **`MADKeyChain`** (Security.framework) are
  excluded; `BDHost` needs a Winsock2 port, `MADKeyChain` has no Windows
  keychain equivalent yet. `BDHostTests` is not registered on Windows for the
  same reason (it cannot link without `BDHost.m`) — recorded, not skipped.
* **The remaining headless frameworks** (`MAD`, the drivers, `MADFileManager`,
  `MADCocoaExtensions`, …) and **the CLI** are the next increments.
* **The WPF app** is a later phase.

## 7. Supported Windows versions

.NET 10's supported OS matrix (Windows 10 Enterprise 21H2/1809/1607, Windows
11) and GNUstep's Windows 10 1903+ baseline; tested on Windows 11 Enterprise
26H2 (build 26300). Windows 7/8 are not supported by .NET 10.

## Related documents

* `docs/project/MAD_LINUX.md` and `Linux/README.md` — the Linux build this
  Windows build mirrors.
* `docs/project/MAD_MACOS.md` and `Mac/README.md` — the native macOS application
  whose behaviour the WPF app will mirror.
