# MAD same-document composition implementation plan

> **The normative execution model is [MAD_COMPOSITION_SPEC.md](MAD_COMPOSITION_SPEC.md).**
> Read it first. This file is the implementation plan and progress record against it.

Baseline: [mthomason/MAD master at 2d87f220](https://github.com/mthomason/MAD/tree/2d87f220b972397a325a9d225df8b4ee9acb6d6d). Audited 2026-11-23 against `feat/query-composition` at `5dba230eb`, which already carries the versioning and build-identity work; the revisions below are what that audit and the SQLite spike changed.

## Target behavior

One .mad document contains source queries and one explicit report root. For example, a SQL Server query returns invoices, a PostgreSQL query returns payments, and the root joins their materialized tables in local SQLite. **Every node is a full report:** it has an editable definition, an output schema, its own layout, and its own Viewer/print/export. The root is the document's default report and default output; it is not the only node that can be designed or viewed. The .mad file contains the definitions, layouts, and connection references. Rows and page caches stay in companion storage, and credential secrets stay in the platform credential store or runtime inputs.

Deliver two upstream queries and one composer end to end first. Represent dependencies as a DAG so the model can grow to additional dependencies and nested composers. Each child keeps its layout and data when it is combined; per-node Designer/Viewer is required, not deferred. Defer cross-document links, pinned snapshots, and a generic API driver. The current driver execution contract is sufficient for this SQL-only milestone. The published design puts a structured driver plan in Phase 0. Treat that as a prerequisite only if the composition spike exposes a concrete dependency. [Vision](https://github.com/mthomason/MAD/blob/master/docs/vision.md) · [Multi-source design](https://github.com/mthomason/MAD/blob/master/docs/developers/multi-source.md#8-phases)

## Decision recorded 2026-11-26 — a node is a report (final)

**Final, not open.** Every node in a composition owns its query definition, its materialized
result table, and its own report layout. Combining reports carries each child's layout with it.
The root is the document's default node; any node can be designed, viewed, printed, and
exported. This supersedes the earlier target text that made the root result the only consumer
and deferred independently rendered subreports.

The normative statement is [`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md) §0. The
implementation scope — store revision, import, query-scoped layout/describe/result reads, and
the Windows/macOS/iOS surfaces — is
[`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md). The current root-only behavior
(one layout, import drops source layouts, root-scoped serve) is a known gap, not a design
choice.

## 0. Before implementation

1. **Record the contracts.** Settle the root and source identity rules, the projected column identity and type rules, the cache publication boundary, the supported document ladder, and the Windows client/engine handshake. Add these decisions to the existing design record when implementation is authorized. Record how a required child field behaves when a user removes it. Recommend rejecting that edit with a list of dependents and allowing undo or explicit relinking.
2. **Capture a reproducible baseline.** Archive a shipped single-query SQLite fixture, one SQL-entry fixture, and existing SQL Server and PostgreSQL fixtures. Capture generated SQL, result schema and rows, grouping and aggregate results, page count and representative page contents, and stable exports. Include a report with an empty result. Use stable ordering where an assertion depends on order. Record the tested engine revision. Run the Linux suites and CLI, Mac and iOS engine tests and smoke paths, and WPF against a Windows engine built from the same commit. The current hosted Windows job fetches the v0.7.0 engine asset, so green WPF CI alone cannot validate new Objective-C engine changes. Add a candidate-artifact lane or a documented workstation build and parity gate before integration. [CLI fixtures](https://github.com/mthomason/MAD/tree/master/CLI/Fixtures) · [Windows verification](https://github.com/mthomason/MAD/blob/master/.github/workflows/windows.yml)
3. **Do a focused SQLite spike.** Done 2026-11-23 on this branch; the script and outputs are scratch, not committed. Two portable SQLite fixtures were refreshed through `mad refresh` (the real `MADDataTableFast` path), and a dedicated connection attached the two committed `.maddb` files read-only:
   - **Attach, name resolution, join: pass.** `file:…?mode=ro` attaches both results; each `.mdcache` plist maps a logical identifier to its physical `c<hash>` column; a join on `"Invoice0"."InvoiceId"` returned 676 rows, exactly `Σ count(i)²` over the 76-row input, and a filtered join returned the expected 81. An unqualified column was rejected as ambiguous, so the root must qualify every column by source alias.
   - **Collation.** The row table's indexes use MAD's `LSASC` collation. A raw sqlite3 handle fails on `ORDER BY … COLLATE LSASC` and on any write that maintains those indexes; `MADDatabaseSqlite3` registers it (`MADDatabaseSqlite3.m:267`). The composer must run on a MAD connection or register the collation itself, and its root ORDER BY/grouping will name `COLLATE LSASC`.
   - **Journal and handles.** At rest the file is rollback (`delete`) mode. `beginBulkInsert` runs `journal_mode=MEMORY`, `BEGIN`, then `END`, and **closes the writer** (`MADDatabaseSqlite3.m:955-985`); the selects handle stays open for the table's lifetime. A reader can read while the writer holds `RESERVED`, but a reader holding a read transaction makes the writer's `COMMIT` return `SQLITE_BUSY`, and the WAL checkpoint in `beginBulkInsert` asserts `SQLITE_OK`. Attach only after publication, and never hold a composer read across a rebuild or `DROP`/`VACUUM`.
   - **Zero rows.** A committed zero-row table joins correctly (inner = 0; left keeps the other side with NULLs). But MAD's SQLite driver adds columns inside the first-row loop and calls `beginBulkInsert` only when `rowCounter > 0` (`MADDatabaseSqlite3.m:664-723`), so a zero-row SQLite source leaves **no table and no columns**; querying it fails with `no such table`, and a missing `.maddb` fails to attach read-only. MySQL creates the columns unconditionally. Result metadata must come from the projection, not from a row.
   - **Attachment surface.** There is no `ATTACH` anywhere in the repo, and `MADDatabaseSqlite3 -executeQueryWithSql:` is private/undeclared. Production needs a raw-exec entry point and a helper that opens the composing connection with URI/read-only semantics. A bound parameter for the attach path worked on the host SQLite 3.51; the engine links 3.53.3 (`mad inspect`), so pin it in the MADSqlite3 suite.
   - **Not covered.** A real SQL Server, PostgreSQL, or Windows run, the Windows candidate-artifact gate, UTF-8 attachment paths, and the 10-database attach limit on the engine build still need their own validation.
   - **Operational note.** `mad refresh` could not open a fixture copied under the host home directory (the simulator sandbox denied the guts extraction at `NSHomeDirectory()/tmp`); running from the simulator's own data directory worked. That is a CLI-run constraint, not product behavior.
   [SQLite wrapper](https://github.com/mthomason/MAD/blob/master/MADSqlite3/Source/MADDatabaseSqlite3.m) · [Table storage](https://github.com/mthomason/MAD/blob/master/MADSqlite3/Source/MADDataTableFast.m)

## 1. Versioning and document compatibility

| Version | Current source or behavior | Proposed policy |
| --- | --- | --- |
| Product and release | **Landed on this branch:** root `Versions.yml` is the one manifest, and `scripts/dev/versions.py check` enforces docs data, `MADMeta.plist`, the container words, the store revision, Windows package defaults, and public download links in CI. Remaining: the mirrored marketing data file is not checked, the release workflow does not publish a versioned image tag, and the manifest comment already nominates 0.8.0 for composition. | Keep the manifest; add the marketing-mirror check, a release-time versioned image tag, and a pre-release tag for composition testing. Decide the public release number at release time. |
| Engine and build | **Landed on this branch:** `mad version`/`serve engine-info` return the engine identity; the app About screen and Windows engine handshake read the same generated build info. `Versions.yml` carries engine 9.0 / r4433, and `next_release` is 0.7.1 vs `published_release` 0.7.0. | Done for this milestone. Still pin verification to the actual candidate artifact and checksum, and publish a versioned image tag when releasing. |
| Container format | **Landed on this branch:** `MADFileFormatHeaderIsSupported` accepts v0 and 1.x up to this build's minor and rejects newer before extraction; both `MADArchiveManager` and `MADCLIContainer` validate before stripping. The 16-byte header has four flag bytes, of which only the checkpointed bit is used; the container stays 1.0. | Keep 1.0 for baseline documents, but agree on a required composition capability before a graph ships. A 1.1 marker with a required flag (or a distinct composed-document discriminator) is still needed and is the downgrade gate below. Parse through the one shared reader. |
| Definition store | **Landed on this branch:** `MADStore` reads `PRAGMA user_version` on open and refuses a newer revision with `MADStoreErrorUnsupportedVersion` before any journal/schema/migration write; migration is transactional and writes the current version. Store revision is still 2; `MADStoreSchema` has no query name, root marker, or upstream reference. | Introduce store revision 3 for the graph only after agreeing on the compatibility ladder. Keep migration transactional and test `user_version` on failure. Test whether a revision-2 writer remains practical for ordinary reports. |
| Windows RPC and local caches | **Landed on this branch:** `serve engine-info` reports `protocolVersion` and a fixed capability list (open, describe, query, refresh, export, write, query-model, layout-model, sql-entry, engine-info); the Windows client parses it tolerantly. No composition capability, no handshake gating, and no cache versioning exist yet. | Add a composition capability to the list, gate composition editing on the handshake, and version the disposable cache separately. An incompatible cache can be regenerated. |

**Downgrade is a release blocker.** A new minor version, feature bit, or store revision cannot force an already shipped reader to reject something it ignores. This branch validates the container header and refuses a newer store revision before writing, but the published 0.7 binary predates both, so it is the one that decides the discriminator. Test an actual 0.7 binary against a composed file, including Save As. If it can open and flatten or misread the graph, ship a compatibility update and choose a packaging discriminator the unpatched binaries demonstrably reject before distributing composed files. Test that discriminator on GUI and headless paths. Expose minimum-reader information in the new reader and return an actionable error before editing or execution. Preserve supported legacy input and keep the existing platform-specific Core Data converter path. [Format constants](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADConstants.m#L16) · [Archive reader](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADArchiveManager.m#L332) · [Store open and migration](https://github.com/mthomason/MAD/blob/master/MAD/Source/rptq/store/MADStore.m#L77) · [Release metadata](https://github.com/mthomason/MAD/blob/master/docs/_data/versions.yml)

## 2. Query identity, schema, and execution

| Edit points | Change |
| --- | --- |
| MADStoreSchema.m, MADStore.m, RptqDocument+Extras.m, RptqQuery and RptqQueryTable model declarations, MADModelDocument.m | Persist an explicit root query, a display name on each query, and an upstream-query reference on a table node. Reuse durable query identifiers after verifying uniqueness and persistence through save, copy, and undo. Keep database tables and upstream outputs as distinct variants of a table source. Backfill the root for a legacy document with one query. Inspect real legacy fixtures before defining the rule for multiple candidates. |
| MADQueryFull.m, MADQueryActiveQueryFields.m, MADQueryFullTableEnumerator.m, sql/MADSQLStatementResolver.m and MADSQLQueryCompiler.m | Compile the selected query with its own connection and dialect. Remove implicit first-query selections from generation, preview, and SQL-entry apply. Derive an ordered result schema from the same projection used for SQL. Retain the active fields rule and include fields that a downstream consumer explicitly references. Keep field identity stable across aliases and captions. Validate shape and type when an upstream schema changes. Keep directly entered SQL working for ordinary source queries. Gate SQL entry for the local composer until its resolver can scope the selected query and resolve derived tables safely. |
| MADDatabaseSqlite3.m and MADDataTableFast.m | Create result metadata before iterating rows. Use the planned type for composed statements where SQLite's declared type or origin metadata is incomplete. Distinguish SQLITE_DONE from step errors, propagate insert or finalization failures, and handle mid-result cancellation. Resolve logical field IDs to real cache columns before generating qualified SQLite SQL. Limit attachment paths to engine-owned staged results, use generated aliases and bound path values where supported, attach read-only, and always finalize and close the composing connection. |
| MADOperationRefresh.m, MADOperationRefreshInitialize.m, MADOperationRefreshInitalizeMainDataTable.m, MADDocumentDataProtocol.h, MADocument.m, MADHeadlessDocument.m | Extract one headless refresh coordinator used by both document implementations. Compile a snapshot of the graph on the store's owning queue, then run database I/O off that queue. Reuse MADDatabaseProtocol's execute-into-table method. Resolve credentials and connection settings per source ID. Validate cycles and missing inputs before I/O. Execute each reachable query once in topological order, initially serially, and stage its table and schema privately. |

**Verified against the branch (2026-11-23).** The edit points above are right, but the audit changes several assumptions:

- **Compilation ignores the query it is given.** `MADQueryFull -SQLOnlyActiveFields:` re-reads `RptqDocument` and takes `hasDatabaseSchemas.anyObject` / `hasQueries.anyObject` (`MADQueryFull.m:147-149`); the query passed to `initWithQuery:` supplies only `objectID`. The dialect comes from `[self.dataDelegate database]` (`:156`, `:282`). Selected-query compilation is a prerequisite, not a refinement. `MADQueryFull.m:206` also dereferences `*error` without a nil check; fix it before adding callers.
- **The projection is global, not query-scoped.** `MADQueryActiveQueryFields` scans the whole store (its header still says "only handles one query object"), and `MADQuerySelectExpressionActiveFields` emits every referenced field. With two queries, the root's SELECT list would name upstream aliases that are not in its FROM.
- **Aliases collide across queries.** `queryAlias` is `schemaTableName + dropIndex`, and `dropIndex` is counted against `database.defaultQuery` (`RptqQueryTable+Extras.m:60-95`). Two queries over the same table both yield `Orders0`, and the cache keys columns by identifier hash, so their result keys are identical. Upstreams need a query-scoped alias namespace and a per-query dropIndex.
- **The store has nowhere to put a root or a dependency.** `RptqQuery` has no name, root marker, or upstream reference; `RptqQueryTable` has one `databaseSchemaTable` to-one; creation writes exactly one database and one query (`RptqDocument+Extras.m:367-429`). Revision 3 needs new columns/relationships, and the unused `RptqQueryHasFields` is the only existing place a projection could attach.
- **One `MADDatabase`, one connection, one credential.** `MADOperationRefresh` connects `document.database` once (`:105-108`) and takes the first dependency's credentials (`:79-102`); the database is built from `hasDatabaseSchemas.anyObject` (`MADocument.m:1252-1266`, `MADOperationRefreshInitialize.m:100-124`). Per-source connection, dialect, and credential resolution is new work.
- **One `.maddb` cannot hold two results.** `MADDatabaseSqlite3 -beginBulkInsert` deletes every table in the file (`:926-938`) and `MADDataTableFast -beginBulkInsert` reopens the connection first (`:1523-1538`). Use one committed `.maddb` per result and attach them.
- **Cache identity is the filename hash alone.** `initWithId:filename.hash` (`MADocument.m:273-275`) makes the table name `t<hash>`, the `.maddb`/`.mdcache` names, and the cache directory all collide for same-named documents; Save As and two opens of same-named documents collide (`MADDocumentStore.m:52-55`). A per-instance/per-generation namespace is required.
- **Result shape is first-row only, and zero rows differ by driver.** SQLite adds columns from row 0 and skips `beginBulkInsert` when `rowCounter == 0`, leaving no table or columns; MySQL creates the columns unconditionally. The SQLite executor indexes `fieldKeys[columnCounter]` unguarded (`MADDatabaseSqlite3.m:666`), so the projection's key count must equal the SQL column count.
- **Publication is split and the flag lies.** Rows become visible at each driver's `endBulkInsert`; the `.mdcache` plist is written later by `dataTableMakeCache`; `MADOperationRefresh` sets `refreshed = YES` before checking that write (`:163-169`), and Mac completion treats `refreshed` as success (`MADMacDocument.m:370`). `urlDataTableCache` is the `.mdcache`, not the row file (`MADocument.m:408-411`), so the protocol exposes neither the `.maddb` path nor a generation id.
- **No attachment surface exists.** There is no `ATTACH` in the repo, `MADDatabaseSqlite3 -executeQueryWithSql:` is private, and the cache opens without `SQLITE_OPEN_URI`/`READONLY`. The composer needs a raw-exec entry point and an attach helper (read-only via URI or `PRAGMA query_only`), plus `LSASC` registration.

The newly compiled graph snapshot must own the projection, logical-to-physical mapping, and connection settings it needs. Freeze the definition revision for the run and discard a result if the definition changes before publication. Keep existing mainQuery and dataTable accessors as root adapters while migrating callers. Use a unique cache namespace per document instance or coordinated workspace plus a stable query ID and a generation ID. Test Save As and simultaneous opens of two same-named documents. Separate logical document identity from local cache ownership.

Publish a generation only after every required node, the root sort and grouping indexes, and cache metadata succeed. Use an atomic pointer or manifest swap for the matched .maddb and .mdcache, with a single writer per cache namespace. Existing readers retain the previous generation until done. On failure, cancellation, or restart, keep the most recent complete result visibly stale and clean staged files once their handles close. Associate success and progress with the current operation. Today MADOperationRefresh sets document.refreshed before checking cache persistence, and Mac completion partly infers success from that flag. Return the committed result or an error explicitly. [Compiler](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADQueryFull.m#L143) · [Refresh operation](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADOperationRefresh.m#L116) · [Headless table lifecycle](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADHeadlessDocument.m#L410)

## 3. Render and export from the selected node's committed result

> **Updated for the node-as-report decision (2026-11-26, final).** The render/export path is
> node-scoped, defaulting to the root. Where the bullets below say "root", read "the selected
> node (the root by default)". A node's own layout revision and its materialized table — not
> the document's single root — are the pinned inputs. The same renderer, formatter, and export
> source serve every node.

Keep the existing banded renderer. Its page index cache stores row IDs, so using a page index and row table from different refreshes can display plausible but incorrect data. The renderer needs a pinned view of the selected node's result (the root by default) for the lifetime of a format, page read, export, or print job.

- **Backing data:** Update MADDocumentRenderDataSource, MADDocumentRenderProtocol, MADocument and MADHeadlessDocument so row enumeration, row-ID lookup, group boundaries, and MADDocumentObjectDataReference field and aggregate reads all resolve to the same node generation and compatible layout revision. Bind Designer fields to the selected node's output (the root's outputs by default). Resolve formatting types from that node's schema. Audit MADSectionsLayout's current use of the document database class for the local composer. Today a designer field key is `[database queryKey:fieldName table:queryAlias]` (`MADDocumentObjectDataReference.m:173-179`) and a group's identity is `hasField.databaseSchemaField.name` plus `inQueryTable.alias` (`MADSectionsLayout.m:64-75`) — both schema-based, so a composed node must make those resolve against its own committed output, not the live schema.
- **Pagination and caching:** Update MADReportFormatter and its MADArrayCaching keys or cache namespace to include root generation, layout revision, and existing page geometry and formatter variants. The current page-index key is `<layoutIdentifier>ih<NSStringFromCGSize(size)>` and the layout key is the same with `lh`; the `andHash:` argument exists but is unused (`MADReportFormatter.m:199-209`). The index stores row ids into a table identified only by `filename.hash`, in `.madac` files in a cache directory keyed by the document basename (`MADArrayCaching.m:287-293`, `MADDocumentStore.m:52-55`). `needsFormat` reuses the persisted pages whenever `didRefresh` is false, the caches are non-empty, and the file exists (`MADReportFormatter.m:569-578`), so a surviving page index can be paired with a newer row table. Keep sort order and aggregate calculation in the current engine. Reuse pages for identical inputs. An edit to geometry or layout should rerender the pinned rows, and a successful data refresh should cause one reformat for the current Viewer. Failed refresh should leave the previous complete pages readable. Render an empty but valid root using the agreed zero-row layout behavior.
- **Exports:** Inspect every path through MADReportExportSource, CLI refresh/export, native printing, and Viewer. MADReportExportSource currently compiles the live main query at export time for field keys and schema (`MADReportExportSource.m:85, 110-131`), picks the driver from the first `hasDatabaseSchemas` entry (`:136-143`), and reads rows from `document.dataTable` (`:180-182`); `mad export` also refreshes before it exports (`MADCLIExport.m:28-66`). For composed reports, use the committed root's schema, fields, SQL metadata and rows. Preserve single-source output contracts where possible. Ensure row exports and paginated exports derive from the same generation even if a refresh completes mid-export. [Render data source](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADDocumentRenderDataSource.m#L246) · [Formatter cache and render loop](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADReportFormatter.m#L518) · [Export source](https://github.com/mthomason/MAD/blob/master/MAD/Source/MADReportExportSource.m#L82)

## 4. Ship through the existing workspaces

- **Headless and Windows RPC first.** Update MADCLIDocument.m, MADCLIRefresh.m, MADCLIQuery.m, MADCLISchema.m, and MADCLIServe.m. Preserve existing root defaults. Add query/source selection for inspection and preview, report result schema and dependencies, and accept per-source credential/connection resolution through the appropriate runtime channel. `mad serve` already dispatches by named method and advertises a fixed capability list, so a composition method and capability are additive. `mad refresh` applies `--rows` to `mainQuery` only (`MADCLIRefresh.m:49-51`), and the preview limit must keep meaning the selected node's limit, defaulting to the root. Return errors with a source or query ID. Existing single-source overrides and preview limits must keep their meaning. A limited node preview must leave full upstream inputs intact unless the query definition itself filters them.
- **AppKit first authoring surface.** In MADMacQueryViewController and MADMacDocument, add a query selector that shows the root and upstream queries, source setup via the existing connection flow, and an upstream output picker when editing the root. Scope add-table, join, filter, preview and undo operations to the selected query. `MADMacDocument` currently treats `document.refreshed` as success (`MADMacDocument.m:370`), so make it consume an explicit committed-result/error before adding per-source progress. Use MADMacViewerViewController for phase progress, source-specific failures and the stale-result state. Center the first macOS smoke test on a complete author → save → reopen → refresh → preview → export sequence.
- **WPF and UIKit.** Extend Windows/App/Mad.Designer.Windows/Engine/EngineService.cs and the MadEngineClient transport as needed, then DocumentViewModel, QueryViewModel and ViewerViewModel. Keep graph mutations and validation in the engine. On iOS, adapt MADQueryViewController, its BuilderDelegates and query data source, plus MADOperationRefreshReload and MADViewerController. Collect credentials per source, scope progress to the current document/run, and preserve the Query → Designer → Viewer workflow. Use a compact query picker on iPhone and the same graph semantics on iPad. Gate shipping authoring controls on end-to-end save/reopen support for each surface. [macOS document refresh](https://github.com/mthomason/MAD/blob/master/Mac/Source/MADMacDocument.m#L295) · [Windows engine service](https://github.com/mthomason/MAD/blob/master/Windows/App/Mad.Designer.Windows/Engine/EngineService.cs) · [iOS refresh adapter](https://github.com/mthomason/MAD/blob/master/MADDesigner/Source/MADOperationRefreshReload.m)

## 5. Merge and release gates

1. **Compatibility and baseline checks are landed on this branch** (manifest checker, header validation, store-revision refusal, engine identity). Next land selected-query compilation and schema description with the existing one-query fixtures green. Fix `MADQueryFull.m:206` and the unguarded `fieldKeys[columnCounter]` while there. Add new Objective-C sources to the Apple target and both Linux and Windows engine source lists in the same change.
2. Land staged refresh and generation-pinned rendering on the single-query path before adding SQLite composition. The concrete change point is `MADOperationRefresh.m:163-169`: write and verify the generation first, only then set `refreshed`, and return the committed result or an error explicitly. The protocol also needs the `.maddb` path and a generation id (`MADDocumentDataProtocol.h:48-52` currently exposes only the `.mdcache`). Test failed queries, cache writes, cancellation, and concurrent refresh/export here, where regressions are easier to isolate.
3. Land the headless composition fixture. Check an inner and left join, empty upstream and empty root, null and duplicate keys, decimal and date conversions, missing or changed fields, cycle rejection, and two parents sharing a dependency. Add the spike's cases: a root ORDER BY on a text key (requires `LSASC`), a table-less zero-row SQLite upstream (must be distinguished from an empty table and from MySQL's column-bearing empty result), and more than ten attachments (return a design-time error at `SQLITE_MAX_ATTACHED`). Compare grouped totals, page contents across page sizes, and normalized exports to expected values. Exercise interruption before publication and reopening with the previous result.
4. Land the authoring UI and test both drivers on a real integration fixture. Verify compatibility against released readers, the native Viewer and print paths, and the WPF bundle's actual engine. Add a release checklist for the manifest, app build numbers, engine commit/checksum, versioned image, docs and test outputs. Keep the migration and CI checks focused on this release rather than expanding them into a packaging overhaul.

The first milestone is a repeatable two-source refresh and render on a single .mad file from the CLI. The release milestone is the same document surviving an edit, save, reopen, refresh, print, and export through the supported native surfaces, with a clear upgrade path for readers that cannot execute it yet.

## 6. Audit verdict and first production change (2026-11-23)

The draft's structure survives the audit. Two of its §0 prerequisites changed: the compatibility checks in §1 have landed on this branch, and the SQLite spike is done with the results in §0.3. The remaining ordering holds: selected-query compilation, then the publish boundary, then composition.

**First production change (recommended): make `MADQueryFull` compile the query it is asked for, with that query's own database and dialect.**

- Add an explicit query selection (for example `-initWithQueryIdentifier:database:`) and resolve the `RptqQuery` by identifier instead of taking `hasDatabaseSchemas.anyObject` / `hasQueries.anyObject` (`MADQueryFull.m:147-149`).
- Take the dialect from the `MADDatabase` supplied with the selected query (its `inDatabase`), not from `[self.dataDelegate database]` (`MADQueryFull.m:156`, `:282`).
- Fix the `*error` nil dereference at `MADQueryFull.m:206`.
- Add no store columns yet: `RptqQuery.identifier` is already durable, so this is a no-format-change step and ordinary documents keep working.
- Tests: in `MAD/MADTests`, build a portable store with two queries over different tables and connections; assert each compiles only its own FROM and SELECT list, that `fieldKeys` equal the SQL columns in order, and that the dialect quoting matches its own database. Keep the existing one-query fixtures and the SQL-entry tests green. Mirror the case in the Linux suite.

**Immediate follow-ups, in order:** (1) create result metadata before iterating rows so a zero-row SQLite result carries its projection, with the zero-row test; (2) the publish boundary at `MADOperationRefresh.m:163-169` plus the `.maddb` path and generation id in `MADDocumentDataProtocol`; (3) the MADSqlite3 raw-exec and read-only attach helper with `LSASC` and the attach-limit error; (4) store revision 3 for the root/upstream graph.

**Decisions still owed by the user:** the downgrade discriminator (container flag vs distinct file type), the graph's store representation (new revision-3 columns vs encoding in existing metadata), whether ordinary reports keep container 1.0/store 2 while only composed documents bump, and whether the first milestone stays on the SQL-text driver contract (the spike found no reason to adopt the structured driver plan yet).

## 7. Decisions recorded 2026-11-23

- Composition uses one committed `.maddb` per result, paired with its `.mdcache`. The root compiles against a MAD SQLite connection that attaches those files with read-only `ATTACH DATABASE`; every reference is qualified by the attached input, and each upstream projection keeps the fields a downstream consumer explicitly requires. The current SQL-text driver contract stays.
- Ordinary reports remain writable as container 1.0 / store 2. Composed documents will carry explicit root and upstream relationships in store 3. The downgrade discriminator is chosen when there is a composed fixture to test; a shipped 0.7 binary must be shown to reject it safely, including on direct-open paths.
- Zero-row materialization, atomic publication, `ATTACH` integration, and graph persistence are saved for their own milestones. The first change requires no document-format migration.

**Milestone 1 landed (this branch).** `MADQueryFull` now compiles the query it was given: it resolves the captured identifier instead of `hasQueries.anyObject`, takes the dialect from the database set for that query, scopes active-field discovery to it, counts a table's drop index within its own query, guards every error out-parameter, and propagates the graph sorter's cycle error. Regression coverage: two queries with distinct dialects, no cross-query field leak, all-fields versus active-fields, `fieldKeys`/SELECT order, a NULL error pointer, cycle propagation, and a per-query drop index. Apple `MAD` (729 tests) and `MADDataStructures` (72), plus headless Linux `MADQueryFullTests` (26) and `MTGraphTests` (12), are green.

**Milestone 2 landed (this branch).** A successful zero-row SQLite query now creates a real `.maddb` table with the projection's columns, validated against the prepared statement's column count before the destination is cleared, plus a matching `.mdcache` that reopens through the normal cache path. Column types keep the runtime affinity for a non-NULL value (so existing outputs and export checksums do not move), then SQLite's declared type for the current statement, then the previous materialization's known type, and finally the runtime affinity, which is String for an untyped empty expression. The prior-type step only applies when the destination table is reused (the direct `executeSQL` path): a document refresh stages a fresh table per generation (`beginRefreshResultWithError:`), so the previous type does not carry across generations. A repeat refresh from nonempty to empty replaces both the rows and the columns. Apple `MADSqlite3` (125) and `MAD` (730), plus headless Linux `MADDatabaseSqlite3DatabaseTests` (31), `MADDatabaseSqlite3Tests` (49), `MADDataTableRegressionTests` (76), `MADHeadlessDocumentTests` (6), and `MADReportExporterTests` (12), are green.

**Milestone 3 landed (this branch).** A refresh stages its rows in a generation-named `.maddb` beside the live one and writes a generation-specific column map; publication is the atomic replacement of the stable `<filename.hash>.mdcache`, so the live result is untouched until the commit. `MADDocumentDataProtocol.currentResult` carries the generation identifier, row database URL, and column map together; `pendingResult` is separate, and a failed refresh discards it. `MADReportExportSource` pins `currentResult` at creation. A failed first refresh leaves no result; a retry publishes; `refreshed` is set only after publication. The current projection's declared type now beats a cached type for a reused output key. Apple `MAD` (734) and `MADSqlite3` (126), the affected headless Linux suites, and the macOS smoke test (London refreshed, 76 rows, every format exported) are green.

**Checkpoint landed (this branch): render pins one generation.** `MADReportFormatter` pins the render data source to `currentResult` at the start of a pagination pass, and the page-index/layout cache names carry the generation, so a refresh that publishes mid-render cannot change what the operation reads and a viewer re-paginates to the new result. `MADReportPageBuilder` runs its page read transaction on the pinned table. `rowIDFirstOfReport` now reads by index (the `MADArrayCaching` enumerator cursor is not reset between enumerations). Apple `MAD` (735), the affected Linux suites and the macOS smoke test are green.

**Checkpoint landed (this branch): the first composition join.** `MADDatabaseSqlite3 -attachReadOnlyDatabaseAtURL:asName:error:` attaches a committed `.maddb` read-only (`file:…?mode=ro`). The composition tests publish two small SQLite documents through the ordinary refresh chain, attach their row databases, resolve physical table and column names from each `MADDataResult`, and materialize a LEFT JOIN back through `MADDataResult`. They pin the exact rows (populated `(1,100,40) (1,100,60) (2,200,NULL) (3,300,NULL)`; empty-input `(1,100,NULL) (2,200,NULL) (3,300,NULL)`), the narrow upstream projection, read-only enforcement, a missing file, and the attachment limit. Apple `MAD` (738), `MADSqlite3` (126), the affected Linux suites and the macOS smoke test are green.

**What the join fixture proves, and what it does not.** The fixture demonstrates narrow projection with explicitly activated fields: `MADCompositionAddQuery` inserts one data label per desired upstream field, so only those fields enter that upstream's projection. It does not exercise downstream-only field propagation — an upstream field the root needs but the upstream query does not itself reference — and it does not order or compare a text key, so `LSASC` behaviour through an attachment is untested. Both still need end-to-end coverage.

## Review checkpoint at `452a4c6ed`

Independent review on 2026-11-23 against merge base `e1abb715` (the versioning work plus the composition stack since `5dba230eb`). Every finding below is **OPEN**: none has both a fix and a green verification. P1–P8 are the identifiers to cite from the next session.

- **P1 — Cache identity is the document basename.** `MADDocumentStore.m:52-54`, `MADURLFactory.m:66-68`, `MADDataTable.m:373-376`, `MADocument.m:508`, `MADHeadlessDocument.m:326`. *Consequence:* two same-named documents (different folders, or Save As) share `<hash>.mdcache` and the `t<hash>` row table; the last publisher wins and reopening the other reads its rows. *Reachable:* yes, on reopen or Save As; no test covers it. *Owner:* §5.4 release milestone and the §2 "unique cache namespace" item. *Closing test:* refresh two same-named documents in different directories, reopen each, and assert each reads its own generation; repeat through the macOS open path.
- **P2 — The generation pin is not one snapshot.** `MADReportFormatter.m:204-215,379,599,642-644`, `MADDocumentRenderDataSource.m:49-55`, `MADocument.m:297,1003-1005`, `MADHeadlessDocument.m:512,626-628`, `MADReportExporterJSON.m:69,74`, `MADReportExporterJSONReport.m:114`. *Consequence:* the page-index key is read from `currentResult` before the pin, group types come from the live `layout.dataTable`, and `json-report` uses an export-source pin and a render pin, so an export crossing a publication can carry one generation's rows and another's pages. *Reachable:* yes; publication runs off the main thread and `json-report` uses two pins. *Owner:* the follow-up to the landed "render pins one generation" checkpoint, before the composer consumes it. *Closing test:* publish between cache-key selection and the pin (or during a format) and assert the key's generation equals the pinned generation; export `json-report` across a publish and assert one identifier for rows and pages.
- **P3 — Staged files are deleted while their SQLite handles are open.** `MADOperationRefresh.m:212,240,247`, `MADocument.m:307-315`, `MADHeadlessDocument.m:522-530`, `MADDataTableFast.m:496-515`. *Consequence:* Windows cannot delete an open `.maddb`, and the removal error is discarded (`error: NULL`), so failed refreshes leak `<uuid>.maddb`/`.mdcache`; Apple unlinks but holds the space until the handles close. *Reachable:* Windows only. *Owner:* Windows composition ship (§5.1, §5.4). *Closing test:* a failing refresh on Windows leaves no staged files, or reports the removal failure.
- **P4 — Superseded generations are never reclaimed.** `MADReportFormatter.m:209-215`, `MADArrayCaching.m:287-293`, `MADocument.m:297-303`. *Consequence:* every refresh leaves the previous `.maddb`, every format leaves two generation-named `.madac` files, and an interrupted refresh leaves its staged files; nothing sweeps on open or publish, and a restarted document cannot reach the old generation. *Reachable:* yes; growth is monotonic per refresh and format. *Owner:* publication/cache lifecycle before release. *Closing test:* two refreshes plus a format leave only the current generation (or a bounded set), and a simulated interrupted refresh's staged files are swept on open.
- **P5 — The attach helper requires `SQLITE_OPEN_URI`, which neither default open path sets.** `MADDatabaseSqlite3.m:890-897,238-239`, `MADDataTableFast.m:506`. *Consequence:* without the flag, `?mode=ro` is a literal filename and `SQLITE_OPEN_CREATE` can attach an empty writable file, so read-only is silently not in effect. *Reachable:* not through current callers; the tests pass the flag explicitly. *Owner:* the composer's connection setup, first CLI milestone (§0.3 attach surface). *Closing test:* open the composer connection through its production constructor and assert the attached database rejects a write.
- **P6 — Attach URI and alias are unescaped.** `MADDatabaseSqlite3.m:890-892`. *Consequence:* a path containing `?`, `#` or `%` is misparsed, and an alias needing quoting (`main`, `temp`, spaces) breaks. *Reachable:* no for engine-owned `<uuid>.maddb` names; the helper is public. *Owner:* hardening; can wait. *Closing test:* attach with those characters in the path and alias.
- **P7 — One `pendingResult` slot with no operation ownership (latent).** `MADOperationRefresh.m:212,246`, `MADocument.m:140,256-303`. *Consequence:* overlapping pipelines overwrite each other's staged table, publish the wrong identifier, or discard each other's files. *Reachable:* not today — Mac's refresh queue is serial (`MADMacDocument.m:62`) and iOS guards with `_refreshing` (`MADViewerController.m:513`); deferred until a parallel composer. *Owner:* per-node staging in the composer, after the serial milestone. *Closing test:* two overlapping begin/publish pairs; each publishes its own generation or the second is refused cleanly.
- **P8 — Active-field scoping drops a field with no owning query table.** `MADQueryActiveQueryFields.m:43-44`. *Consequence:* an orphaned field silently leaves the SELECT instead of erroring. *Reachable:* not with current authoring paths. *Owner:* selected-query/active-field follow-up (§2). *Closing test:* an element referencing a field whose `inQueryTable` is nil is retained (or rejected with an explicit error).

**Coverage gaps to close.** Text ordering through `LSASC`; downstream-only field propagation; same-named documents and Save As; overlapping and interrupted refreshes; generation reclamation; cross-generation column types; and a production root selection — `MADDocument.m:1331,1402` and `MADOperationRefreshInitialize.m:100-101,130` still use `defaultQuery`/`anyObject`, so no caller selects a non-default query through the document API yet.

**Platform checks outstanding.** Full `./Linux/build.sh`; the Windows engine build and tests plus `Windows/package.ps1`; the WPF suite; and re-pinning the attach-limit test to the engine's SQLite 3.53.3 (the suite currently runs against the host 3.51). The hosted Windows job fetches the v0.7.0 engine and cannot validate this branch's Objective-C.

A finding stays open until a fix lands and its named test (or an equivalent, recorded) is green on Apple and, where the flag applies, on the headless and Windows suites.

## Checkpoint A landed (2026-11-23)

P1, P2 and P3 are fixed on `feat/query-composition` at `75ee1c60b`; Apple `MAD` (742) and `MADSqlite3` (126) are green, and the macOS smoke test (London refreshed, every format exported) passes.

- **P1 (cache identity).** `MADDocumentStore` now derives the cache namespace and the row-table `id` from the document's standardized file URL instead of its basename (`cacheNamespaceHash`); `MADocument` and `MADHeadlessDocument` pass it to every `initWithId:`. Two same-named documents in different folders, and a Save As copy, keep separate `.maddb`/`.mdcache` files and reopen to their own rows. Legacy basename-keyed caches are orphaned and regenerated (disposable). Container 1.0 / store 2 unchanged. *Regressions:* `testTwoSameNamedDocumentsInDifferentFoldersKeepSeparateCaches`, `testSaveAsCopyRefreshDoesNotChangeTheOriginal`.
- **P2 (one render snapshot).** `MADReportFormatter` pins the render data source once, at the top of `format:contentChanged:`, before the page-index/layout cache key or group types are read; `generationIdentifier` and `groupDataTypes` read the pinned result; `formatDocument` no longer re-pins. `MADReportExporterJSONReport` pins the render data source to `source.result` for the page walk and unpins after, so a publish mid-export cannot pair one generation's rows with another's pages. *Regression:* `testJSONReportExportUsesOneGenerationAcrossAPublish` (a zero-row publish placed between the source capture and the page walk; the crossing export's bytes equal a clean export of A).
- **P3 (staged cleanup).** `MADDataTableFast -closeConnections` finalizes prepared statements and closes both SQLite handles; `discardPendingResult` calls it before removing the staged `.maddb`/`.mdcache` and logs a removal failure instead of discarding it. *Regression:* `testFailedRefreshLeavesNoStagedFilesAndRetrySucceeds` (a failed publish leaves A readable, adds no staged row file, and a retry succeeds). Windows still needs a real run to prove the open-handle deletion case, which Apple cannot exercise.

**Out of scope, recorded for later:** the guts directory (`tmp/<basename>.mada`) still collides for same-named documents — a pre-existing definition-storage identity gap separate from the row cache, observed when a `Invoices.mad` test collided with a leftover `invoices.mada` guts directory. P4–P8 remain open.

## Checkpoint B landed (2026-11-24)

The two-input join is now a production engine API, `MADComposer` (`MAD/Source/MADComposer.h`), used by the invoice/payment fixture on Apple. Apple `MAD` (747) and `MADSqlite3` (126) are green, and the macOS smoke test (London refreshed, every format exported) passes.

- **Production entry point.** `+[MADComposer composeLeft:right:joinType:orderByKeys:rootIdentifier:cacheDirectory:error:]`. `MADComposerInput` names an input (alias, published `MADDataResult`, projected `MADComposerField`s, and the join key); `MADComposerField` maps a full logical key to a root column key. The composer resolves physical table/column names, opens a URI-capable MAD SQLite connection, attaches both inputs read-only, runs the join, and returns a normal `MADDataResult`. A failed attempt closes the connection and leaves both inputs and any prior root untouched.
- **P5/P6 fixed in `attachReadOnlyDatabaseAtURL:`.** The path is percent-encoded for the `file:` URI (so `?` `#` `%` and non-ASCII cannot misparse), the alias is double-quoted (so `main`/`temp`/spaces survive), and the composer opens its connection with `SQLITE_OPEN_URI`. `testCompositionAttachUnicodeReservedPathAndAlias` attaches a file under a `Café ?#% ü` path with a space alias and proves a write is refused.
- **Fixture conversion.** `testCompositionJoinPopulated` and `testCompositionJoinEmptyPayments` now call `MADComposer` instead of hand-building the SQL, resolving names, attaching, and constructing the result (the manual helpers are gone from the Apple suite). Populated root rows are exactly `(1,100,40) (1,100,60) (2,200,NULL) (3,300,NULL)`; empty-right-side root rows `(1,100,NULL) (2,200,NULL) (3,300,NULL)`.
- **`LSASC`.** `testCompositionJoinOrdersTextByLSASC` composes over a text key with an `ORDER BY … COLLATE LSASC` and asserts the order equals `-mad_orderedCompare:`. The composer emits `COLLATE LSASC` for a text key via `sortDescriptionForColumnType:ascending:`.
- **Required fields (downstream-only propagation).** `MADQueryFull -requiredQueryFields` threads a per-query set through `MADQuerySelectExpressionActiveFields` into `MADQueryActiveQueryFields`, so a field a downstream consumer needs is projected with no report label. `testCompositionRequiredJoinKeyWithoutLabel` projects the payment-side `invoice_id` (the root's join key) while `payment_id` stays out.
- **Empty expression type.** `testCompositionEmptyExpressionKeepsKnownType` refreshes a typed column to zero rows and asserts the empty result keeps its declared type (`INTEGER`→`MADDataTypeInteger`, `REAL`→`MADDataTypeDouble`), not the String fallback.
- **Attachment limit.** `testCompositionAttachmentLimitAndSQLiteVersion` reports **SQLite 3.53.3** (the engine-linked build, not the host 3.51) and **effective `SQLITE_MAX_ATTACHED` 10**, and asserts the 11th attach is refused.

**Remaining for Checkpoint B.** The Linux composition tests still exercise the manual attach/execute path; converting them to `MADComposer` (and mirroring the new cases) is deferred with the full `./Linux/build.sh`. `MADComposer.m` is already in `Linux/cmake/MADSources.cmake` and is headless-safe (Foundation + MADSqlite3 + sqlite3 only). The same-commit Windows engine/package/WPF run, full Linux, and PR CI remain separately identified until actually run.

## Checkpoint C landed (2026-11-24)

The headless composition tests now run the production `MADComposer` instead of hand-built ATTACH/join SQL, on Linux and Windows. Commits `d18a96fa3` and `1249740d4` pushed to `origin/feat/query-composition`. This closes the "Remaining for Checkpoint B" item above.

- **Conversion.** `Linux/Tests/MADReportExporterTests.m` and its Windows mirror `Windows/Engine/Tests/MADReportExporterTests.m` (byte-identical, kept in sync) convert `testCompositionJoinPopulated` and `testCompositionJoinEmptyPayments` to `+[MADComposer composeLeft:...]`, and drop the manual `MADCompositionPhysicalColumn`/`MADCompositionExecute` helpers. The manual ATTACH/execute path is gone.
- **New cases, mirrored from Apple.** `testCompositionJoinOrdersTextByLSASC` (root ORDER BY over a text key through `LSASC`), `testCompositionAttachUnicodeReservedPathAndAlias` (P5/P6 path and alias), `testCompositionAttachmentLimitAndSQLiteVersion` (engine-linked SQLite, effective limit), `testCompositionRequiredJoinKeyWithoutLabel` (downstream-only join key), and `testCompositionEmptyExpressionKeepsKnownType` (zero-row declared type).
- **Windows source inventory.** `Windows/Engine/cmake/MADSources.cmake` now lists `MADComposer.m`; `scripts/dev/check_source_lists.py` is green (12 frameworks, 367 files) where it previously reported `MADComposer.m` missing from the Windows list.
- **Regression fixed.** `MADDatabaseSqlite3.m` used `NSMutableCharacterSet` in the P6 percent-encoding without importing `<Foundation/NSCharacterSet.h>`; GNUstep's self-contained-header rule failed the full Linux build. The import is added (`d18a96fa3`).

**Results (actual, 2026-11-24).**
- Full `./Linux/build.sh`: **131 suites, 0 failures** (`100% tests passed`), 7 pre-existing NEEDs (documented GNUstep divergences). `MADReportExporterTests` is 25 tests / 700 checks / 0 failures, up from 20; the attachment-limit case prints `SQLite 3.53.3, effective SQLITE_MAX_ATTACHED 10`.
- Apple `MADSqlite3`: **126 tests, 5 skipped, 0 failures** (the import fix's Apple gate).

**Outstanding / pending.** The same-commit Windows engine/package/WPF run and the PR CI have not been run; they remain identified as pending until actually exercised. P4 (generation reclamation), P7 (operation ownership), and P8 (active-field scoping) remain open.

## Decisions recorded 2026-11-24 (Checkpoint D/E authorisation)

- **Versioning.** Separate the highest store revision the engine can read from the revision a document needs. Ordinary reports keep container 1.0 / store 2 (existing creation/open/edit/save and legacy migrations preserved, revision-2 schema). A document is written as store 3 only when a user first saves a graph that requires composition, transactionally; a failed conversion/save leaves the original usable. Do **not** stamp every opened store with the engine's maximum revision.
- **Capability.** One shareable `.mad`, the existing extension. Composed documents use container 1.1 with a small versioned metadata record declaring required capability `query-composition`; the header is for format recognition, the metadata for required feature names. Ordinary reports carry no new metadata. The reader compares a document's requirements with engine support before migration/edit/execution; an unknown required capability produces an actionable upgrade message and leaves the file untouched. The engine capability declaration must match `engine-info`. A graphical capability matrix can wait.
- **Shipped 0.7 policy.** Ordinary reports stay compatible with 0.7; composed reports require a composition-capable MAD. Record the shipped 0.7 binary's behaviour on disposable copies only if it is readily available; if not, record that and continue. Not a gate.

## Checkpoint D in progress (2026-11-24)

- **Guts extraction collision fixed** (`5a2be28b4`, pushed). `MADURLFactory -newURLDocumentArchiveForFileURL:extension:` now keys the `.mada` working directory by the document's full normalized path (the same key the row cache uses) instead of its basename, so two same-named documents in different folders — and a Save As copy — no longer share one guts directory. Tests: the archive URL is the path hash, and two same-named documents in different folders get different guts directories. Apple `MADFoundation`, Linux `MADURLFactoryTests` (19), and the full `./Linux/build.sh` (131 suites, 0 failures) are green.

**Still to do (D and E).** Container 1.1 + the capability metadata record and the reader's capability check; missing-reference and cycle errors that name the affected query; the unknown-capability test; the shipped-0.7 observation if the binary is available; and Checkpoint E's CLI execution (`defaultQuery`/`anyObject` call sites at `MADocument.m:1331,1341,1350,1402` and `MADOperationRefreshInitialize.m`, per-source connection/dialect, topological source execution, publish through `MADComposer`).

## Checkpoint D — store round trip landed (2026-11-24)

Pushed `8d600a010` to `origin/feat/query-composition`. The store-level round trip is verified end to end.

- **Schema.** Store revision 3 adds `RptqQuery.name` (TEXT), `RptqDocument.rootQuery` → `RptqQuery` and `RptqQueryTable.upstreamQuery` → `RptqQuery` (with their inverses), marked `introducedInVersion = 3`. The base DDL and a revision-2 read omit them; the 2→3 migration adds them. `MADStoreCurrentVersion` stays 2; `MADStoreMaximumReadableVersion` is 3; open refuses only past 3.
- **Transactional composed save.** `-writeGraph:replacingAll:composed:` / `-writeObjects:deletingObjects:composed:` and `RptqStoreContext -saveComposed:` fold the migration columns + `user_version = 3` into the same transaction as the graph write. `storeVersion` is advanced only after the commit, so a rollback leaves the in-memory revision matching the on-disk one.
- **Legacy conversion preserved.** `MADStoreConverter` skips the store-only fields (no Core Data counterpart); the Core Data model is unchanged. The fidelity check (`MADStoreTests testSchemaMatchesEveryModelEntity`) records the store-only fields per entity, and `testAStoreFromANewerBuildIsRefusedBeforeAnyWrite` now writes one past `MADStoreMaximumReadableVersion`.
- **Round-trip test.** `testCompositionGraphRoundTripsAndIsRevision3` builds an invoices/payments graph through `RptqStoreContext`, saves composed, reopens in a fresh context, and recovers — from the reopened objects alone — the explicit root (`rootQuery.name == "root"`), both named sources (`invoices`/`payments`) with their connection references (`inDatabase.databaseDriverType`), the root's two upstream-referencing tables, and the left outer join with its `invoice_id` keys. `testOrdinaryReportStaysRevision2` and `testFailedCompositionSaveRollsBackToRevision2` pin the on-disk revisions.

**Results (actual).** On-disk revisions observed: ordinary save = **2**, composed save = **3**, failed conversion = **2**. Apple `MAD` suite green (fidelity, converter, migration, store, and the three new tests); Linux `RptqStoreContextTests` 20/0; full `./Linux/build.sh` 131 suites / 0 failures; `scripts/dev/versions.py` and `scripts/dev/check_source_lists.py` green.

## Checkpoint D — container 1.1 + capability landed (2026-11-24)

Pushed `9546bae85` to `origin/feat/query-composition`.

- **Container 1.1.** `MADFileFormatCompositionMinorVersion = 1`; `MADFileFormatHeaderIsSupported` accepts 1.1. `MADArchiveManager` gains a `composed` flag that writes the 1.1 header and a versioned `requirements.plist` (`{format: 1, requiredCapabilities: ["query-composition"]}`) into the guts; ordinary documents stay 1.0 with no record.
- **Reader check.** `-unarchiveWithError:` checks the requirements record for a 1.1 container before the store opens; `-checkRequirementsWithError:` refuses a missing/malformed record or an unknown required capability with an actionable upgrade message, leaving the file untouched. `MADDocumentCapabilityQueryComposition` is the name, and it is also advertised in `engine-info`.
- **Composed save.** `MADHeadlessDocument -writeToURL:` detects a composed document by its explicit root, saves at store revision 3 (`-saveComposed:`), and sets the archive's composed flag.
- **Validation.** `RptqDocument -validateCompositionGraphWithError:` rejects a cycle and a missing upstream reference, each error naming the affected query.

**Tests.** Container 1.1 vs 1.0 headers + the requirements record; missing/unknown/supported capability checks; graph cycle and missing-upstream validation; the header now accepts 1.1 and refuses 1.2. Apple `MAD` green, Linux `MADArchiveManagerTests` 7/0 and `RptqStoreContextTests` 21/0, full `./Linux/build.sh` 131/0, versions.py + check_source_lists.py green.

**Still to do.** The archive round trip through the production writer/reader with *distinct* per-source connection references, the ordered root projection (invoice_id/invoice_amount from invoices, payment_amount from payments) — the store does not yet preserve field *order*, a model gap to close — Save As identity, the forced failed-archive-save case, and the macOS ordinary-report smoke test. Then Checkpoint E.

## Checkpoint D — ordered output projection + archive round trip landed (2026-11-24)

Pushed `3d491eedf` to `origin/feat/query-composition`.

- **Ordered projection.** `RptqQueryField` gains `outputIndex` and `outputKey` (both revision 3, so ordinary revision-2 documents keep their schema). `RptqDocument -orderedCompositionOutputsWithError:` returns the root's projected fields ordered by `outputIndex`, and errors — rather than inventing an order — when a composed document records none (an earlier store or an unset projection).
- **Archive round trip.** `testComposedArchiveRoundTrip` builds invoices and payments with *distinct* connection references (`invoices.sqlite` / `payments.sqlite`), saves through the production store + archive writers (container 1.1), copies only the `.mad` into a clean directory, reopens it through the production reader, and recovers — from the document alone — both connection references, the root, and the ordered outputs (`invoice_id` ← invoices, `invoice_amount` ← invoices, `payment_amount` ← payments).

**Results.** Apple `MAD` green, Linux `RptqStoreContextTests` 22/0, full `./Linux/build.sh` 131/0, versions.py + check_source_lists.py green.

**Still to do.** The explicit reorder case (payment_amount between the two invoice outputs), Save As identity, the forced failed-archive-save case, and the macOS ordinary-report smoke test. Then Checkpoint E.

## Checkpoint D — reorder, Save As, and failed-save landed (2026-11-24)

Pushed `d9fff7566` to `origin/feat/query-composition`.

- **Reorder.** `testComposedProjectionReorder` round-trips the reordered projection (`invoice_id`, `payment_amount`, `invoice_amount`) and asserts the exact sequence and the source field behind each output.
- **Save As.** `testComposedSaveAs` saves two same-named documents in different directories — the original with the default order, the copy with the reordered projection — and verifies each reopens with its own order and both keep their two connection references.
- **Failed save.** `testComposedFailedArchivePreservesDestination` forces the archive to fail (moved guts) and verifies the previous destination still opens with its projection. This exposed and fixed two defects: the native `MADocument` save path did not detect a composed document (it saved at revision 2 / container 1.0), and `MADArchiveManager -archive:` swallowed a failed requirements-record write.
- **Native path.** `MADocument -writeStoreAndArchiveWithError:` and `MADHeadlessDocument -writeToURL:` now detect composition by reading the document row directly (safe before the create flow inserts it), save at revision 3, and archive as container 1.1.

**Results.** Apple `MAD` green, Linux `RptqStoreContextTests` 25/0, full `./Linux/build.sh` 131/0, and `./Mac/build.sh --smoke-test` passes (London 76 rows, every format exported, plus a created/designed/refreshed/exported 3-row report). `versions.py` + `check_source_lists.py` green.

Checkpoint D is complete. Next: Checkpoint E (fresh-process `mad refresh` and export of the invoice/payment rows).

## Checkpoint E — fresh-process CLI refresh and export landed (2026-11-24)

A saved composed report now refreshes and exports end to end through the shared engine
path. The CLI stays a thin adapter; the work lives in the engine so native clients can
reuse it.

- **Composer projection order.** `MADComposer` gained `MADComposerProjection` (an input
  plus its `sourceKey`/`outputKey`) and `+composeLeft:right:joinType:projections:orderByKeys:cacheDirectory:intoTable:error:`,
  which composes an explicit ordered projection into a caller-owned result table. The
  existing `+composeLeft:right:joinType:orderByKeys:rootIdentifier:cacheDirectory:error:`
  is now a convenience that folds the two inputs' fields into one projection and writes
  the column map itself. A caller honors a persisted output order by passing the
  projections in that order.
- **The composed refresh coordinator.** `MADOperationRefreshComposed` (in
  `MADOperationRefresh.m`) is the composition branch of the refresh chain. On the store's
  owning queue it resolves the explicit root, validates the graph, reads the ordered
  outputs and the join, derives each source's required fields (every output field plus
  each join key — so a downstream-only join key is projected), and compiles each source's
  SQL with that source's own connection and dialect. Off that queue it refreshes each
  source once serially into a fresh generation, builds the composer inputs and ordered
  projections, composes into the document's staged result, and publishes through the
  ordinary `beginRefreshResult`/`publishPendingResult` boundary. A failed source reports
  the source by name, and a failed refresh leaves the previous published root untouched.
- **Export reads the committed root.** `MADReportExportSource` detects a composed document
  and builds its columns, schema fields and rows from `currentResult` plus the persisted
  output projection, instead of compiling `document.mainQuery`.
- **Join keys are not outputs.** `RptqDocument -orderedCompositionOutputsWithError:` now
  returns only the fields that name an `outputKey`; a field with none is a join key, not a
  projection the store forgot to order. The "no output order" error still fires when the
  root has fields but none of them is an output.
- **CLI adapter.** `MADCLIDocument -refreshWithCredentials:` selects
  `MADOperationRefreshComposed` when `activeDocumentModel.rootQuery` is non-nil, with the
  same credentials-holder dependency the ordinary path uses. `MADFixtureMaker compose`
  builds the invoices/payments fixture (and `compose … reorder` the reordered projection)
  through the production store and archive writers.
- **Test.** `testComposedRefreshProducesRoot` builds a composed document through the
  store + archive writers, reopens it headless, refreshes through
  `MADOperationRefreshComposed`, and pins the column order and row count.

**Fixture and commands (all run from a different working directory so an accidental
source-path resolution against the shell's cwd would fail).**

```sh
CLI/build.sh --make-fixture compose /tmp/mad-e2e/composed.mad
env SIMCTL_CHILD_MAD_HOST_CWD="$PWD" xcrun simctl spawn booted CLI/build/mad refresh /tmp/mad-e2e/composed.mad
env SIMCTL_CHILD_MAD_HOST_CWD="$PWD" xcrun simctl spawn booted CLI/build/mad export --format json /tmp/mad-e2e/composed.mad
```

**Observed results (actual).**

- Default projection: `refreshed 4 rows`; `json` columns `invoice_id, invoice_amount,
  payment_amount`; rows `(1,100,40) (1,100,60) (2,200,null) (3,300,null)`.
- Empty payments (`DELETE FROM payments;`, same saved report): `refreshed 3 rows`; rows
  `(1,100,null) (2,200,null) (3,300,null)` — the zero-row payments source keeps its
  `invoice_id` join key, and all three invoices stay.
- Reordered projection (`compose … reorder`): columns `invoice_id, payment_amount,
  invoice_amount`; rows `(1,40,100) (1,60,100) (2,null,200) (3,null,300)` — the exported
  values follow their output keys.
- Failure and recovery: with `payments.sqlite` moved aside, `mad refresh` exits 4 with
  `The source 'payments' could not connect: …`; the stable `.mdcache` still names the same
  generation and its row file still holds the four rows; restoring the source and
  refreshing again succeeds.

**Results.** Apple `MAD` 752/0 (including `testComposedRefreshProducesRoot`), full
`./Linux/build.sh` 131 suites / 0 failures, `./Mac/build.sh --smoke-test` passes (London
76 rows, every format exported, plus the created/designed/refreshed/exported 3-row report),
and `scripts/dev/check_source_lists.py` green.

**Pending.** The same-commit Windows engine/package/WPF run and the PR CI have not been
run; they remain identified as pending. PR creation and merge await the user's direction.


## Checkpoint F — native macOS composition landed (2026-11-24)

The composed report now opens, refreshes, renders, and exports through the native AppKit
application's own path: the ordinary Refresh action selects the composed coordinator, and
the Viewer's detail band binds the joined rows to their root output keys.

- **Shared refresh selection.** `MADOperationRefresh` gained
  `+documentUsesComposedRefresh:`, the one place that decides a document refreshes through
  `MADOperationRefreshComposed` (an explicit `rootQuery`) rather than the ordinary
  single-query chain. Both the CLI (`MADCLIDocument`) and the native document
  (`MADMacDocument`) now call it. `MADMacDocument -refreshDataWithPassword:completion:`
  branches to a `MADOperationRefreshComposed` run for a composed root and leaves the
  ordinary `MADOperationRefreshInitialize…` → `MADOperationRefresh` chain unchanged for an
  ordinary report.
- **Field binding.** `MADDocumentObjectDataReferenceLabelDynamic -fieldKey` returns a root
  field's persisted `outputKey` when one is set. The composed result table is keyed by the
  output keys the composer wrote, not by a source-table alias, so a composed detail band
  would otherwise render blank — or, with two sources naming a field `amount`, bind both to
  the wrong source. The ordinary alias path is unchanged.
- **Fixture layout.** `MADFixtureMaker compose` now writes a detail band whose three data
  labels are bound to the root outputs `invoice_id`, `invoice_amount`, `payment_amount`.
  The document now uses `newDocumentForManagedObjectContext:` for its five sections, so the
  composed fixture is a real report layout rather than a sectionless root.
- **Native verification.** `Mac/Tests/MADMacSmokeTest.m` adds the composed case: build the
  fixture through the production store and archive writers, open it through
  `MADMacDocument`, refresh through the Viewer's `refreshReportAction:`, read back the
  joined detail values, take the payments source away and refresh (the failure names
  `payments` and the previous report stays readable), restore an empty payments source and
  refresh (three invoices, blank payments), and export the visible generation to PDF.
- **Multi-page verification.** The smoke suite also builds a 60-invoice fixture (invoices
  `i%3==0` carry two payments, `i%3==1` one, `i%3==2` none, so unpaid invoices render blank
  payment fields) and verifies: the detail rows, in page order, are exactly `1…N` (no row
  dropped or duplicated at a page break) and each row's invoice/payment amounts match the
  fixture; the first and last PDF pages contain the first and last invoice amounts; the
  exported PDF page count equals the rendered page count; and refreshing the same open
  report with only the first five invoices shrinks the page count. The fixture relies on
  sorted insertion order — the composed coordinator has no explicit `ORDER BY` yet, a gap
  the test's ordered comparison would expose.
- **Grouping parity.** The composed root now groups the way an ordinary report does. Two
  defects were found and fixed: `readCurrentSortDescriptors` read the *default* query (an
  arbitrary source query with no groups) instead of the explicit `rootQuery`, and the
  group sort key was built as `"<alias>.<field>"` — a spelling a composed output field
  (which references an upstream query table) has none of, and one that cannot name a
  column of the composed result table, which is keyed by its output keys. Both
  `RptqQuery -sortDescriptorsForDatabase:` and `MADSectionGroupLayout -safeSortKey` now use
  a root field's persisted `outputKey` when one is set, so the data table sort and the
  renderer's group-break comparison key off the same output keys. `MADSectionGroupLayout`
  and `MADSectionsLayout` carry the output key through the section dictionary. The ordinary
  alias path is unchanged. `testComposedGroupingSortsByOutputKeysAndBreaksGroups` builds a
  composed document with two nested groups (invoice_id ascending, payment_amount
  descending) over deliberately shuffled invoices and duplicate detail records, then checks
  the sort descriptors, the sorted row order, and the rendered group breaks; the macOS smoke
  suite adds a 40-payment group that crosses a page boundary.
- **Filter behavior.** A filter is a `RptqQueryPredicate` owned by a query
  (`RptqQuery.hasQueryPredicate`), compiled by `MADQueryPredicate` into the query's SQL
  `WHERE`. There is no separate Viewer or report-level filter. On a composed document a
  source predicate runs in that source's own SQL, before the join: `amount > 50` on the
  payments source leaves payment 60 and the left join still returns `(1,100,60) (2,200,null)
  (3,300,null)`. A predicate on the composed *root* is compiled into the local join `SELECT`'s
  `WHERE`, after the `ON`, so it filters the joined rows: `payment_amount > 50` keeps only
  `(1,100,60)` and drops the null payments of invoices 2 and 3. `MADQueryPredicate` gained a
  field resolver — the ordinary path spells a field `"<alias>.<field>"`, the composer spells
  it `src0.<physical>`/`src1.<physical>` against the attached input it came from — so the
  comparison and value-handling behaviour is one implementation. Fields referenced only by a
  root predicate are materialized by their upstream source but never become visible root
  outputs (narrow projection preserved). The cases are pinned by
  `testComposedSourcePredicateFiltersTheSource`, `testComposedRootPredicateFiltersTheRoot`,
  `testComposedSourcePredicateOnNonReturnedFieldPreservesProjection`,
  `testComposedChildAndRootPredicatesBothApply`, `testComposedRootTextPredicateOnNonOutputField`,
  and `testComposedRootFieldToFieldPredicateAcrossInputs`; the CLI fixture maker's
  `compose … rootfilter` writes `payment_amount > 50`, which `mad refresh`/`export` reduce to
  one row. The macOS authoring milestone will expose the existing Filters control for
  whichever query the author selects, including the root.

**Observed rendered values.** Default projection refreshes 4 rows and exports columns
`invoice_id, invoice_amount, payment_amount` with rows `(1,100,40) (1,100,60) (2,200,null)
(3,300,null)`. The native Viewer reads the same four rows through `dataForRow:column:` and
confirms invoice 1's two payments (40 and 60) sit beside invoice amount 100 — the amounts
bind to their own root keys, not swapped (the renderer's key mapping is pinned by
`testFieldKeyUsesTheComposedOutputKey`). Empty payments refresh 3 rows with blank payment
amounts. The unavailable-payments refresh reports `The source 'payments' …` and keeps the
four-row result readable.

**Results.** Apple `MAD` 760/0 (added `testFieldKeyUsesTheComposedOutputKey`,
`testComposedGroupingSortsByOutputKeysAndBreaksGroups`, and the six filter tests); headless
`MADDocumentObjectDataReferenceLabelDynamicTests` (5/0) and `MADReportExporterTests` (25/0)
pass in the Linux image; the headless `mad` framework compiles; the CLI refresh of
`compose … rootfilter` reduces to one row and exports `(1,100,60)`; and
`./Mac/build.sh --smoke-test` passes (21 PASS) with the composed open→refresh→view→export
case, the multi-page composed case, the grouped composed case (46 rows / 2 pages / 2
groups, one group crossing a page boundary), and the ordinary London/created reports.

**Pending.** The full `./Linux/build.sh` image build, the Windows engine/package/WPF run,
and the PR CI have not been run; PR creation and merge await the user's direction.

## Checkpoint G — native macOS authoring landed (2026-11-24)

The first native macOS workflow for **authoring** a composed report is landed: a user can
build the invoices/payments report from a new document and two SQLite sources, through the
app's own actions, without a prebuilt `.mad`. The engine (Checkpoints A–F) is unchanged;
this checkpoint is the AppKit authoring surface on top of it.

- **Document model.** `MADMacDocument` gains `isComposed`, `rootQuery`, `allQueries`,
  `reportQuery` (root for a composed document, else the single query), `selectedQuery`,
  `databaseForQuery:`, `requiresComposedStore`, and the graph mutations
  `addSourceQueryNamed:withConnection:credentials:error:`,
  `addRootQueryNamed:error:`, and `renameQuery:to:`. A composed document (a root, more
  than one query, or any named query) now persists at store revision 3 on every mutation
  (`notifyDocumentMutated` → `saveComposed:`), not only at the final save, so an
  interrupted session does not lose the revision-3 columns.
- **Adding a source.** `addSourceQueryNamed:…` connects to a live source, imports its
  schema as a new `RptqDatabase` plus a named `RptqQuery` (each source keeps its own
  `inDatabase` connection reference), and adds it to the document. The connection sheet
  gained a source-picker mode (builds/tests and hands back a connection) and a
  `targetQuery`, so an existing source reconnects in place instead of overwriting the
  document's default database.
- **Query workspace.** A query selector (root + sources) with add-source, add-root, and
  rename actions. Switching queries scopes the schema sidebar, the visual canvas, the
  Filters/Groupings editors, and the SQL editor to the selected query, so editing one
  source preserves the others' connections, fields, and filters.
- **The root.** When the root is selected, the sidebar lists the source queries;
  double-clicking one adds it as an upstream table (one root query field per projected
  source field). The existing drag/context-menu field connection creates the left outer
  join (the root is scoped to one left outer join). The new **Outputs** popover chooses,
  names, and reorders the root's output columns via `outputKey`/`outputIndex`; a field may
  be both a join key and an output (the composer derives the join key from
  `databaseSchemaField` and the output from `outputKey`, so they do not collide). Filter
  and group field labels show each field's source and output key, keeping
  `invoices.amount` distinct from `payments.amount`.
- **Report Designer.** The field browser lists a composed document's root outputs in
  order and binds a placed data field to its `outputKey`, so the detail band renders the
  joined values against the right source; the ordinary alias path is unchanged.

**Verification.** `./Mac/build.sh --smoke-test` is green (22 PASS), including a new
authoring case that builds the report from scratch through the document and query-workspace
actions, saves, reopens, refreshes, and pins: four unfiltered detail rows
`(1,100,40) (1,100,60) (2,200,null) (3,300,null)`, a source filter `payments.amount > 50`
→ three rows, and the same predicate on the root → one row `(1,100,60)`. The ordinary
single-source workflow (London refresh/export, created+SQL+designer report, viewer) stays
green. `MADFixtureMaker sources <dir>` writes the two sample databases. The smoke test
drives the controller actions where they are reachable (`addSchemaTableToQuery:`,
`addUpstreamQueryToRoot:`, `connectQueryField:`, the designer's `addDataField:inSection:`)
and sets `outputKey`/`outputIndex` directly rather than through the Outputs popover, and
drives the connection sheet's effect via `addSourceQueryNamed:` rather than the sheet's
buttons — those two UI steps are the ones the test bypasses.

**Not covered / pending.** The full `./Linux/build.sh` image build, the Windows
engine/package/WPF run, and the PR CI have not been run (this checkpoint touches only the
AppKit app and the fixture maker, not the headless or Windows surfaces). Source-query
*preview* and the SQL editor still compile the default query rather than the selected
source, and the SQL editor is disabled for the root. A graphical capability matrix, the
Windows/iOS authoring surfaces, and the remaining open review items (P4, P7, P8) are out
of scope for this milestone. PR creation and merge await the user's direction.

## Checkpoint H — create / import / convert landed (2026-11-25)

The three authoring workflows are now engine primitives, with the AppKit surface on top.
Everything is in the `MAD` framework (headless-safe, so Windows and iOS reuse it); the
macOS smoke suite drives the new flows end to end.

- **Import (graph copy + identifier remap).** `RptqStoreContext -importQueryGraphFromContext:relativePathBaseURL:error:`
  copies another document's query graph — queries, databases, their schema, and every query
  table/field/link/group/predicate/sort — into the destination, minting fresh identifiers so
  two independently authored documents coexist even with identical ids. Layout bands,
  elements, and the source document row are not copied; a relative SQLite source path is
  resolved to an absolute path against the source document's own location; and each imported
  database is wired into the destination document's `hasDatabaseSchemas`. Returns the imported
  root (the source's explicit root, else its single query).
- **Naming.** `RptqQuery +composeOutputKeysForFields:existingKeys:` derives one output key per
  field, preserving established keys, naming a field by its bare schema-field name when unique,
  and qualifying a collision with the source alias (`payments.amount`). `existingKeys` reserve
  names taken by already-added children; a collision that survives qualification gets a numeric
  suffix.
- **Convert.** `RptqDocument -convertToCompositionWithChildName:error:` keeps the report's query
  and connection as the child, adds a root that projects the child's fields with derived output
  keys, moves the child's groups and sort to the root (rebound to the root's outputs, bands kept),
  and rebinds the layout's data-field, aggregate, and barcode references to the root's outputs.
  A failure leaves the report unchanged.

> **Superseded by the node-as-report decision (2026-11-26, final).** Convert must keep the
> child's layout with the child and give the new root its own layout. The "bands kept on the
> root" behavior recorded above is a pre-decision shortcut, not the target. See spec §0 and
> `MAD_COMPOSITION_NODE_VIEW.md` §3.
- **Add child.** `RptqDocument -addChildQuery:error:` adds a child as a new input of the composed
  root (upstream table + one root field per child field), derives output keys preserving existing
  outputs, and appends to the output order.
- **Empty document.** `MADHeadlessDocument +createEmptyDocumentAtURL:error:` makes a
  connection-less document the composition flows import children into; `-database` now answers
  nil for a document with no database instead of asserting.
- **AppKit surface.** The document type label ("Standard Report" / "Composition Report") is
  persistent in the window toolbar and VoiceOver-exposed. `File → New…` offers Standard vs
  Composition; `File → New Composition…` picks existing `.mad` reports, imports each as a child,
  adds the root, and opens the result; `File → Convert to Composition…` converts the current
  standard report and is enabled only when it applies. `MADMacDocument` gains
  `importChildFromURL:name:error:`, `convertToCompositionWithChildName:error:`, and
  `addChildQuery:error:`.

**Tests.** Apple `MAD` store suite is 26/0 (import remap + relative-path resolution + composed
import, naming, convert, add-child). `RptqStoreContextTests` is mirrored to Linux/Windows. The
macOS smoke suite adds the convert (outputs, refresh, save, reopen) and create-by-import
(structure, outputs, save, reopen without the source files) flows, on top of the existing
authored-composed case.

**Pending.** The Windows engine/package/WPF run and the PR CI have not been run. PR creation and
merge await the user's direction.

**Follow-up (same day).** The two-input join cap at `MADMacQueryViewController.m` is lifted: the
composed root now supports N-way joins (the engine's general-query compiler already did), and the
join-type editor offers the full SQLite set. The query toolbar gains `+ Import…`, which imports an
existing `.mad` as a child of the composed root. Full `./Linux/build.sh` is green (131 suites /
0 failures, `RptqStoreContextTests` 31/0), and the Linux CLI verify is 42/0.

## Checkpoint I — native Windows composition landed (2026-11-25)

The Windows workstation now authors, saves, reopens, refreshes, views and exports a
composition through the native WPF shell, on the shared engine. The engine and macOS
surface (Checkpoints A–H) are unchanged except for the baseline fixes below; the work here
is the `mad serve` transport and the WPF surface on top of the existing engine primitives.

- **Baseline.** Three Windows-only failures were fixed before the surface work:
  `RptqDocument -mainQuery` could return the composed root instead of the source query
  (the root shares the first source's database, so `hasDatabaseSchemas.anyObject.hasQueries.anyObject`
  is ambiguous once a root exists); `MADDatabaseSqlite3 -executeSQL:…` failed an empty query
  (a freshly created document with no tables) as `SQLITE_MISUSE`/“not an error” instead of an
  empty result; and the byte-identical Linux/Windows `MADReportExporterTests` mirror assumed
  Linux's two-level test path and used `?` (a DOS wildcard) in a fixture path.
- **Serve protocol.** Every query-model mutation takes an optional `query` identifier and edits
  that query; an unknown or stale identifier answers an actionable error and leaves the document
  unchanged. New methods, backed by the existing `MAD` primitives: `document-info`, `create-empty`,
  `add-root`, `add-source`, `add-upstream`, `import-child`, `convert`, and `set-root-outputs`.
  `layout-model` resolves the composed root (its ordered outputs become the designer field list);
  this is pre-decision behavior — the per-node layout decision (spec §0) makes it query-scoped,
  with the root as the default. Ordinary single-query callers that omit `query` keep today's
  behaviour.
- **WPF surface.** `DocumentViewModel` exposes `IsComposed`, the query list, and the selected
  query (shown separately from the document type, which is labelled in the window toolbar);
  `QueryViewModel` edits the selected query; the File menu gains New Composition, Convert to
  Composition and Import; the Query workspace gains a query selector. New `document-info`/query
  models and `EngineService` methods carry the protocol.
- **Acceptance tests.** `CompositionAcceptanceTests` drives the full flow through the engine
  service and view models: create + author + save + reopen + refresh + view + export (pinning
  the joined rows `(1,100,40) (1,100,60) (2,200,null) (3,300,null)`), convert a standard report,
  and import a child report. The invoices/payments SQLite fixtures are checked in under the test
  project.

**Results (actual, 2026-11-25).** Windows engine build `131 suites / 0 failures`; WPF suite
`122/122` (including the three composition acceptance tests); `check_source_lists.py` green. The
packaged app (`Windows/package.ps1`) verifies its bundled engine is the tested checkout and writes
`MAD-Designer-Windows-0.7.1.zip` (75.3 MB) and `mad-windows-x64.zip` (11.8 MB); the bundled engine
reports `9.0 (r4433) commit 25de4050`. The packaged WPF app launches
`Windows\Engine\build\mad.exe` beside itself (`MadPathResolver.MadExe()`), built from the tested
checkout.

**Not covered / deferred.** A graphical capability matrix; the remaining open review items
(P4, P7, P8). The Linux CI and Apple suites for the shared-source baseline fixes have not been run
here. PR creation and merge await the user's direction.

## Checkpoint J — Windows authoring gaps closed (2026-11-25)

The follow-up closes the Windows authoring gaps named in Checkpoint I, so a user can sit down at
the packaged app with two standard `.mad` reports and author a composition themselves.

- **Add-upstream.** When the composed root is selected, the Query sidebar lists the source
  queries; double-clicking one adds it as an upstream input of the root (the Mac's
  `addUpstreamQueryToRoot:`, served as `add-upstream`).
- **Outputs editor.** An Outputs popover (visible only for the root) chooses, names, removes and
  reorders the root's outputs, persisted through `set-root-outputs` (the field list in the query
  model now carries each field's `outputKey`/`outputIndex`).
- **Query-scoped SQL.** `validate-sql`/`apply-sql` take a `query` identifier and compile against
  that query's own schema; a composing root answers an actionable "SQL editing is not supported
  for the composed root" error, the SQL toggle is disabled for the root, and a stale selection
  leaves the document unchanged.
- **Tests.** `ImportTwoReports_AuthorJoinAndOutputs` drives two imported reports → join on
  `invoice_id` → choose and then reorder the outputs, asserting the exported column order follows;
  `SqlEntry_ActsOnTheSelectedQueryAndRejectsTheRoot` pins the query-scoped SQL behavior.

**Results (actual, 2026-11-25).** Windows engine build `131 suites / 0 failures`; WPF suite
`124/124` (five composition acceptance tests). The packaged app writes
`MAD-Designer-Windows-0.7.1.zip` and `mad-windows-x64.zip`, and its bundled engine reports the
checked-out commit.


## Checkpoint K — Windows composition pane and node selection (2026-11-26)

The Windows surface now makes the container legible as a graph rather than a flat query
selector. The engine and serve protocol are unchanged by this checkpoint.

- **Composition pane.** A docked column beside the workspace (absent for a Standard Report),
  with a `GridSplitter`, an Expand/Collapse mode, an Import entry point, and an empty state.
  Its graph is built from each query's own upstream tables, so nested composers and shared
  children draw correctly; the Result is at depth 0 and connectors point at the consumer.
- **One selection.** The graph and a new toolbar **Component** picker drive
  `Document.SelectedQueryId`; the Query workspace loads that node. Selecting a source moves to
  Query; the Designer/Viewer show an explicit notice that they still render the Result.
- **Start workspace.** Opening a report starts in Query; a created standard report starts in
  the Designer; a created composition starts in Query.
- **Terminology and guidance.** Outputs → Columns ("Report columns"), Sources/Result/Source
  wording, the root canvas placeholder, the Sources hint, the one-source hint, and the
  Designer's "Report columns" caption. The Sources list now hides sources already joined to
  the Result and says when all are added. All new strings are in the six dictionaries.
- **Two client-side protocol/flow fixes found by rendering the real window.** `query-model`
  writes `isRoot` as `1`/`0` while `document-info` writes a JSON boolean; the parser now
  accepts both, so the Result's Query workspace shows Sources/Columns instead of the schema
  list. A root-only composition's missing source database makes the `connection` endpoint
  answer an error; the document now treats that as the expected empty-composition state, so
  **File ▸ New Composition** reaches its guide instead of failing to open.
- **Tests.** `CompositionGraphTests` pins edge/depth derivation, selection events, and the
  rendered card/connector counts; `CompositionPaneTests` pins the XAML shell;
  `CompositionSelectionTests` drives a real composition through select-source / select-Result,
  the workspace notice, and the empty-composition open; `ProtocolParsingTests` pins the
  boolean/1-0 root flag.

**Results (actual, 2026-11-26).** WPF suite `165/165` and client suite `24/24` on the Windows
engine build from 2026-11-25; the engine, serve protocol, and store are unchanged, so no engine
suite was rerun.

**Remaining — decided final, implementation pending.** Designer and Viewer still show the
Result for any selection: a document has one layout and import drops a source's layout. The
target is not in question: every node keeps its layout and data, and all three workspaces
follow the selection (spec §0). The implementation scope — store revision, import,
query-scoped layout/describe/result reads, and the Windows/macOS/iOS surfaces — is in
[`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md).

## Checkpoint L — macOS per-node reports (2026-11-27)

The native AppKit app now treats every composition node as a report: one selection in the
toolbar drives Query, Designer, and Viewer together; a source shows and edits its own
layout and renders its own values; a layout-less source is a row grid; the Result and a
Standard Report keep the document path. The engine, store, import, and serve code is
unchanged (`253847b04` plus this slice).

- **Selection model.** `MADMacDocument.selectedQuery` is the one selection. A custom setter
  posts `MADMacDocumentDidSelectQueryNotification` (selection is not a mutation: no dirty
  flag, no save, no workspace switch) and bumps `selectionVersion`. Selecting a non-root
  query with no structural bands calls `ensureStructuralSectionsInContext:` once, persists
  that real store mutation (without the mutate notification), and rebuilds the
  `MADSectionsLayout` snapshot for the selected query. `orderedSections` is now
  `[selectedQuery orderedLayoutSectionsForDocument:]`, so the canvas, band table, minimap,
  inspector, and drag/drop follow the selection in one place; the report root still returns
  the document's five sections, so the ordinary report is byte-for-byte the old path.
- **Node picker.** A toolbar `NSPopUpButton` (Composition Reports only) lists the Result
  first, marked "Result — <name>", then each source. It shares the selection with the Query
  workspace's existing popup; selecting a node never changes the active workspace.
- **Query workspace.** A nested composing source is read-only structure (its upstream
  tables; no Add Table) with a note that the source is itself a composition. SQL editing is
  disabled for any composing node with a localized explanation. The generated SQL preview
  is now compiled from a `MADQueryFull` built for the **selected** leaf's own database and
  dialect, closing the Checkpoint G gap where it compiled `headlessDocument.mainQuery`.
- **Designer.** The field list is the selected node's: its ordered output fields for the
  Result/any composer (caption "REPORT COLUMNS"), its own query fields for a leaf (caption
  "QUERY FIELDS"). A leaf's data field binds with `queryAlias` so it resolves to the key the
  node result carries. Stale cross-node section/element selections are cleared on reload;
  an empty layout shows an "add elements" hint rather than an error. Paper stays
  document-level.
- **Viewer.** Renders the selected node with the PDF exporter's
  `exportDocument:query:toURL:…` (never the no-query fallback for a non-root; a format
  without node support refuses). Status uses the node's own row count. A node whose
  ordered bands contain no elements shows an `NSTableView` row grid built from its
  retained `nodeResults` (root: `currentResult`); the previous node's PDF/grid is cleared
  before the new render. `json-report` is offered only for the report root and refused for
  a source; every other format exports the selected node. Refresh stays whole-document, and
  a failed node leaves the previous result readable. Print is disabled in grid mode.
- **Localization.** `sync_catalog.py` added the 100 keys the composition work had left
  uncatalogued (the Mac authoring strings plus this slice's), and all five translations
  (de, es, ja, pt-BR, zh-Hans) were written for them. The catalog is complete and
  `check_translations.py --require-complete` passes.
- **Verification (actual).** `./Mac/build.sh --smoke-test` passes, 25 checks. The new
  per-node check drives the real toolbar picker: selecting payments keeps the workspace,
  creates its five bands, shows its leaf caption, then authors a label + `payments.amount`
  data field, refreshes the composition, renders a node PDF, and exports HTML containing
  the authored text and its own values (40/60); selecting the untouched invoices source
  shows a three-row grid; selecting the Result restores the document bands, a non-empty PDF,
  and the "Report columns" caption; `json-report` is present for the Result and absent/refused
  for the source; save/reopen preserves the source layout (2 elements) and leaves the
  Result's (3) untouched; a Standard Report keeps document-owned bands and json-report; an
  empty composition (root, no sources) selects the Result and shows the not-yet-refreshed
  guidance without a crash.

  The per-node states were also captured from the app's own window with the smoke binary's
  `--write-node-screenshots <dir>` mode (written for hosts where screen capture is
  unavailable): the Result/Designer, Payments/Designer, Payments/Viewer (node PDF showing
  40 and 60), Invoices/Viewer (three-row grid), and Result/Viewer (four joined rows). The
  AppKit snapshot does not draw the toolbar's popup/segmented controls into the bitmap, so
  the per-node evidence there is the field caption, bands, status line, and page content;
  the PDF rendering of each state is written beside its PNG.

**Finding — the Apple print walk is dead code.** The handoff expected the first compile of
the node-aware section substitution in `MAD/Source/MADPrintPageRenderer.m` to be the gate.
It compiles because the whole `accessibilityDrawingObjectsOnPageAtIndex:` region is inside
a block comment (`/*` at `:379` through `*/` at `:469`), so the substitution has never been
compiled or run. If it is uncommented it will not build: `:432` has a stray `]` with no
opening `[`, and `:413` calls `newDatabaseConnectionForUserCredentals:`, a selector that
does not exist (`+[MADDatabaseConnection newDatabaseConnection:]` is the real factory).
The Mac Viewer prints the rendered PDF (`PDFView`), not this renderer, so the slice is not
blocked. Recorded in `docs/project/registers/BUGS.md`; reviving the accessibility walk
belongs to its own change.

**Deferred / recorded.** Direct nested-composer authoring (adding upstream children to a
non-root composer), per-node paper size, `json-report` node scoping, an optional sidebar
node list, and node-scoped selection of a source's connection sheet. The audit's one
pre-existing over-baseline occurrence (`MADDataStructures/Source/MTGraph.m`,
`nonliteral-key: TextCycleEncountered`, now 2 vs baseline 1) is untouched.
