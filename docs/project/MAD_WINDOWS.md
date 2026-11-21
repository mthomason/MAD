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
build lands under `Windows/`, a sibling of `Mac/` and `Linux/`; the WPF app
followed in Phases 5–6f (`Windows/App`; §6e–§6i).

The Phase 2b increment proved the toolchain and the framework port. Phase 2 (the
first increment) built **MADDataStructures** and **MADFoundation** and ran a
smoke test. Phase 2b added **MADAPI** (the transitive dependency MADSqlite3
pulls in) and **MADSqlite3**, compiled the pinned SQLite amalgamation into a
static library, and ported the Linux test suites for MADDataStructures,
MADFoundation and MADSqlite3 (GNUstep `Testing.h` + `MADTestSupport.h`). It did
not yet build the remaining headless frameworks, the CLI, or the app.

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

> This section records the Phase 1/2 gaps as they stood then. Phases 3a–6e
> closed all of them except the accepted ones; see §6b–§6h, and
> `Windows/README.md` for the current state.

* **`BDHost`** (reverse DNS) and **`MADKeyChain`** (Security.framework) are
  excluded; `BDHost` needs a Winsock2 port, `MADKeyChain` has no Windows
  keychain equivalent yet. `BDHostTests` is not registered on Windows for the
  same reason (it cannot link without `BDHost.m`) — recorded, not skipped.
* **The remaining headless frameworks** (`MAD`, the drivers, `MADFileManager`,
  `MADCocoaExtensions`, …) and **the CLI** are the next increments.
* **The WPF app** is a later phase.

## 6b. Phase 3a — the frameworks, the archive stack, and the CLI

Phase 3a builds the remaining headless frameworks, the `.mad` container's C
libraries, and `mad.exe`:

* **Frameworks.** `MADCocoaExtensions` (7 files), `MADFileManager` (10) and `MAD`
  (168) join the Phase 2/2b set, from the same Linux source lists and with the
  same exclusion reasons (the UI tail, `MADocument`, the keychain operations,
  `MADCloud`). `MADDirectoryMonitor` compiles against an inert `sys/inotify.h`
  shim — the CLI is single-shot and needs no change events.
* **C libraries.** `zlib` 1.3.2, `bzip2` 1.0.8 and `libarchive` 3.8.9 (the Linux
  pins) build in `build.ps1`: zlib and bzip2 by direct clang + `llvm-lib`,
  libarchive through CMake + clang-cl (zlib/bzip2 in; xml2/lzma/zstd/lz4/openssl
  and the tools out), matching `Linux/lib/libraries.sh` / Compressor. The barcode
  stack — `libpng` 1.6.59 and `zint` 2.16.0 — builds the same way (both through
  CMake + clang-cl), so `MADBarcodes` compiles and renders here too.
* **CLI.** `CLI/Source` → `mad.exe`, whole-linked. `inspect`, `schema`, `query`
  and `refresh` (76 rows) run on `London.portable.mad`; all six export digests
  match the Mac/Linux pins byte-for-byte, and `write --reproducible` writes the
  same 16261-byte document (`09815b24…`) the Mac and Linux write.

### 6b.1 The two Windows-only runtime fixes (Phase 3a final)

* **`write --reproducible` (the 116-byte store read).** The archive writer's
  `open`/`read` went through `Windows/Engine/Compat/unistd.h`, whose `open`
  mapped to the UCRT `_open` — which defaults to *text* mode.  A SQLite store
  contains a `0x1A` (Ctrl-Z) byte at offset 116; text-mode `_read` stops there
  as EOF, so the writer saw 116 of 663552 bytes and emitted a 518-byte archive.
  The shim now ORs `_O_BINARY` into the flags, so `open`/`read` are the POSIX
  byte-for-byte behaviour.  Guarded to the Windows shim; the Apple/Linux bytes
  are unchanged.  Pinned by `MADArchiveManagerTests` (5 tests, 0 needs).
* **Repeated `export` in one user (the `.mdcache` rename).** The row-cache
  `.mdcache` is a plist read through `NSInputStream` then rewritten atomically.
  `Compat/NSPropertyListSerialization+Stream.m` opened the already-open stream
  a second time; GNUstep's win32 `GSFileInputStream -open` calls `CreateFileW`
  (`FILE_SHARE_READ`) every time and overwrites `_loopID`, leaking the first
  handle.  That handle blocked the later `MoveFileEx` over the `.mdcache`
  (`"being used by another process"`), so the second export failed.  The shim
  now reads the open stream without re-opening it (Apple's contract), and two
  exports in one user both succeed.

### 6b.2 The test inventory

The copied MAD/MADFileManager/MADCocoaExtensions/MADAPI suites are wired into
`build.ps1` (fixture paths adapted for `Windows/Engine/Tests`): **107 ported
suites + the smoke test, 966 tests, 6 needs, 5 skips, 0 failures**. The six
needs match the Linux image's platform gaps: `MADDirectoryMonitorTests` (3 — the
Windows monitor is inert), `MADStoreTests` (1 — Core Data + `MAD.momd`) and
`RptqStoreContextTests` (2 — the converter/document path). Four MAD suites that
need the Phase 3b drivers are deferred and recorded in `build.ps1`:
`MADDatabaseDriverDispatchTests`, `MADQueryFullTests`, `MADSQLParserTests` and
`MADQueryMaxFieldLengthTests`. The five skips are the SQLite benchmark at its
default scale.

The additional Windows `Compat` shims are `unistd.h`, `dirent.h`, `libgen.h`,
`sys/{unistd,fcntl,inotify}.h`, plus `MADCompat.h` gaining `strlcpy`, the
`S_IS*`/`S_IR*` mode macros, `ssize_t`/`mode_t`, `M_PI`, `arc4random` and
`gmtime_r`. The additional minimal shared-source changes (all `#if __APPLE__`-safe
or byte-neutral on Linux; the Linux CI and Apple suites are the gates):

* `MADReportSectionRepresentation.m` drops an empty `@finally` (clang 20.1.8's
  GNUstep-2.2 + ARC codegen crashed on it).
* `madtar.m` gains a `_WIN32` mtime branch (the UCRT `struct stat` has `st_mtime`,
  no `st_mtim`).
* `MADArchiveManager.m`, `MADStore.m` and `MADCLIInspect.m` use
  `NSString -UTF8String` where they took `-fileSystemRepresentation` (GNUstep's
  NSString spelling returns UTF-16 on Windows).
* `MADDatabaseConnection+Constructor.m`'s `+Identifier:` returns the four
  document-format constants directly, so a process linking only Sqlite3 can still
  map a stored `driverID` to a type. (Phase 3b removed this guard — see §6c.)

## 6c. Phase 3b — the drivers, BDHost and the live fixtures

Phase 3b adds the four database drivers and the C libraries they link:

* **C libraries** (`Windows/Engine/libraries.conf`, `build.ps1` §3c): OpenSSL
  3.5.9 (Strawberry Perl + `VC-WIN64A` + `nmake`, static), FreeTDS 1.4.27 (CMake
  `db-lib`, `ENABLE_MSDBLIB`, `sybdb.h` BOOL edit), MariaDB Connector/C 3.4.11
  (CMake `mariadbclient`, auth plugins static), libpq 17.11 (**Meson + MSVC
  `cl.exe`**, `libpq_st` + `libpgcommon_shlib` + `libpgport_shlib` merged into one
  COFF `libpq.lib`). PostgreSQL 17 dropped the MSVC build, so Meson is its Windows
  path; `cl.exe` (not `clang-cl`) is used because PostgreSQL's Meson checks
  `cc.get_id() == 'msvc'` and `clang-cl` reports `clang-cl`, silently dropping
  `win32gettimeofday.c`/`dirent.c` and the `win32_msvc` include dir. Meson and
  Strawberry Perl are documented prerequisites.
* **BDHost** — `MADFoundation/Source/BDHost.m` gains a `#elif defined(_WIN32)`
  branch over `winsock2.h`/`ws2tcpip.h` (`WSAStartup` once,
  `getaddrinfo`/`getnameinfo`, IPv4-only); `+ipAddresses`/`+ethernetAddresses` are
  compiled out on Windows. `BDHostTests` passes 3/3.
* **Drivers** — four `cmake/*Sources.cmake` lists (18/1/3/4 files) and header shims
  for `<MADTds/sybdb.h>`, `<MADTdsClient/MADTdsClient.h>` and
  `<MADPostgres/libpq-fe.h>` etc. `MADTdsDb.m` is linked normally (its global
  `err_handler` collides with `MADDatabaseSQLServer.m`'s). The Phase 3a
  `+Identifier:` guard is removed — the registry lookup works with all four drivers
  linked, pinned by `MADDatabaseDriverDispatchTests` (9/9).
* **Test inventory** — **129 suites + the smoke test, 1308 tests, 6 needs, 5 skips
  (48 when the live containers are not running), 0 failures** (the barcode increment
  added `MADBarcodesTests` and `MADBarcodeExportTests`; the image closure added
  `MADImageElementTests` and `MADImageExportTests`). Live suites against the local
  `127.0.0.1` containers: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29, `MADPostgresLiveTests`
  14/14. CLI `mad refresh` returns 50 MySQL / 20 TDS / 25 PostgreSQL rows.

## 6d. Phase 4 — the stdio JSON process contract

Phase 4 adds `mad serve`, the long-lived process boundary the WPF shell will use. It
reads newline-delimited JSON on standard input and writes one newline-delimited JSON
response per request on standard output; diagnostics stay on standard error, so the
two never mix. The wire shape reuses the project's existing JSON contract rather than
inventing a parallel one.

**Request / response** — one JSON value per line, UTF-8, `\n`-terminated:

```text
request:   { "id": <int|string>, "method": "<name>", "params": { … } }
ok:        { "id": <id>, "ok": true,  "result": { … } }
error:     { "id": <id|null>, "ok": false, "error": { "code": <int>, "message": "…" } }
```

`id` is client-chosen and echoed back for correlation; a malformed request answers with
`"id": null`. `error.code` is the CLI's exit code (MADCLI.h): 1 usage/protocol, 2 bad
document, 3 database unreachable, 4 query failed, 5 export failed. A malformed line, an
unknown method, a missing parameter and an unexpected engine exception all answer
`ok: false` with a message — never a traceback — and the session keeps running.

**Methods:**

| method | params | result |
|---|---|---|
| `open` | `path`, optional `host`/`port`/`database` | `handle`, `filename`, `driver` |
| `create` | `path`, `driver` + connection fields, optional `credentials` | `handle`, `filename`, `driver` (the created document) |
| `test-connection` | `driver` + connection fields, optional `credentials` | `tableCount` |
| `describe` | `handle` | `driver`, `columns` (key/name/table/type), `tables` (name + fields) |
| `connection` | `handle` | `driver` + `file`/`host`/`port`/`database`/`server` |
| `apply-connection` | `handle`, `driver` + connection fields, optional `credentials` | `{}` |
| `query` | `handle` | `sql` |
| `query-model` | `handle` | `driver` token, `sql`, `sqlSourceText`, `tables`/`links`/`predicates`/`groups` (with store identifiers) |
| `add-table` | `handle`, `table` (schema name) | the full `query-model` |
| `remove-table` | `handle`, `table` (query-table id) | the full `query-model` |
| `add-link` | `handle`, `leftField`, `rightField` (field ids) | the full `query-model` (Left Outer Join default) |
| `set-link-type` | `handle`, `link`, `type` | the full `query-model` |
| `swap-link` | `handle`, `link` | the full `query-model` |
| `delete-link` | `handle`, `link` | the full `query-model` |
| `add-predicate` | `handle`, `leftField`, `operator`, `value` | the full `query-model` |
| `remove-predicate` | `handle`, `predicate` | the full `query-model` |
| `add-group` | `handle`, `field`, `sort` | the full `query-model` |
| `remove-group` | `handle`, `group` | the full `query-model` |
| `validate-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` (the plan's counts) |
| `apply-sql` | `handle`, `sql` | `tables`, `links`, `predicates`, `groups` |
| `refresh` | `handle`, optional `rows`/`credentials` | `rowCount`, `elapsed` |
| `export` | `handle`, `format`, optional `path`/`deterministic` | `format` + `data` (the exporter's bytes) or `path` + `bytes` |
| `write` | `handle`, `out`, optional `reproducible` | `path`, `bytes` — serializes the live document |
| `shutdown` | — | `{}`, then the process exits 0 |

The connection methods (`create`, `test-connection`, `connection`, `apply-connection`)
take a `driver` token — `sqlite3` | `mysql` | `sqlserver` | `postgres` — and
driver-specific fields: SQLite takes `file`; the server drivers take
`host`/`port`/`database` (SQL Server also takes an optional `server` instance), plus the
existing `credentials` (`user:password`) string. They reuse the engine's
`createDocumentAtURL:`, `MADDatabase` (connect/getTables/close) and
`applyDatabaseConnection:` — the same calls the Mac's connection window makes.

`export` is the export seam (`MADReportExporting` / `MADReportExporterRegistry`), not a
new schema: `format: "json"` returns the exact `mad.report/1` bytes `mad export
--format json` writes (`MADReportExporterJSON` — `columns` and `rows`), and `format:
"csv"` the RFC 4180 bytes. A format this build cannot produce (for example `pdf` off
Apple) answers `error.code` 5 with the exporter's reason. `describe`'s `columns` are
those same `mad.report/1` columns (`MADReportExportSource`), and its `tables` is the
stored database schema `mad schema` prints. `open` applies `host`/`port`/`database` the
way the one-shot verbs do, so a checked-in document can run against a different server
for the session. `write` now serializes the live session document rather than re-opening
`sourceURL`, so a connection applied in-session is persisted. End-of-file on standard
input is a clean shutdown, as is `shutdown`.

The `query-model`/`add-table`/…/`apply-sql` methods are the Phase 6b Query workspace
extension. The original `serve` contract exposed the query only as its generated `sql`,
which the Mac derives by mutating the `RptqQuery` objects in-process; the WPF app has no
such in-process handle, so these methods close that gap. `query-model` reads the full
query model — tables/fields/links/predicates/groups with their store identifiers, the
entered `sqlSourceText`, and the driver token — and every mutation method answers that
same shape, so the client replaces its snapshot atomically. The mutations call the same
factories and `MADSQLQueryDocument` helpers the Mac's `MADMacQueryViewController` uses
(`newQueryTableForSchemaTable:`, `newQueryLinksWithLeftField:`, `addQueryGroupWithQueryField:`,
`removeGroupWitObjectID:`, …), and `validate-sql`/`apply-sql` run the existing
`MADSQLParser` → `MADSQLStatementResolver` → `MADSQLQueryCompiler` path unchanged.
`query` now returns the all-fields SQL first and falls back to the active-field select,
matching the Mac's `generatedSQLString:` — so a fresh document with no report elements
still yields SQL.

**Client and tests.** `Windows/Client/` holds the .NET 10 console acceptance client
(`Mad.Client`) and the xunit suite (`Mad.Client.Tests`), both pinned by
`Windows/global.json`. The client spawns `mad serve` and covers the seven methods; the
tests exercise the success path over `CLI/Fixtures/London.portable.mad` (open → describe
→ query → refresh 76 rows → export json/csv → shutdown, exit 0, no orphan process),
malformed requests, an unknown method, a bad document, an unavailable format, and
process shutdown.

## 6e. Phase 5 — the WPF shell proof

Phase 5 adds the first WPF app on top of the Phase 4 process boundary: a
`net10.0-windows` shell under `Windows/App/` that proves the engine runs from a real UI.
It reuses `Mad.Client` unchanged and adds an async `EngineService` (a `SemaphoreSlim`
serializes the single-threaded line protocol; every blocking call runs on the thread
pool), a hand-rolled MVVM layer (`ObservableObject`, `RelayCommand`, `AsyncRelayCommand`),
and a `DocumentViewModel` that mirrors the Mac's `MADMacDocument` for the first slice:
open → describe → query → refresh → export.

The shell has the three-workspace frame (MAD Query / Designer / Viewer). Query shows the
stored schema and generated SQL; Viewer shows the refreshed rows in a `DataGrid` (fed by
parsing `mad.report/1` into a `DataTable`) and exports CSV/JSON; Designer is a Phase 6
placeholder. On startup it auto-opens `CLI/Fixtures/London.portable.mad` (override with
`MAD_DOCUMENT`), so it demos with zero clicks. The About window (Overview / License &
Notice / Acknowledgements) renders the Windows dependency register from
`ThirdParty/Licenses/Windows/` and the relink offer — the Windows component set, never the
Apple one.

Acceptance is verified headlessly by `Windows/App/Mad.Designer.Windows.Tests` (xunit):
open London → describe (21 columns / 11 tables / driver "Sqlite 3") → refresh 76 rows →
export json (76 rows) / csv (78 lines) → clean shutdown with no orphan, plus the
`mad.report/1` parser and the licence-register checks. The app and tests build and run on
`net10.0-windows` (pinned by `Windows/global.json`); the Linux CI is unaffected (it never
builds .NET).

## 6f. Phase 6c — the report-layout model (Designer)

Phase 6c extends `serve` with the report-layout model the Designer workspace edits, using the
same granular pattern as the 6b query-model methods. `layout-model` reads the full snapshot;
every mutation method mutates the existing `RptqDocumentSection`/`RptqDocumentElement` objects
and answers that same snapshot, so the client replaces its state atomically. Barcode is part of
the model (the barcode-closure increment added the element kind, its content edits, the
symbology catalogue, an engine-rendered preview and the WPF composer — §6j; the image
closure followed with PNG content and the WPF file picker — §6k). Colours are deferred (no
portable colour type in the headless model). Undo/redo is client-side.

| method | params | result |
|---|---|---|
| `layout-model` | `handle` | `paperSize`, `sections[]`, `elements[]`, `fields[]` |
| `add-element` | `handle`, `kind` (`label`\|`data-field`\|`aggregate`\|`image`\|`line`\|`barcode`), `section`, `x`, `y`; `data` for an image (base64 PNG) | the full snapshot |
| `remove-elements` | `handle`, `elements: [id…]` | the full snapshot |
| `duplicate-elements` | `handle`, `elements: [id…]` | the full snapshot |
| `move-elements` | `handle`, `elements: [id…]`, `section` | the full snapshot |
| `set-element-geometry` | `handle`, `elements: [{id,x,y,w,h}…]` | the full snapshot |
| `set-element-content` | `handle`, `element`, `content{text,field,function,scope,group,barcodeType,humanReadable,borderStyle,data}` (`data` is an image's base64 PNG; empty clears it) | the full snapshot |
| `set-element-typography` | `handle`, `elements: [id…]`, `style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | the full snapshot |
| `set-element-box-model` | `handle`, `elements: [id…]`, `box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | the full snapshot |
| `set-section` | `handle`, `section`, `{height,visible,pageBreak}` | the full snapshot |
| `set-paper-size` | `handle`, `paperSize` (`MTPaperType` int16: Letter 2 / Legal 7 / A4 19) | the full snapshot |

The snapshot carries the sections in the designer's canonical order (Report Header, Page
Header, Group Headers, Detail, Group Footers, Page Footer, Report Footer), each with `id`,
`type` (`MADocumentSectionType`), `title`, `height` (the interface height `layoutHeight`),
`visible`, `pageBreak` and `groupField`. Each element carries `id`, `type`
(`MADPrintPageElementType`), `section`, `x/y/w/h`, `text`, `field` (bound query-field id),
`table`/`column`, `function`/`scope`/`group` (aggregate), `fontname`/`fontsize`,
`bold`/`italic`/`underline`/`strikethrough`, `hAlign`/`vAlign`, `borderTop`/`borderBottom`/
`borderLeft`/`borderRight`, `padding` and `margin`. A barcode element additionally carries the
nested `barcode` object (§6j); an image element carries `image{data}`, the stored picture as
base64 PNG (empty when it has none — §6k). `fields[]` lists the query fields (with store ids)
for the sidebar browser and the binding popup.

## 6g. Phase 6d — the Viewer workspace (render, page size, export, print)

Phase 6d finishes the MAD Viewer on top of the 6a–6c shell. The Mac viewer renders a
paginated PDF in `PDFView`; **PDF is an accepted gap on Windows** (no PDFKit, and the
engine's `pdf` exporter is Apple-only), so the interim the plan names is HTML + print:

* **Render approach — WebView2 over the engine's HTML exporter.** The preview shows the
  exact `export --format html` bytes (one `<div class="page" data-index="N">` box per
  page, the same formatter the PDF and every other exporter use), hosted in a WebView2.
  The page count on the status line is the number of those page boxes, so the engine
  remains the only paginator and no exporter is reimplemented in C#. The preview adds
  only presentation chrome (grey desk, page gaps and shadows) through an injected style;
  the exported bytes are untouched. The HTML is written to a temporary file and navigated
  by URL because `NavigateToString` has a 2 MB ceiling a large report would hit. Zoom is
  the WebView2 `ZoomFactor`; page navigation scrolls the requested page box into view.
  **Print** uses `CoreWebView2.ShowPrintUI` — the interim HTML print path. The browser is
  created on `Loaded`, not in XAML, so the workspace composes headlessly for its tests.
* **`ViewerViewModel`** owns the page-size selection and its rendered lock (US Letter
  default, US Legal, A4), the zoom steps (0.25–4.0, 1.25×, 100% reset), previous/next
  navigation, the export-format catalogue, and the status line. The status line is the
  Mac's: `Rendered N pages from M cached rows.` with its singular/plural grammar, green on
  success and red on failure. Selecting a paper size does not change the rendered report
  until the next refresh (the Mac's `selectedPaperType`/`renderedPaperType` split); the
  selection survives refresh, and the export uses the rendered paper.
* **Export** offers the six formats this build produces — HTML Page, HTML Flow, CSV,
  JSON Data, JSON Full Report, and Plain Text — each with its own file extension
  (`html`, `html`, `csv`, `json`, `json`, `txt`). The toolbar carries the format selector;
  Export opens the save dialog filtered to the chosen format. PDF is not offered.
  Exporting before a refresh refreshes first, as the Mac's Export does.
* **Document integration.** `DocumentViewModel.RefreshAsync` runs the query and then calls
  `Viewer.RenderAsync`, which applies the selected paper through the document (so the
  Designer's snapshot follows) and loads the HTML preview. The Viewer's Refresh, Export
  and Print buttons all run through that same document path.
* **Engine correction.** `set-paper-size` mutated the stored `RptqDocument` but not the
  render document, whose `MTPaper` is cached after the first layout, so the second paper
  change never reached an export. It now also calls `setPaperType:` on the render document
  (the call the Mac viewer makes before refreshing) and re-formats a report that is already
  laid out, so the new size reaches an export that follows without another refresh.

The Viewer replaces Phase 5's placeholder rows grid: the rendered report is the workspace,
as on the Mac, and the rows remain available through the CSV/JSON exports.

**Tests.** `ViewerViewModelTests` (status grammar, format catalogue, page counting, zoom,
navigation, print request), `ViewerSurfaceTests` (the workspace materialised on an STA
thread — the toolbar, the six formats, the page-size selector, the status colour and the
page label), and `ViewerAcceptanceTests` against the engine (London → 5 pages / 76 cached
rows, page-size lock and persistence through A4 with the exported page box at 595 × 842,
every export format with its extension, and the paper-size switch A4 → Legal → Letter
reaching each export).

## 6h. Phase 6e — About, localization, and the WPF smoke test

Phase 6e closes the merge gate without changing the engine: it finishes the About
window's dependency register, localizes the WPF app into the Mac app's language
set, adds the WPF counterpart of `MADMacSmokeTest.m`, and brings this record and
`Windows/README.md` up to date. Public `docs/windows.md` and its translations are
deferred by design.

**About and the WebView2 notice.** The Viewer preview runs in the
**Microsoft Edge WebView2** control (NuGet `Microsoft.Web.WebView2` 1.0.4314.35).
The SDK that ships with the app is BSD-3-Clause and carries Microsoft's
third-party notices; the Evergreen WebView2 Runtime is a Microsoft
redistributable, not open-source software. The About window therefore lists
`Microsoft Edge WebView2` with both terms and the runtime attribution, all in
`ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`. The register is
`docs/project/THIRD_PARTY_LICENSES.md` §10. The rest of the component list is
unchanged (GNUstep Base, gnustep-corebase, libiconv, libobjc2,
libdispatch/BlocksRuntime, libffi, and the C libraries), and the LGPL relink
offer still names the Windows engine; the WPF app never shows the Apple set.

**Localization.** Every user-facing string lives in a WPF `ResourceDictionary`
under `Windows/App/Mad.Designer.Windows/Resources/`: `Strings-en.xaml` is the
authoritative source and `Strings-de.xaml`, `Strings-es.xaml`,
`Strings-ja.xaml`, `Strings-pt-BR.xaml` and `Strings-zh-Hans.xaml` mirror the
Mac app's language set (`MAD_APP_LOCALIZATION.md` D1/D9). The dictionaries are
embedded in the main assembly (not compiled `Page` items and not satellite
assemblies — the hyphen in `Strings-de.xaml` keeps MSBuild from reading the
language code as a culture suffix), and `Infrastructure/Localizer.cs` loads them
with `XamlReader` and serves `Get`/`Format`. XAML consumes them through the
`{infra:Loc Key}` markup extension, which resolves at load time; code-behind and
view models call `Localizer`. The language follows the OS UI culture at launch
(`de`, `es`, `ja`, `pt-BR`, `zh-Hans`; anything else is English), and
`MAD_LANGUAGE` overrides it for inspection:

```powershell
$env:MAD_LANGUAGE = "de"
dotnet run --project .\Windows\App\Mad.Designer.Windows\Mad.Designer.Windows.csproj
```

Translations reuse the Mac's `Localizable.xcstrings` where the English source
matches, then follow the machine-assisted policy (MAD_APP_LOCALIZATION.md D14):
the About Overview ends with the notice that the translations are
machine-assisted and may contain errors, in each language. The About chrome,
connection assistant, query/designer/viewer toolbars and status lines, dialogs,
and the band names are translated; licence bodies, component notices, the LGPL
relink offer, copyright and brand names stay verbatim English (D6/§8), with a
localized sentence saying the licence texts are reproduced in their original
English. SQL keywords, data-type names, and field/table identifiers are not
translated, and error text the engine itself returns (driver failures, SQL
parser messages) stays English, as the Mac's driver messages do.

**The smoke test.** `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` is
the view-model/service-level counterpart of `MADMacSmokeTest.m`, not a pixel
test:

1. **London.** Open `CLI/Fixtures/London.portable.mad`, refresh 76 rows (5
   pages), then export HTML Page, HTML Flow, CSV, JSON Data, JSON Full Report and
   Plain Text through the Viewer's own path. Each file's byte count and SHA-256
   are asserted against the Mac/Linux pins in `Linux/README.md` (`html`
   `285541ed…`, `html-flow` `0565204a…`, `csv` `773f6215…`, `json` `569c6ee2…`,
   `json-report` `9d01d0da…`, `text` `7dcee96c…`).
2. **A new document.** Create a `.mad` from `chinook.sqlite3`, apply the Mac's
   SQL statement (`SELECT Customer.FirstName, Customer.LastName, Customer.City
   FROM Customer WHERE Customer.Country = 'United Kingdom';`), add a static
   label, a data field bound to `LastName`, and a report-scope COUNT aggregate,
   refresh, then export every available format and check the JSON row count and
   the HTML page count.

PDF and barcode are excluded as accepted gaps (barcode is not a Windows element
kind; PDF has no Windows exporter). The suite runs headlessly with the rest of
the app tests; see `Windows/README.md`.

## 6i. Phase 6f — the theme, the shell, and the usability pass

Phase 6f is presentation-only: no engine, protocol, document or workflow change.
It fixes the two functional defects the design review reported and applies one
Fluent-inspired design system and shell across the existing three-workspace
architecture. (The theme pass was not part of the merge gate; it follows it.)

**Defects fixed.** Help ▸ About terminated the process: the About window's
read-only `Overview`, `LicenseNotice` and `SelectedAcknowledgement` were bound
to `TextBox.Text`, whose default binding mode is TwoWay, and the binding threw
`InvalidOperationException` during the window's first layout. The bindings are
now OneWay, and `AboutWindowTests` shows the window to pin it. The Designer's
drag defect was Z-order: each band's opaque background was added with its
elements, so an element dragged into a later band painted underneath that band
and vanished until the drop rebuilt the canvas; its resize handles also stayed
at the old position. The dragged element now paints above every band, the
handles are hidden while dragging, selection chrome updates in place instead of
rebuilding, the ScrollViewer offset is preserved across a rebuild, and the drag
math is pinned at zoom 2 with the view scrolled.

**The design system.** `Themes/Theme.xaml` is the single resource set:
typography (Segoe UI Variable Text/Display, Fluent sizes), spacing, corner radii,
surfaces, command and navigation styles, primary/secondary buttons, segmented
toggles, form and card styles, and semantic status colours. Chrome brushes are
Fluent dynamic-resource keys, so light/dark, the user's accent and high contrast
follow the system; `App.xaml` opts into the native Fluent theme with
`ThemeMode="System"` (the experimental API's `WPF0001` is suppressed). Report
documents keep their own fixed palette: `Infrastructure/DesignPalette.cs` is the
single frozen source for paper, element tints, the selection accent, joins and
the minimap. `MAD_THEME=Light|Dark` is an inspection override like
`MAD_LANGUAGE`, and the Viewer's WebView2 desk follows it (or the Windows
AppsUseLightTheme setting).

**The shell.** The application icon is generated from the existing MAD artwork
(`Assets/AppIcon.png` and the multi-size `AppIcon.ico`) and is the window,
taskbar and About identity. Launching with no report shows a Welcome/Home screen
(New report, Open report, recent reports, a short introduction) rather than an
empty Viewer. The three workspaces are a NavigationView-style left rail with
icon + label, a clear selected state, and Ctrl+1/Ctrl+2/Ctrl+3; they are disabled
while Welcome is shown. A newly created report opens in the Designer; an existing
report opens in the Viewer. There is no Home destination: the three workspaces
stay the first-class peer set. The File menu keeps New/Open/Save/Save As/Recent/
Connection/Exit; the command bar keeps New and Open (About stays in Help).

**Workspace organisation.** The connection assistant is a fixed 640 × 660
window (resizable, with a scrolling body) whose grouped cards keep the driver-
specific form inside the same frame; switching SQLite → MySQL/SQL Server/
PostgreSQL does not resize it. Query has a segmented Designer/SQL switch, grouped
commands, a normal-sized Add table command in the table panel's header, and a
bottom zoom bar with in/out, percentage and Fit. The Designer groups insert and
edit commands, moves the minimap from the upper-left corner to a collapsed
Expander at the top of the inspector, and puts zoom/grid/snap/rulers on the
bottom view bar. The Viewer puts document/page/output commands at the top and
zoom, page navigation and the status/paper line at the bottom, giving the report
the maximum area.

**About.** The window now reports two distinct identities: the engine
(`v9.0 (r4433)`) and the Windows application (`v0.7`). The settled decision is
that the Windows application is pre-1.0 while the engine is mature.

**Accessibility and localization.** The navigation and command surfaces have
tooltips, text labels where an icon is ambiguous, UI Automation names (including
the icon-only zoom and page buttons), keyboard shortcuts, and Fluent focus and
disabled states. Every new or renamed string is in all six dictionaries
(`LocalizerTests` checks completeness and placeholders; English remains the
authoritative source); licence bodies, notices, copyright and brand names stay
verbatim English. The suite is 110 tests, including the Welcome/navigation/
first-workspace tests, the About window show test, the theme dictionary test and
the query zoom/fit tests.

**Ribbon evaluation.** No ribbon was introduced. The Designer's command surface
is two groups (insert palette, edit) plus a view bar; a ribbon would add chrome
and take canvas space for no discoverability gain at this command count. A
Designer-only ribbon is worth revisiting only if the element/command set grows
substantially (for example, full typography, alignment and table-layout groups).
The three workspaces have materially different commands, so an application-wide
ribbon would be more complex, not simpler.

**Not done (recorded, not defects).** No fourth Home destination; no in-app
close-to-Welcome. The Viewer's WebView2 desk colour is read when the browser is
created, so a mid-session theme switch needs a relaunch. The reference WPF
application named in the brief was not present on the workstation; the direction
follows Microsoft's Windows 11 design guidance, the native Fluent theme and the
existing MAD artwork, with the palette and spacing centralised for easy
retuning. Public `docs/windows.md` and its translations remain deferred.

## 6j. The barcode closure (2026-11-20)

The barcode element is no longer a gap on either side of the boundary.

**Engine.** `MADBarcodes` compiles here (every symbology subclass; `MADBarcodeView` and
`MADBarcodeCache` stay Apple-only), linking libpng 1.6.59 and zint 2.16.0 from
`libraries.conf`. `MADBarcode`'s encode pass is shared, and `-renderedPNGData` writes zint's
RGB bitmap through libpng with no Core Graphics, so the headless engine produces the same
symbol. `MADPrintPageElementBarcode`, `RptqDocumentElementBarcode+Extras` and
`MADDocumentObjectDataReferenceBarcode` are in the headless build; the page walk puts the PNG
on `MADReportLineRepresentation.imageData`, the HTML facsimile embeds it as a data URI (the
input is the `alt` text), and the JSON report names it with `"image": true`. A barcode with
`useStaticInput1`/`inputStatic1` renders that string; a bound one reads its query field.

**serve.** `add-element` accepts `"kind": "barcode"` (Code 128, human-readable, static
`MAD-2026`, 160×48, the Mac's defaults); `layout-model` carries a nested `"barcode"` object
(symbology id and name, options, input binding, and a base64 PNG `preview` from the same
render core); `set-element-content` edits the symbology, human-readable flag, border style and
the static-or-field binding; `duplicate-elements` copies the barcode columns;
`barcode-types` returns MADBarcode's name table as `{id, name}` sorted by name.

**WPF.** The palette's Barcode button inserts one; the canvas draws the engine's preview
(text fallback when zint refuses); the inspector shows the symbology picker, Show text, the
border picker and the input picker (static, which the Text box edits, or a query field).
`DesignerAcceptanceTests.Barcode_InsertEditBindAndUnbind` and the created-document smoke test
pin it (the HTML/JSON exports carry the symbol and its text), and the London byte pins are
unchanged because a barcode-free document's bytes did not move.

**Licence.** zint (BSD-3-Clause) and libpng (PNG Reference Library v2) are in §10, the About
window's component list and `ThirdParty/Licenses/` (both texts already existed).

## 6k. The image closure (2026-11-20)

The image element stops being a placeholder. No library was added: the store's image column
already holds PNG bytes.

**Engine.** Off Apple `MADReferenceImage` and `MADElementImage` are `NSData` — the store's
wire format itself — so the model is headless-ready and `RptqDocumentElementImage (Extras)`
gained the portable `-pngData` / `-setPngData:`, which store the bytes verbatim everywhere
(Apple's `-image` accessors still code/decode the picture where UIKit/AppKit exists).
`MADPrintPageElementImage -renderedImageData` answers the stored PNG, so
`MADReportLineRepresentation.imageData` — the barcode closure's seam — carries a picture too:
the HTML facsimile embeds it as a `data:image/png;base64,…` URI and the JSON report names it
`"image": true` with no text. On Apple the PDF path still draws the element and
`-renderedImageData` answers nil, which is the pre-existing Mac export behaviour.

**serve.** `add-element` accepts `"kind": "image"` with an optional base64 `"data"` (decoded
before the element is inserted, so a malformed request leaves nothing behind); `layout-model`
carries a nested `"image"` object `{data}`; `set-element-content` accepts `"data"` (base64 PNG;
empty clears it); `duplicate-elements` copies the picture.

**WPF.** The palette's Image button inserts an element; the inspector shows a localized
"Choose Image…" button for a selected image (the Mac inspector's row). The picker decodes any
PNG/JPEG through WIC and re-encodes it as PNG (`ImageFileEncoder`) before sending it — the
column is always PNG, so the HTML data URI is honest. The canvas draws the stored picture and
falls back to the `[Image]` placeholder when the element has none. `ImageElementTests` pins
the protocol, the picker's re-encode and the canvas; the created-document smoke test adds one
to the exported document.

## 6l. The PDF closure (2026-11-20)

`mad export --format pdf` and `mad serve`'s `export` now write a PDF on Windows, and the
Windows half is the third headless library stack the build carries.

**Libraries.** `Windows/Engine/libraries.conf` pins the Linux pins exactly: pixman
0.46.4 and cairo 1.18.6 (git tags, commits pinned) and FreeType 2.15.0 (tarball), plus
the Liberation 2.1.5 font tarball. `build.ps1` builds FreeType with its own CMake
(clang-cl, static, core only), then pixman and cairo with Meson under the MSVC
environment (`cl`), statically and with the PDF surface only. The Meson builds find
their local dependencies through generated `.pc` files and the same Windows-native
pkg-config shim the libpq build introduced (`Ensure-PkgConfigShim`, now a function so
both builds share it). Three archives join the link: `cairo.lib`, `freetype.lib`,
`pixman-1.lib`; `msimg32` joins the system list for cairo's win32 surface.

**Fonts.** The Liberation faces are copied to `Engine/build/fonts`;
`MADReportExporterPDFCairo` searches `<exe>/fonts` first (so `mad.exe` finds
`build/fonts` and a test in `build/tests` finds `build/fonts` through `<exe>/../fonts`),
then the installed layouts and `MAD_FONTS_DIR`.

**Writer.** `MADReportExporterPDFCairo` in `MAD/Source` is the non-Apple body of
`MADReportExporterPDF`; the Apple body is untouched and does not link Cairo. The
structural target, the font mapping and the determinism are
`docs/project/MAD_PDF_LINUX.md`'s. `MADPDFExportTests` is the acceptance test on both
engines; it reads the PDF back and compares page count, MediaBox, every frame and every
line's text with the `json-report` oracle, checks the barcode and picture as image
XObjects, and checks deterministic byte equality.

**Licences.** cairo (MPL-1.1), pixman (MIT), FreeType (FTL) and the Liberation fonts
(SIL OFL 1.1) are registered in `THIRD_PARTY_LICENSES.md` §3.5 and §10, their texts are
in `ThirdParty/Licenses/`, and `WindowsLicenseRegistry` lists all four for the About
window. None adds a relink obligation.

**Not done.** The WPF Viewer's format picker does not list PDF (the engine and `serve`
do); adding it is a UI change with its own strings.

## 7. Supported Windows versions

.NET 10's supported OS matrix (Windows 10 Enterprise 21H2/1809/1607, Windows
11) and GNUstep's Windows 10 1903+ baseline; tested on Windows 11 Enterprise
26H2 (build 26300). Windows 7/8 are not supported by .NET 10.

## 8. Third-party licensing and the Windows About page

The Windows engine is a third distribution surface, registered in
`docs/project/THIRD_PARTY_LICENSES.md` §10. It adds the GNUstep runtime to the
compliance surface:

* **GNUstep Base, gnustep-corebase and the libiconv library** are
  LGPL-2.1-or-later. The Windows distribution must carry the LGPL-2.1 text, the
  notice, and the written relink offer in `ThirdParty/Licenses/README.md`.
* **libobjc2 (including libBlocksRuntime) and libffi** are MIT; retain the
  notices.
* **libdispatch** is Apache-2.0 with the Swift runtime exception; ship the full
  text.
* **FreeTDS and MariaDB Connector/C** are statically linked under the existing
  LGPL-3.0 election; the FreeTDS `sybdb.h` edit is marked, and the existing
  relink offer now names the Windows engine.
* **The C libraries** (SQLite, zlib, bzip2, libarchive, libpng, zint, OpenSSL,
  libpq) use the existing entries and texts in `ThirdParty/Licenses/`.
* **Microsoft Edge WebView2** (the WPF Viewer's preview control, NuGet
  `Microsoft.Web.WebView2` 1.0.4314.35) is a Microsoft product, not open-source
  software: the Evergreen WebView2 Runtime is installed with Windows 11 and Edge
  and is neither modified nor redistributed by this project. It is registered
  with the SDK's BSD-3-Clause licence and Microsoft's third-party notices, the
  runtime's Microsoft Software License Terms, and this project's attribution —
  all in `ThirdParty/Licenses/Windows/WebView2-LICENSE.txt`.
* **gnustep-make** is GPL-3.0-or-later build tooling and is not distributed; its
  `Testing.h` is compiled only into test binaries, which are not shipped. The
  libiconv `iconv` tools and the gnustep-corebase test programs are likewise not
  distributed. The GNUstep Base command-line tools (`gdomap`, `gdnc`,
  `defaults`, `plutil`, `gspath`) are GPL-3.0-or-later and are not part of
  `mad.exe`; do not package them without the GPL text and a corresponding-source
  offer.

The exact DLL/static split is measured from the built `mad.exe` with
`dumpbin /dependents` (or `llvm-objdump -p`) and recorded in the Phase 3b
report; it is not inferred from the toolchain layout. The build and any package
must copy `ThirdParty/Licenses/` and `NOTICE`.

The WPF **About** window (Phase 5 shell proof, completed in Phase 6e; the
engine/application version split arrived in Phase 6f) mirrors
the Mac's three tabs — Overview, License & Notice, and Acknowledgements — and
lists every component above, including WebView2, with the texts from
`ThirdParty/Licenses/Windows/` and the shared root texts and the LGPL written
offer. The Acknowledgements list is the Windows component list, not the Apple
app's; the License & Notice tab carries the MIT/brand notice and the Windows
relink offer; the Overview carries the machine-assisted translation notice. Its
chrome is localized, while every licence body, component notice, licence name
and copyright line stays verbatim English (D6/§8 of
`MAD_APP_LOCALIZATION.md`). The existing iOS and macOS About screens stay
Apple-only: they list the C libraries the Apple app links and must not claim the
Apple app links the GNUstep runtime. The public `docs/windows.md` and the
`README.md` Windows entry landed with the 0.7 unsigned release (2026-11-21);
the page is English-only for now, the one recorded exception to the
five-language documentation contract (`docs/project/LOCALIZATION.md`), and its
five translations are queued. The Windows verification workflow
(`.github/workflows/windows.yml`) tests the .NET suites against the
`mad-windows-x64.zip` engine asset attached to `v0.7.0`;
`Windows/package.ps1` assembles both that asset and the app's release zip.

## Test databases

The three live driver suites (Phase 3b) are exercised against the same pinned
Docker test servers the Apple/Linux builds use, run as **local Windows
containers bound to `127.0.0.1`** (the Mac keeps all-interface publishing so the
Linux image and CLI fixtures reach its containers by name). The cross-platform
entry points are `TestDatabase/test-databases.sh` (Git Bash) and
`TestDatabase/test-databases.ps1` (PowerShell), which delegate to the three
per-framework scripts; `TestDatabase/README.md` is the reference.

```powershell
.\TestDatabase\test-databases.ps1 -Action download   # fetch datasets, no Docker
.\TestDatabase\test-databases.ps1 -Action up         # create/start all three
.\TestDatabase\test-databases.ps1 -Action status     # -Service mysql|tds|postgres
.\TestDatabase\test-databases.ps1 -Action verify
.\TestDatabase\test-databases.ps1 -Action env        # print the env block
```

The `env` block is the contract the Phase 3b live suites read; apply it in the
same session as `build.ps1`:

```powershell
$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"; $env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"; $env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"; $env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"; $env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"; $env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"; $env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
```

There is no `MAD_TDS_TEST_PORT` — the TDS suite hardcodes 1433. Driver build
results are documented in the Phase 3b report, not here.

## Related documents

* `docs/project/MAD_LINUX.md` and `Linux/README.md` — the Linux build this
  Windows build mirrors.
* `docs/project/MAD_MACOS.md` and `Mac/README.md` — the native macOS application
  whose behaviour the WPF app will mirror.
* `docs/project/THIRD_PARTY_LICENSES.md` §10 — the Windows engine's licensing
  register; `ThirdParty/Licenses/` and `ThirdParty/Licenses/Windows/` — the
  texts and the written relink offer.
