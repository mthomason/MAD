# MADDataTable — Architecture & Decoupling Report

**Scope:** `MADDataTable` and every implementation, subclass, protocol, and call site across
`MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL`, and `MADTdsClient`.
**Branch:** `refactor/mad-database-decouple`
**Date:** 2026-10-01
**Verification:** `xcodebuild test` — all 11 schemes, 807 tests, 0 failures; no warnings from any
file in scope (the two `-Warc-repeated-use-of-weak` warnings in `MADDatabaseMySQL.m` are
pre-existing and untouched). (798 at Revision 2; 804 at Revision 3.)

All `file:line` references below were read first-hand during this analysis, not inferred.

> **Revision 4 — 2026-10-01.** The MySQL obstacle of Revision 3 is gone. The column metadata
> that `MysqlFetch+DataTable.m` reads mid-fetch is now declared by `<MADDataTableWriting>`
> itself, so all three drivers — including `MADDatabaseMySQL`, `MADDatabase.m` and the
> `MADDatabaseDataSource` protocol — take `id <MADDataTableWriting>` and the fetch's
> out-parameters are by-value (`&` dropped at all call sites). Phase 2 ("store `urlFastCache`;
> inject the cache directory") and Phase 4 step 12 (serialize the write pipeline) are done, and
> Phase 3 is done for the rehydration path only. §2.1 and §2.3–§2.5 and §4.2 mark each. Three tests were
> added; the suite goes 804 → 807. Because the fixes shifted `MADDataTableFast.m` by 87 lines,
> every `file:line` reference to it in this report was re-derived rather than adjusted, and the
> appendix line counts were refreshed with them.
>
> **Revision — 2026-09-30.** Sections §2.5, §3.3, §3.5 and §4.2 were rewritten after the first
> revision was found to be wrong on three points: the `-dataForRow:error:` diagnosis (a two-line
> method signature was misread — the method *is* implemented on `MADDataTableFast`), the
> `-allObjects` "live bug" (no production caller) and the `rowCounter` drift framing (unreachable).
> §4.5 is new. Corrected text is marked **Corrected** / **Fixed**; the original claims are left
> visible where they were instructive. Three code fixes landed with this revision — see §3.5.
>
> **Revision 3 — 2026-10-01.** Phase 1 step 5 has landed: `<MADDataTableWriting>`,
> `<MADDataTableReading>` and `<MADDataTableCursoring>` are declared in `MADDataTable.h` and the
> class adopts all three. Step 6 landed for two drivers of three — `MADDatabaseSQLServer` and
> `MADDatabaseSqlite3` are now write-port-typed. Step 6 **could not** land for `MADDatabaseMySQL`,
> and step 5's "delete the now-redundant stub block" was declined; §4.2 records why for each.
> The whole pass is additive: no behaviour changed, and all 11 schemes pass (804 tests).
>
> **Revision 2 — 2026-09-30.** The eight `sqlite3_mprintf` format-string sites of §4.5 are now
> fixed, and Phase 0 has landed: the unimplemented operations in `MADDataTable.m` assert instead
> of failing silently (§3.2, §4.2). The §3.1 table and the appendix line counts were re-derived
> against the changed files. Two errors in the previous revision were also corrected: the
> workspace test total was stated as 799 and is 798, and §3.6 had cited four `_database` sites
> where there are fifteen.

---

## 1. Current Architecture & Class Hierarchy

### 1.1 The class family

`MADDataTable` is **not** a single class — it is a small class cluster split across three
frameworks along a storage axis, plus a cursor axis implemented as separate enumerator objects.

```
MADFoundation
└── MADDataTable                          NSObject <NSCoding, NSFastEnumeration>
        │                                 "abstract": declares the full surface,
        │                                 implements metadata + plist persistence
        │
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (240 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1267 ln)
                sqlite3-backed. Rows live in a `.maddb` file; the object holds two
                MADDatabaseSqlite3 handles (one for writes, one for reads).

MADSqlite3 (private — NOT exported from the framework)
├── MADDataTableObjectEnumerator          173 ln — wraps a live sqlite3_stmt, yields row dicts
└── MADDataTableSingleColumnEnumerator    149 ln — same, yields a single column (row-ids)

MAD
├── MADDataTable+Constructor              the ONLY place that maps type -> concrete class
└── MADDataTableLocation                  NSCoding value object (row, column) — see §3.7
```

Verified export surface (from built `.framework/Headers`):

| Framework | Publicly exported data-table headers |
|---|---|
| `MADFoundation` | `MADDataTable.h`, `MADDataTableType.h`, `MADDataTableVirtual.h` |
| `MADSqlite3` | `MADDataTableFast.h` **only** |
| `MADMySQL` | none |
| `MADTdsClient` | none |

That split is deliberate and healthy: the enumerator class names never leak. Consumers only
ever see `NSEnumerator *`, which is what `MADDataTable.h` returns.

### 1.2 Two orthogonal axes, one enum

`MADDataTableType` (`MADFoundation/Source/MADDataTableType.h`) encodes only the **storage** axis:

```objc
typedef NS_ENUM(short, MADDataTableType) {
    MADDataTableTypeVirtual,    // -> MADDataTableVirtual
    MADDataTableTypePhysical,   // -> MADDataTableFast
};
```

The **access** axis — row-by-row vs. cursor — is orthogonal and is expressed by returning an
enumerator rather than by a type. There is no `MADDataTableTypeCursor`. This matters for the
refactor: the cursor seam already exists and is correctly hidden.

### 1.3 The single point of subclass selection

`MAD/Source/MADDataTable+Constructor.m:51-69` is the only place in the codebase that names a
concrete subclass:

```objc
+ (instancetype)newDataTableOfType:(MADDataTableType)type withObjectID:(NSUInteger)objectID {
	switch (type) {
		case MADDataTableTypeVirtual:  result = [[MADDataTableVirtual alloc] initWithId:objectID]; break;
		case MADDataTableTypePhysical: result = [[MADDataTableFast alloc] initWithId:objectID];    break;
		default: NSAssert(NO, @"Not implemented."); break;
	}
	return result;
}
```

I confirmed there is **no** `isKindOfClass:`, `NSClassFromString`, class-name string comparison,
or `respondsToSelector:` probe on a data table anywhere in the codebase. This is the single most
valuable property for the refactor — the cluster can be reshaped behind this one method.

Two caveats in the same file:

* `+newDataTableWithDefinition:` calls `NSAssert(NO, @"Not implemented.")` and returns `nil`
  when no object id is present (`:44-46`). The "default to virtual" intent in the comment at
  `:31-32` is unreachable — `objectIdSet` gates the only return path.
* `+newDataTableForIdentifier:` (`:79-92`) is the *de facto* public entry point: most call sites
  (`MTTableController.m:90`, `MADQuerySampleDataTable.m:68`, `MADQuerySampleDataTableRange.m:69`)
  go through `newDataTableWithDefinition:` directly instead, and always pin the type to Virtual.

### 1.4 The write contract

Every database driver populates a table through the **base-class** API, never through a
subclass-specific one. `MADDatabaseSqlite3.m:474-540` is the canonical loop:

```objc
[dataTable removeAllObjects];
// first row only:
[dataTable addColumn:dataColumn];       // per column, discovered from sqlite metadata
[dataTable beginBulkInsert];
// per row:
[dataTable addRowWithDataForFieldKeys:resultsForRow];
[dataTable endBulkInsert];
```

`MADDatabaseSQLServer.m:500 / :1367 / :1472` uses the identical five-call shape.
`MysqlFetch+DataTable.m:211 / :438 / :442` likewise.

This is a **narrow, well-defined write port**: five methods. It is the strongest existing
boundary in the family and should be preserved verbatim by any refactor.

Divergence between drivers:

| Driver | Table it builds | Write path |
|---|---|---|
| `MADDatabaseSqlite3` | whatever it is handed (typically `MADDataTableFast`) | `executeSQL:...intoResultTable:` |
| `MADDatabaseMySQL` | **constructs** `MADDataTableVirtual` itself (`MADDatabaseMySQL.m:83, 110, 137, 175, 196, 376`) | `MysqlFetch+DataTable.m` |
| `MADDatabaseSQLServer` | **never constructs one** — purely write-only into a caller-supplied table | `MADDatabaseSQLServer.m` |

So MySQL cannot produce a `MADDataTableFast`, and SQL Server cannot produce any table at all.
The "physical" (sqlite-backed) storage exists only for the local cache, not for remote results.

### 1.5 The read contract

Three distinct read styles are in production use:

1. **Random access** — `-objectAtRow:` / `-objectAtRow:column:`.
   `MADMySQL` uses `objectAtRow:i column:0` inside O(n) loops
   (`MADDatabaseMySQL.m:88-92, 118-122, 150-154, 187-189`) to read `SHOW TABLES` results.
   `MADQuerySampleDataTable.m:126` / `MADQuerySampleDataTableRange.m:131` call `objectAtRow:0`
   once to read a width row. `MTTableController.m:281, 284, 389` uses `objectAtRow:` for paging.

2. **Enumeration** — `-enumeratorForKeyObjectsSorted`.
   `MADocument.m:865-867` returns this as `enumeratorForReportData`, consumed by
   `MADReportFormatter.m:449-502`.

3. **Counts** — `-rowCounter` / `-count` / `-numberOfRows`.
   `MADocument.m:197` (`numberOfResults`), `MTTableController.m:249` (table size) and
   `:375, :395, :440, :445` (page-cursor arithmetic).

`MADReportFormatter` is the most forgiving consumer and the one that constrains the
refactor least. Note `MADReportFormatter.m:463-472`:

```objc
if (!calculatedRowId) {
    if ([resultRow isKindOfClass:[NSDictionary class]]) { rowIdOnly = NO; }
    calculatedRowId = YES;
}
self.machineState.detailRowId = rowIdOnly
    ? ((NSNumber *)resultRow).unsignedIntegerValue
    : ((NSNumber *)resultRow[MADIdentifierROWID]).unsignedIntegerValue;
```

The formatter **already tolerates an enumerator that yields bare row-id `NSNumber`s** as well as
full row dictionaries. `enumeratorForAllObjectsSortedRowIdOnly` exists precisely for that case.
This is a ready-made seam: a cursor that streams row ids only is already an accepted input.

---

## 2. Memory Model, Lifecycle & State

### 2.1 ARC and the one raw ivar

All files are ARC (`#if !__has_feature(objc_arc) #warning ...` guards). State lives in class
extensions. `MADDataTableFast` has exactly one non-object ivar:

```objc
@implementation MADDataTableFast {
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:103
}
```

It is finalized in `-dealloc` (`:163-165`) and in `-endBulkInsert` (`:1321-1326`). The pattern
is correct but *was* fragile: `-endBulkInsert` used to null the statement **before** taking the
barrier, so the teardown was outside the only window in which no insert is in flight.

**Fixed (Revision 4).** The teardown now runs inside the barrier, at `:1324-1325`.

### 2.2 Two sqlite connections over one file

`-reopenDbConnection` (`:385-401`) builds **two** independent `MADDatabaseSqlite3` instances
pointing at the same `.maddb` file:

```objc
// write handle
MADDatabaseConnection *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
database.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
database.databaseConnection = connection;
[(MADDatabaseSqlite3 *)database openDatabaseWithFlags:
     SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX];
self.databaseForInserts = database;

// read handle — same URL, separate connection, default flags
MADDatabaseConnection *connectionSelect = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl:urlFastCache];
MADDatabaseSqlite3 *databaseSelect = [[MADDatabaseSqlite3 alloc] init];
[databaseSelect setDatabaseConnection:connectionSelect];
[databaseSelect openDatabase];
databaseSelect.delegate = (id <MADDatabaseResultsProtocol>)cacheDelegate;
self.databaseForSelects = databaseSelect;
```

The read handle is opened with **`-openDatabase` (default flags)** and the write handle with
`SQLITE_OPEN_FULLMUTEX`. `SQLITE_OPEN_FULLMUTEX` is a **per-connection** serialization mode;
it does not arbitrate between two connections on the same file. Combined with §2.4 this is the
single largest correctness assumption in the family.

### 2.3 Storage location is resolved from ambient global state

`-urlFastCache` was a *computed* property (`:299-311` before this revision), not stored:

```objc
- (NSURL *)urlFastCache {
	NSString *filename = [[self filenameCacheMadDB] copy];
	NSURL *cacheDirectory;
	if (self.cacheDelegate == nil) {
		id <UIApplicationDelegate, MADApplicationProtocol> appDelegate = [MADApplication AppDelegate];
		id groupIdentifier = [appDelegate groupIdentifier].copy;
		cacheDirectory = [MADURLFactory newURLForLocalCacheDirectoryForGroupIdentifier:groupIdentifier];
	} else {
		cacheDirectory = [self.cacheDelegate cachedFilesDirectory].copy;
	}
	return [cacheDirectory URLByAppendingPathComponent:filename isDirectory:NO];
}
```

Consequences:

* A table with no `cacheDelegate` **silently depends on the global app delegate** for its
  on-disk identity. That is why `MADDataTableFast` could not be instantiated in a hostless logic
  test without a delegate — the regression suite works around it with a stub conforming to
  `MADCacheProtocol` + `MADDatabaseResultsProtocol`.
* `-setCacheDelegate:` (`:377-383`) calls `-reopenDbConnection`. Swapping a
  delegate **repoints the table at a different file** while keeping `tag`/`rowCounter`/
  `columnKeys` in memory. Nothing detects the mismatch.
* `-copyPlist` asserts `urlFastCache != nil` (`:243`) — so an archived table's persisted URL
  depends on the ambient state at archive time.

**Fixed (Revision 4).** `-urlFastCache` now resolves once and holds the answer
(`_urlFastCache`, at `:347-355`, written by the getter and by `-setCacheDelegate:` at `:377-383`,
which drops it before reopening). `-newUrlFastCache` (`:357-373`) keeps the resolution itself,
with a new first choice: a cache directory supplied at init. `MADDataTableFast` gained
`-initWithId:cacheDirectory:` (`:173-181`),
`+[MADDataTable newDataTableOfType:withObjectID:cacheDirectory:]` passes it through (`nil` keeps
the old behaviour), and it opens the connection immediately so the table is usable with no
delegate and no app. The delegate-swap repointing above still happens — that is the intended
reading of "the URL is derived from the delegate" — but it no longer depends on *when* the
property was first read.

`tag` (set from `initWithId:fromCache:`, `:190`) is the only stable identity; it produces both
the table name (`t<tag>`, `:403-409`) and the filename (`<tag>.maddb`, `:340-343`).

### 2.4 Thread safety: no locks, one queue

I grepped the entire family for `dispatch_sync`, `dispatch_async`, `@synchronized`, `NSLock`,
`os_unfair_lock`, and `pthread_mutex`. The **only** concurrency primitive present is
`queueBulkAdd`:

* Created three separate times — `initWithId:fromCache:` (`:186`), `initWithCoder:` (`:202`),
  and `beginBulkInsert` (`:1309`) — each `dispatch_queue_create(..., SERIAL)`.
* Used in exactly **two** places: `-endBulkInsert` (`:1321`) wraps the delegate call in
  `dispatch_barrier_sync`, and (since Revision 4) `-addRow:error:` enters it with
  `dispatch_sync`.
* Before Revision 4 it was **never** used to serialize `-addRow:error:`.

So `-addRow:` — the mutation entry point — *was* entirely unprotected by the queue. Under
`_bulkInsertLoop`, `-addRow:` reuses a single cached `_statementInsert` across calls
(`:529-611`): `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
`sqlite3_reset`, with no mutual exclusion. Two threads entering `-addRow:` concurrently race on
that shared statement regardless of `SQLITE_OPEN_FULLMUTEX`, because the race is in the
bind/step/clear/reset *sequence*, not inside any single sqlite call.

The regression suite records current concurrent behaviour but cannot make it safe — the
serialization has to be added.

**Fixed (Revision 4).** `-addRow:error:` (`:504-528`) is now a thin wrapper that runs the insert body
(`-insertRow:error:` at `:529`, the old method renamed) under `dispatch_sync(queueBulkAdd)`, falling back
to a direct call only when the queue is nil — which happens only for a table that never
finished initializing. `-endBulkInsert`'s `sqlite3_finalize(_statementInsert)` moved *inside*
its `dispatch_barrier_sync`, so the cached statement is torn down only when no insert is in
flight. On a serial queue the barrier and the `dispatch_sync` are mutually exclusive, which is
all the mutual exclusion the bind/step/clear/reset sequence needs. Two tests pin it:
`testFastTableConcurrentWritersLoseNoRows` (new) drives four writers from a *concurrent* queue;
`testFastTableSerializedConcurrentWritesLoseNoRows` keeps the app's serial-queue pattern, and its
"the table does not serialize internally" contract note was corrected. Step 13 (one connection
pair per file) is untouched.

### 2.5 `rowCounter` is an independent counter, not a derived value

`-insertRow:error:` increments `rowCounter` (`:532`) and **never consults sqlite**.
`-numberOfRows` / `-count` return it directly (`:1209` / `:1203`), and `-removeAllObjects` zeroes it
(`:683`). But `-dropTable` (`:796`), `-dropTableName:` (`:800`), `-deleteAll` (`:809`) and
`-vacuumCacheDb` (`:789`) do **not** touch it.

The two sources of truth can therefore diverge:

* `rowCounter` says N; the `.maddb` file holds a different number of rows.
* On a `-loadFromCacheWithUrl:` round trip the counter came from the plist
  (`MADDataTable.m:305-306`) while the rows come from the sqlite file — they are rehydrated by
  two unrelated mechanisms.

**Partly fixed (Revision 4).** The reload half is closed: `-loadWithPlist:` now ends with
`self.rowCounter = [self recountRows];` (`:313`), where `-recountRows` (`:317-338`) asks the
cache file for `SELECT COUNT(*)` and falls back to the plist's value only when the table does
not exist yet. A counter inflated by the in-memory path can no longer survive a reload.

What is **not** fixed: the four methods above still leave a stale counter behind for the
in-memory lifetime of the table, and `-recountRows` returns the counter unchanged when the
sqlite handle is unavailable. Those are step 11 of the plan and remain open.

`MADDataTableVirtual` has the same shape (`:179`, `:193`, `:225`) but its counter and its
`sortIndex` are mutated together, so it is consistent by construction.

This is the state most at risk under a class-cluster refactor: `MTTableController.m:375, :395,
:440, :445` treats `datatable.count` as a *page cursor* (`hasMore = (count == limit)`), so a
counter that drifts from reality would corrupt paging.

**Corrected:** the drift is real in the code, but no caller can reach it today. `-deleteAll`
(`:809`) has **no callers anywhere in the repository**, and `-dropTable` (`:796`) is reached
only from `-removeAllObjects` (`:674`), which zeroes `rowCounter` nine lines later (`:683`).
No current path leaves the counter out of step with the file, so this is a hazard for a
future caller rather than a live defect. The `-loadFromCacheWithUrl:` divergence, however,
is real: the counter is rehydrated from the plist while the rows come from sqlite. Left for
Phase 3, where the counter should be invalidated against the file rather than trusted.

**Partly fixed (Revision 4).** The rehydration half is done: `-loadWithPlist:` now ends with
`self.rowCounter = [self recountRows]`, and the new private `-recountRows` runs
`SELECT COUNT(*) FROM t<tag>` against the select connection, falling back to the stored counter
when the file cannot answer (no table yet, no handle). The counter and the rows can no longer
disagree *after a reload*. `-numberOfRows` / `-count` still return the counter directly and the
paths that never touch it (`-dropTable:`, `-deleteAll`, `-vacuumCacheDb`) are unchanged, so a
counter that drifts *while populated* is still possible; that is the remainder of step 10/11,
deliberately left because §4.3 ranks `MTTableController`'s paging the highest-risk consumer of
`count`. `testFastTableReloadRecountsRowsFromCacheFile` pins the new behaviour by loading a
plist whose counter says 99 over a file holding 3 rows.

### 2.6 Two unrelated persistence mechanisms

| Mechanism | Where | Stores |
|---|---|---|
| Plist, `NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`, `:135-191` | `name`, `columnKeys`, `columns` (metadata), `rowCounter`. **No rows.** |
| sqlite `.maddb` file | `MADDataTableFast.m` | actual row data, plus `MADDataTableFast`-specific keys (`urlFastCache`, `tag`, `bulkInsertLoop`, `sortDescriptorsSet`, `groupKeyIndexes`) |

`-cacheWithUrl:error:` in the base class is documented as generic caching but only ever
serializes *shape*, not *content*. `MADocument.m:413-414` derives `urlDataTableCache` from
`[self.dataTable newFilenameMDCache]` (`<tag>.mdcache`) while `MADDataTableFast` reads and
writes `<tag>.maddb` (`:340-343`). Two file extensions, two formats, two owners, one logical
table.

### 2.7 Enumerator lifetime

`MADDataTableObjectEnumerator` holds its own `MADDatabaseSqlite3` + connection + prepared
statement, all built in `-initWith...` (`:60-72`) and released in `-dealloc` (`:45-49`).
Therefore:

* An enumerator keeps a database handle and file descriptor alive for as long as it is retained
  — and `MADReportFormatter.m:449-502` holds one for the entire duration of a report render.
* Any table mutation that drops or rebuilds the table (`-removeAllObjects`, `-dropTable`)
  invalidates the live statement in an outstanding enumerator. Nothing guards this.
* Each `-objectEnumerator` / `-enumeratorFor...` call allocates a **fresh connection** to the
  same file (`:1126`, `:1145`, `:1173`, `:1189`). Enumerating twice opens sqlite twice.

---

## 3. Public API vs. Leaky Abstractions

### 3.1 Declared surface vs. actual implementation

`MADDataTable.h` declares 30 methods (plus the `name` / `columnKeys` / `sortDescriptors` /
`columns` / `rowCounter` / `tag` properties, two of which the writing protocol re-declares —
see §4.2). The base class implements 18 of them and stubs 12:

| Declared in `MADDataTable.h` | Base impl (`MADDataTable.m`) | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **assert** `:365` | override `:112` | override `:431` |
| `-addRow:error:` | **assert** `:369` | override `:179` | override `:504` |
| `-addRowWithDataForFieldKeys:` | **assert** `:374` | override `:197` | override `:614` |
| `-sortUsingDescriptors:` | **assert** `:378` | override `:208` | override `:634` |
| `-removeAllObjects` | **assert** `:382` | override `:225` | override `:674` |
| `-objectAtRow:column:` | **assert** `:386` | override `:159` | override `:821` |
| `-objectAtRow:` | **assert** `:391` | override `:151` | override `:835` |
| `-columnsEnumerator` | **assert** `:396` | override `:149` | override `:1110` |
| `-objectEnumerator` | **assert** `:401` | override `:148` | override `:1114` |
| `-beginBulkInsert` / `-endBulkInsert` | no-op `:408-409` | no-op `:236-238` | override `:1298`/`:1317` |
| `-allObjects` | `return @[]` `:414-417` | override `:118` | override `:1196` |
| `-objectAtRow:limit:` | `return @[]` `:419` | override `:220` | override `:1073` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:420-422` | override `:122`, `:214`, `:216` | override `:1203`, `:1207`, `:1209` |
| `-countByEnumeratingWithState:...` | `0` `:423-427` | override `:140` | inherits (0) |
| `-enumeratorForAllObjectsSorted*`, `-objectsForGroupKeys:`, `-dataForRow:error:`, `-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **also** `NSAssert(NO)` `:31-54` | implemented `:1021`, `:1135`, `:1159`, `:1180`; `-dataForRow:error:` `:928` |

### 3.2 Leak 1 — the base class cannot express "abstract"

Objective-C has no `abstract`. So the base used to return **`YES` from `-addRow:error:`** and
**`nil` from every reader**. A partially-implemented subclass, or a direct `MADDataTable`
instance, would silently accept writes and report success, then read back nothing.

**Fixed (Phase 0).** The nine write/read operations that a storage subclass must override now
open with `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)` (`MADDataTable.m:365`,
`:369`, `:374`, `:378`, `:382`, `:386`, `:391`, `:396`, `:401`), matching the `:327-350` group.
`-addRow:error:` returns `false` in Release rather than `true`, so even with assertions compiled
out it no longer claims a row was stored.

Two groups were deliberately **left** as silent defaults, because for them silence is correct:

* `-beginBulkInsert` / `-endBulkInsert` (`:408-409`) — optional hooks. A subclass that does not
  need bulk mode may legitimately inherit the no-op.
* `-allObjects` (`:414-417`), `-objectAtRow:limit:` (`:419`), `-count` / `-numberOfColumns` /
  `-numberOfRows` (`:420-422`) and `-countByEnumeratingWithState:...` (`:423-427`) — these
  return `@[]` / `0`, which is the *truthful* answer for a table with no rows, and matches what
  `MADDataTableVirtual` returns. Asserting on `-count` would turn a correct answer into a crash.

The remaining half of this leak — expressing the split in the type system rather than by
assertion — is Phase 1 (§4.2).

### 3.3 Leak 2 — a nullability contract that is already broken

`MADDataTable.h:65` declares (inside `@protocol MADDataTableCursoring`):

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m` used to answer it like this (`:1093-1096` before this revision):

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

A declared-`nonnull` method returning `nil` on one subclass and `@[]` / `[self.sortIndex copy]`
on the others. Any caller that trusted the annotation would crash — it was the only `FIXME` in
the family that contradicted a header contract.

**Corrected:** there is no production caller. The only sends to `-allObjects` on a data table
are in this regression suite, and `MADDataTableRegressionTests.m` deliberately pinned the
`nil` in `testFastTableBulkInsertAllObjectsIsUnimplemented`. So the annotation was a trap
laid for a future caller, not a live crash.

**Fixed:** `MADDataTableFast -allObjects` (`:1196-1201`) now returns every row via
`-objectAtRow:0 limit:numberOfRows`, and `@[]` for a table that has no columns, matching the
`nonnull` declaration and `MADDataTableVirtual`'s existing behaviour (`:118-120`). The test
that pinned the `nil` was replaced by two that assert the real contract.

### 3.4 Leak 3 — `-objectAtRow:column:` means different things per subclass

The two implementations disagree on both the meaning of `row` and the storage consulted:

```objc
// MADDataTableVirtual.m:159-163 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:821-833 — reads the row dictionary, physical order
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSDictionary *objForRow = [self objectAtRow:row];
	if (objForRow == nil || column >= self.columnKeys.count) return nil;
	NSString *key = self.columnKeys[column];
	MADDataColumn *columnMetaData = self.columns[key];
	if (columnMetaData == nil) return nil;
	return objForRow[columnMetaData.identifier];      // PHYSICAL (sqlite) order
}
```

Note also the bounds discipline differs: Virtual does **no** bounds check on `column`
(`self.columnKeys[column]` will throw `NSRangeException` on out-of-bounds, caught only by the
`@try` in `-objectAtRow:`, not here) and no nil check on `dataInColumn`; Fast does both.

Same selector, two sets of semantics. `MADMySQL` calls this in a tight loop
(`MADDatabaseMySQL.m:88-92` and three more sites), so a refactor that unifies semantics will
be felt by MySQL first.

### 3.5 Leak 4 — `-dataForRow:error:` is implemented on one subclass and missing on the other

**This section was wrong in the first revision of this report.** It claimed
`MADDataTableFast` does not implement `-dataForRow:error:` and that the barcode/print path
therefore hit the base class's `NSAssert(NO)`. That is false, and it sent a reader down a
false path. The corrected analysis follows.

`MADDataTable.h:67` declares
`- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
and the base implements it as `NSAssert(NO, @"Not implemented: %s")` + `return nil`
(`MADDataTable.m:342-345`).

* **`MADDataTableFast` does implement it**, at `MADDataTableFast.m:928-1002`:

  ```objc
  - (NSDictionary <NSString *, MADResult *> *)dataForRow:(NSUInteger)cacheId
                                                   error:(NSError * __autoreleasing *)outError {
  ```

  It is a two-line signature, which is what the earlier revision misread: the selector wraps
  onto a second line, and the second line was taken for a separate `-dataForRow:column:`
  overload. (The real `-dataForRow:column:error:` is a different method at `:853-919`.) The
  implementation is real, and the regression suite already covers it --
  `MADDataTableRegressionTests.m` `testFastTableDataForRowReturnsValues` and
  `testFastTableDataForRowCachesLastRow` both send the two-argument selector to a live
  `MADDataTableFast` and pass.

* **`MADDataTableVirtual` implements neither form.** It has a `-dataForRow:` stub at
  `:41-44`, but that stub is `NSAssert(NO, @"Not implemented: %s")` + `return nil` — it is
  not a working overload, and it is not declared in `MADDataTableVirtual.h`. The
  two-argument form falls through to the asserting base. So the in-memory subclass has no
  row-by-id access at all.

The call sites are therefore not at risk: `MADocument.m:875/880/919` dispatch to
`MADocument.dataTable`, which is both statically and actually a `MADDataTableFast`
(`MADocument.m:159`, allocated at `:230` and `:288`). The `MADPrintPageElement.m:80` and
`MADPrintPageElementBarcode.m:30` paths reach the same object. Nothing on a live path
asserts.

The real defect is narrower and is now fixed: because `MADDataTableVirtual` never
implemented the selector, any future caller holding an `MADDataTable *` that happens to be
a Virtual table would have asserted in Debug and silently received `nil` in Release.
`MADDataTableVirtual` now implements `-dataForRow:error:` by delegating to `-objectAtRow:`
and reporting the out-of-range case through the error pointer.

The `MADDataTableFast` implementation also had a genuine defect, now fixed: its
`if (sqlite3_prepare == SQLITE_OK)` had **no `else`**, so a prepare failure returned `nil`
without setting `*outError`, and the `-getSql:` error was discarded. Its sibling
`-dataForRow:column:error:` (`:892-919`) handles both correctly. The SQL was also passed to
`sqlite3_mprintf` as the *format* string (`sqlite3_mprintf((char *) sql.UTF8String)`), which
mangles or crashes on SQL containing `%`; it is now `sqlite3_mprintf("%s", ...)`, matching
the sibling at `:888`. Eight further sites in `MADSqlite3` had the same defect; all are now
fixed — see §4.5.

### 3.6 Leak 5 — `MADDataTableFast` reaches into another class's private ivar

`MADDataTableFast.m` accesses `MADDatabaseSqlite3`'s private ivar `_database` directly at
fifteen sites — `:488`, `:538`, `:784`, `:793`, `:806`, `:817` (through `_databaseForInserts`)
and `:892`, `:963`, `:1052`, `:1065`, `:1093`, `:1095`, `:1235`, `:1238`, `:1248` (through
`databaseForSelects`):

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :1008
```

This bypasses `MADDatabaseSqlite3`'s API entirely and is the reason `MADDataTableFast` needs a
real sqlite file to do anything at all. It is also why the test target needed the
`MADDataTable+Constructor` module import work: the class family is only usable from code that
links both frameworks together.

### 3.7 Leak 6 — dead public API

`MADDataTableLocation` (`MAD/Source/MADDataTableLocation.{h,m}`, 67 lines) is a
`(row, column)` value object with `NSCoding` and a `+newDataTableLocationForRow:inColumn:`
factory. I grepped the whole codebase excluding its own implementation: **its only references
are in the regression test file.** It is production-dead. It also adopts `NSCoding` but not
`NSSecureCoding`, which the regression suite records as a contract.

### 3.8 Leak 7 — the table reaches *back* into the write query

`MADDataTableFast` conforms privately to four protocols
(`:71`):

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

and implements `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`
(`:419-430`) purely so `MADQueryCacheAddRow` can pull state back out of the table it is writing
into. The insert path is therefore a cycle: table → query object → back into table. Note the
name collision risk — `-queryRowData` (`:428`) and the private `_rowDataLastInserted` property
are unrelated to the public `-dataForRow:` family.

### 3.9 What is *not* leaky (preserve these)

* All subclass selection is in `MADDataTable+Constructor.m:51-69`.
* The write port is five base-class methods (§1.4).
* Enumerator classes are private to `MADSqlite3` and only ever surface as `NSEnumerator *`.
* `MADReportFormatter.m:463-472` already tolerates row-id-only enumeration.
* `MADArrayCaching` (`MADSqlite3`) is prior art in this codebase for a caching abstraction with
  a narrower, protocol-shaped surface.
* No runtime class sniffing on tables anywhere.

---

## 4. Decoupling & Refactoring Strategy

The goal is to make `MADDataTable` a *stable interface* over swappable storage and access
strategies, without changing the behaviour the five drivers and four consumers already depend on.

### 4.1 Target shape

Keep the class names (they are baked into `NSCoding` archives and Core Data) but move the
variation behind two protocols the constructors return:

```
                    ┌─────────────────────────────────────┐
                    │  MADDataTable        (concrete base) │
                    │  metadata, plist persistence,        │
                    │  NSCoding, — no-op defaults removed   │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┴───────────────────────────┐
        │                                                       │
  MADDataTableVirtual                                   MADDataTableFast
  (unchanged semantics)                          (sqlite; owns a connection pair)

  Both conform to:
     <MADDataTableWriting>   removeAllObjects / addColumn: /
                             begin|endBulkInsert /
                             addRowWithDataForFieldKeys:
     <MADDataTableReading>   objectAtRow: / objectAtRow:column: /
                             count / numberOfRows
     <MADDataTableCursoring> enumeratorForKeyObjectsSorted /
                             enumeratorForAllObjectsSorted /
                             enumeratorForAllObjectsSortedRowIdOnly
```

`MADDatabaseSqlite3.m:474-540` and `MADDatabaseSQLServer.m:500-1472` should take
`id <MADDataTableWriting>` instead of `MADDataTable *`. That alone removes the "base class
returns YES from a write I discarded" hazard from every driver.

### 4.2 Sequenced plan

**Phase 0 — make the failure modes loud (no behaviour change).**
1. **Done**, with a narrower scope than first proposed. The nine operations a storage
   subclass must override now assert (`MADDataTable.m:365-403`); the honest empty-table
   answers and the optional bulk hooks were left as defaults, because for those the silent
   value is the *correct* one. See §3.2 for the split and the reasoning, and
   `MADDataTableRegressionTests.m` `testBaseTableAbstractOperationsAssert` for the contract.
2. **Not needed — see §3.5.** The original text here said to implement
   `MADDataTableFast -dataForRow:error:` because it "currently asserts". It does not; the
   method is implemented at `:928-1002`, and the earlier reading mistook a two-line signature
   for a `column:` overload. The subclass that was genuinely missing the selector is
   `MADDataTableVirtual`, and it now implements it by delegating to `-objectAtRow:`.
3. **Done.** `-allObjects` (§3.3) was a `nonnull` method returning `nil` on
   `MADDataTableFast`; it now returns the rows. In the same pass
   `MADDataTableFast -dataForRow:error:` gained the missing `else` on its prepare check, and
   no longer discards the `-getSql:` error or passes SQL to `sqlite3_mprintf` as the format
   string.
4. Re-verify against the existing regression suite (`MADDataTableRegressionTests.m`, 65 tests)
   — it already pins instantiation, enumeration, concurrency, and the `MADDataTableLocation`
   contract, so it will detect a mistake here.

**Phase 1 — declare the protocols.**

5. **Done — the stub block was deliberately kept.** The three protocols are declared in
   `MADFoundation/Source/MADDataTable.h` above the `@interface`, which now reads
   `MADDataTable : NSObject <NSCoding, NSFastEnumeration, MADDataTableWriting,
   MADDataTableReading, MADDataTableCursoring>`, and the thirty flat method declarations that
   used to sit in the `@interface` body are gone from it. The split is by axis: **Writing**
   is the mutable surface (`removeAllObjects`, `addColumn:`, `addRow:error:`,
   `addRowWithDataForFieldKeys:`, `sortUsingDescriptors:`, plus `@optional`
   `beginBulkInsert`/`endBulkInsert`); **Reading** is random access and the counts;
   **Cursoring** is enumeration, with the three sorted enumerators and
   `objectsForGroupKeys:` `@optional` because `MADDataTableVirtual` genuinely cannot serve
   them.

   The plan's "delete the now-redundant stub block" was **not** carried out, because both
   stub blocks are pinned contracts, not redundancy:
   `testBaseTableAbstractOperationsAssert` requires the nine base-class asserting stubs to
   exist and throw, and `testVirtualTableDoesNotImplementSortedEnumerators` asserts
   `-respondsToSelector:` is **YES** for the four sqlite-only selectors on
   `MADDataTableVirtual`. Deleting either would have turned a caught defect into an
   unrecognised-selector crash and broken a test that exists specifically to prevent that.
   `MADDataTable` satisfies the protocols' `@required` members by asserting, which is what
   Phase 0 put there.

6. **Done (Revision 4) — all three drivers and the protocol.** The block below is Revision 3's
   account of why this was blocked; it is kept for the record. The unblock it identified was
   taken: the column metadata `MysqlFetch+DataTable.m` needs (`columns`, `columnKeys`) is now
   declared by `<MADDataTableWriting>` itself, so the write port is sufficient for MySQL too.
   `MysqlFetch`'s two `fetchWithCommand:dataTable:...` methods and its private
   `-fetchResultsFromConnection:intoDataTable:...` take `id <MADDataTableWriting>` by value and
   return the same table (`(MADDataTable *)dataTable`); all 11 call sites in
   `MADDatabaseMySQL.m` and the 7 in `MADMySQLLiveTests.m` dropped their `&`. The metadata was
   put on the write protocol rather than a fourth one because MySQL reads it *while writing* —
   it corrects a column's type on the first row — and because every conformer gets it free from
   the base class. §2.5's `// FIXME: This is a hack.` is untouched.

   *Revision 3 text, for the record:* **partly done — two drivers of three, and the protocol
   declaration deliberately not narrowed.** `MADDatabaseSqlite3`
   (`executeSQL:...intoResultTable:`,
   `executeQuery:withDataTable:andError:`, `executeQuery:withError:`) and
   `MADDatabaseSQLServer` (the same two, plus the private `-runQuery:onProcess:withDataTable:`
   and `-runSQL:onDataTable:fieldKeys:process:`) now take `id <MADDataTableWriting>`. Both are
   genuinely write-only: `grep` for what they send the table returns exactly the five-call port
   and nothing else.

   **`MADDatabaseMySQL` cannot be narrowed yet**, and neither can
   `MADAPI/Source/MADDatabaseProtocol.h:28-31`. The obstacle is not in the driver — it is in
   `MysqlFetch+DataTable.m`, which reads `(*dataTable).columns` and `.columnKeys` *while*
   filling the table, to correct a column's type once it sees the first row
   (`:301` and `:321`, under the existing `// FIXME: This is a hack.` at `:297`). A write port that
   does not expose the column metadata is therefore not sufficient for that path. Since
   `MADDatabaseMySQL` conforms to `MADDatabaseDataSource` and must keep doing so, narrowing
   the protocol would have made it promise something its own implementation cannot honour —
   a remote crash for the next caller, not a compile error. Both declarations carry a comment
   pointing here.

   **The concrete unblock, found while checking this:** `MysqlFetch+DataTable.m` never
   assigns through its `MADDataTable * __autoreleasing *` out-parameters —
   `grep -n '\*dataTable *=' MADMySQL/Source/MysqlFetch+DataTable.m` returns nothing. The
   pointer is an in-parameter the callers were never told about. Making it by-value
   (`dataTable:(id <MADDataTableWriting>)dataTable`) removes the pointer-type problem
   outright and lets the 11 call sites in `MADDatabaseMySQL.m` drop their `&`. That, plus
   adding the column-metadata accessors to `<MADDataTableWriting>` or a fourth protocol,
   is the whole of what remains for MySQL. It is deferred rather than bundled in because
   §4.3 already ranks MySQL the highest-risk consumer, and the change is mechanical enough
   to be reviewed on its own.

7. **Now possible for sqlite, unproven for MySQL.** `MADDatabaseSqlite3`'s row loop can be
   driven by any object conforming to `<MADDataTableWriting>` with no `.maddb` file and no
   app delegate, since the parameter no longer implies the `MADDataTable` class — and,
   through it, the `-urlFastCache` dependency on `[MADApplication AppDelegate]` described in
   §2.3. No such mock test has been written yet; it is the natural next step and the first
   thing Phase 2's injected cache directory makes cheaper.
   **Revision 4:** the hostless half is proven — `testFastTableInitWithCacheDirectoryNeedsNoDelegate`
   builds a working physical table with a directory and no delegate. The mock-table half (driving
   the sqlite row loop with a plain `<MADDataTableWriting>` conformer) is still unwritten.

**Phase 2 — remove the storage-location ambiguity. DONE (Revision 4).**
8. ✅ Make `urlFastCache` stored, not computed (§2.3). Resolved once into `_urlFastCache`; a
   delegate swap drops it in `-setCacheDelegate:` before reopening, so the resolution is always
   against the current delegate.
9. ✅ Inject the cache directory rather than reaching for `[MADApplication AppDelegate]` inside
   the property. `-initWithId:cacheDirectory:` and
   `+newDataTableOfType:withObjectID:cacheDirectory:` carry it; `nil` keeps the old chain.
   `testFastTableInitWithCacheDirectoryNeedsNoDelegate` builds, fills and reads a physical table
   with no delegate at all.

**Phase 3 — make `rowCounter` derived.**
10. ◐ Add a private `-recountRows` backed by `SELECT COUNT(*)`, and make `-numberOfRows`/`-count`
    use it (or invalidate against it) on `MADDataTableFast`. Keep the `rowCounter` property for
    archive compatibility, but stop treating it as the source of truth (§2.5).
    **Revision 4:** `-recountRows` exists and runs at the end of `-loadWithPlist:`, so a reloaded
    table can no longer carry a counter that disagrees with its file. `-numberOfRows`/`-count`
    still return the ivar, and drift while populated is still possible — see §2.5.
11. ⬜ Audit `MTTableController.m:375/395/440/445` — paging must not read a counter that can drift
    from the file.

**Phase 4 — fix concurrency.**
12. ✅ Serialize `-addRow:error:` on `queueBulkAdd` (§2.4). The queue already exists and is already
    used for `-endBulkInsert`; extending it to the mutation path is a small, contained change.
    Move the `sqlite3_finalize(_statementInsert)` in `-endBulkInsert` *inside* the
    barrier so the cached statement is only torn down when no `-addRow:` is in flight.
    **Done (Revision 4)** — the teardown is now the first thing inside the
    `dispatch_barrier_sync` at `:1321`.
13. Consider one shared connection pair per file rather than per table instance, since
    `-objectEnumerator` currently opens a new connection on every call (§2.7).

**Phase 5 — retire the dead surface.**
14. Delete `MADDataTableLocation` (§3.7) and its three tests, or wire it into an actual feature.
    It is currently public API with no production caller.
15. Reconcile the two persistence mechanisms (§2.6) — either the base plist really is metadata-only
    (then rename it and document it as such) or row data should round-trip through it.

### 4.3 Breakage ranking for the current consumers

| Consumer | Site | Risk under refactor |
|---|---|---|
| `MTTableController` | `:249, :281, :284, :375, :389, :395, :440, :445` | **High** — treats `count` as a page cursor; any change to `rowCounter` semantics breaks paging |
| `MADDatabaseMySQL` | `:88-92, :118-122, :150-154, :187-189` | **High** — O(n) `objectAtRow:i column:0`; per-subclass `row` semantics must be unified first |
| `MADocument` | `:197` (`rowCounter`), `:865-867` (enumerator), `:874-919` (`dataForRow:error:`), `:1053-1072` | **High** — but only for the enumerator and `rowCounter`. Its `-dataForRow:error:` sends resolve to `MADDataTableFast`, which implements the selector, so the print/barcode path is sound (see §3.5) |
| `MysqlFetch+DataTable` | `:301, :321` | **Medium** — mutates `column.type` mid-fetch behind `// FIXME: This is a hack.` (`:297`); the column dictionary must stay publicly mutable |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **Low** — single `objectAtRow:0` width probe |
| `MADReportFormatter` | `:449-502` | **Low** — tolerant of both row-id and dictionary enumeration |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **Low** — write-only through the five-method port |

### 4.4 Constraints to respect

* **Do not change `MADDataTableType`'s raw values.** `MADDataTableParametersType` is encoded
  into definition dictionaries (`MTTableController.m:91`, `MTTableViewControllerBarcodeExtraMaxicode.m:104`)
  and the enum is serialized via `initWithShort:`.
* **Do not rename the classes.** `MADDataTableFast` archives carry
  `[MADDataTableFast keyTag]`-style keys (`:114-119`) and `MADDataTableVirtual` carries
  `keySortIndex` (`:202`) into existing `.mdcache`/`.maddb` files.
* **Keep the five-method write port.** All three drivers depend on the exact sequence
  `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`.
* **No class-name sniffing was introduced.** Preserve that: any new branch should be on a
  protocol or an enum, never on a class.

### 4.5 SQL passed to `sqlite3_mprintf` as a format string

Found while fixing §3.5. Eight other call sites handed a variable to `sqlite3_mprintf` as the
*format* string rather than as an argument. Any `%` in the SQL would then be read as a
conversion, so a query containing one is mangled — or reads past the argument list and crashes.

**Fixed.** All eight now pass a literal `"%s"` and the SQL as the argument, matching the sites
that were already correct:

| File | Sites |
|---|---|
| `MADSqlite3/Source/MADDataTableFast.m` | `:1049`, `:1089`, `:1232` |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | `:301`, `:397`, `:875` |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | `:69` |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | `:64` |

The already-correct reference sites were `MADDataTableFast.m:548`, `:888` and `:960`, and
`MADDatabaseSqlite3.m:459`. Every `sqlite3_mprintf` call in `MADSqlite3` now either uses a
literal `"%s"` or a literal format string containing no conversions — `grep -n
sqlite3_mprintf MADSqlite3/Source/*.m` returns fourteen calls and no variable format strings.

Reachability was low: the SQL comes from the generated query builders, and a repo-wide search
found no `LIKE` pattern that would introduce a `%`. Identifiers, however, come from the
connected database's schema, so a `%` in a column or table name would have hit this. It was a
latent correctness bug rather than a live one — fixed because the change is mechanical and the
consequence of being wrong is silent corruption.

---

## Appendix — Files examined

| File | Lines |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 123 / 435 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 240 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`, `MADDataProtocol.h`, `MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 47 / 1355 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | 1346 |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 30 / 94 |
| `MAD/Source/MADDataTableLocation.h` / `.m` | 24 / 67 |
| `MAD/Source/MADocument.m`, `MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`, `MysqlFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`, `MADQuery.h`, `MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 69 tests |
