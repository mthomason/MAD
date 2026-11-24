---
layout: default
title: "Multi-source reports"
description: "Reports as tables, and drivers for anything that returns a table."
---

# Multi-Source Reports — reports as tables, and drivers for anything

This page describes composable reports: a report's result becomes a table another report can query, and a driver can front anything that returns rows. It is a design record; §8 names the phases, and not all of them are built.

> **Normative model:** the execution contract this page motivates is now stated, normatively
> and in one place, in
> [`MAD_COMPOSITION_SPEC.md`](../project/design/MAD_COMPOSITION_SPEC.html). Where this page
> (or `data-object.md`) differs from it, the spec wins.

**Scope:** the architecture the user described on 2026-11-22: a user designs a report
against a data source (MySQL, SQL Server, PostgreSQL, SQLite, or a Web API such as eBay's
Seller API); that report's result is a materialized SQLite table; and another report can
design a query against that report — joining one report's output to another report's
output, and to base sources, in one query graph. On refresh the engine walks the graph
bottom-up, executes each leaf against its own source, materializes each result, and finally
runs the composing query over the materializations. The non-SQL driver seam is part of
this: a driver that fronts an API receives a structured query, not SQL text, and returns
rows in table form.
**Date:** 2026-11-22, read at `eba4225a1`; decisions folded in 2026-11-22 (§9.2).
**Status:** design report. It states the idea and the design; it does not implement
anything and it does not add work to `TASKS.md`. The code audit that grounds the
data-object half is [`MAD_DATA_OBJECT.md`](data-object.md); the direction is
[`docs/vision.md`](../vision.md). This document adds the multi-source composition model
(intra-document sub-reports first), the driver API that makes non-SQL sources first-class,
and a combined phase order.

---

## 1. The idea, in one page

A report is a function from data sources to a table. The account-vs-order distinction that
matters for this design is already in the code:

- The **definition** is the query graph — tables, fields, links, predicates, groupings —
  plus the banded layout. It lives in the `.mad` archive.
- The **result** is a schema (`MADDataColumn`s) and rows. It lives beside the document in a
  companion SQLite cache (`.maddb` + `.mdcache`), outside the archive, because it is
  derived and regenerable.

The extension is to make the result **addressable as a table**. A report's output then
becomes a source for another report, exactly as a schema table is a source today. A report
built on reports is a DAG of derived tables: a portable semantic layer where designing a
report is also designing a reusable data source.

The same extension makes multi-source reports natural. Each source object executes against
its own database or API, with its own driver and credentials, and materializes into its own
SQLite table. The composing object executes against the **local cache**, not a remote
server, joining the materializations. No federation engine is added; the snapshots are the
federation.

The user's example: a business wants a report of its eBay listings. One report object
queries the eBay Seller API and materializes the listings; another queries the company's
MySQL database for sales; a composing report joins the two outputs on SKU. Each driver only
knows its own source. The join happens in SQLite, locally.

The non-SQL driver is what makes the first object possible. Its contract is the same
"schema plus rows" contract the SQL drivers satisfy — but its input should be the query
graph, not a SQL string it has to parse.

## 2. What is already true in the code

The expensive parts exist. `MAD_DATA_OBJECT.md` §3 is the detailed audit; the load-bearing
facts for this report are:

1. **The definition is a graph, and the store permits many.** `RptqQuery` owns tables,
   fields, links, predicates, and groups. `MADModelDocument` builds one `MADModelDatabase`
   per `RptqQuery`, with the code's own note that current versions use one. The cardinality
   is a convention of the app's flows, not of the store (`MAD_DATA_OBJECT.md` §3.1).
2. **The compiler exists and is deterministic.** `MADQueryFull -copySQLWithManagedObjectContext:error:`
   (`MAD/Source/MADQueryFull.m:133-273`) builds the SELECT list, the FROM/JOIN tree from a
   topologically sorted graph, the WHERE clause, and the limit, through the driver's
   dialect hooks.
3. **The execution seam is already table-shaped.** `MADDatabase`'s abstract point is
   `executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
   (`MADAPI/Source/MADDatabaseProtocol.h:33-34`), and the destination is any
   `id <MADDataTableWriting>`, not a concrete table class. All four drivers fill it the same
   way: remove all objects, add columns, bulk insert, add rows.
4. **The materialization is a real SQLite table.** `MADDataTableFast` writes
   `<tag>.maddb` and the table `t<tag>` (`MADSqlite3/Source/MADDataTableFast.m:403-406`,
   `:463-467`, `:503-511`). The schema plist is `.mdcache`; rows and schema are separable
   (`docs/05-companion-files.md` §5). SQLite is already a driver
   (`MADSqlite3/Source/MADDatabaseSqlite3.m`), so a query whose "database" is the cache is
   today's code, not new code.
5. **The cache is disposable and per-device.** It is not in the document and not in iCloud
   (`docs/05-companion-files.md` §5.2). That is correct for a derived artifact, but it is a
   constraint on any design that treats another report's cache as a source: the cache may
   not be there.

The same section names the three single-query hardwiring points, and they are still true
today:

- `MADQueryFull` re-reads the document's first database and first query rather than using
  the query it was initialized with (`MAD/Source/MADQueryFull.m:147-149`).
- `MADocument -dataTableForQuery:` is a one-slot switch: it returns the document's one table
  for `MADQueryFull` and nil for everything else (`MAD/Source/MADocument.m:873-880`).
- `MADQueryActiveQueryFields` scans every element, link, and group in the store with no
  query scoping (`MAD/Source/MADQueryActiveQueryFields.m:27-100`). A second query's fields
  would leak into the first query's SELECT list.

Two more facts matter for the composition design:

- **The address is the filename hash.** The document creates its table with
  `initWithId: self.fileURL.lastPathComponent.hash` (`MAD/Source/MADocument.m:273-275`), and
  the cache directory is named by that hash. Nothing can point at the table by a stable
  identity.
- **One `MADDataTableFast` is one file.** `filenameCacheMadDB` is `<tag>.maddb`
  (`MADSqlite3/Source/MADDataTableFast.m:403-406`), and each instance opens its own insert
  and select connections (`:482-501`). There is no "several tables in one `.maddb`" mode
  today. `MAD_DATA_OBJECT.md` §5.1 describes that mode as a design variant; the current
  class does not implement it.
- **There is no `ATTACH` support.** A search of `MADSqlite3`, `MAD`, and `CLI` finds no
  `ATTACH DATABASE` use. Cross-file composition needs it added, or a copy-in step.

## 3. The composition model

### 3.1 Nodes and edges

- A **source object** owns one `RptqDatabase` (driver + connection + credentials) and one
  query definition. It is executed against its source.
- A **composing object** owns a query whose tables are other data objects (source or
  composing). It is executed against the local cache. A composing object does not own a
  remote source in this design: a remote table it needs is a **source object** whose output
  it references. That keeps the node taxonomy to two kinds — remote leaves and local
  composers — and keeps the refresh walk honest.
- An **edge** is a table reference in a composing query to another object's output schema.
- The graph must be acyclic. A cycle is a design-time error, reported on the offending
  reference, not a stack overflow at refresh.

### 3.2 Refresh is topological

1. Walk the DAG bottom-up. The existing compiler already topologically sorts the join graph
   (`MAD/Source/MADQueryFull.m:170-204`); the object graph needs the same discipline at the
   object level.
2. Execute each leaf against its own source, through its own driver, into its own
   materialization.
3. Attach or open the materializations needed by the composing object.
4. Execute the composing query against the local SQLite database and materialize its result.
5. Repeat up the graph. The root is an ordinary report; its cache is what the viewer reads.

Paging is unchanged. The engine still pulls the full result into the local cache; the UI
pages over the cache. For an API driver, "pagination" is an **internal loop** over the API's
pages to fill its materialization; it is not a streaming or paging contract with the
engine. The plan's `limit`/`offset` exist for design-mode previews and for a driver that
wants to cap its fetch, not for the viewer's paging.

Grouping, sorting, and aggregates are unchanged: they are computed over the local cache
(`MAD_DATA_OBJECT.md` §3.5). The driver returns detail rows; it does not need to implement
`GROUP BY` or the report's grouping. A sort hint in the plan lets a driver push down a
top-N request when a limit is present; the engine still re-sorts.

### 3.3 Two materialization layouts

The user's instinct was `ATTACH`, and the current code makes it the shorter path.

**Layout A — one `.maddb` per source object, `ATTACH` to join.**
- Each object's `MADDataTableFast` keeps its own `<tag>.maddb` and `t<tag>`.
- The composing query opens a connection to the local cache (or an in-memory database) and
  runs `ATTACH DATABASE '<path>' AS <alias>` for each source object it needs.
- SQL generation qualifies the table as `<alias>.t<tag>`.
- New work: `ATTACH` support in `MADDatabaseSqlite3`, alias management, and path quoting.
  The class is already a full SQLite wrapper, so this is a small addition.
- Limits: SQLite's `SQLITE_MAX_ATTACHED` defaults to 10, and no build recipe in the
  repository raises it (`Compressor/sqlite3.xcconfig`, `Linux/`, `Windows/Engine/`). Raising
  it is a build change on three platforms. v1 treats more than ten direct sources as a
  design-time error.
- The composing object itself materializes into its own `.maddb`, like any other result.

**Layout B — several tables in one `.maddb`.**
- One cache file per document, several `t<tag>` tables, no `ATTACH`.
- This requires changing `MADDataTableFast` from "one instance owns one file" to a shared
  file/connection model, or adding a table registry above it. That is a larger change than
  `ATTACH`, and it cuts against the class's current one-file-per-table design.
- Its advantage is a single file and no attach limit.

**Recommendation:** Layout A for the first composition implementation, because it follows
the current class boundary and matches the user's model. Layout B remains the cleaner
long-term file story if the per-table file model is ever revisited.

### 3.4 What a reference means

A composing query's table reference needs a second kind beside `databaseSchemaTable`
(today's `RptqQueryTable.databaseSchemaTable`, `MAD/Source/rptq/autogen/RptqQueryTable.h:27`).
The user's decision (2026-11-22) is that composition is **intra-document first**: a `.mad`
document contains several report/query definitions — **sub-reports** — and the composing
report references one by its identity. The one-portable-file property is preserved, and the
iOS cross-file re-authorization problem does not arise for v1. A reference to a **report in
another `.mad` file** (a document identity plus a path) is a later, separate concern,
deferred behind same-document composition.

The cache is per-device and disposable, so the reference records *what to run*, not *where
the data is*:

- **Live reference (default).** The parent stores the child's definition reference and, on
  refresh, executes the child and materializes its result.
- **Pinned snapshot.** The parent retains the child's materialization in the companion cache
  (`.maddb`/`.mdcache`) and reuses it instead of re-executing the child. A pin is a retained
  cache artifact, **never data embedded in the `.mad`** — the archive stays definition-only
  (§6). Live and pinned both read from the cache directory; "pin" means "keep and reuse
  this materialization," not "copy the data into the document."

Materialization naming moves from the filename hash to a stable object identity so files
cannot clash and a parent can address a specific child (§3.6, §6).

### 3.4.1 How the parent names a child's columns

`RptqQueryField` has exactly one field reference, `databaseSchemaField`
(`MAD/Source/rptq/autogen/RptqQueryField.h:27`), and the select builder, join builder,
predicates, and the join UI all read `queryField.databaseSchemaField.name`. A child's output
columns are `MADDataColumn`s, not schema fields. The recommendation is to **synthesize a
per-object result-schema table and field set** from the child's `MADDataColumn`s: the
parent's query fields then point at ordinary schema-field rows, and every existing builder
and UI works unchanged. The synthetic rows are a snapshot of the child's result schema and
are refreshed when the child's schema changes. The alternative — a second field-reference
kind on `RptqQueryField` — touches every builder and is not recommended. **Builder call.**

### 3.5 Failure, staleness, and coordination

- If a child fails, the parent refresh fails with the child's error and the node's name. The
  parent's previous cache is not replaced with a half-built result.
- A missing child file, a moved file, a changed schema, or a missing credential is a
  refresh-time error the UI can explain, not a silent empty result.
- Cycles, self-references, and a child that is also an ancestor are rejected before
  execution.
- Cross-document references (deferred beyond v1) will, when they arrive, go through file
  coordination and security-scoped URLs on iOS; iCloud may evict the child. The CLI and
  macOS take explicit paths. The design needs one path-resolution policy across all three.
- Refresh progress should be per node. A long API fetch in a child should be visible as that
  child's progress, not an unexplained stall.
- Cancellation must reach the running driver. The current execution method is synchronous
  and has no cancellation token; a plan execution options object is the natural place for
  one.

### 3.6 What the parent stores

At design time the parent needs the child's **result schema** — column names, types,
lengths — to draw the join UI and validate field references. It should not need the child's
rows, and it should not need the child's source connection. The schema is the same
`MADDataColumn` description the cache already serializes. This is the "describe without
executing" half of the data-object contract; it is a prerequisite for composition, not an
optional nicety.

The user's decision (2026-11-22) is that **the result schema is the active fields** — the
columns the report's elements, joins, and groups reference — exactly the SELECT list
`MADQueryActiveQueryFields` already computes (`MAD/Source/MADQueryActiveQueryFields.m:27-100`).
No behaviour change: describe returns that list as `MADDataColumn`s without running. The
all-columns form remains a table-preview concern, not a data-object schema. Public column
names should be human-readable: `MADDataColumn.caption` already exists for the display name,
and the SELECT-list builder should set it from the schema field's display name when one
exists, instead of exposing only the internal `"Table0"."Field"` alias.

One more piece of identity is missing: the **root**. `RptqDocument -mainQuery` and
`RptqDatabase -defaultQuery` are both `hasQueries.anyObject`
(`MAD/Source/rptq/RptqDocument+Extras.m:184-186`,
`MAD/Source/rptq/RptqDatabase+Extras.m:88`), and `MADocument -database` takes
`hasDatabaseSchemas.anyObject` (`MAD/Source/MADocument.m:1248-1258`). With several data
objects in one document, the query the viewer and designer render is nondeterministic. Add
an explicit root reference (or a flag) to the document, migrating today's single query to
it. **Builder call.**

## 4. The driver seam for non-SQL sources

### 4.1 Why SQL text is the wrong boundary

Today the report refresh compiles the graph to SQL and calls
`executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
(`MAD/Source/MADOperationRefresh.m:134`). That is correct for a SQL dialect. For a REST API
it forces the driver to parse SQL back into a graph, and the parser's subset does not match
the generated SQL in at least two places: the generator appends a `LIMIT` clause
(`MADQueryFull.m:164`) that `MADSQLParser` rejects (`MAD/Source/sql/MADSQLParser.m:151-154`),
and the designer can generate `NATURAL`/`CROSS` joins
(`RptqQueryLinks+Extras.m:76-86`, `MADQueryLinkType.h:15-16`) that the parser also rejects
(`MADSQLParser.m:330-338`). Reusing the parser would also invert the layering: it lives in
`MAD`, above the drivers, and on Linux `mad` links the drivers whole-archive
(`Linux/CMakeLists.txt:469-474`).

Passing `MADQuery`/`MADQueryFull` directly is not the answer either: `MADQueryFull` is
store-bound, in `MAD`, and computes the active field list only while building SQL. A
driver would compile against the document store.

### 4.2 The plan

Add a driver-neutral value object in `MADAPI`:

```objc
@interface MADQueryPlanTable : NSObject
@property (copy) NSString *name;                        // schema table or object name
@property (copy) NSString *alias;                       // query alias
@property (copy, nullable) NSString *sourceIdentifier;  // nil = schema table
@end

@interface MADQueryPlanField : NSObject
@property (strong) MADQueryPlanTable *table;
@property (copy) NSString *field;
@property (copy) NSString *outputKey; // exactly what the driver names the column
@end

@interface MADQueryPlanLink : NSObject
@property (assign) MADLinkType type;              // moved down to MADAPI
@property (strong) MADQueryPlanTable *leftTable, *rightTable;
@property (copy) NSString *leftField, *rightField;
@end

@interface MADQueryPlanPredicate : NSObject
@property (assign) MADPredicateOperator op;        // moved down to MADAPI
@property (strong) MADQueryPlanOperand *left, *right; // field reference or literal
@end

@interface MADQueryPlan : NSObject
@property (copy) NSArray<MADQueryPlanTable *> *tables;
@property (copy) NSArray<MADQueryPlanField *> *fields;   // the active SELECT list
@property (copy) NSArray<MADQueryPlanLink *> *links;
@property (copy) NSArray<MADQueryPlanPredicate *> *predicates;
@property (copy) NSArray<MADQueryPlanSort *> *sort;      // pushdown hint
@property (assign) NSUInteger limit;
@property (assign) NSUInteger offset;
@end
```

`MADLinkType`, `MADPredicateOperator`, and `MADSortOrder` are currently in `MAD`
(`MAD/Source/MADQueryLinkType.h`, `MADPredicateOperator.h`, `MADSortOrder.h`). A plan in
`MADAPI` cannot reference them until they move down (or the plan defines its own enums,
which duplicates the model). Moving the three pure enums is the right fix.

Execution becomes an optional method on the existing protocol:

```objc
@protocol MADDatabaseDataSource <NSObject>
// existing required methods stay ...
@optional
- (BOOL)executeQueryPlan:(MADQueryPlan *)plan
                 options:(MADDatabaseExecutionOptions *)options
          intoResultTable:(id <MADDataTableWriting>)table
                withError:(NSError **)error;
@end

@interface MADDatabaseExecutionOptions : NSObject
@property (copy) BOOL (^isCancelled)(void);
@property (copy) void (^progress)(double fraction, NSString *node);
@property (strong) id credentials;                  // driver-specific, or a resolver
@property (copy) NSArray<MADMaterializationReference *> *attachments; // SQLite composer
@end
```

The plan stays **logical**; the options carry the execution context. A composing SQLite
driver resolves each table's `sourceIdentifier` to an attachment (path, table, alias)
supplied in `options`. That keeps file paths out of the third-party driver surface and gives
cancellation and per-node progress a home. **Builder call.**

`MADOperationRefresh` prefers it when the driver implements it, and falls back to the
existing SQL path otherwise. The four shipped drivers need no change on day one. A
reference implementation can compile the plan to SQL internally and assert it matches the
current compiler's output, which pins the plan against the existing suite.

### 4.3 Capabilities

The engine and the UI should ask a driver what it can do rather than hardcode driver IDs:

```objc
@interface MADDatabaseCapabilities : NSObject
@property (assign) MADLinkTypeMask supportedLinkTypes;
@property (assign) MADPredicateOperatorMask supportedOperators;
@property (assign) BOOL supportsLimitOffset;
@property (assign) BOOL supportsServerSideSort;
@property (assign) BOOL supportsNativeStatementText; // SQL editor
@property (assign) BOOL isReadOnly;
@property (assign) NSUInteger maximumPageSize;
@end
```

This replaces the hardcoded driver lists and join rules in
`MADDesigner/Source/MADDriverSelectorController.m:64-90,124-140`,
`MAD/Source/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m:19-33`,
`Mac/Source/MADMacConnectionWindowController.m:198-204,359-375`,
`CLI/Source/MADCLIServe.m:277-291`, and
`MADDesigner/Source/MADQueryAddLinkJoinTypeController.m:46-95`. The registry already
enumerates the drivers (`registeredDriverClasses`); the UI can use it plus
`driverName`/`imageIconName` instead of a switch.

### 4.4 What each layer keeps

- **Schema browsing** stays `getTables:` / `getTablesFromConnection:error:` and
  `fieldsForTable:connection:error:`. A non-SQL driver returns `MADDatabaseTable` and
  `MADDatabaseField` values; the reporting user sees them in the query designer exactly as
  schema tables today.
- **The result contract** stays `id <MADDataTableWriting>`; the driver adds
  `MADDataColumn`s and rows keyed by `fieldKeys`/`outputKey`.
- **Grouping, sorting, aggregates** stay in the engine over the cache. The driver returns
  detail rows.
- **Joins** are a capability: native, client-side, or unsupported. Composition is the
  fallback. A driver that does not support joins can still be a source object; the user
  splits the resources into separate objects and joins them in the composing report.
- **SQL text entry and the validation probe** are capability-gated. A non-SQL driver does
  not need to accept a pasted SELECT.
- **Registration** can stay on the connection class (`MADDatabaseDriver`) for compatibility.
  The cleaner long-term contract puts type, identifier, capabilities, and connection
  construction on the `MADDatabase` subclass; that can be added alongside the current
  protocol without breaking the four drivers.

## 5. The generic API driver

The user's "one driver for a whole class of data sources" is a driver whose schema comes
from a **source manifest**, not from the code. The engine sees an ordinary `MADDatabase`;
the manifest tells the driver what tables, fields, endpoints, and pagination rules exist.

Minimal manifest shape:

```json
{
  "name": "eBay Seller",
  "baseURL": "https://api.ebay.com",
  "resources": {
    "listings": {
      "path": "/sell/inventory/v1/inventory_item",
      "rowsPath": "inventoryItems",
      "primaryKey": "sku",
      "pagination": { "limitParam": "limit", "offsetParam": "offset", "max": 100 },
      "fields": {
        "sku": "string",
        "listingId": "string",
        "product.title": "string",
        "price.value": "number"
      },
      "filters": { "sku": { "eq": "sku" } }
    }
  }
}
```

The driver maps the plan to requests:

- `tables[0]` selects the resource.
- `fields` become a select list or are ignored if the API returns whole objects.
- `predicates` become query parameters when the manifest names a mapping; otherwise the
  driver filters locally.
- `limit`/`offset` drive the page loop. With no limit the driver pages until exhausted.
- `links` are native if the API supports them, client-side if the driver implements a hash
  join, or unsupported (the capability disables the link in the UI).
- JSON values map to `MADDataType` through the manifest's field types.

Connection-wise, today's credential row covers the SQL drivers (`host`, `username`,
`password`, `database`). For an API driver that needs a client secret, a refresh token, a
marketplace ID, or a sandbox flag, the user's decision (2026-11-22) is a single **extensible
options field** on the credential: one text column holding JSON (or XML), versioned into the
store format, parsed by the driver — rather than a new store column per driver. The existing
fields map the common case (`host` = base URL, `database` = manifest name, `username` =
client ID, `password` = OAuth token). Sensitive values (client secret, refresh token) belong
in the Keychain, not the document; the JSON holds the non-secret shape plus a Keychain key
reference. This is not a workaround — it is the extensibility point, so a driver does not
change the document format each time it adds a parameter.

Manifest authorship is **bundled/developer-authored first** (the user's decision,
2026-11-22): the driver's developer writes the manifest and ships it with the driver. A
user-facing manifest editor/import and its trust boundary are deferred behind the plugin
system (§5.1). The long-term want — drivers that plug in and are added/removed through the
UI — is recorded here; it is a macOS/Linux/Windows and server concern first, because iOS
has historically blocked loading arbitrary third-party code, so on iOS drivers stay
linked at build time.

The generic driver also carries the non-SQL obligations the plan does not: HTTP client and
TLS, auth refresh, rate limits, retries, cancellation, response-size caps, and error
mapping. Those belong in the driver framework, not the engine.

What the generic driver cannot do is as important as what it can: arbitrary GraphQL, a
source whose rows are not tabular, or server-side joins the manifest cannot express. The
capability object is how it says so, and the query designer is where the user finds out.

### 5.1 Plug-and-play drivers (future, not v1)

The user's larger goal is drivers that install, register, and unregister like plugins, and
that can be added or removed through the UI rather than linked into the app. The registry
already does per-process registration by link (§1 of the driver tutorial); a real plugin
system is a packaging and trust question layered on top: dynamic loading, a discovery
location, signing/sandboxing, and a UI. That is a macOS/Linux/Windows and server feature, not
an iOS one, and it is out of scope for this design's phases. It is noted here so the
driver seam (Phase 0) does not paint itself into a corner: the plan, capability, and
registration types should stay loadable from a dynamically-linked image, which means no
compile-time coupling to a fixed driver list.

## 6. What changes in the store and the format

Minimal shape, following `MAD_DATA_OBJECT.md` §4.4:

- `RptqQuery` gains a name. It is already the definition.
- `RptqQueryTable`'s reference gains a second kind: **a data object (sub-report) in the same
  document**, in addition to a schema table. A v1 row that names a schema table means exactly
  what it means today. A reference to a report in *another* `.mad` file is deferred beyond
  v1; when it arrives it needs a document identity and a path, plus a live/pinned marker.
- The credential gains the extensible **options** text column (JSON/XML) for driver-specific
  parameters (§5), versioned in with the format.
- The materialization address becomes the object's identity hash, not
  `fileURL.lastPathComponent.hash`. The table name stays `t<tag>`; the tag becomes the
  object's identity.
- Each object gets its own schema plist (`.mdcache`) and table. Layout A keeps one file per
  object; Layout B would change the file model.
- The store needs a version step for the new reference and options fields. The existing
  store already has versioning machinery for the SQL-source column (`MADStoreSchema.m:314`),
  so this is a known pattern, not a new mechanism.

The `.mad` document remains a definition and holds **no data, now or later** — that is the
user's explicit call. Snapshots and materializations are companion cache files on the
user's system, and they are what `ATTACH` joins together. The auto-naming of those cache
files moves from the filename hash to a stable object identity so files cannot clash.

## 7. UI, CLI, and the headless engine

- The Add Table panel grows a second kind of source: the document's other data objects
  (sub-reports). The join UI is unchanged; both ends are fields. Cross-document `.mad`
  references are a later addition.
- The designer must be able to show a child's result schema without executing it, and to
  mark a broken reference (changed schema, missing credential) before refresh.
- Refresh needs per-node progress and errors. A child that fails should be named.
- Credentials are per node. Same-document sub-reports keep their credentials in the one
  document, so the policy is per object; cross-document refresh, when it arrives, needs a
  policy for obtaining the child's credentials.
- The CLI and the headless engine walk the same DAG. `MADOperationRefresh` is shared by the
  app, macOS, and the CLI (`CLI/Source/MADCLIDocument.m:120-127`,
  `Mac/Source/MADMacDocument.m:337-360`), so the topological walk belongs there or in a
  helper it calls, not in each front end.
- The macOS app's connection form and the CLI's driver token map need the same
  registry-driven treatment as the iOS selector.

## 8. Phases

Ordered so each phase ships green and the single-query app keeps working. The first phase is
independent of composition and is the one that unblocks non-SQL sources.

| Phase | Work | Depends on |
|---|---|---|
| 0 | **The driver seam.** Add `MADQueryPlan` + value types and move the three enums to `MADAPI`; add the optional `executeQueryPlan:`; add capabilities; make refresh prefer the plan and fall back to SQL. Implement the plan in one existing driver as a reference and pin plan-to-SQL equivalence with tests. No behavior change. | — |
| 1 | **The data-object contract.** Split the SELECT-list construction from execution; add describe/execute; return the result schema as `MADDataColumn`s; make refresh call the contract. This is `MAD_DATA_OBJECT.md` Phase 1. | 0 (overlaps) |
| 2 | **The query owns itself.** `MADQueryFull` uses the query it was given; `dataTableForQuery:` resolves per query; `MADQueryActiveQueryFields` scopes to a query; `MADModelDocument` mirrors any query. | 1 |
| 3 | **Same-document composition.** A query table may reference another data object (sub-report); topological refresh; `ATTACH` support in `MADDatabaseSqlite3`; the composing query executes against the local cache. This is the user's one-portable-file model. | 1, 2 |
| 4 | **Cross-document composition (deferred).** A reference to another `.mad` report; document identity and path resolution; live vs pinned; file coordination; credential policy; missing/renamed handling. Lower priority: same-document composition satisfies the user's model. | 3 |
| 5 | **The generic API driver.** One manifest-driven HTTP/JSON driver; schema from the manifest; plan-to-request mapping; pagination loop; type mapping; the extensible credential `options` field; eBay Seller as the worked example. | 0, 1 (and 3 for joins) |
| 6 | **Surfaces and documentation.** Registry-driven driver lists and join rules; per-node refresh UI; CLI verbs; the driver-authoring tutorial updated with the plan/capabilities seam. | 0–5 |

Not a phase: **plug-and-play driver loading** (§5.1) is a macOS/Linux/Windows and server
feature tracked separately from this design; nothing in Phases 0–6 depends on it, and Phase 0
should merely avoid coupling to a fixed driver list so dynamic loading stays possible.

Phase 0 is the "not far off" part: it is new value types, one optional method, a branch in
refresh, and tests. It does not require the store, the UI, or the composition model to
change. Phase 3 is where the user's `ATTACH` model lands, and it is smaller than it sounds
because SQLite is already a driver and the compiler already sorts a graph.

## 9. Decisions

### 9.1 Builder calls recorded in this document

These are settled from the code or by a design trade-off; they can be revisited, but the
plan assumes them.

1. **Layout A, with `ATTACH`.** One `.maddb` per object; the composing connection attaches
   them. This follows `MADDataTableFast`'s one-table-per-file model. Layout B (several tables
   in one file) is a later refactor, not v1. This supersedes `MAD_DATA_OBJECT.md` §9.2's
   Layout B recommendation for this design.
2. **Composing objects are local-only.** A composing query's tables are data objects; a
   remote table is wrapped in a source object. No mixed remote/local execution.
3. **The parent's child fields are ordinary schema fields.** Synthesize a per-object
   result-schema table/field set from the child's `MADDataColumn`s, and refresh it when the
   child's schema changes. No second field-reference kind.
4. **The root is explicit.** A document-level root reference (or flag), migrated from
   today's single query. Not `hasQueries.anyObject`.
5. **The plan is logical; the execution context is separate.** `MADDatabaseExecutionOptions`
   carries cancellation, progress, credentials, and the SQLite composer's attachment set.
   `MADQueryPlanTable.sourceIdentifier` names the logical source; it is not a file path.
6. **More than ten direct sources is a design-time error in v1.** Raising
   `SQLITE_MAX_ATTACHED` is a three-platform build change, deferred.
7. **Build the plan in parallel with the SQL compiler, then pin equivalence.** Do not
   refactor the SQL compiler to render from the plan until the plan is proven by the current
   suite.
8. **Name the existing `RptqQuery`; do not introduce `RptqDataObject` yet.**
   `MAD_DATA_OBJECT.md` §9.1 recommends this, and it is the smaller migration.
9. **Keep `MADDatabaseDriver` on the connection class for compatibility.** A database-class
   registration contract can be added alongside it later.
10. **The first generic API driver declares joins unsupported.** It relies on composition
    for joins, then grows a client-side hash join behind the capability object. This keeps
    the first driver a single-resource fetch.
11. **Same-document composition ships before cross-document.** Phase 3 retires the
    hardwiring points without path/coordination/credential complexity; cross-document is
    Phase 4.

### 9.2 Decisions answered by the user (2026-11-22)

The user's own words follow; the implications are the author's.

1. **The output schema is the active fields — unchanged.** A data object's output is the
   columns the report uses: the layout elements' fields, the join fields, and the group
   fields, which is precisely the SELECT list `MADQueryActiveQueryFields` already computes
   (`MADQueryActiveQueryFields.m:27-100`). The user: *"it would just be the fields that are
   used in that report."* The all-columns form is a table-preview concern only. Describe
   returns that same list as `MADDataColumn`s without executing. Two consequences are noted
   as future features, not part of this work: **human-readable column names** (set
   `MADDataColumn.caption`, which already exists, instead of exposing only the
   `"Table0"."Field"` alias), and **preview paging** (the preview currently caps at ~512 rows
   and should page through the full result — the user flagged this for the wishlist, which
   is the user's `TODO.md`, not this document). The zero-row rule still applies: a source
   object materializes its full schema even when it returns no rows.
2. **Drivers are expected to run on every platform; plug-and-play is the goal.** The user:
   *"That's really up to the person who writes the driver, but yes I'd expect so."* The
   headless engine and the same DAG hold on Linux/Windows; whether a *given* driver runs
   headless is its author's concern. The larger want — *"drivers could be plug-and-play…
   add and remove drivers through the UI"* — is §5.1, a future feature and a
   macOS/Linux/Windows/server concern, because iOS has historically blocked loading arbitrary
   third-party code.
3. **Snapshots live in the companion cache, never in the `.mad`.** The user: *"The `.mad`
   file only describes the schema… that shouldn't change… It would be in whatever the cache
   file is right now… the cached files that are Sqlite3 data stores, and that is what would
   be `ATTACH`ed together."* So the archive stays definition-only; a pinned snapshot is a
   retained `.maddb`/`.mdcache`, and materialization naming moves to a stable object identity
   to avoid clashes.
4. **Manifests are bundled/developer-authored first.** The user: *"your answer is correct…
   the idea was always that new drivers could be added through some plugin system… I don't
   believe you can have plugins in iOS."* v1 ships a manifest-driven driver with
   developer-authored manifests; a user-facing manifest editor/import and its trust boundary
   ride behind the plugin system.
5. **Composition is intra-document first — sub-reports in one portable file.** The user:
   *"maybe you could add 'sub-reports' to the mad document… the idea would still be one
   portable file."* A `.mad` contains several report/query definitions; each runs to a
   SQLite table; the composing report `ATTACH`es them. This preserves the one-file property
   and removes the iOS cross-file re-authorization problem for v1. Cross-*document*
   references are deferred behind same-document composition.
6. **Credentials grow an extensible options field.** The user: *"we could design one and add
   it to the report format… perhaps all in one database field, that we parse out somehow
   (like JSON or XML) so it can be extensible."* One text column holding JSON, versioned into
   the store, parsed by the driver. Sensitive values (client secret, refresh token) go in
   the Keychain; the JSON holds the non-secret shape plus a Keychain reference.

### 9.3 Defaults the author is assuming (builder calls)

- **Live is the default; pin means retain the cache snapshot.** Live executes the child on
  refresh; pin reuses the retained materialization. Both read from the cache directory.
- **Refresh policy.** Recompute every node on refresh (the user's bottom-up description). A
  freshness/cache-reuse knob for expensive API children is a later addition behind the
  capabilities object.
- **Naming.** "Data object" is the store/protocol term; "sub-report" is the user-facing term
  for a referenced object in the composition UI.

## 10. Risks, and what makes it not a one-liner

- **The three hardwiring points** (`MADQueryFull`'s re-read, the one-slot data table, the
  unscoped active fields) are load-bearing for today's single-query app. They must fall
  before a second query, let alone a nested one, can execute.
- **The cache address is the filename hash** and the cache is per-device. Addressability is
  a prerequisite, not a detail.
- **Cross-document references** bring path resolution, iCloud eviction, file coordination,
  missing children, and credentials for a source the parent does not own. This is the most
  product-heavy part.
- **`ATTACH` has a limit** (`SQLITE_MAX_ATTACHED`, default 10) and needs alias/name
  management and path quoting. Do not discover it in production.
- **Full refresh cost.** The cache design is pull-everything by design; a DAG multiplies
  that. A cache/freshness policy is part of the design, not an optimization.
- **API rate limits and data volume.** A driver that pages an API for every refresh needs
  retries, caps, cancellation, and a visible progress story.
- **Schema drift.** A child's columns can change; the parent's query then references fields
  that no longer exist. Design-time validation and refresh-time errors are required.
- **Driver API stability.** Third-party drivers compile against `MADAPI`; the plan and
  capability types become a public surface. Version them deliberately.
- **Testing matrix.** Four platforms (iOS, macOS, Linux, Windows), SQL and non-SQL drivers,
  same-document and cross-document composition. The phase order is the mitigation: one new
  axis at a time.

## 11. What this is not

- **Not a federation engine.** Nothing new talks to MySQL and an API in one statement. Each
  object executes against its own source; the join is local.
- **Not a second query implementation.** The graph, the compiler, the drivers, the result
  table, and SQLite's join engine already exist.
- **Not a change to the pull-everything cache.** The two-pass cache is load-bearing
  (`docs/05-companion-files.md` §5.1).
- **Not scheduled.** This is the design record for future work. `docs/project/registers/TODO.md` is
  the user's own wishlist (the preview-paging wish belongs there), `TASKS.md` is the
  engineering queue, and `ROADMAP.md` says what is picked up next. Nothing here is started on
  an agent's initiative.

Two future features are named here but belong in the user's tracking files, not this design:
the **preview paging** fix (§9.2.1) and the **plug-and-play driver system** (§5.1). This
document is where their shape is recorded; it does not schedule them.

## 12. The through-line

The query tab already builds the function. The refresh chain already compiles and executes
it. The result table already is a schema and a result set, on disk as SQLite. SQLite is
already a driver. The drivers already return tables. What is missing is the name, the
address, the describe half, and the structured query that a non-SQL driver needs instead of
SQL text. Those are additive: a plan value object, a capability object, an optional
execution method, a stable object identity, a second kind of table reference, a topological
walk, and `ATTACH`.

The composition is then the existing pipeline addressed by something better than a filename
hash. The non-SQL driver is the same pipeline with a different execution body. Neither is a
new engine; both are what the abstractions were built to allow.
