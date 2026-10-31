**English** | [简体中文](README_zh.md) | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md)

# Linux — the headless engine's build

`docs/project/MAD_LINUX.md` §9: Phase B proved the toolchain (a Dockerfile that
source-builds clang + libobjc2 + GNUstep Base and compiled a MADFoundation
subset); Phase C is the §4 shim list, and this directory is where it lands.
The build now compiles **all eleven headless frameworks** — every framework in
docs/project/MAD_LINUX.md §3's table plus `MADPostgres`, except the UI-only ones (`MADExplorer`, `MADBarcodes`,
`MADFeedback`, `Scrimpter`, the app) — and runs their suites inside the
container: 126 test executables, 1,303 tests, 7 recorded needs. The test
coverage master merged on 2026-10-10 (~100 Xcode test files) is ported in
full, suite for suite. Nothing here ships in the app; the CLI — Phase D's
checkpoint — builds and runs here too (see "The CLI runs here" below), and
Phase F's runtime image runs it as a deliverable ("The runtime image" below).

## Running it

	./Linux/build.sh              build the image, run the tests, exit with the result
	./Linux/build.sh --test       run the tests in the existing image
	./Linux/build.sh --runtime    build the runtime image (mad-cli:latest)
	./Linux/build.sh --verify     build the runtime image, then verify the CLI in it
	./Linux/build.sh --probe      run only the toolchain probe, with its report
	./Linux/build.sh --info       print clang and gnustep-config from the image
	./Linux/build.sh --shell      interactive shell in the build image
	./Linux/build.sh --toolchain  build only the toolchain image (the cache base)
	./Linux/build.sh --rebuild    rebuild without cache
	./Linux/build.sh --clean      remove both images

Docker Desktop's CLI is not on `PATH` by default; `build.sh` finds it at
`/Applications/Docker.app/Contents/Resources/bin` and puts it (and the
credential helper beside it) on `PATH` for the run. The first build takes
15–25 minutes (the toolchain stage) and produces a ~2.5 GB image; later runs
are cached — only the source layer rebuilds. The `--platform linux/amd64`
cross-check was last run end to end after the merged coverage landed
(2026-10-11, before Phase D): the whole image builds under emulation (the
amd64 toolchain stage and libraries came from the earlier cache; the subset,
the 55 new suites included, rebuilt), and the run matched native arm64
exactly — 114 executables, 1098 tests, 6 needs, 10 report items, the counts
of that day. It is kept as the record of that hand-run; it is superseded by
the CI build, which compiles the image natively on amd64
(ubuntu-latest) and runs `--verify` there on every push to master — the
publish workflow pushes that same platform's runtime stage. Run it under its
own tag (`MAD_LINUX_IMAGE=mad-linux:phase-b-amd64 ./Linux/build.sh
--platform linux/amd64`) so the native image is not replaced.

## Pins

`toolchain.conf` is the single place a toolchain component's version, source
and hash is written down, in the same shape as `Compressor/matrix.conf`; git
sources pin the release tag *and* the commit checked out, the GNUstep
tarballs carry sha256 values computed from `ftp.gnustep.org`.

	libobjc2      2.3      v2.3                 (github.com/gnustep/libobjc2)
	libdispatch   6.1.3    swift-6.1.3-RELEASE  (github.com/apple/swift-corelibs-libdispatch)
	gnustep-make  2.9.3    ftp.gnustep.org tarball
	gnustep-base  1.31.1   ftp.gnustep.org tarball

The library-combo is `ng-gnu-gnu` with runtime ABI `gnustep-2.2`, so everything
compiles with `-fobjc-runtime=gnustep-2.2` and ARC.

## The libraries layer

`libraries.conf` + `lib/libraries.sh` build the C libraries the frameworks
link, natively, into `/usr/local` (docs/project/MAD_LINUX.md §7). Same shape and intent as
the Compressor matrix next door; nothing here ships.

	sqlite3      3.53.3   the released amalgamation; the option list still comes
	                      from Compressor/sqlite3.xcconfig, the one place it lives
	openssl      3.5.9    static, before freetds
	freetds      1.4.27   --enable-msdblib, apps/server/pool/odbc off, and the
	                      recipe's sybdb.h BOOL edit (spelled for GNU sed)
	zlib         1.3.2
	bzip2        1.0.8    CC=clang: its Makefile hardcodes gcc
	libarchive   3.8.9    the .mad container's tar/bzip2 path
	mariadb      3.4.11   the mariadbclient static target, openssl + external
	                       zlib, auth plugins static, others off (mirrors
	                       Compressor/lib/recipes/mariadb.sh)
	postgres     17.11    the libpq static client library + libpgcommon/libpgport,
	                       with openssl, without readline/icu/gssapi/ldap/pam/xml/
	                       xslt/lz4/zstd/zlib (mirrors Compressor/lib/recipes/postgres.sh)

Two external build dependencies remain from the retired mysqlclient build
(`libncurses-dev` and `libtirpc-dev`, which mysql's cmake needed); the mariadb
build does not use them, but they stay in the image.

## What compiles, and what does not

| Framework | Linux build | Excluded, and why |
|---|---|---|
| MADFoundation | 26 of 27 | `MADKeyChain` (Security.framework; §4 — the refresh path never reads the keychain). The umbrella goes with it |
| MADDataStructures | all 17 | (the Xcode target's files; `madmap.cpp` is not in it either) |
| MADFileManager | 10 of 11 | `MADCloudFileCoordinator` (NSMetadataQuery; §4 — iCloud dies in Phase D) |
| MADCocoaExtensions | 7 of 17 | the ten UIKit drawers/presenters (colors, labels, text fields, alerts, view helpers, the error presenter, MessageUI) |
| MADAPI | 8 of 11 | the three connection view controllers (§3: not headless) |
| MADSqlite3 | all 26 | (five orphan `.m` files are not in the Xcode target either) |
| MADTds | all 1 | |
| MADTdsClient | 4 of 5 | its connection view controller |
| MADMySQL | 18 of 19 | its connection view controller |
| MADPostgres | 5 of 6 | its connection view controller |
| MAD | 150 of 181 | the UI tail (§5.2), `MADocument` + the operations that build/close one (Phase D's), the keychain operations, the MADBarcodes-backed element files. Each is named in `cmake/MADSources.cmake` |

Each framework's source list is a `cmake/<Name>Sources.cmake` beside the
build, with the exclusions named and their reasons — the same shape as
`MADFoundationSources.cmake`. `MADExplorer`, `MADBarcodes`, `MADFeedback` and
`Scrimpter` are not in the Linux build at all (docs/project/MAD_LINUX.md §3).

The Linux build supplies what GNUstep lacks without touching the framework
sources:

* an include shim per framework so the `<Framework/…>` self-imports resolve
  (MAD's is a directory of symlinks, because the Xcode target flattens its
  headers as `<MAD/Foo.h>`), plus four library-header shims
  (`<MADSqlite3/sqlite3.h>`, `<MADTds/sybdb.h>`, the MADTdsClient umbrella,
  `<MADPostgres/libpq-fe.h>`);
* a prelude header (`Compat/MADCompat.h`) carrying the platform gaps that are
  macros or typedefs (see the list below);
* whole-archive linking, Apple's `-ObjC`, without which the frameworks'
  categories are silently dropped from the static archives;
* one category compiled into `libmad.a` (`target_sources` in
  `Linux/CMakeLists.txt`): MADQuery+Sqlite3's `-whereClauseWithRowIds:` /
  `-whereClauseWithParameters:` are reached by message send, so the linker
  drops the archive member, and whole-archiving `libmadsqlite3.a` would
  duplicate the compat objects every framework archive already embeds;
* `-lgnustep-base` before `-lobjc` on the link line: libobjc2 exports a weak
  `objc_enumerationMutation()` that aborts and GNUstep Base exports the real
  one that raises, and the first library on the line wins.

The frameworks themselves gained small platform guards, all `#if __APPLE__`
so the Apple paths are textually unchanged. The macOS suites are the proof
they are behaviour-neutral: MADFoundation, MADDataStructures, MADFileManager,
MADCocoaExtensions, MADAPI, MADSqlite3, MADMySQL, MADTdsClient, MADPostgres
and MAD are all green on the simulator, and the `MAD Designer` workspace builds.

## The drivers are registered, not imported

The constructor used to import the drivers, which is the `MAD` ↔ drivers cycle
(`docs/project/ROADMAP.md` §5.1). `MADDatabaseDriverRegistry` (`MADAPI`) is the seam now: each
driver's connection class conforms to `MADDatabaseDriver` and registers itself in
`+load`, and `MADDatabase+Constructor` / `MADDatabaseConnection+Constructor` look a
driver up by `MADDatabaseType` instead of naming one. Which drivers a process has
is therefore a matter of what it *links*.

On Apple the host links the driver frameworks — the app and the CLI name MADMySQL,
MADTdsClient and MADPostgres, and `MAD.framework` no longer does, so its test bundle names them
too. On Linux the driver archives are **whole-archived** from the `mad` target
(`$<LINK_LIBRARY:WHOLE_ARCHIVE,…>`, which propagates to every consumer): a static
archive is searched, not loaded, so a member nothing references — a driver's
`+load`, or a category — is dropped otherwise. That is not a nicety; it is what
made `mad refresh` over MySQL abort before it was fixed (§ the category below).
`MADDatabaseDriverDispatchTests` pins the registry, and
`Linux/Tests/MADHeadlessDocumentTests.m` drives the whole chain.

Adding a driver means a link entry in `Linux/CMakeLists.txt` and nothing in `MAD`.

## The compat shims are an archive of their own — and why

Every framework archive used to embed `Compat/*.m`. That made whole-archiving two
of them a duplicate-symbol error, which is why exactly one category
(`MADQuery+Sqlite3`) had been compiled into `libmad.a` by hand. The CLI found the
cost of that arrangement: `mad refresh` against live MySQL **aborted** (SIGABRT,
no diagnostic) because `MADMySQLFetch (DataTable)` — the method that runs the
prepared statement — was a category reached by message send, so the linker had
never pulled its object file in. `nm` showed `.objc_category_MADMySQLFetchDataTable`
present in the MySQL test binary and absent from the CLI's.

`madcompat` is now its own static library, whole-archived by every executable
(`mad_add_test`, `ToolchainProbe`, `mad-cli`), and the framework archives are
pure, so the driver archives can be whole-archived like any other code. The
per-file `target_sources` hack is gone. The general rule this leaves: **a
framework archive is only safe to link if it is whole-archived**; anything less
and its categories are silently absent at runtime.

## GNUstep divergences the probe and tests found

* **NSOperationQueue and KVO — found here, fixed in MADOperation.** GNUstep's
  `NSOperationQueue` removes its `"isReady"` observation on every notification
  it receives, and it checks `isReady` once more after registering that
  observation. MADOperation used to advance its state machine from inside
  `-isReady` itself (through the KVO dependent keys of `state`), so the first
  readiness check fired the notification the queue was waiting for, and the
  second call then removed an observation that was already gone —
  `NSInvalidArgumentException`, and the operation never ran. MADOperation now
  drives the advance explicitly (`-willEnqueue` starts condition evaluation)
  and sends `will`/`didChangeValueForKey:` for `isReady`, `isExecuting` and
  `isFinished` only when each value actually changes, so the queue sees one
  `isReady` notification per enqueue, the way Apple's does. The Linux tests
  assert this plainly on both platforms; nothing is silenced, and the Phase D
  refresh path is no longer blocked by it.
* **Secure-coding archiving is absent.** `archivedDataWithRootObject:
  requiringSecureCoding:YES` returns nil with no error, so the code paths
  that must work off Apple — MADArrayCaching's `.madac` render cache,
  MADDataTableFast's group-key set, MADFileUtilities' archives — fall back to
  `requiringSecureCoding:NO` behind `#if __APPLE__`, which is the same coder
  without the hardening. The unarchiving side needs no fallback:
  `unarchivedObjectOfClass:fromData:error:` and its plural do work on GNUstep
  (measured 2026-10-06 — the probe's earlier report that neither it nor
  `+unarchiveTopLevelObjectWithData:error:` exists came from a branch the nil
  strict-archive never reached, so only the latter was ever true). That one
  does not exist and is shimmed in `Compat/` over `+unarchiveObjectWithData:`.
* **`-localizedCaseInsensitiveCompare:` is case-sensitive on GNUstep** — no
  longer load-bearing (fixed 2026-10-25). The SQLite collation
  MADDatabaseSqlite3 registers (`compare_string_utf8_localized_asc_collation`),
  the in-memory sort selectors and the report formatter's string comparator all
  route through one first-party defined order (`NSString+Comparison.h`:
  case-fold, then UTF-8 code-point order), so the divergence the localized
  comparison caused is gone, not papered over; the tests assert the defined
  order identically on both platforms. See `docs/project/MAD_CLI.md`'s `mad export` section.
* **BOOL's runtime encoding, and `class_getProperty` inheritance — found by
  MAD's rptq suites, fixed in RptqObject.** The runtime compares an installed
  accessor's type encoding against the compiled call site's, and BOOL is
  `unsigned char` (`'C'`) on GNUstep where Apple uses `signed char` (`'c'`),
  so `RptqObject`'s dynamically-installed bool accessors now register a
  per-platform encoding (`MAD_RPTQ_BOOL_TYPE`). And GNUstep's
  `class_getProperty()` looks at the class itself only, where Apple's walks
  the superclass chain — so an inherited property (a label's `alignment`) fell
  through to the generic object arm; `RptqPropertyNamed` does the walk on both
  platforms. The failure mode was a silently wrong value, not a crash, so both
  are pinned by the ported suites.
* **GNUstep's file APIs refuse scheme-less URLs — found by MADFileManager's
  ported tests, fixed in MADURLFactory.** `-contentsOfDirectoryAtURL:` and
  `-writeToURL:` quietly do nothing for a URL that carries no `file://`
  scheme (measured 2026-10-11), and `+newURLForLocalDocumentsDirectory`
  built its URL with `-initWithString:` from a path — which Apple tolerates.
  It now uses `+fileURLWithPath:`, the honest answer on both platforms; that
  plus the coordinator shim below turned five parked needs into five
  passing tests (`MADLocalFileCoordinatorTests`, 12 tests, 0 needs).
* **dispatch objects are plain C pointers** (`os/object.h` declines ObjC
  support outside Darwin, and refuses `OS_OBJECT_USE_OBJC=1` outright — the
  libdispatch build comments say so), so ARC cannot own one: every
  `strong`/`copy` dispatch property is `assign` off Apple, commented in
  place. Queues are created once and live for the process; nothing releases
  them.
* **Smaller gaps, shimmed or guarded:** `NSOperation.name`,
  `NSOperation.cancelled` and `NSOperation.asynchronous` (GNUstep keeps only
  the old `-isConcurrent` spelling, as a stub that always answers NO — its
  own bookkeeping consults it, and without the Compat category answering
  `[self isAsynchronous]` a finishing async operation raised out of
  `-dealloc`), the NSFileManager ubiquity methods (no iCloud off
  Apple; every answer is the empty one), `-initWithFilePresenter:` on
  NSFileCoordinator, `-coordinateAccessWithIntents:queue:byAccessor:`
  (GNUstep's implementation faults when it runs the accessor — SIGSEGV,
  measured; the Compat category calls the accessor on the given queue, there
  being nothing to coordinate with off Apple), NSURL's security-scoped access and
  `-fileSystemRepresentation`, NSData's `-options:error:` readers and their
  constants, `-decodeTopLevelObjectOfClasses:forKey:error:` on NSCoder,
  `-registerUndoWithTarget:handler:` on NSUndoManager,
  `+propertyListWithStream:options:format:error:` (a stub returning nil, the
  stream never read — the Compat category reads the stream and defers to
  `+propertyListWithData:`; with it, MADDataTable's `-loadFromCacheWithUrl:`
  runs on Linux and is asserted on both platforms), NSValue's `CG*Value`
  spellings, the `CF_ENUM`/`CFAvailability` macros, the CFNumber extraction
  calls (a compat `CoreFoundation/CFNumber.h`), `copyfile(3)` in POSIX,
  `htonll`, the MacTypes scalars (`Float64`, `SInt32`…`UInt64`, `Boolean`),
  `NS_RETURNS_INNER_POINTER`, the `__nullable` spelling,
  `NSOperation.qualityOfService`, `NSDataWritingFileProtection*`,
  `containerURLForSecurityApplicationGroupIdentifier:` (absent — the reason
  MADURLFactory's group path falls back to the per-user directories),
  `QOS_CLASS_DEFAULT` from `<sys/qos.h>` (absent).
* **Verified good:** ARC and weak zeroing, blocks, exceptions,
  `@synchronized`, KVO (manual and dependent keys), `NSOperation`
  state-machine KVO, `NSPredicate predicateWithFormat:@"error != nil"` (MAD's
  exact predicate), dispatch (once/queues/groups/semaphores), the main queue
  draining under a plain executable, JSON, UUID, dates, plists, sort
  descriptors, streams, NSDecimalNumber, NSCalendar and keyed archiving on
  the permissive path. The full report is what `--probe` prints; its 19 core
  checks gate the exit code, its 12 report items do not (the CLI's run added
  `directory-enumeration` and `directory-enumeration-url-form`).

**Currency formatting (found 2026-10-16, fixed 2026-10-17).**  Two GNUstep behaviours
made the rendered money differ from Apple's: `NSNumberFormatterCurrencyStyle` renders
no fraction digits for any locale (`en_US` gave `$1`, Apple `$0.99`), and the image's
current locale is `en_US_POSIX`, whose currency has a space after the symbol and no
grouping.  Both are answered without replacing the formatter: the report takes its
locale and its fraction digits from the document's numeric format (the fallback is
`en_US`, not the machine's locale), and the currency symbol is written explicitly with
the yen sign normalized (GNUstep spells it fullwidth U+FFE5).  A 60-case comparison --
six locales times ten values, negatives and 1e12 included -- is now byte-identical
between the two platforms; the only difference it found was that yen codepoint.
`docs/project/BUGS.md` has the entry (archived: it is fixed), and the render-side exports below are
pinned to the Mac's bytes.

## The need count, and why it is 6

The Phase B image reported 3 needs; the finished Phase C image reports 6, and
the three new ones each come from MAD's suites landing on Apple-only
machinery. They are needs, not skips, deliberately: the check cannot run
without a resource Linux does not have, and the need says so out loud where a
skip would hide it.

* **The three that were already there.** The toolchain probe's strict-archiving
  check (`requiringSecureCoding:YES` returns nil, above) and its app-group
  check (`containerURLForSecurityApplicationGroupIdentifier:` is absent), plus
  MADCredentialTests' conditional one on the same strict-archiving gap.
* **MADStoreTests** — the model-fidelity check needs Core Data and the
  compiled `MAD.momd`, both Apple-only.
* **RptqStoreContextTests, twice** — the converted-sample fixture needs
  `MADStoreConverter`, Core Data and `London.mad`, and the document path needs
  `MADocument` and `MADStoreConverter` (Phase D's to settle).

The live-database suites skip (never fail) when no server is reachable — the
same contract the Xcode schemes have — and the SQLite benchmarks skip at their
default scale; skips are counted separately and are not needs.

## The live database suites run here

`MADMySQLLiveTests`, `MADTdsClientLiveTests` and `MADPostgresLiveTests` talk to
real servers and skip (never fail) when none is reachable — the same contract the
Xcode schemes have. The servers are the three containers `docs/project/DEVELOPER.md`
documents; start them first:

	MADMySQL/TestDatabase/mysql-test-db.sh up          # mad-mysql on :13306
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up  # mad-mssql on :1433
	MADPostgres/TestDatabase/postgres-test-db.sh up    # mad-postgres on :5432

	docker run --rm \
		-e MAD_MYSQL_TEST_HOST=host.docker.internal \
		-e MAD_MYSQL_TEST_PORT=13306 \
		-e MAD_TDS_TEST_HOST=host.docker.internal \
		-e MAD_PG_TEST_HOST=host.docker.internal \
		--entrypoint bash mad-linux:phase-b -c \
		'/src/Linux/build/MADMySQLLiveTests && /src/Linux/build/MADTdsClientLiveTests && /src/Linux/build/MADPostgresLiveTests'

Measured 2026-10-17 with that clean setup: MySQL 44/44, 311 checks (prepared
statements, the type conversions, schema discovery), and SQL Server 29/29, 169
checks (the freetds wire path, the date/time cracking, decimal/blob/nvarchar,
schema discovery); PostgreSQL 14/14, 132 checks (measured 2026-10-27: libpq
fetch, OID type conversions, schema discovery across public and non-public
schemas) — so all three drivers work on Linux, not just compile.
`MADTdsClientTests`' two connection-failure tests run without a server.

## Licences

Everything in the image is build tooling; nothing is linked into the app.
libobjc2 is MIT; libdispatch is Apache-2.0 with the Swift runtime exception;
GNUstep Base is LGPL-2.1-or-later; gnustep-make is GPL-3.0-or-later, and its
`Testing.h` (GPL-3.0-or-later) is compiled into the Linux test binaries — those
exist only inside this build image. The C libraries carry their own licences
(docs/project/THIRD_PARTY_LICENSES.md); the mysqlclient GPL problem is settled — D1 went
to MariaDB Connector/C (LGPL-2.0-or-later, elected LGPL-3.0) and this image
builds it (`docs/project/TASKS.md` §10). The runtime image is published as
`ghcr.io/mthomason/mad`, so the LGPL components it distributes need relink
offers: the written offer in `ThirdParty/Licenses/README.md` now names the
image, and the register entry is `THIRD_PARTY_LICENSES.md` §9. gnustep-make
is build tooling and is not in the runtime image.

## The CLI runs here — Phase D

`mad` is built by this CMakeLists from `CLI/Source` (the same sources
`CLI/build.sh` builds for the iOS Simulator), links the eleven frameworks
whole-archive, and runs in the image:

	/build/mad inspect <document.mad>
	/build/mad schema  <document.mad>
	/build/mad query   <document.mad>
	/build/mad refresh --credentials user:pass <document.mad>

`export` is the one verb that is not here: PDF is a Core Graphics context drawn by
a `UIPrintPageRenderer`, so it stays on Apple and says so (`docs/project/MAD_LINUX.md` §5.2;
the renderer decision is Phase E's).

**`export` grew its Foundation formats here (Phase E, 2026-10-16).** The export seam
(`MADReportExporting` + `MADReportExporterRegistry`, `docs/project/MAD_CLI.md` §5.3) is in `mad`, so
`text`, `csv` and `json` run in the image and write the same bytes as the Mac's tool
(the render-side formats — `html`, `html-flow`, `json-report` — run here too; see the
section below, and `pdf` says why it cannot).
The comparison, run for the record on the London fixture (`CLI/Fixtures/London.portable.mad`,
refreshed first, `sha256sum` on each side):

| format | bytes | sha256 (identical on both platforms) |
|---|---|---|
| `json` | 64595 | `569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc` |
| `csv` | 12538 | `773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21` |
| `text` | 40441 | `7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49` |

`Linux/Tests/MADReportExporterTests.m` is the same check as a test: it refreshes the
fixture and asserts each export's FNV-1a checksum against the Mac's bytes (plus the
shape and a few values), so a spelling that drifts between GNUstep and Apple fails
here — and the same FNV-1a checksums are pinned on the Mac side now
(`MAD/MADTests/MADReportExporterTests.m`), so the drift cannot be silent on either
platform. `json-report` is the same schema with the rendered report as an extra
member; it needs the render half (`MADReportFormatter` and the page renderer), which
compiles here since Phase E — the section below carries its digest, and only `pdf`
registers and says why it cannot run (`docs/project/MAD_CLI.md` §3); `Linux/Tests/MADReportExporterTests.m`
asserts that it fails
rather than silently writing the data half.

**How the document class was settled.** `MADocument` is a `UIDocument`, so it
cannot come along, and `MADCLIDocument` used to be built on it. The data half of
a document is now a protocol — `MADDocumentDataProtocol` — which `MADocument`
conforms to (unchanged behaviour; every member was already one of its accessors)
and `MADHeadlessDocument` implements: it opens the container and the portable
store with `MADDocumentStore` (the store layout MADocument uses too, so the two
cannot disagree about it), compiles the query, builds the driver-backed database
through the registry, and holds the row table. The refresh chain takes the
protocol, so Apple and Linux run the *same* `MADOperationRefresh` — only its one
render-side branch (the report formatter and the section layout managers) is
`#if __APPLE__`. The user chose this shape on 2026-10-16 over a `UIDocument` shim
in Compat and over splitting `MADocument` itself.

**The checkpoint, from inside the image** (Docker Desktop; the documents are in
`CLI/Fixtures/`, and their host name `mac` resolves here to the Mac):

| Run | Result |
|---|---|
| `mad inspect` on `London.mad` (the legacy sample) | v0, 6 members, store + WAL + SHM reported |
| `mad inspect` on `London.portable.mad` | v1, 4 members, `StoreContent/store.sqlite (portable)`, 41 sections / 25 elements |
| `mad schema` on the two portable fixtures | identical to the Mac's output, byte for byte |
| `mad query` on the same | the same field set as the Mac; the *order* differs (below) |
| `mad refresh` on `London.portable.mad` | 76 rows, and the row cache is identical to the Mac's (21 columns by name, 76 rows, every value equal) |
| `mad refresh --rows 50 --credentials root:root` on `MySQL.employees.mad` | 50 rows from live MySQL 8.4 (prepared-statement fetch, database `employees`) |
| `mad refresh --rows 20 --credentials sa:Root1@Root2` on `TDS.AdventureWorksLT2022.mad` | 20 rows from live SQL Server 2022 (freetds, `AdventureWorksLT2022`) |
| `mad refresh --rows 25 --credentials mad:mad_test_pw` on `Postgres.chinook.mad` | 25 rows from live PostgreSQL 17 (libpq, `chinook`) |

The live suites agree: `MADMySQLLiveTests` 44/44, `MADTdsClientLiveTests` 29/29
and `MADPostgresLiveTests` 14/14 from the same image. `Linux/Tests/MADHeadlessDocumentTests.m` is the same
checkpoint as a test — open, schema, query, driver resolution, refresh, 76 rows —
so it fails in CI rather than in a hand-run.

**Two differences worth knowing, both found here.** The SELECT list's column order
was *set* order (`MADQueryActiveQueryFields` accumulates into an `NSSet`), so the
same document produced a different order on Apple and on GNUstep — the same fields,
different order; the cache's *data* is identical once compared by field name, and the
cache's `c<hash>` column names are hash-derived, so they differed per platform too.
**Settled 2026-10-16 (the JSON export shape decision, `docs/project/MAD_LINUX.md` §10.1):** the
order is now defined as the column alias, sorted with `-compare:`, in both SQL
builders, so the generated SQL, the row cache and every export agree on both
platforms (docs/project/BUGS.md, the SELECT-list entry; the order tests in
`Linux/Tests/MADQuerySelectExpressionTests.m`). A cache refreshed before the change
orders its columns differently from one refreshed after it — the same data, a new
order — so refresh once before comparing caches across that date.

## The writer runs here, and the two platforms agree

Phase E's other half (`docs/project/MAD_LINUX.md` §9; the user's requirement, 2026-10-16): the `.mad`
writer works on Linux and produces the **same bytes** as the Mac's for the same
document.  `mad write <doc.mad> --out <copy.mad> [--reproducible]` is the surface, and
the document is opened headlessly on both platforms, so both sides run the same writer.

Measured on the London fixture (`CLI/Fixtures/London.portable.mad`):

	$ mad write London.portable.mad --out copy.mad --reproducible
	16261 bytes, sha256 09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5
	                                     (identical on the Mac and in this image)

The fixture is a version-1 store, and the write opens the document first, so the
opened copy carries the store migration (SQL entry Phase A: the `sqlSourceText`
column and `user_version` 2) on both platforms; the bytes above are the migrated
document's.

`--reproducible` pins uid/gid 0, the fixed time 2001-01-12T00:00:00Z and a sorted member
walk; an ordinary write keeps the members' real metadata, so it differs between runs
and platforms by design.

Two things had to be fixed for the writer to run here, both recorded in `docs/project/BUGS.md`
(the `.mad` byte-identity entry):

* `-write_archive:` walked each enumerated URL *up to* the archived directory, and
  GNUstep's `-enumeratorAtURL:` strips the containing directory, so the loop never
  arrived.  The members are read with `-subpathsAtPath:` now, the way the CLI's member
  list already was.
* `backup_file` handed its path to `dirname(3)`/`basename(3)`, which glibc is allowed to
  modify and does: the caller's archive path came back truncated at its last slash, so
  the composed document was written over its own directory (`Open (…) failed - Is a
  directory`).  Apple's implementations leave the buffer alone, which is why only Linux
  saw it.

`Linux/Tests/MADArchiveManagerTests.m` is the coverage (5 tests, 0 needs): the round
trip (`docs/project/MAD_CLI.md` §6.1), the ordinary mode's characterisation, the reproducible mode --
including an FNV-1a checksum of the whole document against the Mac's bytes -- and the
document path, which writes a copy and leaves the source untouched.

## The render half and the HTML formats run here

Phase E's second decision (the user's, 2026-10-16) was HTML next and PDF last, and the
HTML step is where the render half moves off Apple.  It moved as a conformance:

* `MADReportFormatter` takes `id <MADDocumentRenderProtocol>`; `MADHeadlessDocument`
  conforms, and `MADOperationRefreshInitialize`'s render branch keys on the protocol.
* `MADReportPageBuilder` is the page walk, out of `MADPrintPageRenderer` (which keeps
  `UIPrintPageRenderer` and the drawing).  It owns the render side's geometry (US
  Letter, the 1pt trim) and the preparation sequence, so the PDF, json-report and the
  HTML formats cannot disagree about a page.
* `MADDocumentRenderDataSource` is the one implementation of the render half's reads,
  shared by `MADocument` and `MADHeadlessDocument`; the `MADPrintPageElement` family
  compiles here (its initialisers are Foundation; only drawing is Apple's).

`mad export` now has `html`, `html-flow` and `json-report` here, and `pdf` registers
and says why it cannot run (its body is Core Graphics).  Measured against the Mac on
the London fixture:

| format | bytes | sha256 (identical on both platforms) |
|---|---|---|
| `json-report` | 118,109 | `9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c` |
| `html` | 62,007 | `285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327` |
| `html-flow` | 54,766 | `0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382` |
| `pdf` | — | not produced here; `+isAvailable` NO with the reason |

The render-side formats are byte-identical across the platforms, like the data ones:
every frame, font, font size, trait, alignment, text run and page box, and the money
(the finding that made them differ, and its fix, are above and in `docs/project/BUGS.md`).
`Linux/Tests/MADReportExporterTests.m` pins the three checksums.

## The runtime image — the CLI deliverable (Phase F)

Phase F's deliverable is a container that runs the CLI, not a build tree a
developer has to remember the path to. `./Linux/build.sh --runtime` builds it
from the same Dockerfile (the `runtime` stage, downstream of `build`), tagged
`mad-cli:latest`:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad

The image is published (2026-10-26) as `ghcr.io/mthomason/mad`, tagged
`latest` and the commit's short SHA. The published tags are built by CI
(`.github/workflows/publish-image.yml`) on ubuntu-latest, so they are
**linux/amd64** — the Mac's local `mad-cli:latest` build is arm64. Pulling
instead of building is the ten-second route; on Apple silicon add
`--platform linux/amd64` (Docker Desktop runs the tag under emulation —
without the flag the pull fails with `no matching manifest`):

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Distributing the image obliges relink offers for the LGPL components in it
(GNUstep Base, and mariadb and freetds static inside `mad`); the written
offer in `ThirdParty/Licenses/README.md` names the image (the §Licences
section above).

The image carries:

* `/usr/local/bin/mad`, the CMake install rule's stable path (the binary is no
  longer reachable only at `Linux/build/mad`);
* the shared objects the binary links — GNUstep Base, libobjc2, libdispatch
  and libBlocksRuntime — plus GNUstep's runtime directories and config. The
  other C libraries (sqlite3, freetds, openssl, zlib, bzip2, libarchive,
  mariadb, postgres) are static and are already inside the binary;
* none of mysqlclient's share data: Connector/C embeds its client error
  messages and installs no `share/` files;
* `chinook.sqlite3` at `/root/GNUstep/Library/ApplicationSupport/`, where a
  Sqlite3 document's bare database name resolves. A document stores the name,
  not a path, so this one file is what lets the checked-in London and Music
  fixtures refresh without extra setup.

It leaves behind the compiler, cmake, git, the sources, the 126 test binaries,
and the static archives and headers: the final stage is `ubuntu:24.04` plus
the runtime libraries from apt, not the toolchain image. It is **283 MB on
disk (66.5 MB compressed)**; the build image is 6.65 GB.

Every verb runs the same way:

	docker run --rm -v "$PWD/docs":/docs mad-cli:latest mad schema /docs/x.mad
	docker run --rm -v "$PWD/docs":/docs -v "$PWD/out":/out mad-cli:latest \
		mad export /docs/x.mad --format html --out /out/x.html
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

The live fixtures name the server `mac` (`CLI/Fixtures/README.md`); from the
container that resolves to the Mac through Docker Desktop. The refresh cache
is written under `/root/GNUstep/Library/Caches` inside the container, so it
does not survive `--rm`; `export` refreshes the document itself, so that is
not a problem. Add a volume if a cache should persist between runs. The image
runs as root; a `--user` run needs the sample database (and any document) in
that user's own Application Support directory.

**`--verify` is the repeatable check.** It rebuilds the runtime image and runs
`Linux/verify-cli.sh` in it with the repository mounted read-only: the six
verbs, every export format against its pinned digest, `pdf`'s refusal, the
`--reproducible` writer's bytes, the exit codes, and the image's own shape (no
clang, cmake, git or build tree). 41 checks; it exits non-zero on any failure.

	./Linux/build.sh --verify
	...
	MADVERIFY 41 passed, 0 failed

`--live` adds the MySQL, TDS and PostgreSQL refreshes (50, 20 and 25 rows); start
the three test containers first (`docs/project/DEVELOPER.md` has their scripts
and logins):

	MADMySQL/TestDatabase/mysql-test-db.sh up
	MADTdsClient/TestDatabase/sqlserver-test-db.sh up
	MADPostgres/TestDatabase/postgres-test-db.sh up
	docker run --rm -v "$PWD":/repo:ro mad-cli:latest \
		bash /repo/Linux/verify-cli.sh --live

**Published, with CI (2026-10-26, reversing the 2026-10-17 decision).**
`.github/workflows/publish-image.yml` pushes the runtime stage to
`ghcr.io/mthomason/mad` as `latest` and `<short-sha>` on every push to
master, plus by hand from the Actions tab (`workflow_dispatch`); the local
`./Linux/build.sh --runtime` build is unchanged. The published tags are
amd64, built by CI; the Mac's local build is arm64.

**A Dockerfile hazard, written down because it bit the first build.** The
runtime stage is the Dockerfile's last stage, so `docker build` with no
`--target` now produces the runtime image. `build.sh` passes `--target build`
for the build image and `--target toolchain` for the toolchain cache; a
hand-run build should do the same.

## What this does not do yet

The Linux PDF writer — **deferred 2026-10-17, blocked on the user's research; do not
start it without their decision.**  `docs/project/MAD_PDF_LINUX.md` is the handoff file (what
exists, what is missing, the candidate stacks with licences, the open questions, the
acceptance test); `docs/project/MAD_LINUX.md` §10.2 records the reasoning.  Until it lands, a PDF
on Linux is a browser printing `--format html`.

Phase F's other parts, as of 2026-10-17: the **runtime image** and its **repeatable
verification** are done (the section above), and the **CI row was dropped on the
user's decision** — no GitHub Actions, because the Linux port is a proof of concept
for testing, not a product release. That changed 2026-10-26 with the GHCR
publish: the image is published and `publish-image.yml` builds and pushes it
(the section above). The **Compressor Linux driver** is not done and
is not needed for the CLI: the image already builds the C libraries natively
(`libraries.conf` + `lib/libraries.sh`).  Ask before starting it.
