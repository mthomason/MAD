# Phase C — App Integration: the mechanism

This is the design for turning the `Rptq` classes from `NSManagedObject` subclasses into
plain objects backed by the portable store, and for replacing the app's
`NSManagedObjectContext` / `NSFetchRequest` / `NSEntityDescription` usage with the store.
It is the mechanism the rest of Phase C executes; the schema-family slice is the first
proof of it.

§8 is the migration map the swap was executed from; **§9 is the review of milestones (a)–(c)
and the outstanding list**, written 2026-10-03. Read §9 before starting further work.

## 1. The two new types

Everything hangs off two store-side types, both Core Data-free:

- **`RptqObject`** — the plain base class the `Rptq` entities inherit from. It wraps a
  `MADStoreObject` (the raw row: entity, identifier, values, references, collections) and
  a weak back-pointer to the context that owns it.
- **`RptqStoreContext`** — the store-backed replacement for the `NSManagedObjectContext`
  role. It owns an open `MADStore`, holds the loaded `MADStoreGraph` (with inverses
  completed), and is the single place objects are created, faulted, saved and deleted.

`MADStoreObject` already *is* the row. `RptqObject` adds nothing but a context and typed,
faulting access; `RptqStoreContext` adds the object-graph semantics the store deliberately
does not have (identity, inverse maintenance, dirty tracking).

## 2. Property backing

The `Rptq` headers keep their property declarations. The `.m` files stop declaring
`@dynamic` over Core Data and instead inherit generic access from `RptqObject`, which
overrides the two KVC fall-through hooks:

- `valueForUndefinedKey:` — looks the key up in `MADStoreSchema`. An **attribute** reads
  `backingObject.values[name]`; a **to-one relationship** resolves `references[name]`
  through the context into a faulted `RptqObject`; a **to-many** resolves
  `collections[name]` in order into an `NSArray` of faulted `RptqObject`s.
- `setValue:forUndefinedKey:` — the mirror image, and the place inverse maintenance
  happens (see §4).

Because `MADStoreSchema` already carries every property's name, type and relationship
descriptor, there is **no per-entity accessor code** to write: the schema is the single
source of truth for routing, exactly as it is for the store's reader/writer. The typed
`@dynamic` accessors the headers still promise are satisfied by `resolveInstanceMethod:`
on the base (a generic getter/setter that dispatches to these two hooks), so `element.
textStyle.bold = bold` keeps compiling and running unchanged.

## 3. Fetch, insert, save

The app's three Core Data verbs map one-to-one:

| Today | Store-backed |
|---|---|
| `+[RptqX fetchRequest]` + `executeFetchRequest:` (projection dictionaries) | `-[RptqStoreContext objectsForEntity:]` + attribute reads on the faulted objects |
| `NSEntityDescription insertNewObjectForEntityForName:` | `-[RptqStoreContext insertObjectForEntity:identifier:]` |
| `[context save:]` | `-[RptqStoreContext save:]` → `-[MADStore writeGraph:replacingAll:]` |
| `[context objectWithID:]` / fetch-by-id | `-[RptqStoreContext objectForEntity:identifier:]` |
| `RptqDataHelper nextIdentifierForClass:` | max identifier over the loaded graph + 1 |

Loading is per part (`-[RptqStoreContext loadPart:]` → `graphForPart:`), not per
relationship and not the whole graph, per §8 of the migration plan.

The `MADModel*` layer keeps its public API and its `_uid`-based object model; only its
`NSFetchRequest`/`NSExpressionDescription` projection fetches are rewritten as plain
attribute reads (they already only want `{identifier, name, queryable}`-shaped tuples).
`MADModel*` currently holds a `__weak NSManagedObjectContext`; that ivar's type changes to
`RptqStoreContext` and nothing else in the layer's contract moves.

## 4. Relationships and faulting

A to-one edge is an identifier in `references`; a to-many is an ordered identifier list in
`collections`. `RptqObject` resolves an edge lazily — `objectForEntity:identifier:` — so
a "fault" is just a store-backed object with an unloaded row, and loading a part fills the
whole part's rows at once (the store reads a table, not a row).

Setting an edge maintains its inverse, mirroring what Core Data does automatically and
what `graphByCompletingInverses` does at the graph level:

- set `db.ownedByUser = credential` → also sets `credential.inDatabase = db`, so the
  import flow's `credential.inDatabase.databaseDriverTypeEnum = …` keeps working.
- append to `document.hasDatabaseSchemas` → also sets each database's
  `ownedByQueryAsStaticResource`.

The context does this against the graph's `MADStoreObject`s, so it holds even before a
save, and it is idempotent with the store's own inverse completion.

## 5. Undo

Undo is high-level and already shape-agnostic: `registerUndoWithTarget:handler:` on an
`NSUndoManager`, whose handlers call fetch-by-id + set-a-property
(`[RptqDocumentElement newDocumentElementWithIdentifier:fromObjectContext:]` then
`element.textStyle.bold = bold`). Fetch-by-id is `objectForEntity:identifier:` and
set-a-property is `setValue:forUndefinedKey:` — nothing Core Data-specific is left.

## 6. `NSFetchedResultsController`

Two files use it (`MADQueryBuilderAddTableViewController`, `MTGraph+RptqQuery`). The store
has no live query, so both become load-then-reload-on-change: fetch the rows, hold them in
an array, and reload the view when the document signals a change (the `MADModel*` layer
already posts `MADNotificationQueryTableInsert`/`…Delete` for this).

## 7. Sequencing (how the phase lands without a broken build)

The `Rptq` hierarchy all switches superclass in one mechanical step (33 `.m` files: drop
Core Data, drop the factory's `initWithEntity:insertIntoManagedObjectContext:` in favour of
`insertObjectForEntity:`). The app's *usage* migrates family by family, schema first, then
query, then sections/elements — each family re-pointing the `MADModel*` reads and the
operation inserts at the store. A family that is not yet migrated keeps compiling only
because the superclass swap is done once, up front; there is no half-converted object graph
with Core Data relationships reaching into plain objects.

This checkpoint delivers the two types, the routing, and the schema family proven against
the store, before any of the app's query or sections/elements code moves.

---

## 8. Remaining: the swap and the consumer migration (slice 2)

The mechanism above is landed and green (213 tests). The next slice is the superclass swap
plus the consumer migration, and it is the whole of the remaining Phase C work. This is the
map, recorded so the slice resumes cold.

### 8.1 The swap (mechanical, scripted)

Thirty-three autogen entities. Twenty-four declare `: NSManagedObject`; the nine
`RptqDocumentElement*` subclasses declare `: RptqDocumentElement` and inherit the change.

- In each `autogen/*.h`: replace the two `#import <CoreData/NSManagedObject.h>` /
  `#import <CoreData/NSFetchRequest.h>` lines with `#import "RptqObject.h"`; change
  `: NSManagedObject` to `: RptqObject`; drop every `+ (NSFetchRequest…) fetchRequest…`
  declaration.
- In each `autogen/*.m`: drop the `+fetchRequest` body (keep the `@dynamic` list). Two
  files carry hand-added Core Data methods to strip instead: `RptqQuery.m`
  (`fetchRequestTableCount:objectContext:`, called from
  `MADDesigner/Source/MADQueryViewDataSource.m:125`) and the header declaration in
  `RptqQuery.h`.
- `@dynamic` stays; `+resolveInstanceMethod:` on `RptqObject` serves the accessors (see §2).

### 8.2 The consumer surface (~65 files)

- **Extras** (`MAD/Source/rptq/*+Extras.{h,m}`): factory methods
  (`new…FactoryForManagedObjectContext:`), `awakeFromInsert` (identifier autoincrement —
  now `insertObjectForEntity:identifier:0`), `NSFetchRequest` projection helpers (delete —
  their callers read the store directly), and `objectWithID:` / `[obj managedObjectContext]`
  sites. All take `NSManagedObjectContext *` → `RptqStoreContext *`.
- **`RptqDataHelper`**: `nextIdentifierForClass:managedObjectContext:` is superseded by
  `insertObjectForEntity:identifier:0`; keep the class or fold it away.
- **`MADModel*`** (`MADModelDatabase/Table/Field/Document/Query/QueryTable/QueryLink`): the
  `__weak NSManagedObjectContext *` ivar becomes `RptqStoreContext *`; every
  `NSFetchRequest` + `NSExpressionDescription` projection becomes an `objectsForEntity:` +
  attribute read (e.g. `MADModelDatabase.updateTables` already wants only
  `{identifier, name, queryable}`).
- **`MADocument`**: open = unarchive + load the portable store through `RptqStoreContext`
  (run `MADStoreConverter` first when the store is still Core Data); save = write the store
  instead of `[super writeContents:]`. `activeDocumentModel` reads the root from the context.
- **Operations** (`MADOperationCreateDocument*`): the private `NSManagedObjectContext` with a
  `parentContext` becomes a `RptqStoreContext` over the store; `storeDatabaseConnectionDefination:`
  and `storeTablesAndFieldsForTables:` (in `RptqDocument+Extras.m`) are the schema write path.
- **MAD query/report sources** (`MADQueryFull`, `MADQuerySelectExpression*`,
  `MADReportFormatter`, `MADSectionLayout`, `MADSectionsLayout`, `MADReportSection`,
  `MADQueryActiveQueryFields`, …): fetch/insert sites.
- **MADDesigner** (~22 files, `MADQuery*` controllers, designer element views, barcodes,
  `MTGraph+RptqQuery`): the two `NSFetchedResultsController` uses
  (`MADQueryBuilderAddTableViewController`, `MTGraph+RptqQuery`) become load + reload.
- **Tests**: `MADCoreDataModelTests` (model-loading) largely survives; `MADRptqDatabaseTests`,
  `MADRptqDocumentSectionTests`, `MADRptqQueryTests`, `MADRptqValueTypeTests` build objects
  through Core Data and must switch to `RptqStoreContext` + `insertObjectForEntity:`.

### 8.3 The write/read vocabulary (already built)

`insertObjectForEntity:identifier:` (mints when 0), `objectForEntity:identifier:`,
`objectsForEntity:`, `loadPart:`/`loadAllWithError:`, `save:`, `deleteObject:error:`,
`setRelationship:value:onObject:` + `addObject:toRelationshipNamed:onObject:` /
`removeObject:fromRelationshipNamed:onObject:` (inverse-maintaining), and `@dynamic`
dot-syntax via `+resolveInstanceMethod:`.

---

## 9. Review findings, 2026-10-03

Milestones (a), (b) and (c) landed and were reviewed against their committed diffs. What was
verified good is in §9.4; what follows is outstanding, in the order it should be worked.

### 9.1 `objectsForEntity:` misses subentity rows

Element rows are keyed in the graph by their **concrete kind** (`RptqDocumentElementLabel`),
which is what the converter writes (`MADStoreConverter.m:232`, from `object.entity.name`). The
**singular** lookup has an explicit table fallback for exactly this reason
(`MADStoreGraph.m:45-59`, documented in `MADStoreGraph.h`). The **plural** lookup does not —
`MADStoreGraph.m:71` returns `self.objects[entity]` by exact name, and
`RptqStoreContext.m:102` iterates it. So `objectsForEntity:@"RptqDocumentElement"` returns only
rows whose kind is exactly the base entity, which is none of them.

Four live sites depend on it returning the base entity **and its subclasses**:

| Site | Consequence |
|---|---|
| `RptqDocumentElement+Extras.m:153` (in `awakeFromInsert`) | the `dropIndex` scan finds nothing, so every new element is given `dropIndex` 1 — z-order and stacking collide |
| `RptqDocumentSection+Extras.m:456` (`nextDropIndexForSection:`) | always 0 |
| `MADocument.m:1288` (`deleteAggregateFieldRelatedToTable:`) | aggregates are never deleted when a query table is removed |
| `MADocument.m:1307` (`deleteDatafieldsRelatedToTable:`) | same — data-field elements are orphaned against a removed table |

**Fix:** give the plural lookup the same table fallback the singular one has, so a query for a
table-owning entity returns every row whose entity resolves to that table.

### 9.2 The coverage lesson

`MADStoreConverterTests.m:136` builds its Core Data reference fetch with
`includesSubentities = NO` — the *same* narrowing the broken lookup has. Both sides count "rows
whose entity is exactly this name", both return zero for the base element, and
`testEveryLegacyRowIsWritten` passes. Its own header comment says the counts "come from Core
Data itself, so a walk that quietly skips a relationship … shows up here rather than passing
because both sides of the comparison made the same omission" — and the test *does* make the same
omission, in the entity dimension rather than the row dimension.

This is the general hazard, not a one-off: **a reference implementation that shares the code's
blind spot cannot falsify it.** Two habits follow. When a test compares against a reference,
the reference must be asked a *different* question than the code asks (here:
`includesSubentities = YES` for a table-owning entity). And when a new lookup is added, it needs
a test that would fail if the lookup silently returned nothing — the singular lookup's fallback
was tested, the plural one's absence was not.

### 9.3 The rest of the outstanding list

- **`RptqObject` identity.** No `-isEqual:`/`-hash:` (NSManagedObject gave objectID equality),
  and `RptqStoreContext.m:80` keys its registry by the **requested** entity name — so the same
  row reached as `RptqDocumentElement` and as `RptqDocumentElementLabel` faults into two
  instances. A concrete consequence: `-save:` clears deleted rows from the registry with
  `self.registry[row.entity]`, which misses an entry stored under a different requested name,
  leaving a deleted object faultable. Key the registry on the row's own entity, and/or
  implement `-isEqual:`/`-hash:` on (entity, identifier).
- **Non-optional attribute defaults are filled at write time** (`MADStore.m`, the post-loop in
  `writeRowForObject:`). It is `O(attributes × columns)` per row on the save path, and it
  invents `@""` for text, which is not distinguishable from an intentionally-empty string. Core
  Data applied defaults at insert; `insertObjectForEntity:` is the equivalent place.
- **Notifications registered with `object: nil`** (`MADocument.m:331`, `:336`) and the handlers
  do not filter by context (`:892`, `:898`), so any Core Data context in the process — a legacy
  conversion in another open document, for instance — marks *every* open document
  `needsSave`. Filter on the document's own context, or scope to the converter's.
  `handleManagedObjectContextWillSave:` (`:903`) is registered against `object: self`, so it
  can never fire.
- **`closeWithCompletionHandler:` bypasses `[super …]`** (`MADocument.m`), because the
  superclass path deadlocks on its own file-access queue. That is a real deadlock and skipping
  super is a legitimate response, but it also skips UIDocument's file-presenter and state
  bookkeeping. Worth confirming the document still reaches `UIDocumentStateClosed` and releases
  its file presenter; if not, the eventual `UIDocument` conversion in Phase D inherits the
  problem.
- **`objectsForEntity:` sorts and allocates on every call** (`MADStoreGraph.m:74`), and
  `MADQueryViewDataSource.m:119,499,511,526,543` calls it per accessor. Small N today; memoize
  per load if it profiles.
- **`layoutHeight` dropped** from the `MADSectionsLayout` projection (the old fetch had it,
  `RptqDocumentSection+Extras.m:348,351`). Every consumer was traced — `MADSectionLayout` and
  `MADSectionGroupLayout` read identifier, type, height, numberOfRows, visibility,
  wrappingStyle and the `inGroup*` keys — so it appears benign. Confirm, or restore it.
- **Test scaffolding in the shipping app.** `AppDelegate.m` gained `-UITestOpenSample` and
  `-UITestSelectTab` hooks with hard-coded `dispatch_after` delays. Inert in production (the
  arguments are never present), but it is test-only code in the app target; wrap it in
  `#if DEBUG` or retire it when the UI tests can run.
- **`MAD.momd` is now compiled into the MAD framework** so legacy conversion can always find its
  model. Correct while conversion exists; **must be removed in Phase D**, together with
  `MADStoreConverter` once no shipping document is v0. Recorded in `MAD_STORE_MIGRATION.md` §7.

### 9.4 Verified good

- **Refresh and paging are untouched by the store migration.** `MADReportFormatter.m`,
  `MADDataTableFast.m` and `MADArrayCaching.m` have zero diff against `master`; the row cache
  and the render cache still carry the hot paths, exactly as `MAD_FORMAT.md` §5 describes.
- **No leftover Core Data calls.** Every Core Data-only selector (`executeFetchRequest`,
  `objectWithID`, `existingObjectWithID`, `insertNewObjectForEntityForName`, `registeredObjects`,
  `refreshObject:mergeChanges:`, `deleteCacheWithName`) was swept across MAD and MADDesigner:
  the only hits are a commented-out block and `MADStoreConverter`, which is allowed to.
- **The removed `awakeFromInsert` bodies were identifier-assignment only**, which
  `insertObjectForEntity:` now performs — no behavioural loss.
- **The two Sqlite3 driver fixes are genuine.** `connectWithConnection:` really did open the
  database and return `nil`; `fieldsForTable:` really was listing tables where fields were
  asked for, and `PRAGMA table_info` is the correct replacement.
- **Dirty-tracking is real.** `-save:` early-returns when clean, before any I/O, and the
  incremental path writes only dirty rows, positions for dirty ordered parents, and join rows
  for dirty participants.
