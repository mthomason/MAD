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
| `MADMySQL` | 0 |
| `MADFileManager` | 0 |
| `MAD` | 0 |
| `MADExplorer` | 0 |
| `MADAPI` | 0 |

`MADSqlite3` has none. Each area ended with the same three-part result the first pass
produced: defects fixed, load-bearing behaviour documented instead of changed, and
`BUGS.md` updated in place with the fix, its `Now:` line, and the test that covers it.

**One thing this pass did not settle:** every live-database finding was verified against
the offline suite or by reading the driver, not by a run against a real server. The
`MADMySQL` and `MADTdsClient` live suites skip when no server is reachable, so a
`scheme`-level green run does not mean the wire path was exercised.

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

**Status:** Phases 1–3 done 2026-10-01. Remaining: §3.4 housekeeping (move
`MADOperationRefresh` into `MAD`). See `ROADMAP.md` Track 3.

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

**Not first:** moving `MADOperationRefresh` into `MAD`. The refresh chain reaches
`MADDatabase+Constructor`, which imports all three drivers, so the move re-asserts the
`MAD`↔drivers cycle that `ROADMAP.md` §5.1 exists to cut. Do it together with the driver
registry, not before. Until then `CLI/build.sh`'s `REFRESH_SOURCES` compiles it across the
target boundary and it works.

---

## 8. Export formats — the third extensibility seam

**Status:** Open. Do not start before task 7's Phase 1.

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
the app and no image ships yet, so no register entry is due; when one does
(Phase F), GNUstep Base slots into Workstream B's mechanism and the rest need
entries of their own. `Linux/README.md` §Licences carries the detail.

Do not start any of this without the user asking for it by name — the blocker in
particular is a business decision, not an engineering task.

---

## 11. The Linux toolchain (MAD_LINUX.md Phase B)

**Status:** Done 2026-10-06 on branch `linux-port` (renamed from `linux-phase-b`) — the spike is green, and
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

**Status:** Open, and smaller than `MAD_LINUX.md` §4's 2026-10-04 table: the
pre-Phase-C work on branch `linux-port` (§11) cleared three rows before Phase C
started. Not to be started without the user asking for it by name.

**The audit, re-run 2026-10-06** (files matching the pattern, `*.m`/`*.h`/`*.c`,
`.xcodeproj` excluded):

| Shim | Frameworks |
|---|---|
| `asl.h` | MAD 2 |
| `copyfile.h` | MAD 2 |
| `vm_param` | MAD 1 |
| `CFNetwork` / `CFHost` | MADFoundation 1 (`BDHost.m`) |
| `os/log.h` | MADFoundation 1 (`madlog.h` itself — the intended Apple branch) |
| `CoreFoundation` | MADFoundation 2, MAD 18, MADSqlite3 1 |
| `UIKit` | MADFoundation 4, MADCocoaExtensions 12, MADAPI 3, MAD 29 |
| `CoreGraphics` | MADCocoaExtensions 3, MAD 14 |
| `AppKit` | MADFoundation 1 (`MADApplication.m`) |

The app side (MADDesigner: 312 UIKit, 13 CoreGraphics, 3 `asl.h`; MADExplorer: 19
UIKit) is out of scope by §3's table — the UI stays on Apple platforms. One
deliberate exception inside it: `MADDesigner/Source/MADNavigationController.m`
imports `<os/log.h>` because it logs with `OS_LOG_DEFAULT` and is compiled by the
stand-alone MAD Viewer target, which links no MAD frameworks.

**Already cleared by the pre-Phase-C work (§11):**
* the eight extra `madlog.h` copies, and with them every framework's direct
  `<os/log.h>` import (MADAPI 4, MADFileManager 2, MADSqlite3 4, MADMySQL 2,
  MADTds 1) — what remains is the one header's Apple branch, above;
* MADFoundation's non-self-contained headers — the Linux prelude is down to the
  `NSOperation` `name` shim, and every header and source in the closure imports
  what it uses;
* the MADOperation/`NSOperationQueue` KVO blocker to the Phase D refresh path.

**What Phase C still owns** (the §4 disposition table, still accurate):
`getaddrinfo` for BDHost; the asl/copyfile/vm_param swaps in MAD; the CoreFoundation
sites (GNUstep equivalents — CoreBase is immature, do not rely on it); the
UIKit/CoreGraphics tail in MAD, MADCocoaExtensions and MADAPI; the AppKit branch in
`MADApplication.m`; the two `#if`-guarded one-liners (`UIScreen` in MADURLFactory,
the background task in `MADOperation.m`); plus the frameworks' `os_log_*(Get*Log(),
...)` call sites as each reaches Linux.

**Follow-ups carried forward:**
* the driver registry (`ROADMAP.md` §5.1) — it breaks the `MAD` ↔ drivers cycle
  and is what lets a Linux build link drivers as plugins; `MADOperationRefresh`
  does not move into `MAD` until it exists (§7);
* the toolchain components' licence-register entries (§10) — Phase F work, at the
  moment an image ships.
