# Phase C — App Integration: the mechanism

This is the design for turning the `Rptq` classes from `NSManagedObject` subclasses into
plain objects backed by the portable store, and for replacing the app's
`NSManagedObjectContext` / `NSFetchRequest` / `NSEntityDescription` usage with the store.
It is the mechanism the rest of Phase C executes; the schema-family slice is the first
proof of it.

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
