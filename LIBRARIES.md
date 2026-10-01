# Static Libraries: Inventory, Gaps, and the Build Plan

This document answers four questions:

1. What builds the `.a` files the application links?
2. What is actually on disk today, for which platform and which architecture?
3. What is missing, stale, or dead?
4. What should the build look like instead?

It is a **plan**. Nothing described here has been deleted, and nothing will be deleted
until the replacement builds every combination in §7. That constraint is the user's,
stated explicitly, and it is the right one: a build system that cannot reproduce a
library is worse than a messy one that can.

---

## 1. What builds the libraries

There are **two generations of tooling**, and both are live.

### Generation 1 -- one script per library

`Compressor/build_*.sh`:

| Script | Produces |
|---|---|
| `build_sqlite3.sh` | the SQLite amalgamation (`sqlite3.c`, `sqlite3.h`) |
| `build_bzip2.sh` | `libbz2.a` |
| `build_archive.sh` | `libarchive.a` |
| `build_openssl.sh`, `build_openssl_thridparty.sh` | `libssl.a`, `libcrypto.a` |
| `build_png.sh` | `libpng.a` |
| `build_zlib.sh` | `libz.a` |
| `build_tds.sh` | `libsybdb.a`, `libct.a` |
| `build_mysqlclient.sh`, `build_mysqlclient_old.sh` | `libmysqlclient.a` and friends |

### Generation 2 -- one flag-driven driver

`Compressor/compressor.sh` (1292 lines) handles:

```
--libbzip  --libarchive  --unixodbc  --openssl  --libpng
--mysqlold --mysql       --freetds   --zint
```

Its own `--help` advertises `--gettext` and `--acl`, which the `case` statement has no
arms for. It cannot build sqlite3 or zlib at all.

**The two generations overlap.** `compressor.sh` builds bzip2, libarchive, openssl,
libpng, freetds and mysqlclient inline rather than invoking the `build_*.sh` scripts,
so they are not layers -- they are two independent implementations of the same jobs.
Which one produced any given `.a` on disk is not recorded anywhere. That is the first
thing the plan fixes (§8).

### sqlite3 is not a library

`Compressor/library/sqlite3/` contains exactly two files:

```
sqlite3.c   9233181 bytes
sqlite3.h    658960 bytes
```

There is **no `libsqlite3.a`**. The amalgamation is compiled straight into the
`MADSqlite3` framework target as a source file:

```
MADSqlite3.xcodeproj/project.pbxproj:162
  name = sqlite3.c; path = ../Compressor/library/sqlite3/sqlite3.c;

MADSqlite3.xcodeproj/project.pbxproj:494
  sqlite3.c in Sources
```

So for sqlite3 the build script's only job is to *generate the source*; every decision
about how it is compiled belongs to the Xcode target. §4 shows that this is where the
format defect lives.

---

## 2. What is on disk

Every `.a`, with the architectures `lipo` reports. Verified, not estimated.

| Library | Platform | Path | Architectures |
|---|---|---|---|
| bzip2 | iOS | `bzip2/iOS/lib` | arm64, arm64e |
| | iOS (arm64e only) | `bzip2/iOS-arm64e/lib` | arm64e |
| | iOS sim | `bzip2/iOS-simulator/lib` | x86_64, arm64 |
| | **macOS** | `bzip2/macOS/lib` | x86_64, arm64 |
| | tvOS / watchOS | `bzip2/tvOS*/lib`, `bzip2/watchOS*/lib` | not targeted |
| libarchive | iOS | `libarchive/iOS/lib` | arm64, arm64e |
| | iOS sim | `libarchive/iOS-simulator/lib` | x86_64, arm64 |
| | **macOS** | `libarchive/macOS/lib` | x86_64, arm64 |
| | (fat, older) | `libarchive/libarchive.a` | armv7, x86_64, arm64 |
| openssl | iOS | `openssl/iOS/lib` | arm64, arm64e |
| | iOS sim | `openssl/iOS-simulator/lib` | x86_64, arm64 |
| | **macOS** | `openssl/macOS/lib` | x86_64, arm64 |
| | tvOS | `openssl/tvOS*/lib` | not targeted |
| libpng | iOS | `libpng/iphoneos/{arm64,arm64e}/lib` | arm64 / arm64e |
| | iOS sim | `libpng/iphonesimulator/{arm64,x86_64}/lib` | arm64 / x86_64 |
| | **macOS** | `libpng/macosx/{arm64,x86_64}/lib` | arm64 / x86_64 |
| | (fat paths) | `libpng/libpng.a`, `libpng_device.a`, `libpng_simulator.a` | merged |
| freetds | iOS | `freetds/iOS/lib`, `freetds/iOS-arm64/lib`, `freetds/iOS-arm64e/lib` | arm64, arm64e |
| | iOS sim | `freetds/iOS-simulator*/lib` | x86_64, arm64 |
| | **macOS** | `freetds/macOS-arm64/lib`, `freetds/macOS-x86_64/lib` | arm64 / x86_64 |
| libmysqlclient | iOS | `libmysqlclient/iphoneos/{Debug,Release}` | arm64 |
| | iOS sim | `libmysqlclient/iphonesimulator/{Debug,Release}` | arm64 |
| | (device fat) | `libmysqlclient/libmysqlclient.a` | arm64 |
| zlib | iOS | `zlib/lib/libz_ios_device.a` | armv7, armv7s, arm64 |
| | iOS sim | `zlib/lib/libz_ios_simulator.a` | x86_64, arm64 |
| gettext | -- | `gettext/lib{intl,gettextpo,asprintf}.a` | armv7, armv7s, i386 |
| libffi | -- | `libffi/libffi.a` | armv7, armv7s, i386 |

`crt_externs/` and `media/` hold no libraries.

**The headline: most libraries already have macOS slices.** bzip2, libarchive, openssl,
libpng and freetds all have both `arm64` and `x86_64` for `macosx`. The problem is not
that they were never built; it is that **nothing points at them** (§3).

---

## 3. How Xcode consumes them

Each framework project links its libraries by **file reference with a hardcoded iOS
path**:

| Project | Library reference | Path |
|---|---|---|
| `MAD` | libarchive | `../Compressor/library/libarchive/iOS/lib/libarchive.a` |
| `MAD` | libsybdb | `../opt/lib/freetds/libsybdb.a` |
| `MAD` | libct | `../opt/lib/freetds/libct.a` |
| `MADMySQL` | libmysqlclient | `../Compressor/library/libmysqlclient/libmysqlclient.a` |
| `MADMySQL` | libcrypto, libssl | `../Compressor/library/openssl/iOS/lib/*.a` |
| `MADBarcodes` | libpng | `../Compressor/library/libpng/libpng.a` |
| `MADTds` | libct, libsybdb | `../Compressor/library/freetds/iOS-arm64/lib/*.a` |
| `MAD Designer` (app) | libcrypto, libssl | `Compressor/library/openssl/iOS/lib/*.a` |

Three consequences, each verified:

**(a) No `macosx` arm exists anywhere.** A repo-wide search for
`LIBRARY_SEARCH_PATHS[sdk=macosx*]` returns nothing. Every SDK-conditional path in the
project is `iphoneos*` or `iphonesimulator*`, and `SUPPORTED_PLATFORMS` is
`"iphoneos iphonesimulator"` with `SUPPORTS_MACCATALYST = NO`. The macOS slices that
exist are unreachable by construction.

**(b) Three paths are dangling, and the link survives by accident.**
`../opt/lib/freetds/` does not exist. Yet `libsybdb.a` and `libct.a` are *in* the `MAD`
framework's Frameworks build phase. The link succeeds only because ld falls back to
`LIBRARY_SEARCH_PATHS`, which for `MAD` contains
`$(PROJECT_DIR)/../Compressor/library/freetds/iOS/lib`. The reference is a lie that
resolves to an iOS slice.

**(c) Search paths name directories that do not exist.** `MADMySQL` sets
`$(SRCROOT)/../Compressor/library/openssl/lib/iOS`; the real path is
`openssl/iOS/lib`. `MAD Designer` lists `Compressor/library/libsybdb`, which was never
created. Neither breaks the build -- the SDK-conditional arms happen to be correct --
but they are noise that hides which path is load-bearing.

### The sqlite3 compile flags (hazard H7)

This is the one item here that is not merely untidy. It changes bytes on disk.

`build_sqlite3.sh` declares 20 flags (plus `-Os`):

```
-DSQLITE_ENABLE_FTS5        -DSQLITE_ENABLE_JSON1     -DSQLITE_ENABLE_STAT4
-DSQLITE_ENABLE_COLUMN_METADATA                       -DSQLITE_THREADSAFE=1
-DSQLITE_DEFAULT_MEMSTATUS=0                          -DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1
-DSQLITE_DEFAULT_CACHE_SIZE=-4096                     -DSQLITE_DEFAULT_PAGE_SIZE=8192
-DSQLITE_TEMP_STORE=2       -DSQLITE_LIKE_DOESNT_MATCH_BLOBS
-DSQLITE_MAX_MMAP_SIZE=0    -DSQLITE_OMIT_PROGRESS_CALLBACK
-DSQLITE_OMIT_DEPRECATED    -DSQLITE_OMIT_AUTHORIZATION
-DSQLITE_OMIT_DECLTYPE      -DSQLITE_OMIT_LOAD_EXTENSION
-DSQLITE_DQS=0              -DSQLITE_MAX_EXPR_DEPTH=0   -DNOMINMAX
```

But `sqlite3.c` is compiled **by the `MADSqlite3` target**, which passes exactly one
define (`MADSqlite3.xcodeproj/project.pbxproj:571` and `:630`, Debug and Release):

```
GCC_PREPROCESSOR_DEFINITIONS_NOT_USED_IN_PRECOMPS = "SQLITE_ENABLE_COLUMN_METADATA=1";
```

Everything else falls back to whatever the amalgamation's own `#ifndef` defaults say.
The app target also sets `SQLITE_ENABLE_COLUMN_METADATA=1`
(`MAD Designer.xcodeproj/project.pbxproj:2957`), which is inert for `sqlite3.c`, because
the app target does not compile it.

**Measured against the shipped binary**, not inferred. The framework's own compile-option
table reports:

```
$ strings MADSqlite3.framework/MADSqlite3 | grep -x 'ENABLE_*\|DEFAULT_PAGE_SIZE=*'
DEFAULT_PAGE_SIZE=4096
ENABLE_COLUMN_METADATA
```

and its symbol table has **no fts5 symbols at all**:

```
$ nm -gU MADSqlite3.framework/MADSqlite3 | grep -ci fts5
0
```

So the engine that writes every `.maddb` cache is built with a **4096-byte page size**
where the script asks for 8192, and without FTS5 or STAT4. `SQLITE_DEFAULT_PAGE_SIZE`
is an ordinary compile-time `#ifndef` (`sqlite3.c:14217-14219`), so it is genuinely 4096
in the shipped product.

Why this matters beyond tidiness: **the page size is written into the database header.**
A `.maddb` produced by a correctly-flagged build and one produced by this build are not
byte-identical files, and a future macOS or CLI build that *does* pass the script's
flags would produce caches the current app reads but did not write. The format is
defined by accident. Fixing this belongs with the build system, which is why it is here
and not in `MAD_FORMAT.md` alone.

> Two adjacent facts, kept separate on purpose: the `.mad` **store** reports SQLite
> 3.43.2 (`MAD_FORMAT.md` §3) because Core Data writes it with the OS's SQLite. The
> amalgamation in `Compressor/library/sqlite3/` is **3.49.2**, and it writes the
> `.maddb` caches. They are different engines and different files.

---

## 4. Missing, stale, and dead

**Missing combinations** (the matrix in §7 has no slice for these):

| Gap | Consequence |
|---|---|
| zlib / macOS | no macOS slice exists; anything needing zlib on Mac cannot link |
| mysqlclient / macOS | no macOS slice; `MADMySQL` cannot be built for Mac |
| mysqlclient / iOS simulator (canonical path) | `libmysqlclient/libmysqlclient.a` is arm64-device-only; the simulator slices live under `iphonesimulator/` but are not the ones referenced |
| everything / macOS wiring | slices exist but no `[sdk=macosx*]` search path consumes them |

**Stale, unreferenced, or ancient:**

| Item | Evidence |
|---|---|
| `gettext/` -- `libintl.a`, `libgettextpo.a`, `libasprintf.a` | armv7 / armv7s / i386 only; no project references them; `--gettext` is advertised but unimplemented |
| `libffi/libffi.a` | armv7 / armv7s / i386; unreferenced |
| `bzip2/{tvOS,watchOS}*`, `openssl/tvOS*` | platforms the app does not target |
| `libarchive/libarchive.a` (fat, armv7) | superseded by the per-platform directories |
| `libpng/{libpng_device.a, libpng_simulator.a, libpng.a}` | three generations of merging in one directory |
| `build_mysqlclient_old.sh` | a second mysqlclient implementation, plus a third inline copy in `compressor.sh` |
| `build_openssl_thridparty.sh` | misspelled; relationship to `build_openssl.sh` undocumented |
| `compressor.sh --unixodbc`, `--zint` | no `library/unixodbc` or `library/zint` output exists |
| `MADTds/MADTds.xcodeproj` `LIBRARY_SEARCH_PATHS[sdk=…]` | set to `""` in one configuration, populated in another |

None of this is deleted. It is listed so the plan has an inventory to reconcile against.

---

## 5. What each framework actually needs

The dependency set is smaller than the library directory suggests:

| Framework | Needs |
|---|---|
| `MADSqlite3` | sqlite3 amalgamation (compiled in) |
| `MAD` | libarchive, bzip2 (transitively via libarchive), freetds (libct, libsybdb) |
| `MADMySQL` | mysqlclient, openssl |
| `MADTdsClient` | freetds (via `MADTds`) |
| `MADBarcodes` | libpng |
| app | openssl, plus all of the above via frameworks |

A headless CLI needs the first three rows and libpng only if it renders a barcode
element. That is the subset §6 of `MAD_CLI.md` refers to.

---

## 6. The target matrix

The intended state. **Platforms:** iOS device, iOS simulator, macOS.
**Architectures:** `arm64`, `x86_64`; `arm64e` only where a device slice already exists.

| Library | iphoneos | iphonesimulator | macosx | State |
|---|---|---|---|---|
| sqlite3 | compile-in | compile-in | compile-in | flags must be pinned (§4) |
| bzip2 | arm64, arm64e | arm64, x86_64 | arm64, x86_64 | built; mac unwired |
| libarchive | arm64, arm64e | arm64, x86_64 | arm64, x86_64 | built; mac unwired |
| openssl | arm64, arm64e | arm64, x86_64 | arm64, x86_64 | built; mac unwired |
| libpng | arm64, arm64e | arm64, x86_64 | arm64, x86_64 | built; mac unwired |
| freetds | arm64, arm64e | arm64, x86_64 | arm64, x86_64 | built; mac unwired |
| zlib | arm64, arm64e | arm64, x86_64 | **arm64, x86_64** | **macOS missing** |
| mysqlclient | arm64 | arm64, x86_64 | **arm64, x86_64** | **macOS + sim wiring missing** |

Five of eight rows need only *wiring*. Two need a build. One needs a flag fix.

---

## 7. The plan

### 7.1 One declarative matrix

A single file -- `Compressor/matrix.conf` -- is the only place a library's platforms,
architectures, version and flags are written down. Illustrative:

```
openssl      1.1.1w  ios:arm64,arm64e  sim:arm64,x86_64  mac:arm64,x86_64
libpng       1.6.43  ios:arm64,arm64e  sim:arm64,x86_64  mac:arm64,x86_64
zlib         1.3.1   ios:arm64,arm64e  sim:arm64,x86_64  mac:arm64,x86_64
sqlite3      3.49.2  amalgamation      defines: SQLITE_ENABLE_COLUMN_METADATA, …
```

The sqlite3 `defines:` line is the fix for §4. It is consumed in **two** places --
`build_sqlite3.sh` when generating, and the Xcode target when compiling -- so the two
can no longer disagree. Better still, the defines belong in a single `.xcconfig` that
both the `MADSqlite3` target and every future headless target include, because the
amalgamation is compiled per-target and an `.xcconfig` is the only mechanism that
reaches all of them without duplication.

### 7.2 One driver

`Compressor/build.sh <library>…|--all`, reading the matrix. It replaces neither script
in place; it is a third entry point that produces the same outputs, so the old ones can
be kept and compared until it is trusted. It should:

- build each slice into a canonical path,
  `Compressor/library/<lib>/<platform>/<arch>/lib<name>.a`
- merge per platform, and emit an **XCFramework** (`xcodebuild -create-xcframework`)
  as the single artifact Xcode links. XCFramework is Apple's own answer to exactly this
  problem: one bundle, every platform, and the linker picks the slice. It removes the
  SDK-conditional search paths from §3 entirely.
- write a `manifest.json` per library recording version, source revision, flags, and
  the SHA of every slice. This is what makes "which flags built this" answerable -- the
  question §4 could only answer by disassembling.

### 7.3 Reconcile Xcode

- Replace hardcoded `iOS/lib` references with the XCFramework, or, as an intermediate
  step, with `LIBRARY_SEARCH_PATHS[sdk=macosx*]` arms matching the existing
  `iphoneos*` ones.
- Delete the three dangling references (§3b) and the paths that name non-existent
  directories (§3c). These are removals of *references*, not of libraries -- the
  distinction matters under the standing constraint.
- Extend `SUPPORTED_PLATFORMS` with `macosx` per target, and set a macOS deployment
  target. This is Phase 2 of `MAD_CLI.md` §7.

### 7.4 Then, and only then, prune

Once the matrix builds every row of §6 **and** the app builds and its tests pass against
the new artifacts, the stale items in §4 can be removed -- one commit per item, with the
matrix diff in the message as evidence that nothing that was in use disappeared.

---

## 8. Other drivers worth adding

Anything with tables can be a `MADDatabase` subclass. Ordered by value to this project:

| Driver | Why | Cost |
|---|---|---|
| **SQLite file** | already inside the app; makes any `.db` a report source with no new library | low |
| **PostgreSQL** (libpq) | the most common open-source server; small, clean C API | low |
| **ODBC** | one driver reaches SQL Server, Oracle, DB2, Snowflake, BigQuery and more | medium |
| **Oracle** (OCI) | the remaining large enterprise database | medium |
| **CSV / TSV / JSON files** | no server at all; makes the tool useful for flat data | low |
| **DuckDB** | analytics-grade SQL over files; embeds like SQLite | low |
| **REST / JSON endpoint** | any HTTP API becomes a table source | medium |
| **Prometheus / InfluxDB** | time-series, which the grouping model handles well | medium |

**On ODBC**, since you asked about it directly. ODBC is not a database; it is a
*contract*. A vendor ships a small shared library -- a driver -- that knows how to talk
to their server. Your code calls one fixed API (`SQLConnect`, `SQLExecDirect`,
`SQLFetch`) and the driver translates. On macOS and iOS, unixODBC (the manager) plus the
vendor's driver is the whole story; the application never changes. The catch is
distribution: a driver is a separate binary per database per platform, and on iOS it
must be statically linked into the app. So ODBC buys breadth at the cost of shipping a
manager and being limited to drivers that can be statically linked. It is the right
answer for "many enterprise databases", and the wrong answer for "just one more".

---

## 9. Verification

```sh
# every slice, and what it contains
find Compressor/library -name '*.a' -exec sh -c 'printf "%-60s %s\n" "$1" "$(lipo -archs "$1")"' _ {} \;

# what the compiled sqlite actually is
nm -gU MADSqlite3.framework/MADSqlite3 | grep -ci fts5
strings MADSqlite3.framework/MADSqlite3 | grep -x 'DEFAULT_PAGE_SIZE=.*'

# what each project points at, and which of those exist
grep -rn 'LIBRARY_SEARCH_PATHS' --include='*.pbxproj' .
```

Any change to the matrix must be accompanied by these three commands' output, so the
inventory in this document is checked rather than trusted.
