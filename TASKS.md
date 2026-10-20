# TASKS.md

The engineering task queue for _MAD Designer_.

> **Agents: maintain this file, do not act on it.** Add, re-status, and link tasks as
> work proceeds, but do not start work on an entry just because it is listed here.
> Pick up a task only when the user asks for that task by name or number.

## How this relates to the other tracking files

Three files track work, and they are deliberately different things:

* `BUGS.md` — the **defect register**. Every confirmed wrong behaviour, with the test that
  pins it. Evidence, not a queue.
* `TODO.md` — the user's **product wishlist**. Features and ideas, written by hand.
* `TASKS.md` — this file, the **engineering queue**. What is actively being worked, in
  order, with enough context to start cold. Entries link to `BUGS.md` rather than
  restating it.

Status key: **Open** · **In progress** · **Blocked** · **Done**.

---

## 1. Keychain and credential flow — highest priority

**Status:** Open — the user has asked to return to this.

The user's words: *"It seems like this keychain flow is very important to getting right,
or no one will ever use the software."* Saving a database password is what makes a
document usable, so a broken prompt sequence blocks the whole product.

**What goes wrong today.** On create-document, the app presents **two competing
password prompts**:

1. The app's own `MADOperationPromptPolarQuestion` alert — "Save to Keychain" Yes/No.
2. The **system** Passwords-app sheet — "Update Password?" with *Not Now* / *Update* —
   which appears **on top** of the app's alert.

The user clicked *Update* on the system sheet, then *Yes* on the app's alert, and only
then did the document get created. Saving and deleting a password is otherwise broken.

**Where to look.**
* `MADFoundation/Source/MADKeyChain.m` — the `SecItem*` wrapper. Note it was recently
  fixed: `-deleteSavedPasswordForKey:error:` was swallowing failures and dereferencing a
  `NULL` error out-parameter. Deletion failures now surface, which may be part of the
  user-visible wonkiness.
* `MADDesigner/Source/` — `MADOperationKeyChainPut`, `MADOperationKeyChainGet`,
  `MADOperationKeyChainDeletePassword`, `MADOperationGetCredentials`, and the
  `MADOperationConditionPolarQuestionAffirmative` condition that gates them.

**Design question to settle with the user.** The duplicate prompt is almost certainly
because the app writes its own keychain item *and* iOS offers its own credential storage
for the same host. Decide which system owns the password:

* use the platform's AutoFill/`kSecClassInternetPassword` path and delete the app's own
  prompt, or
* keep the app's private keychain item and suppress the system sheet.

Do not guess which — this is a product decision.

**Evidence:** `MADDesigner/run.log`, the `MADOperationKeyChainPut` / `KeyChainGet` /
`KeyChainDeletePassword` / `GetCredentials` sequences around lines 380–570.

**Also worth checking while here:** the log line

```
MADOperationCreateDocument Keychain keys generated.
  MainKey (connStr):"(TDS)[localhost:localhost:1433]AdventureWorksLT2022"
```

names the host **twice** in one key. Confirm whether the connection-string formatter is
emitting a duplicated host, because every keychain key is derived from that string — a
wrong key means a saved password that can never be found again. Related: the accessor is
spelled `-[MADDatabase credentalsWithConnection:]`.

**Done when:** one prompt, save works, delete works, and the key round-trips identically
between save and lookup. See task 4 for the tests that must cover it.

---

## 2. A SQL Server connection that reports success and failure at the same time

**Status:** Fixed for the reporting half; the live connection itself is still unverified.

**What was wrong.** The SQL Server driver swallowed every failure past the connection
point. `MADDatabaseSQLServer -connectWithConnection:credentals:connectionError:` and
`-connect:andPassword:error:` built an `NSError` and never wrote it to the caller's
out-parameter, and `-executeQuery:withDataTable:andError:` ignored both. So
`MADOperationDatabaseTestConnection` saw `success = NO` with `error = nil`, logged

```
MADOperation <MADOperationDatabaseTestConnection> finish with 0 direct errors.
MADOperation <MADOperationDatabaseTestConnection> finishing with no errors.
...
MADOperationConditionResult: created 'failed' (not satisfied) for condition name:
    "MADOperationConditionTestConnectionSuccess"
```

— the operation reporting no errors while the condition consumed it and reported not
satisfied, which is the disagreement in the log.

**Now:** the three methods write the real error to the caller's `NSError **` (all three
are NULL-tolerant), so `MADOperationDatabaseTestConnection` records the failure and its
message, and `MADOperationConditionTestConnectionSuccess` — which reads `isSuccess` /
`error` through `MADOperationTestResults` — sees the same thing the operation does.
Covered by the `MADTdsClient` offline and live suites; see `BUGS.md`, MADTdsClient
entries for `-connectWithConnection:credentals:connectionError:`,
`-connect:andPassword:error:` and `-executeQuery:withDataTable:andError:`.

**Still open:** whether the connection *succeeds* against the development server is not
something the unit tests can answer — they skip without a server. That is a hand run, and
it now produces a real error message to go on if it fails. The
`[localhost:localhost:1433]` key oddity seen in the same log is a separate problem and
belongs to task 1.

---

## 3. Two fixes that need a human to confirm in the running app

**Status:** Open.

Both are already committed and unit-tested; only a live run can show they are right.

* [ ] **Keychain** — open and create a document, and check that no spurious error alert
      appears. (Overlaps task 1.)
* [ ] **File size** — the document info screen should now read `1.5 MB`, not `1 MB`. The
      `MTMath` conversion used integer division and truncated the fraction
      (`BUGS.md`, Already fixed → MADCocoaExtensions batch).

---

## 4. Unit and UI test coverage for the keychain flow

**Status:** Open — depends on the design decision in task 1.

The keychain is the one part of the flow with **no unit test at all**: the existing
`MADKeyChain` coverage stops at the wrapper, and
`BUGS.md` recorded the delete bug as *"inspection; not covered by a test — keychain
calls"*. That is not good enough for the path the whole product depends on.

Needed:
* Unit coverage for the `MADKeyChain` wrapper: add / read / update / delete, the
  not-found path, and the `NULL` error out-parameter. A test keychain service (a unique
  service string per run, deleted in teardown) keeps these off the developer's real
  credentials.
* Unit coverage for the credential operations — `MADOperationKeyChainPut` / `Get` /
  `DeletePassword`, `MADOperationGetCredentials` — and for
  `MADOperationConditionPolarQuestionAffirmative`.
* **UI test** for the prompt sequence itself, so "two alerts appear" is caught rather
  than discovered by hand. The app already has a `MADDesignerUITests` target.
* A round-trip test that saves a password and reads it back **through the same
  connection-string key** — this is what would have caught the
  `[localhost:localhost:1433]` oddity in task 1.

---

## 5. Caller analysis for the remaining BUGS.md findings

**Status:** Done — every area analysed, every decision recorded in `BUGS.md`.

The second pass covered the 52 findings left after MADFoundation and MADCocoaExtensions.
Each one was caller-analysed before it was touched, because some "confirmed" behaviour is
load-bearing — the `CGRectAdjustForScale` case, where the two callers split the
`zoomScale` domain between them, is the standing example.

The outcome split three ways:

* **43 fixed**, each with the pinning test flipped or added.
* **6 documented and deliberately left alone**, with an in-code comment naming the callers
  that depend on the behaviour: `MADFileManager` self-replacing metadata initialisers,
  `MADDatabaseSQLServer -runSQL:onDataTable:fieldKeys:process:` closing the process it was
  handed, and `-sqlSampleDataForField:andTable:` bypassing the base class's clause builders.
* **3 that needed the user's call**, all three decided: decimal-MB file sizes, the
  year/month/week timer fallthrough, and the modern date/time values — which at the time
  were typed but unfetched. The values were fetched on 2026-10-01 (Track 1.1 of
  `ROADMAP.md`), and getting them uncovered a second defect in the same record: the
  classic `DATETIME` cases had been adding a month that freetds had already added.
  Both are recorded in `BUGS.md`; `SYBDATETIME4`'s base-date arithmetic is newly open.

| Area | Open findings |
|---|---|
| `MADTdsClient` | 1 — `SYBDATETIME4` counts its days from the wrong epoch |
| MAD Designer (app) | 0 |
| `MADMySQL` | 4 — `MysqlUpdate`'s out-of-bounds delete, `MysqlConnection`'s handle-less transaction crash, `MysqlInsert`'s `ULONG_MAX` row count, `MysqlTruncate`'s missing factory guard |
| `MADFileManager` | 8 — two live crashes (`MADCloudFileCoordinator` init, `MADDirectoryMonitor` cancel) plus the `-setFileCoordinator:` URL/metadata mix-up and five lesser records |
| `MAD` | 0 |
| `MADExplorer` | 0 |
| `MADAPI` | 0 |

`MADSqlite3` has none. Each area ended with the same three-part result the first pass
produced: defects fixed, load-bearing behaviour documented instead of changed, and
`BUGS.md` updated in place with the fix, its `Now:` line, and the test that covers it.

**The MySQL half of this caveat is now closed.** `MADMySQL/TestDatabase/mysql-test-db.sh`
builds the live-test server in Docker from a pinned image and a checksum-verified copy of
the standard `employees` dataset, and the scheme starts it for the test action. The
`MADMySQL` suite runs 119 tests, 0 skipped, against that server (verified against the
container on a non-default port — the scheme environment carries the port, because
`xcodebuild` does not forward shell variables to the test process). `MADTdsClient` still
has the old caveat: its live findings were verified offline or by reading the driver.

---

## 6. The macOS library builds and the declarative build system

**Status:** In progress since 2026-10-04 (resumed by the user as the Compressor rework;
was deferred 2026-10-01). Progress:

- [x] Phase 0 — portability micro-fixes: workspace absolute path, `CLI/build.sh`
      DerivedData hash, MADMySQL stray `-v`, inert app `SQLITE_ENABLE_COLUMN_METADATA`.
- [x] Phase 1 — `matrix.conf` + `build.sh` + `lib/recipes/` written and verified
      green for all nine libraries at their baseline versions (sqlite3 3.49.2,
      zlib 1.3.1, openssl 3.5.0 with macosx too, bzip2 1.0.8, libpng 1.6.47,
      libarchive 3.7.8, freetds 1.4.26, mysqlclient 8.0.42, zint 2.4.2).
      mysqlclient took a two-stage design: a native macosx-arm64 build produces
      the host tools and generated files; the cross builds seed those and run
      the tools from the native stage. `build.sh --verify --all` is green.
- [x] Phase 2 — Xcode rewiring to the xcframeworks + ensure phases. All eight
      steps landed one commit per project: MADSqlite3 (links sqlite3.xcframework,
      sqlite3.c no longer a target source, the xcconfig's only consumer is the
      recipe), MAD (libarchive + bzip2 + zlib xcframeworks; the wrong system
      libarchive.2.tbd ref is gone), MADMySQL (mysqlclient + openssl; the
      hardcoded Debug/ search paths are gone with the arms), MADTds (freetds +
      openssl), MADTdsClient (search-path cleanup), MADBarcodes (libpng + zlib,
      then the vendored Zint tree replaced by zint.xcframework with zint.h kept
      Public), and the app (openssl). Every target gained an Ensure Libraries
      phase pinned to ios,simulator. Suites: MADSqlite3 77/0, MAD 238/0,
      MADMySQL 58/0 (live server tests ran and passed), MADTdsClient 75/0;
      MADBarcodes and MADTds build; the app builds for simulator and device.
- [x] Phase 3 — full verification. All twelve suites green (MADSqlite3 77/0,
      MAD 238/0, MADMySQL 58/0 live, MADTdsClient 75/0, MADFoundation 118/0,
      MADAPI 78/0, MADDataStructures 72/0, MADCocoaExtensions 76/0, MADExplorer
      9/0, MADFileManager 31/0; MADBarcodes/MADTds build), the app builds for
      simulator and device, `--verify --all` is green, and the **fresh-clone
      simulation passes**: `git archive HEAD` to a new path, workspace loads,
      `Compressor/build.sh --all` bootstraps all nine libraries from downloads,
      and `MAD Designer` builds for device from the bootstrapped artifacts.
      The simulation caught two real bugs, both fixed: the mysqlclient native
      stage needs the openssl macosx slice, which an ios+simulator bootstrap
      never built (the recipe now builds it inline from the matrix row), and
      per-platform rebuilds dropped the other platforms' slices (finish_library
      now preserves them, creating into a temp xcframework and swapping).
- [x] Phase 4 — macOS slices for every library (the matrix builds all three
      platforms; `--verify --all` across ios+simulator+macosx).
- [x] Phase 5 — version updates, one library per commit: zlib 1.3.2, libpng
      1.6.59, freetds 1.4.27 (75 tests), sqlite3 3.53.3 (D1 gate + 77 tests;
      the bump forced dropping --disable-tcl and touching vdbe.c/parse.y so
      the stale checked-in opcodes regenerate), openssl 3.5.9 LTS,
      mysqlclient 8.4.10 LTS (live server tests pass on the 8.4 client; 8.4
      bundles boost in-tree and dropped libevent, so the recipe's boost
      flags and libevent seeds retired), libarchive 3.8.9, zint 2.16.0
      (cmake recipe; the wrapper needed exactly the ZINT_ error-code
      renames; MADBarcodes builds, MAD 238 tests). bzip2 stays 1.0.8 --
      still the newest release.
- [x] Phase 6 — prune complete: the eleven old scripts and their navigator
      references, and all 1,797 tracked legacy artifact files (`.a` binaries,
      per-platform trees, per-platform include dirs, the tracked sqlite3
      amalgamation). Compressor/AGENTS.md is rewritten for the new system.
      Post-prune, the app builds and MADMySQL's 58 tests pass.
- [x] Phase 7 — untracked: zero files remain tracked under
      Compressor/library. The fresh-clone simulation re-run is the proof of
      this state (in flight at the time of writing).

The user's earlier words, for context:

> *"let's skip section 2.2, The two real builds; we will build for MacOS later. We will also
> put off the declarative build system, though I believe it's important. This info should be
> stored in a plist or something, IDK. We need to keep track of them on some TODO list,
> which previous ones probably haven't been maintained."*

**What this covers.**

*   **`ROADMAP.md` §2.2 — the two remaining macOS builds.** zlib/macOS and
    mysqlclient/macOS. Five of the eight library rows are already built; these two are not.
    `LIBRARIES.md` §3 has the matrix.
*   **`ROADMAP.md` §2.3 — the declarative build system.** `Compressor/matrix.conf`,
    `Compressor/build.sh`, a per-library `manifest.json`, and an XCFramework as the single
    artifact Xcode links. `LIBRARIES.md` §7.3 has the design.

**Why deferring is safe right now.** Neither is on the path to anything the user is doing
next. The `mad` CLI builds for the **iOS Simulator** and runs on the Mac through
`xcrun simctl spawn`, so it links the existing iOS artifacts unchanged — the CLI track needs
no macOS slice at all. And a *native* macOS binary is blocked by the UIKit imports in
`MADFoundation` (`ROADMAP.md` §4.2), which is upstream of the build wiring: even a perfect
matrix would not let a target compile for macOS today.

**What must not be lost.**

*   The user's "store it in a plist or something" is exactly what the `manifest.json` in
    §2.3 is. The design already answers the concern that prompted the deferral, so it should
    be read as confirming §2.3's shape rather than asking for a new one.
*   `ROADMAP.md` §2.1's third bullet is **not** cancelled by this. Adding `[sdk=macosx*]`
    search paths cannot work, because `PBXFileReference.path` names an iOS slice directly and
    is not SDK-conditional. The XCFramework in §2.3 remains the answer, whenever macOS work
    resumes.
*   The standing constraint still holds: nothing in `Compressor/library` is deleted until a
    replacement builds every combination. A deferral is not permission to prune.

---

## 7. The `mad` CLI — the headless path

**Status:** Phases 1–3 done 2026-10-01; the §3.4 housekeeping landed
2026-10-16 with the driver registry (`e0741a187`, `61991e85f`). The Linux
runtime image and its repeatable CLI check landed 2026-10-17
(`Linux/Dockerfile`'s `runtime` stage, `Linux/verify-cli.sh`,
`./Linux/build.sh --runtime|--verify`; `Linux/README.md`). No CI and no
publication — the user's decision that day: the Linux port is a proof of
concept and a regression harness, not a release. See `ROADMAP.md` Track 3.

**The CLI does not ship.** The user's decision, 2026-10-01: *"the CLI isn't going to be shipped
(least not now, it's only for our understanding of how the software works, and testing)."* It
is a developer instrument. That removes signing, notarisation and an installer from scope, and
it means `--credentials user:pass` may take a plaintext argument.

**Why it is the next thing.** It is the only way to read the document with the app out of the
way. `mad inspect` reads the container and the store as raw SQLite — no Core Data, no UI — which
is the reader `MAD_FORMAT.md` §7 asks a second platform to be able to write.

**Phase 1 — the four runs — done 2026-10-01, no code changed.** All four passed on both
samples first time. `mad refresh` did **76 rows (London)** and **3503 rows (Music)**, and
`mad export` wrote a 5-page and a 77-page PDF whose content was read back and checked. The
headless path had never been exercised end to end before this.

| # | Run | What it proved |
|---|---|---|
| 1 | `mad inspect` on London and Music | the container and store read without Core Data |
| 2 | `mad query` on both | the query model loads headlessly |
| 3 | `mad refresh` on London, then Music | the data path, end to end |
| 4 | `mad export --out` | a PDF produced from a headless run |

London went first in run 3: its driver is **Sqlite 3** over a local `chinook.sqlite3`, so no
server sat in the path and a failure would have been the code's rather than the network's.

**Found while doing it:** a refresh rewrites only the cache files it needs and does not clear
the cache directory, so the `{0, 0}` render-cache entries survived a refresh that rebuilt
everything else. Whether that is a measurement cache behaving correctly or stale content is
open — recorded as evidence in `MAD_FORMAT.md` §5.3 and §8.4, not resolved.

Run with `CLI/build.sh --run <command> <document.mad>`; it wants a booted simulator, because it
runs the tool through `xcrun simctl spawn booted`.

**Phase 2 — the surface — done 2026-10-01.** `mad schema` landed (the last stub verb;
`MADCLIUnimplemented.m` is deleted) and prints the stored snapshot: driver, tables sorted by
name, fields with type and a `pk` marker, no credentials needed. `refresh --rows N` landed and
caps the query with a real SQL `LIMIT` rather than fetching everything and discarding: `--rows 7`
returns 7 rows, no flag returns the full set. The cache afterwards holds the capped rows — a
refresh replaces the cache, it does not preview beside it.

**Phase 3 — `inspect` reports the companion files — done 2026-10-01.** `inspect` now lists the
cache directory's files grouped by extension (`.maddb` row data, `.mdcache` index, `.madac`
render cache) with sizes, and per-file under `--verbose`. The directory is found with the app's
own `MADURLFactory` rule, so it cannot drift. Music's cache reads 15.0 MB and is entirely
`.madac`; London's is 402.7 KB and 79% `.madac`. The two render-cache layout identifiers are
now visible side by side — the `{0, 0}` vs `{612, 792}` question in `MAD_FORMAT.md` §5.3 is
reportable instead of hand-measured.

**Done 2026-10-16, with the driver registry.** `MADOperationRefresh`,
`MADOperationRefreshInitialize` and `MADOperationRefreshInitalizeMainDataTable` moved from
the application target into `MAD` (`e0741a187`), in one change with
`MADDatabaseDriverRegistry`: the constructor looks a driver up by `MADDatabaseType`
(`61991e85f`) instead of importing MySQL and TDS, so the refresh chain no longer re-asserts
the cycle. `CLI/build.sh`'s `REFRESH_SOURCES` is gone; the CLI takes the chain from
`-framework MAD`.

---

## 8. Export formats — the third extensibility seam

**Status:** Done 2026-10-16, both halves — the seam and the Foundation formats
(`2c0e6df6c`, `c97ded85c`, `55e386700`), and the byte-identical `.mad` writer
(`mad write`, the reproducible mode, the cross-platform comparison).  The one piece
left in this section is a Linux writer that creates a *store* rather than re-archiving
one: the comparison covers the container today.  It needed two decisions
from the user before code — **the JSON export shape** (`MAD_CLI.md` §8.3,
`MAD_LINUX.md` §10.1) and **the renderer staging** (§10.2, HTML/SVG before PDF) — plus
two more the work raised: how `json-report` reaches the rendered report, and whether
`pdf` moves onto the seam now.  All four were put as options with a recommendation and
answered 2026-10-16: both JSON shapes with the report half as its own format (`json` +
`json-report`); the SELECT list's order defined as the column alias; HTML/SVG next and
PDF last; `pdf` stays the CLI's arm until the HTML step; and, for the byte-identity
work, an opt-in reproducible mode on `-archive:` landing after the formats.

**What landed** (`ROADMAP.md` §5.2, `MAD_LINUX.md` §9 Phase E): `<MADReportExporting>`
and `MADReportExporterRegistry` in the driver registry's shape; `MADReportExportSource`
and `MADReportExportWriter` as the one read and the one write; `text`, `csv`, `json`
(both platforms, byte-identical output on both — digests in `Linux/README.md`) and
`json-report` (Apple; built from the page renderer's walk, now split from its draw).
**Landed since, 2026-10-16 (the HTML step):** the render half's move to Linux — one
formatter (`MADReportFormatter` on `MADDocumentRenderProtocol`), one page walk
(`MADReportPageBuilder`), one set of render reads (`MADDocumentRenderDataSource`) —
so `json-report` runs on both platforms; the two HTML formats the user chose (`html`,
the page-box facsimile, and `html-flow`, the reflowable reading view); and `pdf` on
the seam (`MADReportExporterPDF`, Apple's body, registered everywhere, byte-identical
output).  **What remains:** the Linux PDF writer itself — **deferred 2026-10-17, blocked on the
user's research; do not start it without their decision** (`MAD_PDF_LINUX.md` is the
handoff file: what exists, what is missing, the candidate stacks and the open
questions).  The currency-formatting divergence found on the way
was closed on 2026-10-17 (the report's money is formatted from the document's locale
and precision, so the render-side exports are byte-identical across platforms;
`BUGS.md`'s archive).

Two things landed since this entry was written and belong to it: the driver registry
(`ROADMAP.md` §5.1, `61991e85f`) — the seam shape this task mirrors — and the CLI
running on Linux (`040d162c9`), which is where the first new formats should be proved,
since `--format json`/`csv` are pure Foundation and PDF is not.

**The byte-identical `.mad`** (the user's requirement, 2026-10-16) is the other half of
this work as the queue now stands: `BUGS.md` records that the archive is not
reproducible and that the Linux writer cannot even terminate. Its fix is a
reproducible-writer mode plus the round-trip fixture, which is also the acceptance layer
`MAD_CLI.md` §6 asks for — decide its shape with the user, since it defines `.mad` v1
(`MAD_FORMAT.md` §7).

The project's synopsis promises that a developer can add an **export format** without editing
the core, alongside new database types and new document element types. That promise has no
seam yet: `mad export` has one arm, PDF, behind a string comparison in `MADCLIExport.m`.

The user's framing, 2026-10-01:

> *"You can also create a new export format if you want... put that in the task... export to
> text or email or markdown or any of a hundred things. That's part of the app that is supposed
> to be expandable. But, only do that now if it's quick and it aids the core task."*

**The work.** `MAD_CLI.md` §5.3 asks for a `<MADReportExporting>` protocol, so a new format is a
new class rather than a new branch of a switch. That is the same shape as the driver registry
`ROADMAP.md` §5.1 wants, which is why the two belong together.

**Build text first, when this is picked up.** Not because text is wanted, but because it is the
cheapest proof the seam is real: pure Foundation, no Core Graphics, and it puts the report's
content in front of you in a terminal without a PDF viewer. If the seam is right, text is an
afternoon. If it is not, text is where that shows — before JSON or CSV have been written
against a shape that cannot hold them.

**Why it waits.** An exporter that renders nothing because refresh is broken proves nothing
about the seam, and today nobody has run refresh headlessly at all. Task 7 Phase 1 changes
that. After it, this is quick and it does aid the core task, which is the user's own test for
whether to do it now — so it is queued directly behind Phase 1 rather than at the back.

---

## 9. The portable store migration

**Status:** Phases A, B and C landed on `portable-store-phase-a` (2026-10-03) — the store, the
legacy converter, and the app integration, with the document path, undo and dirty-tracking
proven. Phase D is most of the way in: `MADocument` is a `UIDocument`, the legacy converter
lives in the application target behind `MADLegacyStoreConversion`, the compiled `.momd` is out
of the MAD framework, a converted document prunes its Core Data files before saving, and the
framework/MADDesigner sweep removed the remaining Core Data imports, types and dead code
(`2bf9af919` and its follow-up). Kept by decision: the value transformers, the explorer's
cloud pane, the iCloud entitlements/`Info.plist` container, and `MADocumentState` (reserved for
a future cloud-status feature). `MAD_STORE_PHASE_C.md` §9 holds the review findings;
`MAD_LINUX.md` Phase A is the tracker for the remainder — nothing blocks Linux on Core Data
now, so what is left there is the iCloud/entitlement cleanup the user has deferred.

The `.mad` store moves from Core Data to a portable SQLite format of our own — this is the
decision in `MAD_FORMAT.md` §8.1 and `ROADMAP.md` §4.2, and it is what removes the last Apple
dependency (hazard H3) so a reader on another platform can open a document.

The user's direction on how, verbatim in substance:

> *"we are moving the store to a portable Sqlite3 file format. But, I thought we would continue
> to use the auto generated headers... not auto gen them anymore, but just use them, and write
> the code to insert and update the tables most ourselves for the Rptq stuff. Anyway, that's a
> big project, and it's going to take some planning, because it has to convert reports, etc."*

So: keep the generated `Rptq` headers as a fixed, hand-maintained contract (stop regenerating),
and write the CRUD against a SQLite schema by hand. The hard part is not the schema — it is
**converting existing documents**: every shipping `.mad` carries a Core Data store, and the
migration must read one and write the other without losing a report.

**A simplification that comes with it.** `MADocument` is a `UIManagedDocument`, so dropping
Core Data drops the iCloud document machinery along with it. The user's note, 2026-10-01:
*"with getting rid of Core Data we are also getting rid of iCloud stuff. That should simplify
the application."* Fold that into the plan — the migration is also a de-iCloud-ing, and the
document-open/save path gets simpler, not just more portable.

This is independent of v1 (`ROADMAP.md` §4.3, the magic header + checkpointed store): v1 is
identification and a checkpoint, and neither cares what the store's schema is. Do not couple
the two.

Not to be started without the user asking for it by name, and only after a written plan that
covers the conversion of the two shipping samples and the existing user reports.

---

## 10. Third-party licence compliance

**Status:** Open — the plan is written and one item is done. The register is
`THIRD_PARTY_LICENSES.md` and the plan is `LICENSE_COMPLIANCE_PLAN.md`; read those
first, this entry is only the queue. Done so far: the miniz copyright headers were
corrected (2026-10-04).

The review found one blocker, three components with no licence grant at all, and a set of
notice obligations the app does not currently meet (it ships no attributions).

**Delayed 2026-10-17.** The user is not taking D1 yet: the CLI deliverable comes
first.  Nothing here is started, and the image keeps mysqlclient until D1 is decided;
if an image is ever *published* before then, the GPL exposure below becomes real and
has to be raised with the user, not decided by an agent.

**Blocker — needs an owner decision, not an agent.** `libmysqlclient` 8.4.10 is GPLv2,
and the Universal FOSS Exception covers only software that is itself FOSS. _MAD Designer_
is proprietary, so shipping the MySQL client library as configured obliges us to release
the app's source under the GPLv2. The options are: buy an Oracle commercial licence,
replace the client with MariaDB Connector/C (LGPL-2.0-or-later, same C API — all 27
`mysql_*` entry points `MADMySQL` uses are in its surface), or drop MySQL support.
Linking it dynamically does **not** help; GPL copyleft is indifferent to the link mode.
Do not submit a build until this is resolved. `LICENSE_COMPLIANCE_PLAN.md` §3 is the
step-by-step for the MariaDB route.

**Unlicensed code that must be resolved.** Three committed components carry "all rights
reserved" and no grant: the Karl Kraft MySQL connector (`MADMySQL/Source/`, 30 files), and
`NSData+AES256` (`MADDesigner/Source/`, a pastie snippet with no author), and
`NSOperation+Advanced` (`MADFoundation/Source/`, two small methods, upstream
`kas-kad/AdvancedNSOperations` has no LICENSE file). All three are rewrites rather than
negotiations. On the connector specifically: the original distribution (examined
2026-10-04, then deleted) carries no grant either — a public blog post is not a
dedication to the public domain — and since the MariaDB swap means touching that layer
anyway, the plan rewrites it as first-party code (plan §3 A3).

**Mechanical compliance work, once the above is decided.** Add an Acknowledgements surface
and commit the licence texts; FreeTDS needs its LGPL notices, a marked modified `sybdb.h`
and a written relink offer (elect LGPL-3.0 — it links OpenSSL 3, and Apache-2.0 is not
compatible with the v2 terms); add the OFL text for FontAwesome and the readme for
CarbonBlock. The miniz headers were corrected on 2026-10-04.

**Linux toolchain, flagged 2026-10-06 (see §11).** The Phase B image builds on
libobjc2 (MIT), libdispatch (Apache-2.0 with the Swift runtime exception), GNUstep
Make (GPL-3.0-or-later) and GNUstep Base (LGPL-2.1-or-later), and compiles
gnustep-make's GPL-3.0 `Testing.h` into its test binaries. Nothing is linked into
the app. A runtime image now exists (Phase F, `Linux/Dockerfile`'s `runtime`
stage) and contains mysqlclient and GNUstep Base, but it is built and run
locally and is not published (user decision, 2026-10-17), so no register entry
is due; if it is ever distributed, GNUstep Base slots into Workstream B's
mechanism, mysqlclient is the §3 blocker, and the rest need entries of their
own. `Linux/README.md` §Licences carries the detail.

Do not start any of this without the user asking for it by name — the blocker in
particular is a business decision, not an engineering task.

---

## 11. The Linux toolchain (MAD_LINUX.md Phase B)

**Status:** Done 2026-10-06 on `linux-port` (renamed from `linux-phase-b`; merged to `master` 2026-10-16, `524e0d86e`) — the spike is green, and
Phase C is the next step. Two of Phase C's inputs come from this work: the GNUstep
divergences recorded in `Linux/README.md`, and the shim list being that much shorter.

**What landed.** `Linux/` builds one Docker image — Ubuntu 24.04, distro clang 18,
source-built libobjc2 2.3, libdispatch 6.1.3, gnustep-make 2.9.3 and gnustep-base
1.31.1, all pinned in `Linux/toolchain.conf` — compiles 23 of the 27 MADFoundation
implementation files plus `madlib.c` against GNUstep, and runs 15 test executables
(14 ported suites and the toolchain probe) inside the container: all pass, with 5
recorded needs and the probe's 10 report items. `./Linux/build.sh` is the entry
point; the iOS suite (118 tests, 0 failures) is the regression gate for the six
small platform guards the build required. The amd64 cross-check ran end to end on
an arm64 machine (2026-10-06): the toolchain builds under emulation and the run is
15/15 with the same 3 needs and 10 report items.

**The finding that mattered — settled 2026-10-06.** GNUstep's `NSOperationQueue`
removes its `isReady` KVO observation on every notification, and MADOperation's
state machine used to notify `isReady` more than once per enqueue (`Pending` →
`EvaluatingConditions` → `Ready`) where Apple's notifies once; the second removal
raised `NSInvalidArgumentException` and the operation never ran, which put the
Phase D refresh path at risk. MADOperation now drives the advance explicitly from
`-willEnqueue` and sends `isReady`/`isExecuting`/`isFinished` KVO only on real
value changes, so the queue sees one notification, as Apple's does. The Linux
tests assert the queue paths plainly on both platforms and the counted needs
dropped from 5 to 3 (the probe's archiving/app-group items and the credential
secure-coding item remain). The mechanism is written up in `Linux/README.md`.

**Not proved by this phase, deliberately:** the four excluded files (`BDHost`,
`MADApplication`, `MADKeyChain`, `MADURLFactory`), the CLI, the other frameworks and
drivers, export formats, CI and shipping. Phase D's data-path checkpoint remains the
go/no-go.

**Follow-ups this created:**
* ~~the eight other `madlog.h` copies each need the same platform branch when their
  frameworks reach Linux~~ — done 2026-10-06: all nine copies are consolidated
  into MADFoundation's single `madlog.h`/`madlog.m`, with per-target
  `MADLOG_ACCESSOR` routing; the other frameworks' remaining Phase C work is
  their direct `os_log_*(Get*Log(), ...)` call sites (§12);
* ~~MADFoundation's headers are not self-contained — the Linux build paper over
  that with `Compat/MADCompat.h`~~ — done 2026-10-06: every header and source in
  the Linux build imports what it uses (verified by compiling each as a
  one-line translation unit with only the `NSOperation name` shim as prelude),
  and `MADCompat.h` is that shim alone;
* the licence-register entries for the toolchain components (§10 above).

Not to be started without the user asking for it by name.

---

## 12. Linux Phase C — the §4 shim list

**Status:** Done 2026-10-06 on `linux-port`, merged to `master` 2026-10-16
(`524e0d86e`). All ten headless
frameworks compile and link inside the Linux image, their suites run under
ctest, and the remaining exclusions are named with reasons in each
`Linux/cmake/<Name>Sources.cmake`. Phase D — the CLI/data-path checkpoint —
landed 2026-10-16 and is written up in `Linux/README.md` and `MAD_LINUX.md` §9:
`mad` builds and runs in the image, `inspect`/`schema`/`query`/`refresh` are
green against the fixtures in `CLI/Fixtures/` and against live MySQL and SQL
Server, 117 executables (1153 tests) pass under ctest, and the document
question is settled with `MADDocumentDataProtocol` + `MADHeadlessDocument`
(user's choice, 2026-10-16).

**The audit, re-run 2026-10-06 before the work and again at the end** (files
matching the pattern, `*.m`/`*.h`/`*.c`, `.xcodeproj` excluded). Before:
`asl.h` MAD 2; `copyfile.h` MAD 2; `vm_param` MAD 1; `CFNetwork`/`CFHost`
MADFoundation 1; `os/log.h` MADFoundation 1 (the intended Apple branch);
`CoreFoundation` MADFoundation 2, MAD 18, MADSqlite3 1; `UIKit` MADFoundation
4, MADCocoaExtensions 12, MADAPI 3, MAD 29; `CoreGraphics` MADCocoaExtensions
3, MAD 14; `AppKit` MADFoundation 1. The app side (MADDesigner/MADExplorer) is
out of scope by §3's table; the stand-alone MAD Viewer target's
`MADNavigationController.m` keeps its own `<os/log.h>` — it links no MAD
frameworks.

**What landed, framework by framework** (all on `linux-port`, now `master`):

* **The logging layer.** `madlog.h`'s non-Apple branch supplies `os_log_t`,
  `OS_LOG_DEFAULT`, `os_log_create` and the five `os_log_*` functions as
  macros over `MADLogEmit`, so every framework's Apple-spelled call site
  compiles unchanged; the accessors exist as no-op handles, and
  `MADLogFormat` strips the `%{public}` annotations GNUstep would print
  literally. Swept for `os_log_*` outside the header: none remain.
* **MADFoundation.** `BDHost` (`getaddrinfo`/`getnameinfo` behind `__APPLE__`,
  AF_PACKET for the ethernet walk), `MADApplication` (nil `AppDelegate`
  headless; the header forward-declares `UIApplicationDelegate`),
  `MADURLFactory` (no screen; the app-group path falls back to the per-user
  directories). `MADKeyChain` stays out (§4) and the umbrella with it. 26 of
  27 files.
* **MADDataStructures** (all 17), **MADFileManager** (10 of 11; the cloud
  coordinator out per §4, the directory monitor ported over inotify),
  **MADCocoaExtensions** (7 of 17: the ten UI files out), **MADAPI** (8 of 11:
  the connection view controllers out), **MADSqlite3** (all 26),
  **MADTds** (1), **MADTdsClient** (4 of 5), **MADMySQL** (18 of 19).
* **MAD** (150 of 181). The §4 items: the `asl.h` and `vm_param.h` imports
  were vestigial and went; `copyfile(3)` is answered in POSIX
  (`Compat/MADCompatFileCopy.h`); the CoreFoundation sites are the
  `CFNumberGetValue` extraction calls, answered by a compat
  `CoreFoundation/CFNumber.h`. The 31 exclusions group as: the UI tail
  (§5.2), `MADocument` + the operations that build/close one (Phase D's),
  the keychain operations (§4), and the MADBarcodes-backed element files
  (§3: unused; the element *type* stays in the model and the two creation
  paths log-and-skip it off Apple).
* **The libraries layer.** `Linux/libraries.conf` + `lib/libraries.sh` build
  sqlite3 3.53.3 (the released amalgamation, compiled with the option list in
  `Compressor/sqlite3.xcconfig`), openssl 3.5.9, freetds 1.4.27, zlib 1.3.2,
  bzip2 1.0.8, libarchive 3.8.9 and mysqlclient 8.4.10 into the image's
  `/usr/local`. Nothing ships; the GPL question is
  `LICENSE_COMPLIANCE_PLAN.md`'s (§10).

**The tests.** Every ported suite is one ctest executable under
`Linux/Tests/`, written to the `Testing.h` conventions in `Linux/AGENTS.md`.
114 executables (1098 tests) run under ctest, all passing, with 6 recorded
needs — the counter and each need are argued in `Linux/README.md`. The
coverage master merged on 2026-10-10 (~100 Xcode test files across MAD,
MADFoundation, MADAPI, MADCocoaExtensions, MADFileManager, MADSqlite3 and
MADMySQL, plus the MySQL test-database Docker infra) is ported in full: 55
new executables, suite for suite. The suites that need a live database skip
(never fail) when none is reachable; `MADTdsClientLiveTests` was run against
the SQL Server 2022 container from inside the Linux image — 29/29, 169 checks
— and `MADMySQLLiveTests` against the host's MySQL (44/44, 309 checks), so
the wire paths are exercised, not just compiled.
MAD's eight suites are ported too (186 tests over the data table, the portable
store, the rptq object layer, the query and the document section), and running
them found three more GNUstep divergences, all fixed or shimmed and written
down in `Linux/README.md`: BOOL's runtime encoding (`'C'` here, `'c'` on
Apple — registered per-platform in `RptqObject`), `class_getProperty()` not
walking superclasses (an explicit walk in `RptqObject`), and the stub
`+propertyListWithStream:options:format:error:` (a Compat category, which lets
MADDataTable's `-loadFromCacheWithUrl:` be asserted instead of parked as a
need). The merge-and-port round added more: the framework targets' dropped
`$(inherited)` (DEBUG was dead in every Apple framework target — fixed in the
ten projects) and MAD's non-hermetic document fixtures (both recorded in
`BUGS.md`); on the Linux side `NSOperation.asynchronous`/`-isConcurrent` (a
Compat category — without it a finishing async operation raised out of
`-dealloc`), the faulting `-coordinateAccessWithIntents:` (a Compat category),
scheme-less URLs from `MADURLFactory` (now `+fileURLWithPath:`), and
MADQuery+Sqlite3's category being dropped by the linker (compiled into
`libmad.a` via `target_sources`). Six needs remain for Apple-only machinery —
Core Data, the compiled model, `MADocument`, the converter — recorded in the
tests that cannot run.
One divergence stays pinned rather than fixed:
`-localizedCaseInsensitiveCompare:` is case-sensitive on GNUstep, so the
SQLite collation MADSqlite3 registers orders differently (asserted per-platform
in `MADDatabaseSqlite3Tests`).

**Exclusions that remain, and where they are recorded:** `MADKeyChain` and
the umbrella (MADFoundation), the cloud coordinator (MADFileManager), the ten
UI files (MADCocoaExtensions), three view controllers (MADAPI), one
(MADTdsClient), one (MADMySQL), and MAD's 31 — each named with its reason in
the framework's `cmake/<Name>Sources.cmake`. `MADExplorer`, `MADBarcodes`,
`MADFeedback` and `Scrimpter` are not built at all (§3's table).

**Follow-ups carried forward:**
* ~~the driver registry (`ROADMAP.md` §5.1)~~ — done 2026-10-16 (`61991e85f`):
  `MADDatabaseDriverRegistry` registers the drivers, the constructor looks them
  up, and the Linux build whole-archives the driver archives so their categories
  and `+load`s survive the static link;
* ~~`MADocument` and `MADReportFormatter`~~ — settled 2026-10-16 by the user's
  choice of a headless document path: `MADDocumentDataProtocol` is the data
  half, `MADHeadlessDocument` implements it, `MADocument` conforms unchanged, and
  the refresh chain runs against either. `MADReportFormatter` stays Apple-only
  and so does `mad export` (§8);
* the toolchain and library components' licence-register entries (§10) — Phase
  F work, at the moment an image ships.

---

## 13. Compiler-warning and analyzer cleanup

**Status:** In progress — five frameworks done 2026-10-17 and MADBarcodes cleared
2026-10-20; the app and MAD remain.

The 2026-10-17 clean Analyze of `MAD Designer` reported 128 raw / 124 unique
compiler warnings and 98 analyzer issues. The five requested frameworks were
cleared first, each analyzed in isolation with a private derived-data path and
each committed with its suite green:

* **MADTds** — no first-party diagnostics; the vendored `sybdb.h` quote and the
  Compressor sandbox note stay documented. Commit `c55cef2bc`.
* **MADTdsClient** — 8 cleared; `-runSQL:` now logs and propagates its SQL
  errors. Suite 76/76 against SQL Server 2022. Commit `93c2e1d57`.
* **MADMySQL** — 3 cleared; NULL `error` guarded, `MYSQL_BIND` zero-initialised.
  Suite 121/121 against MySQL. Commit `598cadd03`.
* **MADAPI** — 3 source and 12 test-bundle `-Wnonnull` cleared. Suite 105/105.
  Commit `cd814227d`.
* **MADSqlite3** — 11 source and 5 test-bundle warnings cleared; the
  `MADArrayCaching` initializer contract and the `MADDataTableFast` nil paths
  were settled with the user. Suite 89/89 (5 benchmarks skipped). Commit
  `daff35986`.
* **MADBarcodes** — 20 compiler warnings and one analyzer issue cleared in an
  isolated clean build and Analyze. The `CGImageCreate` alpha is cast to
  `CGBitmapInfo`, the `height` assignment casts to `float`, the out-parameter is
  explicitly `__autoreleasing`, and the already-bounded copy into zint's
  `primary[128]` uses `memcpy` instead of `strcpy`; seventeen
  `NSInteger`/enum option assignments took explicit `int16_t` casts, behaviour
  unchanged. Suite 29/29; app build green. The project's Copy Headers sandbox
  note is a build-setting warning, not source. Commit `2be05d692`.

`./Linux/build.sh` passes 120/120. The full-project analyzer count stood at 86
after the five frameworks (was 98); MADBarcodes' one isolated issue is cleared
here, and all remaining analyzer results and compiler warnings are in the app
and MAD. The test bundles also carry a deployment-target linker
warning (XCTest built for 17.0, bundle floor 15.0) that belongs to §6/the
project-settings pass.

---

## 14. Report formatter end-to-end performance

**Status:** Open — the group-boundary comparison phase is done (`327cccc1b`);
the per-row work below is what remains.

The 2026-10-20 performance pass resolved one comparator per group level once
per format and computed one changed flag per level per row, shared by the
header and footer walks. On the synthetic 200k-row, 3-level format used to
measure it, the boundary phase fell from ~0.20 s to ~0.03 s (5–6×), and the
London and Music `json-report` exports stayed byte-identical. That phase is
now ~0.1% of a ~38 s Debug/simulator format; the rest is the per-row work
below. The design and the measurements are in commit `327cccc1b`; the
correctness contract it builds on is `483a77259` and the archived entries in
`BUGS_FIXED.md` (“MADReportFormatter compares untyped values through id” and
“The cache's ORDER BY ignores column types, so text keys sort binary”).

**Hot spots, in expected-impact order.**

1. **The page index array is copied per row.** `MADReportFormatter.m:756`:
   `self.pageIndexesTemporary = [self.pageIndexesTemporary arrayByAddingObject:rowIDObject]`
   is an O(page) copy for every detail row, O(rows²/page) over a page. The
   loop's own comment (`:687-692`) already suspects it in the memory-spike
   story. Replace it with one mutable page buffer reset per page, flushing a
   copy into the report caches at the page break and at the end; keep the
   arrays the caches receive unchanged. Likely the largest wall-clock win.
2. **A fresh key-value array per row.** `-newObjectArrayKeyValuesForResultRow:`
   (`:491`, called at `:708`) allocates an `NSMutableArray` and does one
   dictionary lookup per group per row. A reusable per-formatter buffer (or
   an enumerator that hands the keys back) removes the allocation. Do not
   change the method's public result: `MADDocumentRenderDataSource
   -groupLevelKeys:` uses it for the aggregate WHERE clauses
   (`MADDocumentRenderDataSource.m:87`), so a reused buffer must stay internal
   to the formatter.
3. **Per-row `@autoreleasepool`.** `:687-693`. It is deliberate and prevents
   the 8k-page memory spike; do not remove it. Measure it only after 1 and 2,
   and only if the remaining per-row work warrants it.
4. **Per-detail-row section objects and cache inserts.** Every body row
   allocates a `MADSectionRepresentation` (`:752`), and each page's layout and
   index arrays are inserted into `MADArrayCaching` (`:638-641`, `:861-867`).
   A representation pool or a different page-layout carrier is a larger design
   change; measure before designing.
5. **The public comparator's per-call path.** `+compareValue:withValue:forDataType:`
   (`:335-352`) resolves the family per call (`MADComparisonFunctionForDataType`,
   `:329`) and measured ~16 ns slower than the pre-pass implementation. It is
   the test-facing and rare path, not the row loop; leave it unless an
   external caller ever makes it hot.

**How to measure and prove a win.** Reproduce the baseline on the same machine
and configuration:

* a `MADDataTableVirtual`-backed document with 200,000 rows and 3 group levels
  (a ten-value repeating pattern so ~1,110 boundaries fire), timing `format:`
  as the median of three runs, with a 0-group control;
* report the boundary phase and the end-to-end time separately: the end-to-end
  is noisy (±1.5 s on this machine), so a change that only moves a small phase
  may not show there;
* build the CLI (`CLI/build.sh --no-frameworks`), refresh and export London
  and Music with `--deterministic`, and compare the `json-report` bytes; they
  must be identical before and after;
* run the MAD suite and `./Linux/build.sh` (plain, Docker up);
  `MADReportFormatter.m` is in the Linux build.

**Done when:** at least one hot spot shows a measured end-to-end improvement
above the noise floor, the exports are byte-identical, and the MAD and Linux
suites are green. Do not change the comparison contract, the header/footer
walk order, or the page arrays the caches receive as part of a speed change.

**Follow-ups without a queue entry yet:** Enum storage (`"red"` parses to 0)
and the cache `user_version` stamp that would let the pre-contract cold
fallback retire. Both currently live only in the archived `BUGS_FIXED.md`
entry; give each its own task or `BUGS.md` entry when it is picked up.

---

## 15. Barcode element: modernize MADBarcodes and re-integrate the element

**Status:** In progress -- Tasks 0-4 implemented (rename, framework defects, cached
render path, warning sweep); Tasks 5-8 remain.

The barcode element was never removed from the Apple app -- it is wired end to end
(model `RptqDocumentElementBarcode`, render `MADPrintPageElementBarcode`, the
`MADDesigner/Source/barcodes/` editor, the `MADBarcodeDesigner.storyboard`) and
hidden only by the designer picker's IAP check
(`MADDesignerElementPickerViewController.m:117-120`). The user's decision
(2026-10-20): the element is **always available** -- the picker gate comes off.
The `MADBarcodes` framework wraps zint 2.16.0 (Compressor recipe) behind 67
`MADBarcode*` symbology subclasses, has a green 29-test suite, and is excluded from
the Linux build by design (the `#if __APPLE__` creation paths log-and-skip).

The full survey, the design decisions (framework-only rename `MTBarcode*` ->
`MADBarcode*`; one-`CGImage`-draw render path plus an `NSCache` for the per-row
perf requirement; the four pinned `BUGS.md` framework defects; the base-`type`
clobber and the store colour-columns bug that may crash barcode creation on
Apple), and the self-contained per-task prompts for a flash model are in
**`MAD_BARCODES.md`** -- the implementer starts there, with Task 0 (baseline) and
goes in order. Known defects this track closes: the `BUGS.md` `## MADBarcodes`
entries (duplicate name key, QR/EAN128 wrong symbology, ISBN recursion, `strcpy`
overflow, broken NSCoding) and "The store's colour columns have no reader"
(whose one writer is the barcode creation path). Gates per task: the
`MADBarcodes` and `MAD` suites, the app build, and `./Linux/build.sh` (the
guards and `MADSources.cmake` exclusions stay intact). Out of scope, documented
in `MAD_BARCODES.md` §5: headless barcode rendering, GS1/Data input modes, HTML
barcode images, the notices gap.
