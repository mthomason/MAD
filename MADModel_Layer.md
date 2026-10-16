# MADModel — the document read-model layer

**Scope:** `MAD/Source/model/MADModel*.{h,m}`, `MAD/Source/model/MADTableFieldIdentifier.{h,m}`, and every
consumer of the layer in `MAD` and `MAD Designer`.
**Date:** 2026-10-16, read at `d7faff320`.
**Status:** reference. Everything here was read first-hand at that commit; §7's refactoring
candidates are proposals and are not applied.

---

## 1. What the layer is

`MADModel*` is a **document-scoped, read-only view of the document's definition** — the
connection, the schema (tables and fields), and the query graph (which tables the query uses,
which fields, and the joins between them). It is what the designer's query UI binds to.

It is *not* the canonical model. The canonical model is the `Rptq*` object graph in the
portable store: it is what the app edits, saves, converts and renders. A `MADModel*` object is
little more than **a store row identifier (`int64_t`) plus a weak pointer to the
`RptqStoreContext` plus a few copied display values**, resolved lazily by fetching rows with
`objectsForEntity:identifier:`.

The rule of thumb the code follows:

> **Write through `Rptq`; read and observe through `MADModel`.**

The two layers share one identifier space: a model object's `identifier` *is* the store row's
`identifier`. That is the whole glue — see §3.

```
MADModelDocument                       one per open .mad — MADocument.documentModel
 └ databases: [MADModelDatabase]       (today: exactly one)
    ├ driverID / driverType / schemaName   ← RptqDatabase + RptqDatabaseCredentals
    ├ tables / tableDictionary : {id → MADModelTable}      ← RptqDatabaseSchemaTable
    │   └ MADModelTable  (name, queryable)
    │      └ fields / fieldIDs : {id → MADModelField}      ← RptqDatabaseSchemaField
    │         └ MADModelField (name, dataType, decimals, width, primaryKey)
    └ queries: [MADModelQuery]         (today: exactly one; `firstQuery` everywhere)
       └ MADModelQuery
          ├ queryTableIDs / tables : {id → MADModelQueryTable}   ← RptqQueryTable
          │   └ MADModelQueryTable  (schemaTable id, dropIndex, alias)
          │      └ queryFields : {id → MADModelQueryField}       ← RptqQueryField
          │         └ MADModelQueryField (schemaTable + schemaField ids)
          └ queryLinkIDs / links : {id → MADModelQueryLink}      ← RptqQueryLinks
              └ MADModelQueryLink   (left/right table+field ids — one join)
```

## 2. The classes

### 2.1 `MADModel` — identity (`MADModel.h`, `MADModel.m`)

The base class is only identity: `_uid` (`MADModel.m:32-64`), with `hash`, `isEqual:` (same
class and same `_uid`) and `-objectID` returning the id boxed in an `NSNumber`.
`+[MADModel newModelDocument:]` (`MADModel.m:35`) is the nominal factory — nothing calls it;
`MADocument` allocates `MADModelDocument` directly. `MADModelType.h` defines
`MADModelTypeUnknown/Document/Database/Queries`; nothing in the tree uses the enum.

The name `objectID` and a commented-out `debugDescription` that formats
`_objectID.URIRepresentation` are the tell for the layer's age: the objects used to wrap
`NSManagedObjectID`s (see §5).

### 2.2 `MADModelDocument` — the root (`MADModelDocument.h`, `.m`)

- Created once per open document by `-MADocument.documentModel`
  (`MADocument.m:389-395`), lazily, over `self.storeContext`. Nothing else in production
  builds one; the app delegate has no part in it.
- Holds `databases` (built by `-updateDocumentDatabaseQuery`, `MADModelDocument.m:210-240`:
  one `MADModelDatabase` *per `RptqQuery` row* — "database" here means the connection plus its
  schema plus a query) with `firstDatabase` / `firstQuery` convenience accessors. The code
  says why the plural is theatre: *"current versions of the software only use one database and
  query"* (`MADModelDocument.m:207-208`).
- **Registers for the store's change notifications** (`RptqStoreContextObjectsDidChange`,
  `WillSave`, `DidSave`, `MADModelDocument.m:160-176`) on a private `NSOperationQueue`
  (`MADModelDocument.m:83-87`, `_objectContextQueue`). On insert/delete of a `RptqQueryTable`
  or `RptqQueryLinks` row it mirrors the change into `firstQuery` — see §3.3.
- `-update` (`MADModelDocument.m:201-205`) re-runs the document→database→query scan and
  *replaces* `_databases` with new objects.

### 2.3 `MADModelDatabase` — connection, schema and queries (`MADModelDatabase.h`, `.m`)

- Keyed by the `RptqDatabase` row's identifier.
- Metadata is resolved *through the store, one property at a time*: `driverType`
  (`MADModelDatabase.m:157-164`), `schemaName` (`:166-173`) and `driverID` (`:175-182`) each
  lazily fetch the `RptqDatabase` and read through to `RptqDatabaseCredentals`. `schemaName`
  and the broken `driverName` (§6) both answer the credentials' `dbname`.
- `tables` / `tableDictionary` (`-updateTables`, `MADModelDatabase.m:221-247`) list every
  `RptqDatabaseSchemaTable` whose `inDatabase` matches, **sorted by name** — restoring the
  sort a pre-migration fetch applied, with a comment pointing at BUGS.md.
- `queries` (`-updateQueries`, `:249-261`) does the same for `RptqQuery` rows.

### 2.4 `MADModelTable` / `MADModelField` — the schema (`MADModelTable.{h,m}`, `MADModelField.h`)

- `MADModelTable` caches `name`, and lazily builds `fields` / `fieldIDs`
  (`MADModelTable.m:120-146`) from `RptqDatabaseSchemaField` rows whose `inTable` matches,
  sorted by name. `MADModelField` is a plain value: name, primary-key flag, data type,
  native type, decimals, width — no store access.

### 2.5 `MADModelQuery` — one query (`MADModelQuery.h`, `.m`)

The biggest class, and the one that actually earns its keep. It owns:

- `queryTableIDs` + `tables` (`MADModelQuery.m:213-283`): every `RptqQueryField` whose
  `inQueryTable.inQuery` is this query is projected to a dictionary
  (`MADStoreProjectionForQueryField`, `:59-68`) — the exact shape the old Core Data fetch
  projections produced — and fed to `-insertTablesFromFetchRequestResults:`.
- `queryLinkIDs` + `links` (`:302-344`): the same for `RptqQueryLinks`
  (`MADStoreProjectionForQueryLink`, `:70-78`).
- Topology helpers: `-tablesInLinks` (`:183`) and `-orphanedQueryTables` (`:196`, the tables
  no link touches, via an `NSExpression` set-minus).
- **The mutation surface**: `-insertQueryTable:` / `-insertQueryLink:` /
  `-deleteQueryTableID:` / `-deleteQueryLinkID:` and the id-based variants. Each applies the
  change to the collections and then re-posts `MADNotificationQueryTableInsert/Delete` or
  `MADNotificationQueryLinkInsert/Delete` (names in `MADModel.h:22-26`) **on the main queue**
  via `[NSOperationQueue mainQueue] addOperationWithBlock:`, with the affected model object in
  the `userInfo`. These notifications are the layer's public event stream; the designer
  subscribes to them (§4).

### 2.6 `MADModelQueryTable` / `MADModelQueryField` — the query's tables and fields

- `MADModelQueryTable` (`MADModelQueryTable.m`) caches `dropIndex` and the **schema** table id,
  and lazily holds `queryFields` / `queryFieldIDs` (built by `-addField:schemaField:`, `:92`).
  `-alias` (`:119-129`) is the SQL-facing name: the schema table's name for the first copy and
  name + drop index afterwards (`Customer`, `Customer0`, …).
- `MADModelQueryField` (`MADModelQueryField.m`) is two ids: the schema table and the schema
  field. `-schemaField` (`:52-57`) resolves the real metadata by walking
  database → `tableDictionary[schemaTable]` → `fields[schemaField]`. That chain —
  link → query table → schema table → query field → schema field — is the layer's defining
  pattern; `MADQueryVisualizationViewController.m:1024-1048` performs it by hand to place a
  connector.

### 2.7 `MADModelQueryLink` / `MADTableFieldIdentifier`

- `MADTableFieldIdentifier` (`MADTableFieldIdentifier.{h,m}`) is a tiny value pair
  (table id + field id) with `NSNumber` accessors.
- `MADModelQueryLink` (`MADModelQueryLink.m`) holds a `MADTableFieldIdentifier` for each end,
  built either from raw ids or from a `RptqQueryLinks` row (`-initWithRptqQueryLink:`,
  `:60-76`, which reads `hasLeftField.inQueryTable.identifier` / `hasLeftField.identifier`).
  `-isAdjacentToQueryTable:` (`:78`) and `-tables` (`:82`) answer the graph questions the
  visualization asks.

### 2.8 The protocols and the vestigial pieces

- `MADModelIDProtocol` — four lines: `identifier` (`MADModelIDProtocol.h`).
- `MADModelDataProtocol` (`MADModelDataProtocol.h`) — `managedObjectContext`,
  `-initWithIdentifier:managedObjectContext:` and `-update`. In practice `-update` is an
  internal refresh hook: it is called only from the layer's own lazy getters
  (`MADModelDocument.m:188`, `MADModelTable.m:99` and `:115`). `MADModelDatabase -update`
  (`MADModelDatabase.m:148`) and `-MADModelQuery -update` (`MADModelQuery.m:354`, an empty
  method) have no callers at all.

## 3. Lifecycle

### 3.1 Creation

`MADocument` builds one `MADModelDocument` lazily (`MADocument.m:389-395`) and keeps it for
the document's lifetime. It holds the `RptqStoreContext` **weakly**
(`MADModelDocument.m:42`), like every model object that keeps a context — the store context is
owned by the document.

### 3.2 Population

Everything below the document is **lazy and cached**: the first read of `databases`, `tables`,
`fields`, `queryTableIDs`, `queryFields` or `links` triggers a fetch-and-filter pass
(`objectsForEntity:` over the relevant Rptq entity, filtered by the parent's identifier, then
sorted where a pre-migration fetch sorted). The caches are only invalidated by calling
`-update` or by the notification path below; nothing expires on its own.

### 3.3 Live changes — the round trip

Adding a table or a link in the designer writes **Rptq rows** (e.g. the add-table flow at
`MADQueryViewController.m:745-790` creates `RptqQueryTable` + `RptqQueryField` rows and saves
the context). The model then catches up on its own:

```
user adds a table / link
  → RptqQueryTable / RptqQueryLinks rows written + saved
    → RptqStoreContextObjectsDidChangeNotification
      → MADModelDocument's observer (on its private queue)     MADModelDocument.m:91-158
        → [firstQuery insertQueryTable:/insertQueryLink:]       MADModelQuery.m:361-410
          → MADNotification…Insert/Delete reposted on main      MADModelQuery.m:361-514
            → MADQueryVisualizationViewController, MADQueryBuilderAddTableViewController
```

Two queues are in play: the model *mutates* on `_objectContextQueue` (a private
`NSOperationQueue`, `MADModelDocument.m:83-87`) and the notifications *arrive* on the main
queue. The collections themselves are not synchronised.

### 3.4 Staleness

`-update` (document or database) rebuilds collections with **new** model objects; any model
object handed out earlier keeps working for what it cached but is no longer the one in
`firstQuery.tables`. Nothing in the tree calls `-update` on a model object today — the
notification path is the live one — but code that stores model objects across an `-update`
would be reading stale entries.

## 4. Consumers

### 4.1 The Query tab (ad-hoc query builder)

- `MADQueryViewDataSource.m:365` — the datasource header cell: "You are connecting to
  *driverID* datasource named *schemaName*" from `firstDatabase`.
- `MADQueryViewDataSource.m:533-546` — the query-tables list takes `firstQuery` and uses
  `query.identifier` to filter `RptqQueryTable` rows. Note the pattern: **the model supplies
  identity and metadata; the rows themselves are Rptq objects.**
- `MADQueryTableViewController.m:163-174` — a query table's box title comes from
  `firstQuery.tables[id].alias`; `:186-200` and `:239-266` render the schema field list from
  `firstDatabase.tableDictionary[schemaTableID]` → `fieldIDs` / `fields`. This is the schema
  browser's whole content model.
- `MADQueryBuilderAddTableViewController.m:29-33` — observes the model's insert/delete
  notifications to keep its table panel current.

### 4.2 The Query Visualization tab (boxes and connectors)

- `MADQueryVisualizationModel` (`MADQueryVisualizationModel.m:40-77`) builds an `MTGraph` via
  `-[MTGraph initWtthQueryID:]` (`MTGraph+RptqQuery.m:39-67`), which is written **entirely on
  the model**: `query.queryTableIDs` become vertices, `query.links` become edges. It then
  topologically sorts, computes `startingPoints` (tables no link points *into*) and stores the
  DAG flag. (The same category also has store-based initializers, `:69-93`, predating the
  model path; the visualization uses the model one.)
- `MADQueryVisualizationViewController` (`MADQueryVisualizationViewController.m`) is the main
  consumer of the notification stream: it subscribes to all four model notifications
  (`:314-335`), adds/removes boxes and connectors as they arrive, re-marks root tables after a
  link delete using `-orphanedQueryTables` (`:936`), asks `-linksForQueryTable:` per table
  (`:644`), and lays out each connector by walking the identifier chain
  (`:1024-1048`, §2.6).
- `MADQueryVisualizationCacheManager` persists the canvas layout keyed by model identifiers
  (`updateCacheWithQuery:…`, `MADQueryVisualizationCacheManager.h:20`).

### 4.3 The document and the tests

`MADocument.documentModel` is the only production entry point. Tests:
`MADDocumentTests.m:263-265` (a reopened document's `databases`/`queries`),
`MADDocumentTests.m:399-404` (a `MADModelDatabase`'s table/field order), plus the dedicated
suites `MADModelQueryTableTests`, `MADModelQueryFieldTests` and the `MADModelField` /
`MADModelQueryLink` coverage in `MADModelValueTypesTests`.

### 4.4 What does *not* use it

- **SQL generation** — `MADQueryFull` and the `Rptq*+Extras` classes work on the Rptq layer
  (e.g. `RptqQueryField+Extras.m:137` builds `table.field` names from `RptqQueryTable.alias`).
- **Layout and rendering** — `MADDesignerLayout` and the report path work on
  `RptqDocumentElement`; `MADReportFormatter` does not use the layer at all (its three
  `MADModel*` imports at `MADReportFormatter.m:18-20` are stale).
- **Row data** — none of this touches the `.maddb` cache; that is `MADDataTableFast` /
  `MADReportFormatter` territory.

So the layer's real scope today is: **the query side of the designer, and nothing else.**

## 5. Why it exists

The layer is from early 2017 (file headers `1/22/17`–`6/3/17`) and was built in the Core Data
era as a **hand-made view model for the query UI**: light objects the designer's table views
and the visualization canvas could bind to, instead of `NSManagedObject`s and
`NSFetchedResultsController`s. The evidence is in the files: `-objectID`, the commented-out
`NSManagedObjectID` debug description in `MADModel.m:66-80`, and three surviving comments that
say "was an `NSFetchedResultsController`" (`MADQueryChooseFieldController.m:149`,
`MTGroupByViewController.m:53`, `MADTableViewControllerCoreDataResults.h:14`).

The store migration (Phase C/D of `MAD_STORE_MIGRATION.md`) rewired every fetch from Core Data
to `RptqStoreContext` + `objectsForEntity:` **without changing this layer's surface** — which
is why `MIGRATION_KICKOFF.md` §Findings calls it "[a] clean `MADModel*` domain layer [that]
already wraps the `Rptq` entities; it is the seam to keep."

So it is MVC of a sort, but not "the app's model": it is a **per-document read model** (MVC's
"model" as seen by the controller), and the canonical domain objects are the Rptq graph. The
abstraction buys three things and is thin everywhere else: (1) the query graph in a
display-shaped form (aliases, adjacency, id-to-metadata lookups) without relationship
traversal; (2) one place that converts store change notifications into query-graph events;
(3) an interface the UI could keep untouched while the store beneath it changed completely —
which is exactly what happened.

## 6. Known rough edges

Read first-hand; none of these has a consumer today, so all are latent.

1. `MADModelField.inTable` (`MADModelField.h:20`) is declared `weak MADModelField *` — the
   type is wrong (it should be `MADModelTable *`) — and nothing ever assigns it.
2. The other parent back-pointers are just as unused: `MADModelTable.inDatabase`,
   `MADModelQueryTable.inQuery` and `MADModelQueryField.inQueryTable` are never assigned by
   any code path in the tree. Only `MADModelQuery.inDatabase` is ever set
   (`MADModelQuery.m:108-114`). (`-addField:schemaField:` not wiring its field's back-pointer
   is already recorded in BUGS.md.)
3. `MADModelDatabase -driverName` (`MADModelDatabase.m:184-215`) ends in `return @"";`, so it
   answers the empty string even after caching the real name; `-schemaName` already returns
   the same string from the same place. No reader exists.
4. `MADModelDocument.m:228-234` decodes a document id (`docID`) and never uses it.
5. `MADModelQuery -update` (`MADModelQuery.m:354`) is empty; `MADModelDatabase -update` has no
   callers; `+[MADModel newModelDocument:]` has no callers.
6. `MADModelType` is unused.
7. No synchronisation between the private queue that mutates the model and the main-thread
   readers; and `MADModelDocument` holds the store context weakly, so a model outliving its
   document has no context to resolve anything.
8. Naming: a `MADModelDocument` has `databases`, and a `MADModelDatabase` has `queries` — but
   the document builds one "database" *per query* and today there is exactly one of each. The
   structure is future-proofing from before the one-database/one-query simplification.

## 7. Refactoring candidates (proposals — none applied)

Ordered by value over risk. A and B are pure tidying; C changes what a public header promises;
D is a decision.

**A. Documentation, not consolidation.** The cheapest clarity win is per-class header comments
(2–4 lines: what the class is, what it is keyed by, who reads it) plus this document. Merging
the classes' *files* is the expensive option, not the cheap one: sixteen-plus files import the
per-class headers (`#import <MAD/MADModelQueryField.h>` etc.), each header is a separate file
in the Xcode targets, and the Linux build's include shim is a directory of per-header symlinks
(`Linux/README.md`, MAD's shim). Consolidating would touch the pbxproj, the Linux source lists
and every import site for a cosmetic gain. If any merge is ever wanted, the safe direction is
the opposite: keep one class per file and make the **entry point** obvious (document top of
`MADModel.h`, "start at `MADModelDocument`").

**B. Delete or complete the vestigial surface.** Each of these is behaviour-safe (nothing
reads them) but touches headers, so treat it as an API decision:
- `MADModelField.inTable`: fix the type and set it in `MADModelTable -update` (one line,
  symmetric with the other parents), or delete the property.
- `MADModelDatabase -driverName`: return the cached value like its siblings, or delete it.
- `MADModelType`: delete the header. (Requires the project-file removal; do it in one commit.)
- `+[MADModel newModelDocument:]`: either make `MADocument -documentModel` use it (restoring
  the factory's purpose) or delete it.
- The unused `docID` decode in `MADModelDocument.m:228-234`.

**C. Wire the declared back-pointers.** `inDatabase`, `inQuery` and `inQueryTable` exist so the
graph can be walked upwards; today only downward lookups work. Assigning them at construction
(`MADModelDatabase -updateTables` already has `self`; `insertTableRptqQueryTable:` has the
model query; `-addField:schemaField:` has the table) makes the object graph match its headers
and is safe precisely because nothing reads them yet. Semantics to keep in mind: they are
declared `weak`, which is right for downward-owned parents.

**D. Identity across refreshes (a decision, not a tidy-up).** `-update` replaces objects; if
stable identity across updates is ever wanted, the update methods must mutate in place
(reuse the object for an identifier, add/remove the difference) rather than rebuild. That
changes observable identity of handed-out objects, so it needs a deliberate choice.

**E. Mechanical dedup.** `MADModelTable.fields` and `-fieldIDs` (`MADModelTable.m:88-118`)
contain the same initialisation block twice, and `MADModelQuery`'s three getters repeat the
same "ensure collections, then update" dance (`MADModelQuery.m:116-181`). Both can collapse
into one private helper each with no behaviour change; worth doing only when the file is open
for something else.

**F. NOT recommended: renaming.** `MADModelDatabase` → something like `MADModelConnection`
would read better, but renames here are churn across Xcode/Linux project files with no
functional payoff.

## 8. If you change this layer

- Keep the identifier-only contract: a model object must stay constructible from ids alone
  (that is what the notification path and the tests rely on).
- Anything that creates or deletes `RptqQueryTable` / `RptqQueryLinks` rows gets picked up by
  `MADModelDocument`'s observer automatically — but only for rows reached through
  `firstQuery`; a second query in a document is not mirrored.
- The four `MADNotification…` names are the layer's public API for the UI; observe them
  against the `firstQuery` object, as `MADQueryVisualizationViewController` does.
- The iOS suite (`MAD` scheme) and `./Linux/build.sh` both compile these files; see
  `Linux/cmake/MADSources.cmake`.
