# ROADMAP.md

The plan for the next stretch of work on _MAD Designer_, and the order to take it in.

This file is a **plan**, not a queue you act on. `BUGS.md` is the defect register, `TASKS.md`
is the engineering queue, `TODO.md` is the product wishlist. This one says which of those, and
which of the three design documents written on 2026-10-01, get picked up next and why in that
order. Work starts here when the user asks for a track by name or number.

Written 2026-10-01 against `master` at `073bb2e24`; reordered the same day against `master` at
`c6e5cab0f`, once the user settled what the core task is.

---

## The core task

**Define the `.mad` document.** What it is today, what it should be, what travels with it,
and how a reader on another platform opens it. Every other track in this file is either a step
toward that or an instrument for seeing it.

The user's words:

> *"The core task is to define this `.mad` document; we also need to define the files related
> to it... all the caches that are built... we need to understand what it is, and then define
> what it will be, and then make it portable. Rebuilding static libraries at this point doesn't
> get it closer to it."*

Two consequences reorder the whole plan:

- **The macOS library builds are not on the path.** Deferred 2026-10-01; Track 2 records why
  the deferral costs nothing.
- **The `mad` CLI is the instrument, not the product.** It does not ship. It exists so the
  document can be read, exercised and tested with the app out of the way — which makes Track 3
  a means and Track 4 the end.

---

## Where the project stands

Recorded so the plan can be read cold.

**The repository is clean and backed up.** `master` is at `c6e5cab0f`, pushed. Track 1's fixes
and Track 2.1's reconciliation have both landed on it, and the two merged working branches have
been deleted.

**The tree builds and the suite is broad.** `MAD Designer` builds. 885 test methods across 11
suites, with `MADMySQL` and `MADTdsClient` carrying live suites that skip when no server is
reachable. Both a MySQL and a SQL Server instance are available for live work, and the `mad`
CLI can drive a report without the UI.

**The format is already measured.** `MAD_FORMAT.md` describes the container, the store and the
hazards from the two shipping samples, and states the normative target. What it treats thinly
is the companion files — Track 4.1.

**The registers are in much better shape than their headline counts suggest.** `BUGS.md` holds
76 entries; 56 are fully fixed. Of the 20 that are not, **12 are documented deliberate
non-defects** — load-bearing shapes recorded so nobody "fixes" them. That leaves roughly four
genuinely open defects, all listed in Track 1.

---

## Track 1 — Close the real bug backlog — **done 2026-10-01**

Kept here because the evidence is worth being able to read without going to git. The full
record, with tests, is in `BUGS.md`.

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

## Track 2 — The build wiring — **deferred 2026-10-01**

**§2.2 and §2.3 are deferred — the user's decision, 2026-10-01.** The macOS builds are not
wanted yet ("we will build for MacOS later"), and the declarative build system is agreed to
be important but not now ("we will also put off the declarative build system, though I
believe it's important. This info should be stored in a plist or something"). Both are
recorded in `TASKS.md` §6, so the deferral is a tracked intent rather than a dropped thread.

**The user's reason, and it is the right one:** rebuilding static libraries does not move the
core task forward. Nothing in Tracks 3, 4 or 5 needs a macOS slice.

**This track does not gate anything.** The claim in the original heading — "gates Tracks 3 and
4" — was written before `CLI/build.sh` had been read. Track 3 builds and runs entirely on iOS
Simulator artifacts. If anything the dependency runs the other way: Track 5.1's decoupling is
what a native macOS binary is actually waiting on.

This is `LIBRARIES.md` §7, minus the pruning.

**The finding is good news.** Five of the eight library rows need only *wiring*. macOS slices
for bzip2, libarchive, openssl, libpng and freetds already exist on disk. They are unreachable
by construction: there are 10 `LIBRARY_SEARCH_PATHS[sdk=iphoneos*]` arms and 10
`[sdk=iphonesimulator*]` arms, and **zero** `[sdk=macosx*]` arms. (The 84 `sdk=macosx*` hits in
the project files are all `CODE_SIGN_IDENTITY`, `PROVISIONING_PROFILE_SPECIFIER` and
`DEVELOPMENT_TEAM` — signing boilerplate, not library paths.)

§2.1 then clarified what "wiring" has to mean. The slices are not merely unreachable through a
missing setting: the file references themselves are not SDK-conditional, so adding the
`[sdk=macosx*]` arms would not have been enough to link them. See §2.1.

**There is a second `Compressor` on the desktop.** `/Users/michael/Desktop/Compressor` is a
standalone git repository last touched June 2025; the tree in this workspace is the newer of
the two (it carries `gettext`, `libffi` and `sqlite3` build outputs the desktop copy lacks, and
`build_sqlite3.sh` as of 2026-10-01). Which archive actually went into the last shipped build
is not answerable from here and does not need to be — but it is why the desktop copy should not
be deleted without asking.

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

### 2.2 The two real builds — **deferred 2026-10-01**

zlib/macOS and mysqlclient/macOS. Five rows are already built; these two are not.

Deferred by the user's call, and nothing is waiting on them: the CLI runs on the iOS
Simulator (Track 3), and a native macOS binary is blocked by Track 5.1's UIKit decoupling
rather than by a missing archive.

### 2.3 The declarative build system — **deferred 2026-10-01**

`Compressor/matrix.conf`, `Compressor/build.sh`, per-library `manifest.json`, and an XCFramework
as the single artifact Xcode links. Kept as a third entry point alongside the existing scripts
until trusted. The `manifest.json` is what makes "which flags built this?" answerable — today
that question can only be answered by disassembling the archive.

Deferred by the user's call. Worth keeping from that exchange: the user's instinct was that
"this info should be stored in a plist or something" — which is precisely what the
`manifest.json` is, so the design as written already answers the concern that prompted it.
When this resumes, the per-library manifest should be built **first**: it is what makes every
other piece of the matrix checkable rather than merely runnable.

The XCFramework is still the answer to §2.1's third bullet. That finding does not expire with
the deferral — `PBXFileReference.path` names an iOS slice directly, so no search path can fix
it whenever the macOS work is picked back up.

### 2.4 Prune last

Only after the matrix builds every row **and** the app builds and its tests pass against the new
artifacts. One commit per item, with the matrix diff in the message as evidence.

---

## Track 3 — The headless CLI (the instrument)

**The CLI does not ship.** The user's decision, 2026-10-01:

> *"the CLI isn't going to be shipped (least not now, it's only for our understanding of how
> the software works, and testing)."*

That settles `MAD_CLI.md` §8.1 — it is a developer tool — and with it several questions that
were only hard because shipping was assumed: no signing, no notarisation, no installer, and
`--credentials user:pass` may take a plaintext argument.

**Why it comes first anyway.** It is the only way to see the document with the app out of the
way. `mad inspect` already reads the container and the store as raw SQLite — no Core Data, no
UI — which is precisely the reader `MAD_FORMAT.md` §7 asks a second platform to be able to
write. So the CLI is not a detour from the core task; it is how the core task gets checked.

**Track 2 does not gate this track.** `CLI/build.sh` builds `mad` for the **iOS Simulator** and
runs it on the Mac through `xcrun simctl spawn`, linking the existing frameworks and the existing
iOS static libraries unchanged. The macOS slices are only needed for a *native* macOS binary,
and what blocks that is Track 5.1.

**The track is smaller than it reads.** `CLI/Source` is 1011 lines and the entire unimplemented
surface is two entries, both greppable as `"not implemented yet"`:

- `schema` — the whole of `MADCLIUnimplemented.m` (15 lines).
- `refresh --rows N` — rejected at `MADCLIRefresh.m:17`.

`inspect` (115 lines), `query` (36), `refresh` (54) and `export` (66) are real implementations
that open a document and do the work. So §3.2 below is as much a description of what exists as
a specification of what to build.

### 3.1 Phase 1 — prove the path — **done 2026-10-01**

**All four runs pass, on both samples, first time, with no code changed.** The headless path had
never been exercised end to end before; it works.

| # | Run | London | Music |
|---|---|---|---|
| 1 | `mad inspect` | 6 members, 41 sections, 25 elements | 6 members, 29 sections, 10 elements |
| 2 | `mad query` | 6-table join, `WHERE "Customer0"."City" = 'London'` | 4-table join |
| 3 | `mad refresh` | **76 rows, 0.02 s** | **3503 rows, 0.10 s** |
| 4 | `mad export --out` | 5 pages, 43 KB | 77 pages, 354 KB |

The London PDF was checked for content, not just for existing: it carries the real chinook
data — *"Sales Report"*, customer Phil Hughes, invoice #335, R.E.M.'s *The Wrong Child* at
$0.99. The text predicate is what makes this meaningful: run 2 emits
`WHERE "Customer0"."City" = 'London'`, and run 3 is the first proof that a headless refresh
executes it correctly. Both halves of the literal-quoting fix (`0c187aca3`) are confirmed live.

**One false alarm, worth knowing about.** `file` reports Music's export as 8 pages where `mad`
says 77. `mad` is right — the PDF has 77 `/Type /Page` objects and a root `/Count 77`; `file`
takes one node's `/Count` out of 13 nested page-tree nodes. Do not use `file` to check page
counts on these.

Four runs against the two shipping samples. Each was an acceptance test; nothing broke. The
runs as written, for the record:

| # | Run | What it proves |
|---|---|---|
| 1 | `mad inspect` on London and Music | the container and the store read without Core Data |
| 2 | `mad query` on both | the query model loads headlessly |
| 3 | `mad refresh` on **London first**, then Music | the data path, end to end |
| 4 | `mad export --out` | a PDF produced from a headless run |

London goes first in run 3 because its driver is **Sqlite 3** over a local `chinook.sqlite3`:
no server sits in the path, so a failure is the code's rather than the network's. Music is the
control.

Precondition: `xcrun simctl spawn booted` wants a booted simulator. `CLI/build/mad` is already
built.

**Do not do §3.4 first.** Moving `MADOperationRefresh` into `MAD` is housekeeping with a working
workaround — `CLI/build.sh`'s `REFRESH_SOURCES` reaches across the target boundary and compiles
it today. Reorganising before the runs have said what shape the code wants is the wrong order.

### 3.2 Phase 2 — close the surface — **done 2026-10-01**

`mad schema`, and `refresh --rows N`. Both landed and both are verified against the samples.

**`schema`** was the only stub verb (`MADCLIUnimplemented.m` held nothing else, and that file is
now deleted). It reads the snapshot stored at creation time out of the store's own `Rptq`
entities — `RptqDocument` → `RptqDatabase` → `RptqDatabaseSchemaTable` → `RptqDatabaseSchemaField`
— and prints the driver, the tables sorted by name, and each table's fields with their display
type and a `pk` marker. It needs no credentials and no database, because it is not a live read.

```
London.mad
  schema 1   Sqlite 3
  tables     11
    Album (3 fields)
      AlbumId  Integer  pk
      Title  String
      ArtistId  Integer
    …
```

**`--rows N`** caps the query rather than the fetch: it sets `MADQueryFull.limitResults` before
the refresh runs, so the SQL carries a real `LIMIT N` instead of pulling every row and discarding
the surplus. `refresh --rows 7` returns 7 rows; no flag returns the full 76 (London) / 3503
(Music). The cap is the SQL limit, so the cached `.maddb` afterwards holds N rows — a refresh
replaces the cache, it does not preview alongside it.

### 3.3 Phase 3 — make the CLI the document's spec — **done 2026-10-01**

`mad inspect` now reports the companion files, grouped by extension, with a per-kind description
and a per-file listing under `--verbose`:

```
  cache       7308922102201200 (6 files, 402.7 KB)
    madac 4 files  320.0 KB  rendered-page cache
    maddb 1 file   80.0 KB   row data
    mdcache 1 file   2.7 KB   virtual-table index
```

The directory is located with the app's own rule — `MADURLFactory
newURLCacheFilesDirectoryForFilename:` — rather than re-derived, so the CLI cannot drift from the
app's idea of where the cache lives. A subdirectory is skipped (a manual backup is not part of
the footprint), and an un-refreshed document reports `cache none`.

This is the first time the companion files have been *reported* rather than measured by hand, and
it immediately makes Track 4.1 concrete: Music's cache is 15.0 MB and every byte of it is
`.madac`; London's is 402.7 KB and 79% `.madac`. The two render-cache layout identifiers
(`1138777405839048766` and Music's own `14013296909766`) are now visible side by side instead of
inferred from a directory listing.

The success criterion for this track — **`mad inspect` can state everything `MAD_FORMAT.md`
claims, from a file, without the app** — is met for the container, the store, the members, the
WAL/SHM and the companion files. The one claim `inspect` does not yet state is the store's
*schema*, which is `schema`'s job, not `inspect`'s; the two together cover the document.

### 3.4 Move `MADOperationRefresh` into the `MAD` framework — **coupled to §5.1**

`MADDesigner/Source/MADOperationRefresh.m` — 131 lines, zero UIKit symbols, importing only
`MADAPI`, `MADFoundation` and `MAD`. It is already the CLI's refresh verb; it is merely in the
wrong target. The two `Reload` operations stay behind in the app.

The workaround is visible in `CLI/build.sh`: its `REFRESH_SOURCES` list reaches across the
target boundary and compiles `MADOperationRefresh.m` and the two `MADOperationRefreshInitial*`
files straight out of `MADDesigner/Source`. So the CLI works today.

**Why it is not plain housekeeping.** The refresh *chain* has to reach the concrete drivers:
`MADOperationRefreshInitialize` imports `MADDatabase+Constructor`, and that file (and its
sibling `MADDatabaseConnection+Constructor`) import all three drivers —
`<MADSqlite3/MADDatabaseSqlite3.h>`, `<MADMySQL/MADDatabaseMySQL.h>`,
`<MADTdsClient/MADDatabaseSQLServer.h>`. That is why refresh was kept in the app target, which
links everything. It is also why this is half-resolved already: the `Constructor` files live in
`MAD`, and `MAD.framework` already links `MADSqlite3`, `MADMySQL` and `MADTdsClient`, so the
mechanical move would compile. But it would re-assert the cycle the drivers already form with
`MAD` — they subclass `MADDatabase` (they depend on `MAD`), while `MAD`'s `Constructor` imports
them. Moving the refresh operations on top of that pile makes the seam §5.1 wants *harder* to
cut, not easier.

So do **not** move the files until §5.1's driver registry exists; then the move and the registry
are one change, and refresh constructs a driver through the registry instead of through a
`Constructor` that hard-imports them.

---

## Track 4 — The `.mad` document (the core task)

`MAD_FORMAT.md` is the definition: what the format is today, measured from the two shipping
samples; its hazards; and the normative target. This track is the work that document implies.

### 4.1 The companion files are only half described

`MAD_FORMAT.md` §5 records two companion kinds — `.maddb` (the rows) and `.mdcache` (the
virtual-table plist). A real cache directory holds **three**, and the undocumented one
dominates:

| Kind | Written by | One real directory |
|---|---|---|
| `<hash>.maddb` | `MADDataTableFast` | 816 KB |
| `<hash>.mdcache` | `MADDataTable` | 1.7 KB |
| `<hash>{ih,lh}{612, 792}.madac` | `MADArrayCaching`, fed by `MADReportFormatter.m:179,:183` | **~15 MB** |

`.madac` is the formatter's rendered-page cache, keyed by layout identifier and page size
(`{612, 792}` is US Letter in points). Against a document under 80 KB, the render cache is
around 200× the document.

§5 also never describes the cache **directory** as a unit: its `dataTableIdHash` naming, its
lifecycle, or why 0-byte `.maddb` files sit in directories that were created and never
populated. That is the part that matters — nothing currently says what may be deleted, what
must be invalidated when a document changes, or what a second platform has to reproduce.

### 4.2 The three decisions, which block v1

`MAD_FORMAT.md` §8. These are the user's calls, and the first is a genuine prerequisite for
portability:

- **Does the store stay Core Data?** It is the last Apple dependency in the format (hazard H3),
  and the definition it holds is a modest object graph.
- Should the thumbnail be in the document, or is it regenerable like everything else?
- Should `.mad` optionally carry the row cache, making a document openable offline elsewhere?

Plus one raised by 4.1: **is the render cache invalidated when the document changes?** Nothing
in `MAD_FORMAT.md` says so, and a stale page cache would be invisible.

### 4.3 `.mad` v1

A fixed header outside the compression stream (`"MADFILE\0"` + version + flags) and a
checkpointed store, per `MAD_FORMAT.md` §7. Backwards-compatible by design: absence of the
magic means legacy v0, so both shipping samples keep opening. It also pays for itself — the
Music sample spends a third of its bytes on WAL.

**Not to be started before 4.1 and 4.2.** The header is the easy part; the decisions are what
make it correct.

---

## Track 5 — The three seams

The project's synopsis names three things a developer should be able to extend without editing
the core: **database types**, **document element types**, and **export formats**. Today none of
the three has a seam, and this file had a plan for none of them.

### 5.1 Database types

Today the core `MAD` framework imports the concrete drivers in exactly three files:

- `MAD/Source/MADDatabaseConnection+Constructor.m` — MySQL, SQL Server
- `MAD/Source/MADDatabase+Constructor.m` — MySQL, SQL Server
- `MAD/Source/MADPrintPageElementBarcode.m` — MADBarcodes

A driver registry turns "add a driver" from *edit the core* into *add a framework*. It is also
what a native macOS build is waiting on: three of those imports lead to UIKit, which is why no
target compiles for macOS today.

### 5.2 Export formats

`mad export` has one arm: PDF, behind a string comparison in `MADCLIExport.m`. `MAD_CLI.md` §5.3
asks for a `<MADReportExporting>` protocol so `--format json` is a *new class* rather than a new
branch — the same shape as 5.1's driver registry, which is why the two belong in one track.

The user's framing, 2026-10-01:

> *"You can also create a new export format if you want... put that in the task... export to
> text or email or markdown or any of a hundred things. That's part of the app that is supposed
> to be expandable."*

**When this is picked up, build a text exporter first.** Not because text is wanted, but because
it is the cheapest proof the seam is real: pure Foundation, no Core Graphics, and it makes the
report's *content* visible in the CLI without a PDF viewer — which Track 3.1 wants anyway. If
the seam is right, text is an afternoon; if it is not, text is where that shows.

**But not before Track 3.1.** An exporter that renders nothing because refresh is broken proves
nothing about the seam.

### 5.3 Document element types

The third seam, and the one this file says nothing about. `RptqDocumentElement` and its
subclasses are the extension point — the synopsis names static labels, data labels, aggregates
and barcode labels as the family — but nothing describes how a third party adds one. Worth a
design pass before it is worth code.

---

## Decisions the user has to make

These block work rather than being work.

| Decision | Where | Why it blocks |
|---|---|---|
| Which system owns the database password — the app's own keychain item, or the platform AutoFill / `kSecClassInternetPassword` path? | `TASKS.md` §1 | The double prompt is the symptom. `TASKS.md` §4 is blocked behind it. |
| Does the `.mad` store stay Core Data? | `MAD_FORMAT.md` §8.1 | Called a prerequisite for Windows regardless of what the CLI does. Track 4.2. |
| Is the render cache invalidated when the document changes? | Track 4.1 | A stale page cache would be invisible. |
| Should the thumbnail and row cache live in the document? | `MAD_FORMAT.md` §8.2–8.3 | Decides whether every member of a `.mad` is authoritative. |
| Is `.mad` v1 worth doing? | `MAD_FORMAT.md` §7 | It is compatible, but it is a format decision. |
| What is the JSON export shape? | `MAD_CLI.md` §8.3 | Belongs in a schema, not a README. |

Struck: *"Does `mad` ship, or is it a developer tool?"* — settled 2026-10-01; it is a developer
tool, for now.

---

## Order

1. **Track 3.1** — the four runs. Next, and nothing should precede it.
2. **Track 3.2–3.3** — close the surface, then make `inspect` describe the whole document.
3. **Track 4** — the companion files, the decisions, then v1. This is the core task; it starts
   in earnest once the CLI can show the document.
4. **Track 5.2** — the export seam, text first, because it is cheap and it makes the report
   visible.
5. **Track 5.1** — the driver registry, which is also the macOS prerequisite.
6. **Track 5.3** — document element types; needs a design pass first.
7. **Track 2.2–2.4** — deferred; resume only when a native macOS build is wanted, and build the
   `manifest.json` first.
8. **Prune** — `LIBRARIES.md` §7.4, only once its gate is met.

## Standing constraints

- Nothing in `Compressor/library` is deleted until the replacement builds every combination.
- The second `Compressor` at `/Users/michael/Desktop/Compressor` is a separate repository; do not
  delete or reconcile it without asking.
- `TEST-DB-INFO.md` and `MADDesigner/run.log` stay untracked.
- `+[NSString stringWithFormat:]` is avoided in this codebase, deliberately — tight loops on a
  mobile device. Match the `initWithFormat:` / `appendFormat:` house style instead. (The
  constraint is about hot paths, and the codebase is not literally free of the call: it appears
  in one-shot paths, including the CLI. New code in a loop should not add one.)
- Behaviour-safe refactoring and cleanup are welcome without being asked for; the `MTPaper`
  paper classes are the known example. "Behaviour-safe" means provable by the suite.
- Deliberately-unused code is marked with the right clang attribute at the declaration
  (`__attribute__((unused))`, `__unused`, `NS_UNAVAILABLE`).
