# MADDataTable — Architecture & Decoupling Report

**Scope:** `MADDataTable` and every implementation, subclass, protocol, and call site across
`MADFoundation`, `MAD`, `MADSqlite3`, `MADMySQL`, and `MADTdsClient`.
**Branch:** `refactor/mad-database-decouple`
**Date:** 2026-09-30
**Verification:** `xcodebuild test` — 63 tests, 0 failures; no warnings from any file in scope.

All `file:line` references below were read first-hand during this analysis, not inferred.

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
        ├── MADDataTableVirtual            MADFoundation/Source/MADDataTableVirtual.m (224 ln)
        │       In-memory. Rows live in per-column MADDataColumn arrays plus a
        │       `sortIndex` NSMutableArray of row NSDictionaries.
        │
        └── MADDataTableFast               MADSqlite3/Source/MADDataTableFast.m (1249 ln)
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
* `+newDataTableForIdentifier:` (`:70-86`) is the *de facto* public entry point: most call sites
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
	sqlite3_stmt *_statementInsert;   // MADDataTableFast.m:89
}
```

It is finalized in `-dealloc` (`:152-157`) and in `-endBulkInsert` (`:1213-1214`). The pattern
is correct but fragile: `-endBulkInsert` nulls the statement **before** taking the barrier
(`:1213` runs outside `dispatch_barrier_sync` at `:1219`), so it is not covered by that barrier.

### 2.2 Two sqlite connections over one file

`-reopenDbConnection` (`:323-339`) builds **two** independent `MADDatabaseSqlite3` instances
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

`-urlFastCache` is a *computed* property (`:299-311`), not stored:

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
  on-disk identity. That is why `MADDataTableFast` cannot be instantiated in a hostless logic
  test without a delegate — the regression suite works around it with a stub conforming to
  `MADCacheProtocol` + `MADDatabaseResultsProtocol`.
* `-setCacheDelegate:` (`:318-321`) unconditionally calls `-reopenDbConnection`. Swapping a
  delegate **repoints the table at a different file** while keeping `tag`/`rowCounter`/
  `columnKeys` in memory. Nothing detects the mismatch.
* `-copyPlist` asserts `urlFastCache != nil` (`:223`) — so an archived table's persisted URL
  depends on the ambient state at archive time.

`tag` (set from `initWithId:`, `:170`) is the only stable identity; it produces both the table
name (`t<tag>`, `:341-347`) and the filename (`<tag>.maddb`, `:294-297`).

### 2.4 Thread safety: no locks, one unused queue

I grepped the entire family for `dispatch_sync`, `dispatch_async`, `@synchronized`, `NSLock`,
`os_unfair_lock`, and `pthread_mutex`. The **only** concurrency primitive present is
`queueBulkAdd`:

* Created three separate times — `initWithId:fromCache:` (`:166`), `initWithCoder:` (`:182`),
  and `beginBulkInsert` (`:1203-1206`) — each `dispatch_queue_create(..., SERIAL)`.
* Used in exactly **one** place: `-endBulkInsert` (`:1219`) wraps the delegate call in
  `dispatch_barrier_sync`.
* It is **never** used to serialize `-addRow:error:`.

So `-addRow:` — the mutation entry point — is entirely unprotected by the queue. Under
`_bulkInsertLoop`, `-addRow:` reuses a single cached `_statementInsert` across calls
(`:458-514`): `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
`sqlite3_reset`, with no mutual exclusion. Two threads entering `-addRow:` concurrently race on
that shared statement regardless of `SQLITE_OPEN_FULLMUTEX`, because the race is in the
bind/step/clear/reset *sequence*, not inside any single sqlite call.

The regression suite records current concurrent behaviour but cannot make it safe — the
serialization has to be added.

### 2.5 `rowCounter` is an independent counter, not a derived value

`-addRow:error:` increments `rowCounter` (`:445`) and **never consults sqlite**.
`-numberOfRows` / `-count` return it directly (`:1098-1104`), and `-removeAllObjects` zeroes it
(`:596`). But `-dropTable` (`:709`), `-dropTableName:` (`:713`), `-deleteAll` (`:722`) and
`-vacuumCacheDb` (`:702`) do **not** touch it.

The two sources of truth can therefore diverge:

* `rowCounter` says N; the `.maddb` file holds a different number of rows.
* On a `-loadFromCacheWithUrl:` round trip the counter comes from the plist
  (`MADDataTable.m:305-306`) while the rows come from the sqlite file — they are rehydrated by
  two unrelated mechanisms.

`MADDataTableVirtual` has the same shape (`:177`, `:189`, `:217`) but its counter and its
`sortIndex` are mutated together, so it is consistent by construction.

This is the state most at risk under a class-cluster refactor: `MTTableController.m:375, :395,
:440, :445` treats `datatable.count` as a *page cursor* (`hasMore = (count == limit)`), so a
counter that drifts from reality silently corrupts paging.

### 2.6 Two unrelated persistence mechanisms

| Mechanism | Where | Stores |
|---|---|---|
| Plist, `NSPropertyListBinaryFormat_v1_0` | `MADDataTable.m:193-220`, `:135-191` | `name`, `columnKeys`, `columns` (metadata), `rowCounter`. **No rows.** |
| sqlite `.maddb` file | `MADDataTableFast.m` | actual row data, plus `MADDataTableFast`-specific keys (`urlFastCache`, `tag`, `bulkInsertLoop`, `sortDescriptorsSet`, `groupKeyIndexes`) |

`-cacheWithUrl:error:` in the base class is documented as generic caching but only ever
serializes *shape*, not *content*. `MADocument.m:413-414` derives `urlDataTableCache` from
`[self.dataTable newFilenameMDCache]` (`<tag>.mdcache`) while `MADDataTableFast` reads and
writes `<tag>.maddb` (`:294-297`). Two file extensions, two formats, two owners, one logical
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
  same file (`:1023`, `:1042`, `:1070`, `:1086`). Enumerating twice opens sqlite twice.

---

## 3. Public API vs. Leaky Abstractions

### 3.1 Declared surface vs. actual implementation

`MADDataTable.h` declares 30 methods. The base class implements 18 of them and stubs 12:

| Declared in `MADDataTable.h` | Base impl (`MADDataTable.m`) | Virtual | Fast |
|---|---|---|---|
| `-addColumn:` | **no-op** `:358` | override `:110` | override `:369` |
| `-addRow:error:` | **`return true`** `:359` | override `:163` | override `:442` |
| `-addRowWithDataForFieldKeys:` | **no-op** `:360` | override `:181` | override `:527` |
| `-sortUsingDescriptors:` | **no-op** `:361` | override `:192` | override `:547` |
| `-removeAllObjects` | **no-op** `:362` | override `:209` | override `:587` |
| `-objectAtRow:column:` | `return nil` `:363` | override `:157` | override `:734` |
| `-objectAtRow:` | `return nil` `:364` | override `:149` | override `:748` |
| `-columnsEnumerator` | `return nil` `:365` | override `:147` | override `:1007` |
| `-objectEnumerator` | `return nil` `:366` | override `:146` | override `:1011` |
| `-beginBulkInsert` / `-endBulkInsert` | **no-op** `:367-368` | no-op `:220-222` | override `:1193`/`:1212` |
| `-allObjects` | `return @[]` `:370-373` | override `:116` | **`return nil`** `:1093` |
| `-objectAtRow:limit:` | `return @[]` `:375` | override `:204` | override `:970` |
| `-count` / `-numberOfColumns` / `-numberOfRows` | `0` `:376-378` | override `:198-200` | override `:1098-1104` |
| `-countByEnumeratingWithState:...` | `0` `:379-383` | override `:138` | inherits (0) |
| `-enumeratorForAllObjectsSorted*`, `-objectsForGroupKeys:`, `-dataForRow:error:`, `-enumeratorForKeyObjectsSorted` | `NSAssert(NO, @"Not implemented")` `:327-350` | **also** `NSAssert(NO)` `:29-52` | partially `:1032-1091` |

### 3.2 Leak 1 — the base class cannot express "abstract"

Objective-C has no `abstract`. So the base returns **`YES` from `-addRow:error:`** and **`nil`
from every reader**. A partially-implemented subclass, or a direct `MADDataTable` instance, will
silently accept writes and report success, then read back nothing. Every one of these should
assert (as the `NSAssert(NO)` group at `:327-350` correctly does) or be `@optional` in a protocol.

### 3.3 Leak 2 — a nullability contract that is already broken

`MADDataTable.h:80` declares:

```objc
- (nonnull NSArray *)allObjects;
```

`MADDataTableFast.m:1093-1096`:

```objc
- (NSArray *)allObjects {
	// FIXME: Implement this.
	return nil;
}
```

A declared-`nonnull` method returning `nil` on one subclass and `@[]` / `[self.sortIndex copy]`
on the others. Any caller that trusts the annotation will crash. This is a live bug, not a
theoretical one — it is the only `FIXME` in the family that violates a header contract.

### 3.4 Leak 3 — `-objectAtRow:column:` means different things per subclass

The two implementations disagree on both the meaning of `row` and the storage consulted:

```objc
// MADDataTableVirtual.m:157-161 — reads the per-column store, applies the sort index
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column {
	NSString *fieldKey = self.columnKeys[column];
	MADDataColumn *dataInColumn = self.columns[fieldKey];
	return [dataInColumn objectAtIndex:[self sortedIndexForIndex:row]];   // LOGICAL row
}
```

```objc
// MADDataTableFast.m:734-746 — reads the row dictionary, physical order
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

### 3.5 Leak 4 — `-dataForRow:error:` is declared, unimplemented, and already called

This is the sharpest concrete finding in this analysis.

* `MADDataTable.h:75` declares `- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError **)error;`
* The base implements it as `NSAssert(NO, @"Not implemented: %s")` + `return nil` (`:342-345`).
* `MADDataTableVirtual` does **not** override that selector. It declares a *different* selector,
  `-dataForRow:` (`:39-42`, no `error:`), which is an overload, not an override — so the asserting
  base implementation is still what runs for the 2-arg form.
* `MADDataTableFast` overrides `-dataForRow:column:error:` (`:766`) and `-dataForRow:column:`
  (`:841`) — but **not** `-dataForRow:error:`. Its header declares only
  `-dataForRow:column:error:` (`MADDataTableFast.h:33`).

And yet it is called on a `MADDataTableFast`:

```objc
// MAD/Source/MADocument.m:159  ->  self.dataTable is a MADDataTableFast
// MADocument.m:874-876
- (NSDictionary *)dataForRow:(NSUInteger)rowID {
	return [self.dataTable dataForRow:rowID error:nil];     // -> base NSAssert(NO) -> crash
}
// MADocument.m:878-881, :919 also call the 2-arg form
```

Reachability: the main report path is safe — `MADReportFormatter` never calls
`-dataForRow:` (verified: zero hits in `MADReportFormatter.m`). The live path is the
barcode/print-element path, `MADocument.m:1053-1072`:

```objc
- (NSDictionary *)dataForRowReportFirst { ... return [self dataForRow:firstRowID] : nil; }
- (NSDictionary *)dataForRowReportLast  { ... return [self dataForRow:lastRowID]  : nil; }
- (NSDictionary *)dataForRowPageFirst:(NSUInteger)pageIndex { ... }
- (NSDictionary *)dataForRowPageLast:(NSUInteger)pageIndex  { ... }
```

reached from `MADPrintPageElement.m:80` and `MADPrintPageElementBarcode.m:30`. So: a barcode
element bound to a sub-report will hit `NSAssert(NO)` in Debug and silently return `nil` in
Release. A leaky base contract producing an already-live latent crash.

### 3.6 Leak 5 — `MADDataTableFast` reaches into another class's private ivar

`MADDataTableFast.m` accesses `MADDatabaseSqlite3`'s private ivar `_database` directly at
`:451`, `:730`, `:962`, and `:990`:

```objc
sqlite3 *sqlite_database = _databaseForInserts->_database;                       // :451
NSAssert(prepareResult == SQLITE_OK, @"%s", sqlite3_errmsg(databaseForSelects->_database)); // :992
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
(`:67-68`):

```objc
@interface MADDataTableFast () <MADQueryParametersStandardProtocol,
                                MADQueryParametersColumnKeysProtocol,
                                MADQueryParametersColumnMetaProtocol,
                                MADQueryParametersColumnDataProtocol>
```

and implements `-queryTableName` / `-queryColumnKeys` / `-queryColumns` / `-queryRowData`
(`:360-367`) purely so `MADQueryCacheAddRow` can pull state back out of the table it is writing
into. The insert path is therefore a cycle: table → query object → back into table. Note the
name collision risk — `-queryRowData` (`:366`) and the private `_rowDataLastInserted` property
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
1. Replace the silent stubs in `MADDataTable.m:358-368` and `:370-383` with
   `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)`, matching the existing
   `:327-350` style. This converts silent data loss into a caught defect.
2. Implement `MADDataTableFast -dataForRow:error:` (§3.5) — the selector is declared, called
   from `MADocument.m:875/880/919`, and currently asserts. It should delegate to the existing
   `-dataForRow:column:` machinery.
3. Fix `-allObjects` (§3.3) or drop it from the header. A `nonnull` method returning `nil` is
   the most likely source of an unexplained crash.
4. Re-verify against the existing regression suite (`MADDataTableRegressionTests.m`, 62 tests)
   — it already pins instantiation, enumeration, concurrency, and the `MADDataTableLocation`
   contract, so it will detect a mistake here.

**Phase 1 — declare the protocols.**
5. Extract `<MADDataTableWriting>`, `<MADDataTableReading>`, `<MADDataTableCursoring>` from the
   header. Mark the genuinely-optional ones `@optional` and delete the now-redundant stub block.
6. Retarget the driver signatures:
   `MADDatabaseSqlite3.m:427/450/578`, `MADDatabaseSQLServer.m:319/346/350`,
   `MADDatabaseMySQL.m:275/303`, `MysqlFetch+DataTable.h:16-22`, and the
   `MADDatabaseProtocol` declarations (`MADAPI/Source/MADDatabaseProtocol.h:28-31`).
7. This step is what makes the family testable without an app: a mock conforming to
   `<MADDataTableWriting>` can drive `MADDatabaseSqlite3`'s row loop with no file on disk.

**Phase 2 — remove the storage-location ambiguity.**
8. Make `urlFastCache` stored, not computed (§2.3). Resolve it once in the initializer (or in
   `-setCacheDelegate:` with an explicit `-reopenDbConnection` call), so a delegate swap can no
   longer repoint a live table at a different file.
9. Inject the cache directory rather than reaching for
   `[MADApplication AppDelegate]` inside the property. Pass it through
   `+newDataTableOfType:withObjectID:` — this is also what lets `MADDataTableFast` be
   constructed in a hostless logic test.

**Phase 3 — make `rowCounter` derived.**
10. Add a private `-recountRows` backed by `SELECT COUNT(*)`, and make `-numberOfRows`/`-count`
    use it (or invalidate against it) on `MADDataTableFast`. Keep the `rowCounter` property for
    archive compatibility, but stop treating it as the source of truth (§2.5).
11. Audit `MTTableController.m:375/395/440/445` — paging must not read a counter that can drift
    from the file.

**Phase 4 — fix concurrency.**
12. Serialize `-addRow:error:` on `queueBulkAdd` (§2.4). The queue already exists and is already
    used for `-endBulkInsert`; extending it to the mutation path is a small, contained change.
    Move the `sqlite3_finalize(_statementInsert)` in `-endBulkInsert` (`:1213`) *inside* the
    barrier so the cached statement is only torn down when no `-addRow:` is in flight.
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
| `MADocument` | `:197` (`rowCounter`), `:865-867` (enumerator), `:874-919` (`dataForRow:error:`), `:1053-1072` | **High** — hits the unimplemented base selector today |
| `MysqlFetch+DataTable` | `:271-272, :291-292` | **Medium** — mutates `column.type` mid-fetch behind `// FIXME: This is a hack.`; the column dictionary must stay publicly mutable |
| `MADQuerySampleDataTable(Range)` | `:118, :126` / `:123, :131` | **Low** — single `objectAtRow:0` width probe |
| `MADReportFormatter` | `:449-502` | **Low** — tolerant of both row-id and dictionary enumeration |
| `MADDatabaseSQLServer` | `:500, :1367, :1472` | **Low** — write-only through the five-method port |

### 4.4 Constraints to respect

* **Do not change `MADDataTableType`'s raw values.** `MADDataTableParametersType` is encoded
  into definition dictionaries (`MTTableController.m:91`, `MTTableViewControllerBarcodeExtraMaxicode.m:104`)
  and the enum is serialized via `initWithShort:`.
* **Do not rename the classes.** `MADDataTableFast` archives carry
  `[MADDataTableFast keyTag]`-style keys (`:104-109`) and `MADDataTableVirtual` carries
  `keySortIndex` (`:202`) into existing `.mdcache`/`.maddb` files.
* **Keep the five-method write port.** All three drivers depend on the exact sequence
  `removeAllObjects → addColumn: → beginBulkInsert → addRowWithDataForFieldKeys: → endBulkInsert`.
* **No class-name sniffing was introduced.** Preserve that: any new branch should be on a
  protocol or an enum, never on a class.

---

## Appendix — Files examined

| File | Lines |
|---|---|
| `MADFoundation/Source/MADDataTable.h` / `.m` | 94 / 391 |
| `MADFoundation/Source/MADDataTableVirtual.h` / `.m` | 21 / 224 |
| `MADFoundation/Source/MADDataTableType.h` | 17 |
| `MADFoundation/Source/MADDataColumn.h`, `MADDataProtocol.h`, `MADCacheProtocol.h` | — |
| `MADSqlite3/Source/MADDataTableFast.h` / `.m` | 41 / 1249 |
| `MADSqlite3/Source/MADDataTableObjectEnumerator.m` | 173 |
| `MADSqlite3/Source/MADDataTableSingleColumnEnumerator.m` | 149 |
| `MADSqlite3/Source/MADQueryCacheAddRow.m` | 152 |
| `MADSqlite3/Source/MADDatabaseSqlite3.m` | — |
| `MAD/Source/MADDataTable+Constructor.h` / `.m` | 23 / 86 |
| `MAD/Source/MADDataTableLocation.h` / `.m` | 24 / 67 |
| `MAD/Source/MADocument.m`, `MADReportFormatter.m` | — |
| `MADMySQL/Source/MADDatabaseMySQL.m`, `MysqlFetch+DataTable.{h,m}` | — |
| `MADTdsClient/Source/MADDatabaseSQLServer.m` | — |
| `MADAPI/Source/MADDatabaseProtocol.h`, `MADQuery.h`, `MADDatabaseResultsProtocol.h` | — |
| `MADDesigner/Source/MTTableController.m` | — |
| `MAD/MADTests/MADDataTableRegressionTests.m` | 62 tests |
