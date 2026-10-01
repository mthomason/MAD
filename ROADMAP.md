# ROADMAP.md

The plan for the next stretch of work on _MAD Designer_, and the order to take it in.

This file is a **plan**, not a queue you act on. `BUGS.md` is the defect register, `TASKS.md`
is the engineering queue, `TODO.md` is the product wishlist. This one says which of those, and
which of the three design documents written on 2026-10-01, get picked up next and why in that
order. Work starts here when the user asks for a track by name or number.

Written 2026-10-01, against `master` at `073bb2e24`.

---

## Where the project stands

Recorded so the plan can be read cold.

**The repository is clean and backed up.** `master` and `refactor/mad-database-decouple` are
both at `073bb2e24` and both pushed. `feature/mad-format-and-cli` was deleted after its work
landed on `master`.

**The tree builds and the suite is broad.** `MAD Designer` builds. 885 test methods across 11
suites, with `MADMySQL` and `MADTdsClient` carrying live suites that skip when no server is
reachable. Both a MySQL and a SQL Server instance are available for live work, and the `mad`
CLI can drive a report without the UI.

**The registers are in much better shape than their headline counts suggest.** `BUGS.md` holds
76 entries; 56 are fully fixed. Of the 20 that are not, **12 are documented deliberate
non-defects** — load-bearing shapes recorded so nobody "fixes" them. That leaves roughly four
genuinely open defects, listed in Track 1.

**The remaining work is mostly planned and unstarted, not unknown.** Three design documents
were written on 2026-10-01 — `MAD_FORMAT.md`, `MAD_CLI.md`, `LIBRARIES.md` — and the
`MADDataTable` architecture report carries a six-phase migration whose phases 0–5 have largely
landed. What is left is execution.

---

## Track 1 — Close the real bug backlog

**Start here.** The defects are few, they are understood, and every one of them is testable
today against the live servers.

### 1.1 SQL Server loses every modern date/time value — **done 2026-10-01**

`DATE`, `TIME`, `DATETIME2` and `DATETIMEOFFSET` came back as `[NSNull null]`. Only the column
*type* had been corrected; the values were dropped. This was the worst remaining defect because
it is silent data loss on a shipped driver.

The values are now fetched. The fix is smaller than it looked: these type codes need **no bind
array at all**. freetds keeps each value in the row buffer already decoded into its own internal
layout, and `dbanydatecrack()` — handed that buffer plus the column's own type code — does the
rest. Binding would have copied a *converted* layout somewhere else and then cracked the wrong
thing.

Doing this surfaced a second, older defect in the same freetds record: the classic `DATETIME`
and `DATETIMEN` cases were adding a month that freetds had already applied, so every SQL
`DATETIME` came back a month late and December came back a year late. That is fixed too, by the
same live tests. `SYBDATETIME4`'s base-date arithmetic is newly recorded as open.

`BUGS.md`, MADTdsClient, **Fixed**; tests `testSelectModernDateTimeTypes`,
`testSelectModernDateTimeTypesNull`, `testSelectClassicDateTimeKeepsItsMonth` (live).

### 1.2 The `MADDataTableFast` row counter — two documents disagree — **done 2026-10-01**

The two documents were `BUGS.md` and `BUGS.md`. The older entry, under *Already fixed (for
reference)*, still read "Fixed for the reload path; the in-memory path is still open" and asked
for the caller audit; the newer entry in the `MADSqlite3` section reads **Fixed** at `850c32f51`
with four tests, and that is what the architecture report's Revision 5 is describing. So the
report was right and the stale document was the older `BUGS.md` entry.

The code settles it: `-dropTableName:` (`MADDataTableFast.m:887`) and `-deleteAll` (`:904`) zero
the counter, `-vacuumCacheDb` (`:868`) deliberately does not, and `-removeAllObjects` (`:756`)
does. `-numberOfRows` / `-count` returning the ivar rather than querying the file is the design —
`-recountRows` is the reload path's check, not a per-read cost.

Corrected the stale entry's status and `Now:` line to point at `850c32f51`, so the register no
longer contradicts itself. No code changed; nothing was open.

### 1.3 The MySQL `MADDataTypeMySQL` mapping — **done 2026-10-01**

Two mappings were a standing "deferred". Both are now decided and written down.

`MYSQL_TYPE_TIME` **is corrected** to `MADDataTypeTime`. The mapping was live
(`MADDatabaseMySQL.m:247`) and wrong in a way that showed: `MysqlFetch+DataTable.m:431` builds
the value from hour/minute/second alone, so the `NSDate` carries the calendar's default date,
and `dateTimeformatter` rendered "1/1/01, 1:45 PM" for a pure clock. `MADDataTypeTime` is not a
dormant case — the SQL Server driver has produced it for years and its live suite asserts it —
so the clock-only branch is already exercised. Test flipped: `MADMySQLTests.m`.

`MYSQL_TYPE_NULL` **stays `MADDataTypeNumber`**, and now says why. `MADDataTypeNull` is the
*binding* null (`MADDatabaseDataBinding` for null parameters, `MADQuery+Sqlite3.m`), not a
column type, and it has no schema display case, so it would render as "Type 24". A NULL-typed
column can never hold a value, so the mapping only picks a schema label and a formatting branch.

`MADMySQL` suite: 58 tests, 0 failures.

### 1.4 Unblock `MADTestReportFormatter` — **done 2026-10-01**

The recorded reason was wrong. The test was said to be blocked until the Core Data model went
into a build phase; `MAD.xcdatamodeld` has been in the `MADTests` Sources phase all along, and
`MADCoreDataModelTests` has been loading `MAD.momd` from the test bundle for as long as it has
existed. So the item was not "solve the model" — the model was already solved, and what was
left was a fixture that had never run.

Reviving it took four independent fixes, recorded in `BUGS.md` under *Test infrastructure*:

- A `MADTestReportFormatterDocument` double, because the test cast a plain `RptqDocument` to
  `MADocument *` and the formatter reads `-filename` and `-database` off it. A real
  `MADocument` cannot stand in — opening one unarchives a `.mad` the app's create path makes.
- The model loaded from the test bundle rather than the framework bundle, which has no
  `MAD.momd`.
- A parent context, because every `Rptq` class sets its required `identifier` in
  `-awakeFromInsert` only when `managedObjectContext.parentContext` is set.
- Saving before formatting, because `MADSectionsLayout` fetches sections as dictionaries and a
  dictionary-result fetch is answered from the store.

Two more were about modelling the cache rather than Core Data: the group value has to be keyed
by `MADSectionGroupLayout -safeSortKey`, and each row needs a `MADIdentifierROWID`.

**This unblocks more than the test.** It is the first proof that a document's section tree can
be built, saved, fetched and formatted headlessly — which is the shape `MAD_CLI.md` §5.1 needs
from the CLI, and the same constraint the test suite had already hit from the other side.

**Found while doing it:** `MADSectionGroupLayout` segfaults on a group whose field has no query
table — it hands nil to `CFNumberGetValue` at `:43`, `:46`, `:49` and `:58`. The test host died
rather than the test failing, which is how it surfaced. Recorded in `BUGS.md` as **still open**:
wiring the fixture past it was the right call for this item, but *what the layout should do*
with a group it cannot place is a behaviour decision that has not been made.

`MAD` suite: 175 tests, 0 failures.

### 1.5 The `"<null>"` / `"<NULL>"` string hacks — **done 2026-10-01**

The user's own description: "clearly a hack on my part, and should be addressed", qualified by
"while it may not be perfect, it's also not an accident."

So these were fair game, but only with the consumers understood. The audit sorted the hits
into three kinds, and only the first was a defect.

**The sentinel round-trip was already broken.** `RptqDocumentElement -formattedString:forValue:`
guarded with `if (!value)`, which misses `NSNull` — an object, and truthy. A NULL read from a
source database arrives as `NSNull` (that representation is deliberate and stays), so it fell
through to the branches, whose text paths all end in `-initWithFormat:@"%@"`. `[NSNull
description]` is `"<null>"`; a NULL therefore printed on the report as the literal text
`<null>`. The date branches had no guard at all and printed the epoch.

The four callers that were meant to undo this compared against `MTNullIdentifier`, declared
`@"(null)"` — *parentheses*, the way a nil pointer formats, not the way `NSNull` does. The
comparison was never true. The constant was dead from the day it was written; the one string
that could have matched it is real data spelling `(null)`, which it would then have blanked.

Fixed at the source, where the other `NSNull` case in this family
(`MADQueryCacheSelectGroupKeys`) was already fixed: the guard now covers `NSNull`, the four
comparisons are gone, and so is the constant.

**Left alone, and recorded.** The SQL `NULL` keyword sites stay — they are the keyword, not
a string standing in for a value. Scrimpter's `Null` is a language-level rendering of its own
type and is out of the workspace. And `MADQueryValueFromFieldController`'s picker label
`"NULL"` is a string that does reach SQL, but it is display text the selection handler copies
into a value field, and the correct answer — `IS NULL` — needs the operator enum, the SQL
builder and the UI together. Recorded in `BUGS.md` as **still open**; it is a product decision.

`MAD` suite: 176 tests, 0 failures.

### Deliberately not in Track 1

The 12 documented quirks. Each already carries an in-code comment naming the callers that
depend on it. They are recorded correctly and changing them would break working behaviour.

---

## Track 2 — The build wiring

Gates Tracks 3 and 4. This is `LIBRARIES.md` §7, minus the pruning.

**The finding is good news.** Five of the eight library rows need only *wiring*. macOS slices
for bzip2, libarchive, openssl, libpng and freetds already exist on disk. They are unreachable
by construction: there are 10 `LIBRARY_SEARCH_PATHS[sdk=iphoneos*]` arms and 10
`[sdk=iphonesimulator*]` arms, and **zero** `[sdk=macosx*]` arms. (The 84 `sdk=macosx*` hits in
the project files are all `CODE_SIGN_IDENTITY`, `PROVISIONING_PROFILE_SPECIFIER` and
`DEVELOPMENT_TEAM` — signing boilerplate, not library paths.)

§2.1 then clarified what "wiring" has to mean. The slices are not merely unreachable through a
missing setting: the file references themselves are not SDK-conditional, so adding the
`[sdk=macosx*]` arms would not have been enough to link them. See §2.1.

### 2.1 Reconcile the Xcode references — **done 2026-10-01, but the third bullet cannot be done as written**

Two of the three bullets landed:

- **Done.** The three dangling references are deleted — `MAD`'s `libct.a` and `libsybdb.a` at
  `../opt/lib/freetds/`, and `Scrimpter`'s `MADDataStructures.framework` at
  `../MADDataStructures/build/Debug-iphoneos/`. They linked anyway, because `ld` falls back to
  `LIBRARY_SEARCH_PATHS`; MAD's two were confirmed unneeded first with `nm -u` on the built
  framework.
- **Done.** The search paths naming directories that were never created are deleted:
  `MADMySQL`'s base value (`openssl/lib/iOS`, where the real path is `openssl/iOS/lib`) and the
  MAD Viewer target's five dead entries and duplicated `$(PROJECT_DIR)`.
- **Cannot be done as written.** Adding `[sdk=macosx*]` arms and extending `SUPPORTED_PLATFORMS`
  does not work from here, for two independent reasons.

  *The setting cannot be flipped.* Every framework sits on `MADFoundation`, and
  `MADFoundation/Source/MADApplication.h:13` imports `UIKit/UIApplication.h`. A macOS probe
  fails at that import. Flipping `SUPPORTED_PLATFORMS` would claim a platform no target can
  compile for.

  *The arms could not link even so.* `LIBRARY_SEARCH_PATHS` is SDK-conditional;
  `PBXFileReference.path` is not. Every vendored `.a` reference names an iOS slice directly —
  `libarchive/iOS/lib/libarchive.a` (`arm64 arm64e`), `freetds/iOS-arm64/lib/libct.a`
  (`arm64`), `openssl/iOS/lib/libssl.a` (`arm64 arm64e`) — so a `[sdk=macosx*]` search path
  would still hand the linker an iOS file.

  What this needs is the XCFramework in §2.3, not a search path.

**Found on the way:** the MAD Viewer target has not built since `09e0e7b8d`. Its
`CODE_SIGN_ENTITLEMENTS`, `GCC_PREFIX_HEADER` and `INFOPLIST_FILE` all pointed into the
`MADStack/` directory that commit deleted. They now point at the viewer's own files under
`Targets/MADViewer/`, which carries the build as far as the link step — where it fails on seven
classes belonging to the Designer target. What the stand-alone viewer should be is a product
decision; recorded, not patched.

Both are in `BUGS.md` under *Build wiring*.

**This removes references, not libraries.** The standing constraint holds: nothing on disk is
deleted until the replacement builds every combination.

`MAD Designer` builds; `MAD` 176 tests, 0 failures; `MADMySQL` 58, 0 failures.

### 2.2 The two real builds

zlib/macOS and mysqlclient/macOS. Five rows are already built; these two are not.

### 2.3 The declarative build system

`Compressor/matrix.conf`, `Compressor/build.sh`, per-library `manifest.json`, and an XCFramework
as the single artifact Xcode links. Kept as a third entry point alongside the existing scripts
until trusted. The `manifest.json` is what makes "which flags built this?" answerable — today
that question can only be answered by disassembling the archive.

### 2.4 Prune last

Only after the matrix builds every row **and** the app builds and its tests pass against the new
artifacts. One commit per item, with the matrix diff in the message as evidence.

---

## Track 3 — Headless and the CLI

`MAD_CLI.md` phases 3–6. Phases 0–2 are done.

### 3.1 Move `MADOperationRefresh` into the `MAD` framework

`MADDesigner/Source/MADOperationRefresh.m` — 131 lines, zero UIKit symbols, importing only
`MADAPI`, `MADFoundation` and `MAD`. It is already the CLI's refresh verb; it is merely in the
wrong target. The two `Reload` operations stay behind in the app.

### 3.2 The `mad` target: `inspect`, `schema`, `query`

All three exist in `CLI/Source` today as separate verb sources. `inspect` is the verb that
proves the format document has been implemented.

### 3.3 `mad refresh`

Must call the same code the app calls — `MADOperationRefresh` →
`-executeSQL:fieldKeys:onConnection:intoResultTable:withError:` → `<MADDataTableWriting>` —
not reimplement it.

### 3.4 `mad export`

PDF first: it works today, it is simply not headless. Put it behind a `<MADReportExporting>`
protocol so `--format json` is a new class rather than a new branch. JSON and CSV are new work,
but being pure Foundation they are the formats that work on any platform.

---

## Track 4 — The format, and decoupling

Both are decisions as much as work, so they come last.

### 4.1 `.mad` v1

A fixed header outside the compression stream (`"MADFILE\0"` + version + flags) and a
checkpointed store. Backwards-compatible by design: absence of the magic means legacy v0, so
both shipping samples keep opening. It also pays for itself — the Music sample spends a third of
its bytes on WAL.

### 4.2 The framework decoupling

This is what makes the project's own synopsis true: *"Developers should be able to create
frameworks which support new database types."*

Today the core `MAD` framework imports the concrete drivers in exactly three files:

- `MAD/Source/MADDatabaseConnection+Constructor.m` — MySQL, SQL Server
- `MAD/Source/MADDatabase+Constructor.m` — MySQL, SQL Server
- `MAD/Source/MADPrintPageElementBarcode.m` — MADBarcodes

A driver registry turns "add a driver" from *edit the core* into *add a framework*. It is also
the same seam Track 3.4's export protocol needs.

### 4.3 The `MADDataTable` leaks that are left

Three from the architecture report, of which the structural one is that `MADDataTableFast`
reaches into `MADDatabaseSqlite3`'s private `_database` ivar at fifteen sites — which is exactly
why the fast table needs a real file on disk to do anything at all. The insert path is also a
cycle: table → query object → back into table.

---

## Decisions the user has to make

These block work rather than being work.

| Decision | Where | Why it blocks |
|---|---|---|
| Which system owns the database password — the app's own keychain item, or the platform AutoFill / `kSecClassInternetPassword` path? | `TASKS.md` §1 | The double prompt is the symptom. `TASKS.md` §4 is blocked behind it. |
| Is `.mad` v1 worth doing? | `MAD_FORMAT.md` §7 | It is compatible, but it is a format decision. |
| Does `mad` ship, or is it a developer tool? | `MAD_CLI.md` §8.1 | Decides signing, notarisation, an installer, and whether `--credentials` may take a plaintext argument. |
| Does the `.mad` store stay Core Data? | `MAD_FORMAT.md` §8.1 | Called a prerequisite for Windows regardless of what the CLI does. |
| What is the JSON export shape? | `MAD_CLI.md` §8.3 | Belongs in a schema, not a README. |

---

## Order

1. **Track 1** — small, understood, testable today.
2. **Track 2.1** — the reference reconciliation, because it is cheap and unblocks everything.
3. **Track 2.2–2.4**, **Track 3**, **Track 4** — in that order, since each depends on the last.
4. **Prune** — `LIBRARIES.md` §7.4, only once its gate is met.

## Standing constraints

- Nothing in `Compressor/library` is deleted until the replacement builds every combination.
- `TEST-DB-INFO.md` and `MADDesigner/run.log` stay untracked.
- `+[NSString stringWithFormat:]` is not used in this codebase, deliberately — tight loops on a
  mobile device. Match the `initWithFormat:` / `appendFormat:` house style instead.
- Behaviour-safe refactoring and cleanup are welcome without being asked for; the `MTPaper`
  paper classes are the known example. "Behaviour-safe" means provable by the suite.
- Deliberately-unused code is marked with the right clang attribute at the declaration
  (`__attribute__((unused))`, `__unused`, `NS_UNAVAILABLE`).
