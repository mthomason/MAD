# The Data Object — a report's definition, its schema, and its result set

**Scope:** the concept raised 2026-10-16 — what a data object is, how it is represented in
this codebase, and what formalizing it takes. The multi-source / subreport rig-up described
in the same conversation is written down here as a consequence of the contract, deliberately
not built.
**Date:** 2026-10-16, read at `445794e11`.
**Status:** design document. It proposes; it implements nothing, and nothing here is
scheduled. `MAD_FUTURE.md` §1 — "a report is a function from data sources to a table" — is
the vision this file makes concrete and names the code for.

---

## 1. The idea, and what it is not

Today the user designs an ad hoc query against one database (MySQL, SQL Server, or Sqlite3),
it returns a table of data, and the report is built on that data by the layout tools. The
report is query plus layout. The generalization is to take the query half and make it the
object:

> A data object is a named definition that produces a **schema** and a **result set** — a
> report's query, separated from its layout and given an identity, so its output can be
> refreshed, addressed, and used as a source by another data object. A report is a data
> object plus a presentation bound to the object's columns.

The user's own words (2026-10-16): *"something that returns a schema of sorts and a result
set, whereas the report is ad hoc query, reporting, and design."*

Three consequences, each pursued below:

1. **The query becomes the product boundary.** The same object serves the designer (what the
   MAD Query tab edits), the viewer (what refresh executes), the CLI (what `mad refresh`
   runs), a future webserver (what an endpoint executes), and an AI (what it drafts and the
   engine validates). One definition, many consumers — which is only true once the object has
   a name and a schema of its own.
2. **Objects compose.** *"The idea would be to link multiple ones together. In the reporting
   world, this would be subreports"* (user). In data terms it is a DAG of derived tables:
   the output of one object is a table to another, exactly as a schema table is today.
3. **Sources multiply as a consequence, not as a feature.** One object per source database —
   each already carries its own driver and connection — materialized, then joined by their
   outputs. The user's sketch: *"you would query MySQL in a subreport, and you would query
   SQL Server in a subreport… and then you could link those reports together as tables in the
   query designer by their output."* `MAD_FUTURE.md` §1 says the same thing: no federation
   engine needed; the snapshots *are* the federation.

What it is explicitly **not**:

- Not a federation engine. Nothing new talks to MySQL and SQL Server in one statement; each
  object executes against its own source, and the join happens over the already-local results.
- Not a second query implementation. The SQL generator, the drivers, the result table, and
  the SQLite join engine all exist; §5 is a rig on top of them.
- Not a change to the two-pass pull-everything cache paradigm. The cache is load-bearing and
  deliberately large (`MAD_FORMAT.md` §5.1); a data object produces exactly what the cache
  already holds today.

## 2. Vocabulary, because "schema" is four different things in this codebase

| Term | What it is | Today's classes |
|---|---|---|
| **Source schema** | The tables and fields of a database the user can query | Live browsing: `MADDatabaseTable` / `MADDatabaseField` (`MADAPI`). Snapshot: `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`, imported once at document creation |
| **Definition** | The query graph: which tables, which fields, the joins, filters, groupings, sort | `RptqQuery` + `RptqQueryTable` / `RptqQueryField` / `RptqQueryLinks` / `RptqQueryPredicate` / `RptqQueryGroup` |
| **Result schema** | The columns of the output: name, type, native type, length/precision, primary key, not-null | `MADDataColumn` (one per column), carried on the table |
| **Result set** | The rows | `MADDataTable` class cluster; materialized as `MADDataTableFast` |
| **Materialization** | The result set on disk: the SQLite table and its serialized schema | `<tag>.maddb` (SQLite) + `<tag>.mdcache` (plist, `MADDataTable -copyPlist`) in the document's cache directory |
| **Snapshot** | `MAD_FUTURE.md`'s word: a materialization made named, versioned, and addressable | Does not exist; §4.3 is how it starts |
| **Store schema** | Unrelated to all of the above: the document's own storage format | `MADStoreSchema` (`MAD/Source/rptq/store/`) |

The document today holds definitions and layouts; materializations live beside it, keyed by
the document (not by the definition). That split is the right one — `MAD_FORMAT.md` §5 — and
this design keeps it.

## 3. How the idea is represented today

Each piece of a data object already exists, in a different layer, built for a different
purpose. What follows is the exact state of each, with the seam that formalization would
pinch.

### 3.1 The definition exists — `RptqQuery` and its graph

The query graph is complete enough to compile: tables (`RptqQueryTable`, with `alias` and a
`dropIndex` so one schema table can be included several times), projections
(`RptqQueryField` — schema table + schema field ids), joins (`RptqQueryLinks`, with a link
type), filters (`RptqQueryPredicate`), groupings (`RptqQueryGroup`, driving sort descriptors
via `RptqQuery -sortDescriptorsForDatabase:`), and a vestigial sort row (`RptqQuerySort`,
read only by debug descriptions). The designer edits it through the `MADModel*` read model
("write through `Rptq`; read and observe through `MADModel`" — `MADModel_Layer.md`).

A grouping is a query-level definition, not a report section. `RptqQueryGroup.hasField`
names the field the query groups by and `sort` its direction. For the query to run, every
group's field must belong to a query table the document selects
(`hasField.inQueryTable`): the grouping is materialized as an ordered key over the result
rows (`-sortDescriptorsForDatabase:`), and the formatter compares that key to find group
boundaries. A report group header/footer section is only the presentation of that group —
it may contain no element that displays the grouping field, and the grouping still occurs.
No layout can supply a missing grouping field, so a group with a nil field, or a field not
backed by a selected query table, is an invalid document. The designer still builds and
labels such a section so the broken group can be seen; query execution and rendering refuse
it with `NSInvalidArgumentException` and log the group.

Two facts about its identity:

- A `RptqQuery` hangs off a `RptqDatabase` row, and reaches the document through
  "the first one of each": `RptqDatabase -defaultQuery` is `hasQueries.anyObject`
  (`RptqDatabase+Extras.m:88`), `RptqDocument -mainQuery` likewise (`RptqDocument+Extras.m:184`).
- The store already permits many: `MADModelDocument` builds **one `MADModelDatabase` per
  `RptqQuery` row** (`MADModelDocument.m:210-240`), with the code's own comment that "current
  versions of the software only use one database and query." The cardinality is a convention
  of the app's flows, not of the store.

### 3.2 The compiler exists — `MADQueryFull`

`MADQueryFull -copySQLWithManagedObjectContext:error:` (`MADQueryFull.m:133`) builds the SQL:
the projected columns come from `MADQuerySelectExpressionActiveFields`, which asks
`MADQueryActiveQueryFields` for every field the report's *elements*, links, and groups
reference; FROM/JOIN is compiled from an `MTGraph` of tables and links, topologically sorted
(`:170-204`); predicates and the literal quoting go through `MADDatabase`
(`newSafeIdentifier:`, `newSafeLiteral:`); `LIMIT` via `sqlLimitClause:`.

This is the deterministic, owned SQL generation `MAD_FUTURE.md` §3 counts as a differentiator
— it exists, and it is headless (in the Linux build, `MADSources.cmake:93`).

**But it is welded to the document.** `MADQueryFull` stores the query it was initialized with
in `queryObject` (`:79`) and **never uses it**: the SQL path re-reads the document's first
database and first query (`:147-149`). And it does not implement `-getSql:error:` (the base
returns `@""`, `MADQuery.m:48`), so the generic `MADDatabase -executeQuery:withError:` path
cannot run the document's main query at all. The query object you hand it does not determine
what runs.

### 3.3 The execution seam exists — `MADDatabase`

The abstract point is
`-[MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADAPI/Source/MADDatabase.m:147`, overridden by all three drivers). Its destination is
typed `id <MADDataTableWriting>` — *any* writable table, not a table class. The fill contract
is uniform across the drivers: `removeAllObjects` → `addColumn:` → `beginBulkInsert` →
`addRowWithDataForFieldKeys:` → `endBulkInsert` (`MAD_DATA_OBJECT`'s drivers: MySQL
`MysqlFetch+DataTable.m:148-235`, SQL Server `MADDatabaseSQLServer.m:485-571`, Sqlite3
`MADDatabaseSqlite3.m:474-540`).

The drivers also already prefer a query's own target table over the document's, when the
query conforms to `MADQueryDataTableProtocol` (`MADQuery.h:28-50`; every driver's
`-executeQuery:` checks it — e.g. `MADDatabaseMySQL.m:331-339`). Multiple result tables per
process are an intended extension point, exercised only by the sample-data query family.

The document-level stitching is `MADOperationRefresh` (`MADDesigner/Source/MADOperationRefresh.m`,
131 lines, zero UIKit): credentials in, `document.mainQuery` → SQL, `document.database`
connects, execute into `document.dataTable`, `dataTableMakeCache` writes the `.mdcache`,
`document.refreshed = YES`. It is also the CLI's refresh verb, compiled across the target
boundary by `CLI/build.sh`'s `REFRESH_SOURCES` (`ROADMAP.md` §3.4). It is *refresh +
persist + publish*, not *execute*: it is hardwired to the shared document state, discovers
credentials by inspecting `self.dependencies`, and mutates the document.

### 3.4 The return value exists — `MADDataTable` and `MADDataColumn`

`MADDataTable` (`MADFoundation/Source/MADDataTable.h`) is the class cluster whose entire job
is "schema plus rows": metadata plus persistence on the base, storage per subclass
(`MADDataTableVirtual` in memory, `MADDataTableFast` over SQLite). The schema object is
`MADDataColumn` — `identifier`, `fieldName`, `caption`, `type` (`MADDataType`), `nativeType`,
`dataLength`, `dataPercision`, `isPrimaryKey`, `isNotNull`, `isAutoIncrement`, `defaultValue`
— a first-class, serializable column description.

And the schema is already separable from the rows on disk: `-copyPlist`
(`MADDataTable.m:238-253`) serializes name + column keys + column plists + row counter and
**explicitly no rows** — that is exactly what the `.mdcache` file is, written and read by
`MADDataTableFast` (`-copyPlist` / `-loadWithPlist:`; `MAD_FORMAT.md` §5.3).

What is missing at this layer:

- **No schema-only API.** Nothing returns a query's result schema without executing it.
  Schema and data are one object, never two — the schema is discovered *from* the rows.
- **Zero-row Sqlite3 results lose their schema entirely.** The Sqlite3 driver discovers
  columns only inside the first `SQLITE_ROW` iteration (`MADDatabaseSqlite3.m:496-535`), so an
  empty result produces a table with no columns and no DDL. MySQL and SQL Server add columns
  from result metadata before any row arrives, so the gap is Sqlite3-specific.
- `MADDataTableFast`'s `columnKeys` are generated `c<hash>` names, not field names; the usable
  schema surface is the `columns` dictionary of `MADDataColumn`. And `for (x in fastTable)`
  silently yields nothing — the base returns 0 items and Fast does not override
  `countByEnumeratingWithState:`; callers must use `objectEnumerator`.

### 3.5 The materialization is a SQLite table today

`MADDataTableFast` is not an abstraction over a table; it *is* the table. Each instance owns
one physical SQLite table `t<tag>` in `<tag>.maddb` (`-tableName` `MADDataTableFast.m:498`,
`-filenameCacheMadDB` `:399`), with columns `c<hash-of-fieldName>`. A second connection
(`databaseForSelects`) runs the select side. Grouping is indexes on that one table
(`-sortUsingDescriptors:` `:737`, `-setupGroupKeyIndexes` `:545`, one index per group prefix
level), and aggregates are SQL over the cache (`MADQueryCacheAggregateFunction`, driven by
`MADocument -dataForRows:column:groups:function:groupBy:`). **No `GROUP BY` is ever generated
for the source database** — verified: the string does not appear in any source file. The
source is queried flat; everything grouped or aggregated is computed locally, over the
materialization, by Sqlite3.

Two tell-tale stubs show the architecture has reason to want *many* tables: the class factory
`MADDataTable+Constructor` (`newDataTableOfType:withObjectID:cacheDirectory:` — physical maps
to `MADDataTableFast` with the id as tag, `:56-78`) makes second and third tables cheap by
construction; and `-cacheTableNameForGroupLevel:` (`MADDataTableFast.m:813`) would name a
table `s<level>` per group level — it has **no callers**; the per-grouping tables it implies
never materialize.

**The address is the filename.** The document's table is created with
`initWithId: fileURL.lastPathComponent.hash` (`MADocument.m:269-283`); the cache directory is
named `dataTableIdHash` (`MADURLFactory newURLCacheFilesDirectoryForFilename:`). One result
table per document; its name changes when the document is renamed; nothing can point at it.

### 3.6 What is missing, in one table

| Layer | Exists | Missing for a data object |
|---|---|---|
| Definition | Full query graph; read model; store permits many queries | A name and identity of its own; a source reference that can be another data object |
| Compiler | Deterministic SQL from the graph | Freedom from "the document's first query"; a schema-only path |
| Execution | Any `MADDataTableWriting` target; three drivers; per-query target tables | An execute that is not refresh — no mutation of the document, credentials passed not discovered |
| Result value | `MADDataTable` + `MADDataColumn`; schema-only persistence (`-copyPlist`) | A schema-without-execute API; the zero-row schema loss |
| Materialization | Real SQLite tables `t<tag>`; local grouping and aggregates | Tag = filename hash; one table per document by convention |
| Binding | Layout → `referencesQueryField` → resolved at render by `MADDocumentObjectDataReference*` | Binding to *a* data object rather than *the* document's single query |
| Address | — | Everything |

Three hardwiring points are the concrete blockers, and all three are visible in code:

1. `MADQueryFull` ignores its own query object (`MADQueryFull.m:147-149`).
2. `MADDocument -dataTableForQuery:` returns `self.dataTable` for `MADQueryFull` and nil for
   everything else (`MADocument.m:908`) — a one-slot switch.
3. `MADQueryActiveQueryFields` scans **all** elements, links, and groups in the store with no
   query scoping (`MADQueryActiveQueryFields.m:27-99`), under its own header FIXME: *"Right
   now the software only handles one query object."* A second query's fields would leak into
   the first query's SELECT list.

## 4. The contract

### 4.1 Shape in code (proposed, illustrative)

Two halves, deliberately separate:

```objc
@protocol MADDataObjectSchema <NSObject>            // describe: no database needed
- (NSArray<MADDataColumn *> *)resultSchema;          // columns, types, from graph + snapshot
@end

@protocol MADDataObjectExecuting <NSObject>          // execute: yields the materialization
- (nullable MADDataTable *)executeIntoDataTable:(nullable MADDataTable *)target
                                      credentials:(MADCredentials *)credentials
                                            error:(NSError **)error;
@end
```

The names are illustrative; the split is the point. **Describe** must work with no
connection, no credentials, and no rows — from the graph plus the stored schema snapshot —
because that is what the designer draws, what the AI validates against, what a webserver
lists, and what a renamed document cannot corrupt. **Execute** must take a target table and
credentials as arguments and return the table — no document mutation, so `MADOperationRefresh`
shrinks to "call execute, then persist, then publish," and the CLI, a server, and a test all
call the same thing.

### 4.2 Schema without executing

This is the first honest proof the contract is real, because it is *derivable* and nothing
derives it today: the result schema is exactly the SELECT list `MADQueryFull` already
computes — the active query fields, aliased `Table.Field`, plus whatever the aggregates and
groupings project. The types and widths come from the schema snapshot
(`RptqDatabaseSchemaField`); aggregate columns from `MADAggregateFunctionType`. The work is to
split the SELECT-list construction from execution and return it as `MADDataColumn`s. It also
fixes the zero-row Sqlite3 gap for free, the moment columns exist before rows: the drivers
already `addColumn:` before `addRow:`, and the table's DDL is created on the first column
(`MADDataTableFast.m:526-543`).

### 4.3 Identity and address

A data object needs a name that survives renames and an address that survives regeneration:

- **Identity:** a store row's `identifier`, like every other `Rptq` entity, plus a
  human-facing name. The materialization tag becomes the object's identifier hash, not
  `fileURL.lastPathComponent.hash` — which retires, for this purpose, the filename-keyed
  addressing (`MAD_FORMAT.md` §5.3 hazard; `MAD_FUTURE.md` §2.2's "content hash the key"
  note is the same fix at the render layer).
- **Address:** the cache directory already holds one `.maddb` per document; the natural
  formalization is one `t<tag>` table **per data object** in it (tags already make them
  distinct), each with its own `.mdcache`-style schema plist. The per-object `.maddb` file
  (the `t<tag>`/`<tag>.maddb` pairing taken literally) is the alternative; §5.1 says when it
  matters.

### 4.4 Where the store changes — and what it already allows

Minimal shape, recommended:

- `RptqQuery` gains a name (it is already the definition; nothing moves).
- `RptqQueryTable`'s reference — today a schema table id within one `RptqDatabase` — gains a
  second kind: **another data object**. This is the single schema change composition needs,
  and it is additive: a v1 row with a schema-table reference means exactly what it means today.
- Multi-source needs no store change at all: the store already supports many `RptqDatabase`
  rows, each with its own query (one `MADModelDatabase` per `RptqQuery`, §3.1). What today's
  documents have is one of each because the creation flow makes one; the schema was
  future-proofed in 2017 and is still waiting.

The heavier alternative — a new `RptqDataObject` entity owning the definition, with
`RptqQuery` demoted — is cleaner naming and a bigger migration. Recorded as decision 9.1.

## 5. Composition — the subreport rig, documented, not built

**This section is deliberately not scheduled** (the user, 2026-10-16: *"I don't want to rig it
up… but I want to document this idea"*). It exists so that when it is wanted, it is a plan
rather than a discovery.

### 5.1 The mechanism, precisely

1. Each data object executes against its own source — its own `RptqDatabase`, driver, and
   credentials — and materializes into its own SQLite table (a `t<tag>` in the document's
   cache, per §4.3).
2. The composing object's query graph is unchanged in kind: its "tables" include data objects;
   joins, filters, and aliases all apply, because on both sides a table is a set of named
   columns.
3. Execution is topological over the object DAG (the same algorithm `MADQueryFull` already
   runs on the join graph, `MADQueryFull.m:202`): sources first, composing object last, its
   result materialized like any other.
4. The composing object executes **against the cache, not a remote database** — it is a query
   whose "database" is the `.maddb`. `MADSqlite3` is already a full `MADDatabase`, so the
   driver for this step ships today. One `.maddb` holding several `t<tag>` tables needs no
   `ATTACH` at all; `ATTACH DATABASE` is the variant for **separate files** — one `.maddb` per
   object, or objects from *different documents*, which is the case where the subreport
   boundary is a file boundary and `ATTACH` (or a copy-in) is the only join route.

The one-line version, which is the whole reason this is a rig and not a project: **the
result of every query is already a SQLite table, and SQLite is already a driver.** The
federation engine is in the box; it is currently addressed by a filename hash.

### 5.2 What would be built, if wanted

1. The contract of §4 (describe/execute, identity, address) — a prerequisite, not a phase.
2. The source kind: `RptqQueryTable` → data object; SQL generation resolves it to the
   object's materialization table instead of `db.table`.
3. The execution order: walk the DAG; refresh stale objects; then the composing query.
4. The designer's telescoping (the user's word): in the Add Table panel, a second kind of
   source beside schema tables — the document's other data objects, or a subreport box that
   lists the other object's output fields. The join UI is unchanged; both ends are fields.
5. `ATTACH` support in `MADDatabaseSqlite3` if and when cross-file composition is wanted.

### 5.3 What makes it not a one-liner

Recorded so the estimate stays honest: the three hardwiring points of §3.6
(`MADQueryFull`'s re-read, the one-slot `dataTableForQuery:`, the unscoped
`MADQueryActiveQueryFields`) each have to fall before a second query — let alone a *nested*
one — can execute; `MADModelDocument` mirrors only `firstQuery` on the change path
(`MADModel_Layer.md` §8); and `RptqQuery -sortDescriptorsForDatabase:` groups against the
document's single cache. None is hard; all are load-bearing for the current single-query app.

## 6. The CLI, the webserver, and the engine

The user's question, 2026-10-16: *"the CLI is really for testing, understanding, and future
use… it's important, but the goal is to have something that can be called from the webserver,
and I don't know if the CLI is the best way to do that."*

The honest answer, as the artifacts stand:

- **The CLI is a client of the engine, not the engine.** Its six verbs —
  `inspect`, `schema`, `query`, `refresh`, `export`, `write` — are sample call sites of the call chain
  in §3: open the container, read the store, generate SQL, execute into a table, render. What
  a webserver needs is the same chain behind a stable entry point; a subprocess is one
  binding of that chain (the shape `MAD_LINUX.md` §2 sketches: `mad --format json` as a
  subprocess), a linked library another, an in-process Objective-C/Swift API a third.
- **The entry point is the missing piece, and it is named.** There is no UIKit-free
  top-level class today that opens a `.mad`, runs the query, and returns rows: on Apple,
  `MADocument` is a `UIDocument`; the CLI's `MADCLIDocument` is headless in *behaviour* but
  waits on the run loop for that UIDocument.  (Phase D settled the headless side:
  `MADHeadlessDocument` is the entry point on Linux, and since Phase E it carries the render
  half too — `MADDocumentRenderProtocol`, `MADReportPageBuilder` — so `mad export` runs
  there.  `MAD_LINUX.md` §9.)  The contract of §4 is what such an entry point would expose:
  open → list data objects → describe → execute → (schema, rows).
- **The wire format is one decision, not three.** Schema + rows as JSON is the same shape as
  the JSON export (`MAD_CLI.md` §8.3, `ROADMAP.md` decisions table) and the structured output
  an AI layer validates (`MAD_FUTURE.md` §7). `MADDataColumn` is already a plist-able column
  description; the `.mdcache` plist is already a serialized result schema. Design the JSON
  shape once, in the open, and the export, the API, and the AI all consume it.
- **What the CLI stays responsible for** is the discipline `ROADMAP.md` Track 3 set: the
  document visible with the app out of the way, the exit codes (0–5) as the error vocabulary,
  the round-trip fixtures that pin the format. Those do not move to the webserver; they are
  how the webserver's engine stays honest.

The measured facts behind "this is cheap once the contract exists": the data path is already
headless — SQL generation, the store, `MADDataTableFast`, and all three drivers compile on
Linux today, with 119 test executables and 1,136 tests green (`Linux/README.md`), and since
Phase D the CLI builds and runs in that image (`inspect`, `schema`, `query`, `refresh`,
`export`, `write`). So the ordering that follows is the contract first, entry point second,
front-ends third — and it makes "CLI or webserver?" a question with a two-line answer
instead of an architectural fork.

## 7. What it would take — in phases, on the existing tracks

Ordered so the app keeps shipping and the suite stays green throughout; each phase names the
change of §3 it retires.

| Phase | Work | Retires |
|---|---|---|
| 1 | **The contract.** Split `MADQueryFull`'s SELECT-list construction from execution; return it as `MADDataColumn`s. Add the describe/execute protocols; make `MADOperationRefresh` call them. No behaviour change. | No schema-only API; zero-row Sqlite3 schema loss |
| 2 | **The query owns itself.** `MADQueryFull` takes the query it was given (no document re-read); `-dataTableForQuery:` resolves per query; `MADQueryActiveQueryFields` scopes to a query; `MADModelDocument` mirrors any query. One document, many objects. | All three hardwiring points of §3.6 |
| 3 | **Identity and address.** Name the object in the store; tag materializations by object identifier, not filename; one result table per object in the cache; schema plist per object. | Filename-hashed materialization; one-table-per-document |
| 4 | **The bind and the surfaces.** Layout binds to a data object's schema; the CLI grows `describe`; the JSON shape is fixed once (export + API + AI). | Binding to "the document's query" |
| 5 | **Composition** (§5), only when asked. | — |

Phase 1 is the design's real payload and the smallest: it needs no store change, no UI
change, and no new format — it re-sorts code that already exists, and it is provable by the
current suites plus a schema assertion on a zero-row query. Phases 2–4 are the same idea
applied to the layers that hold the single-query assumption. Phase 5 is the rig, documented,
unscheduled.

## 8. What not to do

- **Do not build the multi-source rig now.** The user's decision, 2026-10-16; this document is
  the record, not a queue item. (`TASKS.md`/`BUGS.md` conventions apply: nothing here is
  started on the agent's initiative.)
- **Do not compress or redesign the cache.** It is load-bearing, the two-pass design needs it,
  and `MAD_FORMAT.md` §5.1 is the standing analysis.
- **Do not build a federation engine.** Per §1 and §5, the materializations are the
  federation.
- **Do not implement a second SQL generator or executor.** Everything but the addressing and
  the ordering exists.
- **Do not touch the deliberately-dead things** (`MADQueryDefinition*`, `RptqQuerySort`,
  `MADQueryFullTableEnumerator`, the free-text override fields) as part of this — they are
  separate tidy-up decisions.

## 9. Open decisions

1. **The store shape.** Name the existing `RptqQuery` (minimal, recommended) or introduce
   `RptqDataObject` as its own entity (cleaner, larger migration)?
2. **The materialization unit.** One `.maddb` per document with one `t<tag>` per object
   (recommended — no `ATTACH`, no new files), or one file per object (`ATTACH` when
   composing)?
3. **What the snapshot is.** `MAD_FUTURE.md` §2.2 makes the materialization pair
   (`.maddb` + `.mdcache`) the shareable artifact. Under this design, is the unit of sharing
   the data object's result, or the document?
4. **What a data object's schema exposes outward.** `MADDataColumn` is rich;
   name/type/length is what a webserver and an AI need. The JSON shape (decision once, §6) is
   where this gets fixed.
5. **Naming.** "Data object" is the user's term and this document's; `MAD_FUTURE.md` calls the
   industry artifact a *model*. One of the two should win before anything is built, because
   it lands in store entities, protocols, and the CLI's verbs.

## 10. The through-line

The query tab already builds the function; the refresh chain already compiles and executes it;
the result table already *is* a schema and a result set, on disk as SQLite; the drivers that
would join two of them already exist and already compile on Linux. What none of it has is a
name, an address, and a describe half — the three things that turn "the report's query" into a
data object, and a data object into a table another data object can use. The rest — subreports,
multiple sources, a webserver standing on the engine — is composition over that, and composes
precisely because nothing new has to be invented: it is the existing pipeline, addressed by
something better than a filename hash.
